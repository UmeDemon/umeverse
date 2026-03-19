--[[
    Umeverse Gangs System - Main Server
]]

GangSystem = {}
GangSystem.Gangs = {}
GangSystem.PlayerGangs = {}
GangSystem.Territories = {}
GangSystem.GangWars = {}

-- Initialize gang system from database
function GangSystem.Initialize()
    MySQL.query('SELECT * FROM umeverse_gangs', {}, function(result)
        if result and #result > 0 then
            for _, gang in ipairs(result) do
                GangSystem.Gangs[gang.gang_name] = {
                    name = gang.gang_name,
                    label = gang.label,
                    leader = gang.leader_id,
                    members = 0,
                    bank = gang.bank_balance,
                    reputation = gang.reputation,
                    territory = gang.territory,
                    wars = 0,
                }
            end
        end
    end)
    
    -- Load user gang data
    MySQL.query('SELECT * FROM umeverse_gang_members', {}, function(result)
        if result and #result > 0 then
            for _, member in ipairs(result) do
                GangSystem.PlayerGangs[member.identifier] = {
                    gang = member.gang_name,
                    rank = member.rank,
                    joinedAt = member.joined_date,
                    reputation = member.reputation,
                }
            end
        end
    end)
end

-- Create new gang
function GangSystem.CreateGang(src, gangName, label)
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return false end
    
    if GangSystem.Gangs[gangName] then
        return false, 'Gang already exists'
    end
    
    local data = {
        gang_name = gangName,
        label = label,
        leader_id = Player.PlayerData.citizenid,
        bank_balance = 0,
        reputation = 0,
        founded_date = os.time(),
        territory = 'none',
    }
    
    MySQL.insert('INSERT INTO umeverse_gangs (gang_name, label, leader_id, bank_balance, reputation, founded_date, territory) VALUES (?, ?, ?, ?, ?, ?, ?)',
        { data.gang_name, data.label, data.leader_id, data.bank_balance, data.reputation, data.founded_date, data.territory },
        function(lastId)
            GangSystem.Gangs[gangName] = data
            GangSystem.AddMemberToGang(src, gangName, 5) -- Leader rank
            TriggerClientEvent('umeverse_gangs:notify', src, 'success', 'Gang created: ' .. label)
        end
    )
    
    return true
end

-- Add member to gang
function GangSystem.AddMemberToGang(src, gangName, rank)
    rank = rank or 0 -- Default to Prospect
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return false end
    
    local data = {
        identifier = Player.PlayerData.citizenid,
        gang_name = gangName,
        rank = rank,
        joined_date = os.time(),
        reputation = 0,
    }
    
    MySQL.insert('INSERT INTO umeverse_gang_members (identifier, gang_name, rank, joined_date, reputation) VALUES (?, ?, ?, ?, ?)',
        { data.identifier, data.gang_name, data.rank, data.joined_date, data.reputation },
        function(lastId)
            GangSystem.PlayerGangs[Player.PlayerData.citizenid] = {
                gang = gangName,
                rank = rank,
                joinedAt = data.joined_date,
                reputation = 0,
            }
            TriggerClientEvent('umeverse_gangs:updateGang', src, gangName)
            TriggerClientEvent('umeverse_gangs:notify', src, 'success', 'Joined gang: ' .. GangSystem.Gangs[gangName].label)
        end
    )
    
    return true
end

-- Remove member from gang
function GangSystem.RemoveMemberFromGang(src, targetIdentifier)
    local targetGang = GangSystem.PlayerGangs[targetIdentifier]
    if not targetGang then return false end
    
    MySQL.query('DELETE FROM umeverse_gang_members WHERE identifier = ?', { targetIdentifier }, function(result)
        GangSystem.PlayerGangs[targetIdentifier] = nil
        TriggerClientEvent('umeverse_gangs:updateGang', -1, nil) -- Removed from gang
    end)
    
    return true
end

