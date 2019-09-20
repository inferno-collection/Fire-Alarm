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
-- `server.lua` file, so make sure to edit that file as well
--
-- PLEASE RESTART SERVER AFTER MAKING CHANGES TO THIS CONFIGURATION
--
local Config = {} -- Do not edit this line
-- Whether or not to enable Fire/EMS Pager Intergration
-- Requires https://github.com/inferno-collection/Fire-EMS-Pager
Config.EnablePager = true
-- Assuming pager intergration enabled, which tones should be paged when
-- alarm activated, if none are defined in the JSON file entry
Config.DefaultAlarmTones = {"fire"}
-- The size around the source the alarm can be heard.
-- Alarm gets quieter the further from the origin, so the
-- number below is the further spot it will be able to be heard from
Config.AlarmSize = 80
-- The size around the source the sounder can be heard.
-- Sounder gets quieter the further from the origin, so the
-- number below is the further spot it will be able to be heard from
Config.PanelSize = 20
-- The size around the source announcements can be heard.
-- Sounder gets quieter the further from the origin, so the
-- number below is the further spot it will be able to be heard from
Config.AnnSize = 40
-- The length of time in ms between each alarm sound loop.
-- It is recommended that you do not edit this unless you change the
-- alarm sound file. Time starts from start of audio file, not end
Config.AlarmLength = 500
-- The length of time in ms between each sounder sound loop.
-- It is recommended that you do not edit this unless you change the
-- sounder sound file. Time starts from start of audio file, not end
Config.SounderLength = 1523
-- The length of time in ms it takes to play annoucement sound files.
-- It is recommended that you do not edit this unless you change one
-- or both of the annoucement sound file. Time starts from start of
-- audio file, not end. Use length of longest sound file of the two
Config.AnnLength = 11000
-- The length of time in ms between panel screen changes
Config.ScreenLength = 3000

--
--		Nothing past this point needs to be edited, all the settings for the resource are found ABOVE this line.
--		Do not make changes below this line unless you know what you are doing!
--

-- Local Alarm Variables
local FireAlarm = {}
-- Whether or not an alarm is currently active
FireAlarm.Active = false
-- ID of the active alarm
FireAlarm.ActiveID = 0
-- All alarm call points
FireAlarm.CallPoints = {}
-- Size around the alarm source the alarm can be heard
FireAlarm.Size = Config.AlarmSize

-- Local Panel Variables
local FirePanel = {}
-- Whether or not any panel is currently in use (synced)
FirePanel.Active = false
-- ID of the active panel
FirePanel.ActiveID = false
-- Whether or not a test annoucement is currently being played
FirePanel.AnnActive = false
-- Whether or not a panel is currently sounding its buzzer
FirePanel.Enabled = false
-- Whether or not this client is currently using a pannel
FirePanel.Open = false
-- ID of the active panel
FirePanel.OpenID = 0
-- Current screen showing on active panel
FirePanel.CurrentScreen = ""
-- All alarm control panels
FirePanel.ControlPanels = {}
-- Size around the sounder source the sounder can be heard
FirePanel.Size = Config.PanelSize
-- Size around the announcements source the sounder can be heard
FirePanel.AnnSize = Config.AnnSize

-- When the resource is started, so if the resource is restarted the client respawns the objects
AddEventHandler("onClientResourceStart", function (ResourceName)
	-- If the started resource is this resource
	if(GetCurrentResourceName() == ResourceName) then
		-- Request objects from server
		TriggerServerEvent("Fire-Alarm:GetObjects")
	end
end)

