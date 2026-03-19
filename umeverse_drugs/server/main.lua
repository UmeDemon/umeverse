--[[
    Umeverse Drugs - Server Main (Enhanced)
    Data-driven core server handlers with:
    - Quality system (rep-based tiers affect yield)
    - Batch processing (1x/2x/3x/5x)
    - Failure/waste chance (reduced by higher rep)
    - Rep-based yield bonuses
    - Time-of-day yield modifiers
    - Bonus find events from random encounters
    - Progression (drug rep) system and supply shop
]]

local UME = exports['umeverse_core']:GetCoreObject()

-- Anti-spam cooldowns
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

-- ═══════════════════════════════════════
-- Progression Helpers
-- ═══════════════════════════════════════

--- Get player drug rep from metadata
---@param player table Player object
---@return number
function GetPlayerDrugRep(player)
    local meta = player:GetMetadata('drugRep')
    return meta or 0
end

--- Get drug level from rep
---@param rep number
---@return number
function GetDrugLevelFromRep(rep)
    local level = 1
    for l = 10, 1, -1 do
        if rep >= DrugConfig.Progression.levels[l].xp then
            level = l
            break
        end
    end
    return level
end

--- Add drug rep to a player
---@param player table Player object
---@param amount number XP to add
---@param src number server source
function AddDrugRep(player, amount, src)
    local current = GetPlayerDrugRep(player)
    local oldLevel = GetDrugLevelFromRep(current)
    local newRep = current + amount
    player:SetMetadata('drugRep', newRep)

    local newLevel = GetDrugLevelFromRep(newRep)
    if newLevel > oldLevel then
        local levelData = DrugConfig.Progression.levels[newLevel]
        TriggerClientEvent('umeverse:client:notify', src,
            'Drug Rep Level Up! Level ' .. newLevel .. ': ' .. levelData.label, 'success', 8000)

        if levelData.unlock then
            TriggerClientEvent('umeverse:client:notify', src,
                'Unlocked: ' .. levelData.unlock:upper() .. '!', 'success', 8000)
        end
    end
end

--- Check if player has unlocked a drug type
---@param player table
---@param drugType string
---@return boolean
local function HasUnlocked(player, drugType)
    local rep = GetPlayerDrugRep(player)
    for level = 1, 10 do
        local data = DrugConfig.Progression.levels[level]
        if data.unlock == drugType then
            return rep >= data.xp
        end
    end
    return false
end

-- ═══════════════════════════════════════
-- Server-side Modifier Calculations
-- ═══════════════════════════════════════

--- Get quality tier for a given drug level
---@param level number
---@return table tier
local function GetQualityTierForLevel(level)
    if not DrugConfig.Quality.enabled then
        return { name = 'Standard', yieldMult = 1.0, priceMult = 1.0 }
    end
    for _, tier in ipairs(DrugConfig.Quality.tiers) do
        if level >= tier.minLevel and level <= tier.maxLevel then
            return tier
        end
    end
    return DrugConfig.Quality.tiers[1]
end

--- Get rep-based yield multiplier
---@param level number
---@return number
local function GetRepYieldMult(level)
    if not DrugConfig.RepBonuses.yieldEnabled then return 1.0 end
    local bonus = math.min(level * DrugConfig.RepBonuses.yieldPerLevel, DrugConfig.RepBonuses.maxYieldBonus)
    return 1.0 + bonus
end

--- Get time-of-day yield multiplier (server uses real game time)
---@return number
local function GetTimeYieldMult()
    if not DrugConfig.TimeOfDay.enabled then return 1.0 end
    local hour = tonumber(os.date('%H')) or 12
    local isNight = hour >= DrugConfig.TimeOfDay.nightStart or hour < DrugConfig.TimeOfDay.nightEnd
    return isNight and DrugConfig.TimeOfDay.nightBonuses.yieldMult or DrugConfig.TimeOfDay.dayBonuses.yieldMult
end

