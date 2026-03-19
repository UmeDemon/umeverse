--[[
    Umeverse Framework - Client Functions
    Utility functions for the client side
]]

local noclipEnabled = false
local godModeEnabled = false
local noclipCam = nil

-- ═══════════════════════════════════════
-- Notifications
-- ═══════════════════════════════════════

--- Show a notification via NUI
RegisterNetEvent('umeverse:client:notify', function(message, type, duration)
    SendNUIMessage({
        action   = 'notify',
        message  = message,
        type     = type or 'info',
        duration = duration or 5000,
    })
end)

-- ═══════════════════════════════════════
-- Teleport
-- ═══════════════════════════════════════

RegisterNetEvent('umeverse:client:teleport', function(x, y, z)
    local ped = PlayerPedId()
    SetEntityCoords(ped, x, y, z, false, false, false, false)
    FreezeEntityPosition(ped, false)
end)

RegisterNetEvent('umeverse:client:teleportToWaypoint', function()
    local waypoint = GetFirstBlipInfoId(8)
    if not DoesBlipExist(waypoint) then
        TriggerEvent('umeverse:client:notify', 'No waypoint set.', 'error')
        return
    end

    local coords = GetBlipInfoIdCoord(waypoint)
    local ped = PlayerPedId()

    -- Load collision at target area first
    RequestCollisionAtCoord(coords.x, coords.y, 100.0)
    Wait(500)

    -- Find ground Z by probing from high to low
    local found = false
    local z = 200.0
    for height = 1000.0, 1.0, -25.0 do
        SetEntityCoordsNoOffset(ped, coords.x, coords.y, height, false, false, false)
        Wait(50)
        local success, groundZ = GetGroundZFor_3dCoord(coords.x, coords.y, height, false)
        if success then
            z = groundZ
            found = true
            break
        end
    end

    if not found then z = 200.0 end
    SetEntityCoords(ped, coords.x, coords.y, z + 1.0, false, false, false, false)
    TriggerEvent('umeverse:client:notify', _T('admin_teleported'), 'success')
end)

-- ═══════════════════════════════════════
-- Noclip
-- ═══════════════════════════════════════

RegisterNetEvent('umeverse:client:toggleNoclip', function()
    noclipEnabled = not noclipEnabled

    if noclipEnabled then
        TriggerEvent('umeverse:client:notify', _T('admin_noclip_on'), 'info')
        local ped = PlayerPedId()
        SetEntityVisible(ped, false, false)
        SetEntityCollision(ped, false, false)
        FreezeEntityPosition(ped, true)
        SetEntityInvincible(ped, true)

        -- Noclip movement thread
        CreateThread(function()
            local speed = 1.0
            while noclipEnabled do
                Wait(0)
                local ped = PlayerPedId()
                local coords = GetEntityCoords(ped)
                local fwd = GetEntityForwardVector(ped)
                local heading = GetEntityHeading(ped)

                -- Speed control
                if IsControlPressed(0, 21) then -- Left Shift
                    speed = 3.0
                elseif IsControlPressed(0, 36) then -- Left Ctrl
                    speed = 0.3
                else
                    speed = 1.0
                end

                -- Move forward/back
                if IsControlPressed(0, 32) then -- W
                    coords = coords + fwd * speed
                end
                if IsControlPressed(0, 33) then -- S
                    coords = coords - fwd * speed
                end

                -- Move up/down
                if IsControlPressed(0, 44) then -- Q (up)
                    coords = vector3(coords.x, coords.y, coords.z + speed * 0.5)
                end
                if IsControlPressed(0, 20) then -- Z (down)
                    coords = vector3(coords.x, coords.y, coords.z - speed * 0.5)
                end

                -- Turn left/right
                if IsControlPressed(0, 34) then -- A
                    heading = heading + 2.0
                end
                if IsControlPressed(0, 35) then -- D
                    heading = heading - 2.0
                end

                SetEntityCoordsNoOffset(ped, coords.x, coords.y, coords.z, false, false, false)
                SetEntityHeading(ped, heading)
            end
        end)
    else
        TriggerEvent('umeverse:client:notify', _T('admin_noclip_off'), 'info')
        local ped = PlayerPedId()
        SetEntityVisible(ped, true, false)
        SetEntityCollision(ped, true, true)
        FreezeEntityPosition(ped, false)
        SetEntityInvincible(ped, false)
    end
end)

-- ═══════════════════════════════════════
-- God Mode
-- ═══════════════════════════════════════

RegisterNetEvent('umeverse:client:toggleGodMode', function()
    godModeEnabled = not godModeEnabled
    local ped = PlayerPedId()
    SetEntityInvincible(ped, godModeEnabled)

    if godModeEnabled then
        TriggerEvent('umeverse:client:notify', _T('admin_godmode_on'), 'info')
    else
        TriggerEvent('umeverse:client:notify', _T('admin_godmode_off'), 'info')
    end
end)

