--[[
    Gangs System - Criminal Enterprises
    Gang-specific crime opportunities tied to crime system
]]

GangEnterprises = {}
GangEnterprises.ActiveEnterprises = {}
GangEnterprises.EnterpriseProgress = {}

-- Start enterprise for gang
function GangEnterprises.StartEnterprise(src, gangName, enterpriseType)
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return false end
    
    local enterprise = GangsConfig.Enterprises[enterpriseType]
    if not enterprise then
        return false, 'Enterprise not found'
    end
    
    local playerGang = GangSystem.GetPlayerGang(Player.PlayerData.citizenid)
    if not playerGang or playerGang.gang ~= gangName then
        return false, 'You are not part of this gang'
    end
    
    -- Check if player is high enough rank
    if playerGang.rank < 2 then -- At least Enforcer rank
        return false, 'Insufficient rank for this enterprise'
    end
    
    if enterprise.requiresTeam then
        -- Check for team members
        local nearbyMembers = 0
        local players = GetPlayers()
        for _, playerId in ipairs(players) do
            local nearPlayer = GetPlayerIdentifier(playerId, 0)
            local nearGang = GangSystem.GetPlayerGang(nearPlayer)
            if nearGang and nearGang.gang == gangName then
                local nearCoords = GetEntityCoords(GetPlayerPed(tonumber(playerId)))
                local srcCoords = GetEntityCoords(GetPlayerPed(src))
                if #(nearCoords - srcCoords) < 50 then
                    nearbyMembers = nearbyMembers + 1
                end
            end
        end
        
        if nearbyMembers < enterprise.teamSize then
            return false, 'Insufficient team members nearby'
        end
    end
    
    local reward = math.random(enterprise.rewards.black_money.min, enterprise.rewards.black_money.max)
    reward = math.floor(reward * enterprise.gangBonus) -- Apply gang multiplier
    
    Player.Functions.AddMoney('black', reward, 'Gang Enterprise - ' .. enterprise.label)
    GangSystem.AddReputation(Player.PlayerData.citizenid, enterprise.rewards.reputation)
    
    -- Log enterprise completion
    MySQL.insert('INSERT INTO umeverse_gang_enterprises (gang_name, enterprise_type, active, revenue, runs_completed) VALUES (?, ?, ?, ?, ?) ON DUPLICATE KEY UPDATE runs_completed = runs_completed + 1, revenue = revenue + ?',
        { gangName, enterpriseType, 1, reward, 1, reward },
        function(lastId)
            TriggerClientEvent('umeverse_gangs:notify', src, 'success', enterprise.label .. ' completed! Earned $' .. reward)
        end
    )
    
    return true, reward
end

-- Add progress to ongoing enterprise
function GangEnterprises.AddEnterpriseProgress(gangName, enterpriseType, progressAmount)
    local key = gangName .. ':' .. enterpriseType
    if not GangEnterprises.EnterpriseProgress[key] then
        GangEnterprises.EnterpriseProgress[key] = 0
    end
    
    GangEnterprises.EnterpriseProgress[key] = GangEnterprises.EnterpriseProgress[key] + progressAmount
end

-- Get enterprise info
function GangEnterprises.GetEnterpriseInfo(enterpriseType)
    return GangsConfig.Enterprises[enterpriseType]
end

-- Get all enterprises for gang
function GangEnterprises.GetGangEnterprises(gangName)
    local enterprises = {}
    for enterpriseType, _ in pairs(GangsConfig.Enterprises) do
        table.insert(enterprises, enterpriseType)
    end
    return enterprises
end

-- Network events
RegisterNetEvent('umeverse_gangs:startEnterprise')
AddEventHandler('umeverse_gangs:startEnterprise', function(gangName, enterpriseType)
    local success, result = GangEnterprises.StartEnterprise(source, gangName, enterpriseType)
    if not success then
        TriggerClientEvent('umeverse_gangs:notify', source, 'error', result)
    end
end)

RegisterNetEvent('umeverse_gangs:addEnterpriseProgress')
AddEventHandler('umeverse_gangs:addEnterpriseProgress', function(gangName, crimeType, reward)
    GangEnterprises.AddEnterpriseProgress(gangName, crimeType, math.floor(reward / 100)) -- Convert to progress points
end)

print('^2[Umeverse]^7 Gang Enterprises System loaded')
