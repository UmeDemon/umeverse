--[[
    Umeverse WeatherSync - Configuration
]]

WeatherConfig = {}

-- Time Settings
WeatherConfig.BaseTime     = 8     -- Starting hour (0-23) on server start
WeatherConfig.TimeSpeed    = 1.0   -- Multiplier: 1.0 = real-time, 2.0 = double speed
WeatherConfig.FreezeTime   = false -- If true, time doesn't advance
WeatherConfig.SyncInterval = 5     -- Seconds between client syncs

-- Weather Settings
WeatherConfig.DefaultWeather      = 'CLEAR'
WeatherConfig.DynamicWeather      = true  -- Automatically cycle weather
WeatherConfig.WeatherChangeTime   = 600   -- Seconds between weather changes (10 min)
WeatherConfig.TransitionTime      = 30.0  -- Seconds for weather transition on client

-- Blacklisted weather types (won't be chosen by dynamic weather)
WeatherConfig.BlacklistedWeather = {
    'XMAS',       -- Xmas snow
    'HALLOWEEN',  -- Halloween
}

-- All valid GTA weather types
WeatherConfig.WeatherTypes = {
    'CLEAR',
    'EXTRASUNNY',
    'CLOUDS',
    'OVERCAST',
    'RAIN',
    'CLEARING',
    'THUNDER',
    'SMOG',
    'FOGGY',
    'XMAS',
    'SNOWLIGHT',
    'BLIZZARD',
    'HALLOWEEN',
    'NEUTRAL',
}

-- Natural weather cycle (dynamic weather picks from this weighted list)
-- Higher weight = more common  (used as global fallback when zones are enabled)
WeatherConfig.WeatherWeights = {
    CLEAR       = 30,
    EXTRASUNNY  = 25,
    CLOUDS      = 20,
    OVERCAST    = 10,
    RAIN        = 8,
    CLEARING    = 5,
    THUNDER     = 3,
    SMOG        = 3,
    FOGGY       = 4,
    NEUTRAL     = 2,
}

-- ═══════════════════════════════════════
-- Zone-Based Weather
-- ═══════════════════════════════════════
-- Each zone has its own weather that cycles independently.
-- Players crossing between zones see a smooth transition.
-- Admins can lock a zone to a specific weather with /setzoneweather.

WeatherConfig.ZoneWeather = {
    Enabled            = true,
    ZoneCheckInterval  = 1000,   -- ms – how often the client checks which zone it's in
    ZoneTransitionTime = 20.0,   -- seconds for the smooth weather crossfade on zone change
    BoundaryBuffer     = 120.0,  -- extra metres around each zone for soft boundary handoff

    -- Define as many zones as you want.
    -- Players outside every zone fall back to the global weather.
    Zones = {
        {
            name   = 'CITY',
            label  = 'Los Santos',
            center = vector3(-270.0, -950.0, 31.0),
            radius = 2200.0,
            weights = {
                CLEAR = 22, EXTRASUNNY = 18, CLOUDS = 20, OVERCAST = 15,
                RAIN = 12, CLEARING = 6, THUNDER = 4, SMOG = 5, FOGGY = 4,
            },
        },
        {
            name   = 'SANDY',
            label  = 'Sandy Shores',
            center = vector3(1830.0, 3690.0, 34.0),
            radius = 1500.0,
            weights = {
                CLEAR = 26, EXTRASUNNY = 28, CLOUDS = 14, OVERCAST = 8,
                RAIN = 4, CLEARING = 5, THUNDER = 2, SMOG = 6, FOGGY = 2,
            },
        },
        {
            name   = 'PALETO',
            label  = 'Paleto Bay',
            center = vector3(-250.0, 6200.0, 31.0),
            radius = 1700.0,
            weights = {
                CLEAR = 14, EXTRASUNNY = 8, CLOUDS = 22, OVERCAST = 20,
                RAIN = 14, CLEARING = 7, THUNDER = 6, SMOG = 3, FOGGY = 10,
            },
        },
    },
}

-- Admin ACE permission required for /setzoneweather
WeatherConfig.Admin = {
    AcePermission = 'umeverse.weather.admin', -- add_ace group.admin umeverse.weather.admin allow
}
