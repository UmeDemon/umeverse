--[[
    Umeverse Crime System - Dynamic Mechanics
    Complications, witnesses, time-based bonuses, weather effects, location rotation
]]

CrimeDynamics = {}
CrimeDynamics.RecentCrimes = {}
CrimeDynamics.Witnesses = {}

-- Check for crime complications
function CrimeDynamics.CheckComplications(src)
    if not CrimeConfig or not CrimeConfig.DynamicMechanics or not CrimeConfig.DynamicMechanics.complications then
        return nil
    end
    
    local chance = CrimeConfig.DynamicMechanics.complications.baseChance or 0.15
    if math.random(100) / 100 > chance then return nil end
    
    local complications = CrimeConfig.DynamicMechanics.complications.types
    if not complications or next(complications) == nil then return nil end
    
    local types = {}
    for k, _ in pairs(complications) do table.insert(types, k) end
    
    local selected = types[math.random(#types)]
    return selected, complications[selected]
end

-- Generate witness
function CrimeDynamics.GenerateWitness(src, crimeCoords)
    if not CrimeConfig or not CrimeConfig.DynamicMechanics or not CrimeConfig.DynamicMechanics.witnesses then
        return nil
    end
    
    if not CrimeConfig.DynamicMechanics.witnesses.enabled then return nil end
    
    local witnessConfig = CrimeConfig.DynamicMechanics.witnesses
    local chance = witnessConfig.witnessChance or 0.2
    if math.random(100) / 100 > chance then return nil end
    
    local witnessId = 'witness_' .. src .. '_' .. os.time()
    local ident = math.random(100, 99999)
    
    CrimeDynamics.Witnesses[witnessId] = {
        player = src,
        identified = false,
        location = crimeCoords,
        reportTime = os.time() + (witnessConfig.timeUntilReport or 300),
        identifier = ident,
    }
    
    -- Check identification
    local identChance = (witnessConfig.identification and witnessConfig.identification.chance) or 0.4
    if math.random(100) / 100 < identChance then
        CrimeDynamics.Witnesses[witnessId].identified = true
        TriggerClientEvent('umeverse_crime:notify', src, 'warning', 'You were identified by a witness!')
    end
    
    return witnessId
end

-- Get time-based bonuses
function CrimeDynamics.GetTimeBonus()
    if not CrimeConfig or not CrimeConfig.DynamicMechanics or not CrimeConfig.DynamicMechanics.timeBased then
        return { successBonus = 0, heatReduction = 1.0 }
    end
    
    local hour = GetClockHours()
    local bonuses = { successBonus = 0, heatReduction = 1.0 }
    
    for timeName, timeData in pairs(CrimeConfig.DynamicMechanics.timeBased) do
        if timeData and hour >= (timeData.hour or 0) and hour <= (timeData.hour_end or 23) then
            if timeData.successBonus then bonuses.successBonus = timeData.successBonus end
            if timeData.successPenalty then bonuses.successBonus = -timeData.successPenalty end
            if timeData.heatReduction then bonuses.heatReduction = timeData.heatReduction end
            if timeData.heatMultiplier then bonuses.heatReduction = timeData.heatMultiplier end
            break
        end
    end
    
    return bonuses
end

-- Get weather bonuses
function CrimeDynamics.GetWeatherBonus()
    if not CrimeConfig or not CrimeConfig.DynamicMechanics or not CrimeConfig.DynamicMechanics.weather then
        return {}
    end
    
    local weather = GetCurrentWeather()
    local weatherData = CrimeConfig.DynamicMechanics.weather
    
    if weather and weatherData[weather] then
        return weatherData[weather]
    end
    return {}
end

-- Check location rotation cooling
function CrimeDynamics.CheckLocationCooling(crimeType, location)
    if not CrimeConfig or not CrimeConfig.DynamicMechanics or not CrimeConfig.DynamicMechanics.locationRotation then
        return true
    end
    
    local key = crimeType .. '_' .. location
    if not CrimeDynamics.RecentCrimes[key] then return true end
    
    local timeSince = os.time() - CrimeDynamics.RecentCrimes[key]
    if timeSince < (CrimeConfig.DynamicMechanics.locationRotation.rotationTime or 1800) then
        return false
    end
    
    return true
end

-- Mark location as recently used
function CrimeDynamics.MarkLocationUsed(crimeType, location)
    local key = crimeType .. '_' .. location
    CrimeDynamics.RecentCrimes[key] = os.time()
end

-- Apply all dynamic modifiers to crime
function CrimeDynamics.ApplyModifiers(src, crimeType, baseReward)
    if not baseReward or baseReward <= 0 then
        return {
            finalReward = 0,
            multiplier = 1.0,
            modifiers = {},
        }
    end
    
    local totalMultiplier = 1.0
    local modifiers = {}
    
    -- Time bonus
    local timeBonus = CrimeDynamics.GetTimeBonus()
    if timeBonus and timeBonus.successBonus > 0 then
        totalMultiplier = totalMultiplier + (timeBonus.successBonus / 100)
        modifiers.time = timeBonus.successBonus
    end
    
    -- Weather bonus
    local weatherBonus = CrimeDynamics.GetWeatherBonus()
    if weatherBonus and weatherBonus.rewardBonus then
        totalMultiplier = totalMultiplier * (weatherBonus.rewardBonus or 1.0)
        modifiers.weather = ((weatherBonus.rewardBonus or 1.0) - 1) * 100
    end
    
    -- Check complications
    local complication, complicationData = CrimeDynamics.CheckComplications(src)
    if complication and complicationData and complicationData.rewardReduction then
        totalMultiplier = totalMultiplier * (1 - complicationData.rewardReduction)
        modifiers.complication = complication
        modifiers.complicationReward = -(complicationData.rewardReduction * 100)
    end
    
    -- Generate witness
    local witness = CrimeDynamics.GenerateWitness(src, { x = 0, y = 0, z = 0 })
    if witness then
        modifiers.witness = witness
    end
    
    return {
        finalReward = math.floor(baseReward * totalMultiplier),
        multiplier = totalMultiplier,
        modifiers = modifiers,
    }
end

-- Cleanup witness reports
Citizen.CreateThread(function()
    while true do
        Wait(30000) -- Check every 30 seconds
        
        for witnessId, witnessData in pairs(CrimeDynamics.Witnesses) do
            if os.time() >= witnessData.reportTime then
                -- Witness reports
                if witnessData.identified then
                    -- Add to player record/wanted level
                    TriggerClientEvent('umeverse_crime:notify', witnessData.player, 'error', 'A witness identified you to police!')
                end
                CrimeDynamics.Witnesses[witnessId] = nil
            end
        end
    end
end)

print('^2[Umeverse]^7 Crime Dynamic Mechanics loaded')
