--[[
    Umeverse Jobs - Server Main
    Handles clock-in, payments, item rewards, sell transactions, and streak-aware pay
]]

local UME = exports['umeverse_core']:GetCoreObject()

-- Anti-spam cooldowns per player
local cooldowns = {}
local COOLDOWN_MS = 3000

local function IsOnCooldown(src, action)
    local key = src .. ':' .. action
    local now = GetGameTimer()
    if cooldowns[key] and now - cooldowns[key] < COOLDOWN_MS then
        return true
    end
    cooldowns[key] = now
    return false
end

--- Apply ALL multipliers to a base pay amount (dynamic market, co-op, prestige, perks, mentorship)
---@param src number server id
---@param basePay number
---@param jobName string
---@return number adjusted pay
local function ApplyPayMultipliers(src, basePay, jobName)
    local mult = 1.0

    -- Dynamic Pay Market
    if JobsConfig.DynamicPay and JobsConfig.DynamicPay.enabled then
        local dmMult = exports['umeverse_jobs']:GetDynamicPayMultiplier(jobName)
        if dmMult then mult = mult * dmMult end
    end

    -- Co-Op Bonus
    if JobsConfig.CoOp and JobsConfig.CoOp.enabled then
        local _, coopMult = exports['umeverse_jobs']:GetCoOpInfo(src)
        if coopMult then mult = mult * coopMult end
    end

    -- Prestige Bonus
    if JobsConfig.Prestige and JobsConfig.Prestige.enabled then
        local citizenid = nil
        local player = UME.GetPlayer(src)
        if player then
            local pd = player:GetPlayerData()
            if pd then citizenid = pd.citizenid end
        end
        if citizenid then
            local pMult = exports['umeverse_jobs']:GetPrestigePayMultiplier(citizenid, jobName)
            if pMult then mult = mult * pMult end
        end
    end

    -- Perk Pay Bonus
    if JobsConfig.Perks and JobsConfig.Perks.enabled then
        local perkBonus = exports['umeverse_jobs']:GetPerkPayBonus(src, jobName)
        if perkBonus and perkBonus > 0 then
            mult = mult * (1.0 + perkBonus / 100)
        end
    end

    -- Mentorship Bonus
    if JobsConfig.Mentorship and JobsConfig.Mentorship.enabled then
        local mMult = exports['umeverse_jobs']:GetMentorshipPayMultiplier(src)
        if mMult then mult = mult * mMult end
    end

    -- Contract Bonus (applied as multiplier on each task)
    if JobsConfig.Contracts and JobsConfig.Contracts.enabled then
        local cMult = exports['umeverse_jobs']:GetContractPayMultiplier(src)
        if cMult then mult = mult * cMult end
    end

    return math.floor(basePay * mult)
end

-- ═══════════════════════════════════════
-- Clock In
-- ═══════════════════════════════════════

RegisterNetEvent('umeverse_jobs:server:clockIn', function(jobName)
    local src = source
    local player = UME.GetPlayer(src)
    if not player then return end

    -- Validate job exists in config
    local jobDef = UME.GetJob(jobName)
    if not jobDef then return end

    -- Set the player's job (grade 0 for clock-in jobs)
    local currentJob = player:GetJob()
    local grade = 0

    -- Keep grade if they already have this job
    if currentJob and currentJob.name == jobName then
        grade = currentJob.grade
    end

    player:SetJob(jobName, grade)

    -- Toggle on duty
    if not player:GetJob().onduty then
        player:ToggleDuty()
    end

    TriggerClientEvent('umeverse_jobs:client:clockedIn', src, jobName)
end)

-- ═══════════════════════════════════════
-- Garbage Collector Payment
-- ═══════════════════════════════════════

RegisterNetEvent('umeverse_jobs:server:garbagePay', function()
    local src = source
    if IsOnCooldown(src, 'garbage') then return end

    local player = UME.GetPlayer(src)
    if not player then return end

    local job = player:GetJob()
    if not job or job.name ~= 'garbage' then return end

    local pay = JobsConfig.Garbage.payPerBag[job.grade + 1] or JobsConfig.Garbage.payPerBag[1]
    pay = ApplyPayMultipliers(src, pay, 'garbage')
    player:AddMoney('cash', pay, 'Garbage Collection')
    TriggerClientEvent('umeverse_jobs:client:taskPaid', src, pay)
    TriggerEvent('umeverse_jobs:server:taskCompleted', 'garbage')
end)