--- Calculate total yield multiplier for a player (with specialization)
---@param level number drug level
---@param citizenid string|nil player citizen id
---@param drugType string|nil drug config key
---@return number combined multiplier
local function GetTotalYieldMult(level, citizenid, drugType)
    local quality = GetQualityTierForLevel(level)
    local repMult = GetRepYieldMult(level)
    local timeMult = GetTimeYieldMult()
    local specMult = 1.0
    if citizenid and drugType and DrugConfig.Specialization and DrugConfig.Specialization.enabled then
        local bonuses = GetSpecBonuses(citizenid, drugType)
        specMult = 1.0 + (bonuses.yieldBonus or 0)
    end
    return quality.yieldMult * repMult * timeMult * specMult
end

--- Roll failure chance for processing (with specialization reduction)
---@param level number
---@param citizenid string|nil
---@param drugType string|nil
---@return boolean didFail
local function RollFailure(level, citizenid, drugType)
    if not DrugConfig.Failure.enabled then return false end
    local chance = math.max(
        DrugConfig.Failure.baseChance - (level * DrugConfig.Failure.reductionPerLevel),
        DrugConfig.Failure.minChance
    )
    -- Apply specialization fail reduction
    if citizenid and drugType and DrugConfig.Specialization and DrugConfig.Specialization.enabled then
        local bonuses = GetSpecBonuses(citizenid, drugType)
        chance = math.max(chance - (bonuses.failReduction or 0), 0)
    end
    return math.random(100) <= chance
end

