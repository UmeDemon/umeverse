--[[
    Umeverse Banking - Server
]]

local UME = exports['umeverse_core']:GetCoreObject()

-- ═══════════════════════════════════════
-- Deposit
-- ═══════════════════════════════════════

RegisterNetEvent('umeverse_banking:server:deposit', function(amount)
    local src = source
    local player = UME.GetPlayer(src)
    if not player then return end

    amount = tonumber(amount)
    if not amount or amount <= 0 then
        UME.Notify(src, 'Invalid amount.', 'error')
        return
    end

    if not player:HasMoney('cash', amount) then
        UME.Notify(src, UME.Translate('money_insufficient'), 'error')
        return
    end

    player:RemoveMoney('cash', amount, 'Bank deposit')
    player:AddMoney('bank', amount, 'Bank deposit')

    LogTransaction(player:GetCitizenId(), 'deposit', amount, 'Cash deposit')
    UME.Notify(src, UME.Translate('bank_deposit', UME.Round(amount, 2)), 'success')

    -- Send updated data to NUI
    SendBankData(src)
end)

-- ═══════════════════════════════════════
-- Withdraw
-- ═══════════════════════════════════════

RegisterNetEvent('umeverse_banking:server:withdraw', function(amount)
    local src = source
    local player = UME.GetPlayer(src)
    if not player then return end

    amount = tonumber(amount)
    if not amount or amount <= 0 then
        UME.Notify(src, 'Invalid amount.', 'error')
        return
    end

    if not player:HasMoney('bank', amount) then
        UME.Notify(src, UME.Translate('money_insufficient'), 'error')
        return
    end

    player:RemoveMoney('bank', amount, 'Bank withdrawal')
    player:AddMoney('cash', amount, 'Bank withdrawal')

    LogTransaction(player:GetCitizenId(), 'withdraw', amount, 'Cash withdrawal')
    UME.Notify(src, UME.Translate('bank_withdraw', UME.Round(amount, 2)), 'success')

    SendBankData(src)
end)

-- ═══════════════════════════════════════
-- Transfer
-- ═══════════════════════════════════════

RegisterNetEvent('umeverse_banking:server:transfer', function(targetId, amount)
    local src = source
    local player = UME.GetPlayer(src)
    if not player then return end

    targetId = tonumber(targetId)
    amount = tonumber(amount)

    if not amount or amount <= 0 then
        UME.Notify(src, 'Invalid amount.', 'error')
        return
    end

    if amount > BankConfig.MaxTransferAmount then
        UME.Notify(src, 'Amount exceeds maximum transfer limit.', 'error')
        return
    end

    if amount < BankConfig.MinTransferAmount then
        UME.Notify(src, 'Amount is below minimum transfer limit.', 'error')
        return
    end

    local target = UME.GetPlayer(targetId)
    if not target then
        UME.Notify(src, 'Player not found or offline.', 'error')
        return
    end

    if src == targetId then
        UME.Notify(src, 'You cannot transfer to yourself.', 'error')
        return
    end

    if not player:HasMoney('bank', amount) then
        UME.Notify(src, UME.Translate('money_insufficient'), 'error')
        return
    end

    player:RemoveMoney('bank', amount, 'Transfer to ' .. target:GetFullName())
    target:AddMoney('bank', amount, 'Transfer from ' .. player:GetFullName())

    LogTransaction(player:GetCitizenId(), 'transfer_out', amount, 'Transfer to ' .. target:GetFullName())
    LogTransaction(target:GetCitizenId(), 'transfer_in', amount, 'Transfer from ' .. player:GetFullName())

    UME.Notify(src, UME.Translate('bank_transfer', UME.Round(amount, 2), target:GetFullName()), 'success')
    UME.Notify(targetId, UME.Translate('bank_transfer_received', UME.Round(amount, 2), player:GetFullName()), 'success')

    SendBankData(src)
end)

-- ═══════════════════════════════════════
-- Open Bank
-- ═══════════════════════════════════════

RegisterNetEvent('umeverse_banking:server:openBank', function()
    local src = source
    SendBankData(src)
end)

function SendBankData(src)
    local player = UME.GetPlayer(src)
    if not player then return end

    -- Get transaction history
    local transactions = MySQL.query.await(
        'SELECT * FROM umeverse_transactions WHERE citizenid = ? ORDER BY created_at DESC LIMIT ?',
        { player:GetCitizenId(), BankConfig.MaxTransactionHistory }
    ) or {}

    TriggerClientEvent('umeverse_banking:client:openBank', src, {
        cash = player:GetMoney('cash'),
        bank = player:GetMoney('bank'),
        name = player:GetFullName(),
        citizenid = player:GetCitizenId(),
        transactions = transactions,
    })
end

-- ═══════════════════════════════════════
-- Transaction Log
-- ═══════════════════════════════════════

function LogTransaction(citizenid, type, amount, description)
    MySQL.insert('INSERT INTO umeverse_transactions (citizenid, type, amount, description) VALUES (?, ?, ?, ?)', {
        citizenid, type, amount, description,
    })
end

-- ═══════════════════════════════════════
-- Server Callbacks
-- ═══════════════════════════════════════

UME.RegisterServerCallback('umeverse_banking:getPlayerList', function(source, cb)
    local players = {}
    for src, player in pairs(UME.GetPlayers()) do
        if src ~= source then
            players[#players + 1] = {
                id = src,
                name = player:GetFullName(),
            }
        end
    end
    cb(players)
end)