-- ═══════════════════════════════════════
-- Bus Driver Payment
-- ═══════════════════════════════════════

RegisterNetEvent('umeverse_jobs:server:busPay', function()
    local src = source
    if IsOnCooldown(src, 'bus') then return end

    local player = UME.GetPlayer(src)
    if not player then return end

    local job = player:GetJob()
    if not job or job.name ~= 'bus' then return end

    local pay = JobsConfig.Bus.payPerStop[job.grade + 1] or JobsConfig.Bus.payPerStop[1]
    pay = ApplyPayMultipliers(src, pay, 'bus')
    player:AddMoney('cash', pay, 'Bus Stop Fare')
    TriggerClientEvent('umeverse_jobs:client:taskPaid', src, pay)
    TriggerEvent('umeverse_jobs:server:taskCompleted', 'bus')
end)

-- ═══════════════════════════════════════
-- Trucker Payment
-- ═══════════════════════════════════════

RegisterNetEvent('umeverse_jobs:server:truckerPay', function()
    local src = source
    if IsOnCooldown(src, 'trucker') then return end

    local player = UME.GetPlayer(src)
    if not player then return end

    local job = player:GetJob()
    if not job or job.name ~= 'trucker' then return end

    local pay = JobsConfig.Trucker.payPerDelivery[job.grade + 1] or JobsConfig.Trucker.payPerDelivery[1]
    pay = ApplyPayMultipliers(src, pay, 'trucker')
    player:AddMoney('cash', pay, 'Trucking Delivery')
    TriggerClientEvent('umeverse_jobs:client:taskPaid', src, pay)
    TriggerEvent('umeverse_jobs:server:taskCompleted', 'trucker')
end)

-- ═══════════════════════════════════════
-- Fisherman
-- ═══════════════════════════════════════

RegisterNetEvent('umeverse_jobs:server:catchFish', function(fishItem)
    local src = source
    if IsOnCooldown(src, 'fish') then return end

    local player = UME.GetPlayer(src)
    if not player then return end

    local job = player:GetJob()
    if not job or job.name ~= 'fisherman' then return end

    -- Validate the fish item is in the catch table
    local valid = false
    for _, catch in ipairs(JobsConfig.Fisherman.catches) do
        if catch.item == fishItem then valid = true break end
    end
    if not valid then return end

    player:AddItem(fishItem, 1)
end)

RegisterNetEvent('umeverse_jobs:server:sellFish', function()
    local src = source
    if IsOnCooldown(src, 'sellfish') then return end

    local player = UME.GetPlayer(src)
    if not player then return end

    local job = player:GetJob()
    if not job or job.name ~= 'fisherman' then return end

    local totalEarned = 0
    for itemName, price in pairs(JobsConfig.Fisherman.sellPrices) do
        local count = player:GetItemCount(itemName)
        if count > 0 then
            player:RemoveItem(itemName, count)
            local earned = count * price
            totalEarned = totalEarned + earned
        end
    end

    if totalEarned > 0 then
        totalEarned = ApplyPayMultipliers(src, totalEarned, 'fisherman')
        player:AddMoney('cash', totalEarned, 'Fish Sale')
        TriggerClientEvent('umeverse:client:notify', src, 'Sold fish for $' .. totalEarned, 'success')
        TriggerClientEvent('umeverse_jobs:client:taskPaid', src, totalEarned)
        TriggerEvent('umeverse_jobs:server:taskCompleted', 'fisherman')
    else
        TriggerClientEvent('umeverse:client:notify', src, 'You have no fish to sell!', 'error')
    end
end)

-- ═══════════════════════════════════════
-- Lumberjack
-- ═══════════════════════════════════════

RegisterNetEvent('umeverse_jobs:server:chopTree', function()
    local src = source
    if IsOnCooldown(src, 'chop') then return end

    local player = UME.GetPlayer(src)
    if not player then return end

    local job = player:GetJob()
    if not job or job.name ~= 'lumberjack' then return end

    local logsCount = JobsConfig.Lumberjack.logsPerChop[job.grade + 1] or 1
    player:AddItem('wood_log', logsCount)
end)

