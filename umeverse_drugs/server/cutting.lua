--[[
    Umeverse Drugs - Cutting / Mixing System
    Post-packaging step: cut drugs with fillers to increase quantity
    at the cost of purity. Server-side validation and item handling.
]]

local UME = exports['umeverse_core']:GetCoreObject()

-- Anti-spam
local cutCooldowns = {}

-- ═══════════════════════════════════════
-- Cut Drug Handler
-- ═══════════════════════════════════════

RegisterNetEvent('umeverse_drugs:server:cutDrug', function(drugItem, agentItem, quantity)
    local src = source
    if not DrugConfig.Cutting.enabled then return end

    -- Cooldown
    local now = GetGameTimer()
    if cutCooldowns[src] and now - cutCooldowns[src] < 5000 then return end
    cutCooldowns[src] = now

    local player = UME.GetPlayer(src)
    if not player then return end

    -- Validate quantity
    quantity = type(quantity) == 'number' and math.max(1, math.floor(quantity)) or 1

    -- Find the cutting agent config
    local agentCfg = nil
    for _, agent in ipairs(DrugConfig.Cutting.agents) do
        if agent.item == agentItem then
            agentCfg = agent
            break
        end
    end
    if not agentCfg then return end

    -- Check if this drug is compatible with the agent
    local compatible = false
    for _, drug in ipairs(agentCfg.compatibleDrugs) do
        if drug == drugItem then
            compatible = true
            break
        end
    end
    if not compatible then
        TriggerClientEvent('umeverse:client:notify', src,
            'This cutting agent can\'t be used with that drug!', 'error')
        return
    end

    -- Check player has the drug and agent
    local drugCount = player:GetItemCount(drugItem)
    if drugCount < quantity then
        TriggerClientEvent('umeverse:client:notify', src,
            'Need ' .. quantity .. 'x ' .. drugItem .. ' (have ' .. drugCount .. ')', 'error')
        return
    end

    -- Agent needed: 1 per item being cut
    local agentNeeded = quantity
    local agentCount = player:GetItemCount(agentItem)
    if agentCount < agentNeeded then
        TriggerClientEvent('umeverse:client:notify', src,
            'Need ' .. agentNeeded .. 'x ' .. agentCfg.label .. ' (have ' .. agentCount .. ')', 'error')
        return
    end

    -- Remove inputs
    player:RemoveItem(drugItem, quantity)
    player:RemoveItem(agentItem, agentNeeded)

    -- Calculate output quantity (increased by cutting agent)
    local outputQuantity = math.floor(quantity * agentCfg.quantityMult + 0.5)

    -- Calculate new purity (reduced by cutting)
    -- If purity system is enabled, we get purity from metadata
    -- For simplicity, we use the average purity or a fallback
    local currentPurity = 70 -- Default if no purity metadata
    if DrugConfig.Purity.enabled then
        -- Purity is tracked server-side based on the player's quality tier
        local rep = GetPlayerDrugRep(player)
        local level = GetDrugLevelFromRep(rep)
        local quality = nil
        for _, tier in ipairs(DrugConfig.Quality.tiers) do
            if level >= tier.minLevel and level <= tier.maxLevel then
                quality = tier
                break
            end
        end
        if quality then
            local tierName = quality.name
            local purityRange = DrugConfig.Purity.basePurityByTier[tierName]
            if purityRange then
                currentPurity = math.random(purityRange.min, purityRange.max)
            end
        end
    end

    local newPurity = math.max(DrugConfig.Cutting.minPurity, currentPurity - agentCfg.purityLoss)

    -- Give output
    player:AddItem(drugItem, outputQuantity)

    -- Add drug rep for cutting
    AddDrugRep(player, 2, src)

    -- Add heat for cutting
    local citizenid = player:GetCitizenId()
    AddPlayerHeat(citizenid, 1, src)

    local drugLabel = UME.GetItemLabel(drugItem) or drugItem
    TriggerClientEvent('umeverse:client:notify', src,
        'Cut ' .. quantity .. 'x → ' .. outputQuantity .. 'x ' .. drugLabel ..
        ' (Purity: ' .. newPurity .. '%)', 'success', 8000)

    TriggerClientEvent('umeverse_drugs:client:cutComplete', src, drugItem, outputQuantity, newPurity)
end)
