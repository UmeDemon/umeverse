--[[
    Umeverse Drugs - Server Money Laundering
    Convert dirty money (black money) to clean bank money
    Rate depends on drug rep level
]]

local UME = exports['umeverse_core']:GetCoreObject()

local launderCooldowns = {}

-- ═══════════════════════════════════════
-- Launder Money Handler
-- ═══════════════════════════════════════

RegisterNetEvent('umeverse_drugs:server:launderMoney', function(locationIdx, amount)
    local src = source

    -- Validate location
    local loc = DrugConfig.Laundering.locations[locationIdx]
    if not loc then return end

    -- Server-side cooldown
    local coolKey = src .. ':launder'
    local now = os.time()
    if launderCooldowns[coolKey] and now - launderCooldowns[coolKey] < DrugConfig.Laundering.cooldown then
        TriggerClientEvent('umeverse:client:notify', src, 'Laundering on cooldown!', 'error')
        return
    end

    local player = UME.GetPlayer(src)
    if not player then return end

    -- Validate amount within config bounds
    if type(amount) ~= 'number' then return end
    amount = math.floor(amount)
    if amount < DrugConfig.Laundering.minAmount or amount > DrugConfig.Laundering.maxAmount then
        TriggerClientEvent('umeverse:client:notify', src,
            'Amount must be between $' .. DrugConfig.Laundering.minAmount .. ' and $' .. DrugConfig.Laundering.maxAmount, 'error')
        return
    end

    -- Check player has enough dirty money (black money)
    if not player:HasMoney('black', amount) then
        local blackMoney = player:GetMoney('black')
        TriggerClientEvent('umeverse:client:notify', src,
            'Not enough dirty money! You have $' .. blackMoney, 'error')
        return
    end

    -- Calculate clean amount based on drug rep level
    local rep = player:GetMetadata('drugRep') or 0
    local level = 1
    for l = 10, 1, -1 do
        if rep >= DrugConfig.Progression.levels[l].xp then level = l break end
    end
    local rate = DrugConfig.Laundering.rates[level] or 0.55
    local cleanAmount = math.floor(amount * rate)

    -- Execute the laundering
    player:RemoveMoney('black', amount, 'Money laundering at ' .. loc.label)
    player:AddMoney('bank', cleanAmount, 'Laundered income via ' .. loc.label)

    -- Set cooldown
    launderCooldowns[coolKey] = now

    -- Add drug rep
    local newRep = rep + DrugConfig.Progression.xpRewards.launder
    player:SetMetadata('drugRep', newRep)

    -- Notify client
    TriggerClientEvent('umeverse_drugs:client:launderComplete', src, amount, cleanAmount)

    -- Log transaction
    MySQL.insert('INSERT INTO umeverse_drug_transactions (citizenid, type, dirty_amount, clean_amount, location, created_at) VALUES (?, ?, ?, ?, ?, NOW())',
        { player:GetCitizenId(), 'launder', amount, cleanAmount, loc.id })

    -- Discord log
    UME.Log('Money Laundering', player:GetFullName() .. ' laundered $' .. amount .. ' → $' .. cleanAmount .. ' at ' .. loc.label .. ' (Rate: ' .. math.floor(rate * 100) .. '%)', 65280)
end)