RegisterNetEvent('umeverse_jobs:server:processLogs', function()
    local src = source
    if IsOnCooldown(src, 'process') then return end

    local player = UME.GetPlayer(src)
    if not player then return end

    local job = player:GetJob()
    if not job or job.name ~= 'lumberjack' then return end

    local logCount = player:GetItemCount('wood_log')
    if logCount <= 0 then
        TriggerClientEvent('umeverse:client:notify', src, 'You have no logs to process!', 'error')
        return
    end

    -- Process one log at a time
    player:RemoveItem('wood_log', 1)
    player:AddItem('wood_plank', JobsConfig.Lumberjack.planksPerLog)
end)

RegisterNetEvent('umeverse_jobs:server:sellWood', function()
    local src = source
    if IsOnCooldown(src, 'sellwood') then return end

    local player = UME.GetPlayer(src)
    if not player then return end

    local job = player:GetJob()
    if not job or job.name ~= 'lumberjack' then return end

    local totalEarned = 0
    for itemName, price in pairs(JobsConfig.Lumberjack.sellPrices) do
        local count = player:GetItemCount(itemName)
        if count > 0 then
            player:RemoveItem(itemName, count)
            totalEarned = totalEarned + (count * price)
        end
    end

    if totalEarned > 0 then
        totalEarned = ApplyPayMultipliers(src, totalEarned, 'lumberjack')
        player:AddMoney('cash', totalEarned, 'Wood Sale')
        TriggerClientEvent('umeverse:client:notify', src, 'Sold wood for $' .. totalEarned, 'success')
        TriggerClientEvent('umeverse_jobs:client:taskPaid', src, totalEarned)
        TriggerEvent('umeverse_jobs:server:taskCompleted', 'lumberjack')
    else
        TriggerClientEvent('umeverse:client:notify', src, 'You have no wood to sell!', 'error')
    end
end)

-- ═══════════════════════════════════════
-- Miner
-- ═══════════════════════════════════════

RegisterNetEvent('umeverse_jobs:server:mineOre', function(oreItem)
    local src = source
    if IsOnCooldown(src, 'mine') then return end

    local player = UME.GetPlayer(src)
    if not player then return end

    local job = player:GetJob()
    if not job or job.name ~= 'miner' then return end

    -- Validate ore item
    local valid = false
    for _, ore in ipairs(JobsConfig.Miner.ores) do
        if ore.item == oreItem then valid = true break end
    end
    if not valid then return end

    player:AddItem(oreItem, 1)
end)

RegisterNetEvent('umeverse_jobs:server:sellOres', function()
    local src = source
    if IsOnCooldown(src, 'sellore') then return end

    local player = UME.GetPlayer(src)
    if not player then return end

    local job = player:GetJob()
    if not job or job.name ~= 'miner' then return end

    local totalEarned = 0
    for itemName, price in pairs(JobsConfig.Miner.sellPrices) do
        local count = player:GetItemCount(itemName)
        if count > 0 then
            player:RemoveItem(itemName, count)
            totalEarned = totalEarned + (count * price)
        end
    end

    if totalEarned > 0 then
        totalEarned = ApplyPayMultipliers(src, totalEarned, 'miner')
        player:AddMoney('cash', totalEarned, 'Ore Sale')
        TriggerClientEvent('umeverse:client:notify', src, 'Sold ores for $' .. totalEarned, 'success')
        TriggerClientEvent('umeverse_jobs:client:taskPaid', src, totalEarned)
        TriggerEvent('umeverse_jobs:server:taskCompleted', 'miner')
    else
        TriggerClientEvent('umeverse:client:notify', src, 'You have no ores to sell!', 'error')
    end
end)

-- ═══════════════════════════════════════
-- Tow Truck Payment
-- ═══════════════════════════════════════

RegisterNetEvent('umeverse_jobs:server:towPay', function()
    local src = source
    if IsOnCooldown(src, 'tow') then return end

    local player = UME.GetPlayer(src)
    if not player then return end

    local job = player:GetJob()
    if not job or job.name ~= 'tow' then return end

    local pay = JobsConfig.Tow.payPerTow[job.grade + 1] or JobsConfig.Tow.payPerTow[1]
    pay = ApplyPayMultipliers(src, pay, 'tow')
    player:AddMoney('cash', pay, 'Tow Delivery')
    TriggerClientEvent('umeverse_jobs:client:taskPaid', src, pay)
    TriggerEvent('umeverse_jobs:server:taskCompleted', 'tow')
end)

