--[[
    Umeverse Admin - Client
]]

local UME = exports['umeverse_core']:GetCoreObject()
local isPanelOpen = false
local isSpectating = false
local spectateTarget = nil

-- ═══════════════════════════════════════
-- Open Panel (rebindable via FiveM Settings > Key Bindings)
-- ═══════════════════════════════════════

RegisterCommand('+umeverse_admin', function()
    if UME.IsLoggedIn() then
        if isPanelOpen then
            ClosePanel()
        else
            TriggerServerEvent('umeverse_admin:server:openPanel')
        end
    end
end, false)
RegisterCommand('-umeverse_admin', function() end, false)
RegisterKeyMapping('+umeverse_admin', 'Open Admin Panel', 'keyboard', 'F7')

RegisterNetEvent('umeverse_admin:client:openPanel', function(data)
    isPanelOpen = true
    SetNuiFocus(true, true)
    SendNUIMessage({
        action = 'openPanel',
        data   = data,
    })
end)

function ClosePanel()
    isPanelOpen = false
    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'closePanel' })
end

-- ═══════════════════════════════════════
-- NUI Callbacks
-- ═══════════════════════════════════════

RegisterNUICallback('closePanel', function(_, cb)
    ClosePanel()
    cb('ok')
end)

RegisterNUICallback('adminAction', function(data, cb)
    TriggerServerEvent('umeverse_admin:server:action', data.action, data.data or {})
    cb('ok')
end)

-- ═══════════════════════════════════════
-- Spawn Vehicle (admin)
-- ═══════════════════════════════════════

RegisterNetEvent('umeverse_admin:client:spawnVehicle', function(model)
    local modelHash = GetHashKey(model)

    if not UME.LoadModel(modelHash) then
        TriggerEvent('umeverse:client:notify', 'Invalid vehicle model.', 'error')
        return
    end

    -- Delete current vehicle if in one
    local ped = PlayerPedId()
    local currentVeh = GetVehiclePedIsIn(ped, false)
    if currentVeh ~= 0 then
        DeleteEntity(currentVeh)
    end

    local coords = GetEntityCoords(ped)
    local heading = GetEntityHeading(ped)

    local vehicle = CreateVehicle(modelHash, coords.x, coords.y, coords.z, heading, true, false)
    SetVehicleEngineOn(vehicle, true, true, false)
    TaskWarpPedIntoVehicle(ped, vehicle, -1)
    SetModelAsNoLongerNeeded(modelHash)
    SetEntityAsMissionEntity(vehicle, true, true)
    SetVehicleNumberPlateText(vehicle, 'ADMIN')
    TriggerEvent('umeverse:client:notify', 'Spawned: ' .. model, 'success')
end)

-- ═══════════════════════════════════════
-- Despawn Vehicle
-- ═══════════════════════════════════════

RegisterNetEvent('umeverse_admin:client:despawnVehicle', function()
    local ped = PlayerPedId()
    local vehicle = GetVehiclePedIsIn(ped, false)
    if vehicle == 0 then
        vehicle = GetVehiclePedIsIn(ped, true)
    end
    if vehicle == 0 then
        -- Try closest vehicle
        local coords = GetEntityCoords(ped)
        vehicle = GetClosestVehicle(coords.x, coords.y, coords.z, 10.0, 0, 71)
    end
    if vehicle ~= 0 then
        SetEntityAsMissionEntity(vehicle, true, true)
        DeleteEntity(vehicle)
        TriggerEvent('umeverse:client:notify', 'Vehicle despawned.', 'success')
    else
        TriggerEvent('umeverse:client:notify', 'No vehicle found nearby.', 'error')
    end
end)

-- ═══════════════════════════════════════
-- Invisible
-- ═══════════════════════════════════════

local isInvisible = false

RegisterNetEvent('umeverse_admin:client:toggleInvisible', function()
    isInvisible = not isInvisible
    local ped = PlayerPedId()
    SetEntityVisible(ped, not isInvisible, false)
    TriggerEvent('umeverse:client:notify', isInvisible and 'You are now invisible.' or 'You are now visible.', 'info')
end)

-- ═══════════════════════════════════════
-- Set Weather (admin override)
-- ═══════════════════════════════════════

RegisterNetEvent('umeverse_admin:client:setWeather', function(weather)
    local weatherHash = GetHashKey(weather)
    SetWeatherTypeOverTime(weather, 15.0)
    Wait(15000)
    ClearWeatherTypePersist()
    SetWeatherTypePersist(weather)
    SetWeatherTypeNow(weather)
    SetWeatherTypeNowPersist(weather)
end)

-- ═══════════════════════════════════════
-- Set Time (admin override)
-- ═══════════════════════════════════════

RegisterNetEvent('umeverse_admin:client:setTime', function(hour, minute)
    NetworkOverrideClockTime(hour, minute or 0, 0)
end)

-- ═══════════════════════════════════════
-- Freeze Player
-- ═══════════════════════════════════════

local isFrozen = false

RegisterNetEvent('umeverse_admin:client:freezePlayer', function()
    isFrozen = not isFrozen
    FreezeEntityPosition(PlayerPedId(), isFrozen)
    TriggerEvent('umeverse:client:notify', isFrozen and 'You have been frozen.' or 'You have been unfrozen.', 'info')
end)

-- ═══════════════════════════════════════
-- Spectate
-- ═══════════════════════════════════════

RegisterNetEvent('umeverse_admin:client:spectatePlayer', function(targetId)
    if isSpectating then
        -- Stop spectating
        isSpectating = false
        local ped = PlayerPedId()
        SetEntityVisible(ped, true, false)
        SetEntityCollision(ped, true, true)
        FreezeEntityPosition(ped, false)
        NetworkSetInSpectatorMode(false, ped)
        TriggerEvent('umeverse:client:notify', 'Stopped spectating.', 'info')
    else
        -- Start spectating
        local targetPed = GetPlayerPed(GetPlayerFromServerId(targetId))
        if targetPed and DoesEntityExist(targetPed) then
            isSpectating = true
            spectateTarget = targetId
            local ped = PlayerPedId()
            SetEntityVisible(ped, false, false)
            SetEntityCollision(ped, false, false)
            FreezeEntityPosition(ped, true)

            local targetCoords = GetEntityCoords(targetPed)
            SetEntityCoords(ped, targetCoords.x, targetCoords.y, targetCoords.z, false, false, false, false)
            NetworkSetInSpectatorMode(true, targetPed)

            TriggerEvent('umeverse:client:notify', 'Spectating player ID: ' .. targetId, 'info')
        end
    end
end)
