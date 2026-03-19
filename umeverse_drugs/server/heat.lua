--[[
    Umeverse Drugs - Heat / Wanted System
    Tracks player heat level from drug activities.
    High heat increases police encounters, raid risk, and sell interference.
]]

local UME = exports['umeverse_core']:GetCoreObject()

-- In-memory heat cache: [citizenid] = { heat, lastActivity }
local heatCache = {}

-- ═══════════════════════════════════════
-- Load heat data on startup
-- ═══════════════════════════════════════

CreateThread(function()
    if not DrugConfig.Heat.enabled then return end
    Wait(2000)

    local results = MySQL.query.await('SELECT * FROM umeverse_drug_heat')
    if results then
        for _, row in ipairs(results) do
            heatCache[row.citizenid] = {
                heat = row.heat,
                lastActivity = row.last_activity,
            }
        end
    end
end)

-- ═══════════════════════════════════════
-- Heat Decay Thread
-- ═══════════════════════════════════════

CreateThread(function()
    if not DrugConfig.Heat.enabled then return end
    Wait(5000)

    while true do
        Wait(DrugConfig.Heat.decayInterval * 1000)

        for citizenid, data in pairs(heatCache) do
            if data.heat > 0 then
                local decay = DrugConfig.Heat.decayRate

                -- Bonus decay if player has been inactive
                local now = os.time()
                local lastStr = data.lastActivity
                if lastStr then
                    -- Parse timestamp or use raw value
                    local diff = now - (data.lastActivityTime or now)
                    if diff >= DrugConfig.Heat.cooldownWindow then
                        decay = decay + DrugConfig.Heat.cooldownBonus
                    end
                end

                data.heat = math.max(0, data.heat - decay)

                MySQL.update('INSERT INTO umeverse_drug_heat (citizenid, heat) VALUES (?, ?) ON DUPLICATE KEY UPDATE heat = ?',
                    { citizenid, data.heat, data.heat })
            end
        end
    end
end)

-- ═══════════════════════════════════════
-- Public API Functions
-- ═══════════════════════════════════════

--- Get a player's current heat level
---@param citizenid string
---@return number
function GetPlayerHeat(citizenid)
    if not DrugConfig.Heat.enabled then return 0 end
    local data = heatCache[citizenid]
    return data and data.heat or 0
end

--- Add heat to a player
---@param citizenid string
---@param amount number
---@param src number player source for client sync
function AddPlayerHeat(citizenid, amount, src)
    if not DrugConfig.Heat.enabled then return end

    if not heatCache[citizenid] then
        heatCache[citizenid] = { heat = 0, lastActivityTime = os.time() }
    end

    local data = heatCache[citizenid]
    data.heat = math.min(DrugConfig.Heat.maxHeat, data.heat + amount)
    data.lastActivityTime = os.time()

    MySQL.update(
        'INSERT INTO umeverse_drug_heat (citizenid, heat, last_activity) VALUES (?, ?, NOW()) ON DUPLICATE KEY UPDATE heat = ?, last_activity = NOW()',
        { citizenid, data.heat, data.heat }
    )

    -- Sync heat to client
    if src then
        TriggerClientEvent('umeverse_drugs:client:syncHeat', src, data.heat)
    end
end

--- Get the heat threshold data for a given heat level
---@param heat number
---@return table|nil threshold
function GetHeatThreshold(heat)
    if not DrugConfig.Heat.enabled then return nil end

    local best = nil
    for _, threshold in ipairs(DrugConfig.Heat.thresholds) do
        if heat >= threshold.heat then
            best = threshold
        end
    end
    return best
end

--- Get police alert multiplier based on heat
---@param heat number
---@return number
function GetHeatAlertMult(heat)
    local threshold = GetHeatThreshold(heat)
    return threshold and threshold.policeAlertMult or 1.0
end

--- Get encounter multiplier based on heat
---@param heat number
---@return number
function GetHeatEncounterMult(heat)
    local threshold = GetHeatThreshold(heat)
    return threshold and threshold.encounterMult or 1.0
end

-- ═══════════════════════════════════════
-- Heat Callback (for client queries)
-- ═══════════════════════════════════════

UME.RegisterServerCallback('umeverse_drugs:getHeat', function(source, cb)
    local player = UME.GetPlayer(source)
    if not player then cb(0) return end
    cb(GetPlayerHeat(player:GetCitizenId()))
end)

-- ═══════════════════════════════════════
-- Player join: load their heat + sync
-- ═══════════════════════════════════════

RegisterNetEvent('umeverse_drugs:server:requestHeat', function()
    local src = source
    if not DrugConfig.Heat.enabled then return end

    local player = UME.GetPlayer(src)
    if not player then return end

    local citizenid = player:GetCitizenId()
    local heat = GetPlayerHeat(citizenid)
    TriggerClientEvent('umeverse_drugs:client:syncHeat', src, heat)
end)

-- ═══════════════════════════════════════
-- Command: Check heat
-- ═══════════════════════════════════════

RegisterCommand('heatlevel', function(source)
    local src = source
    if src <= 0 then return end
    if not DrugConfig.Heat.enabled then return end

    local player = UME.GetPlayer(src)
    if not player then return end

    local heat = GetPlayerHeat(player:GetCitizenId())
    local threshold = GetHeatThreshold(heat)
    local label = threshold and threshold.label or 'Cool'

    TriggerClientEvent('umeverse:client:notify', src,
        'Heat Level: ' .. heat .. '/100 (' .. label .. ')', 'info', 8000)
end, false)
