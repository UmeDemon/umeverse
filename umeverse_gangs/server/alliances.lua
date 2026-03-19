--[[
    Umeverse Gangs System - Alliances
    Temporary alliances and treaties between gangs with shared benefits
]]

GangAlliances = {}
GangAlliances.ActiveAlliances = {}

-- Request alliance
function GangAlliances.RequestAlliance(src, targetGang, duration, allianceType)
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return false end
    
    local playerGang = GangSystem.GetPlayerGang(Player.PlayerData.citizenid)
    if not playerGang or playerGang.rank < 4 then
        return false, 'Insufficient permissions to form alliances'
    end
    
    if targetGang == playerGang.gang then
        return false, 'Cannot ally with own gang'
    end
    
    local typeConfig = GangsConfig.Alliances.types[allianceType]
    if not typeConfig then return false, 'Invalid alliance type' end
    
    local cost = typeConfig.initialCost
    if GangSystem.GetGangBank(playerGang.gang) < cost then
        return false, 'Gang bank insufficient: $' .. cost .. ' required'
    end
    
    -- Deduct cost
    GangSystem.RemoveGangBank(playerGang.gang, cost, 'Alliance Request - ' .. targetGang)
    
    local allianceId = 'alliance_' .. playerGang.gang .. '_' .. targetGang .. '_' .. os.time()
    
    GangAlliances.ActiveAlliances[allianceId] = {
        id = allianceId,
        gang1 = playerGang.gang,
        gang2 = targetGang,
        type = allianceType,
        startTime = os.time(),
        duration = duration * 86400, -- Convert days to seconds
        active = false,
        createdBy = Player.PlayerData.citizenid,
    }
    
    MySQL.insert('INSERT INTO umeverse_gang_alliances (gang1, gang2, type, start_time, duration, active) VALUES (?, ?, ?, ?, ?, ?)',
        {playerGang.gang, targetGang, allianceType, os.time(), duration * 86400, 0},
        function(lastId)
            if lastId then
                TriggerClientEvent('umeverse_gangs:notify', src, 'info', 'Alliance request sent to ' .. targetGang)
            else
                TriggerClientEvent('umeverse_gangs:notify', src, 'error', 'Failed to send alliance request')
            end
        end
    )
    
    return true
end

-- Accept alliance
function GangAlliances.AcceptAlliance(src, allianceId)
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return false end
    
    local playerGang = GangSystem.GetPlayerGang(Player.PlayerData.citizenid)
    if not playerGang or playerGang.rank < 4 then
        return false, 'Insufficient permissions'
    end
    
    local alliance = GangAlliances.ActiveAlliances[allianceId]
    if not alliance then return false, 'Alliance not found' end
    
    if alliance.gang2 ~= playerGang.gang then
        return false, 'You are not the target of this alliance'
    end
    
    local typeConfig = GangsConfig.Alliances.types[alliance.type]
    
    -- Check for recurring costs
    if typeConfig.dailyCost and typeConfig.dailyCost > 0 then
        if GangSystem.GetGangBank(playerGang.gang) < typeConfig.dailyCost then
            return false, 'Gang bank insufficient for daily costs'
        end
    end
    
    alliance.active = true
    
    MySQL.update('UPDATE umeverse_gang_alliances SET active = 1 WHERE id = ?', {allianceId},
        function(affected)
            if affected > 0 then
                TriggerClientEvent('umeverse_gangs:notify', src, 'success', 'Alliance formed with ' .. alliance.gang1)
            else
                TriggerClientEvent('umeverse_gangs:notify', src, 'error', 'Failed to activate alliance')
            end
        end
    )
    
    return true
end