-- Return of objects
RegisterNetEvent("Fire-Alarm:Return:GetObjects")
AddEventHandler("Fire-Alarm:Return:GetObjects", function(Objects)
	-- Update local values with server ones
	FireAlarm.CallPoints = Objects[1]
	FirePanel.ControlPanels = Objects[2]

	-- Loop though all call points
	for _, Object in ipairs(Objects[1]) do
		-- Check if there is an object
		if Object.Prop ~= nil then
			-- Attempt to create a new object
			local NewObject = CreateObjectNoOffset(GetHashKey(Object.Prop), vector3(Object.x, Object.y, Object.z), false, false, false)

			-- If able to create object
			if NewObject then
				-- Update object rotation
				SetEntityRotation(NewObject, vector3(Object.rx, Object.ry, Object.rz), 2, true)
				-- Freeze object in place
				FreezeEntityPosition(NewObject, true)
			-- If unable to create object
			else
				print("===================================================================")
				print("=============================ATTENTION=============================")
				print("Unable to create call point for Inferno-Fire-Alarm. Call point numb")
				print("er: " .. Object.ID .. " - This is non-fatal warn.")
				print("===================================================================")
			end
		-- If there is no object
		else
			print("===================================================================")
			print("==============================Warning==============================")
			print("No prop found for a call point in Inferno-Fire-Alarm. Call point nu")
			print("mber: " .. Object.ID .. " - This is non-fatal warn.")
			print("===================================================================")
		end
	end

	-- Loop though all call points
	for _, Object in ipairs(Objects[2]) do
		-- Check if there is an object
		if Object.Prop ~= nil then
			-- Attempt to create a new object
			local NewObject = CreateObjectNoOffset(GetHashKey(Object.Prop), vector3(Object.x, Object.y, Object.z), false, false, false)

			-- If able to create object
			if NewObject then
				-- Update object rotation
				SetEntityRotation(NewObject, vector3(Object.rx, Object.ry, Object.rz), 2, true)
				-- Freeze object in place
				FreezeEntityPosition(NewObject, true)
			-- If unable to create object
			else
				print("===================================================================")
				print("=============================ATTENTION=============================")
				print("Unable to create control panel for Inferno-Fire-Alarm. Control pane")
				print("l number: " .. Object.ID .. " - This is non-fatal warn.")
				print("===================================================================")
			end
		-- If there is no object
		else
			print("===================================================================")
			print("==============================Warning==============================")
			print("No prop found for a control panel in Inferno-Fire-Alarm. Control pa")
			print("nel nummber: " .. Object.ID .. " - This is non-fatal warn.")
			print("===================================================================")
		end
	end
end)

-- Update local values with server values
RegisterNetEvent("Fire-Alarm:Bouce:UpdateCallPoints")
AddEventHandler("Fire-Alarm:Bouce:UpdateCallPoints", function(CallPoints)
	FireAlarm.CallPoints = CallPoints
end)

-- Set a pull station as pulled
RegisterNetEvent("Fire-Alarm:Return:SetPulled")
AddEventHandler("Fire-Alarm:Return:SetPulled", function(CallPoint)
	-- Set alarm active
	FireAlarm.Active = true
	-- Set active alarm ID
	FireAlarm.ActiveID = CallPoint.Control

	-- Create a thread for safe looping
	Citizen.CreateThread(function()
		-- Stops crashes
		Citizen.Wait(0)
		-- While an alarm is still playing
		while FireAlarm.Active do
			-- Additional check, for when the script loops
			if FireAlarm.Active then
				-- New NUI message
				SendNUIMessage({
					-- Tell NUI to play alarm sound
					PayloadType	= "PlayAlarm"
				})
				-- Length of alarm sound file
				Citizen.Wait(Config.AlarmLength)
			-- If alarm is no longer active
			else
				-- Break from loop
				break
			end
		end
	end)
end)

-- Activate alarm sounder
RegisterNetEvent("Fire-Panel:Return:SoundPanel")
AddEventHandler("Fire-Panel:Return:SoundPanel", function(Panel)
	-- Set panel sounder active
	FirePanel.Active = true
	-- Set active panel sounder ID
	FirePanel.ActiveID = Panel.ID

	-- Create a thread for safe looping
	Citizen.CreateThread(function()
		-- Stops crashes
		Citizen.Wait(0)
		-- While a sounder is still playing
		while FirePanel.Active do
			-- Additional check, for when the script loops
			if FirePanel.Active then
				-- New NUI message
				SendNUIMessage({
					-- Tell NUI to play sounder sound file
					PayloadType	= "PlaySounder"
				})
				-- Length of sounder sound file
				Citizen.Wait(Config.SounderLength)
			-- If alarm is no longer active
			else
				-- Break from loop
				break
			end
		end
	end)
end)

