--[[
    Umeverse Drugs - Dynamic Pricing System
    Fluctuating demand per drug per sell corner.
    High demand = better prices, selling floods supply.
]]

local UME = exports['umeverse_core']:GetCoreObject()

-- In-memory demand cache: [cornerIdx][drugKey] = demand (0-100)
local demandCache = {}

-- Active demand events: [cornerIdx] = { drugKey, demandChange, expiresAt }
local activeEvents = {}

-- ═══════════════════════════════════════
-- Load demand data on startup
-- ═══════════════════════════════════════

CreateThread(function()
    if not DrugConfig.DynamicPricing.enabled then return end
    Wait(2000)

    -- Initialize all corners with base demand
    for i, corner in ipairs(DrugConfig.SellCorners) do
        demandCache[i] = {}
        for _, drugItem in ipairs(corner.drugs) do
            local info = DrugConfig.DrugSellItems[drugItem]
            if info then
                demandCache[i][info.config] = DrugConfig.DynamicPricing.baseDemand
            end
        end
    end

    -- Load persisted state from DB
    local results = MySQL.query.await('SELECT * FROM umeverse_drug_demand')
    if results then
        for _, row in ipairs(results) do
            if demandCache[row.corner_index] then
                demandCache[row.corner_index][row.drug_key] = row.demand
            end
        end
    end
end)

-- ═══════════════════════════════════════
-- Demand Recovery Thread
-- ═══════════════════════════════════════

CreateThread(function()
    if not DrugConfig.DynamicPricing.enabled then return end
    Wait(10000)

    while true do
        Wait(DrugConfig.DynamicPricing.recoveryInterval * 1000)

        for cornerIdx, drugs in pairs(demandCache) do
            for drugKey, demand in pairs(drugs) do
                local base = DrugConfig.DynamicPricing.baseDemand
                local recovery = DrugConfig.DynamicPricing.demandRecoveryRate

                -- Recover toward base demand
                if demand < base then
                    drugs[drugKey] = math.min(base, demand + recovery)
                end

                -- Clamp
                drugs[drugKey] = math.max(DrugConfig.DynamicPricing.minDemand,
                    math.min(DrugConfig.DynamicPricing.maxDemand, drugs[drugKey]))

                -- Persist
                MySQL.update(
                    'INSERT INTO umeverse_drug_demand (corner_index, drug_key, demand) VALUES (?, ?, ?) ON DUPLICATE KEY UPDATE demand = ?',
                    { cornerIdx, drugKey, drugs[drugKey], drugs[drugKey] }
                )
            end
        end
    end
end)

-- ═══════════════════════════════════════
-- Random Demand Events Thread
-- ═══════════════════════════════════════

