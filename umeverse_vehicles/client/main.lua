--[[
    Umeverse Vehicles - Client
]]

local UME = exports['umeverse_core']:GetCoreObject()
local spawnedVehicles = {} -- plate -> netId
local vehicleKeys = {}     -- plate -> true
local currentGarage = nil

-- ═══════════════════════════════════════
-- Blips
-- ═══════════════════════════════════════

CreateThread(function()
    for id, garage in pairs(VehConfig.Garages) do
        if not garage.job then -- Only show public garages
            local blip = AddBlipForCoord(garage.coords.x, garage.coords.y, garage.coords.z)
            SetBlipSprite(blip, garage.blip.sprite)
            SetBlipDisplay(blip, 4)
            SetBlipScale(blip, garage.blip.scale)
            SetBlipColour(blip, garage.blip.color)
            SetBlipAsShortRange(blip, true)
            BeginTextCommandSetBlipName('STRING')
            AddTextComponentString(garage.label)
            EndTextCommandSetBlipName(blip)
        end
    end

    -- Impound blip
    local impBlip = AddBlipForCoord(VehConfig.ImpoundLocation.x, VehConfig.ImpoundLocation.y, VehConfig.ImpoundLocation.z)
    SetBlipSprite(impBlip, 68)
    SetBlipDisplay(impBlip, 4)
    SetBlipScale(impBlip, 0.7)
    SetBlipColour(impBlip, 1)
    SetBlipAsShortRange(impBlip, true)
    BeginTextCommandSetBlipName('STRING')
    AddTextComponentString('Impound Lot')
    EndTextCommandSetBlipName(impBlip)
end)

-- ═══════════════════════════════════════
-- Garage Interaction
-- ═══════════════════════════════════════

CreateThread(function()
    while true do
        local sleep = 1000
        if UME.IsLoggedIn() and not UME.IsDead() then
            local myCoords = GetEntityCoords(PlayerPedId())

            for id, garage in pairs(VehConfig.Garages) do
                local dist = #(myCoords - garage.coords)
                if dist < 15.0 then
                    sleep = 0

                    -- Draw marker
                    DrawMarker(36, garage.coords.x, garage.coords.y, garage.coords.z - 0.9, 0, 0, 0, 0, 0, 0, 1.2, 1.2, 0.5, 59, 130, 246, 150, false, false, 2, false, nil, nil, false)

                    if dist < VehConfig.InteractDistance then
                        local inVehicle = IsPedInAnyVehicle(PlayerPedId(), false)

                        if inVehicle then
                            UME.ShowHelpText('Press ~INPUT_CONTEXT~ to store vehicle')
                            if IsControlJustPressed(0, 38) then
                                StoreVehicle(id)
                            end
                        else
                            UME.ShowHelpText('Press ~INPUT_CONTEXT~ to open garage')
                            if IsControlJustPressed(0, 38) then
                                OpenGarage(id)
                            end
                        end
                    end
                end
            end

            -- Impound interaction
            local impDist = #(myCoords - VehConfig.ImpoundLocation)
            if impDist < 15.0 then
                sleep = 0
                DrawMarker(36, VehConfig.ImpoundLocation.x, VehConfig.ImpoundLocation.y, VehConfig.ImpoundLocation.z - 0.9, 0, 0, 0, 0, 0, 0, 1.2, 1.2, 0.5, 239, 68, 68, 150, false, false, 2, false, nil, nil, false)

                if impDist < VehConfig.InteractDistance then
                    UME.ShowHelpText('Press ~INPUT_CONTEXT~ to check impound')
                    if IsControlJustPressed(0, 38) then
                        OpenImpound()
                    end
                end
            end
        end
        Wait(sleep)
    end
end)

-- ═══════════════════════════════════════
-- Open Garage (NUI menu)
-- ═══════════════════════════════════════

