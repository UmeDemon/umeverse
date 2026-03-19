--[[
    Umeverse Drugs - Server Warehouse
    Warehouse rental, storage, and expiration system
    Warehouses persist in the database and auto-expire
]]

local UME = exports['umeverse_core']:GetCoreObject()

-- In-memory warehouse ownership cache (loaded from DB on start)
local warehouseOwners = {} -- [warehouseId] = { citizenid, expires }

-- ═══════════════════════════════════════
-- Load warehouse data on startup
-- ═══════════════════════════════════════

CreateThread(function()
    Wait(2000)

    local results = MySQL.query.await('SELECT * FROM umeverse_drug_warehouses WHERE expires > NOW()')
    if results then
        for _, row in ipairs(results) do
            warehouseOwners[row.warehouse_id] = {
                citizenid = row.citizenid,
                expires = row.expires,
            }
        end
    end

    -- Cleanup expired warehouses every 5 minutes
    while true do
        Wait(300000)
        CleanupExpiredWarehouses()
    end
end)

function CleanupExpiredWarehouses()
    MySQL.update('DELETE FROM umeverse_drug_warehouses WHERE expires <= NOW()')

    for whId, data in pairs(warehouseOwners) do
        -- Re-check against DB
        local result = MySQL.scalar.await('SELECT COUNT(*) FROM umeverse_drug_warehouses WHERE warehouse_id = ?', { whId })
        if result == 0 then
            warehouseOwners[whId] = nil
        end
    end
end

-- ═══════════════════════════════════════
-- Get Warehouse State Callback
-- ═══════════════════════════════════════

UME.RegisterServerCallback('umeverse_drugs:getWarehouseState', function(source, cb, warehouseId)
    local player = UME.GetPlayer(source)
    if not player then cb(nil) return end

    local citizenid = player:GetCitizenId()
    local ownerData = warehouseOwners[warehouseId]

    if ownerData and ownerData.citizenid == citizenid then
        cb({ owned = true, expires = ownerData.expires })
    else
        cb({ owned = false })
    end
end)

-- ═══════════════════════════════════════
-- Rent Warehouse
-- ═══════════════════════════════════════

RegisterNetEvent('umeverse_drugs:server:rentWarehouse', function(warehouseId)
    local src = source
    local player = UME.GetPlayer(src)
    if not player then return end

    -- Check rep level
    local rep = player:GetMetadata('drugRep') or 0
    local level = 1
    for l = 10, 1, -1 do
        if rep >= DrugConfig.Progression.levels[l].xp then level = l break end
    end
    if level < DrugConfig.Warehouses.requiredLevel then
        TriggerClientEvent('umeverse:client:notify', src, 'Need Rep Level ' .. DrugConfig.Warehouses.requiredLevel .. ' to rent warehouses!', 'error')
        return
    end

    -- Find warehouse config
    local whCfg = nil
    for _, wh in ipairs(DrugConfig.Warehouses.locations) do
        if wh.id == warehouseId then whCfg = wh break end
    end
    if not whCfg then return end

    -- Check if already owned by someone
    if warehouseOwners[warehouseId] then
        TriggerClientEvent('umeverse:client:notify', src, 'This warehouse is already rented!', 'error')
        return
    end

    -- Check if player can afford
    if not player:HasMoney('cash', whCfg.rentCost) then
        TriggerClientEvent('umeverse:client:notify', src, 'Not enough cash! Need $' .. whCfg.rentCost, 'error')
        return
    end

    -- Deduct money and save to DB
    player:RemoveMoney('cash', whCfg.rentCost, 'Warehouse rent: ' .. whCfg.label)

    local citizenid = player:GetCitizenId()
    local expires = os.date('%Y-%m-%d %H:%M:%S', os.time() + 86400) -- 24 hours from now

    MySQL.insert('INSERT INTO umeverse_drug_warehouses (warehouse_id, citizenid, expires) VALUES (?, ?, ?)',
        { warehouseId, citizenid, expires })

    warehouseOwners[warehouseId] = { citizenid = citizenid, expires = expires }

    TriggerClientEvent('umeverse_drugs:client:warehouseRented', src, whCfg.label)
    UME.Log('Warehouse Rented', player:GetFullName() .. ' rented ' .. whCfg.label .. ' for $' .. whCfg.rentCost, 16776960)
end)

-- ═══════════════════════════════════════
-- Open Warehouse Storage
-- ═══════════════════════════════════════

RegisterNetEvent('umeverse_drugs:server:openWarehouse', function(warehouseId)
    local src = source
    local player = UME.GetPlayer(src)
    if not player then return end

    local citizenid = player:GetCitizenId()
    local ownerData = warehouseOwners[warehouseId]

    if not ownerData or ownerData.citizenid ~= citizenid then
        TriggerClientEvent('umeverse:client:notify', src, 'You don\'t own this warehouse!', 'error')
        return
    end

    -- Open warehouse as a stash via inventory system
    TriggerClientEvent('umeverse_drugs:client:openWarehouseStash', src, warehouseId)
end)

-- ═══════════════════════════════════════
-- Warehouse Status
-- ═══════════════════════════════════════

RegisterNetEvent('umeverse_drugs:server:warehouseStatus', function(warehouseId)
    local src = source
    local player = UME.GetPlayer(src)
    if not player then return end

    local citizenid = player:GetCitizenId()
    local ownerData = warehouseOwners[warehouseId]

    if not ownerData or ownerData.citizenid ~= citizenid then
        TriggerClientEvent('umeverse:client:notify', src, 'You don\'t own this warehouse!', 'error')
        return
    end

    -- Find label
    local label = 'Warehouse'
    for _, wh in ipairs(DrugConfig.Warehouses.locations) do
        if wh.id == warehouseId then label = wh.label break end
    end

    -- Calculate time remaining
    local expiresTime = MySQL.scalar.await(
        'SELECT TIMESTAMPDIFF(SECOND, NOW(), expires) FROM umeverse_drug_warehouses WHERE warehouse_id = ? AND citizenid = ?',
        { warehouseId, citizenid }
    )

    if expiresTime and expiresTime > 0 then
        local hours = math.floor(expiresTime / 3600)
        local mins = math.floor((expiresTime % 3600) / 60)
        TriggerClientEvent('umeverse_drugs:client:warehouseStatus', src, label, hours .. 'h ' .. mins .. 'm')
    else
        TriggerClientEvent('umeverse:client:notify', src, 'Warehouse rent has expired!', 'warning')
        warehouseOwners[warehouseId] = nil
    end
end)

-- ═══════════════════════════════════════
-- Cancel Warehouse Rent
-- ═══════════════════════════════════════

RegisterNetEvent('umeverse_drugs:server:cancelWarehouse', function(warehouseId)
    local src = source
    local player = UME.GetPlayer(src)
    if not player then return end

    local citizenid = player:GetCitizenId()
    local ownerData = warehouseOwners[warehouseId]

    if not ownerData or ownerData.citizenid ~= citizenid then
        TriggerClientEvent('umeverse:client:notify', src, 'You don\'t own this warehouse!', 'error')
        return
    end

    MySQL.update('DELETE FROM umeverse_drug_warehouses WHERE warehouse_id = ? AND citizenid = ?',
        { warehouseId, citizenid })

    warehouseOwners[warehouseId] = nil

    local label = 'Warehouse'
    for _, wh in ipairs(DrugConfig.Warehouses.locations) do
        if wh.id == warehouseId then label = wh.label break end
    end

    TriggerClientEvent('umeverse_drugs:client:warehouseCanceled', src, label)
end)