-- Open panel on this specific client
RegisterNetEvent("Fire-Panel:Return:OpenPanel")
AddEventHandler("Fire-Panel:Return:OpenPanel", function(Panel)
	-- Set open panel ID
	FirePanel.OpenID = Panel.ID
	--Update local screen value with server value
    FirePanel.CurrentScreen = Panel.CurrentScreen
    -- Set NUI in focus
	SetNuiFocus(true, true)
	-- New NUI message
    SendNUIMessage({
		-- Tell NUI to open a new screen
		PayloadType	= "OpenPanel",
		-- Tell NUI which screen specifically
        Payload		= FirePanel.CurrentScreen
	})

	-- If animation dictionary not loaded
	if not HasAnimDictLoaded("anim@amb@trailer@touch_screen@") then
		-- Load animation Dictionary
		RequestAnimDict("anim@amb@trailer@touch_screen@")
		-- While the dictionary is not loaded
		while not HasAnimDictLoaded("anim@amb@trailer@touch_screen@") do
			-- Wait
			Citizen.Wait(0)
		end
	end

	-- Player's Ped
	local PlayerPed = PlayerPedId()
	-- Make player face the panel
	TaskTurnPedToFaceCoord(PlayerPed, Panel.x, Panel.y, Panel.z, 0)
	-- Player panel interaction animation
	TaskPlayAnim(PlayerPed, "anim@amb@trailer@touch_screen@", "idle_c", 8.0, -8, 0.01, 49, 0, 0, 0, 0)
end)

-- Play an annoucement from a panel
RegisterNetEvent("Fire-Panel:Return:Ann")
AddEventHandler("Fire-Panel:Return:Ann", function(Ann, Panel)
	-- Set annoucement in use
	FirePanel.AnnActive = true

	-- New NUI message
	SendNUIMessage({
		-- Tell NUI which sound to play
		PayloadType = Ann
	})

	-- Create a thread for safe looping
	Citizen.CreateThread(function()
		-- While annoucement is still playing
		while FirePanel.AnnActive do
			-- Stops crashes
			Citizen.Wait(0)
			-- Additional check, for when the script loops
            if FirePanel.AnnActive then
                -- Player position
                local PP = GetEntityCoords(PlayerPedId(), false)
                -- Panel position
                local CPP = vector3(Panel.x, Panel.y, Panel.z)
                -- Distance between player and station
                local Distance = Vdist(PP.x, PP.y, PP.z, CPP.x, CPP.y, CPP.z) + 0.01 -- Stops divide by 0 errors
                -- If distance between player and panel is within range
				if (Distance <= FirePanel.AnnSize) then
					-- New NUI message
                    SendNUIMessage({
						-- Tell NUI to update volume
						PayloadType	= "SetAnnVolume",
						-- Volume value
                        Payload		= 1 - (Distance / FirePanel.AnnSize)
					})
				-- If distance beyween player and panel is outside range
				else
					-- New NUI message
                    SendNUIMessage({
						-- Tell NUI to update volume
						PayloadType	= "SetAnnVolume",
						-- Volume value
                        Payload		= 0
                    })
                end
            end
		end
	end)

    -- Wait until sound finshes playing
    Citizen.Wait(Config.AnnLength)
    -- Disable annoucement in use
    FirePanel.AnnActive = false
end)