function OpenGarage(garageId)
    currentGarage = garageId
    UME.TriggerServerCallback('umeverse_vehicles:getVehicles', function(vehicles)
        if not vehicles or #vehicles == 0 then
            TriggerEvent('umeverse:client:notify', UME.Translate('garage_empty'), 'info')
            return
        end

        local garageData = VehConfig.Garages[garageId]
        SendNUIMessage({
            action   = 'openGarage',
            title    = garageData and garageData.label or 'Garage',
            vehicles = vehicles,
        })
        SetNuiFocus(true, true)
    end, garageId)
end

-- ═══════════════════════════════════════
-- Store Vehicle
-- ═══════════════════════════════════════

function StoreVehicle(garageId)
    local ped = PlayerPedId()
    local vehicle = GetVehiclePedIsIn(ped, false)

    if vehicle == 0 then return end

    local plate = string.gsub(GetVehicleNumberPlateText(vehicle), '%s+', '')

    -- Collect vehicle mods
    local mods = {}
    for i = 0, 49 do
        local modIndex = GetVehicleMod(vehicle, i)
        if modIndex >= 0 then
            mods[tostring(i)] = modIndex
        end
    end

    local vehicleData = {
        fuel   = GetVehicleFuelLevel(vehicle) or 100,
        body   = GetVehicleBodyHealth(vehicle) or 1000,
        engine = GetVehicleEngineHealth(vehicle) or 1000,
        mods   = mods,
    }

    TaskLeaveVehicle(ped, vehicle, 0)
    Wait(1500)

    TriggerServerEvent('umeverse_vehicles:server:storeVehicle', plate, garageId, vehicleData)
end

-- ═══════════════════════════════════════
-- Open Impound
-- ═══════════════════════════════════════

function OpenImpound()
    UME.TriggerServerCallback('umeverse_vehicles:getImpounded', function(vehicles)
        if not vehicles or #vehicles == 0 then
            TriggerEvent('umeverse:client:notify', 'No impounded vehicles.', 'info')
            return
        end

        SendNUIMessage({
            action   = 'openImpound',
            vehicles = vehicles,
        })
        SetNuiFocus(true, true)
    end)
end

-- NUI Callbacks for garage/impound selection
RegisterNUICallback('selectVehicle', function(data, cb)
    SetNuiFocus(false, false)
    if data.type == 'impound' then
        TriggerServerEvent('umeverse_vehicles:server:retrieveImpound', data.id)
    else
        TriggerServerEvent('umeverse_vehicles:server:spawnVehicle', data.id, currentGarage)
    end
    cb('ok')
end)

RegisterNUICallback('closeGarage', function(_, cb)
    SetNuiFocus(false, false)
    cb('ok')
end)

-- ═══════════════════════════════════════
-- Spawn Vehicle (Client)
-- ═══════════════════════════════════════

RegisterNetEvent('umeverse_vehicles:client:spawnVehicle', function(data)
    local modelHash = GetHashKey(data.model)

    if not UME.LoadModel(modelHash) then
        TriggerEvent('umeverse:client:notify', 'Failed to load vehicle model.', 'error')
        return
    end

    local spawn = data.spawn
    local vehicle = CreateVehicle(modelHash, spawn.x, spawn.y, spawn.z, spawn.w, true, false)

    SetVehicleNumberPlateText(vehicle, data.plate)
    SetVehicleFuelLevel(vehicle, data.fuel + 0.0)
    SetVehicleBodyHealth(vehicle, data.body + 0.0)
    SetVehicleEngineHealth(vehicle, data.engine + 0.0)
    SetVehicleEngineOn(vehicle, true, true, false)
    SetEntityAsMissionEntity(vehicle, true, true)

    -- Apply mods if any
    if data.mods and type(data.mods) == 'table' then
        SetVehicleModKit(vehicle, 0)
        for modType, modIndex in pairs(data.mods) do
            local modNum = tonumber(modType)
            if modNum and modIndex then
                SetVehicleMod(vehicle, modNum, modIndex, false)
            end
        end
    end

    -- Set ped into vehicle
    TaskWarpPedIntoVehicle(PlayerPedId(), vehicle, -1)
    SetModelAsNoLongerNeeded(modelHash)

    -- Track and give keys
    local plate = data.plate
    spawnedVehicles[plate] = VehToNet(vehicle)
    vehicleKeys[plate] = true
end)

