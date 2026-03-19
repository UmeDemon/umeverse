--[[
    Umeverse Drugs - Turf / Territory Control
    Players can claim sell corners as their turf.
    Controlling turf grants passive income and sell bonuses.
]]

local UME = exports['umeverse_core']:GetCoreObject()

-- In-memory turf ownership: [cornerIdx] = { citizenid, capturedAt }
local turfOwners = {}

-- ═══════════════════════════════════════
-- Load turf data on startup
-- ═══════════════════════════════════════

CreateThread(function()
    if not DrugConfig.Turf.enabled then return end
    Wait(2000)

    local results = MySQL.query.await('SELECT * FROM umeverse_drug_turf')
    if results then
        for _, row in ipairs(results) do
            turfOwners[row.corner_index] = {
                citizenid = row.citizenid,
                capturedAt = row.captured_at,
            }
        end
    end
end)

-- ═══════════════════════════════════════
-- Passive Income Thread
-- ═══════════════════════════════════════

CreateThread(function()
    if not DrugConfig.Turf.enabled then return end
    Wait(10000)

    while true do
        Wait(DrugConfig.Turf.passiveInterval * 1000)

        for cornerIdx, data in pairs(turfOwners) do
            -- Find the player who owns this turf
            local players = UME.GetPlayers()
            for _, player in pairs(players) do
                if player:GetCitizenId() == data.citizenid then
                    player:AddMoney(DrugConfig.Turf.passiveMoneyType, DrugConfig.Turf.passiveIncome,
                        'Turf income: ' .. (DrugConfig.SellCorners[cornerIdx] and DrugConfig.SellCorners[cornerIdx].label or 'Corner'))
                    TriggerClientEvent('umeverse:client:notify', player:GetSource(),
                        'Turf income: +$' .. DrugConfig.Turf.passiveIncome .. ' (' .. (DrugConfig.SellCorners[cornerIdx] and DrugConfig.SellCorners[cornerIdx].label or 'Corner') .. ')', 'success')
                    break
                end
            end
        end
    end
end)

-- ═══════════════════════════════════════
-- Offline Expiry Thread
-- ═══════════════════════════════════════

CreateThread(function()
    if not DrugConfig.Turf.enabled then return end
    Wait(60000)

    while true do
        Wait(300000) -- Check every 5 minutes

        -- Check which owners are offline and for how long
        local onlineCids = {}
        local players = UME.GetPlayers()
        for _, player in pairs(players) do
            onlineCids[player:GetCitizenId()] = true
        end

        for cornerIdx, data in pairs(turfOwners) do
            if not onlineCids[data.citizenid] then
                -- Player is offline, check last_online timestamp
                local elapsed = MySQL.scalar.await(
                    'SELECT TIMESTAMPDIFF(SECOND, last_online, NOW()) FROM umeverse_drug_turf WHERE corner_index = ?',
                    { cornerIdx }
                )
                if elapsed and elapsed >= DrugConfig.Turf.offlineExpiry then
                    -- Expire this turf
                    MySQL.update('DELETE FROM umeverse_drug_turf WHERE corner_index = ?', { cornerIdx })
                    turfOwners[cornerIdx] = nil
                end
            else
                -- Update last_online for active players
                MySQL.update('UPDATE umeverse_drug_turf SET last_online = NOW() WHERE corner_index = ?', { cornerIdx })
            end
        end
    end
end)

-- ═══════════════════════════════════════
-- Public API Functions
-- ═══════════════════════════════════════

--- Check if a corner is owned
---@param cornerIdx number
---@return string|nil citizenid of owner
function GetTurfOwner(cornerIdx)
    if not DrugConfig.Turf.enabled then return nil end
    local data = turfOwners[cornerIdx]
    return data and data.citizenid or nil
end

--- Check if player owns a specific corner
---@param citizenid string
---@param cornerIdx number
---@return boolean
function PlayerOwnsTurf(citizenid, cornerIdx)
    if not DrugConfig.Turf.enabled then return false end
    local data = turfOwners[cornerIdx]
    return data and data.citizenid == citizenid
end

--- Count how many turfs a player owns
---@param citizenid string
---@return number
function CountPlayerTurfs(citizenid)
    local count = 0
    for _, data in pairs(turfOwners) do
        if data.citizenid == citizenid then
            count = count + 1
        end
    end
    return count
end

