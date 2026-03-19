--[[
    Umeverse Drugs - Server Selling
    Handles drug sale validation, pricing, dirty money, and police alerts
]]

local UME = exports['umeverse_core']:GetCoreObject()

local sellCooldowns = {}

-- ═══════════════════════════════════════
-- Drug Sale Handler
-- ═══════════════════════════════════════

RegisterNetEvent('umeverse_drugs:server:sellDrug', function(cornerIdx, drugItem)
    local src = source

    -- Validate corner index
    local corner = DrugConfig.SellCorners[cornerIdx]
    if not corner then return end

    -- Cooldown check (server-side authoritative)
    local coolKey = src .. ':sell:' .. cornerIdx
    local now = os.time()
    if sellCooldowns[coolKey] and now - sellCooldowns[coolKey] < DrugConfig.SellCooldown then return end
    sellCooldowns[coolKey] = now

    local player = UME.GetPlayer(src)
    if not player then return end

    local citizenid = player:GetCitizenId()

    -- Validate drug item is sold at this corner
    local validDrug = false
    for _, drug in ipairs(corner.drugs) do
        if drug == drugItem then
            validDrug = true
            break
        end
    end
    if not validDrug then return end

    -- Check player has the drug
    local drugInfo = DrugConfig.DrugSellItems[drugItem]
    if not drugInfo then return end

    -- Buyer rep bulk amount
    local sellAmount = DrugConfig.SellAmount
    if DrugConfig.BuyerRep and DrugConfig.BuyerRep.enabled then
        local bulkAmt = GetBuyerBulkAmount(citizenid, cornerIdx)
        if bulkAmt > 1 then
            sellAmount = math.min(bulkAmt, player:GetItemCount(drugItem))
        end
    end
    sellAmount = math.max(1, sellAmount)

    if not player:HasItem(drugItem, sellAmount) then
        TriggerClientEvent('umeverse:client:notify', src, 'You don\'t have enough ' .. drugInfo.drug .. ' to sell!', 'error')
        return
    end

    -- Get price config for this drug
    local cfg = DrugConfig.Drugs[drugInfo.config]
    if not cfg then return end

    local rep = GetPlayerDrugRep(player)
    local level = GetDrugLevelFromRep(rep)

    -- Base price per unit (random within range)
    local basePrice = math.random(cfg.sellPrice.min, cfg.sellPrice.max)

    -- === Purity price modifier ===
    local purityMod = 0
    if DrugConfig.Purity and DrugConfig.Purity.enabled then
        local quality = nil
        for _, tier in ipairs(DrugConfig.Quality.tiers) do
            if level >= tier.minLevel and level <= tier.maxLevel then
                quality = tier
                break
            end
        end
        if quality then
            local range = DrugConfig.Purity.basePurityByTier[quality.name]
            if range then
                local purity = math.random(range[1], range[2])
                local diff = purity - DrugConfig.Purity.basePurityRef
                purityMod = math.floor(diff * DrugConfig.Purity.pricePerPurityPoint * basePrice + 0.5)
            end
        end
    end

    -- === Dynamic pricing modifier ===
    local demandMult = 1.0
    if DrugConfig.DynamicPricing and DrugConfig.DynamicPricing.enabled then
        demandMult = GetDemandPriceMult(cornerIdx, drugInfo.config)
    end

    -- === Buyer rep price bonus ===
    local buyerBonus = 0
    if DrugConfig.BuyerRep and DrugConfig.BuyerRep.enabled then
        buyerBonus = GetBuyerPriceBonus(citizenid, cornerIdx)
    end

    -- === Turf sell bonus ===
    local turfBonus = 0
    if DrugConfig.Turf and DrugConfig.Turf.enabled then
        turfBonus = GetTurfSellBonus(citizenid, cornerIdx)
    end

    -- Calculate final price per unit
    local pricePerUnit = basePrice + purityMod
    pricePerUnit = math.floor(pricePerUnit * demandMult + 0.5)
    pricePerUnit = math.floor(pricePerUnit * (1.0 + buyerBonus + turfBonus) + 0.5)
    pricePerUnit = math.max(1, pricePerUnit) -- Never below $1

    local totalPrice = pricePerUnit * sellAmount

    -- Remove drug from inventory
    player:RemoveItem(drugItem, sellAmount)

    -- Add dirty money (black money)
    player:AddMoney('black', totalPrice, 'Drug sale: ' .. drugInfo.drug)

    -- Add drug rep
    AddDrugRep(player, DrugConfig.Progression.xpRewards.sell * sellAmount, src)

    -- === Post-sale system hooks ===

    -- Heat gain
    if DrugConfig.Heat and DrugConfig.Heat.enabled then
        AddPlayerHeat(citizenid, DrugConfig.Heat.gains.sell * sellAmount, src)
    end

    -- Specialization XP
    if DrugConfig.Specialization and DrugConfig.Specialization.enabled then
        AddSpecXP(citizenid, drugInfo.config, (DrugConfig.Specialization.xpRewards.sell or 8) * sellAmount, src)
    end

    -- Buyer reputation
    if DrugConfig.BuyerRep and DrugConfig.BuyerRep.enabled then
        local purityForRep = 50 -- default
        if DrugConfig.Purity and DrugConfig.Purity.enabled then
            local quality = nil
            for _, tier in ipairs(DrugConfig.Quality.tiers) do
                if level >= tier.minLevel and level <= tier.maxLevel then
                    quality = tier
                    break
                end
            end
            if quality then
                local range = DrugConfig.Purity.basePurityByTier[quality.name]
                if range then purityForRep = math.random(range[1], range[2]) end
            end
        end
        AddBuyerRep(citizenid, cornerIdx, purityForRep, src)
    end

    -- Reduce demand at this corner
    if DrugConfig.DynamicPricing and DrugConfig.DynamicPricing.enabled then
        ReduceDemand(cornerIdx, drugInfo.config)
    end

    -- Build sale feedback
    local bonusInfo = ''
    if demandMult > 1.01 then bonusInfo = bonusInfo .. ' ~g~+demand' end
    if demandMult < 0.99 then bonusInfo = bonusInfo .. ' ~r~-demand' end
    if buyerBonus > 0 then bonusInfo = bonusInfo .. ' ~g~+buyer' end
    if turfBonus > 0 then bonusInfo = bonusInfo .. ' ~g~+turf' end
    if purityMod > 0 then bonusInfo = bonusInfo .. ' ~g~+purity' end
    if purityMod < 0 then bonusInfo = bonusInfo .. ' ~r~-purity' end

    local qtyTag = sellAmount > 1 and (sellAmount .. 'x ') or ''

    -- Notify seller
    TriggerClientEvent('umeverse_drugs:client:saleComplete', src, totalPrice, qtyTag .. drugInfo.drug .. bonusInfo)

    -- Police alert chance (scaled by heat)
    if DrugConfig.PoliceAlert.enabled then
        local alertChance = DrugConfig.PoliceAlert.alertChance
        if DrugConfig.Heat and DrugConfig.Heat.enabled then
            local heatMult = GetHeatAlertMult(citizenid)
            alertChance = math.floor(alertChance * heatMult + 0.5)
        end
        local roll = math.random(1, 100)
        if roll <= alertChance then
            TriggerPoliceAlert(corner.coords)
        end
    end

    -- Log the sale
    UME.Log('Drug Sale', player:GetFullName() .. ' sold ' .. qtyTag .. drugInfo.drug .. ' for $' .. totalPrice .. ' at ' .. corner.label, 16711680)
end)