--- Validate batch size is allowed for the player's level
---@param batchSize number
---@param level number
---@return number sanitized batch size (clamped to what's allowed)
local function ValidateBatchSize(batchSize, level)
    if not DrugConfig.Batching.enabled then return 1 end
    if type(batchSize) ~= 'number' then return 1 end

    local maxAllowed = 1
    for _, batch in ipairs(DrugConfig.Batching.sizes) do
        if level >= batch.requiredLevel and batch.size > maxAllowed then
            maxAllowed = batch.size
        end
    end

    return math.min(math.max(math.floor(batchSize), 1), maxAllowed)
end

-- ═══════════════════════════════════════
-- Gathering Handler (Enhanced)
-- ═══════════════════════════════════════

RegisterNetEvent('umeverse_drugs:server:gather', function(drugType)
    local src = source
    if IsOnCooldown(src, 'gather_' .. tostring(drugType)) then return end

    local player = UME.GetPlayer(src)
    if not player then return end

    local cfg = DrugConfig.Drugs[drugType]
    if not cfg then return end

    if not HasUnlocked(player, cfg.unlockKey) then return end

    local citizenid = player:GetCitizenId()

    -- NPC-type gathering requires cash
    if cfg.gatherType == 'npc' and cfg.gatherCost then
        if not player:HasMoney('cash', cfg.gatherCost) then
            TriggerClientEvent('umeverse:client:notify', src, 'Not enough cash! Need $' .. cfg.gatherCost, 'error')
            return
        end
        player:RemoveMoney('cash', cfg.gatherCost, 'Purchase: ' .. cfg.gatherItem)
    end

    local rep = GetPlayerDrugRep(player)
    local level = GetDrugLevelFromRep(rep)

    -- Base amount + yield multipliers (including specialization)
    local baseAmount = math.random(cfg.gatherAmount[1], cfg.gatherAmount[2])
    local yieldMult = GetTotalYieldMult(level, citizenid, drugType)
    local amount = math.max(1, math.floor(baseAmount * yieldMult + 0.5))

    player:AddItem(cfg.gatherItem, amount)
    AddDrugRep(player, DrugConfig.Progression.xpRewards.gather, src)

    -- Heat gain
    if DrugConfig.Heat and DrugConfig.Heat.enabled then
        AddPlayerHeat(citizenid, DrugConfig.Heat.gains.gather, src)
    end

    -- Specialization XP
    if DrugConfig.Specialization and DrugConfig.Specialization.enabled then
        AddSpecXP(citizenid, drugType, DrugConfig.Specialization.xpRewards.gather or 3, src)
    end

    local label = UME.GetItemLabel(cfg.gatherItem) or cfg.gatherItem
    local quality = GetQualityTierForLevel(level)
    TriggerClientEvent('umeverse:client:notify', src,
        'Got ' .. amount .. 'x ' .. label .. ' (' .. quality.name .. ' quality)', 'success')
end)

-- ═══════════════════════════════════════
-- Processing Handler (Enhanced with Batching + Failure)
-- ═══════════════════════════════════════

RegisterNetEvent('umeverse_drugs:server:process', function(drugType, batchSize)
    local src = source
    if IsOnCooldown(src, 'process_' .. tostring(drugType)) then return end

    local player = UME.GetPlayer(src)
    if not player then return end

    local cfg = DrugConfig.Drugs[drugType]
    if not cfg then return end

    if not HasUnlocked(player, cfg.unlockKey) then return end

    local citizenid = player:GetCitizenId()
    local rep = GetPlayerDrugRep(player)
    local level = GetDrugLevelFromRep(rep)
    batchSize = ValidateBatchSize(batchSize, level)

    local recipe = cfg.processRecipe

    -- Check all input items (multiplied by batch size)
    for _, input in ipairs(recipe.input) do
        local needed = input.amount * batchSize
        local count = player:GetItemCount(input.item)
        if count < needed then
            local label = UME.GetItemLabel(input.item) or input.item
            TriggerClientEvent('umeverse:client:notify', src,
                'Need ' .. needed .. 'x ' .. label .. ' (have ' .. count .. ')', 'error')
            return
        end
    end

    -- Remove inputs (full batch)
    for _, input in ipairs(recipe.input) do
        player:RemoveItem(input.item, input.amount * batchSize)
    end

    -- Process each batch individually for failure rolls
    local totalOutput = 0
    local failedBatches = 0
    local yieldMult = GetTotalYieldMult(level, citizenid, drugType)

    for i = 1, batchSize do
        local failed = RollFailure(level, citizenid, drugType)
        if failed then
            failedBatches = failedBatches + 1
            if DrugConfig.Failure.partialOutput then
                -- Partial output on failure
                local partial = math.max(1, math.floor(recipe.output.amount * DrugConfig.Failure.partialFraction * yieldMult + 0.5))
                totalOutput = totalOutput + partial
            end
            -- If not partialOutput, this batch produces nothing
        else
            -- Successful batch — apply yield multipliers
            local batchOutput = math.max(1, math.floor(recipe.output.amount * yieldMult + 0.5))
            totalOutput = totalOutput + batchOutput
        end
    end

    -- Give total output
    if totalOutput > 0 then
        player:AddItem(recipe.output.item, totalOutput)
    end

    AddDrugRep(player, DrugConfig.Progression.xpRewards.process * batchSize, src)

    -- Heat gain
    if DrugConfig.Heat and DrugConfig.Heat.enabled then
        AddPlayerHeat(citizenid, DrugConfig.Heat.gains.process * batchSize, src)
    end

    -- Specialization XP
    if DrugConfig.Specialization and DrugConfig.Specialization.enabled then
        AddSpecXP(citizenid, drugType, (DrugConfig.Specialization.xpRewards.process or 5) * batchSize, src)
    end

    local label = UME.GetItemLabel(recipe.output.item) or recipe.output.item
    local quality = GetQualityTierForLevel(level)

    if failedBatches > 0 then
        TriggerClientEvent('umeverse:client:notify', src,
            'Produced ' .. totalOutput .. 'x ' .. label ..
            ' (' .. quality.name .. ') — ' .. failedBatches .. ' batch(es) had issues!', 'warning', 8000)
    else
        local batchTag = batchSize > 1 and (' [' .. batchSize .. 'x batch]') or ''
        TriggerClientEvent('umeverse:client:notify', src,
            'Produced ' .. totalOutput .. 'x ' .. label .. ' (' .. quality.name .. ')' .. batchTag, 'success')
    end
end)

-- ═══════════════════════════════════════
-- Packaging Handler (Enhanced with Batching + Quality)
-- ═══════════════════════════════════════

RegisterNetEvent('umeverse_drugs:server:package', function(drugType, batchSize)
    local src = source
    if IsOnCooldown(src, 'package_' .. tostring(drugType)) then return end

    local player = UME.GetPlayer(src)
    if not player then return end

    local cfg = DrugConfig.Drugs[drugType]
    if not cfg then return end

    if not HasUnlocked(player, cfg.unlockKey) then return end

    local citizenid = player:GetCitizenId()
    local rep = GetPlayerDrugRep(player)
    local level = GetDrugLevelFromRep(rep)
    batchSize = ValidateBatchSize(batchSize, level)

    local recipe = cfg.packageRecipe

    -- Check all input items (multiplied by batch size)
    for _, input in ipairs(recipe.input) do
        local needed = input.amount * batchSize
        local count = player:GetItemCount(input.item)
        if count < needed then
            local label = UME.GetItemLabel(input.item) or input.item
            TriggerClientEvent('umeverse:client:notify', src,
                'Need ' .. needed .. 'x ' .. label .. ' (have ' .. count .. ')', 'error')
            return
        end
    end

    -- Remove inputs (full batch)
    for _, input in ipairs(recipe.input) do
        player:RemoveItem(input.item, input.amount * batchSize)
    end

    -- Calculate yield with all multipliers including specialization (packaging has no failure)
    local yieldMult = GetTotalYieldMult(level, citizenid, drugType)
    local baseOutput = recipe.output.amount * batchSize
    local totalOutput = math.max(1, math.floor(baseOutput * yieldMult + 0.5))

    player:AddItem(recipe.output.item, totalOutput)
    AddDrugRep(player, DrugConfig.Progression.xpRewards.package * batchSize, src)

    -- Heat gain
    if DrugConfig.Heat and DrugConfig.Heat.enabled then
        AddPlayerHeat(citizenid, DrugConfig.Heat.gains.package * batchSize, src)
    end

    -- Specialization XP
    if DrugConfig.Specialization and DrugConfig.Specialization.enabled then
        AddSpecXP(citizenid, drugType, (DrugConfig.Specialization.xpRewards.package or 4) * batchSize, src)
    end

    local label = UME.GetItemLabel(recipe.output.item) or recipe.output.item
    local quality = GetQualityTierForLevel(level)
    local batchTag = batchSize > 1 and (' [' .. batchSize .. 'x batch]') or ''
    TriggerClientEvent('umeverse:client:notify', src,
        'Packaged ' .. totalOutput .. 'x ' .. label .. ' (' .. quality.name .. ')' .. batchTag, 'success')
end)

-- ═══════════════════════════════════════
-- Bonus Find (Random Encounter Reward)
-- ═══════════════════════════════════════

RegisterNetEvent('umeverse_drugs:server:bonusFind', function()
    local src = source
    if IsOnCooldown(src, 'bonusFind') then return end

    local player = UME.GetPlayer(src)
    if not player then return end

    -- Give a random raw material from any unlocked drug
    local possibleItems = {}
    for _, cfg in pairs(DrugConfig.Drugs) do
        if HasUnlocked(player, cfg.unlockKey) then
            possibleItems[#possibleItems + 1] = cfg.gatherItem
        end
    end

    if #possibleItems == 0 then return end

    local item = possibleItems[math.random(#possibleItems)]
    local amount = math.random(3, 8)
    player:AddItem(item, amount)

    local label = UME.GetItemLabel(item) or item
    TriggerClientEvent('umeverse:client:notify', src,
        'Found a hidden stash! Got ' .. amount .. 'x ' .. label, 'success', 6000)
    AddDrugRep(player, 5, src)
end)

-- ═══════════════════════════════════════
-- Supply Shop (Buy packaging materials)
-- ═══════════════════════════════════════

RegisterNetEvent('umeverse_drugs:server:buySupply', function(itemName, price)
    local src = source
    if IsOnCooldown(src, 'supply') then return end

    local player = UME.GetPlayer(src)
    if not player then return end

    -- Validate item exists in a supply shop
    local validItem = false
    local validPrice = 0
    for _, shop in ipairs(DrugConfig.SupplyShops) do
        for _, item in ipairs(shop.items) do
            if item.item == itemName then
                validItem = true
                validPrice = item.price
                break
            end
        end
        if validItem then break end
    end

    if not validItem then return end

    -- Use the server-authoritative price, not the client-sent one
    if not player:HasMoney('cash', validPrice) then
        TriggerClientEvent('umeverse:client:notify', src, 'Not enough cash! Need $' .. validPrice, 'error')
        return
    end

    player:RemoveMoney('cash', validPrice, 'Supply purchase: ' .. itemName)
    player:AddItem(itemName, 1)

    local label = UME.GetItemLabel(itemName) or itemName
    TriggerClientEvent('umeverse:client:notify', src, 'Bought 1x ' .. label, 'success')
end)

-- ═══════════════════════════════════════
-- Admin Command: Set Drug Rep
-- ═══════════════════════════════════════

RegisterCommand('setdrugrep', function(source, args)
    local src = source
    if src > 0 and not UME.HasPermission(src, 'umeverse.admin') then return end

    local targetId = tonumber(args[1])
    local repAmount = tonumber(args[2])

    if not targetId or not repAmount then
        if src > 0 then
            TriggerClientEvent('umeverse:client:notify', src, 'Usage: /setdrugrep [id] [amount]', 'error')
        else
            print('Usage: setdrugrep [id] [amount]')
        end
        return
    end

    local player = UME.GetPlayer(targetId)
    if not player then
        if src > 0 then
            TriggerClientEvent('umeverse:client:notify', src, 'Player not found', 'error')
        end
        return
    end

    player:SetMetadata('drugRep', repAmount)
    local level = GetDrugLevelFromRep(repAmount)
    local levelData = DrugConfig.Progression.levels[level]

    if src > 0 then
        TriggerClientEvent('umeverse:client:notify', src,
            'Set drug rep to ' .. repAmount .. ' (Level ' .. level .. ': ' .. levelData.label .. ')', 'success')
    end
    TriggerClientEvent('umeverse:client:notify', targetId,
        'Drug rep updated! Level ' .. level .. ': ' .. levelData.label, 'info')
end, false)

-- ═══════════════════════════════════════
-- Player Command: Check Drug Rep (Enhanced)
-- ═══════════════════════════════════════

RegisterCommand('drugrep', function(source)
    local src = source
    if src <= 0 then return end

    local player = UME.GetPlayer(src)
    if not player then return end

    local rep = GetPlayerDrugRep(player)
    local level = GetDrugLevelFromRep(rep)
    local levelData = DrugConfig.Progression.levels[level]
    local quality = GetQualityTierForLevel(level)

    local nextLevel = DrugConfig.Progression.levels[level + 1]
    local nextXp = nextLevel and nextLevel.xp or rep
    local remaining = nextXp - rep

    local failChance = DrugConfig.Failure.enabled
        and math.max(DrugConfig.Failure.baseChance - (level * DrugConfig.Failure.reductionPerLevel), DrugConfig.Failure.minChance)
        or 0

    TriggerClientEvent('umeverse:client:notify', src,
        'Drug Rep: ' .. rep .. ' XP | Level ' .. level .. ': ' .. levelData.label ..
        ' | Quality: ' .. quality.name ..
        ' | Fail: ' .. failChance .. '%' ..
        ' | Next: ' .. remaining .. ' XP needed', 'info', 12000)
end, false)
