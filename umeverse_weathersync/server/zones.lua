--[[
    Umeverse WeatherSync - Server Zone Manager
    Maintains per-zone weather state, cycles independently, handles admin overrides.
    Broadcasts zone state to all clients so they can transition smoothly.
]]

local UME = exports['umeverse_core']:GetCoreObject()

-- ═══════════════════════════════════════
-- Zone State
-- ═══════════════════════════════════════
-- ZoneState[zoneName] = { weather = 'CLEAR', override = false, untilTs = 0 }
-- override = true means an admin locked this zone
-- untilTs  = 0 means permanent lock, > 0 means expires at that Unix timestamp

local ZoneState = {}

-- ═══════════════════════════════════════
-- Helpers
-- ═══════════════════════════════════════

local function IsBlacklisted(name)
    for _, b in ipairs(WeatherConfig.BlacklistedWeather or {}) do
        if b == name then return true end
    end
    return false
end

local function WeightedPick(weights)
    local pool = {}
    local total = 0

    for weather, w in pairs(weights or {}) do
        if w > 0 and not IsBlacklisted(weather) then
            total = total + w
            pool[#pool + 1] = { weather = weather, cumWeight = total }
        end
    end

    if total <= 0 then return WeatherConfig.DefaultWeather end

    local roll = math.random(1, total)
    for _, entry in ipairs(pool) do
        if roll <= entry.cumWeight then
            return entry.weather
        end
    end

    return WeatherConfig.DefaultWeather
end

local function FindZoneDef(zoneName)
    for _, z in ipairs(WeatherConfig.ZoneWeather.Zones or {}) do
        if z.name == zoneName then return z end
    end
end

local function BroadcastZoneState(target)
    TriggerClientEvent('umeverse_weather:client:zoneState', target or -1, ZoneState)
end

-- ═══════════════════════════════════════
-- Init – seed each zone with a starting weather
-- ═══════════════════════════════════════

CreateThread(function()
    if not (WeatherConfig.ZoneWeather and WeatherConfig.ZoneWeather.Enabled) then return end

    for _, zone in ipairs(WeatherConfig.ZoneWeather.Zones or {}) do
        ZoneState[zone.name] = {
            weather  = WeightedPick(zone.weights or WeatherConfig.WeatherWeights),
            override = false,
            untilTs  = 0,
        }
    end

    -- Small delay so clients connecting during start-up receive the state
    Wait(500)
    BroadcastZoneState(-1)
end)

-- ═══════════════════════════════════════
-- Dynamic Zone Weather Cycle
-- ═══════════════════════════════════════

CreateThread(function()
    if not (WeatherConfig.ZoneWeather and WeatherConfig.ZoneWeather.Enabled) then return end

    while true do
        Wait((WeatherConfig.WeatherChangeTime or 600) * 1000)

        local nowTs = os.time()
        local changed = false

        for _, zone in ipairs(WeatherConfig.ZoneWeather.Zones or {}) do
            local st = ZoneState[zone.name]
            if not st then
                st = { weather = WeatherConfig.DefaultWeather, override = false, untilTs = 0 }
                ZoneState[zone.name] = st
            end

            -- Check if override has expired
            if st.override and st.untilTs > 0 and st.untilTs <= nowTs then
                st.override = false
                st.untilTs  = 0
            end

            -- Only cycle if no active admin override
            if not st.override then
                local newWeather = WeightedPick(zone.weights or WeatherConfig.WeatherWeights)
                if newWeather ~= st.weather then
                    st.weather = newWeather
                    changed = true
                    print(('[WeatherSync] Zone %s weather changed to: %s'):format(zone.name, newWeather))
                end
            end
        end

        if changed then
            BroadcastZoneState(-1)
        end
    end
end)

-- ═══════════════════════════════════════
-- Client requesting zone state (on join / reconnect)
-- ═══════════════════════════════════════

RegisterNetEvent('umeverse_weather:server:requestZoneState', function()
    local src = source
    BroadcastZoneState(src)
end)

-- ═══════════════════════════════════════
-- Admin Command: /setzoneweather [zone] [weather] [minutes?]
-- minutes = 0 or omitted → permanent until manually cleared
-- ═══════════════════════════════════════

RegisterCommand('setzoneweather', function(source, args, _)
    -- Permission check (console always allowed)
    if source > 0 then
        local hasAce = IsPlayerAceAllowed(source, WeatherConfig.Admin.AcePermission)
        local hasPerm = UME.HasPermission(source, 'umeverse.admin')
        if not hasAce and not hasPerm then
            TriggerClientEvent('umeverse:client:notify', source, 'No permission.', 'error')
            return
        end
    end

    local zoneName = string.upper(tostring(args[1] or ''))
    local weather  = string.upper(tostring(args[2] or ''))
    local minutes  = tonumber(args[3]) or 0

    -- Validate zone
    local zoneDef = FindZoneDef(zoneName)
    if not zoneDef then
        local names = {}
        for _, z in ipairs(WeatherConfig.ZoneWeather.Zones or {}) do names[#names + 1] = z.name end
        local msg = 'Unknown zone. Available: ' .. table.concat(names, ', ')
        if source > 0 then
            TriggerClientEvent('umeverse:client:notify', source, msg, 'error')
        else
            print(msg)
        end
        return
    end

    -- Validate weather
    local valid = false
    for _, w in ipairs(WeatherConfig.WeatherTypes or {}) do
        if w == weather then valid = true; break end
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

    -- Apply override
    local untilTs = 0
    if minutes > 0 then
        untilTs = os.time() + math.floor(minutes * 60)
    end

    ZoneState[zoneName] = { weather = weather, override = true, untilTs = untilTs }
    BroadcastZoneState(-1)

    local duration = minutes > 0 and (' for %d min'):format(minutes) or ' (permanent)'
    local msg = ('Zone %s weather set to %s%s'):format(zoneName, weather, duration)
    if source > 0 then
        TriggerClientEvent('umeverse:client:notify', source, msg, 'success')
    end
    print('[WeatherSync] ' .. msg)
end, false)

-- ═══════════════════════════════════════
-- Admin Command: /clearzoneweather [zone]
-- Removes the admin override so dynamic cycling resumes
-- ═══════════════════════════════════════

RegisterCommand('clearzoneweather', function(source, args, _)
    if source > 0 then
        local hasAce = IsPlayerAceAllowed(source, WeatherConfig.Admin.AcePermission)
        local hasPerm = UME.HasPermission(source, 'umeverse.admin')
        if not hasAce and not hasPerm then
            TriggerClientEvent('umeverse:client:notify', source, 'No permission.', 'error')
            return
        end
    end

    local zoneName = string.upper(tostring(args[1] or ''))
    local st = ZoneState[zoneName]
    if not st then
        local msg = 'Unknown zone or no state.'
        if source > 0 then
            TriggerClientEvent('umeverse:client:notify', source, msg, 'error')
        else
            print(msg)
        end
        return
    end

    st.override = false
    st.untilTs  = 0
    BroadcastZoneState(-1)

    local msg = ('Zone %s weather override cleared.'):format(zoneName)
    if source > 0 then
        TriggerClientEvent('umeverse:client:notify', source, msg, 'success')
    end
    print('[WeatherSync] ' .. msg)
end, false)