CreateThread(function()
    if not DrugConfig.DynamicPricing.enabled then return end
    if not DrugConfig.DynamicPricing.events.enabled then return end
    Wait(30000)

    while true do
        Wait(DrugConfig.DynamicPricing.events.interval * 1000)

        if math.random(100) <= DrugConfig.DynamicPricing.events.chance then
            -- Pick random corner and drug
            local cornerIdx = math.random(1, #DrugConfig.SellCorners)
            local corner = DrugConfig.SellCorners[cornerIdx]
            if corner and #corner.drugs > 0 then
                local drugItem = corner.drugs[math.random(1, #corner.drugs)]
                local info = DrugConfig.DrugSellItems[drugItem]
                if info then
                    -- Pick random event type
                    local eventType = DrugConfig.DynamicPricing.events.types[math.random(1, #DrugConfig.DynamicPricing.events.types)]

                    -- Apply event
                    if demandCache[cornerIdx] and demandCache[cornerIdx][info.config] then
                        local current = demandCache[cornerIdx][info.config]
                        demandCache[cornerIdx][info.config] = math.max(
                            DrugConfig.DynamicPricing.minDemand,
                            math.min(DrugConfig.DynamicPricing.maxDemand, current + eventType.demandChange)
                        )

                        -- Record event for expiry
                        activeEvents[#activeEvents + 1] = {
                            cornerIdx = cornerIdx,
                            drugKey = info.config,
                            change = eventType.demandChange,
                            expiresAt = os.time() + eventType.duration,
                        }

                        -- Notify nearby players
                        local coord = corner.coords
                        local players = UME.GetPlayers()
                        for _, player in pairs(players) do
                            TriggerClientEvent('umeverse_drugs:client:demandEvent', player:GetSource(), eventType.label, corner.label, info.config)
                        end
                    end
                end
            end
        end

        -- Clean up expired events (revert changes)
        local now = os.time()
        local alive = {}
        for _, event in ipairs(activeEvents) do
            if now >= event.expiresAt then
                -- Revert the demand change
                if demandCache[event.cornerIdx] and demandCache[event.cornerIdx][event.drugKey] then
                    local current = demandCache[event.cornerIdx][event.drugKey]
                    demandCache[event.cornerIdx][event.drugKey] = math.max(
                        DrugConfig.DynamicPricing.minDemand,
                        math.min(DrugConfig.DynamicPricing.maxDemand, current - event.change)
                    )
                end
            else
                alive[#alive + 1] = event
            end
        end
        activeEvents = alive
    end
end)

-- ═══════════════════════════════════════
-- Public API Functions
-- ═══════════════════════════════════════

--- Get demand level for a drug at a corner
---@param cornerIdx number
---@param drugKey string
---@return number demand (0-100)
function GetDemand(cornerIdx, drugKey)
    if not DrugConfig.DynamicPricing.enabled then return DrugConfig.DynamicPricing.baseDemand end
    if not demandCache[cornerIdx] then return DrugConfig.DynamicPricing.baseDemand end
    return demandCache[cornerIdx][drugKey] or DrugConfig.DynamicPricing.baseDemand
end

--- Get price multiplier based on demand
---@param cornerIdx number
---@param drugKey string
---@return number multiplier
function GetDemandPriceMult(cornerIdx, drugKey)
    if not DrugConfig.DynamicPricing.enabled then return 1.0 end

    local demand = GetDemand(cornerIdx, drugKey)
    local minD = DrugConfig.DynamicPricing.minDemand
    local maxD = DrugConfig.DynamicPricing.maxDemand
    local lowM = DrugConfig.DynamicPricing.lowMult
    local highM = DrugConfig.DynamicPricing.highMult

    -- Linear interpolation between low and high multiplier
    local ratio = (demand - minD) / (maxD - minD)
    ratio = math.max(0, math.min(1, ratio))
    return lowM + (highM - lowM) * ratio
end

--- Reduce demand after a sale
---@param cornerIdx number
---@param drugKey string
function ReduceDemand(cornerIdx, drugKey)
    if not DrugConfig.DynamicPricing.enabled then return end
    if not demandCache[cornerIdx] then return end

    local current = demandCache[cornerIdx][drugKey] or DrugConfig.DynamicPricing.baseDemand
    demandCache[cornerIdx][drugKey] = math.max(
        DrugConfig.DynamicPricing.minDemand,
        current - DrugConfig.DynamicPricing.demandDropPerSale
    )

    -- Persist
    MySQL.update(
        'INSERT INTO umeverse_drug_demand (corner_index, drug_key, demand) VALUES (?, ?, ?) ON DUPLICATE KEY UPDATE demand = ?',
        { cornerIdx, drugKey, demandCache[cornerIdx][drugKey], demandCache[cornerIdx][drugKey] }
    )
end

-- ═══════════════════════════════════════
-- Callback: Get demand for all drugs at a corner
-- ═══════════════════════════════════════

UME.RegisterServerCallback('umeverse_drugs:getDemand', function(source, cb, cornerIdx)
    if not DrugConfig.DynamicPricing.enabled then cb({}) return end
    cb(demandCache[cornerIdx] or {})
end)
