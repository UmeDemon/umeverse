--[[
    Umeverse Drugs - Supply Chain Runs / Transport Missions
    Server-side mission management, validation, rewards, and ambush triggers.
]]

local UME = exports['umeverse_core']:GetCoreObject()

-- Active supply runs: [src] = { routeId, startTime, completed }
local activeRuns = {}

-- Cooldowns: [citizenid] = lastRunTime
local runCooldowns = {}

-- ═══════════════════════════════════════
-- Start Supply Run
-- ═══════════════════════════════════════

RegisterNetEvent('umeverse_drugs:server:startSupplyRun', function(routeIdx)
    local src = source
    if not DrugConfig.SupplyRuns.enabled then return end

    local player = UME.GetPlayer(src)
    if not player then return end

    -- Check if already on a run
    if activeRuns[src] then
        TriggerClientEvent('umeverse:client:notify', src, 'Already on a supply run!', 'error')
        return
    end

    -- Validate route
    local route = DrugConfig.SupplyRuns.routes[routeIdx]
    if not route then return end

    -- Check level requirement
    local rep = GetPlayerDrugRep(player)
    local level = GetDrugLevelFromRep(rep)
    if level < (route.requiredLevel or DrugConfig.SupplyRuns.requiredLevel) then
        TriggerClientEvent('umeverse:client:notify', src,
            'Need Drug Rep Level ' .. (route.requiredLevel or DrugConfig.SupplyRuns.requiredLevel) .. ' for this route!', 'error')
        return
    end

    -- Check cooldown
    local citizenid = player:GetCitizenId()
    local now = os.time()
    if runCooldowns[citizenid] and now - runCooldowns[citizenid] < DrugConfig.SupplyRuns.cooldown then
        local remaining = DrugConfig.SupplyRuns.cooldown - (now - runCooldowns[citizenid])
        TriggerClientEvent('umeverse:client:notify', src,
            'Supply run cooldown: ' .. math.ceil(remaining / 60) .. ' min remaining', 'error')
        return
    end

    -- Start the run
    activeRuns[src] = {
        routeIdx = routeIdx,
        startTime = now,
        citizenid = citizenid,
    }

    -- Add heat
    AddPlayerHeat(citizenid, DrugConfig.SupplyRuns.heatGain, src)

    TriggerClientEvent('umeverse_drugs:client:startSupplyRun', src, routeIdx)

    UME.Log('Supply Run Started', player:GetFullName() .. ' started supply run: ' .. route.label, 16776960)
end)

-- ═══════════════════════════════════════
-- Complete Supply Run
-- ═══════════════════════════════════════

RegisterNetEvent('umeverse_drugs:server:completeSupplyRun', function(routeIdx)
    local src = source
    if not DrugConfig.SupplyRuns.enabled then return end

    local run = activeRuns[src]
    if not run or run.routeIdx ~= routeIdx then return end

    local player = UME.GetPlayer(src)
    if not player then return end

    local route = DrugConfig.SupplyRuns.routes[routeIdx]
    if not route then return end

    -- Check time limit
    local elapsed = os.time() - run.startTime
    if elapsed > route.timeLimit then
        -- Failed - took too long
        activeRuns[src] = nil
        TriggerClientEvent('umeverse:client:notify', src, 'Supply run failed — took too long!', 'error')
        return
    end

    -- Reward player
    if route.reward.cash > 0 then
        player:AddMoney('cash', route.reward.cash, 'Supply run: ' .. route.label)
    end
    if route.reward.black > 0 then
        player:AddMoney('black', route.reward.black, 'Supply run: ' .. route.label)
    end
    if route.reward.rep > 0 then
        AddDrugRep(player, route.reward.rep, src)
    end

    -- Set cooldown
    runCooldowns[run.citizenid] = os.time()

    -- Clean up
    activeRuns[src] = nil

    TriggerClientEvent('umeverse:client:notify', src,
        'Supply run complete! Earned $' .. (route.reward.black + route.reward.cash) .. ' + ' .. route.reward.rep .. ' rep', 'success', 8000)

    UME.Log('Supply Run Complete', player:GetFullName() .. ' completed supply run: ' .. route.label, 65280)
end)

-- ═══════════════════════════════════════
-- Fail/Cancel Supply Run
-- ═══════════════════════════════════════

RegisterNetEvent('umeverse_drugs:server:failSupplyRun', function()
    local src = source
    if not activeRuns[src] then return end

    local player = UME.GetPlayer(src)
    if player then
        TriggerClientEvent('umeverse:client:notify', src, 'Supply run failed!', 'error')
    end

    activeRuns[src] = nil
end)

-- ═══════════════════════════════════════
-- Callback: Check active run status
-- ═══════════════════════════════════════

UME.RegisterServerCallback('umeverse_drugs:getSupplyRunStatus', function(source, cb)
    local run = activeRuns[source]
    if run then
        local route = DrugConfig.SupplyRuns.routes[run.routeIdx]
        local elapsed = os.time() - run.startTime
        local remaining = route and (route.timeLimit - elapsed) or 0
        cb({ active = true, routeIdx = run.routeIdx, timeRemaining = remaining })
    else
        cb({ active = false })
    end
end)

-- ═══════════════════════════════════════
-- Callback: Get available routes
-- ═══════════════════════════════════════

UME.RegisterServerCallback('umeverse_drugs:getSupplyRoutes', function(source, cb)
    if not DrugConfig.SupplyRuns.enabled then cb({}) return end

    local player = UME.GetPlayer(source)
    if not player then cb({}) return end

    local rep = GetPlayerDrugRep(player)
    local level = GetDrugLevelFromRep(rep)
    local citizenid = player:GetCitizenId()

    local result = {}
    for i, route in ipairs(DrugConfig.SupplyRuns.routes) do
        local reqLevel = route.requiredLevel or DrugConfig.SupplyRuns.requiredLevel
        result[i] = {
            label = route.label,
            reward = route.reward,
            timeLimit = route.timeLimit,
            available = level >= reqLevel,
            requiredLevel = reqLevel,
        }
    end

    -- Include cooldown info
    local cooldownRemaining = 0
    if runCooldowns[citizenid] then
        cooldownRemaining = math.max(0, DrugConfig.SupplyRuns.cooldown - (os.time() - runCooldowns[citizenid]))
    end

    cb({ routes = result, cooldown = cooldownRemaining, onRun = activeRuns[source] ~= nil })
end)

-- ═══════════════════════════════════════
-- Cleanup on player disconnect
-- ═══════════════════════════════════════

AddEventHandler('playerDropped', function()
    local src = source
    activeRuns[src] = nil
end)