-- ═══════════════════════════════════════
-- Pizza Delivery Payment
-- ═══════════════════════════════════════

RegisterNetEvent('umeverse_jobs:server:pizzaPay', function()
    local src = source
    if IsOnCooldown(src, 'pizza') then return end

    local player = UME.GetPlayer(src)
    if not player then return end

    local job = player:GetJob()
    if not job or job.name ~= 'pizza' then return end

    local pay = JobsConfig.Pizza.payPerDelivery[job.grade + 1] or JobsConfig.Pizza.payPerDelivery[1]
    pay = ApplyPayMultipliers(src, pay, 'pizza')
    player:AddMoney('cash', pay, 'Pizza Delivery')
    TriggerClientEvent('umeverse_jobs:client:taskPaid', src, pay)
    TriggerEvent('umeverse_jobs:server:taskCompleted', 'pizza')
end)

-- ═══════════════════════════════════════
-- News Reporter Payment
-- ═══════════════════════════════════════

RegisterNetEvent('umeverse_jobs:server:reporterPay', function()
    local src = source
    if IsOnCooldown(src, 'reporter') then return end

    local player = UME.GetPlayer(src)
    if not player then return end

    local job = player:GetJob()
    if not job or job.name ~= 'reporter' then return end

    local pay = JobsConfig.Reporter.payPerStory[job.grade + 1] or JobsConfig.Reporter.payPerStory[1]
    pay = ApplyPayMultipliers(src, pay, 'reporter')
    player:AddMoney('cash', pay, 'News Story')
    TriggerClientEvent('umeverse_jobs:client:taskPaid', src, pay)
    TriggerEvent('umeverse_jobs:server:taskCompleted', 'reporter')
end)

-- ═══════════════════════════════════════
-- Taxi Payment
-- ═══════════════════════════════════════

RegisterNetEvent('umeverse_jobs:server:taxiPay', function()
    local src = source
    if IsOnCooldown(src, 'taxi') then return end

    local player = UME.GetPlayer(src)
    if not player then return end

    local job = player:GetJob()
    if not job or job.name ~= 'taxi' then return end

    local pay = JobsConfig.Taxi.payPerFare[job.grade + 1] or JobsConfig.Taxi.payPerFare[1]
    pay = ApplyPayMultipliers(src, pay, 'taxi')
    player:AddMoney('cash', pay, 'Taxi Fare')
    TriggerClientEvent('umeverse_jobs:client:taskPaid', src, pay)
    TriggerEvent('umeverse_jobs:server:taskCompleted', 'taxi')
end)

-- ═══════════════════════════════════════
-- Helicopter Tour Waypoint Payment
-- ═══════════════════════════════════════

RegisterNetEvent('umeverse_jobs:server:heliTourWaypoint', function()
    local src = source
    if IsOnCooldown(src, 'helitour') then return end

    local player = UME.GetPlayer(src)
    if not player then return end

    local job = player:GetJob()
    if not job or job.name ~= 'helitour' then return end

    -- Pay per waypoint (tour pay divided by avg waypoints)
    local tourPay = JobsConfig.HeliTour.payPerTour[job.grade + 1] or JobsConfig.HeliTour.payPerTour[1]
    local pay = math.floor(tourPay / 3) -- 3 waypoints per tour
    pay = ApplyPayMultipliers(src, pay, 'helitour')
    player:AddMoney('cash', pay, 'Heli Tour Waypoint')
    TriggerClientEvent('umeverse_jobs:client:taskPaid', src, pay)
    TriggerEvent('umeverse_jobs:server:taskCompleted', 'helitour')
end)

-- ═══════════════════════════════════════
-- Postal Payment
-- ═══════════════════════════════════════

RegisterNetEvent('umeverse_jobs:server:postalPay', function()
    local src = source
    if IsOnCooldown(src, 'postal') then return end

    local player = UME.GetPlayer(src)
    if not player then return end

    local job = player:GetJob()
    if not job or job.name ~= 'postal' then return end

    local pay = JobsConfig.Postal.payPerPackage[job.grade + 1] or JobsConfig.Postal.payPerPackage[1]
    pay = ApplyPayMultipliers(src, pay, 'postal')
    player:AddMoney('cash', pay, 'Postal Delivery')
    TriggerClientEvent('umeverse_jobs:client:taskPaid', src, pay)
    TriggerEvent('umeverse_jobs:server:taskCompleted', 'postal')
end)

