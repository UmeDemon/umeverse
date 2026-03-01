--[[
    Umeverse WeatherSync - Client
    Receives weather & time state from server and applies locally
]]

-- ═══════════════════════════════════════
-- State
-- ═══════════════════════════════════════

local currentWeather  = WeatherConfig.DefaultWeather
local targetWeather   = currentWeather
local currentHour     = WeatherConfig.BaseTime
local currentMinute   = 0
local isFrozen        = false
local isTransitioning = false

-- ═══════════════════════════════════════
-- Apply Weather
-- ═══════════════════════════════════════

local function ApplyWeather(weather, transition)
    if transition and transition > 0 then
        targetWeather = weather
        isTransitioning = true

        SetWeatherTypeOvertimePersist(weather, transition)

        SetTimeout(math.floor(transition * 1000), function()
            ClearOverrideWeather()
            ClearWeatherTypePersist()
            SetWeatherTypeNowPersist(weather)
            SetWeatherTypeNow(weather)
            currentWeather = weather
            isTransitioning = false
        end)
    else
        ClearOverrideWeather()
        ClearWeatherTypePersist()
        SetWeatherTypeNowPersist(weather)
        SetWeatherTypeNow(weather)
        currentWeather = weather
        targetWeather = weather
    end
end

-- ═══════════════════════════════════════
-- Apply Time
-- ═══════════════════════════════════════

local function ApplyTime(hour, minute)
    NetworkOverrideClockTime(hour, minute, 0)
end

-- ═══════════════════════════════════════
-- Sync from Server
-- ═══════════════════════════════════════

RegisterNetEvent('umeverse_weather:client:sync', function(weather, hour, minute, frozen)
    currentHour = hour
    currentMinute = minute
    isFrozen = frozen

    ApplyTime(hour, minute)

    -- Only force weather if not in the middle of a transition
    if not isTransitioning and currentWeather ~= weather then
        ApplyWeather(weather, 0)
    end
end)

RegisterNetEvent('umeverse_weather:client:setWeather', function(weather, transitionTime)
    ApplyWeather(weather, transitionTime or 0)
end)

-- ═══════════════════════════════════════
-- Time Override Loop
-- ═══════════════════════════════════════

CreateThread(function()
    -- Disable GTA's default time advancement
    while true do
        Wait(0)
        NetworkOverrideClockTime(currentHour, currentMinute, 0)

        -- Disable GTA random weather events
        if not isTransitioning then
            SetWeatherTypeNowPersist(currentWeather)
        end
    end
end)

-- ═══════════════════════════════════════
-- Wind (subtle, weather-accurate)
-- ═══════════════════════════════════════

CreateThread(function()
    while true do
        Wait(60000) -- every minute

        local windSpeed = 0.0
        if currentWeather == 'THUNDER' or currentWeather == 'BLIZZARD' then
            windSpeed = math.random(8, 12) + 0.0
        elseif currentWeather == 'RAIN' then
            windSpeed = math.random(3, 6) + 0.0
        elseif currentWeather == 'OVERCAST' or currentWeather == 'FOGGY' then
            windSpeed = math.random(1, 3) + 0.0
        else
            windSpeed = math.random(0, 1) + 0.0
        end

        SetWindSpeed(windSpeed)
        SetWindDirection(math.random() * math.pi * 2.0)
    end
end)

-- ═══════════════════════════════════════
-- Request initial sync on spawn
-- ═══════════════════════════════════════

CreateThread(function()
    Wait(2000)
    TriggerServerEvent('umeverse_weather:server:requestSync')
end)

RegisterNetEvent('umeverse:client:playerLoaded:done', function()
    TriggerServerEvent('umeverse_weather:server:requestSync')
end)
