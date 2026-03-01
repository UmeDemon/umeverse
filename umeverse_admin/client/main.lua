--[[
    Umeverse Admin - Client
]]

local UME = exports['umeverse_core']:GetCoreObject()
local isPanelOpen = false
local isSpectating = false
local spectateTarget = nil

-- ═══════════════════════════════════════
-- Open Panel
-- ═══════════════════════════════════════

CreateThread(function()
    while true do
        Wait(0)
        if UME.IsLoggedIn() then
            if IsControlJustPressed(0, AdminConfig.OpenControl) then
                if isPanelOpen then
                    ClosePanel()
                else
                    TriggerServerEvent('umeverse_admin:server:openPanel')
                end
            end
        else
            Wait(500)
        end
    end
end)

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

    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    local heading = GetEntityHeading(ped)

    local vehicle = CreateVehicle(modelHash, coords.x, coords.y, coords.z, heading, true, false)
    SetVehicleEngineOn(vehicle, true, true, false)
    TaskWarpPedIntoVehicle(ped, vehicle, -1)
    SetModelAsNoLongerNeeded(modelHash)
    SetEntityAsMissionEntity(vehicle, true, true)
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
