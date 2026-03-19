--[[
    Umeverse WeatherSync - Client Zone Handler
    Detects which weather zone the player is in, applies smooth transitions
    when crossing zone boundaries or when zone weather changes server-side.
]]

-- ═══════════════════════════════════════
-- State
-- ═══════════════════════════════════════

local ZoneState       = {}       -- [zoneName] = { weather = 'CLEAR', ... }
local currentZone     = nil      -- zone name the player is currently in (nil = global)
local zoneWeather     = nil      -- the weather we last applied from zone logic
local applyToken      = 0        -- cancellation token for overlapping transitions

-- ═══════════════════════════════════════
-- Receive zone state from server
-- ═══════════════════════════════════════

RegisterNetEvent('umeverse_weather:client:zoneState', function(state)
    ZoneState = state or {}
end)

-- Request zone state on resource start / player load
CreateThread(function()
    Wait(2500) -- allow server to initialise
    TriggerServerEvent('umeverse_weather:server:requestZoneState')
end)

RegisterNetEvent('umeverse:client:playerLoaded:done', function()
    TriggerServerEvent('umeverse_weather:server:requestZoneState')
end)

-- ═══════════════════════════════════════
-- Determine which zone the player is in
-- ═══════════════════════════════════════

local function GetPlayerZone(coords)
    local cfg = WeatherConfig.ZoneWeather
    if not cfg or not cfg.Zones then return nil end

    local bestName     = nil
    local bestPriority = 0.0 -- higher = closer to centre / smaller overlap

    for _, z in ipairs(cfg.Zones) do
        local dist   = #(coords - z.center)
        local buffer = cfg.BoundaryBuffer or 0.0
        local outer  = z.radius + buffer

        if dist <= outer then
            -- Inside the hard radius → full match
            -- Inside the buffer ring → partial (still counts but lower priority)
            local priority
            if dist <= z.radius then
                priority = 1.0 + (z.radius - dist) -- deeper inside = higher
            else
                priority = 1.0 - ((dist - z.radius) / buffer)
            end

            if priority > bestPriority then
                bestPriority = priority
                bestName     = z.name
            end
        end
    end

    return bestName
end

-- ═══════════════════════════════════════
-- Apply a smooth weather transition
-- ═══════════════════════════════════════

local function ApplyZoneWeather(targetWeather, transitionTime)
    if not targetWeather then return end
    if targetWeather == zoneWeather then return end

    zoneWeather = targetWeather
    applyToken  = applyToken + 1
    local token = applyToken

    local t = transitionTime or WeatherConfig.ZoneWeather.ZoneTransitionTime or 20.0

    SetWeatherTypeOvertimePersist(targetWeather, t)

    SetTimeout(math.floor(t * 1000), function()
        if token ~= applyToken then return end -- a newer transition superseded us
        ClearOverrideWeather()
        ClearWeatherTypePersist()
        SetWeatherTypeNowPersist(targetWeather)
        SetWeatherTypeNow(targetWeather)
    end)
end

-- ═══════════════════════════════════════
-- Zone Detection Loop
-- ═══════════════════════════════════════

CreateThread(function()
    -- Wait for config & initial state
    while not WeatherConfig.ZoneWeather or not WeatherConfig.ZoneWeather.Enabled do
        Wait(1000)
    end

    local interval = WeatherConfig.ZoneWeather.ZoneCheckInterval or 1000

    while true do
        Wait(interval)

        local ped  = PlayerPedId()
        local pos  = GetEntityCoords(ped)
        local zone = GetPlayerZone(pos)

        -- Determine what weather to apply
        local targetWeather = nil

        if zone and ZoneState[zone] then
            targetWeather = ZoneState[zone].weather
        end
        -- If targetWeather is nil, we're outside all zones → let the global
        -- sync from client/main.lua handle it. We just clear our zone tracking.

        if zone ~= currentZone then
            -- Player crossed into a different zone (or left all zones)
            currentZone = zone

            if targetWeather then
                ApplyZoneWeather(targetWeather, WeatherConfig.ZoneWeather.ZoneTransitionTime)
            else
                -- Left all zones → reset so global sync takes over
                zoneWeather = nil
            end
        elseif zone and targetWeather and targetWeather ~= zoneWeather then
            -- Same zone but the server changed its weather (dynamic cycle / admin)
            ApplyZoneWeather(targetWeather, WeatherConfig.ZoneWeather.ZoneTransitionTime)
        end
    end
end)

-- ═══════════════════════════════════════
-- Exports so client/main.lua can check
-- ═══════════════════════════════════════

-- Returns the zone name the player is currently in (or nil)
exports('GetCurrentWeatherZone', function()
    return currentZone
end)

-- Returns true if zone weather is actively controlling the client
exports('IsInWeatherZone', function()
    return currentZone ~= nil and zoneWeather ~= nil
end)
