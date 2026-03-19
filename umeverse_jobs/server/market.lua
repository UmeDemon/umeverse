-- ═══════════════════════════════════════════════════════════════════
-- Umeverse Jobs - Dynamic Pay Market System (Server)
-- ═══════════════════════════════════════════════════════════════════

local UME = exports['umeverse_core']:GetCoreObject()

local jobCounts = {}    -- [jobName] = number of active on-duty players
local payMultipliers = {} -- [jobName] = { mult, label }

-- ───────────────────────────────────────
-- Recalculate Market Multipliers
-- ───────────────────────────────────────

local function RecalculateMarket()
    if not JobsConfig.DynamicPay or not JobsConfig.DynamicPay.enabled then return end
    local tiers = JobsConfig.DynamicPay.tiers
    if not tiers then return end

    -- Count players per job
    local counts = {}
    local players = UME.GetPlayers()
    if players then
        for _, src in ipairs(players) do
            local player = UME.GetPlayer(src)
            if player then
                local jobData = player.GetJob()
                if jobData and jobData.onduty and jobData.name then
                    counts[jobData.name] = (counts[jobData.name] or 0) + 1
                end
            end
        end
    end

    jobCounts = counts

    -- Determine multiplier per job based on tiers
    for jobName, count in pairs(counts) do
        local mult = 1.0
        local label = ''
        for _, tier in ipairs(tiers) do
            if count <= tier.maxPlayers then
                mult = tier.payMult
                label = tier.label
                break
            end
            -- If we pass all tiers, use the last one
            mult = tier.payMult
            label = tier.label
        end
        payMultipliers[jobName] = { mult = mult, label = label }
    end
end

-- ───────────────────────────────────────
-- Public API
-- ───────────────────────────────────────

--- Get the dynamic pay multiplier for a specific job
function GetDynamicPayMultiplier(jobName)
    if not JobsConfig.DynamicPay or not JobsConfig.DynamicPay.enabled then return 1.0 end
    local data = payMultipliers[jobName]
    if data then return data.mult end
    return 1.15 -- Default high demand for jobs with no players
end

exports('GetDynamicPayMultiplier', GetDynamicPayMultiplier)

--- Get market label for a job (for client display)
function GetDynamicPayLabel(jobName)
    if not JobsConfig.DynamicPay or not JobsConfig.DynamicPay.enabled then return '' end
    local data = payMultipliers[jobName]
    if data then return data.label end
    return '~g~High Demand'
end

exports('GetDynamicPayLabel', GetDynamicPayLabel)

-- ───────────────────────────────────────
-- Events
-- ───────────────────────────────────────

-- Client can request current market info
RegisterNetEvent('umeverse_jobs:server:getMarketInfo', function()
    local src = source
    if not JobsConfig.DynamicPay or not JobsConfig.DynamicPay.enabled then return end

    local info = {}
    for jobName, data in pairs(payMultipliers) do
        info[jobName] = {
            mult = data.mult,
            label = data.label,
            players = jobCounts[jobName] or 0,
        }
    end

    TriggerClientEvent('umeverse_jobs:client:marketInfo', src, info)
end)

-- ───────────────────────────────────────
-- Periodic Refresh
-- ───────────────────────────────────────

CreateThread(function()
    while true do
        RecalculateMarket()
        local interval = (JobsConfig.DynamicPay and JobsConfig.DynamicPay.updateIntervalMs) or 60000
        Wait(interval)
    end
end)