-- ═══════════════════════════════════════
-- Dock Worker Payment
-- ═══════════════════════════════════════

RegisterNetEvent('umeverse_jobs:server:dockPay', function()
    local src = source
    if IsOnCooldown(src, 'dock') then return end

    local player = UME.GetPlayer(src)
    if not player then return end

    local job = player:GetJob()
    if not job or job.name ~= 'dockworker' then return end

    local pay = JobsConfig.DockWorker.payPerCrate[job.grade + 1] or JobsConfig.DockWorker.payPerCrate[1]
    pay = ApplyPayMultipliers(src, pay, 'dockworker')
    player:AddMoney('cash', pay, 'Dock Cargo')
    TriggerClientEvent('umeverse_jobs:client:taskPaid', src, pay)
    TriggerEvent('umeverse_jobs:server:taskCompleted', 'dockworker')
end)

-- ═══════════════════════════════════════
-- Train Engineer Payment
-- ═══════════════════════════════════════

RegisterNetEvent('umeverse_jobs:server:trainPay', function()
    local src = source
    if IsOnCooldown(src, 'train') then return end

    local player = UME.GetPlayer(src)
    if not player then return end

    local job = player:GetJob()
    if not job or job.name ~= 'train' then return end

    local pay = JobsConfig.Train.payPerStation[job.grade + 1] or JobsConfig.Train.payPerStation[1]
    pay = ApplyPayMultipliers(src, pay, 'train')
    player:AddMoney('cash', pay, 'Train Station')
    TriggerClientEvent('umeverse_jobs:client:taskPaid', src, pay)
    TriggerEvent('umeverse_jobs:server:taskCompleted', 'train')
end)

-- ═══════════════════════════════════════
-- Hunter
-- ═══════════════════════════════════════

RegisterNetEvent('umeverse_jobs:server:huntSkinAnimal', function(peltItem, meatItem)
    local src = source
    if IsOnCooldown(src, 'huntskin') then return end

    local player = UME.GetPlayer(src)
    if not player then return end

    local job = player:GetJob()
    if not job or job.name ~= 'hunter' then return end

    -- Validate items are in the animal models config
    local valid = false
    for _, animal in ipairs(JobsConfig.Hunter.animalModels) do
        if animal.pelt == peltItem and animal.meat == meatItem then valid = true break end
    end
    if not valid then return end

    player:AddItem(peltItem, 1)
    player:AddItem(meatItem, 1)
end)

RegisterNetEvent('umeverse_jobs:server:sellHunterGoods', function()
    local src = source
    if IsOnCooldown(src, 'sellhunt') then return end

    local player = UME.GetPlayer(src)
    if not player then return end

    local job = player:GetJob()
    if not job or job.name ~= 'hunter' then return end

    local totalEarned = 0
    for itemName, price in pairs(JobsConfig.Hunter.sellPrices) do
        local count = player:GetItemCount(itemName)
        if count > 0 then
            player:RemoveItem(itemName, count)
            totalEarned = totalEarned + (count * price)
        end
    end

    if totalEarned > 0 then
        totalEarned = ApplyPayMultipliers(src, totalEarned, 'hunter')
        player:AddMoney('cash', totalEarned, 'Hunting Goods Sale')
        TriggerClientEvent('umeverse:client:notify', src, 'Sold hunting goods for $' .. totalEarned, 'success')
        TriggerClientEvent('umeverse_jobs:client:taskPaid', src, totalEarned)
        TriggerEvent('umeverse_jobs:server:taskCompleted', 'hunter')
    else
        TriggerClientEvent('umeverse:client:notify', src, 'You have no hunting goods to sell!', 'error')
    end
end)

-- ═══════════════════════════════════════
-- Farmer
-- ═══════════════════════════════════════