-- Add reputation to player
function GangSystem.AddReputation(identifier, amount)
    local gangInfo = GangSystem.PlayerGangs[identifier]
    if not gangInfo then return false end
    
    local newRep = (gangInfo.reputation or 0) + amount
    
    MySQL.update('UPDATE umeverse_gang_members SET reputation = ? WHERE identifier = ?',
        { newRep, identifier })
    
    GangSystem.PlayerGangs[identifier].reputation = newRep
    
    -- Check milestone rewards
    GangSystem.CheckMilestones(identifier, newRep)
    
    return true
end

-- Check gang milestones
function GangSystem.CheckMilestones(identifier, reputation)
    for level, milestone in ipairs(GangsConfig.Reputation.reputationMilestones) do
        if reputation >= level * GangsConfig.Reputation.xpPerLevel then
            -- Award milestone reward
            local Player = QBCore.Functions.GetPlayer(identifier)
            if Player then
                Player.Functions.AddMoney('black', milestone.reward.black_money, 'Gang - ' .. milestone.label)
            end
        end
    end
end

-- Deposit to gang bank
function GangSystem.DepositToGangBank(src, gangName, amount)
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return false end
    
    local playerMoney = Player.PlayerData.money['black'] or 0
    if playerMoney < amount then
        return false, 'You don\'t have enough black money'
    end
    
    local fee = math.ceil(amount * GangsConfig.StashSystem.depositFee)
    local netAmount = amount - fee
    
    Player.Functions.RemoveMoney('black', amount, 'Gang Deposit')
    
    local gang = GangSystem.Gangs[gangName]
    gang.bank = (gang.bank or 0) + netAmount
    
    MySQL.update('UPDATE umeverse_gangs SET bank_balance = ? WHERE gang_name = ?',
        { gang.bank, gangName })
    
    TriggerClientEvent('umeverse_gangs:notify', src, 'success', 'Deposited $' .. netAmount .. ' (Fee: $' .. fee .. ')')
    
    return true, netAmount
end

-- Withdraw from gang bank
function GangSystem.WithdrawFromGangBank(src, gangName, amount)
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return false end
    
    local gang = GangSystem.Gangs[gangName]
    if (gang.bank or 0) < amount then
        return false, 'Insufficient gang bank balance'
    end
    
    local fee = math.ceil(amount * GangsConfig.StashSystem.withdrawFee)
    local netAmount = amount - fee
    
    gang.bank = (gang.bank or 0) - amount
    Player.Functions.AddMoney('black', netAmount, 'Gang Withdrawal')
    
    MySQL.update('UPDATE umeverse_gangs SET bank_balance = ? WHERE gang_name = ?',
        { gang.bank, gangName })
    
    TriggerClientEvent('umeverse_gangs:notify', src, 'success', 'Withdrawn $' .. netAmount .. ' (Fee: $' .. fee .. ')')
    
    return true, netAmount
end

-- Get gang info
function GangSystem.GetGangInfo(gangName)
    return GangSystem.Gangs[gangName]
end

-- Get player gang
function GangSystem.GetPlayerGang(identifier)
    return GangSystem.PlayerGangs[identifier]
end

-- Network events
RegisterNetEvent('umeverse_gangs:createGang')
AddEventHandler('umeverse_gangs:createGang', function(gangName, label)
    GangSystem.CreateGang(source, gangName, label)
end)

RegisterNetEvent('umeverse_gangs:joinGang')
AddEventHandler('umeverse_gangs:joinGang', function(gangName)
    GangSystem.AddMemberToGang(source, gangName, 0)
end)

RegisterNetEvent('umeverse_gangs:depositBank')
AddEventHandler('umeverse_gangs:depositBank', function(gangName, amount)
    GangSystem.DepositToGangBank(source, gangName, amount)
end)

RegisterNetEvent('umeverse_gangs:withdrawBank')
AddEventHandler('umeverse_gangs:withdrawBank', function(gangName, amount)
    GangSystem.WithdrawFromGangBank(source, gangName, amount)
end)

-- Initialize gangs on start
GangSystem.Initialize()

print('^2[Umeverse]^7 Gang System loaded')
