--[[
    Gangs System - Gang Warfare
]]

GangWarfare = {}
GangWarfare.ActiveWars = {}

-- Control points during gang war
function GangWarfare.CreateWarZone(territoryName, attackerGang, defenderGang)
    local territory = GangsConfig.Territories[territoryName]
    if not territory then return false end
    
    local warZone = {
        territory = territoryName,
        attacker = attackerGang,
        defender = defenderGang,
        attackerKills = 0,
        defenderKills = 0,
        duration = GangsConfig.GangWar.maxDuration,
        startTime = os.time(),
    }
    
    GangWarfare.ActiveWars[territoryName] = warZone
    return true
end

-- Record kill during war
function GangWarfare.RecordKill(killerGang, territoryName)
    local war = GangWarfare.ActiveWars[territoryName]
    if not war then return false end
    
    if killerGang == war.attacker then
        war.attackerKills = war.attackerKills + 1
    elseif killerGang == war.defender then
        war.defenderKills = war.defenderKills + 1
    end
    
    return true
end

-- End war by score
function GangWarfare.CheckWarProgress(territoryName)
    local war = GangWarfare.ActiveWars[territoryName]
    if not war then return false end
    
    local timeElapsed = os.time() - war.startTime
    if timeElapsed >= war.duration then
        -- War time expired - winner is who has more kills
        if war.attackerKills > war.defenderKills then
            TriggerEvent('umeverse_gangs:warEnded', war.attacker, war.defender, territoryName)
        else
            TriggerEvent('umeverse_gangs:warEnded', war.defender, war.attacker, territoryName)
        end
        GangWarfare.ActiveWars[territoryName] = nil
        return true
    end
    
    return false
end

print('^2[Umeverse]^7 Gang Warfare System loaded')
