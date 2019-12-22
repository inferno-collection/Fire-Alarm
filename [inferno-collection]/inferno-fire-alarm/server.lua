-- Inferno Collection Fire Alarm Version 4.6 ALPHA
--
-- Copyright (c) 2019, Christopher M, Inferno Collection. All rights reserved.
--
-- This project is licensed under the following:
-- Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to use, copy, modify, and merge the software, under the following conditions:
-- The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. THE SOFTWARE MAY NOT BE SOLD.
--

--
-- Resource Configuration
-- Please note, there is also some configuration required in the
-- `client.lua` file, so make sure to edit that file as well
--
-- PLEASE RESTART SERVER AFTER MAKING CHANGES TO THIS CONFIGURATION
--
local Config = {} -- Do not edit this line
-- The code used for a panel when one is not set, or set correctly, in the JSON file.
-- Must be EXACTLY 3 numbers, in STRING form
Config.DefaultPasscode = "333"

--
--		Nothing past this point needs to be edited, all the settings for the resource are found ABOVE this line.
--		Do not make changes below this line unless you know what you are doing!
--

-- Server variables
local Data
local Server = {}
Server.CallPoints = {}
Server.ControlPanels = {}

-- Load data from control panel JSON file
Data = LoadResourceFile(GetCurrentResourceName(), "control-panels.json")
-- If able to load and read file
if Data then
	Server.ControlPanels = json.decode(Data)
	if Server.ControlPanels then
		for _, Panel in ipairs(Server.ControlPanels) do
			Panel.Active = false
			Panel.ActiveLoc = false
			Panel.AnnActive = false
			Panel.WalkAround = false
			Panel.CurrentScreen = "sysnormal"
			Panel.CurrentCode = {}
			Panel.ScreenText = {nil, nil}
			Panel.AccessLevel = 1
			-- Check if a passcode is set
			if Panel.Passcode then
				-- Ensure it is in string form, as some people will inevitably
				-- put it in a int form in the JSON file
				Panel.Passcode = tostring(Panel.Passcode)
			-- If one is not set
			else
				-- Set passcode to default passcode
				Panel.Passcode = Config.DefaultPasscode
				print("===================================================================")
				print("==============================WARNING==============================")
				print("Control Panel number " .. Panel.ID .. " for Inferno-Fire-Alarm does not have")
				print("a valid passcode set, the default passcode (" .. Config.DefaultPasscode .. ") has")
				print("been applied to it instead - This is non-fatal warn.")
				print("===================================================================")
			end
		end
	end
end

-- If unable to load JSON file or file data
if not Data or not Server.ControlPanels then
	print("===================================================================")
	print("==============================WARNING==============================")
	print("Unable to load control-panels.json file for Inferno-Fire-Alarm. The")
	print("resource will not function correctly. Please correct this issue and")
	print("restart the Server.")
	print("===================================================================")
end

-- Load data from call point JSON file
Data = LoadResourceFile(GetCurrentResourceName(), "call-points.json")
-- If able to load and read file
if Data then
	Server.CallPoints = json.decode(Data)
	if Server.CallPoints then
		for _, Channel in ipairs(Server.CallPoints) do
			for _, Point in ipairs(Channel.Devices) do
				Point.Pulled = false
				Point.Control = Channel.Control
				Point.Channel = Channel.Channel
			end
		end
	end
end

-- If unable to load JSON file or file data
if not Data or not Server.CallPoints then
	print("===================================================================")
	print("==============================WARNING==============================")
	print("Unable to load call-points.json file for Inferno-Fire-Alarm. The re")
	print("source will not function correctly. Please correct this issue and r")
	print("estart the Server.")
	print("===================================================================")
end

-- Objects requested from client
RegisterServerEvent("Fire-Alarm:GetObjects")
AddEventHandler("Fire-Alarm:GetObjects", function()
	-- Provide client with call point and control panel data
	TriggerClientEvent("Fire-Alarm:Return:GetObjects", source, Server.CallPoints, Server.ControlPanels)
end)

-- Set a pull station pulled
RegisterServerEvent("Fire-Alarm:SetPulled")
AddEventHandler("Fire-Alarm:SetPulled", function(CallPoint)
	Server.ControlPanels[CallPoint.Control].Active = true
	Server.ControlPanels[CallPoint.Control].ActiveLoc = CallPoint.Location

	for _, Channel in ipairs(Server.CallPoints) do
		for _, Point in ipairs(Channel.Devices) do
			-- If call point belongs to the same control panel as the pulled call point
			if Point.Control == CallPoint.Control then
				-- Set all pulled, this stops two alarms going off at one time
				Point.Pulled = true
			end
		end
	end

	TriggerClientEvent("Fire-Alarm:Bouce:UpdateValues", -1, Server)
	TriggerEvent("Fire-Panel:SetScreen", CallPoint.Control, "fire", {nil, nil})
	TriggerClientEvent("Fire-Alarm:Return:SetPulled", -1, CallPoint)
end)

-- Start walk around for call point
RegisterServerEvent("Fire-Alarm:WalkAround")
AddEventHandler("Fire-Alarm:WalkAround", function(CallPoint)
	Server.ControlPanels[CallPoint.Control].Active = true

	for _, Channel in ipairs(Server.CallPoints) do
		for _, Point in ipairs(Channel.Devices) do
			-- If call point belongs to the same control panel as the pulled call point
			if Point.Control == CallPoint.Control then
				-- Set all pulled, this stops two alarms going off at one time
				Point.Pulled = true
			end
		end
	end

	TriggerClientEvent("Fire-Alarm:Bouce:UpdateValues", -1, Server)
	TriggerClientEvent("Fire-Alarm:Return:StartWalkAround", -1, CallPoint)
end)

