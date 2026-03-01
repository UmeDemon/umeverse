--[[
    Umeverse Vehicles - Server
]]

local UME = exports['umeverse_core']:GetCoreObject()

-- ═══════════════════════════════════════
-- Get Player Vehicles
-- ═══════════════════════════════════════

UME.RegisterServerCallback('umeverse_vehicles:getVehicles', function(source, cb, garageId)
    local player = UME.GetPlayer(source)
    if not player then cb({}) return end

    local garage = VehConfig.Garages[garageId]
    if not garage then cb({}) return end

    -- Job garage check
    if garage.job and player:GetJob().name ~= garage.job then
        cb({})
        return
    end

    local vehicles
    if garage.job then
        -- Job vehicles
        vehicles = MySQL.query.await(
            'SELECT * FROM umeverse_vehicles WHERE citizenid = ? AND garage = ? AND job = ?',
            { player:GetCitizenId(), garageId, garage.job }
        ) or {}
    else
        -- Personal vehicles stored in this garage
        vehicles = MySQL.query.await(
            'SELECT * FROM umeverse_vehicles WHERE citizenid = ? AND garage = ? AND job IS NULL',
            { player:GetCitizenId(), garageId }
        ) or {}
    end

    local result = {}
    for _, veh in ipairs(vehicles) do
        result[#result + 1] = {
            id         = veh.id,
            plate      = veh.plate,
            model      = veh.model,
            state      = veh.state, -- 0=out, 1=garaged, 2=impounded
            fuel       = veh.fuel or 100,
            body       = veh.body or 1000,
            engine     = veh.engine or 1000,
            mods       = json.decode(veh.mods or '{}'),
        }
    end

    cb(result)
end)

-- ═══════════════════════════════════════
-- Spawn Vehicle from Garage
-- ═══════════════════════════════════════

RegisterNetEvent('umeverse_vehicles:server:spawnVehicle', function(vehicleId, garageId)
    local src = source
    local player = UME.GetPlayer(src)
    if not player then return end

    local garage = VehConfig.Garages[garageId]
    if not garage then return end

    -- Verify ownership
    local veh = MySQL.query.await('SELECT * FROM umeverse_vehicles WHERE id = ? AND citizenid = ?', { vehicleId, player:GetCitizenId() })
    if not veh or #veh == 0 then
        UME.Notify(src, 'Vehicle not found.', 'error')
        return
    end

    veh = veh[1]
    if veh.state ~= 1 then
        UME.Notify(src, 'Vehicle is not stored in this garage.', 'error')
        return
    end

    -- Mark as out (0)
    MySQL.update('UPDATE umeverse_vehicles SET state = ? WHERE id = ?', { 0, vehicleId })

    -- Send spawn data to client
    TriggerClientEvent('umeverse_vehicles:client:spawnVehicle', src, {
        model  = veh.model,
        plate  = veh.plate,
        fuel   = veh.fuel or 100,
        body   = veh.body or 1000,
        engine = veh.engine or 1000,
        mods   = json.decode(veh.mods or '{}'),
        spawn  = { x = garage.spawn.x, y = garage.spawn.y, z = garage.spawn.z, w = garage.spawn.w },
    })

    UME.Notify(src, 'Vehicle spawned.', 'success')
end)

-- ═══════════════════════════════════════
-- Store Vehicle
-- ═══════════════════════════════════════

RegisterNetEvent('umeverse_vehicles:server:storeVehicle', function(plate, garageId, vehicleData)
    local src = source
    local player = UME.GetPlayer(src)
    if not player then return end

    local veh = MySQL.query.await('SELECT * FROM umeverse_vehicles WHERE plate = ? AND citizenid = ?', { plate, player:GetCitizenId() })
    if not veh or #veh == 0 then
        UME.Notify(src, UME.Translate('vehicle_not_owned'), 'error')
        return
    end

    MySQL.update('UPDATE umeverse_vehicles SET state = ?, garage = ?, fuel = ?, body = ?, engine = ?, mods = ? WHERE plate = ?', {
        1, garageId,
        vehicleData.fuel or 100,
        vehicleData.body or 1000,
        vehicleData.engine or 1000,
        json.encode(vehicleData.mods or {}),
        plate,
    })

    TriggerClientEvent('umeverse_vehicles:client:deleteVehicle', src, plate)
    UME.Notify(src, UME.Translate('vehicle_stored'), 'success')
end)

-- ═══════════════════════════════════════
-- Impound Vehicle
-- ═══════════════════════════════════════

RegisterNetEvent('umeverse_vehicles:server:impoundVehicle', function(plate)
    local src = source
    local player = UME.GetPlayer(src)
    if not player then return end

    -- Only police can impound
    if player:GetJob().name ~= 'police' then
        UME.Notify(src, 'Only police can impound vehicles.', 'error')
        return
    end

    MySQL.update('UPDATE umeverse_vehicles SET state = ? WHERE plate = ?', { 2, plate })
    TriggerClientEvent('umeverse_vehicles:client:deleteVehicle', -1, plate)
    UME.Notify(src, UME.Translate('vehicle_impounded'), 'success')
end)