-- ═══════════════════════════════════════
-- Utility Functions
-- ═══════════════════════════════════════

--- Draw 3D text in world
---@param coords vector3
---@param text string
function UME.Draw3DText(coords, text)
    local onScreen, x, y = World3dToScreen2d(coords.x, coords.y, coords.z)
    if onScreen then
        SetTextScale(0.35, 0.35)
        SetTextFont(4)
        SetTextProportional(true)
        SetTextColour(255, 255, 255, 215)
        SetTextDropshadow(0, 0, 0, 0, 255)
        SetTextEdge(2, 0, 0, 0, 150)
        SetTextDropShadow()
        SetTextOutline()
        SetTextEntry('STRING')
        SetTextCentre(true)
        AddTextComponentString(text)
        DrawText(x, y)
    end
end

--- Show help text at top left
---@param text string
function UME.ShowHelpText(text)
    BeginTextCommandDisplayHelp('STRING')
    AddTextComponentSubstringPlayerName(text)
    EndTextCommandDisplayHelp(0, false, true, -1)
end

--- Get closest vehicle
---@param coords vector3|nil
---@param maxDistance number|nil
---@return number, number -- entity, distance
function UME.GetClosestVehicle(coords, maxDistance)
    coords = coords or GetEntityCoords(PlayerPedId())
    maxDistance = maxDistance or 5.0
    local vehicles = GetGamePool('CVehicle')
    local closestVeh = -1
    local closestDist = maxDistance

    for _, veh in ipairs(vehicles) do
        local vehCoords = GetEntityCoords(veh)
        local dist = #(coords - vehCoords)
        if dist < closestDist then
            closestDist = dist
            closestVeh = veh
        end
    end

    return closestVeh, closestDist
end

--- Get closest player ped
---@param maxDistance number|nil
---@return number, number -- serverId, distance
function UME.GetClosestPlayer(maxDistance)
    maxDistance = maxDistance or 3.0
    local myPed = PlayerPedId()
    local myCoords = GetEntityCoords(myPed)
    local closestPlayer = -1
    local closestDist = maxDistance

    for _, playerId in ipairs(GetActivePlayers()) do
        if playerId ~= PlayerId() then
            local targetPed = GetPlayerPed(playerId)
            local targetCoords = GetEntityCoords(targetPed)
            local dist = #(myCoords - targetCoords)
            if dist < closestDist then
                closestDist = dist
                closestPlayer = GetPlayerServerId(playerId)
            end
        end
    end

    return closestPlayer, closestDist
end

--- Load a model with timeout
---@param model number|string
---@return boolean
function UME.LoadModel(model)
    if type(model) == 'string' then
        model = GetHashKey(model)
    end

    if not IsModelValid(model) then return false end
    if HasModelLoaded(model) then return true end

    RequestModel(model)
    local timeout = 5000
    while not HasModelLoaded(model) and timeout > 0 do
        Wait(10)
        timeout = timeout - 10
    end

    return HasModelLoaded(model)
end

--- Load an animation dictionary
---@param dict string
---@return boolean
function UME.LoadAnimDict(dict)
    if HasAnimDictLoaded(dict) then return true end

    RequestAnimDict(dict)
    local timeout = 5000
    while not HasAnimDictLoaded(dict) and timeout > 0 do
        Wait(10)
        timeout = timeout - 10
    end

    return HasAnimDictLoaded(dict)
end

--- Load a particle effects asset
---@param asset string
---@return boolean
function UME.LoadPtfx(asset)
    if HasNamedPtfxAssetLoaded(asset) then return true end

    RequestNamedPtfxAsset(asset)
    local timeout = 5000
    while not HasNamedPtfxAssetLoaded(asset) and timeout > 0 do
        Wait(10)
        timeout = timeout - 10
    end

    return HasNamedPtfxAssetLoaded(asset)
end

--- Use an item (triggers server callback)
---@param itemName string
function UME.UseItem(itemName)
    TriggerServerEvent('umeverse:server:useItem:' .. itemName)
end

-- ═══════════════════════════════════════
-- Compatibility Layer (QBCore / TMC style)
-- Maps TMC.Functions.* calls to UME.* equivalents
-- ═══════════════════════════════════════
UME.Functions.TriggerServerCallback = UME.TriggerServerCallback
UME.Functions.TriggerCallback = UME.TriggerServerCallback
UME.Functions.Notify = function(data, ...)
    if type(data) == 'table' then
        TriggerEvent('umeverse:client:notify', data.message or '', data.notifType or data.type or 'info', data.duration or 5000)
    else
        TriggerEvent('umeverse:client:notify', tostring(data), ...)
    end
end
UME.Functions.UseItem = UME.UseItem
UME.Functions.GetPlayerData = function()
    return exports['umeverse_core']:GetPlayerData()
end
