--[[
    Umeverse Crime System - Client Utilities
]]

CrimeUtils = {}
CrimeUtils.HeatLevel = 0
CrimeUtils.OnCrimeMission = false
CrimeUtils.CrimeCooldown = {}

-- Notify player
function CrimeUtils.Notify(message, type)
    type = type or 'info'
    TriggerEvent('chat:addMessage', {
        color = { r = 255, g = 0, b = 0 },
        multiline = true,
        args = { 'Crime', message }
    })
end

-- Draw crime marker
function CrimeUtils.CreateCrimeBlip(crime)
    local blip = AddBlipForCoord(crime.x, crime.y, crime.z)
    SetBlipRoute(blip, true)
    SetBlipAsNoGrp(blip, true)
    BeginTextCommandDisplayName('STRING')
    AddTextComponentString(crime.label)
    EndTextCommandDisplayName(blip)
    SetBlipDisplay(blip, 4)
    SetBlipColour(blip, 1)
    SetBlipScale(blip, 0.8)
    
    return blip
end

-- Draw marker at location
function CrimeUtils.DrawMarker(type, x, y, z, r, g, b, a, size, rotation)
    DrawMarker(type or 1, x, y, z + (size or 0.5), 0.0, 0.0, (rotation or 0),
        90.0, 0.0, 0.0, (size or 1.0), (size or 1.0), (size or 1.0),
        r or 255, g or 0, b or 0, a or 100, false, true, 2, false, nil, nil, false)
end

-- Play crime animation
function CrimeUtils.PlayCrimeAnimation(animDict, animName, duration)
    RequestAnimDict(animDict)
    while not HasAnimDictLoaded(animDict) do Wait(10) end
    
    TaskPlayAnim(PlayerPedId(), animDict, animName, 8.0, -8.0, duration, 1, 0, false, false, false)
    Wait(duration)
    ClearPedTasks(PlayerPedId())
end

-- Check if near crime location
function CrimeUtils.GetNearbyCrime(range)
    range = range or 100
    local ped = PlayerPedId()
    local pedCoords = GetEntityCoords(ped)
    
    for _, crime in ipairs(CrimeConfig.CrimeBlips) do
        local distance = #(pedCoords - vector3(crime.x, crime.y, crime.z))
        if distance < range then
            return crime, distance
        end
    end
    
    return nil
end

-- Generate crime difficulty
function CrimeUtils.GetCrimeDifficulty(crimeType)
    local crime = CrimeConfig.Crimes[crimeType]
    if not crime then return 'unknown' end
    
    return crime.difficulty or 'medium'
end

-- Get crime success chance with bonuses
function CrimeUtils.GetAdjustedSuccessChance(crimeType)
    local crime = CrimeConfig.Crimes[crimeType]
    if not crime then return 50 end
    
    local chance = (crime.successChance.min + crime.successChance.max) / 2
    
    -- Add player skill level bonus (from jobs/drugs rep)
    local playerSkill = exports['umeverse_core']:GetPlayerStat('crime_skill')
    chance = chance + (playerSkill and playerSkill * 0.05 or 0)
    
    return math.min(math.max(chance, 5), 100)
end

-- Check crime requirements
function CrimeUtils.CanCommitCrime(crimeType)
    local crime = CrimeConfig.Crimes[crimeType]
    if not crime then
        return false, 'Crime not found'
    end
    
    -- Check skill requirement
    local playerRep = exports['umeverse_core']:GetPlayerData('crimeRep') or 0
    if playerRep < crime.minSkill then
        return false, 'You are not experienced enough for this crime (Need ' .. crime.minSkill .. ' rep)'
    end
    
    -- Check specialization requirements
    if crime.requiresLockpicking then
        -- Check if player has lockpicking skill
    end
    
    if crime.requiresHacking then
        -- Check if player has hacking skill
    end
    
    -- Check energy/health
    local ped = PlayerPedId()
    if GetEntityHealth(ped) < 100 then
        return false, 'You need to be in better health'
    end
    
    return true, 'Ready'
end

-- Start crime mission
function CrimeUtils.StartCrime(crimeType)
    local canCommit, reason = CrimeUtils.CanCommitCrime(crimeType)
    if not canCommit then
        CrimeUtils.Notify(reason, 'error')
        return false
    end
    
    CrimeUtils.OnCrimeMission = true
    local crime = CrimeConfig.Crimes[crimeType]
    
    -- Show progress bar
    TriggerEvent('umeverse_core:showProgress', {
        name = crimeType,
        label = 'Committing ' .. crime.label,
        duration = math.random(crime.minTime, crime.maxTime) * 1000,
        canCancel = true,
        controlDisables = {
            disableMovement = true,
            disableCarMovement = true,
            disableMouse = false,
            disableCombat = true,
        },
        animation = {
            animDict = crime.animations.dict,
            anim = crime.animations.anim,
            flags = 1,
        },
        prop = {},
    }, function(cancelled)
        CrimeUtils.OnCrimeMission = false
        if not cancelled then
            TriggerServerEvent('umeverse_crime:attemptCrime', crimeType, {})
        else
            CrimeUtils.Notify('Crime cancelled', 'error')
        end
    end)
    
    return true
end

-- Update heat display
RegisterNetEvent('umeverse_crime:updateHeat')
AddEventHandler('umeverse_crime:updateHeat', function(heat)
    CrimeUtils.HeatLevel = heat
end)

-- Crime notification
RegisterNetEvent('umeverse_crime:notify')
AddEventHandler('umeverse_crime:notify', function(type, message)
    TriggerEvent('umeverse_core:notify', message, type)
end)

-- Draw HUD heat indicator
Citizen.CreateThread(function()
    while true do
        Wait(0)
        if CrimeUtils.HeatLevel > 0 then
            -- Draw heat indicator on screen
            local text = 'HEAT: ' .. CrimeUtils.HeatLevel .. '%'
            BeginTextCommandDisplayText('STRING')
            AddTextComponentString(text)
            EndTextCommandDisplayText(0.02, 0.05)
        end
    end
end)

return CrimeUtils
