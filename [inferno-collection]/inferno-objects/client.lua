-- Inferno Collection Fire Alarm Version 4.6 ALPHA
--
-- Copyright (c) 2019, Christopher M, Inferno Collection. All rights reserved.
--
-- This project is licensed under the following:
-- Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to use, copy, modify, and merge the software, under the following conditions:
-- The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. THE SOFTWARE MAY NOT BE SOLD.
--

-- Used for JSON Data
local ControlPanels = {}
local CallPoints = {}
-- Used for GTA Objects
local Objects = {}
Objects.Data = false
Objects.ControlPanels = {}
Objects.CallPoints = {}

-- Place objects command
RegisterCommand("objects", function()
    -- Load JSON file
    Objects.Data = LoadResourceFile(GetCurrentResourceName(), "control-panels.json")
    -- If able to load JSON file
    if Objects.Data then
        -- Turn the JSON into LUA Array
        ControlPanels = json.decode(Objects.Data)
    -- If unable to load JSON file
    else
        -- Print error message to console
        print("===================================================================")
        print("==============================WARNING==============================")
        print("Unable to load control-panels.json file for Inferno-Objects. The re")
        print("source will not function correctly. Please correct this issue and r")
        print("estart the resource.")
        print("===================================================================")
        -- Inform User
        NewNoti("~r~Unable to load control-panels.json. Press F8 for details.", true)
    end

    -- Load JSON file
    Objects.Data = LoadResourceFile(GetCurrentResourceName(), "call-points.json")
    -- If able to load JSON file
    if Objects.Data then
        -- Turn the JSON into LUA Array
        CallPoints = json.decode(Objects.Data)
    -- If unable to load json file
    else
        -- Print error message to console
        print("===================================================================")
        print("==============================WARNING==============================")
        print("Unable to load call-points.json file for Inferno-Objects. The resou")
        print("rce will not function correctly. Please correct this issue and rest")
        print("art the resource.")
        print("===================================================================")
        -- Inform User
        NewNoti("~r~Unable to load call-points.json. Press F8 for details.", true)
    end

    -- Loop though all channels
	for _, Channel in ipairs(CallPoints) do
		-- Loop though all call points
		for _, Object in ipairs(Channel.Devices) do
			-- Check if there is an object
			if Object.Prop ~= nil then
				-- Attempt to create a new object
                local NewObject = CreateObjectNoOffset(GetHashKey(Object.Prop), vector3(Object.x, Object.y, Object.z), false, false, false)

                table.insert(Objects.CallPoints, NewObject)

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
					print("Unable to create call point for Inferno-Objects. Call point number:")
					print(Object.ID .. " - This is non-fatal warn.")
					print("===================================================================")
				end
			-- If there is no object
			else
				print("===================================================================")
				print("==============================Warning==============================")
				print("No prop found for a call point in Inferno-Objects. Call point")
				print("number: " .. Object.ID .. " - This is non-fatal warn.")
				print("===================================================================")
			end
		end
	end

	-- Loop though all call points
	for _, Object in ipairs(ControlPanels) do
		-- Check if there is an object
		if Object.Prop ~= nil then
			-- Attempt to create a new object
            local NewObject = CreateObjectNoOffset(GetHashKey(Object.Prop), vector3(Object.x, Object.y, Object.z), false, false, false)

            table.insert(Objects.ControlPanels, NewObject)

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
				print("Unable to create control panel for Inferno-Objects. Control panel")
				print("number: " .. Object.ID .. " - This is non-fatal warn.")
				print("===================================================================")
			end
		-- If there is no object
		else
			print("===================================================================")
			print("==============================Warning==============================")
			print("No prop found for a control panel in Inferno-Objects. Control panel")
			print("number: " .. Object.ID .. " - This is non-fatal warn.")
			print("===================================================================")
		end
	end
    -- Remind user to clear array
    NewNoti("~g~Remember to run /delobjects before restarting script!", true)
end)

-- Delete objects command
RegisterCommand("delobjects", function()
    -- Loop though all the panels
    for _, Panel in ipairs(Objects.ControlPanels) do
        -- Delete object
        DeleteObject(Panel)
    end

    -- Loop though all the call points
    for _, CallPoint in ipairs(Objects.CallPoints) do
        -- Delete object
        DeleteObject(CallPoint)
    end
end)

-- Draws notification on client's screen
function NewNoti(Text, Flash)
	-- Tell GTA that a string will be passed
	SetNotificationTextEntry("STRING")
	-- Pass temporary variable to notification
	AddTextComponentString(Text)
	-- Draw new notification on client's screen
	DrawNotification(Flash, true)
end