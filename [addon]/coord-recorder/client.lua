local isRecording = false
local recordedCoords = {}
local lastRecordTime = 0
local recordCooldown = 500 -- ms cooldown between records to prevent spam

-- Help text display
local function ShowHelpText(text)
    BeginTextCommandDisplayHelp("STRING")
    AddTextComponentSubstringPlayerName(text)
    EndTextCommandDisplayHelp(0, false, true, -1)
end

-- Draw 3D text at position
local function DrawText3D(x, y, z, text)
    local onScreen, _x, _y = World3dToScreen2d(x, y, z)
    local playerCoords = GetEntityCoords(PlayerPedId())
    local distance = #(playerCoords - vector3(x, y, z))
    
    if onScreen then
        local scale = (1 / distance) * 2
        local fov = (1 / GetGameplayCamFov()) * 100
        scale = scale * fov
        
        if scale > 0.5 then scale = 0.5 end
        if scale < 0.2 then scale = 0.2 end
        
        SetTextScale(0.0, scale)
        SetTextFont(4)
        SetTextProportional(1)
        SetTextColour(255, 255, 255, 215)
        SetTextDropshadow(0, 0, 0, 0, 255)
        SetTextEdge(2, 0, 0, 0, 150)
        SetTextDropShadow()
        SetTextOutline()
        SetTextEntry("STRING")
        SetTextCentre(1)
        AddTextComponentString(text)
        DrawText(_x, _y)
    end
end

-- Draw marker at recorded positions
local function DrawRecordedMarkers()
    for i, coord in ipairs(recordedCoords) do
        -- Draw marker
        DrawMarker(
            28,                         -- Marker type (checkmark)
            coord.x, coord.y, coord.z - 0.9, -- Position
            0.0, 0.0, 0.0,              -- Direction
            0.0, 0.0, 0.0,              -- Rotation
            0.5, 0.5, 0.5,              -- Scale
            0, 200, 100, 150,           -- RGBA
            false, false, 2, false, nil, nil, false
        )
        
        -- Draw number above marker
        DrawText3D(coord.x, coord.y, coord.z + 0.5, tostring(i))
    end
end

-- Format coordinates for display
local function FormatCoordsList()
    local coordsList = {}
    for i, coord in ipairs(recordedCoords) do
        table.insert(coordsList, {
            index = i,
            x = math.floor(coord.x * 100) / 100,
            y = math.floor(coord.y * 100) / 100,
            z = math.floor(coord.z * 100) / 100,
            h = math.floor(coord.h * 100) / 100
        })
    end
    return coordsList
end

-- Generate different output formats
local function GenerateOutputFormats()
    local formats = {}
    
    -- Vector3 list
    local vec3List = {}
    for _, coord in ipairs(recordedCoords) do
        table.insert(vec3List, string.format("vector3(%.2f, %.2f, %.2f)", coord.x, coord.y, coord.z))
    end
    formats.vector3 = "{\n    " .. table.concat(vec3List, ",\n    ") .. "\n}"
    
    -- Vector4 list (with heading)
    local vec4List = {}
    for _, coord in ipairs(recordedCoords) do
        table.insert(vec4List, string.format("vector4(%.2f, %.2f, %.2f, %.2f)", coord.x, coord.y, coord.z, coord.h))
    end
    formats.vector4 = "{\n    " .. table.concat(vec4List, ",\n    ") .. "\n}"
    
    -- Table format
    local tableList = {}
    for _, coord in ipairs(recordedCoords) do
        table.insert(tableList, string.format("{x = %.2f, y = %.2f, z = %.2f, h = %.2f}", coord.x, coord.y, coord.z, coord.h))
    end
    formats.table = "{\n    " .. table.concat(tableList, ",\n    ") .. "\n}"
    
    -- JSON format
    local jsonList = {}
    for _, coord in ipairs(recordedCoords) do
        table.insert(jsonList, string.format('{"x": %.2f, "y": %.2f, "z": %.2f, "h": %.2f}', coord.x, coord.y, coord.z, coord.h))
    end
    formats.json = "[\n    " .. table.concat(jsonList, ",\n    ") .. "\n]"
    
    -- Simple coordinates (comma separated)
    local simpleList = {}
    for _, coord in ipairs(recordedCoords) do
        table.insert(simpleList, string.format("%.2f, %.2f, %.2f, %.2f", coord.x, coord.y, coord.z, coord.h))
    end
    formats.simple = table.concat(simpleList, "\n")
    
    return formats
end

