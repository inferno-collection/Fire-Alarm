-- Inferno Collection Fire Alarm Version 4.5 BETA
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

    -- Loop though all the panels
	for _, Panel in ipairs(ControlPanels) do
		-- Attempt to create a new panel
        local NewControlPanel = CreateObjectNoOffset(GetHashKey(Panel.Prop), vector3(Panel.x, Panel.y, Panel.z), false, false, false)
        -- Add new panel into array for later
        table.insert(Objects.ControlPanels, NewControlPanel)

		-- If successful in creating new call points
        if NewControlPanel then
            -- Set object rotation
            SetEntityRotation(NewControlPanel, vector3(Panel.rx, Panel.ry, Panel.rz), 2, true)
            -- Freeze object in place
            FreezeEntityPosition(NewControlPanel, true)
        -- If unable to create object
        else
            -- Print error to console
            print("Error creating control panel number " .. Panel.ID)
            -- Inform User
            NewNoti("~r~Error creating control panel number " .. Panel.ID, true)
		end
	end

    -- Loop though all the call points
	for _, CallPoint in ipairs(CallPoints) do
		-- Attempt to create a new call points
        local NewCallPoint = CreateObjectNoOffset(GetHashKey(CallPoint.Prop), vector3(CallPoint.x, CallPoint.y, CallPoint.z), false, false, false)
        -- Add new panel into array for later
        table.insert(Objects.CallPoints, NewCallPoint)

		-- If successful in creating new call points
        if NewCallPoint then
             -- Set object rotation
            SetEntityRotation(NewCallPoint, vector3(CallPoint.rx, CallPoint.ry, CallPoint.rz), 2, true)
            -- Freeze object in place
            FreezeEntityPosition(NewCallPoint, true)
        -- If unable to create object
        else
            -- Print error to console
            print("Error creating call point number " .. CallPoint.ID)
            -- Inform User
            NewNoti("~r~Error creating call point number " .. CallPoint.ID, true)
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