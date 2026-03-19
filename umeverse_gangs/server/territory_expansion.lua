--[[
    Umeverse Gangs System - Territory Expansion
    Gradual territory growth, expansion missions, adjacent bonuses
]]

TerritoryExpansion = {}
TerritoryExpansion.ActiveMissions = {}

-- Start expansion mission
function TerritoryExpansion.StartMission(src, gangName, missionType)
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return false end
    
    local mission = GangsConfig.TerritoryExpansion.expansionMissions.missionTypes[missionType]
    if not mission then return false, 'Mission type not found' end
    
    local gang = GangSystem.GetPlayerGang(Player.PlayerData.citizenid)
    if not gang or gang.gang ~= gangName then
        return false, 'Not member of this gang'
    end
    
    if gang.rank < 2 then
        return false, 'Insufficient rank to start expansion missions'
    end
    
    local missionId = 'mission_' .. gangName .. '_' .. os.time()
    
    TerritoryExpansion.ActiveMissions[missionId] = {
        id = missionId,
        gang = gangName,
        player = Player.PlayerData.citizenid,
        type = missionType,
        reward = mission.reward,
        influence = mission.influence,
        startTime = os.time(),
        duration = mission.duration,
        status = 'active',
    }
    
    TriggerClientEvent('umeverse_gangs:notify', src, 'success', 'Expansion mission started: ' .. mission.label)
    
    return true
end

-- Complete expansion mission
function TerritoryExpansion.CompleteMission(src, missionId)
    local mission = TerritoryExpansion.ActiveMissions[missionId]
    if not mission then return false end
    
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player or Player.PlayerData.citizenid ~= mission.player then
        return false, 'Not mission owner'
    end
    
    if os.time() - mission.startTime < mission.duration then
        return false, 'Mission not yet complete'
    end
    
    -- Add reward
    Player.Functions.AddMoney('black', mission.reward, 'Territory Expansion')
    
    -- Add influence to territory
    GangTerritories.GainInfluence(mission.gang, 'current_territory', mission.influence)
    
    TerritoryExpansion.ActiveMissions[missionId] = nil
    
    TriggerClientEvent('umeverse_gangs:notify', src, 'success', 'Mission complete! +' .. mission.influence .. ' influence earned')
    
    return true
end

-- Passive influence gain
Citizen.CreateThread(function()
    while true do
        Wait(3600000) -- Every hour
        
        for territoryName, territory in pairs(GangsConfig.Territories) do
            if GangsConfig.TerritoryExpansion.passiveInfluence.enabled then
                local rate = GangsConfig.TerritoryExpansion.passiveInfluence.ratePerHour
                GangTerritories.GainInfluence(territory.gang, territoryName, rate)
            end
        end
    end
end)

RegisterNetEvent('umeverse_gangs:startExpansionMission')
AddEventHandler('umeverse_gangs:startExpansionMission', function(gangName, missionType)
    TerritoryExpansion.StartMission(source, gangName, missionType)
end)

RegisterNetEvent('umeverse_gangs:completeExpansionMission')
AddEventHandler('umeverse_gangs:completeExpansionMission', function(missionId)
    TerritoryExpansion.CompleteMission(source, missionId)
end)

print('^2[Umeverse]^7 Territory Expansion System loaded')