-- NUI call back for a button being pressed on panel
RegisterNUICallback("Button", function(Button, cb)
	-- Does the screen require a change
	local ScreenChange = false

	-- Enter Passcode screen
	if FirePanel.CurrentScreen == "locked" then
		-- If button pressed is a number
		if tonumber(Button) then
			-- Add number to entered codes
			TriggerServerEvent("Fire-Panel:AddCode", FirePanel.OpenID, Button)
		end

	-- *, **, and ***
	elseif FirePanel.CurrentScreen == "1" or FirePanel.CurrentScreen == "2" or FirePanel.CurrentScreen == "3" then
		-- If entered button is delete button
		if Button == "del" then
			-- Remove last entered code
			TriggerServerEvent("Fire-Panel:RemoveCode", FirePanel.OpenID)
		-- If button pressed is a number
		elseif tonumber(Button) then
			-- Add number to entered codes
			TriggerServerEvent("Fire-Panel:AddCode", FirePanel.OpenID, Button)
		end

	-- If button is acknowledge button
	elseif Button == "ack1" then
		-- If current screen is active fire screen
		if FirePanel.CurrentScreen == "fire" then
			-- Set current screen to global acknowledge
			FirePanel.CurrentScreen = "gack"
			-- If the fire pane is still open
			if FirePanel.Open then
				-- New NUI message
				SendNUIMessage({
					-- Tell NUI to open a new panel
					PayloadType	= "OpenPanel",
					-- Tell NUI to open global acknowledge screen
					Payload 	= FirePanel.CurrentScreen
				})
			end

			-- Update the server value for screen
			TriggerServerEvent("fire-panel:db:setScreen", FirePanel.OpenID, FirePanel.CurrentScreen)

			-- Wait
			Citizen.Wait(Config.ScreenLength)

			-- Set current screen to acknowledged screeb
			FirePanel.CurrentScreen = "ack1"
			-- Update server value shortly
			ScreenChange = true
		end
	-- If button is silence or reset button (they do nearly the same thing)
	elseif Button == "sil" or Button == "res" then
		-- If current screen is acknowledged screen
		if FirePanel.CurrentScreen == "ack1" then
			-- Set current screen to button name (they share names)
			FirePanel.CurrentScreen = Button
			-- If fire panel still open
			if FirePanel.Open then
				-- New NUI message
				SendNUIMessage({
					-- Tell NUI to open a new panel
					PayloadType	= "OpenPanel",
					-- Tell NUI to open alarm silence or reset screen
					Payload 	= FirePanel.CurrentScreen
				})
			end

			-- Update the server value for screen
			TriggerServerEvent("Fire-Panel:SetScreen", FirePanel.OpenID, FirePanel.CurrentScreen)
			-- Reset all call points
			TriggerServerEvent("Fire-Alarm:ResetAllCalls", FirePanel.OpenID)
			-- Reset alarm sound
			TriggerServerEvent("Fire-Alarm:ResetAlarm")

			-- If current screen is reset screen
			if FirePanel.CurrentScreen == "res" then
				-- Wait
				Citizen.Wait(Config.ScreenLength)
				-- Set current screen to reset complete screen
				FirePanel.CurrentScreen = "resc"

				-- If fire panel still open
				if FirePanel.Open then
					-- New NUI message
					SendNUIMessage({
						-- Tell NUI to open a new panel
						PayloadType	= "OpenPanel",
						-- Tell NUI to open reset complete screen
						Payload 	= FirePanel.CurrentScreen
					})
				end

				-- Update the server value for screen
				TriggerServerEvent("Fire-Panel:SetScreen", FirePanel.OpenID, FirePanel.CurrentScreen)

				-- Set current screen to locked screen
				FirePanel.CurrentScreen = "locked"
			-- Else if current screen is silence screen
			else
				-- Set current screen to acknowledged screen
				FirePanel.CurrentScreen = "ack1"
			end

			-- Wait
			Citizen.Wait(Config.ScreenLength)
			-- Update server value shortly
			ScreenChange = true
		end
	-- If button is previous button
	elseif Button == "prev" then
		-- Set menu to previous menu
		if FirePanel.CurrentScreen == "menu1" then
			FirePanel.CurrentScreen = "menu4"
			ScreenChange = true
		elseif FirePanel.CurrentScreen == "menu2" then
			FirePanel.CurrentScreen = "menu1"
			ScreenChange = true
		elseif FirePanel.CurrentScreen == "menu3" then
			FirePanel.CurrentScreen = "menu2"
			ScreenChange = true
		elseif FirePanel.CurrentScreen == "menu4" then
			FirePanel.CurrentScreen = "menu3"
			ScreenChange = true
		end
	-- If button is next button
	elseif Button == "next" then
		-- Set menu to next menu
		if FirePanel.CurrentScreen == "menu1" then
			FirePanel.CurrentScreen = "menu2"
			ScreenChange = true
		elseif FirePanel.CurrentScreen == "menu2" then
			FirePanel.CurrentScreen = "menu3"
			ScreenChange = true
		elseif FirePanel.CurrentScreen == "menu3" then
			FirePanel.CurrentScreen = "menu4"
			ScreenChange = true
		elseif FirePanel.CurrentScreen == "menu4" then
			FirePanel.CurrentScreen = "menu1"
			ScreenChange = true
		end
	-- If button is exit button
	elseif Button == "exit" then
		-- If current screen is any screen
		if FirePanel.CurrentScreen == "menu1" or
		FirePanel.CurrentScreen == "menu2" or
		FirePanel.CurrentScreen == "menu3" or
		FirePanel.CurrentScreen == "menu4" then
			-- Set current screen to home screen
			FirePanel.CurrentScreen = "sysnormal"
			-- Update server value shortly
			ScreenChange = true
		end
	-- If button is enter button
	elseif Button == "ent" then
		-- If cuurent screen is menu 1
		if FirePanel.CurrentScreen == "menu1" then
			-- If fire panel announcement is not already playing
			if not FirePanel.AnnActive then
				-- Play announcement
                TriggerServerEvent("Fire-Panel:Ann", "PlayAnn", FirePanel.OpenID)
			end

			-- Set current screen to home screen
			FirePanel.CurrentScreen = "sysnormal"
			-- Update server value shortly
			ScreenChange = true
		-- If current screen is menu 2
		elseif FirePanel.CurrentScreen == "menu2" then
			-- Set current screen to reset complete screen
			FirePanel.CurrentScreen = "resc"
			-- If fire panel still open
			if FirePanel.Open then
				-- New NUI message
				SendNUIMessage({
					-- Tell NUI to open a new panel
					PayloadType	= "OpenPanel",
					-- Tell NUI to open reset complete screen
					Payload 	= FirePanel.CurrentScreen
				})
			end

			-- Reset all call points
			TriggerServerEvent("Fire-Alarm:ResetAllCalls", FirePanel.OpenID)
			-- Update the server value for screen
			TriggerServerEvent("Fire-Panel:SetScreen", FirePanel.OpenID, FirePanel.CurrentScreen)

			-- Wait
			Citizen.Wait(Config.ScreenLength)

			-- Set current screen to home screen
			FirePanel.CurrentScreen = "sysnormal"
			-- Update server value shortly
			ScreenChange = true
		-- If current screen is menu 3
		elseif FirePanel.CurrentScreen == "menu3" then
			-- If fire panel announcement is not already playing
			if not FirePanel.AnnActive then
				-- Play announcement
                TriggerServerEvent("Fire-Panel:Ann", "PlayClear", FirePanel.OpenID)
			end

			-- Set current screen to home screen
			FirePanel.CurrentScreen = "sysnormal"
			-- Update server value shortly
			ScreenChange = true
		-- If current screen is menu 4
		elseif FirePanel.CurrentScreen == "menu4" then
			-- Set current screen to lock screen
			FirePanel.CurrentScreen = "locked"
			-- Update server value shortly
			ScreenChange = true
		end
	-- If button is menu button
	elseif Button == "menu" then
		-- If current screen is home screen
		if FirePanel.CurrentScreen == "sysnormal" then
			-- Set current screen to menu 1
			FirePanel.CurrentScreen = "menu1"
			-- Update server value shortly
			ScreenChange = true
		end
    end

	-- If the panel needs to be updated
	if ScreenChange then
		-- If the client still has the panel open
		if FirePanel.Open then
			-- New NUI message
			SendNUIMessage({
				-- Tell the NUI to open a new panel screen
				PayloadType	= "OpenPanel",
				-- Tell the NUI which screen to open
				Payload		= FirePanel.CurrentScreen
			})
		end

		-- Update server screen value
		TriggerServerEvent("Fire-Panel:SetScreen", FirePanel.OpenID, FirePanel.CurrentScreen)
	end

	-- Complete callback
    cb("ok")
end)

