--[[
    Umeverse Crime System - Consequences
    Criminal records, wanted levels, police response, prison sentences
]]

CrimeConsequences = {}

-- Apply consequences for crime
function CrimeConsequences.ApplyConsequences(src, crimeType, severity)
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return false end
    
    severity = severity or 'normal'
    
    local consequence = GangsConfig.Crime and GangsConfig.Crime[crimeType]
    if not consequence then return false end
    
    -- Add wanted level
    local wantedLevel = consequence.wantedLevel or 2
    if severity == 'severe' then
        wantedLevel = wantedLevel + 2
    elseif severity == 'minor' then
        wantedLevel = math.max(1, wantedLevel - 1)
    end
    
    CrimeConsequences.AddWantedLevel(src, wantedLevel)
    
    -- Log crime
    CrimeConsequences.LogCrime(src, crimeType, severity, Player.PlayerData.citizenid)
    
    -- Police dispatch
    if wantedLevel >= 2 then
        CrimeConsequences.DispatchPolice(src, crimeType, wantedLevel)
    end
    
    -- Add to criminal record
    CrimeConsequences.AddCriminalRecord(Player.PlayerData.citizenid, crimeType)
    
    return true
end

-- Add wanted level
function CrimeConsequences.AddWantedLevel(src, amount)
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return false end
    
    local currentWanted = Player.PlayerData.metadata.wanted or 0
    local newWanted = math.min(currentWanted + amount, 5) -- Max 5 stars
    
    Player.Functions.SetMetaData('wanted', newWanted)
    
    TriggerClientEvent('umeverse_crime:setWantedLevel', src, newWanted)
    
    return newWanted
end

-- Remove wanted level
function CrimeConsequences.RemoveWantedLevel(src, amount)
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return false end
    
    local currentWanted = Player.PlayerData.metadata.wanted or 0
    local newWanted = math.max(currentWanted - amount, 0)
    
    Player.Functions.SetMetaData('wanted', newWanted)
    
    TriggerClientEvent('umeverse_crime:setWantedLevel', src, newWanted)
    
    return newWanted
end

-- Log crime to database
function CrimeConsequences.LogCrime(src, crimeType, severity, identifier)
    MySQL.Sync.execute('INSERT INTO umeverse_crime_logs (identifier, crime_type, severity, timestamp) VALUES (?, ?, ?, ?)',
        {identifier, crimeType, severity, os.time()})
end

-- Add to criminal record
function CrimeConsequences.AddCriminalRecord(identifier, crimeType)
    MySQL.Sync.execute('INSERT INTO umeverse_criminal_records (identifier, crime_type, recorded_at) VALUES (?, ?, ?)',
        {identifier, crimeType, os.time()})
end

-- Get criminal record
function CrimeConsequences.GetCriminalRecord(identifier, days)
    days = days or 30
    
    local timeSince = os.time() - (days * 86400)
    
    local records = MySQL.Sync.fetchAll('SELECT * FROM umeverse_criminal_records WHERE identifier = ? AND recorded_at > ? ORDER BY recorded_at DESC',
        {identifier, timeSince})
    
    return records or {}
end

-- Dispatch police based on wanted level
function CrimeConsequences.DispatchPolice(src, crimeType, wantedLevel)
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end
    
    local coords = GetEntityCoords(GetPlayerPed(src))
    
    local dispatchData = {
        player = src,
        ped = GetPlayerPed(src),
        coords = coords,
        street = 'Unknown',
        wantedLevel = wantedLevel,
        crime = crimeType,
    }
    
    -- Determine police response
    local responseLevel = 'patrol'
    if wantedLevel >= 3 then
        responseLevel = 'swat'
    elseif wantedLevel >= 2 then
        responseLevel = 'units'
    end
    
    dispatchData.responseLevel = responseLevel
    
    TriggerEvent('umeverse_crime:policeDispatch', dispatchData)
end

-- Prison sentence
function CrimeConsequences.CalculateSentence(criminalHistory)
    local baseTime = 10 -- minutes
    
    if #criminalHistory > 0 then
        baseTime = baseTime + (#criminalHistory * 5) -- Add 5 min per prior conviction
    end
    
    return math.min(baseTime, 120) -- Max 2 hours
end

-- Send to prison
function CrimeConsequences.SendToPrison(src, sentenceMinutes)
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return false end
    
    -- Remove weapons
    TriggerClientEvent('umeverse_crime:removePrisonWeapons', src)
    
    -- Set player location to prison
    local prisonSpawn = GangsConfig and GangsConfig.PrisonSpawn or vector3(1641.8, 2570.7, 45.6)
    
    Player.Functions.TeleportToCoords(prisonSpawn, 340.0)
    
    -- Set metadata
    Player.Functions.SetMetaData('injail', sentenceMinutes)
    
    TriggerClientEvent('umeverse_gangs:notify', src, 'warning', 'Sentenced to ' .. sentenceMinutes .. ' minutes in prison')
    
    return true
end

-- Check if player has warrant
function CrimeConsequences.HasWarrant(identifier)
    local records = CrimeConsequences.GetCriminalRecord(identifier, 30)
    
    if #records >= 3 then
        return true
    end
    
    return false
end

-- Criminal rating (0-100, higher = more criminal)
function CrimeConsequences.GetCriminalRating(identifier)
    local records = CrimeConsequences.GetCriminalRecord(identifier, 90)
    
    -- 1 crime = 10 points, max 100
    local rating = math.min(#records * 10, 100)
    
    return rating
end

-- NPC police interactions based on criminal rating
function CrimeConsequences.CheckNPCRecognition(src, npc)
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return false end
    
    local rating = CrimeConsequences.GetCriminalRating(Player.PlayerData.citizenid)
    
    -- Higher rating = higher chance of recognition
    if rating >= 30 then
        TriggerClientEvent('umeverse_crime:npcRecognizesPlayer', src, npc, rating)
    end
end

RegisterNetEvent('umeverse_crime:applyConsequences')
AddEventHandler('umeverse_crime:applyConsequences', function(crimeType, severity)
    CrimeConsequences.ApplyConsequences(source, crimeType, severity)
end)

RegisterNetEvent('umeverse_crime:sendToPrison')
AddEventHandler('umeverse_crime:sendToPrison', function(sentenceMinutes)
    CrimeConsequences.SendToPrison(source, sentenceMinutes)
end)

exports('getCriminalRating', function(identifier)
    return CrimeConsequences.GetCriminalRating(identifier)
end)

exports('hasWarrant', function(identifier)
    return CrimeConsequences.HasWarrant(identifier)
end)

print('^2[Umeverse]^7 Crime Consequences System loaded')