-- Reset all Pull Stations for a specifc panel
RegisterServerEvent("Fire-Alarm:ResetAllCalls")
AddEventHandler("Fire-Alarm:ResetAllCalls", function(PanelID)
	Server.ControlPanels[PanelID].Active = false

	for _, Channel in ipairs(Server.CallPoints) do
		for _, Point in ipairs(Channel.Devices) do
			-- If call point belongs to the control panel
			if Point.Control == PanelID then
				-- Unset pulled
				Point.Pulled = false
			end
		end
	end

	TriggerClientEvent("Fire-Alarm:Bouce:UpdateCallPoints", -1, Server.CallPoints)
end)

RegisterServerEvent("Fire-Panel:ResetWalkTest")
AddEventHandler("Fire-Panel:ResetWalkTest", function(PanelID)
	Server.ControlPanels[PanelID].Active = false

	for _, Channel in ipairs(Server.CallPoints) do
		for _, Point in ipairs(Channel.Devices) do
			-- If call point belongs to the same control panel as the pulled call point
			if Point.Control == PanelID then
				-- Unset pulled
				Point.Pulled = false
			end
		end
	end

	TriggerClientEvent("Fire-Alarm:Bouce:UpdateValues", -1, Server)
end)

-- Reset alarm on all clients
RegisterServerEvent("Fire-Alarm:ResetAlarm")
AddEventHandler("Fire-Alarm:ResetAlarm", function(ID)
	TriggerClientEvent("Fire-Alarm:Bouce:ResetAlarm", -1, ID)
end)

-- Add code to current code
RegisterServerEvent("Fire-Panel:AddCode")
AddEventHandler("Fire-Panel:AddCode", function(PanelID, Code)
	-- If number of numbers entered is less than 3
	if #Server.ControlPanels[PanelID].CurrentCode < 3 then
		table.insert(Server.ControlPanels[PanelID].CurrentCode, Code)
		TriggerClientEvent("Fire-Panel:Return:AddCode", source, #Server.ControlPanels[PanelID].CurrentCode)
	end
end)

-- Remove last entered code
RegisterServerEvent("Fire-Panel:RemoveCode")
AddEventHandler("Fire-Panel:RemoveCode", function(PanelID)
	-- If there is a last entered code
	if #Server.ControlPanels[PanelID].CurrentCode > 0 then
		table.remove(Server.ControlPanels[PanelID].CurrentCode, #Server.ControlPanels[PanelID].CurrentCode)
		TriggerClientEvent("Fire-Panel:Return:RemoveCode", source, #Server.ControlPanels[PanelID].CurrentCode)
	end
end)

-- Check entered code against server code
RegisterServerEvent("Fire-Panel:CheckCode")
AddEventHandler("Fire-Panel:CheckCode", function(PanelID)
	local Success = false

	-- If the entered code equals the server code, update temporary variable
	if table.concat(Server.ControlPanels[PanelID].CurrentCode, "") == Server.ControlPanels[PanelID].Passcode then Success = true end

	-- Reset entered code regardless
	Server.ControlPanels[PanelID].CurrentCode = {}

	TriggerClientEvent("Fire-Panel:Return:CheckCode", source, Success)
end)

-- Panel requested by client
RegisterServerEvent("Fire-Panel:OpenPanel")
AddEventHandler("Fire-Panel:OpenPanel", function(Panel)
	Server.ControlPanels[Panel.ID].Open = true

	TriggerClientEvent("Fire-Alarm:Bouce:UpdateValues", -1, Server)
	TriggerClientEvent("Fire-Panel:Return:OpenPanel", source, Server.ControlPanels[Panel.ID])
end)

-- Set panel screen
RegisterServerEvent("Fire-Panel:SetScreen")
AddEventHandler("Fire-Panel:SetScreen", function(PanelID, Screen, Text)
	Server.ControlPanels[PanelID].CurrentScreen = Screen
	Server.ControlPanels[PanelID].ScreenText = Text
end)

-- Set panel access level
RegisterServerEvent("Fire-Panel:SetAccessLevel")
AddEventHandler("Fire-Panel:SetAccessLevel", function(PanelID, Level)
	Server.ControlPanels[PanelID].AccessLevel = Level

	TriggerClientEvent("Fire-Alarm:Bouce:UpdateValues", -1, Server)
end)

-- Set panel in walk around mode
RegisterServerEvent("Fire-Panel:SetWalkAround")
AddEventHandler("Fire-Panel:SetWalkAround", function(PanelID, WalkAround)
	Server.ControlPanels[PanelID].WalkAround = WalkAround

	TriggerClientEvent("Fire-Alarm:Bouce:UpdateValues", -1, Server)
end)

-- Play annoucement on all clients
RegisterServerEvent("Fire-Panel:Ann")
AddEventHandler("Fire-Panel:Ann", function(Ann, Panel)
	TriggerClientEvent("Fire-Panel:Return:Ann", -1, Ann, Panel)
end)

-- Update all client values
RegisterServerEvent("Fire-Panel:UpdateAllClients")
AddEventHandler("Fire-Panel:UpdateAllClients", function(FirePanel)
	Server.CallPoints = FirePanel.CallPoints
	Server.ControlPanels = FirePanel.ControlPanels

	TriggerClientEvent("Fire-Alarm:Bouce:UpdateValues", -1, Server)
end)