-- ═══════════════════════════════════════
-- Police Alert System
-- ═══════════════════════════════════════

function TriggerPoliceAlert(coords)
    local alertCoords = vector3(
        coords.x + math.random(-50, 50),
        coords.y + math.random(-50, 50),
        coords.z
    )

    -- Alert all on-duty LEOs
    local players = UME.GetPlayers()
    for _, player in pairs(players) do
        local job = player:GetJob()
        if job and job.type == 'leo' and job.onduty then
            TriggerClientEvent('umeverse_drugs:client:policeAlert', player:GetSource(), alertCoords, DrugConfig.PoliceAlert.alertRadius)
        end
    end
end

-- Helper functions are defined in server/main.lua and available in the same runtime

-- ═══════════════════════════════════════
-- Sell Info Callback (demand, buyer rep, turf)
-- ═══════════════════════════════════════

UME.RegisterServerCallback('umeverse_drugs:getSellInfo', function(src, cb, cornerIdx)
    local player = UME.GetPlayer(src)
    if not player then cb({}) return end

    local citizenid = player:GetCitizenId()
    local result = {}

    -- Demand per drug at this corner
    if DrugConfig.DynamicPricing and DrugConfig.DynamicPricing.enabled then
        result.demand = {}
        local corner = DrugConfig.SellCorners[cornerIdx]
        if corner then
            for _, drugItem in ipairs(corner.drugs) do
                local info = DrugConfig.DrugSellItems[drugItem]
                if info then
                    result.demand[info.config] = GetDemand(cornerIdx, info.config)
                end
            end
        end
    end

    -- Buyer rep level
    if DrugConfig.BuyerRep and DrugConfig.BuyerRep.enabled then
        local rep = GetBuyerRep(citizenid, cornerIdx)
        local levelIdx = GetBuyerLevel(citizenid, cornerIdx)
        result.buyerLevel = levelIdx
        local levelData = DrugConfig.BuyerRep.levels[levelIdx]
        result.buyerLevelLabel = levelData and levelData.label or 'Unknown'
        result.buyerPriceBonus = GetBuyerPriceBonus(citizenid, cornerIdx)
    end

    -- Turf ownership
    if DrugConfig.Turf and DrugConfig.Turf.enabled then
        result.ownsTurf = PlayerOwnsTurf(citizenid, cornerIdx)
        result.turfBonus = result.ownsTurf and (DrugConfig.Turf.turfSellBonus / 100) or 0
    end

    cb(result)
end)
