-- Inferno Collection Fire Alarm Version 4.5 BETA
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
-- Must be EXACTLY 4 numbers, in STRING form
Config.DefaultPasscode = "1234"

--
--		Nothing past this point needs to be edited, all the settings for the resource are found ABOVE this line.
--		Do not make changes below this line unless you know what you are doing!
--

-- Server variables
local Server = {}
-- Call points
Server.CallPoints = {}
-- Control panels
Server.ControlPanels = {}
-- JSON data
Server.Data = false

-- Load data from control panel JSON file
Server.Data = LoadResourceFile(GetCurrentResourceName(), "control-panels.json")
-- If able to load and read file
if Server.Data then
	-- Update server values with JSON file values
	Server.ControlPanels = json.decode(Server.Data)
	-- If data transferred correctly
	if Server.ControlPanels then
		-- Loop though all control panels
		for _, Panel in ipairs(Server.ControlPanels) do
			-- Add default screen
			Panel.CurrentScreen = "locked"
			-- Add empty current code
			Panel.CurrentCode = {}
			-- Check if a passcode is set
			if Panel.Passcode then
				-- Ensure it is in string form, as some people will inevitably
				-- put it in a int form in the JSON file
				Panel.Passcode = tostring(Panel.Passcode)
			-- If one is not set
			else
				-- Set passcode to default passcode
				Panel.Passcode = Config.DefaultPasscode
				-- Print error message to server console
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
if not Server.Data or not Server.ControlPanels then
	-- Print error message to server console
	print("===================================================================")
	print("==============================WARNING==============================")
	print("Unable to load control-panels.json file for Inferno-Fire-Alarm. The")
	print("resource will not function correctly. Please correct this issue and")
	print("restart the Server.")
	print("===================================================================")
end

-- Load data from control panel JSON file
Server.Data = LoadResourceFile(GetCurrentResourceName(), "call-points.json")
-- If able to load and read file
if Server.Data then
	-- Update server values with JSON file values
	Server.CallPoints = json.decode(Server.Data)
	-- If data transferred correctly
	if Server.CallPoints then
		-- Loop though all call points
		for _, Point in ipairs(Server.CallPoints) do
			-- Add default pull state
			Point.Pulled = false
		end
	end
end

-- If unable to load JSON file or file data
if not Server.Data or not Server.CallPoints then
	-- Print error message to server console
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
	TriggerClientEvent("Fire-Alarm:Return:GetObjects", source, {Server.CallPoints, Server.ControlPanels})
end)

-- Set a pull station pulled
RegisterServerEvent("Fire-Alarm:SetPulled")
AddEventHandler("Fire-Alarm:SetPulled", function(CP)
	-- Loop through all call points
	for _, Point in ipairs(Server.CallPoints) do
		-- If call point belongs to the same control panel as the pulled call point
		if Point.Control == CP.Control then
			-- Set all pulled, this stops two alarms going off at one time
			Point.Pulled = true
		end
	end

	-- Update client values
	TriggerClientEvent("Fire-Alarm:Bouce:UpdateCallPoints", -1, Server.CallPoints)
	-- Update server value
	TriggerEvent("Fire-Panel:SetScreen", CP.Control, "fire")
	-- Inform all clients alarm is active
	TriggerClientEvent("Fire-Alarm:Return:SetPulled", -1, CP)
	-- Inform all clients sounder is active
	TriggerClientEvent("Fire-Panel:Return:SoundPanel", -1, Server.ControlPanels[CP.Control])
end)

-- Reset all Pull Stations
RegisterServerEvent("Fire-Alarm:ResetAllCalls")
AddEventHandler("Fire-Alarm:ResetAllCalls", function(Panel)
	-- Loop through all call points
	for _, Point in ipairs(Server.CallPoints) do
		-- If call point belongs to the same control panel as the pulled call point
		if Point.Control == Panel then
			-- Unset pulled
			Point.Pulled = false
		end
	end
	TriggerClientEvent("Fire-Alarm:Bouce:UpdateCallPoints", -1, Server.CallPoints)
end)

-- Reset alarm (bounce)
RegisterServerEvent("Fire-Alarm:ResetAlarm")
AddEventHandler("Fire-Alarm:ResetAlarm", function()
	-- Bounce to all clients
    TriggerClientEvent("Fire-Alarm:Return:ResetAlarm", -1)
end)

-- Add code to current code
RegisterServerEvent("Fire-Panel:AddCode")
AddEventHandler("Fire-Panel:AddCode", function(CP, Code)
	-- If number of numbers entered is less than 4
	if #Server.ControlPanels[CP].CurrentCode < 4 then
		-- Add number to entered codes
		table.insert(Server.ControlPanels[CP].CurrentCode, Code)
		-- Bounce back to client
		TriggerClientEvent("Fire-Panel:Return:AddCode", source)
	end
end)

-- Remove last entered code
RegisterServerEvent("Fire-Panel:RemoveCode")
AddEventHandler("Fire-Panel:RemoveCode", function(CP)
	-- If there is a last entered code
	if #Server.ControlPanels[CP].CurrentCode > 0 then
		-- Remove last entered code
		table.remove(Server.ControlPanels[CP].CurrentCode, #Server.ControlPanels[CP].CurrentCode)
		-- Bounce back to client
		TriggerClientEvent("Fire-Panel:Return:RemoveCode", source)
	end
end)

-- Check entered code against server code
RegisterServerEvent("Fire-Panel:CheckCode")
AddEventHandler("Fire-Panel:CheckCode", function(CP)
	-- Temporary variable
	local Success = false
	-- If the entered code equals the panel's code
	if table.concat(Server.ControlPanels[CP].CurrentCode, "") == Server.ControlPanels[CP].Passcode then
		-- Update temporary variable
		Success = true
	end

	-- Reset entered code regardless
	Server.ControlPanels[CP].CurrentCode = {}
	-- Return to client
	TriggerClientEvent("Fire-Panel:Return:CheckCode", source, Success)
end)

-- Panel usage requested by client
RegisterServerEvent("Fire-Panel:OpenPanel")
AddEventHandler("Fire-Panel:OpenPanel", function(Panel)
	-- Return current screen
	TriggerClientEvent("Fire-Panel:Return:OpenPanel", source, Server.ControlPanels[Panel.ID])
	-- Bouce to all clients
	TriggerClientEvent("Fire-Panel:InUse", -1)
end)

-- Panel no longer needed by client
RegisterServerEvent("Fire-Panel:ClosePanel")
AddEventHandler("Fire-Panel:ClosePanel", function()
	-- Bouce to all clients
    TriggerClientEvent("Fire-Panel:OutOfUse", -1)
end)

-- Set panel screen
RegisterServerEvent("Fire-Panel:SetScreen")
AddEventHandler("Fire-Panel:SetScreen", function(Panel, Screen)
	-- Update panel screen
	Server.ControlPanels[Panel].CurrentScreen = Screen
end)

-- Play annoucement
RegisterServerEvent("Fire-Panel:Ann")
AddEventHandler("Fire-Panel:Ann", function(Ann, Panel)
	-- Bounce to all clients
	TriggerClientEvent("Fire-Panel:Return:Ann", -1, Ann, Server.ControlPanels[Panel])
end)