--[[
    Crime & Gangs Integration with Drugs System
    Handles the interconnection between all three criminal systems
]]

CrimeGangDrugIntegration = {}

-- Get gang crime bonuses
function CrimeGangDrugIntegration.GetGangBonus(identifier, crimeType)
    local gang = GangSystem and GangSystem.GetPlayerGang(identifier)
    if not gang then return 1.0 end
    
    local crime = CrimeConfig.Crimes[crimeType]
    if not crime then return 1.0 end
    
    -- Gang members get bonus on enterprise crimes
    if crime.tier >= 2 then
        return GangsConfig.Enterprises.gang_bonus or 1.3
    end
    
    return 1.0
end

-- Check if player is in controlled territory
function CrimeGangDrugIntegration.IsInControlledTerritory(playerCoords)
    for territoryName, territory in pairs(GangsConfig.Territories) do
        local bbox = territory.boundingBox
        if playerCoords.x >= bbox.x1 and playerCoords.x <= bbox.x2 and
           playerCoords.y >= bbox.y1 and playerCoords.y <= bbox.y2 then
            return territoryName, territory.gang
        end
    end
    return nil, nil
end

-- Apply territory bonuses to crime rewards
function CrimeGangDrugIntegration.ApplyTerritoryBonus(reward, territory, playerGang)
    if not territory or not GangsConfig.Territories[territory] then
        return reward
    end
    
    local territoryData = GangsConfig.Territories[territory]
    
    -- Controlled territory bonus for gang members
    if territoryData.gang == playerGang then
        return math.floor(reward * 1.5) -- 50% bonus in your territory
    end
    
    -- Contested territory penalty for enemies
    if territoryData.contested then
        return math.floor(reward * 0.7) -- 30% penalty in contested territory
    end
    
    return reward
end

-- Apply drug system bonuses when committing crimes in drug territory
function CrimeGangDrugIntegration.GetDrugTerritoryBonus(playerCoords, gangName)
    local territory, controllingGang = CrimeGangDrugIntegration.IsInControlledTerritory(playerCoords)
    
    if not territory then return 1.0 end
    
    local territoryData = GangsConfig.Territories[territory]
    if not territoryData or not territoryData.drugSales then
        return 1.0
    end
    
    -- If gang controls territory, apply drug multiplier benefits
    if territoryData.gang == gangName then
        return territoryData.drugMultiplier or 1.0
    end
    
    return 1.0
end

-- Handle gang war effects on crime rewards
function CrimeGangDrugIntegration.ApplyGangWarEffects(playerGang, reward)
    if not GangSystem or not GangSystem.GangWars then return reward end
    
    for _, war in pairs(GangSystem.GangWars) do
        if (war.attacker_gang == playerGang or war.defender_gang == playerGang) and war.status == 'active' then
            -- During active war, crimes in contested territory pay more
            return math.floor(reward * GangsConfig.GangWar.crimeRewardBonus)
        end
    end
    
    return reward
end

-- Interrupt drug operations when declaring war
function CrimeGangDrugIntegration.InterruptDrugOperations(defendingGang)
    if not exports['umeverse_drugs'] then return end
    
    -- Trigger event to pause drug operations in contested territories
    TriggerEvent('umeverse_drugs:pauseOperations', defendingGang)
end

-- Get crime tier recommendation based on gang reputation
function CrimeGangDrugIntegration.GetRecommendedCrimeTier(gangReputation)
    if gangReputation < 50 then return 1 end    -- Street crimes
    if gangReputation < 150 then return 2 end   -- Medium crimes
    if gangReputation < 300 then return 3 end   -- Big heists
    return 4 -- Maximum tier crimes available
end

-- Sync crime reputation with gang reputation
function CrimeGangDrugIntegration.SyncCrimeReputationToGang(identifier, crimeReward)
    if not GangSystem then return end
    
    local gang = GangSystem.GetPlayerGang(identifier)
    if gang then
        -- Convert crime reward to gang reputation (1000 black money = 1 reputation)
        local repGain = math.floor(crimeReward / 1000)
        if repGain > 0 then
            GangSystem.AddReputation(identifier, repGain)
        end
    end
end

-- Get exclusive gang member crime opportunities
function CrimeGangDrugIntegration.GetGangExclusiveCrimes(gangName)
    local exclusiveCrimes = {
        ['ballas'] = { 'protection_racket', 'drug_runs', 'territory_defense' },
        ['families'] = { 'drug_runs', 'territory_defense', 'heist_planning' },
        ['vagos'] = { 'protection_racket', 'drug_runs', 'carjacking_runs' },
        ['lost'] = { 'bike_chop', 'protection_racket', 'territory_defense' },
        ['mexican'] = { 'drug_runs', 'major_heist', 'cartel_ops' },
    }
    
    return exclusiveCrimes[gangName] or {}
end

-- Handle crime discovery trigger (police alerts)
function CrimeGangDrugIntegration.TriggerPoliceCrimeScanner(src, crimeType, crimeCoords)
    -- Notify law enforcement
    TriggerEvent('umeverse_crime:policeAlert', {
        source = src,
        crime = crimeType,
        coords = crimeCoords,
        timestamp = os.time(),
    })
end

-- Integration event when gang war starts
RegisterNetEvent('umeverse_gangs:warStarted')
AddEventHandler('umeverse_gangs:warStarted', function(attackerGang, defenderGang, territory)
    -- Increase heat for both gangs
    local players = GetPlayers()
    for _, playerId in ipairs(players) do
        local player = GetPlayerIdentifier(playerId, 0)
        local gang = GangSystem and GangSystem.GetPlayerGang(player)
        
        if gang and (gang.gang == attackerGang or gang.gang == defenderGang) then
            -- Increase heat during gang war
            TriggerEvent('umeverse_crime:addWarHeat', playerId, 25)
        end
    end
    
    -- Interrupt drug operations in war territory
    CrimeGangDrugIntegration.InterruptDrugOperations(defenderGang)
end)

-- Integration event when gang war ends
RegisterNetEvent('umeverse_gangs:warEnded')
AddEventHandler('umeverse_gangs:warEnded', function(winnerGang, loserGang, territory)
    -- Winner gang gets control of territory drug sales multiplier
    if exports['umeverse_drugs'] then
        TriggerEvent('umeverse_drugs:updateTerritoryControl', territory, winnerGang)
    end
end)

-- Server event: crime completion triggers gang enterprise progress
RegisterNetEvent('umeverse_crime:crimeCompleted')
AddEventHandler('umeverse_crime:crimeCompleted', function(src, crimeType, reward)
    local player = GetPlayer(src)
    if not player then return end
    
    local gang = GangSystem.GetPlayerGang(player.PlayerData.citizenid)
    if gang then
        -- Add to gang enterprise progress if applicable
        TriggerEvent('umeverse_gangs:addEnterpriseProgress', gang.gang, crimeType, reward)
        CrimeGangDrugIntegration.SyncCrimeReputationToGang(player.PlayerData.citizenid, reward)
    end
end)

print('^2[Umeverse]^7 Crime-Gang-Drug Integration loaded')