-- Close open panel
RegisterNUICallback("ClosePanel", function()
	-- Set panel closed
	FirePanel.Open = false

	-- Inform server panel is free for use
	TriggerServerEvent("Fire-Panel:ClosePanel")

	-- New NUI message
	SendNUIMessage({
		-- Tell NUI to close panel
		PayloadType = "ClosePanel"
	})
	-- Take NUI out of focus
	SetNuiFocus(false, false)

	-- Stop panel animation
	StopAnimTask(PlayerPedId(), "anim@amb@trailer@touch_screen@", "idle_c", 1.0)
end)

-- Add code to entered codes
RegisterNetEvent("Fire-Panel:Return:AddCode")
AddEventHandler("Fire-Panel:Return:AddCode", function()
	-- If current on lockscreen
	if FirePanel.CurrentScreen == "locked" then
		-- Change to * screen
		FirePanel.CurrentScreen = "1"
	-- If on any other screen
	else
		-- Chnage to current plus another *
		FirePanel.CurrentScreen = tostring(tonumber(FirePanel.CurrentScreen) + 1)
	end

	-- New NUI message
	SendNUIMessage({
		-- Tell the NUI to open a new panel screen
		PayloadType	= "OpenPanel",
		-- Tell the NUI which screen to open
		Payload		= FirePanel.CurrentScreen
	})

	-- Update server screen value
	TriggerServerEvent("Fire-Panel:SetScreen", FirePanel.OpenID, FirePanel.CurrentScreen)

	if FirePanel.CurrentScreen == "4" then
		-- Check with server if entered code is correct
		TriggerServerEvent("Fire-Panel:CheckCode", FirePanel.OpenID)
	end
end)

