--[[
    Umeverse WeatherSync - Server
    Manages authoritative weather & time state, syncs to all clients
]]

local UME = exports['umeverse_core']:GetCoreObject()

-- ═══════════════════════════════════════
-- State
-- ═══════════════════════════════════════

local currentWeather = WeatherConfig.DefaultWeather
local currentHour    = WeatherConfig.BaseTime
local currentMinute  = 0
local isFrozen       = WeatherConfig.FreezeTime
local lastWeatherChange = os.time()

-- ═══════════════════════════════════════
-- Time Advancement
-- ═══════════════════════════════════════

CreateThread(function()
    while true do
        Wait(1000)

        if not isFrozen then
            -- Advance time: at speed 1.0, 1 real second = 1 game second
            -- FiveM default: 1 real second = 30 game seconds (roughly)
            -- We use a multiplier so 1.0 = real-time, 30.0 = GTA default speed
            local advanceSeconds = WeatherConfig.TimeSpeed
            currentMinute = currentMinute + (advanceSeconds / 2.0) -- ~30x default

            if currentMinute >= 60 then
                currentHour = currentHour + math.floor(currentMinute / 60)
                currentMinute = currentMinute % 60
            end

            if currentHour >= 24 then
                currentHour = currentHour - 24
            end
        end
    end
end)

-- ═══════════════════════════════════════
-- Dynamic Weather
-- ═══════════════════════════════════════

local function PickRandomWeather()
    -- Build weighted pool
    local pool = {}
    local totalWeight = 0

    for weather, weight in pairs(WeatherConfig.WeatherWeights) do
        local blacklisted = false
        for _, bl in ipairs(WeatherConfig.BlacklistedWeather) do
            if bl == weather then blacklisted = true; break end
        end
        if not blacklisted then
            totalWeight = totalWeight + weight
            pool[#pool + 1] = { weather = weather, cumWeight = totalWeight }
        end
    end

    local roll = math.random(1, totalWeight)
    for _, entry in ipairs(pool) do
        if roll <= entry.cumWeight then
            return entry.weather
        end
    end

    return 'CLEAR'
end

CreateThread(function()
    while true do
        Wait(WeatherConfig.WeatherChangeTime * 1000)

        if WeatherConfig.DynamicWeather then
            local newWeather = PickRandomWeather()
            if newWeather ~= currentWeather then
                currentWeather = newWeather
                TriggerClientEvent('umeverse_weather:client:setWeather', -1, currentWeather, WeatherConfig.TransitionTime)
                print('[WeatherSync] Weather changed to: ' .. currentWeather)
            end
        end
    end
end)

-- ═══════════════════════════════════════
-- Client Sync
-- ═══════════════════════════════════════

CreateThread(function()
    while true do
        Wait(WeatherConfig.SyncInterval * 1000)
        TriggerClientEvent('umeverse_weather:client:sync', -1, currentWeather, currentHour, math.floor(currentMinute), isFrozen)
    end
end)

-- Sync newly joined players
RegisterNetEvent('umeverse_weather:server:requestSync', function()
    local src = source
    TriggerClientEvent('umeverse_weather:client:sync', src, currentWeather, currentHour, math.floor(currentMinute), isFrozen)
end)

-- ═══════════════════════════════════════
-- Admin Commands
-- ═══════════════════════════════════════

RegisterCommand('weather', function(source, args, _)
    if source > 0 and not UME.HasPermission(source, 'umeverse.admin') then
        TriggerClientEvent('umeverse:client:notify', source, 'No permission.', 'error')
        return
    end

    if not args[1] then
        local msg = string.format('Current weather: %s | Time: %02d:%02d | Frozen: %s',
            currentWeather, currentHour, math.floor(currentMinute), tostring(isFrozen))
        if source > 0 then
            TriggerClientEvent('umeverse:client:notify', source, msg, 'info')
        else
            print(msg)
        end
        return
    end

    local newWeather = string.upper(args[1])
    local valid = false
    for _, w in ipairs(WeatherConfig.WeatherTypes) do
        if w == newWeather then valid = true; break end
    end

    if not valid then
        local msg = 'Invalid weather. Valid: ' .. table.concat(WeatherConfig.WeatherTypes, ', ')
        if source > 0 then
            TriggerClientEvent('umeverse:client:notify', source, msg, 'error')
        else
            print(msg)
        end
        return
    end

    currentWeather = newWeather
    TriggerClientEvent('umeverse_weather:client:setWeather', -1, currentWeather, WeatherConfig.TransitionTime)

    local msg = 'Weather set to: ' .. currentWeather
    if source > 0 then
        TriggerClientEvent('umeverse:client:notify', source, msg, 'success')
    end
    print('[WeatherSync] Admin set weather to: ' .. currentWeather)
end, false)

RegisterCommand('time', function(source, args, _)
    if source > 0 and not UME.HasPermission(source, 'umeverse.admin') then
        TriggerClientEvent('umeverse:client:notify', source, 'No permission.', 'error')
        return
    end

    if not args[1] or not args[2] then
        local msg = 'Usage: /time [hour] [minute]'
        if source > 0 then
            TriggerClientEvent('umeverse:client:notify', source, msg, 'error')
        else
            print(msg)
        end
        return
    end

    local hour = tonumber(args[1])
    local minute = tonumber(args[2]) or 0

    if not hour or hour < 0 or hour > 23 then
        if source > 0 then
            TriggerClientEvent('umeverse:client:notify', source, 'Hour must be 0-23.', 'error')
        end
        return
    end

    currentHour = hour
    currentMinute = math.max(0, math.min(59, minute))
    TriggerClientEvent('umeverse_weather:client:sync', -1, currentWeather, currentHour, math.floor(currentMinute), isFrozen)

    local msg = string.format('Time set to %02d:%02d', currentHour, math.floor(currentMinute))
    if source > 0 then
        TriggerClientEvent('umeverse:client:notify', source, msg, 'success')
    end
    print('[WeatherSync] ' .. msg)
end, false)

RegisterCommand('freezetime', function(source, args, _)
    if source > 0 and not UME.HasPermission(source, 'umeverse.admin') then
        TriggerClientEvent('umeverse:client:notify', source, 'No permission.', 'error')
        return
    end

    isFrozen = not isFrozen
    TriggerClientEvent('umeverse_weather:client:sync', -1, currentWeather, currentHour, math.floor(currentMinute), isFrozen)

    local msg = 'Time is now ' .. (isFrozen and 'frozen' or 'unfrozen')
    if source > 0 then
        TriggerClientEvent('umeverse:client:notify', source, msg, 'success')
    end
    print('[WeatherSync] ' .. msg)
end, false)

-- ═══════════════════════════════════════
-- Exports
-- ═══════════════════════════════════════

exports('GetCurrentWeather', function() return currentWeather end)
exports('GetCurrentTime', function() return currentHour, math.floor(currentMinute) end)
exports('IsTimeFrozen', function() return isFrozen end)

exports('SetWeather', function(weather)
    currentWeather = weather
    TriggerClientEvent('umeverse_weather:client:setWeather', -1, currentWeather, WeatherConfig.TransitionTime)
end)

exports('SetTime', function(hour, minute)
    currentHour = hour
    currentMinute = minute or 0
    TriggerClientEvent('umeverse_weather:client:sync', -1, currentWeather, currentHour, math.floor(currentMinute), isFrozen)
end)