--- Get the sell bonus for selling on owned turf
---@param citizenid string
---@param cornerIdx number
---@return number bonus multiplier (0 if not owned)
function GetTurfSellBonus(citizenid, cornerIdx)
    if not DrugConfig.Turf.enabled then return 0 end
    if PlayerOwnsTurf(citizenid, cornerIdx) then
        return DrugConfig.Turf.turfSellBonus
    end
    return 0
end

-- ═══════════════════════════════════════
-- Capture Turf Handler
-- ═══════════════════════════════════════

RegisterNetEvent('umeverse_drugs:server:captureTurf', function(cornerIdx)
    local src = source
    if not DrugConfig.Turf.enabled then return end

    local player = UME.GetPlayer(src)
    if not player then return end

    local citizenid = player:GetCitizenId()

    -- Check level requirement
    local rep = GetPlayerDrugRep(player)
    local level = GetDrugLevelFromRep(rep)
    if level < DrugConfig.Turf.requiredLevel then
        TriggerClientEvent('umeverse:client:notify', src,
            'Need Drug Rep Level ' .. DrugConfig.Turf.requiredLevel .. ' to claim turf!', 'error')
        return
    end

    -- Validate corner exists
    if not DrugConfig.SellCorners[cornerIdx] then return end

    -- Check if already owned by this player
    if PlayerOwnsTurf(citizenid, cornerIdx) then
        TriggerClientEvent('umeverse:client:notify', src, 'You already own this turf!', 'info')
        return
    end

    -- Check max turfs
    if CountPlayerTurfs(citizenid) >= DrugConfig.Turf.maxTurfsPerPlayer then
        TriggerClientEvent('umeverse:client:notify', src,
            'Max turfs reached! (' .. DrugConfig.Turf.maxTurfsPerPlayer .. ')', 'error')
        return
    end

    -- Capture (overwrite existing owner)
    turfOwners[cornerIdx] = {
        citizenid = citizenid,
        capturedAt = os.date('%Y-%m-%d %H:%M:%S'),
    }

    MySQL.update(
        'INSERT INTO umeverse_drug_turf (corner_index, citizenid) VALUES (?, ?) ON DUPLICATE KEY UPDATE citizenid = ?, captured_at = NOW(), last_online = NOW()',
        { cornerIdx, citizenid, citizenid }
    )

    -- Add heat for capturing turf
    AddPlayerHeat(citizenid, DrugConfig.Turf.captureHeatGain, src)

    local label = DrugConfig.SellCorners[cornerIdx].label
    TriggerClientEvent('umeverse:client:notify', src,
        'Claimed turf: ' .. label .. '!', 'success', 8000)

    -- Notify all players (turf change)
    TriggerClientEvent('umeverse_drugs:client:turfUpdate', -1, cornerIdx, citizenid)

    UME.Log('Turf Captured', player:GetFullName() .. ' captured turf at ' .. label, 16776960)
end)

-- ═══════════════════════════════════════
-- Release Turf Handler
-- ═══════════════════════════════════════

RegisterNetEvent('umeverse_drugs:server:releaseTurf', function(cornerIdx)
    local src = source
    if not DrugConfig.Turf.enabled then return end

    local player = UME.GetPlayer(src)
    if not player then return end

    local citizenid = player:GetCitizenId()
    if not PlayerOwnsTurf(citizenid, cornerIdx) then
        TriggerClientEvent('umeverse:client:notify', src, 'You don\'t own this turf!', 'error')
        return
    end

    turfOwners[cornerIdx] = nil
    MySQL.update('DELETE FROM umeverse_drug_turf WHERE corner_index = ?', { cornerIdx })

    local label = DrugConfig.SellCorners[cornerIdx] and DrugConfig.SellCorners[cornerIdx].label or 'Corner'
    TriggerClientEvent('umeverse:client:notify', src, 'Released turf: ' .. label, 'info')
    TriggerClientEvent('umeverse_drugs:client:turfUpdate', -1, cornerIdx, nil)
end)

-- ═══════════════════════════════════════
-- Callback: Get all turf owners
-- ═══════════════════════════════════════

UME.RegisterServerCallback('umeverse_drugs:getTurfs', function(source, cb)
    if not DrugConfig.Turf.enabled then cb({}) return end

    local result = {}
    for cornerIdx, data in pairs(turfOwners) do
        result[cornerIdx] = data.citizenid
    end
    cb(result)
end)
