--[[
    Gangs System - Territories & Influence
    Manages gang territory control and interaction with drug system
]]

GangTerritories = {}
GangTerritories.PlayerTerritories = {}
GangTerritories.TerritoryControl = {}

-- Initialize territories from config
function GangTerritories.Initialize()
    for territoryName, territory in pairs(GangsConfig.Territories) do
        GangTerritories.TerritoryControl[territoryName] = {
            controllingGang = territory.gang,
            influence = territory.influence,
            contested = false,
            contestedBy = nil,
            drugMultiplier = territory.drugMultiplier,
        }
    end
end

-- Gain influence in territory
function GangTerritories.GainInfluence(gangName, territoryName, amount)
    local territory = GangTerritories.TerritoryControl[territoryName]
    if not territory then return false end
    
    if territory.controllingGang == gangName then
        territory.influence = math.min(territory.influence + amount, 100)
        
        MySQL.update('UPDATE umeverse_gang_territories SET influence_level = ? WHERE territory_name = ?',
            { territory.influence, territoryName })
        
        return true
    end
    
    return false
end

-- Lose influence in territory
function GangTerritories.LoseInfluence(gangName, territoryName, amount)
    local territory = GangTerritories.TerritoryControl[territoryName]
    if not territory then return false end
    
    if territory.controllingGang == gangName then
        territory.influence = math.max(territory.influence - amount, 0)
        
        MySQL.update('UPDATE umeverse_gang_territories SET influence_level = ? WHERE territory_name = ?',
            { territory.influence, territoryName })
        
        -- If influence reaches 0, territory becomes contested
        if territory.influence == 0 then
            territory.contested = true
        end
        
        return true
    end
    
    return false
end

-- Declare war on territory
function GangTerritories.DeclareWar(attackerGang, defenderGang, territoryName)
    local territory = GangTerritories.TerritoryControl[territoryName]
    if not territory then return false end
    
    if territory.controllingGang ~= defenderGang then
        return false, 'Gang does not control territory'
    end
    
    territory.contested = true
    territory.contestedBy = attackerGang
    
    local warData = {
        attacker_gang = attackerGang,
        defender_gang = defenderGang,
        territory_name = territoryName,
        started_at = os.time(),
        status = 'active',
    }
    
    MySQL.insert('INSERT INTO umeverse_gang_wars (attacker_gang, defender_gang, territory_name, started_at, status) VALUES (?, ?, ?, ?, ?)',
        { warData.attacker_gang, warData.defender_gang, warData.territory_name, warData.started_at, warData.status },
        function(lastId)
            -- Trigger drug operations interruption
            TriggerEvent('umeverse_crime:warStarted', attackerGang, defenderGang, territoryName)
        end
    )
    
    return true
end

-- End gang war
function GangTerritories.EndWar(winnerGang, loserGang, territoryName)
    local territory = GangTerritories.TerritoryControl[territoryName]
    if not territory then return false end
    
    if winnerGang == territory.controllingGang then
        -- Defending gang won
        territory.influence = 100
    else
        -- Attacking gang won - transfer territory
        territory.controllingGang = winnerGang
        territory.influence = 50 -- New controller starts with 50 influence
    end
    
    territory.contested = false
    territory.contestedBy = nil
    
    MySQL.query('UPDATE umeverse_gang_wars SET status = ?, winner = ?, ended_at = ? WHERE attacker_gang = ? AND defender_gang = ? AND territory_name = ?',
        { 'ended', winnerGang, os.time(), loserGang, winnerGang, territoryName })
    
    -- Update drug multiplier if territory changed hands
    if winnerGang ~= territory.controllingGang then
        GangTerritories.UpdateDrugMultiplier(territoryName, winnerGang)
    end
    
    -- Trigger drug operations resumption
    TriggerEvent('umeverse_crime:warEnded', winnerGang, loserGang, territoryName)
    
    return true
end

-- Update drug multiplier based on territory control
function GangTerritories.UpdateDrugMultiplier(territoryName, controllingGang)
    local multiplier = GangsConfig.Territories[territoryName].drugMultiplier or 1.0
    
    -- Notify drug system of territory change
    TriggerEvent('umeverse_drugs:updateTerritoryControl', territoryName, controllingGang, multiplier)
    
    MySQL.update('UPDATE umeverse_gang_territories SET drug_multiplier = ?, gang_name = ? WHERE territory_name = ?',
        { multiplier, controllingGang, territoryName })
end

-- Get territory info
function GangTerritories.GetTerritoryInfo(territoryName)
    return GangTerritories.TerritoryControl[territoryName]
end

-- Get gang territories
function GangTerritories.GetGangTerritories(gangName)
    local territories = {}
    for territoryName, territory in pairs(GangTerritories.TerritoryControl) do
        if territory.controllingGang == gangName then
            table.insert(territories, territoryName)
        end
    end
    return territories
end

-- Network events
RegisterNetEvent('umeverse_gangs:declareWar')
AddEventHandler('umeverse_gangs:declareWar', function(attackerGang, defenderGang, territoryName)
    local success, reason = GangTerritories.DeclareWar(attackerGang, defenderGang, territoryName)
    if success then
        TriggerClientEvent('umeverse_gangs:notify', -1, 'success', 'War declared: ' .. attackerGang .. ' vs ' .. defenderGang)
    else
        TriggerClientEvent('umeverse_gangs:notify', source, 'error', reason or 'War declaration failed')
    end
end)

RegisterNetEvent('umeverse_gangs:endWar')
AddEventHandler('umeverse_gangs:endWar', function(winnerGang, loserGang, territoryName)
    local success = GangTerritories.EndWar(winnerGang, loserGang, territoryName)
    if success then
        TriggerClientEvent('umeverse_gangs:notify', -1, 'success', winnerGang .. ' won territory: ' .. territoryName)
    end
end)

-- Initialize on start
GangTerritories.Initialize()

print('^2[Umeverse]^7 Gang Territories System loaded')
