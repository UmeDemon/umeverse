--[[
    Umeverse Drugs - NPC Buyer Reputation
    Each sell corner NPC has trust/reputation with the player.
    Higher buyer rep = better prices, bulk deals, special requests.
]]

local UME = exports['umeverse_core']:GetCoreObject()

-- In-memory cache: [citizenid][cornerIdx] = rep
local buyerRepCache = {}

-- ═══════════════════════════════════════
-- Load buyer rep data on startup
-- ═══════════════════════════════════════

CreateThread(function()
    if not DrugConfig.BuyerRep.enabled then return end
    Wait(2000)

    local results = MySQL.query.await('SELECT * FROM umeverse_drug_buyer_rep')
    if results then
        for _, row in ipairs(results) do
            if not buyerRepCache[row.citizenid] then
                buyerRepCache[row.citizenid] = {}
            end
            buyerRepCache[row.citizenid][row.corner_index] = row.rep
        end
    end
end)

-- ═══════════════════════════════════════
-- Rep Decay Thread
-- ═══════════════════════════════════════

CreateThread(function()
    if not DrugConfig.BuyerRep.enabled then return end
    Wait(15000)

    while true do
        Wait(DrugConfig.BuyerRep.repDecayInterval * 1000)

        for citizenid, corners in pairs(buyerRepCache) do
            for cornerIdx, rep in pairs(corners) do
                if rep > 0 then
                    corners[cornerIdx] = math.max(0, rep - DrugConfig.BuyerRep.repDecayRate)

                    MySQL.update(
                        'INSERT INTO umeverse_drug_buyer_rep (citizenid, corner_index, rep) VALUES (?, ?, ?) ON DUPLICATE KEY UPDATE rep = ?',
                        { citizenid, cornerIdx, corners[cornerIdx], corners[cornerIdx] }
                    )
                end
            end
        end
    end
end)

-- ═══════════════════════════════════════
-- Public API Functions
-- ═══════════════════════════════════════

--- Get buyer rep for a player at a corner
---@param citizenid string
---@param cornerIdx number
---@return number
function GetBuyerRep(citizenid, cornerIdx)
    if not DrugConfig.BuyerRep.enabled then return 0 end
    if not buyerRepCache[citizenid] then return 0 end
    return buyerRepCache[citizenid][cornerIdx] or 0
end

--- Get buyer trust level for a player at a corner
---@param citizenid string
---@param cornerIdx number
---@return number level, table levelData
function GetBuyerLevel(citizenid, cornerIdx)
    local rep = GetBuyerRep(citizenid, cornerIdx)
    local level = 1
    local data = DrugConfig.BuyerRep.levels[1]

    for l = #DrugConfig.BuyerRep.levels, 1, -1 do
        if rep >= DrugConfig.BuyerRep.levels[l].xp then
            level = l
            data = DrugConfig.BuyerRep.levels[l]
            break
        end
    end

    return level, data
end

--- Get price bonus from buyer rep
---@param citizenid string
---@param cornerIdx number
---@return number bonus multiplier (e.g. 0.15 for +15%)
function GetBuyerPriceBonus(citizenid, cornerIdx)
    if not DrugConfig.BuyerRep.enabled then return 0 end
    local _, data = GetBuyerLevel(citizenid, cornerIdx)
    return data.priceBonus
end

--- Get bulk sell amount from buyer rep
---@param citizenid string
---@param cornerIdx number
---@return number max items per sale
function GetBuyerBulkAmount(citizenid, cornerIdx)
    if not DrugConfig.BuyerRep.enabled then return 1 end
    local _, data = GetBuyerLevel(citizenid, cornerIdx)
    return data.bulkAmount
end

--- Add buyer rep (with purity scaling)
---@param citizenid string
---@param cornerIdx number
---@param basePurity number|nil purity of sold item (0-100)
---@param src number player source
function AddBuyerRep(citizenid, cornerIdx, basePurity, src)
    if not DrugConfig.BuyerRep.enabled then return end

    if not buyerRepCache[citizenid] then
        buyerRepCache[citizenid] = {}
    end

    local baseRep = DrugConfig.BuyerRep.repPerSale
    local mult = 1.0

    -- Apply purity reputation multiplier
    if basePurity and DrugConfig.Purity.enabled then
        for _, range in ipairs(DrugConfig.BuyerRep.purityRepMult) do
            if basePurity >= range.min and basePurity <= range.max then
                mult = range.mult
                break
            end
        end
    end

    local repGain = math.floor(baseRep * mult + 0.5)
    local oldRep = buyerRepCache[citizenid][cornerIdx] or 0
    local oldLevel, _ = GetBuyerLevel(citizenid, cornerIdx)

    buyerRepCache[citizenid][cornerIdx] = oldRep + repGain

    MySQL.update(
        'INSERT INTO umeverse_drug_buyer_rep (citizenid, corner_index, rep) VALUES (?, ?, ?) ON DUPLICATE KEY UPDATE rep = ?',
        { citizenid, cornerIdx, buyerRepCache[citizenid][cornerIdx], buyerRepCache[citizenid][cornerIdx] }
    )

    -- Check for level up
    local newLevel, newData = GetBuyerLevel(citizenid, cornerIdx)
    if newLevel > oldLevel and src then
        local cornerLabel = DrugConfig.SellCorners[cornerIdx] and DrugConfig.SellCorners[cornerIdx].label or 'Corner'
        TriggerClientEvent('umeverse:client:notify', src,
            'Buyer trust up at ' .. cornerLabel .. '! Level ' .. newLevel .. ': ' .. newData.label, 'success', 6000)
    end
end

-- ═══════════════════════════════════════
-- Callback: Get buyer rep for all corners
-- ═══════════════════════════════════════

UME.RegisterServerCallback('umeverse_drugs:getBuyerRep', function(source, cb)
    local player = UME.GetPlayer(source)
    if not player then cb({}) return end

    local citizenid = player:GetCitizenId()
    local result = {}

    for i = 1, #DrugConfig.SellCorners do
        local level, data = GetBuyerLevel(citizenid, i)
        result[i] = {
            rep = GetBuyerRep(citizenid, i),
            level = level,
            label = data.label,
            priceBonus = data.priceBonus,
            bulkAmount = data.bulkAmount,
        }
    end

    cb(result)
end)
