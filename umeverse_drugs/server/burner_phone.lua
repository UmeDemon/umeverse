--[[
    Umeverse Drugs - Burner Phone System (Server)
    Generates drug deal requests via burner phone.
    Deals are higher-risk but higher-reward than street corner sales.
]]

local UME = exports['umeverse_core']:GetCoreObject()

-- Active deals per player: [src] = { deal data }
local activeDeals = {}

-- Deal cooldowns per player
local dealCooldowns = {}

-- ═══════════════════════════════════════
-- Generate a New Deal
-- ═══════════════════════════════════════

local function GenerateDeal(player, src)
    if not DrugConfig.BurnerPhone.enabled then return nil end

    -- Count active deals
    if activeDeals[src] and #activeDeals[src] >= DrugConfig.BurnerPhone.maxActiveDeals then
        return nil
    end

    local rep = GetPlayerDrugRep(player)
    local level = GetDrugLevelFromRep(rep)

    -- Filter eligible deal types
    local eligible = {}
    local totalWeight = 0
    for _, dealType in ipairs(DrugConfig.BurnerPhone.dealTypes) do
        if not dealType.requiredLevel or level >= dealType.requiredLevel then
            eligible[#eligible + 1] = dealType
            totalWeight = totalWeight + dealType.weight
        end
    end

    if #eligible == 0 then return nil end

    -- Weighted random select
    local roll = math.random(totalWeight)
    local cumulative = 0
    local selected = eligible[1]
    for _, dealType in ipairs(eligible) do
        cumulative = cumulative + dealType.weight
        if roll <= cumulative then
            selected = dealType
            break
        end
    end

    -- Pick random drug (from any unlocked)
    local possibleDrugs = {}
    for drugKey, cfg in pairs(DrugConfig.Drugs) do
        if DrugConfig.DrugSellItems then
            -- Find the sellable item for this drug
            for itemName, info in pairs(DrugConfig.DrugSellItems) do
                if info.config == drugKey then
                    local unlockData = nil
                    for l = 1, 10 do
                        if DrugConfig.Progression.levels[l].unlock == cfg.unlockKey then
                            unlockData = DrugConfig.Progression.levels[l]
                            break
                        end
                    end
                    if unlockData and rep >= unlockData.xp then
                        possibleDrugs[#possibleDrugs + 1] = {
                            item = itemName,
                            config = drugKey,
                            label = info.drug,
                            basePrice = cfg.sellPrice,
                        }
                    end
                    break
                end
            end
        end
    end

    if #possibleDrugs == 0 then return nil end

    local drug = possibleDrugs[math.random(#possibleDrugs)]

    -- Calculate deal details
    local priceMult = selected.priceMult.min + math.random() * (selected.priceMult.max - selected.priceMult.min)
    local quantity = math.random(selected.quantity.min, selected.quantity.max)
    local pricePerUnit = math.floor(math.random(drug.basePrice.min, drug.basePrice.max) * priceMult)
    local totalPrice = pricePerUnit * quantity

    -- Pick random meet location
    local meetLoc = DrugConfig.BurnerPhone.meetLocations[math.random(#DrugConfig.BurnerPhone.meetLocations)]

    -- Pick buyer model
    local buyerModel = DrugConfig.BurnerPhone.buyerModels[math.random(#DrugConfig.BurnerPhone.buyerModels)]

    local deal = {
        id = src .. '_' .. os.time() .. '_' .. math.random(1000),
        type = selected,
        drug = drug,
        quantity = quantity,
        pricePerUnit = pricePerUnit,
        totalPrice = totalPrice,
        meetLocation = meetLoc,
        buyerModel = buyerModel,
        expiresAt = os.time() + selected.timeLimit,
        accepted = false,
        completed = false,
    }

    return deal
end

-- ═══════════════════════════════════════
-- Request Deal via Burner Phone
-- ═══════════════════════════════════════

RegisterNetEvent('umeverse_drugs:server:requestDeal', function()
    local src = source
    if not DrugConfig.BurnerPhone.enabled then return end

    local player = UME.GetPlayer(src)
    if not player then return end

    -- Check if player has burner phone
    if not player:HasItem(DrugConfig.BurnerPhone.phoneItem, 1) then
        TriggerClientEvent('umeverse:client:notify', src, 'You need a burner phone!', 'error')
        return
    end

    -- Cooldown
    local now = os.time()
    if dealCooldowns[src] and now - dealCooldowns[src] < 30 then return end
    dealCooldowns[src] = now

    if not activeDeals[src] then activeDeals[src] = {} end

    if #activeDeals[src] >= DrugConfig.BurnerPhone.maxActiveDeals then
        TriggerClientEvent('umeverse:client:notify', src,
            'Max active deals reached! Complete or let them expire.', 'warning')
        return
    end

    local deal = GenerateDeal(player, src)
    if not deal then
        TriggerClientEvent('umeverse:client:notify', src, 'No deals available right now...', 'info')
        return
    end

    activeDeals[src][#activeDeals[src] + 1] = deal

    -- Send deal info to client
    TriggerClientEvent('umeverse_drugs:client:newDeal', src, {
        id = deal.id,
        typeLabel = deal.type.label,
        drugLabel = deal.drug.label,
        drugItem = deal.drug.item,
        quantity = deal.quantity,
        totalPrice = deal.totalPrice,
        pricePerUnit = deal.pricePerUnit,
        meetLocation = deal.meetLocation,
        buyerModel = deal.buyerModel,
        timeLimit = deal.type.timeLimit,
        minPurity = deal.type.minPurity,
    })
end)

-- ═══════════════════════════════════════
-- Accept Deal
-- ═══════════════════════════════════════

RegisterNetEvent('umeverse_drugs:server:acceptDeal', function(dealId)
    local src = source
    if not activeDeals[src] then return end

    for i, deal in ipairs(activeDeals[src]) do
        if deal.id == dealId and not deal.accepted then
            deal.accepted = true
            TriggerClientEvent('umeverse_drugs:client:dealAccepted', src, dealId)
            return
        end
    end
end)

-- ═══════════════════════════════════════
-- Complete Deal (player delivered drugs to location)
-- ═══════════════════════════════════════

RegisterNetEvent('umeverse_drugs:server:completeDeal', function(dealId)
    local src = source
    if not DrugConfig.BurnerPhone.enabled then return end
    if not activeDeals[src] then return end

    local player = UME.GetPlayer(src)
    if not player then return end

    local dealIdx = nil
    local deal = nil
    for i, d in ipairs(activeDeals[src]) do
        if d.id == dealId and d.accepted and not d.completed then
            dealIdx = i
            deal = d
            break
        end
    end

    if not deal then return end

    -- Check if expired
    if os.time() > deal.expiresAt then
        table.remove(activeDeals[src], dealIdx)
        TriggerClientEvent('umeverse:client:notify', src, 'Deal expired!', 'error')
        return
    end

    -- Check player has the drugs
    local count = player:GetItemCount(deal.drug.item)
    if count < deal.quantity then
        TriggerClientEvent('umeverse:client:notify', src,
            'Need ' .. deal.quantity .. 'x ' .. deal.drug.label .. ' (have ' .. count .. ')', 'error')
        return
    end

    -- Remove drugs
    player:RemoveItem(deal.drug.item, deal.quantity)

    -- Pay player
    player:AddMoney('black', deal.totalPrice, 'Burner phone deal: ' .. deal.drug.label)

    -- Add rep
    AddDrugRep(player, deal.type.repGain, src)

    -- Add heat
    local citizenid = player:GetCitizenId()
    AddPlayerHeat(citizenid, deal.type.heatGain, src)

    -- Specialization XP
    if DrugConfig.Specialization.enabled then
        AddSpecXP(citizenid, deal.drug.config, DrugConfig.Specialization.xpRewards.sell, src)
    end

    -- Mark complete and remove
    deal.completed = true
    table.remove(activeDeals[src], dealIdx)

    TriggerClientEvent('umeverse:client:notify', src,
        'Deal complete! Earned $' .. deal.totalPrice .. ' for ' .. deal.quantity .. 'x ' .. deal.drug.label, 'success', 8000)

    -- Police check
    if math.random(100) <= deal.type.policeChance then
        -- Trigger police alert
        local alertCoords = vector3(
            deal.meetLocation.x + math.random(-50, 50),
            deal.meetLocation.y + math.random(-50, 50),
            deal.meetLocation.z
        )
        local players = UME.GetPlayers()
        for _, p in pairs(players) do
            local job = p:GetJob()
            if job and job.type == 'leo' and job.onduty then
                TriggerClientEvent('umeverse_drugs:client:policeAlert', p:GetSource(), alertCoords, DrugConfig.PoliceAlert.alertRadius)
            end
        end
    end

    UME.Log('Burner Deal', player:GetFullName() .. ' completed ' .. deal.type.label .. ' deal for $' .. deal.totalPrice, 16776960)
end)

-- ═══════════════════════════════════════
-- Callback: Get active deals
-- ═══════════════════════════════════════

UME.RegisterServerCallback('umeverse_drugs:getActiveDeals', function(source, cb)
    if not DrugConfig.BurnerPhone.enabled then cb({}) return end

    local deals = activeDeals[source] or {}
    local result = {}
    local now = os.time()

    for i, deal in ipairs(deals) do
        if now <= deal.expiresAt then
            result[#result + 1] = {
                id = deal.id,
                typeLabel = deal.type.label,
                drugLabel = deal.drug.label,
                drugItem = deal.drug.item,
                quantity = deal.quantity,
                totalPrice = deal.totalPrice,
                pricePerUnit = deal.pricePerUnit,
                meetLocation = deal.meetLocation,
                buyerModel = deal.buyerModel,
                timeRemaining = deal.expiresAt - now,
                accepted = deal.accepted,
                minPurity = deal.type.minPurity,
            }
        end
    end

    cb(result)
end)

-- ═══════════════════════════════════════
-- Cleanup expired deals periodically
-- ═══════════════════════════════════════

CreateThread(function()
    if not DrugConfig.BurnerPhone.enabled then return end

    while true do
        Wait(60000) -- Check every minute

        local now = os.time()
        for src, deals in pairs(activeDeals) do
            local alive = {}
            for _, deal in ipairs(deals) do
                if now <= deal.expiresAt then
                    alive[#alive + 1] = deal
                end
            end
            activeDeals[src] = #alive > 0 and alive or nil
        end
    end
end)

-- ═══════════════════════════════════════
-- Cleanup on player disconnect
-- ═══════════════════════════════════════

AddEventHandler('playerDropped', function()
    activeDeals[source] = nil
    dealCooldowns[source] = nil
end)