-- ═══════════════════════════════════════
-- Retrieve from Impound
-- ═══════════════════════════════════════

RegisterNetEvent('umeverse_vehicles:server:retrieveImpound', function(vehicleId)
    local src = source
    local player = UME.GetPlayer(src)
    if not player then return end

    local veh = MySQL.query.await('SELECT * FROM umeverse_vehicles WHERE id = ? AND citizenid = ? AND state = ?', { vehicleId, player:GetCitizenId(), 2 })
    if not veh or #veh == 0 then
        UME.Notify(src, 'Vehicle not found in impound.', 'error')
        return
    end

    if not player:HasMoney('cash', VehConfig.ImpoundPrice) then
        UME.Notify(src, UME.Translate('money_insufficient'), 'error')
        return
    end

    player:RemoveMoney('cash', VehConfig.ImpoundPrice, 'Impound fee')
    MySQL.update('UPDATE umeverse_vehicles SET state = ? WHERE id = ?', { 0, vehicleId })

    veh = veh[1]
    TriggerClientEvent('umeverse_vehicles:client:spawnVehicle', src, {
        model  = veh.model,
        plate  = veh.plate,
        fuel   = veh.fuel or 100,
        body   = veh.body or 1000,
        engine = veh.engine or 1000,
        mods   = json.decode(veh.mods or '{}'),
        spawn  = { x = VehConfig.ImpoundSpawn.x, y = VehConfig.ImpoundSpawn.y, z = VehConfig.ImpoundSpawn.z, w = VehConfig.ImpoundSpawn.w },
    })

    UME.Notify(src, 'Vehicle retrieved from impound. Fee: $' .. VehConfig.ImpoundPrice, 'success')
end)

-- ═══════════════════════════════════════
-- Get Impounded Vehicles
-- ═══════════════════════════════════════

UME.RegisterServerCallback('umeverse_vehicles:getImpounded', function(source, cb)
    local player = UME.GetPlayer(source)
    if not player then cb({}) return end

    local vehicles = MySQL.query.await(
        'SELECT * FROM umeverse_vehicles WHERE citizenid = ? AND state = ?',
        { player:GetCitizenId(), 2 }
    ) or {}

    cb(vehicles)
end)

-- ═══════════════════════════════════════
-- Give Vehicle Keys
-- ═══════════════════════════════════════

-- ═══════════════════════════════════════
-- Load Vehicle Keys from DB on player join
-- ═══════════════════════════════════════

UME.RegisterServerCallback('umeverse_vehicles:getKeys', function(source, cb)
    local player = UME.GetPlayer(source)
    if not player then cb({}) return end

    local rows = MySQL.query.await(
        'SELECT plate FROM umeverse_vehicle_keys WHERE citizenid = ?',
        { player:GetCitizenId() }
    ) or {}

    local keys = {}
    for _, row in ipairs(rows) do
        keys[#keys + 1] = row.plate
    end
    cb(keys)
end)

-- ═══════════════════════════════════════
-- Give Vehicle Keys (persisted)
-- ═══════════════════════════════════════

RegisterNetEvent('umeverse_vehicles:server:giveKeys', function(plate, targetId)
    local src = source
    targetId = tonumber(targetId)
    if not targetId then return end

    local targetPlayer = UME.GetPlayer(targetId)
    if not targetPlayer then
        UME.Notify(src, 'Player not found.', 'error')
        return
    end

    -- Persist the key grant (INSERT IGNORE to avoid duplicates)
    MySQL.insert(
        'INSERT IGNORE INTO umeverse_vehicle_keys (plate, citizenid) VALUES (?, ?)',
        { plate, targetPlayer:GetCitizenId() }
    )

    TriggerClientEvent('umeverse_vehicles:client:receiveKeys', targetId, plate)
    UME.Notify(src, 'Keys given.', 'success')
    UME.Notify(targetId, 'You received vehicle keys.', 'info')
end)

-- ═══════════════════════════════════════
-- Remove Vehicle Keys
-- ═══════════════════════════════════════

RegisterNetEvent('umeverse_vehicles:server:removeKeys', function(plate, targetId)
    local src = source
    targetId = tonumber(targetId)
    if not targetId then return end

    local targetPlayer = UME.GetPlayer(targetId)
    if not targetPlayer then return end

    MySQL.query('DELETE FROM umeverse_vehicle_keys WHERE plate = ? AND citizenid = ?',
        { plate, targetPlayer:GetCitizenId() }
    )

    TriggerClientEvent('umeverse_vehicles:client:removeKeys', targetId, plate)
    UME.Notify(src, 'Keys removed.', 'success')
    UME.Notify(targetId, 'Vehicle keys revoked for plate: ' .. plate, 'info')
end)

-- ═══════════════════════════════════════
-- Save vehicle state on disconnect
-- ═══════════════════════════════════════

RegisterNetEvent('umeverse_vehicles:server:saveVehicleState', function(plate, data)
    MySQL.update('UPDATE umeverse_vehicles SET fuel = ?, body = ?, engine = ? WHERE plate = ?', {
        data.fuel or 100, data.body or 1000, data.engine or 1000, plate,
    })
end)
