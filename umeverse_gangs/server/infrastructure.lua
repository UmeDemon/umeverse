--[[
    Umeverse Gangs System - Infrastructure
    Gang upgrades: Drug Production, Police Bribery, Soldier Morale, Armory
]]

GangInfrastructure = {}

-- Initialize gang infrastructure
function GangInfrastructure.InitGang(gangName)
    local result = MySQL.Sync.fetchAll('SELECT * FROM umeverse_gang_infrastructure WHERE gang_name = ?', {gangName})
    
    if not result or #result == 0 then
        for infraType, config in pairs(GangsConfig.Infrastructure.types) do
            MySQL.Sync.execute('INSERT INTO umeverse_gang_infrastructure (gang_name, type, level, xp) VALUES (?, ?, ?, ?)',
                {gangName, infraType, 1, 0})
        end
    end
end

-- Upgrade infrastructure
function GangInfrastructure.Upgrade(src, infraType)
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return false end
    
    local gang = GangSystem.GetPlayerGang(Player.PlayerData.citizenid)
    if not gang then return false, 'Not in a gang' end
    
    local infraConfig = GangsConfig.Infrastructure.types[infraType]
    if not infraConfig then return false, 'Invalid infrastructure type' end
    
    local current = MySQL.Sync.fetchAll('SELECT * FROM umeverse_gang_infrastructure WHERE gang_name = ? AND type = ?',
        {gang.gang, infraType})
    
    if not current or #current == 0 then return false, 'Infrastructure not found' end
    
    local infra = current[1]
    if infra.level >= infraConfig.maxLevel then
        return false, 'Already at maximum level'
    end
    
    local cost = infraConfig.costPerLevel * infra.level
    local gangBank = GangSystem.GetGangBank(gang.gang)
    
    if gangBank < cost then
        return false, 'Gang bank insufficient funds: $' .. cost .. ' required'
    end
    
    GangSystem.RemoveGangBank(gang.gang, cost, 'Infrastructure Upgrade - ' .. infraType)
    
    MySQL.Sync.execute('UPDATE umeverse_gang_infrastructure SET level = level + 1, xp = 0 WHERE gang_name = ? AND type = ?',
        {gang.gang, infraType})
    
    -- Broadcast upgrade to all gang members
    TriggerEvent('umeverse_gangs:infraUpgrade', gang.gang, infraType, infra.level + 1)
    
    -- Log to database
    MySQL.Sync.execute('INSERT INTO umeverse_gang_logs (gang_name, log_type, description) VALUES (?, ?, ?)',
        {gang.gang, 'infrastructure', Player.PlayerData.name .. ' upgraded ' .. infraType .. ' to level ' .. (infra.level + 1)})
    
    TriggerClientEvent('umeverse_gangs:notify', src, 'success', infraType .. ' upgraded to level ' .. (infra.level + 1))
    
    return true
end

-- Get infrastructure bonuses
function GangInfrastructure.GetBonuses(gangName)
    local result = MySQL.Sync.fetchAll('SELECT * FROM umeverse_gang_infrastructure WHERE gang_name = ?', {gangName})
    
    if not result then return {} end
    
    local bonuses = {
        drugProduction = 1.0,
        policeBribery = 1.0,
        soldierMorale = 1.0,
        armory = 1.0,
    }
    
    for _, infra in ipairs(result) do
        local config = GangsConfig.Infrastructure.types[infra.type]
        if config then
            local levelBonus = (infra.level - 1) * config.bonusPerLevel
            
            if infra.type == 'drugProduction' then
                bonuses.drugProduction = 1.0 + (levelBonus / 100)
            elseif infra.type == 'policeBribery' then
                bonuses.policeBribery = 1.0 + (levelBonus / 100)
            elseif infra.type == 'soldierMorale' then
                bonuses.soldierMorale = 1.0 + (levelBonus / 100)
            elseif infra.type == 'armory' then
                bonuses.armory = 1.0 + (levelBonus / 100)
            end
        end
    end
    
    return bonuses
end

-- Apply infrastructure effects (called when gang members perform crimes)
function GangInfrastructure.ApplyEffects(gangName, crimeType)
    local bonuses = GangInfrastructure.GetBonuses(gangName)
    local multiplier = 1.0
    
    if crimeType == 'drugSale' or crimeType == 'production' then
        multiplier = bonuses.drugProduction
    elseif crimeType == 'bribery' then
        multiplier = bonuses.policeBribery
    elseif crimeType == 'robbery' then
        multiplier = bonuses.soldierMorale
    end
    
    return multiplier
end

-- Get infrastructure status
function GangInfrastructure.GetStatus(gangName)
    local result = MySQL.Sync.fetchAll('SELECT * FROM umeverse_gang_infrastructure WHERE gang_name = ?', {gangName})
    
    if not result then return {} end
    
    local status = {}
    for _, infra in ipairs(result) do
        status[infra.type] = {
            level = infra.level,
            xp = infra.xp,
            maxLevel = GangsConfig.Infrastructure.types[infra.type].maxLevel
        }
    end
    
    return status
end

-- Infrastructure data initialization on server start
Citizen.CreateThread(function()
    Wait(1000)
    
    for gangName, _ in pairs(GangsConfig.Gangs) do
        GangInfrastructure.InitGang(gangName)
    end
    
    print('^2[Umeverse]^7 Infrastructure initialized for all gangs')
end)

RegisterNetEvent('umeverse_gangs:upgradeInfrastructure')
AddEventHandler('umeverse_gangs:upgradeInfrastructure', function(infraType)
    GangInfrastructure.Upgrade(source, infraType)
end)

exports('getGangInfrastructureMultiplier', function(gangName, infraType)
    local bonuses = GangInfrastructure.GetBonuses(gangName)
    
    if infraType == 'drugProduction' then return bonuses.drugProduction
    elseif infraType == 'policeBribery' then return bonuses.policeBribery
    elseif infraType == 'soldierMorale' then return bonuses.soldierMorale
    elseif infraType == 'armory' then return bonuses.armory
    end
    
    return 1.0
end)

print('^2[Umeverse]^7 Gang Infrastructure System loaded')