-- Open the results NUI
local function OpenResultsUI()
    if #recordedCoords == 0 then
        TriggerEvent('chat:addMessage', {
            args = { '^1[Coord Recorder]', 'No coordinates were recorded!' }
        })
        return
    end
    
    local formats = GenerateOutputFormats()
    
    SendNUIMessage({
        action = "openResults",
        coords = FormatCoordsList(),
        formats = formats,
        count = #recordedCoords
    })
    
    SetNuiFocus(true, true)
end

-- Close NUI callback
RegisterNUICallback("closeUI", function(data, cb)
    SetNuiFocus(false, false)
    cb("ok")
end)

-- Clear and start new recording
RegisterNUICallback("startNew", function(data, cb)
    SetNuiFocus(false, false)
    recordedCoords = {}
    isRecording = true
    TriggerEvent('chat:addMessage', {
        args = { '^2[Coord Recorder]', 'Recording started! Press ~g~E~w~ to record locations, ~r~ESC~w~ to finish.' }
    })
    cb("ok")
end)

-- Start recording command
RegisterCommand('recordcoords', function()
    if isRecording then
        TriggerEvent('chat:addMessage', {
            args = { '^3[Coord Recorder]', 'Already recording! Press ESC to stop.' }
        })
        return
    end
    
    recordedCoords = {}
    isRecording = true
    
    TriggerEvent('chat:addMessage', {
        args = { '^2[Coord Recorder]', 'Recording started! Press ~g~E~w~ to record locations, ~r~ESC~w~ to finish.' }
    })
end, false)

-- Stop recording command
RegisterCommand('stoprecord', function()
    if not isRecording then
        TriggerEvent('chat:addMessage', {
            args = { '^3[Coord Recorder]', 'Not currently recording!' }
        })
        return
    end
    
    isRecording = false
    OpenResultsUI()
end, false)

-- View last recorded coords
RegisterCommand('viewcoords', function()
    if #recordedCoords == 0 then
        TriggerEvent('chat:addMessage', {
            args = { '^1[Coord Recorder]', 'No coordinates recorded yet! Use /recordcoords to start.' }
        })
        return
    end
    
    OpenResultsUI()
end, false)

-- Undo last recorded coordinate
RegisterCommand('undocoord', function()
    if not isRecording then
        TriggerEvent('chat:addMessage', {
            args = { '^3[Coord Recorder]', 'Not currently recording!' }
        })
        return
    end
    
    if #recordedCoords == 0 then
        TriggerEvent('chat:addMessage', {
            args = { '^3[Coord Recorder]', 'No coordinates to undo!' }
        })
        return
    end
    
    table.remove(recordedCoords)
    TriggerEvent('chat:addMessage', {
        args = { '^3[Coord Recorder]', 'Removed last coordinate. Total: ' .. #recordedCoords }
    })
end, false)

-- Main recording loop
CreateThread(function()
    while true do
        if isRecording then
            local playerPed = PlayerPedId()
            local coords = GetEntityCoords(playerPed)
            local heading = GetEntityHeading(playerPed)
            
            -- Draw recorded markers
            DrawRecordedMarkers()
            
            -- Show instructions
            ShowHelpText("Press ~INPUT_CONTEXT~ to record position\nPress ~INPUT_FRONTEND_CANCEL~ to finish\nRecorded: " .. #recordedCoords .. " points")
            
            -- Record on E key press
            if IsControlJustPressed(0, 38) then -- E key
                local currentTime = GetGameTimer()
                if currentTime - lastRecordTime > recordCooldown then
                    lastRecordTime = currentTime
                    
                    table.insert(recordedCoords, {
                        x = coords.x,
                        y = coords.y,
                        z = coords.z,
                        h = heading
                    })
                    
                    PlaySoundFrontend(-1, "SELECT", "HUD_FRONTEND_DEFAULT_SOUNDSET", true)
                    
                    TriggerEvent('chat:addMessage', {
                        args = { '^2[Coord Recorder]', 'Point ' .. #recordedCoords .. ' recorded!' }
                    })
                end
            end
            
            -- Stop recording on ESC
            if IsControlJustPressed(0, 200) then -- ESC key
                isRecording = false
                OpenResultsUI()
            end
            
            Wait(0)
        else
            Wait(500)
        end
    end
end)

-- Chat suggestions
TriggerEvent('chat:addSuggestion', '/recordcoords', 'Start recording coordinates')
TriggerEvent('chat:addSuggestion', '/stoprecord', 'Stop recording and show results')
TriggerEvent('chat:addSuggestion', '/viewcoords', 'View last recorded coordinates')
TriggerEvent('chat:addSuggestion', '/undocoord', 'Remove the last recorded coordinate')