RegisterNetEvent('umeverse_jobs:server:harvestCrop', function(cropItem, yield)
    local src = source
    if IsOnCooldown(src, 'harvest') then return end

    local player = UME.GetPlayer(src)
    if not player then return end

    local job = player:GetJob()
    if not job or job.name ~= 'farmer' then return end

    -- Validate crop item
    local valid = false
    for _, crop in ipairs(JobsConfig.Farmer.cropTypes) do
        if crop.item == cropItem then valid = true break end
    end
    if not valid then return end

    -- Validate yield doesn't exceed max for grade
    local maxYield = JobsConfig.Farmer.yieldPerGrade[job.grade + 1] or JobsConfig.Farmer.yieldPerGrade[1]
    local safeYield = math.min(yield, maxYield)

    player:AddItem(cropItem, safeYield)
end)

RegisterNetEvent('umeverse_jobs:server:sellCrops', function()
    local src = source
    if IsOnCooldown(src, 'sellcrops') then return end

    local player = UME.GetPlayer(src)
    if not player then return end

    local job = player:GetJob()
    if not job or job.name ~= 'farmer' then return end

    local totalEarned = 0
    for itemName, price in pairs(JobsConfig.Farmer.sellPrices) do
        local count = player:GetItemCount(itemName)
        if count > 0 then
            player:RemoveItem(itemName, count)
            totalEarned = totalEarned + (count * price)
        end
    end

    if totalEarned > 0 then
        totalEarned = ApplyPayMultipliers(src, totalEarned, 'farmer')
        player:AddMoney('cash', totalEarned, 'Crop Sale')
        TriggerClientEvent('umeverse:client:notify', src, 'Sold crops for $' .. totalEarned, 'success')
        TriggerClientEvent('umeverse_jobs:client:taskPaid', src, totalEarned)
        TriggerEvent('umeverse_jobs:server:taskCompleted', 'farmer')
    else
        TriggerClientEvent('umeverse:client:notify', src, 'You have no crops to sell!', 'error')
    end
end)

-- ═══════════════════════════════════════
-- Diver / Salvager
-- ═══════════════════════════════════════

RegisterNetEvent('umeverse_jobs:server:salvageDive', function(salvageItem)
    local src = source
    if IsOnCooldown(src, 'salvage') then return end

    local player = UME.GetPlayer(src)
    if not player then return end

    local job = player:GetJob()
    if not job or job.name ~= 'diver' then return end

    -- Validate item
    local valid = false
    for _, s in ipairs(JobsConfig.Diver.salvageItems) do
        if s.item == salvageItem then valid = true break end
    end
    if not valid then return end

    player:AddItem(salvageItem, 1)
end)

RegisterNetEvent('umeverse_jobs:server:sellSalvage', function()
    local src = source
    if IsOnCooldown(src, 'sellsalvage') then return end

    local player = UME.GetPlayer(src)
    if not player then return end

    local job = player:GetJob()
    if not job or job.name ~= 'diver' then return end

    local totalEarned = 0
    for itemName, price in pairs(JobsConfig.Diver.sellPrices) do
        local count = player:GetItemCount(itemName)
        if count > 0 then
            player:RemoveItem(itemName, count)
            totalEarned = totalEarned + (count * price)
        end
    end

    if totalEarned > 0 then
        totalEarned = ApplyPayMultipliers(src, totalEarned, 'diver')
        player:AddMoney('cash', totalEarned, 'Salvage Sale')
        TriggerClientEvent('umeverse:client:notify', src, 'Sold salvage for $' .. totalEarned, 'success')
        TriggerClientEvent('umeverse_jobs:client:taskPaid', src, totalEarned)
        TriggerEvent('umeverse_jobs:server:taskCompleted', 'diver')
    else
        TriggerClientEvent('umeverse:client:notify', src, 'You have no salvage to sell!', 'error')
    end
end)

-- ═══════════════════════════════════════
-- Vineyard Worker
-- ═══════════════════════════════════════

RegisterNetEvent('umeverse_jobs:server:pickGrapes', function(yield)
    local src = source
    if IsOnCooldown(src, 'pickgrapes') then return end

    local player = UME.GetPlayer(src)
    if not player then return end

    local job = player:GetJob()
    if not job or job.name ~= 'vineyard' then return end

    local maxYield = JobsConfig.Vineyard.yieldPerGrade[job.grade + 1] or JobsConfig.Vineyard.yieldPerGrade[1]
    local safeYield = math.min(yield, maxYield)

    player:AddItem('grapes', safeYield)
end)