-- Remove last entered code
RegisterNetEvent("Fire-Panel:Return:RemoveCode")
AddEventHandler("Fire-Panel:Return:RemoveCode", function()
	-- Change current screen to previous screen
	if FirePanel.CurrentScreen == "1" then
		FirePanel.CurrentScreen = "locked"
	elseif FirePanel.CurrentScreen == "2" then
		FirePanel.CurrentScreen = "1"
	elseif FirePanel.CurrentScreen == "3" then
		FirePanel.CurrentScreen = "2"
	end

	-- New NUI message
	SendNUIMessage({
		-- Tell the NUI to open a new panel screen
		PayloadType	= "OpenPanel",
		-- Tell the NUI which screen to open
		Payload		= FirePanel.CurrentScreen
	})

	-- Update server screen value
	TriggerServerEvent("Fire-Panel:SetScreen", FirePanel.OpenID, FirePanel.CurrentScreen)
end)

-- Return for check code
RegisterNetEvent("Fire-Panel:Return:CheckCode")
AddEventHandler("Fire-Panel:Return:CheckCode", function(Success)
	-- If entered code is correct
	if Success then
		-- Take client to system normal screen
		FirePanel.CurrentScreen = "sysnormal"
	-- If entered code is incorrect
	else
		-- Take client back to lock screen
		FirePanel.CurrentScreen = "locked"
	end

	-- New NUI message
	SendNUIMessage({
		-- Tell the NUI to open a new panel screen
		PayloadType	= "OpenPanel",
		-- Tell the NUI which screen to open
		Payload		= FirePanel.CurrentScreen
	})

	-- Update server screen value
	TriggerServerEvent("Fire-Panel:SetScreen", FirePanel.OpenID, FirePanel.CurrentScreen)
end)

