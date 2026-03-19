--[[
    Umeverse Drugs - Specialization System
    Per-drug skill trees that give production bonuses.
    Players earn specialization XP separately from global drug rep.
]]

local UME = exports['umeverse_core']:GetCoreObject()

-- In-memory cache: [citizenid] = { [drugKey] = xp }
local specCache = {}

-- ═══════════════════════════════════════
-- Load specialization data on startup
-- ═══════════════════════════════════════

CreateThread(function()
    if not DrugConfig.Specialization.enabled then return end
    Wait(2000)

    local results = MySQL.query.await('SELECT * FROM umeverse_drug_specialization')
    if results then
        for _, row in ipairs(results) do
            if not specCache[row.citizenid] then
                specCache[row.citizenid] = {}
            end
            specCache[row.citizenid][row.drug_key] = row.xp
        end
    end
end)

-- ═══════════════════════════════════════
-- Public API Functions
-- ═══════════════════════════════════════

--- Get specialization XP for a player and drug
---@param citizenid string
---@param drugKey string
---@return number
function GetSpecXP(citizenid, drugKey)
    if not DrugConfig.Specialization.enabled then return 0 end
    if not specCache[citizenid] then return 0 end
    return specCache[citizenid][drugKey] or 0
end

--- Get specialization level for a player and drug
---@param citizenid string
---@param drugKey string
---@return number level, table levelData
function GetSpecLevel(citizenid, drugKey)
    local xp = GetSpecXP(citizenid, drugKey)
    local level = 1
    local data = DrugConfig.Specialization.levels[1]

    for l = #DrugConfig.Specialization.levels, 1, -1 do
        if xp >= DrugConfig.Specialization.levels[l].xp then
            level = l
            data = DrugConfig.Specialization.levels[l]
            break
        end
    end

    return level, data
end

--- Get specialization bonuses for a player and drug
---@param citizenid string
---@param drugKey string
---@return table { yieldBonus, speedBonus, failReduction, purityBonus }
function GetSpecBonuses(citizenid, drugKey)
    if not DrugConfig.Specialization.enabled then
        return { yieldBonus = 0, speedBonus = 0, failReduction = 0, purityBonus = 0 }
    end
    local _, data = GetSpecLevel(citizenid, drugKey)
    return data
end

--- Add specialization XP for a player and drug
---@param citizenid string
---@param drugKey string
---@param amount number
---@param src number player source
function AddSpecXP(citizenid, drugKey, amount, src)
    if not DrugConfig.Specialization.enabled then return end

    if not specCache[citizenid] then
        specCache[citizenid] = {}
    end

    local oldXP = specCache[citizenid][drugKey] or 0
    local oldLevel, _ = GetSpecLevel(citizenid, drugKey)

    specCache[citizenid][drugKey] = oldXP + amount

    -- Save to DB
    MySQL.update(
        'INSERT INTO umeverse_drug_specialization (citizenid, drug_key, xp) VALUES (?, ?, ?) ON DUPLICATE KEY UPDATE xp = ?',
        { citizenid, drugKey, specCache[citizenid][drugKey], specCache[citizenid][drugKey] }
    )

    -- Check for level up
    local newLevel, newData = GetSpecLevel(citizenid, drugKey)
    if newLevel > oldLevel and src then
        local drugLabel = DrugConfig.Drugs[drugKey] and DrugConfig.Drugs[drugKey].label or drugKey
        TriggerClientEvent('umeverse:client:notify', src,
            drugLabel .. ' Specialization Up! Level ' .. newLevel .. ': ' .. newData.label, 'success', 8000)
    end
end

--- Count how many drugs the player is specialized in (level >= 2)
---@param citizenid string
---@return number
function CountSpecializations(citizenid)
    if not specCache[citizenid] then return 0 end
    local count = 0
    for drugKey, xp in pairs(specCache[citizenid]) do
        local level = GetSpecLevel(citizenid, drugKey)
        if level >= 2 then
            count = count + 1
        end
    end
    return count
end

-- ═══════════════════════════════════════
-- Callback: Get all specializations for player
-- ═══════════════════════════════════════

UME.RegisterServerCallback('umeverse_drugs:getSpecializations', function(source, cb)
    local player = UME.GetPlayer(source)
    if not player then cb({}) return end

    local citizenid = player:GetCitizenId()
    local result = {}

    if specCache[citizenid] then
        for drugKey, xp in pairs(specCache[citizenid]) do
            local level, data = GetSpecLevel(citizenid, drugKey)
            result[drugKey] = {
                xp = xp,
                level = level,
                label = data.label,
                bonuses = data,
            }
        end
    end

    cb(result)
end)

-- ═══════════════════════════════════════
-- Command: Check specializations
-- ═══════════════════════════════════════

RegisterCommand('drugspec', function(source)
    local src = source
    if src <= 0 then return end
    if not DrugConfig.Specialization.enabled then return end

    local player = UME.GetPlayer(src)
    if not player then return end

    local citizenid = player:GetCitizenId()
    local msg = 'Drug Specializations:\n'
    local hasAny = false

    if specCache[citizenid] then
        for drugKey, xp in pairs(specCache[citizenid]) do
            local level, data = GetSpecLevel(citizenid, drugKey)
            local drugLabel = DrugConfig.Drugs[drugKey] and DrugConfig.Drugs[drugKey].label or drugKey
            msg = msg .. drugLabel .. ': Lv.' .. level .. ' (' .. data.label .. ') - ' .. xp .. 'xp\n'
            hasAny = true
        end
    end

    if not hasAny then
        msg = msg .. 'None yet. Start crafting to specialize!'
    end

    TriggerClientEvent('umeverse:client:notify', src, msg, 'info', 12000)
end, false)
