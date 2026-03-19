--[[
    Umeverse Crime System - Main Server
]]

CrimeSystem = {}
CrimeSystem.PlayerCrimes = {}
CrimeSystem.PlayerHeat = {}
CrimeSystem.Specializations = {}

-- Initialize player crime data
function CrimeSystem.InitializePlayer(src, identifier)
    CrimeSystem.PlayerCrimes[src] = {
        identifier = identifier,
        totalCrimes = 0,
        successfulCrimes = 0,
        failedCrimes = 0,
        specialized = nil,
        experience = 0,
        reputation = 0,
    }
    CrimeSystem.PlayerHeat[src] = 0
end

-- Log crime to database
function CrimeSystem.LogCrime(src, crimeType, success, reward)
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end
    
    local data = {
        identifier = Player.PlayerData.citizenid,
        crime_type = crimeType,
        success = success and 1 or 0,
        reward = reward or 0,
        heat_generated = success and CrimeConfig.Crimes[crimeType].heat or 0,
        timestamp = math.floor(os.time() / 1000),
    }
    
    MySQL.insert('INSERT INTO umeverse_crime_logs (identifier, crime_type, success, reward, heat_generated, timestamp) VALUES (?, ?, ?, ?, ?, ?)',
        { data.identifier, data.crime_type, data.success, data.reward, data.heat_generated, data.timestamp },
        function(lastId)
            TriggerClientEvent('umeverse_crime:crimeLocked', src, lastId)
        end
    )
end

-- Add heat to player
function CrimeSystem.AddHeat(src, amount, multiplier)
    multiplier = multiplier or 1.0
    if not CrimeSystem.PlayerHeat[src] then
        CrimeSystem.PlayerHeat[src] = 0
    end
    
    CrimeSystem.PlayerHeat[src] = math.min(CrimeSystem.PlayerHeat[src] + (amount * multiplier), CrimeConfig.Heat.maxHeat)
    TriggerClientEvent('umeverse_crime:updateHeat', src, CrimeSystem.PlayerHeat[src])
    
    -- Check if police should respond
    CrimeSystem.CheckPoliceResponse(src)
end

-- Reduce heat over time
function CrimeSystem.ReduceHeat(src)
    if not CrimeSystem.PlayerHeat[src] or CrimeSystem.PlayerHeat[src] <= 0 then return end
    
    CrimeSystem.PlayerHeat[src] = math.max(CrimeSystem.PlayerHeat[src] - CrimeConfig.Heat.heatDecayRate, 0)
    TriggerClientEvent('umeverse_crime:updateHeat', src, CrimeSystem.PlayerHeat[src])
end

-- Police Response System
function CrimeSystem.CheckPoliceResponse(src)
    local heat = CrimeSystem.PlayerHeat[src]
    local responseLevel = nil
    
    if heat >= CrimeConfig.Heat.policeResponse.high.minHeat then
        responseLevel = 'high'
    elseif heat >= CrimeConfig.Heat.policeResponse.medium.minHeat then
        responseLevel = 'medium'
    elseif heat >= CrimeConfig.Heat.policeResponse.low.minHeat then
        responseLevel = 'low'
    end
    
    if responseLevel then
        TriggerEvent('umeverse_crime:policeDispatch', src, responseLevel, CrimeSystem.PlayerHeat[src])
    end
end

-- Handle crime completion
RegisterNetEvent('umeverse_crime:attemptCrime')
AddEventHandler('umeverse_crime:attemptCrime', function(crimeType, teamMembers)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    
    if not Player or not CrimeConfig.Crimes[crimeType] then
        return
    end
    
    local crime = CrimeConfig.Crimes[crimeType]
    local successChance = math.random(crime.successChance.min, crime.successChance.max)
    local success = math.random(1, 100) <= successChance
    
    -- Get specialization bonus
    local specialBonus = 0
    if CrimeSystem.Specializations[Player.PlayerData.citizenid] then
        local spec = CrimeSystem.Specializations[Player.PlayerData.citizenid]
        for _, bonusCrime in ipairs(CrimeConfig.Specializations[spec].crimeBonus) do
            if bonusCrime == crimeType then
                specialBonus = CrimeConfig.Specializations[spec].successBonus or 0
                break
            end
        end
    end
    
    if success then
        local reward = math.random(crime.rewards.black_money.min, crime.rewards.black_money.max)
        reward = math.floor(reward * (1 + (specialBonus / 100)))
        
        Player.Functions.AddMoney('black', reward, 'Crime - ' .. crime.label)
        CrimeSystem.AddHeat(src, crime.heat, 1.0)
        CrimeSystem.LogCrime(src, crimeType, true, reward)
        
        TriggerClientEvent('umeverse_crime:notify', src, 'success', 'Crime successful! Earned $' .. reward)
    else
        CrimeSystem.AddHeat(src, crime.heat * 1.5, 1.0) -- Increased heat on failure
        CrimeSystem.LogCrime(src, crimeType, false, 0)
        
        TriggerClientEvent('umeverse_crime:notify', src, 'error', 'Crime failed!')
    end
end)

-- Get player heat
RegisterNetEvent('umeverse_crime:getPlayerHeat')
AddEventHandler('umeverse_crime:getPlayerHeat', function()
    local src = source
    local heat = CrimeSystem.PlayerHeat[src] or 0
    TriggerClientEvent('umeverse_crime:updateHeat', src, heat)
end)

-- Get player crime stats
RegisterNetEvent('umeverse_crime:getCrimeStats')
AddEventHandler('umeverse_crime:getCrimeStats', function()
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end
    
    MySQL.query('SELECT * FROM umeverse_crime_logs WHERE identifier = ?', { Player.PlayerData.citizenid }, function(result)
        if result and #result > 0 then
            local stats = {
                total = #result,
                successful = 0,
                failed = 0,
                totalEarned = 0,
            }
            
            for _, log in ipairs(result) do
                if log.success == 1 then
                    stats.successful = stats.successful + 1
                    stats.totalEarned = stats.totalEarned + (log.reward or 0)
                else
                    stats.failed = stats.failed + 1
                end
            end
            
            TriggerClientEvent('umeverse_crime:updateStats', src, stats)
        end
    end)
end)

-- Player joined
AddEventHandler('playerJoined', function()
    local src = source
    local identifier = GetPlayerIdentifier(src, 0)
    CrimeSystem.InitializePlayer(src, identifier)
end)

-- Player dropped
AddEventHandler('playerDropped', function()
    local src = source
    CrimeSystem.PlayerCrimes[src] = nil
    CrimeSystem.PlayerHeat[src] = nil
end)

-- Heat decay loop
Citizen.CreateThread(function()
    while true do
        Wait(60000) -- Every minute
        for src in pairs(CrimeSystem.PlayerHeat) do
            CrimeSystem.ReduceHeat(src)
        end
    end
end)

print('^2[Umeverse]^7 Crime System loaded')