-- ═══════════════════════════════════════
-- Delete Vehicle
-- ═══════════════════════════════════════

RegisterNetEvent('umeverse_vehicles:client:deleteVehicle', function(plate)
    for p, netId in pairs(spawnedVehicles) do
        if p == plate then
            local veh = NetToVeh(netId)
            if DoesEntityExist(veh) then
                DeleteEntity(veh)
            end
            spawnedVehicles[p] = nil
            break
        end
    end
end)

-- ═══════════════════════════════════════
-- Vehicle Keys
-- ═══════════════════════════════════════

RegisterNetEvent('umeverse_vehicles:client:receiveKeys', function(plate)
    vehicleKeys[plate] = true
    TriggerEvent('umeverse:client:notify', 'You received keys for plate: ' .. plate, 'info')
end)

--- Check if player has keys to current vehicle
function HasVehicleKeys(vehicle)
    if not vehicle or vehicle == 0 then return false end
    local plate = string.gsub(GetVehicleNumberPlateText(vehicle), '%s+', '')
    return vehicleKeys[plate] == true
end

-- ═══════════════════════════════════════
-- Fuel System
-- ═══════════════════════════════════════

if VehConfig.EnableFuel then
    local lastCoords = nil

    CreateThread(function()
        while true do
            Wait(5000)
            if UME.IsLoggedIn() then
                local ped = PlayerPedId()
                if IsPedInAnyVehicle(ped, false) then
                    local vehicle = GetVehiclePedIsIn(ped, false)
                    local coords = GetEntityCoords(vehicle)

                    if lastCoords then
                        local dist = #(coords - lastCoords)
                        if dist > 10.0 then
                            local currentFuel = GetVehicleFuelLevel(vehicle)
                            local newFuel = math.max(0, currentFuel - (dist / 100.0 * VehConfig.FuelDecayRate))
                            SetVehicleFuelLevel(vehicle, newFuel)

                            if newFuel <= 0.0 then
                                SetVehicleEngineOn(vehicle, false, true, true)
                            end
                        end
                    end

                    lastCoords = coords
                else
                    lastCoords = nil
                end
            end
        end
    end)
end

-- ═══════════════════════════════════════
-- Seatbelt (basic)
-- ═══════════════════════════════════════

local seatbeltOn = false

CreateThread(function()
    while true do
        Wait(0)
        if UME.IsLoggedIn() and IsPedInAnyVehicle(PlayerPedId(), false) then
            if IsControlJustPressed(0, 311) then -- K
                seatbeltOn = not seatbeltOn
                TriggerEvent('umeverse:client:notify', seatbeltOn and 'Seatbelt on' or 'Seatbelt off', 'info')
            end

            if seatbeltOn then
                DisableControlAction(0, 75, true) -- Disable exit vehicle (must unbuckle first)
            end
        else
            seatbeltOn = false
            Wait(500)
        end
    end
end)

-- ═══════════════════════════════════════
-- Exports
-- ═══════════════════════════════════════

exports('HasVehicleKeys', HasVehicleKeys)
exports('GetSpawnedVehicles', function() return spawnedVehicles end)

-- ═══════════════════════════════════════
-- Cleanup on resource stop
-- ═══════════════════════════════════════

AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    -- Clean up spawned vehicles
    for plate, netId in pairs(spawnedVehicles) do
        local veh = NetToVeh(netId)
        if DoesEntityExist(veh) then
            DeleteEntity(veh)
        end
    end
end)
