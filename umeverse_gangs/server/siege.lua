--[[
    Umeverse Gangs System - Siege Warfare
    Gang war mechanics with siege duration, influence shifts, negotiations
]]

GangSiege = {}
GangSiege.ActiveSieges = {}

-- Start siege war between gangs
function GangSiege.StartSiege(src, targetGang, initialReason)
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return false end
    
    local playerGang = GangSystem.GetPlayerGang(Player.PlayerData.citizenid)
    if not playerGang or playerGang.rank < 4 then
        return false, 'Insufficient permissions to declare war'
    end
    
    if targetGang == playerGang.gang then
        return false, 'Cannot declare war on own gang'
    end
    
    local existingSiege = GangSiege.GetSiege(playerGang.gang, targetGang)
    if existingSiege then
        return false, 'War already in progress'
    end
    
    local warCost = GangsConfig.War.siegeDeclarationCost
    if GangSystem.GetGangBank(playerGang.gang) < warCost then
        return false, 'Gang bank insufficient: $' .. warCost .. ' required'
    end
    
    GangSystem.RemoveGangBank(playerGang.gang, warCost, 'Siege Declaration - ' .. targetGang)
    
    local siegeId = 'siege_' .. playerGang.gang .. '_' .. targetGang .. '_' .. os.time()
    
    GangSiege.ActiveSieges[siegeId] = {
        id = siegeId,
        attacker = playerGang.gang,
        defender = targetGang,
        startTime = os.time(),
        duration = GangsConfig.War.siegeDuration,
        influenceShift = 0,
        daysPassed = 0,
        reason = initialReason,
        state = 'active',
    }
    
    MySQL.Sync.execute('INSERT INTO umeverse_gang_wars (attacker, defender, start_time, status) VALUES (?, ?, ?, ?)',
        {playerGang.gang, targetGang, os.time(), 'active'})
    
    TriggerClientEvent('umeverse_gangs:notify', src, 'warning', 'War declared on ' .. targetGang)
    
    return true
end

-- Get active siege between two gangs
function GangSiege.GetSiege(gang1, gang2)
    for _, siege in pairs(GangSiege.ActiveSieges) do
        if siege.state == 'active' and (
            (siege.attacker == gang1 and siege.defender == gang2) or
            (siege.attacker == gang2 and siege.defender == gang1)
        ) then
            return siege
        end
    end
    return nil
end

-- Daily influence shift during siege
Citizen.CreateThread(function()
    while true do
        Wait(86400000) -- Every 24 hours
        
        for siegeId, siege in pairs(GangSiege.ActiveSieges) do
            if siege.state == 'active' then
                siege.daysPassed = siege.daysPassed + 1
                
                -- Influence shift per day
                local shift = GangsConfig.War.influencePerDay
                
                GangTerritories.GainInfluence(siege.attacker, 'current_territory', shift)
                GangTerritories.LoseInfluence(siege.defender, 'current_territory', shift)
                
                siege.influenceShift = siege.influenceShift + shift
                
                -- Check if siege duration is over
                if siege.daysPassed >= siege.duration then
                    GangSiege.EndSiege(siegeId)
                end
            end
        end
    end
end)

-- End siege war
function GangSiege.EndSiege(siegeId)
    local siege = GangSiege.ActiveSieges[siegeId]
    if not siege then return false end
    
    siege.state = 'ended'
    
    MySQL.Sync.execute('UPDATE umeverse_gang_wars SET status = ?, end_time = ? WHERE id = ?',
        {'ended', os.time(), siegeId})
    
    print('^3[Gang War] Siege ended: ' .. siege.attacker .. ' vs ' .. siege.defender .. '^7')
    
    return true
end

-- Negotiate peace/truce
function GangSiege.NegotiatePeace(src, targetGang, territoryOffer, moneyOffer)
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return false end
    
    local playerGang = GangSystem.GetPlayerGang(Player.PlayerData.citizenid)
    if not playerGang or playerGang.rank < 4 then
        return false, 'Insufficient permissions'
    end
    
    local siege = GangSiege.GetSiege(playerGang.gang, targetGang)
    if not siege then return false, 'No active siege with this gang' end
    
    if GangSystem.GetGangBank(playerGang.gang) < moneyOffer then
        return false, 'Gang bank insufficient'
    end
    
    TriggerClientEvent('umeverse_gangs:notify', src, 'info', 'Peace negotiation proposal sent')
    
    return true
end

-- Automatic revenge trigger after war ends
function GangSiege.CheckRevengeEligibility(gang1, gang2)
    local recentWars = MySQL.Sync.fetchAll(
        'SELECT * FROM umeverse_gang_wars WHERE (attacker = ? AND defender = ?) OR (attacker = ? AND defender = ?) ORDER BY end_time DESC LIMIT 1',
        {gang1, gang2, gang2, gang1}
    )
    
    if recentWars and #recentWars > 0 then
        local lastWar = recentWars[1]
        local timeSinceWar = os.time() - lastWar.end_time
        
        if timeSinceWar < GangsConfig.War.revengeWindowHours * 3600 then
            return true
        end
    end
    
    return false
end

RegisterNetEvent('umeverse_gangs:startSiege')
AddEventHandler('umeverse_gangs:startSiege', function(targetGang, reason)
    GangSiege.StartSiege(source, targetGang, reason)
end)

RegisterNetEvent('umeverse_gangs:negotiatePeace')
AddEventHandler('umeverse_gangs:negotiatePeace', function(targetGang, territoryOffer, moneyOffer)
    GangSiege.NegotiatePeace(source, targetGang, territoryOffer, moneyOffer)
end)

exports('isGangWarActive', function(gang1, gang2)
    return GangSiege.GetSiege(gang1, gang2) ~= nil
end)

print('^2[Umeverse]^7 Gang Siege Warfare System loaded')