-- Reset alarm values
RegisterNetEvent("Fire-Alarm:Return:ResetAlarm")
AddEventHandler("Fire-Alarm:Return:ResetAlarm", function()
	-- Locally unset alarm and panel sounder values
	FireAlarm.Active = false
	FireAlarm.ActiveID = 0
	FirePanel.Active = false
	FirePanel.ActiveID = 0
end)

-- Panel currently in use
RegisterNetEvent("Fire-Panel:InUse")
AddEventHandler("Fire-Panel:InUse", function()
	-- Set panel in use
	FirePanel.Enabled = true
end)

-- Panel no longer in use
RegisterNetEvent("Fire-Panel:OutOfUse")
AddEventHandler("Fire-Panel:OutOfUse", function()
	-- Set panel not in use
	FirePanel.Enabled = false
end)

-- Resource master loop
Citizen.CreateThread(function()
	-- Forever
	while true do
		-- Stops crashes
		Citizen.Wait(0)

		-- If alarm not active and E just pressed
		if not FireAlarm.Active and IsControlJustReleased(0, 38) then
			-- Loop though all call points
			for _, CallPoint in ipairs(FireAlarm.CallPoints) do
				-- If this call point is not already been pulled
				if not CallPoint.Pulled then
					-- Player position
					local PP = GetEntityCoords(PlayerPedId(), false)
					-- Call point position
					local CP = vector3(CallPoint.x, CallPoint.y, CallPoint.z)
					-- Distance between player and call point
					local Distance = Vdist(PP.x, PP.y, PP.z, CP.x, CP.y, CP.z)
					-- If player is very close to call point
					if Distance <= 1.5 then
						-- Set point to pulled to avoid setting twice
						CallPoint.Pulled = true

						-- If animation dictionary not loaded
						if not HasAnimDictLoaded("anim@mp_radio@low_apment") then
							-- Load animation Dictionary
							RequestAnimDict("anim@mp_radio@low_apment")
							-- While the dictionary is not loaded
							while not HasAnimDictLoaded("anim@mp_radio@low_apment") do
								-- Wait
								Citizen.Wait(0)
							end
						end

						-- Player Ped
						local PlayerPed = PlayerPedId()
						-- Fire panel connect to call point
						local Panel = FirePanel.ControlPanels[CallPoint.Control]
						-- Make player face the panel
						TaskTurnPedToFaceCoord(PlayerPed, CallPoint.x, CallPoint.y, CallPoint.z, 0)
						-- Allow time to face call point
						Citizen.Wait(500)
						-- Player call point interaction animation
						TaskPlayAnim(PlayerPed, "anim@mp_radio@low_apment", "button_press_kitchen", 8.0, -8, 0.01, 49, 0, 0, 0, 0)
						-- Allow time to press button
						Citizen.Wait(500)
						-- Stop call point animation
						StopAnimTask(PlayerPed, "anim@mp_radio@low_apment", "button_press_kitchen", 1.0)
						-- Send call point to server
						TriggerServerEvent("Fire-Alarm:SetPulled", CallPoint)
						-- If pager intergation enabled
						if Config.EnablePager then
							-- Get nearest street and cross street to control panel
							local Street, CrossStreet = GetStreetNameAtCoord(Panel.x, Panel.y, Panel.z)
							-- Initialise details array
							local DetailsArray = {}
							-- Initialise details variable
							local Details
							-- If there is a cross street
							if CrossStreet ~= 0 then
								-- Set details
								Details = "Box Alarm - " .. GetStreetNameFromHashKey(Street) .. " X " .. GetStreetNameFromHashKey(CrossStreet)
							-- If there is not cross street
							else
								-- Set details
								Details = "Box Alarm - " .. GetStreetNameFromHashKey(Street)
							end
							-- Turn each word in the details variable into an array entry
							for w in Details:gmatch("%S+") do table.insert(DetailsArray, w) end
							-- If the panel has tones predefined
							if Panel.AlarmTones then
								-- Send message to pager resource
								TriggerServerEvent("Fire-EMS-Pager:PageTones", Panel.AlarmTones, true, DetailsArray)
							-- If panel does not have predefined tones
							else
								-- Send message to pager resource
								TriggerServerEvent("Fire-EMS-Pager:PageTones", Config.DefaultAlarmTones, true, DetailsArray)
							end
						end
					end
				end
			end
		-- If alarm is active
		elseif FireAlarm.Active then
			-- Loop though all control points
			for _, Panel in ipairs(FirePanel.ControlPanels) do
				-- If alarm is active, and active ID equals call point ID
				if FireAlarm.ActiveID == Panel.ID then
					-- Player position
					local PP = GetEntityCoords(PlayerPedId(), false)
					-- Control panel position
					local CPP = vector3(Panel.x, Panel.y, Panel.z)
					-- Distance between player and panel
					local Distance = Vdist(PP.x, PP.y, PP.z, CPP.x, CPP.y, CPP.z) + 0.01 -- Stops divide by 0 errors
					-- If distance between player and panel is within range
					if (Distance <= FireAlarm.Size) then
						-- Set Alarm volume
						local AlarmVolume = (1 - (Distance / FireAlarm.Size))
						-- If player is in a vehicle
						if IsPedInAnyVehicle(PlayerPedId(), false) then
							-- Get player vehicle class
							local VC = GetVehicleClass(GetVehiclePedIsIn(PlayerPedId()), false)
							-- If vehicle is not a motobike or a bicycle
							if VC ~= 8 or VC ~= 13 then
								-- Lower the alarm volume by 45%
								AlarmVolume = AlarmVolume * 0.45
							end
						end

						-- New NUI message
						SendNUIMessage({
							-- Tell NUI to set alarm volume
							PayloadType	= "SetAlarmVolume",
							-- Volume value
							Payload 	= AlarmVolume
						})
					-- If player is outside of range
					else
						-- New NUI message
						SendNUIMessage({
							-- Tell NUI to set alarm volume
							PayloadType	= "SetAlarmVolume",
							-- Volume value
							Payload		= 0
						})
					end
				end
			end
		end

		-- If panel not already in use and if E just pressed
		if not FirePanel.Enabled and IsControlJustReleased(0, 38) then
			-- Loop though all control panels
			for _, Panel in ipairs(FirePanel.ControlPanels) do
				-- Player position
				local PP = GetEntityCoords(PlayerPedId(), false)
				-- Panel position
				local CPP = vector3(Panel.x, Panel.y, Panel.z)
				-- Distance between player and panel
				local Distance = Vdist(PP.x, PP.y, PP.z, CPP.x, CPP.y, CPP.z)
				-- If player is face-to-face with panel
				if Distance < 1.7 then
					-- Send panel to server
					TriggerServerEvent("Fire-Panel:OpenPanel", Panel)
					-- Set enabled locally so it is not opened twice
					FirePanel.Open = true
				end
			end
		end

		if FirePanel.Active then
			-- Loop though all control panels
			for _, Panel in ipairs(FirePanel.ControlPanels) do
				-- If panel sounder is active, and active panel is this panel
				if FirePanel.Active and FirePanel.ActiveID == Panel.ID then
					-- Player position
					local PP = GetEntityCoords(PlayerPedId(), false)
					-- Panel position
					local CPP = vector3(Panel.x, Panel.y, Panel.z)
					-- Distance between player and control panel
					local Distance = Vdist(PP.x, PP.y, PP.z, CPP.x, CPP.y, CPP.z) + 0.01 -- Stops divide by 0 errors
					-- If distance between player and control panel is within range
					if (Distance <= FirePanel.Size) then
						-- New NUI message
						SendNUIMessage({
							-- Tell NUI to set sounder volume
							PayloadType	= "SetSounderVolume",
							-- Volume value
							Payload		= 1 - (Distance / FirePanel.Size)
						})
					-- If player out of range
					else
						-- New NUI message
						SendNUIMessage({
							-- Tell NUI to set sounder volume
							PayloadType	= "SetSounderVolume",
							-- Volume value
							Payload 	= 0
						})
					end
				end
			end
		end

	end
end)