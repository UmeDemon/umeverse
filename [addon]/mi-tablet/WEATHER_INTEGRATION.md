# MI Tablet - Weather Integration with tmc_realtimeweather

## Overview
The MI Tablet weather app now uses real-time weather data from the `tmc_realtimeweather` resource, providing accurate and synchronized weather information across the server.

## Features
- **Real-time Weather Sync**: Weather displayed matches the actual in-game weather from tmc_realtimeweather
- **UK-Realistic Data**: Weather details (temperature, humidity, wind, etc.) are calculated based on UK weather patterns
- **Dynamic Updates**: Weather changes automatically as tmc_realtimeweather updates the server weather
- **3-Day Forecast**: Realistic forecast based on current weather trends
- **Detailed Metrics**: Includes temperature, feels like, humidity, wind speed, visibility, UV index, rain chance, and pressure

## How It Works

### 1. tmc_realtimeweather Export Functions
The `tmc_realtimeweather` resource now exports three functions:
- `GetCurrentWeather()` - Returns the current weather type (e.g., "CLOUDS", "RAIN", "CLEAR")
- `GetCurrentTime()` - Returns the current UK time (hour, minute, second)
- `GetLocation()` - Returns the configured location name (e.g., "Liverpool")

### 2. MI Tablet Server Integration
The tablet server requests weather data from tmc_realtimeweather and calculates realistic metrics:

```lua
TMC.Functions.CreateCallback('mi-tablet:server:getWeather', function(source, cb)
    local currentWeather = exports.tmc_realtimeweather:GetCurrentWeather()
    local hour, min, sec = exports.tmc_realtimeweather:GetCurrentTime()
    local location = exports.tmc_realtimeweather:GetLocation()
    -- ... processes and returns comprehensive weather data
end)
```

### 3. Weather Detail Calculation
Based on the weather type, the server calculates UK-realistic values:

| Weather Type | Temp Range | Humidity | Wind Speed | Visibility | Rain Chance |
|-------------|------------|----------|------------|------------|-------------|
| EXTRASUNNY  | 18-24°C    | 40-55%   | 8-15 km/h  | 15 km      | 5%          |
| CLEAR       | 15-20°C    | 50-65%   | 10-18 km/h | 12 km      | 10%         |
| CLOUDS      | 12-18°C    | 60-75%   | 12-22 km/h | 10 km      | 25%         |
| OVERCAST    | 10-16°C    | 70-85%   | 15-28 km/h | 8 km       | 45%         |
| RAIN        | 8-14°C     | 80-95%   | 18-32 km/h | 5 km       | 85%         |
| FOGGY       | 6-12°C     | 90-98%   | 5-12 km/h  | 2 km       | 30%         |
| THUNDER     | 10-16°C    | 85-95%   | 25-45 km/h | 4 km       | 95%         |
| SMOG        | 14-18°C    | 65-80%   | 5-10 km/h  | 3 km       | 15%         |
| CLEARING    | 13-17°C    | 60-70%   | 12-20 km/h | 10 km      | 20%         |

### 4. Client Request Flow
1. User opens weather app in tablet
2. Client calls NUI callback `getWeather`
3. Client triggers server callback `mi-tablet:server:getWeather`
4. Server requests data from tmc_realtimeweather
5. Server calculates realistic weather details
6. Server returns comprehensive weather data to client
7. Client displays weather information in UI

## Weather Data Structure

```javascript
{
    weather: "Cloudy",              // Human-readable weather type
    hash: "CLOUDS",                 // Game weather hash
    temperature: 15,                // Temperature in Celsius
    feelsLike: 13,                  // Feels-like temperature
    humidity: 68,                   // Humidity percentage
    windSpeed: 18,                  // Wind speed in km/h
    visibility: 10,                 // Visibility in km
    uvIndex: 3,                     // UV Index (0-11)
    rainChance: 25,                 // Rain probability %
    pressure: 1013,                 // Atmospheric pressure in hPa
    sunrise: "06:32",               // Sunrise time
    sunset: "20:15",                // Sunset time
    moonPhase: "Waxing Crescent",   // Current moon phase
    location: "Liverpool",          // Location from tmc_realtimeweather
    forecast: [                     // 3-day forecast
        {
            day: "Tomorrow",
            weather: "Rainy",
            high: 18,
            low: 11
        },
        // ... more days
    ]
}
```

## Dependencies
Make sure both resources are started in the correct order in your `server.cfg`:
```cfg
ensure tmc_realtimeweather
ensure mi-tablet
```

## Configuration

### Changing the Location
To change the displayed location in the weather app, edit the `tmc_realtimeweather` configuration:

1. Open `[testingdev]\tmc_realtimeweather\server.lua`
2. Find the location configuration:
```lua
local OWM_CITY = 'Liverpool,GB'
local OWM_CITY_NAME = 'Liverpool' -- Display name for the location
```
3. Update both values:
   - `OWM_CITY` - Used for OpenWeatherMap API (must be in format 'City,CountryCode')
   - `OWM_CITY_NAME` - The name displayed in the weather app

Example for London:
```lua
local OWM_CITY = 'London,GB'
local OWM_CITY_NAME = 'London'
```

The location will automatically update in the mi-tablet weather app without any additional changes needed.

## Fallback Behavior
If `tmc_realtimeweather` is unavailable or returns no data:
- The tablet will fall back to using local game weather detection
- Default values will be used for weather metrics
- The app will still function but without synchronized real-time data

## Benefits
- **Immersive Experience**: Weather data matches what players see in-game
- **Server-wide Consistency**: All players see the same weather information
- **Realistic UK Weather**: Temperature and conditions reflect UK climate patterns
- **Automatic Updates**: Weather changes propagate to tablets without requiring manual refreshes

## Technical Notes
- Weather calculations use randomized values within realistic ranges to add variety
- Sunrise/sunset times adjust based on season (simplified monthly calculation)
- Moon phase is calculated based on the day of the month
- Feels-like temperature accounts for wind chill
- Forecast is generated with slight variations from current conditions

## Troubleshooting

### Weather not updating
1. Ensure `tmc_realtimeweather` is running: `/ensure tmc_realtimeweather`
2. Check console for errors from either resource
3. Restart mi-tablet: `/restart mi-tablet`

### Default values showing
- Verify tmc_realtimeweather is in the dependencies list
- Check that tmc_realtimeweather exports are working

### Weather doesn't match game
- tmc_realtimeweather may be updating (changes every 10-20 minutes)
- Close and reopen the weather app to refresh data