-- Break alliance
function GangAlliances.BreakAlliance(src, allianceId)
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return false end
    
    local playerGang = GangSystem.GetPlayerGang(Player.PlayerData.citizenid)
    if not playerGang or playerGang.rank < 4 then
        return false, 'Insufficient permissions'
    end
    
    local alliance = GangAlliances.ActiveAlliances[allianceId]
    if not alliance then return false, 'Alliance not found' end
    
    if alliance.gang1 ~= playerGang.gang and alliance.gang2 ~= playerGang.gang then
        return false, 'Your gang is not part of this alliance'
    end
    
    GangAlliances.ActiveAlliances[allianceId] = nil
    
    MySQL.update('UPDATE umeverse_gang_alliances SET active = 0 WHERE id = ?', {allianceId},
        function(affected)
            if affected > 0 then
                TriggerClientEvent('umeverse_gangs:notify', src, 'warning', 'Alliance dissolved')
            end
        end
    )
    
    return true
end

-- Get bonuses from active alliances
function GangAlliances.GetBonuses(gangName)
    local bonus = {
        crimeRewardBoost = 1.0,
        defenseBoost = 1.0,
        hasAlliance = false,
    }
    
    for _, alliance in pairs(GangAlliances.ActiveAlliances) do
        if alliance.active and (alliance.gang1 == gangName or alliance.gang2 == gangName) then
            local typeConfig = GangsConfig.Alliances.types[alliance.type]
            
            bonus.hasAlliance = true
            bonus.crimeRewardBoost = bonus.crimeRewardBoost + (typeConfig.sharedCrimeRewardBoost / 100)
            bonus.defenseBoost = bonus.defenseBoost + 0.1
        end
    end
    
    return bonus
end

-- Daily maintenance for recurring costs
Citizen.CreateThread(function()
    while true do
        Wait(86400000) -- Every 24 hours
        
        for _, alliance in pairs(GangAlliances.ActiveAlliances) do
            if alliance.active then
                local typeConfig = GangsConfig.Alliances.types[alliance.type]
                
                if typeConfig and typeConfig.dailyCost and typeConfig.dailyCost > 0 then
                    local bank1 = GangSystem.GetGangBank(alliance.gang1)
                    local bank2 = GangSystem.GetGangBank(alliance.gang2)
                    
                    if bank1 < typeConfig.dailyCost or bank2 < typeConfig.dailyCost then
                        -- Alliance broken due to insufficient funds
                        GangAlliances.BreakAlliance(0, alliance.id)
                        
                        print('^2[Umeverse]^7 Alliance ' .. alliance.id .. ' broken: insufficient gang bank funds')
                    else
                        -- Deduct costs asynchronously
                        GangSystem.RemoveGangBank(alliance.gang1, typeConfig.dailyCost, 'Alliance Maintenance')
                        GangSystem.RemoveGangBank(alliance.gang2, typeConfig.dailyCost, 'Alliance Maintenance')
                    end
                end
            end
        end
    end
end)

-- Expire alliances after duration
Citizen.CreateThread(function()
    while true do
        Wait(300000) -- Every 5 minutes
        
        for allianceId, alliance in pairs(GangAlliances.ActiveAlliances) do
            if alliance.active and (os.time() - alliance.startTime) >= alliance.duration then
                GangAlliances.BreakAlliance(0, allianceId)
            end
        end
    end
end)

RegisterNetEvent('umeverse_gangs:requestAlliance')
AddEventHandler('umeverse_gangs:requestAlliance', function(targetGang, duration, allianceType)
    GangAlliances.RequestAlliance(source, targetGang, duration, allianceType)
end)

RegisterNetEvent('umeverse_gangs:acceptAlliance')
AddEventHandler('umeverse_gangs:acceptAlliance', function(allianceId)
    GangAlliances.AcceptAlliance(source, allianceId)
end)

RegisterNetEvent('umeverse_gangs:breakAlliance')
AddEventHandler('umeverse_gangs:breakAlliance', function(allianceId)
    GangAlliances.BreakAlliance(source, allianceId)
end)

exports('getGangAllianceBonuses', function(gangName)
    return GangAlliances.GetBonuses(gangName)
end)

print('^2[Umeverse]^7 Gang Alliances System loaded')