RegisterNetEvent('umeverse_jobs:server:processGrapes', function()
    local src = source
    if IsOnCooldown(src, 'processgrapes') then return end

    local player = UME.GetPlayer(src)
    if not player then return end

    local job = player:GetJob()
    if not job or job.name ~= 'vineyard' then return end

    local grapeCount = player:GetItemCount('grapes')
    local needed = JobsConfig.Vineyard.grapesPerBottle

    if grapeCount < needed then
        TriggerClientEvent('umeverse:client:notify', src, 'You need ' .. needed .. ' grapes per bottle! (Have: ' .. grapeCount .. ')', 'error')
        return
    end

    -- Process as many bottles as possible
    local bottles = math.floor(grapeCount / needed)
    player:RemoveItem('grapes', bottles * needed)
    player:AddItem('wine_bottle', bottles)
    TriggerClientEvent('umeverse:client:notify', src, 'Processed ' .. bottles .. ' wine bottle(s)!', 'success')
end)

RegisterNetEvent('umeverse_jobs:server:sellVineyard', function()
    local src = source
    if IsOnCooldown(src, 'sellvineyard') then return end

    local player = UME.GetPlayer(src)
    if not player then return end

    local job = player:GetJob()
    if not job or job.name ~= 'vineyard' then return end

    local totalEarned = 0
    for itemName, price in pairs(JobsConfig.Vineyard.sellPrices) do
        local count = player:GetItemCount(itemName)
        if count > 0 then
            player:RemoveItem(itemName, count)
            totalEarned = totalEarned + (count * price)
        end
    end

    if totalEarned > 0 then
        totalEarned = ApplyPayMultipliers(src, totalEarned, 'vineyard')
        player:AddMoney('cash', totalEarned, 'Vineyard Sale')
        TriggerClientEvent('umeverse:client:notify', src, 'Sold vineyard goods for $' .. totalEarned, 'success')
        TriggerClientEvent('umeverse_jobs:client:taskPaid', src, totalEarned)
        TriggerEvent('umeverse_jobs:server:taskCompleted', 'vineyard')
    else
        TriggerClientEvent('umeverse:client:notify', src, 'You have nothing to sell!', 'error')
    end
end)

-- ═══════════════════════════════════════
-- Electrician Payment
-- ═══════════════════════════════════════

RegisterNetEvent('umeverse_jobs:server:electricianPay', function()
    local src = source
    if IsOnCooldown(src, 'electrician') then return end

    local player = UME.GetPlayer(src)
    if not player then return end

    local job = player:GetJob()
    if not job or job.name ~= 'electrician' then return end

    local pay = JobsConfig.Electrician.payPerFix[job.grade + 1] or JobsConfig.Electrician.payPerFix[1]
    pay = ApplyPayMultipliers(src, pay, 'electrician')
    player:AddMoney('cash', pay, 'Electrical Repair')
    TriggerClientEvent('umeverse_jobs:client:taskPaid', src, pay)
    TriggerEvent('umeverse_jobs:server:taskCompleted', 'electrician')
end)

-- ═══════════════════════════════════════
-- Security Guard Payment
-- ═══════════════════════════════════════

RegisterNetEvent('umeverse_jobs:server:securityCheckpoint', function()
    local src = source
    if IsOnCooldown(src, 'security') then return end

    local player = UME.GetPlayer(src)
    if not player then return end

    local job = player:GetJob()
    if not job or job.name ~= 'security' then return end

    local pay = JobsConfig.Security.payPerCheckpoint[job.grade + 1] or JobsConfig.Security.payPerCheckpoint[1]
    pay = ApplyPayMultipliers(src, pay, 'security')
    player:AddMoney('cash', pay, 'Security Patrol')
    TriggerClientEvent('umeverse_jobs:client:taskPaid', src, pay)
    TriggerEvent('umeverse_jobs:server:taskCompleted', 'security')
end)

-- ═══════════════════════════════════════
-- Cleanup on player drop
-- ═══════════════════════════════════════

AddEventHandler('playerDropped', function()
    local src = source
    -- Clear cooldowns for this player
    for key in pairs(cooldowns) do
        if key:find('^' .. src .. ':') then
            cooldowns[key] = nil
        end
    end
end)
