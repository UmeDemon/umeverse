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
-- Higher weight = more common
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
