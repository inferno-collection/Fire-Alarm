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
Config.DefaultAlarmTones = {"fire", "rescue"}
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
-- The length of time in ms between panel screen changes
Config.ScreenLength = 3000

--
--		Nothing past this point needs to be edited, all the settings for the resource are found ABOVE this line.
--		Do not make changes below this line unless you know what you are doing!
--

-- Local Panel Variables
local FirePanel = {}
-- Open Panel on this client
FirePanel.Open = false
-- All alarm call points
FirePanel.CallPoints = {}
-- All alarm control panels
FirePanel.ControlPanels = {}
-- All sizes
FirePanel.Sizes = {}
-- Size around the announcements source the sounder can be heard
FirePanel.Sizes.Ann = Config.AnnSize
-- Size around the alarm source the alarm can be heard
FirePanel.Sizes.Alarm = Config.AlarmSize
-- Size around the sounder source the sounder can be heard
FirePanel.Sizes.Panel = Config.PanelSize

-- When the resource is started, so if the resource is restarted the client respawns the objects
AddEventHandler("onClientResourceStart", function(ResourceName)
	if(GetCurrentResourceName() == ResourceName) then
		TriggerServerEvent("Fire-Alarm:GetObjects")
	end
end)

-- Return of objects from server
RegisterNetEvent("Fire-Alarm:Return:GetObjects")
AddEventHandler("Fire-Alarm:Return:GetObjects", function(CallPoints, ControlPanels)
	-- Update local values with server ones
	FirePanel.CallPoints = CallPoints
	FirePanel.ControlPanels = ControlPanels

	for _, Channel in ipairs(FirePanel.CallPoints) do
		for _, Object in ipairs(Channel.Devices) do
			if Object.Prop ~= nil then
				local NewObject = CreateObjectNoOffset(GetHashKey(Object.Prop), vector3(Object.x, Object.y, Object.z), false, false, false)

				if NewObject then
					SetEntityRotation(NewObject, vector3(Object.rx, Object.ry, Object.rz), 2, true)
					FreezeEntityPosition(NewObject, true)
				else
					print("===================================================================")
					print("=============================ATTENTION=============================")
					print("Unable to create call point for Inferno-Fire-Alarm. Call point numb")
					print("er: " .. Object.ID .. " - This is non-fatal warn.")
					print("===================================================================")
				end
			else
				print("===================================================================")
				print("==============================Warning==============================")
				print("No prop found for a call point in Inferno-Fire-Alarm. Call point nu")
				print("mber: " .. Object.ID .. " - This is non-fatal warn.")
				print("===================================================================")
			end
		end
	end

	for _, Object in ipairs(FirePanel.ControlPanels) do
		if Object.Prop ~= nil then
			local NewObject = CreateObjectNoOffset(GetHashKey(Object.Prop), vector3(Object.x, Object.y, Object.z), false, false, false)

			if NewObject then
				SetEntityRotation(NewObject, vector3(Object.rx, Object.ry, Object.rz), 2, true)
				FreezeEntityPosition(NewObject, true)
			else
				print("===================================================================")
				print("=============================ATTENTION=============================")
				print("Unable to create control panel for Inferno-Fire-Alarm. Control pane")
				print("l number: " .. Object.ID .. " - This is non-fatal warn.")
				print("===================================================================")
			end
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
RegisterNetEvent("Fire-Alarm:Bouce:UpdateValues")
AddEventHandler("Fire-Alarm:Bouce:UpdateValues", function(Server)
	FirePanel.CallPoints = Server.CallPoints
	FirePanel.ControlPanels = Server.ControlPanels
end)

-- Start playing fire alarm and panel sounder
RegisterNetEvent("Fire-Alarm:Return:SetPulled")
AddEventHandler("Fire-Alarm:Return:SetPulled", function(CallPoint)
	SendNUIMessage({
		PayloadType	= "PlayAlarm",
		Payload		= CallPoint.Control
	})

	SendNUIMessage({
		PayloadType	= "PlaySounder",
		Payload		= CallPoint.Control
	})
end)

-- Play walktest audio for specific callpoint
RegisterNetEvent("Fire-Alarm:Return:StartWalkAround")
AddEventHandler("Fire-Alarm:Return:StartWalkAround", function(CallPoint)
	SendNUIMessage({
		PayloadType	= "WalkAround",
		Payload		= CallPoint
	})
end)

-- Open panel on this client
RegisterNetEvent("Fire-Panel:Return:OpenPanel")
AddEventHandler("Fire-Panel:Return:OpenPanel", function(Panel)
	-- Store the panel for easy access
	FirePanel.Open = Panel

	if FirePanel.Open.CurrentScreen == "access" then
		FirePanel.Open.ScreenText = {"access", FirePanel.Open.AccessLevel}
	end

	if not HasAnimDictLoaded("anim@amb@trailer@touch_screen@") then
		RequestAnimDict("anim@amb@trailer@touch_screen@")
		while not HasAnimDictLoaded("anim@amb@trailer@touch_screen@") do
			Citizen.Wait(0)
		end
	end

	local PlayerPed = PlayerPedId()

	TaskTurnPedToFaceCoord(PlayerPed, Panel.x, Panel.y, Panel.z, 0)
	TaskPlayAnim(PlayerPed, "anim@amb@trailer@touch_screen@", "idle_c", 8.0, -8, 0.01, 49, 0, 0, 0, 0)

	SetNuiFocus(true, true)
	OpenPanel(FirePanel.Open.CurrentScreen, FirePanel.Open.ScreenText)
end)

-- Play an annoucement from a panel
RegisterNetEvent("Fire-Panel:Return:Ann")
AddEventHandler("Fire-Panel:Return:Ann", function(Ann, Panel)
	FirePanel.ControlPanels[Panel].AnnActive = true
	if FirePanel.Open then FirePanel.Open.AnnActive = true end

	SendNUIMessage({
		PayloadType = Ann,
		Payload		= {Panel, math.random(0, 3)}
	})
end)

-- Unset annoucement as active
RegisterNUICallback("RemoveAnn", function(ID)
	FirePanel.ControlPanels[ID].AnnActive = false
	if FirePanel.Open then FirePanel.Open.AnnActive = false end
end)

-- Unset walk test as active
RegisterNUICallback("RemoveWalkTest", function(ID)
	FirePanel.ControlPanels[ID].Active = false
	if FirePanel.ControlPanels[ID].WalkAround == PlayerPedId() then TriggerServerEvent("Fire-Panel:ResetWalkTest", ID) end
end)

-- NUI call back for a button being pressed on panel
RegisterNUICallback("Button", function(Button)
	-- Used to compare at the end of the script
	local ScreenText = FirePanel.Open.ScreenText

	function ScreenChange(ID, Screen, Text)
		ID = ID or false
		Screen = Screen or false
		Text = Text or false

		if FirePanel.Open then ID = FirePanel.Open.ID end
		if FirePanel.Open and FirePanel.Open.CurrentScreen then Screen = FirePanel.Open.CurrentScreen end
		-- If the text has not be set to anything new, but the screen is changing, remove the old text
		if FirePanel.Open and ScreenText == FirePanel.Open.ScreenText then FirePanel.Open.ScreenText = {nil, nil} end
		if FirePanel.Open then Text = FirePanel.Open.ScreenText end
		if FirePanel.Open then OpenPanel(Screen, FirePanel.Open.ScreenText) end

		-- Update server screen values
		TriggerServerEvent("Fire-Panel:SetScreen", ID, Screen, Text)
	end

	if FirePanel.Open.CurrentScreen == "passcode" then
		if Button == "del" then
			-- Remove last entered number
			TriggerServerEvent("Fire-Panel:RemoveCode", FirePanel.Open.ID)
		elseif Button == "exit" then
			FirePanel.Open.CurrentScreen = "access"
			FirePanel.Open.ScreenText = {"access", FirePanel.Open.AccessLevel}
			ScreenChange()
		-- If button pressed is a number and panel is not signed in
		elseif tonumber(Button) and FirePanel.Open.AccessLevel ~= 3 then
			TriggerServerEvent("Fire-Panel:AddCode", FirePanel.Open.ID, Button)
		end

	elseif FirePanel.Open.CurrentScreen == "access" then
		local Number = tonumber(Button)
		-- If button pressed is a number
		if Number then
			-- If client wants to login
			if Number == 1 and FirePanel.Open.AccessLevel ~= 3 then
				FirePanel.Open.CurrentScreen = "passcode"
				ScreenChange()
			-- If client wants to logout
			elseif Number == 2 and FirePanel.Open.AccessLevel ~= 1 then
				TriggerServerEvent("Fire-Panel:SetAccessLevel", FirePanel.Open.ID, 1)
				FirePanel.Open.AccessLevel = 1
				FirePanel.Open.ScreenText = {"access", FirePanel.Open.AccessLevel}
				ScreenChange()
			end
		elseif Button == "exit" then
			FirePanel.Open.CurrentScreen = "menu1"
			ScreenChange()
		end

	elseif Button == "ack" then
		if FirePanel.Open.CurrentScreen == "fire" then
			FirePanel.Open.CurrentScreen = "gack"
			if FirePanel.Open then OpenPanel(FirePanel.Open.CurrentScreen, FirePanel.Open.ScreenText) end
			TriggerServerEvent("Fire-Panel:SetScreen", FirePanel.Open.ID, FirePanel.Open.CurrentScreen, FirePanel.Open.ScreenText)

			Citizen.Wait(Config.ScreenLength)

			FirePanel.Open.CurrentScreen = "ack"
			FirePanel.Open.ScreenText = {"location", FirePanel.Open.ActiveLoc}
			ScreenChange()
		end

	-- If button is silence or reset button (they do nearly the same thing)
	elseif Button == "sil" or Button == "res" then
		if FirePanel.Open.CurrentScreen == "ack" then
			-- Set current screen to button name (they share names)
			FirePanel.Open.CurrentScreen = Button
			FirePanel.Open.ScreenText = {nil, nil}
			if FirePanel.Open then OpenPanel(FirePanel.Open.CurrentScreen, FirePanel.Open.ScreenText) end

			TriggerServerEvent("Fire-Panel:SetScreen", FirePanel.Open.ID, FirePanel.Open.CurrentScreen, FirePanel.Open.ScreenText)
			TriggerServerEvent("Fire-Alarm:ResetAllCalls", FirePanel.Open.ID)
			TriggerServerEvent("Fire-Alarm:ResetAlarm", FirePanel.Open.ID)

			Citizen.Wait(20000)

			if FirePanel.Open.CurrentScreen == "res" then
				FirePanel.Open.CurrentScreen = "resc"

				if FirePanel.Open then OpenPanel(FirePanel.Open.CurrentScreen, FirePanel.Open.ScreenText) end

				TriggerServerEvent("Fire-Panel:SetScreen", FirePanel.Open.ID, FirePanel.Open.CurrentScreen, FirePanel.Open.ScreenText)

				FirePanel.Open.CurrentScreen = "sysnormal"
				FirePanel.Open.ScreenText = {nil, nil}
			else
				FirePanel.Open.CurrentScreen = "ack"
				FirePanel.Open.ScreenText = ScreenText
				ScreenText = {nil, nil}
			end

			Citizen.Wait(Config.ScreenLength)
			ScreenChange()
		end

	elseif Button == "prev" then
		if FirePanel.Open.CurrentScreen == "menu1" and FirePanel.Open.AccessLevel == 3 then
			FirePanel.Open.CurrentScreen = "menu4"
			ScreenChange()
		elseif FirePanel.Open.CurrentScreen == "menu4" and FirePanel.Open.AccessLevel == 3 then
			FirePanel.Open.CurrentScreen = "menu3"
			ScreenChange()
		elseif FirePanel.Open.CurrentScreen == "menu3" and FirePanel.Open.AccessLevel == 3 then
			FirePanel.Open.CurrentScreen = "menu2"
			ScreenChange()
		elseif FirePanel.Open.CurrentScreen == "menu2" and FirePanel.Open.AccessLevel == 3 then
			FirePanel.Open.CurrentScreen = "menu1"
			ScreenChange()
		end

	elseif Button == "next" then
		if FirePanel.Open.CurrentScreen == "menu1" and FirePanel.Open.AccessLevel == 3 then
			FirePanel.Open.CurrentScreen = "menu2"
			ScreenChange()
		elseif FirePanel.Open.CurrentScreen == "menu2" and FirePanel.Open.AccessLevel == 3 then
			FirePanel.Open.CurrentScreen = "menu3"
			ScreenChange()
		elseif FirePanel.Open.CurrentScreen == "menu3" and FirePanel.Open.AccessLevel == 3 then
			FirePanel.Open.CurrentScreen = "menu4"
			ScreenChange()
		elseif FirePanel.Open.CurrentScreen == "menu4" and FirePanel.Open.AccessLevel == 3 then
			FirePanel.Open.CurrentScreen = "menu1"
			ScreenChange()
		end

	elseif Button == "exit" then
		if FirePanel.Open.CurrentScreen == "menu1" or
		FirePanel.Open.CurrentScreen == "menu2" or
		FirePanel.Open.CurrentScreen == "menu3" or
		FirePanel.Open.CurrentScreen == "menu4" then
			FirePanel.Open.CurrentScreen = "sysnormal"
			ScreenChange()
		elseif FirePanel.Open.CurrentScreen == "walktest" then
			FirePanel.Open.CurrentScreen = "menu4"
			ScreenChange()
		end

	elseif Button == "ent" then
		if FirePanel.Open.CurrentScreen == "menu1" then
			FirePanel.Open.CurrentScreen = "access"
			FirePanel.Open.ScreenText = {"access", FirePanel.Open.AccessLevel}
			ScreenChange()
		elseif FirePanel.Open.CurrentScreen == "menu2" then
			-- If fire panel announcement is not already playing
			if not FirePanel.Open.AnnActive then
				-- Play announcement
				TriggerServerEvent("Fire-Panel:Ann", "PlayAnn", FirePanel.Open.ID)

				FirePanel.Open.CurrentScreen = "sysnormal"
				ScreenChange()
			end
		elseif FirePanel.Open.CurrentScreen == "menu3" then
			-- If fire panel announcement is not already playing
			if not FirePanel.Open.AnnActive then
				-- Play announcement
				TriggerServerEvent("Fire-Panel:Ann", "PlayClear", FirePanel.Open.ID)

				FirePanel.Open.CurrentScreen = "sysnormal"
				ScreenChange()
			end
		elseif FirePanel.Open.CurrentScreen == "menu4" then
			-- Collected up here in case the player closes the panel during the wait
			local PlayerPed = PlayerPedId()
			local PanelID = FirePanel.Open.ID

			-- If panel is not already in walk test mode
			if not FirePanel.Open.WalkAround then
				FirePanel.Open.CurrentScreen = "walktestupdating"
				FirePanel.Open.ScreenText = {nil, nil}

				if FirePanel.Open then OpenPanel(FirePanel.Open.CurrentScreen, FirePanel.Open.ScreenText) end

				TriggerServerEvent("Fire-Panel:SetScreen", FirePanel.Open.ID, FirePanel.Open.CurrentScreen, FirePanel.Open.ScreenText)

				Citizen.Wait(5000)

				-- Something unique to this client
				if FirePanel.Open then FirePanel.Open.WalkAround = PlayerPed end

				TriggerServerEvent("Fire-Panel:SetWalkAround", PanelID, PlayerPed)

				if FirePanel.Open then FirePanel.Open.CurrentScreen = "walktest" end
				ScreenChange(PanelID, "walktest", {nil, nil})
			else
				FirePanel.Open.CurrentScreen = "walktestupdating"
				FirePanel.Open.ScreenText = {nil, nil}

				if FirePanel.Open then OpenPanel(FirePanel.Open.CurrentScreen, FirePanel.Open.ScreenText) end

				TriggerServerEvent("Fire-Panel:SetScreen", FirePanel.Open.ID, FirePanel.Open.CurrentScreen, FirePanel.Open.ScreenText)

				Citizen.Wait(10000)

				if FirePanel.Open then FirePanel.Open.WalkAround = false end

				TriggerServerEvent("Fire-Panel:SetWalkAround", FirePanel.Open.ID, FirePanel.Open.WalkAround)

				if FirePanel.Open then FirePanel.Open.CurrentScreen = "walktestcomplete" end
				if FirePanel.Open then FirePanel.Open.ScreenText = {nil, nil} end
				if FirePanel.Open then OpenPanel(FirePanel.Open.CurrentScreen, FirePanel.Open.ScreenText) end

				TriggerServerEvent("Fire-Panel:SetScreen", PanelID, "walktestcomplete", PlayerPed)

				Citizen.Wait(3000)

				if FirePanel.Open then FirePanel.Open.CurrentScreen = "sysnormal" end
				ScreenChange(PanelID, "sysnormal", {nil, nil})
			end
		end

	elseif Button == "menu" then
		if FirePanel.Open.CurrentScreen == "sysnormal" then
			FirePanel.Open.CurrentScreen = "menu1"
			ScreenChange()
		end
	end
end)

-- Close open fire panel
RegisterNUICallback("ClosePanel", function()
	FirePanel.ControlPanels[FirePanel.Open.ID].Open = false
	FirePanel.ControlPanels[FirePanel.Open.ID].CurrentScreen = FirePanel.Open.CurrentScreen
	FirePanel.ControlPanels[FirePanel.Open.ID].ScreenText = FirePanel.Open.ScreenText
	FirePanel.Open = nil

	TriggerServerEvent("Fire-Panel:UpdateAllClients", FirePanel)
	SendNUIMessage({
		PayloadType = "ClosePanel"
	})
	SetNuiFocus(false, false)
	StopAnimTask(PlayerPedId(), "anim@amb@trailer@touch_screen@", "idle_c", 1.0)
end)

-- Add code to entered codes
RegisterNetEvent("Fire-Panel:Return:AddCode")
AddEventHandler("Fire-Panel:Return:AddCode", function(Length)
	if Length == 1 then
		FirePanel.Open.ScreenText = {"passcode", "X"}
	elseif Length == 2 then
		FirePanel.Open.ScreenText = {"passcode", "XX"}
	elseif Length == 3 then
		FirePanel.Open.ScreenText = {"passcode", "XXX"}
	end

	OpenPanel(FirePanel.Open.CurrentScreen, FirePanel.Open.ScreenText)

	-- If final code is entered
	if Length == 3 then
		Citizen.Wait(300)
		TriggerServerEvent("Fire-Panel:CheckCode", FirePanel.Open.ID)
	end
end)

-- Remove last entered code
RegisterNetEvent("Fire-Panel:Return:RemoveCode")
AddEventHandler("Fire-Panel:Return:RemoveCode", function(Length)
	if Length == 1 then
		FirePanel.Open.ScreenText = {"passcode", "X"}
	elseif Length == 2 then
		FirePanel.Open.ScreenText = {"passcode", "XX"}
	end

	OpenPanel(FirePanel.Open.CurrentScreen, FirePanel.Open.ScreenText)
end)

-- Return for check code
RegisterNetEvent("Fire-Panel:Return:CheckCode")
AddEventHandler("Fire-Panel:Return:CheckCode", function(Success)
	-- If entered code is correct
	if Success then
		TriggerServerEvent("Fire-Panel:SetAccessLevel", FirePanel.Open.ID, 3)

		FirePanel.Open.ScreenText = {"message", "ACCESS GRANTED"}
		FirePanel.Open.AccessLevel = 3
	-- If entered code is incorrect
	else
		FirePanel.Open.ScreenText = {"message", "ACCESS  DENIED"}
	end

	OpenPanel(FirePanel.Open.CurrentScreen, FirePanel.Open.ScreenText)

	Citizen.Wait(2000)

	FirePanel.Open.CurrentScreen = "access"
	FirePanel.Open.ScreenText = {"access", FirePanel.Open.AccessLevel}

	OpenPanel(FirePanel.Open.CurrentScreen, FirePanel.Open.ScreenText)

	TriggerServerEvent("Fire-Panel:SetScreen", FirePanel.Open.ID, FirePanel.Open.CurrentScreen)
end)

-- Stop a playing fire alarm
RegisterNetEvent("Fire-Alarm:Bouce:ResetAlarm")
AddEventHandler("Fire-Alarm:Bouce:ResetAlarm", function(ID)
	SendNUIMessage({
		PayloadType	= "StopAlarm",
		Payload		= ID
	})
end)

-- Gets the distance between the player and the provided coords
function GetDistanceBetween(Coords)
	return Vdist(GetEntityCoords(PlayerPedId(), false), Coords.x, Coords.y, Coords.z) + 0.01
end

-- Updates NUI with open panel payload with supplied parameters
function OpenPanel(Screen, Text)
	Text = Text or {nil, nil}
	SendNUIMessage({
		PayloadType	= "OpenPanel",
		Payload		= {Screen, Text}
	})
end

-- Resource master loop
Citizen.CreateThread(function()
	while true do
		Citizen.Wait(0)

		local NeedToBreak = false

		for _, Panel in ipairs(FirePanel.ControlPanels) do
			if NeedToBreak then break end

			if not Panel.Open then
				-- Placed inside this If statment so distance checking is not being done every tick
				if GetDistanceBetween(Panel) < 1.7 and IsControlJustReleased(0, 38) then
					TriggerServerEvent("Fire-Panel:OpenPanel", Panel)
					-- Set enabled locally so it is not opened twice
					Panel.Open = true
					NeedToBreak = true
				end
			end

			if NeedToBreak then break end

			if not Panel.Active and IsControlJustReleased(0, 38) then
				for _, Channel in ipairs(FirePanel.CallPoints) do
					if NeedToBreak then break end

					for _, CallPoint in ipairs(Channel.Devices) do
						if NeedToBreak then break end

						if not CallPoint.Pulled then
							if GetDistanceBetween(CallPoint) <= 1.0 then
								-- Set point to pulled to avoid setting twice
								CallPoint.Pulled = true

								if not HasAnimDictLoaded("anim@mp_radio@low_apment") then
									RequestAnimDict("anim@mp_radio@low_apment")
									while not HasAnimDictLoaded("anim@mp_radio@low_apment") do
										Citizen.Wait(0)
									end
								end

								local PlayerPed = PlayerPedId()

								TaskTurnPedToFaceCoord(PlayerPed, CallPoint.x, CallPoint.y, CallPoint.z, 0)
								Citizen.Wait(500)
								TaskPlayAnim(PlayerPed, "anim@mp_radio@low_apment", "button_press_kitchen", 8.0, -8, 0.01, 49, 0, 0, 0, 0)
								Citizen.Wait(500)
								StopAnimTask(PlayerPed, "anim@mp_radio@low_apment", "button_press_kitchen", 1.0)

								-- If the panel is not in walk test mode
								if not Panel.WalkAround then
									TriggerServerEvent("Fire-Alarm:SetPulled", CallPoint)

									-- If pager intergation enabled
									if Config.EnablePager then
										local Street, CrossStreet = GetStreetNameAtCoord(Panel.x, Panel.y, Panel.z)
										local DetailsArray = {}
										local Details

										if CrossStreet ~= 0 then
											Details = "Box Alarm - " .. GetStreetNameFromHashKey(Street) .. " X " .. GetStreetNameFromHashKey(CrossStreet)
										else
											Details = "Box Alarm - " .. GetStreetNameFromHashKey(Street)
										end

										for w in Details:gmatch("%S+") do table.insert(DetailsArray, w) end

										if Panel.AlarmTones then
											TriggerServerEvent("Fire-EMS-Pager:PageTones", Panel.AlarmTones, true, DetailsArray)
										else
											TriggerServerEvent("Fire-EMS-Pager:PageTones", Config.DefaultAlarmTones, true, DetailsArray)
										end
									end
								else
									TriggerServerEvent("Fire-Alarm:WalkAround", CallPoint)
								end

								NeedToBreak = true
							end
						end
					end
				end

			elseif Panel.Active then
				local Distance = GetDistanceBetween(Panel)

				if (Distance <= FirePanel.Sizes.Alarm) then
					local AlarmVolume = (1 - (Distance / FirePanel.Sizes.Alarm))

					if IsPedInAnyVehicle(PlayerPedId(), false) then
						local VC = GetVehicleClass(GetVehiclePedIsIn(PlayerPedId()), false)

						-- If vehicle is not a motobike or a bicycle
						if VC ~= 8 or VC ~= 13 then
							-- Lower the alarm volume by 45%
							AlarmVolume = AlarmVolume * 0.45
						end
					end

					SendNUIMessage({
						PayloadType	= "SetAlarmVolume",
						Payload 	= {Panel.ID, AlarmVolume}
					})
				-- If player is outside of range
				else
					SendNUIMessage({
						PayloadType	= "SetAlarmVolume",
						Payload		= {Panel.ID, 0}
					})
				end

				if (Distance <= FirePanel.Sizes.Panel) then
					SendNUIMessage({
						PayloadType	= "SetSounderVolume",
						Payload		= {Panel.ID, 1 - (Distance / FirePanel.Sizes.Panel)}
					})
				-- If player out of range
				else
					SendNUIMessage({
						PayloadType	= "SetSounderVolume",
						Payload 	= {Panel.ID, 0}
					})
				end

			elseif Panel.AnnActive then
				local Distance = GetDistanceBetween(Panel)

				if (Distance <= FirePanel.Sizes.Ann) then
                    SendNUIMessage({
						PayloadType	= "SetAnnVolume",
                        Payload		= {Panel.ID, 1 - (Distance / FirePanel.Sizes.Ann)}
					})
				-- If player out of range
				else
                    SendNUIMessage({
						PayloadType	= "SetAnnVolume",
                        Payload		= {Panel.ID, 0}
                    })
				end
			end
		end

	end
end)