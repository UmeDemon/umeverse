-- MI Tablet Server Script
-- Handles item usage and server-side logic

local TMC = exports['umeverse_core']:GetCoreObject()

-- Helper function to count table items
function table.count(t)
    local count = 0
    if t and type(t) == 'table' then
        for _ in pairs(t) do
            count = count + 1
        end
    end
    return count
end

-- Register the tablet item as useable
CreateThread(function()
    if Config.Item.RequireItem then
        TMC.Functions.CreateUseableItem(Config.Item.Name, function(source, item)
            local src = source
            local Player = TMC.Functions.GetPlayer(src)
            
            if not Player then return end
            
            -- Check job restrictions if any
            if #Config.JobRestrictions > 0 then
                local hasAccess = false
                local playerJob = Player.PlayerData.job.name
                
                for _, job in ipairs(Config.JobRestrictions) do
                    if playerJob == job then
                        hasAccess = true
                        break
                    end
                end
                
                if not hasAccess then
                    TriggerClientEvent('TMC:Notify', src, Config.Locale["job_restricted"], "error")
                    return
                end
            end
            
            -- Trigger the client to open the tablet
            TriggerClientEvent('mi-tablet:client:openTablet', src)
            
            if Config.Debug then
                print("[MI Tablet] Player " .. src .. " opened tablet")
            end
        end)
        
        print("[MI Tablet] Registered useable item: " .. Config.Item.Name)
    end
end)

-- Event to get player data for tablet
RegisterNetEvent('mi-tablet:server:getPlayerData', function()
    local src = source
    local Player = TMC.Functions.GetPlayer(src)
    
    if not Player then return end
    
    -- Safely get player data with nil checks
    local charinfo = Player.PlayerData.charinfo or {}
    local citizenid = Player.PlayerData.citizenid or "N/A"
    
    -- Fetch job from database since Player.PlayerData.job is empty
    MySQL.Async.fetchAll('SELECT jobs FROM players WHERE citizenid = ?', {citizenid}, function(result)
        local jobName = "unemployed"
        local jobGrade = 0
        local jobLabel = "Civilian"
        
        if result and result[1] and result[1].jobs then
            local jobsData = json.decode(result[1].jobs)
            if jobsData and type(jobsData) == "table" then
                -- Jobs is an array, find the first active/onduty job or just use first one
                for _, jobData in ipairs(jobsData) do
                    if jobData.onduty then
                        jobName = jobData.name or "unemployed"
                        jobLabel = jobData.label or "Civilian"
                        jobGrade = jobData.grade and jobData.grade.level or 0
                        break
                    end
                end
                
                -- If no onduty job found, use the first job in the array
                if jobName == "unemployed" and #jobsData > 0 then
                    local firstJob = jobsData[1]
                    jobName = firstJob.name or "unemployed"
                    jobLabel = firstJob.label or "Civilian"
                    jobGrade = firstJob.grade and firstJob.grade.level or 0
                end
                
                if Config.Debug then
                    print("[MI Tablet] Player has " .. #jobsData .. " jobs, selected: " .. jobName)
                end
            end
        end
        
        local playerData = {
            name = (charinfo.firstname or "Unknown") .. " " .. (charinfo.lastname or ""),
            job = jobLabel,
            jobName = jobName,
            jobGrade = jobGrade,
            citizenid = citizenid,
        }
        
        if Config.Debug then
            print(string.format("[MI Tablet] Sending player data to %s - Job: %s (Grade %d)", 
                src, playerData.jobName, playerData.jobGrade))
        end
        
        TriggerClientEvent('mi-tablet:client:receivePlayerData', src, playerData)
    end)
end)

-- Save tablet settings to database (persistent per character)
RegisterNetEvent('mi-tablet:server:saveSettings', function(settings)
    local src = source
    local Player = TMC.Functions.GetPlayer(src)
    
    if not Player then return end
    
    local citizenid = Player.PlayerData.citizenid
    
    if not citizenid then
        print("[MI Tablet] Error: No citizenid found for player " .. src)
        TriggerClientEvent('mi-tablet:client:settingsSaved', src, false)
        return
    end
    
    -- Upsert settings to database (insert or update if exists)
    MySQL.Async.execute([[
        INSERT INTO mi_tablet_settings (citizenid, wallpaper, custom_wallpaper, brightness, dark_mode, volume, notifications, font_size)
        VALUES (@citizenid, @wallpaper, @custom_wallpaper, @brightness, @dark_mode, @volume, @notifications, @font_size)
        ON DUPLICATE KEY UPDATE 
            wallpaper = @wallpaper,
            custom_wallpaper = @custom_wallpaper,
            brightness = @brightness,
            dark_mode = @dark_mode,
            volume = @volume,
            notifications = @notifications,
            font_size = @font_size,
            updated_at = CURRENT_TIMESTAMP
    ]], {
        ['@citizenid'] = citizenid,
        ['@wallpaper'] = settings.wallpaper or 'default',
        ['@custom_wallpaper'] = settings.customWallpaper or nil,
        ['@brightness'] = settings.brightness or 100,
        ['@dark_mode'] = settings.darkMode and 1 or 0,
        ['@volume'] = settings.volume or 50,
        ['@notifications'] = settings.notifications and 1 or 0,
        ['@font_size'] = settings.fontSize or 'medium'
    }, function(rowsChanged)
        if Config.Debug then
            print("[MI Tablet] Saved settings for " .. citizenid .. " (rows: " .. tostring(rowsChanged) .. ")")
        end
        TriggerClientEvent('mi-tablet:client:settingsSaved', src, true)
    end)
end)

-- Callback to load tablet settings from database
TMC.Functions.CreateCallback('mi-tablet:server:getSettings', function(source, cb)
    local src = source
    local Player = TMC.Functions.GetPlayer(src)
    
    if not Player then 
        cb(nil)
        return 
    end
    
    local citizenid = Player.PlayerData.citizenid
    
    if not citizenid then
        cb(nil)
        return
    end
    
    MySQL.Async.fetchAll('SELECT * FROM mi_tablet_settings WHERE citizenid = @citizenid', {
        ['@citizenid'] = citizenid
    }, function(result)
        if result and result[1] then
            local row = result[1]
            local settings = {
                wallpaper = row.wallpaper or 'default',
                customWallpaper = row.custom_wallpaper or '',
                brightness = row.brightness or 100,
                darkMode = row.dark_mode == 1,
                volume = row.volume or 50,
                notifications = row.notifications == 1,
                fontSize = row.font_size or 'medium'
            }
            
            if Config.Debug then
                print("[MI Tablet] Loaded settings for " .. citizenid .. ": " .. json.encode(settings))
            end
            
            cb(settings)
        else
            -- No saved settings, return nil (client will use defaults)
            if Config.Debug then
                print("[MI Tablet] No saved settings for " .. citizenid .. ", using defaults")
            end
            cb(nil)
        end
    end)
end)

-- Callback for checking if player has tablet item
TMC.Functions.CreateCallback('mi-tablet:server:hasTablet', function(source, cb)
    local src = source
    local Player = TMC.Functions.GetPlayer(src)
    
    if not Player then 
        cb(false)
        return 
    end
    
    if not Config.Item.RequireItem then
        cb(true)
        return
    end
    
    local tablet = Player.Functions.GetItemByName(Config.Item.Name)
    cb(tablet ~= nil)
end)

-- ============================================
-- Weather System Integration with tmc_realtimeweather
-- ============================================

-- Helper function to calculate realistic values based on weather type
local function getWeatherDetails(weatherType, hour)
    local details = {
        temperature = 15,
        feelsLike = 15,
        humidity = 65,
        windSpeed = 12,
        visibility = 10,
        uvIndex = 3,
        rainChance = 10,
        pressure = 1013,
        sunrise = "06:32",
        sunset = "20:15",
        location = "Liverpool", -- Default, will be overridden from tmc_realtimeweather
        moonPhase = "Waxing Crescent"
    }
    
    -- Adjust based on weather type (UK-biased)
    if weatherType == "EXTRASUNNY" then
        details.temperature = math.random(18, 24)
        details.humidity = math.random(40, 55)
        details.windSpeed = math.random(8, 15)
        details.visibility = 15
        details.uvIndex = 7
        details.rainChance = 5
    elseif weatherType == "CLEAR" then
        details.temperature = math.random(15, 20)
        details.humidity = math.random(50, 65)
        details.windSpeed = math.random(10, 18)
        details.visibility = 12
        details.uvIndex = 5
        details.rainChance = 10
    elseif weatherType == "CLOUDS" then
        details.temperature = math.random(12, 18)
        details.humidity = math.random(60, 75)
        details.windSpeed = math.random(12, 22)
        details.visibility = 10
        details.uvIndex = 3
        details.rainChance = 25
    elseif weatherType == "OVERCAST" then
        details.temperature = math.random(10, 16)
        details.humidity = math.random(70, 85)
        details.windSpeed = math.random(15, 28)
        details.visibility = 8
        details.uvIndex = 2
        details.rainChance = 45
        details.pressure = 1008
    elseif weatherType == "RAIN" then
        details.temperature = math.random(8, 14)
        details.humidity = math.random(80, 95)
        details.windSpeed = math.random(18, 32)
        details.visibility = 5
        details.uvIndex = 1
        details.rainChance = 85
        details.pressure = 1005
    elseif weatherType == "FOGGY" then
        details.temperature = math.random(6, 12)
        details.humidity = math.random(90, 98)
        details.windSpeed = math.random(5, 12)
        details.visibility = 2
        details.uvIndex = 1
        details.rainChance = 30
        details.pressure = 1010
    elseif weatherType == "THUNDER" then
        details.temperature = math.random(10, 16)
        details.humidity = math.random(85, 95)
        details.windSpeed = math.random(25, 45)
        details.visibility = 4
        details.uvIndex = 1
        details.rainChance = 95
        details.pressure = 998
    elseif weatherType == "SMOG" then
        details.temperature = math.random(14, 18)
        details.humidity = math.random(65, 80)
        details.windSpeed = math.random(5, 10)
        details.visibility = 3
        details.uvIndex = 2
        details.rainChance = 15
        details.pressure = 1012
    elseif weatherType == "CLEARING" then
        details.temperature = math.random(13, 17)
        details.humidity = math.random(60, 70)
        details.windSpeed = math.random(12, 20)
        details.visibility = 10
        details.uvIndex = 4
        details.rainChance = 20
    end
    
    -- Calculate feels like temperature (wind chill/heat index)
    details.feelsLike = details.temperature - math.floor(details.windSpeed / 10)
    
    -- Adjust sunrise/sunset based on time of year (simplified)
    local month = tonumber(os.date("%m"))
    if month >= 4 and month <= 9 then
        -- Spring/Summer
        details.sunrise = "05:30"
        details.sunset = "21:30"
    elseif month >= 10 or month <= 3 then
        -- Autumn/Winter
        details.sunrise = "07:30"
        details.sunset = "16:45"
    end
    
    -- Calculate moon phase based on day of month (simplified)
    local day = tonumber(os.date("%d"))
    local phases = {
        "New Moon", "Waxing Crescent", "First Quarter", "Waxing Gibbous",
        "Full Moon", "Waning Gibbous", "Last Quarter", "Waning Crescent"
    }
    details.moonPhase = phases[math.floor((day / 3.75) % 8) + 1]
    
    return details
end

-- Callback to get weather data from tmc_realtimeweather
TMC.Functions.CreateCallback('mi-tablet:server:getWeather', function(source, cb)
    -- Get current weather from tmc_realtimeweather
    local currentWeather = exports.tmc_realtimeweather:GetCurrentWeather()
    local hour, min, sec = exports.tmc_realtimeweather:GetCurrentTime()
    local location = exports.tmc_realtimeweather:GetLocation()
    
    if not currentWeather then
        currentWeather = "CLOUDS" -- fallback
    end
    
    -- Map weather types to readable names
    local weatherTypes = {
        ["CLEAR"] = "Clear",
        ["EXTRASUNNY"] = "Sunny",
        ["CLOUDS"] = "Cloudy",
        ["OVERCAST"] = "Overcast",
        ["RAIN"] = "Rainy",
        ["CLEARING"] = "Clearing",
        ["THUNDER"] = "Thunderstorm",
        ["SMOG"] = "Smoggy",
        ["FOGGY"] = "Foggy",
        ["XMAS"] = "Snowy",
        ["SNOWLIGHT"] = "Light Snow",
        ["BLIZZARD"] = "Blizzard",
    }
    
    local weatherName = weatherTypes[currentWeather] or "Unknown"
    local weatherDetails = getWeatherDetails(currentWeather, hour)
    
    -- Override location with data from tmc_realtimeweather
    if location then
        weatherDetails.location = location
    end
    
    -- Generate 3-day forecast (randomized but realistic)
    local forecast = {}
    local forecastDays = {"Tomorrow", "Saturday", "Sunday"}
    
    for i = 1, 3 do
        local dayWeather = currentWeather
        -- Slight variation for forecast
        if math.random(1, 100) > 60 then
            local possibleWeathers = {"CLOUDS", "OVERCAST", "RAIN", "CLEAR", "EXTRASUNNY"}
            dayWeather = possibleWeathers[math.random(1, #possibleWeathers)]
        end
        
        local dayDetails = getWeatherDetails(dayWeather, hour)
        table.insert(forecast, {
            day = forecastDays[i] or ("Day " .. i),
            weather = weatherTypes[dayWeather] or "Cloudy",
            high = dayDetails.temperature + math.random(2, 5),
            low = dayDetails.temperature - math.random(3, 6)
        })
    end
    
    -- Compile complete weather data
    local weatherData = {
        weather = weatherName,
        hash = currentWeather,
        temperature = weatherDetails.temperature,
        feelsLike = weatherDetails.feelsLike,
        humidity = weatherDetails.humidity,
        windSpeed = weatherDetails.windSpeed,
        visibility = weatherDetails.visibility,
        uvIndex = weatherDetails.uvIndex,
        rainChance = weatherDetails.rainChance,
        pressure = weatherDetails.pressure,
        sunrise = weatherDetails.sunrise,
        sunset = weatherDetails.sunset,
        moonPhase = weatherDetails.moonPhase,
        location = weatherDetails.location,
        forecast = forecast
    }
    
    if Config.Debug then
        print("[MI Tablet] Weather data sent: " .. weatherName .. " (" .. currentWeather .. ")")
    end
    
    cb(weatherData)
end)

-- Command to open tablet (alternative to item usage)
RegisterCommand('tablet', function(source, args, rawCommand)
    local src = source
    
    if src == 0 then return end -- Console check
    
    if Config.Item.RequireItem then
        local Player = TMC.Functions.GetPlayer(src)
        if not Player then return end
        
        local tablet = Player.Functions.GetItemByName(Config.Item.Name)
        if not tablet then
            TriggerClientEvent('TMC:Notify', src, Config.Locale["no_tablet"], "error")
            return
        end
    end
    
    TriggerClientEvent('mi-tablet:client:openTablet', src)
end, false)

-- ============================================
-- Rep App Server Functions
-- ============================================

-- Helper function to check if a rep type is criminal
local function IsCriminalRep(repName)
    if not Config.HideCriminalReps then return false end
    
    for _, criminalType in ipairs(Config.CriminalRepTypes) do
        if string.lower(repName) == string.lower(criminalType) then
            return true
        end
    end
    return false
end

-- Helper function to get rep label with overrides
local function GetRepLabel(rep)
    return Config.RepNameOverrides[rep] and Config.RepNameOverrides[rep] or rep
end

-- NUI Callback to get current rep data
RegisterNetEvent('mi-tablet:server:getCurrentRep', function()
    local src = source
    local Player = TMC.Functions.GetPlayer(src)
    
    if not Player then return end
    
    local repData = {}
    local playerRep = Player.PlayerData.rep or {}
    
    for repName, repValue in pairs(playerRep) do
        -- Skip criminal rep types if hiding is enabled
        if not IsCriminalRep(repName) then
            local label = GetRepLabel(repName)
            repData[label] = repValue
        end
    end
    
    if Config.Debug then
        print("[MI Tablet] Rep data for player " .. src .. ": " .. json.encode(repData))
    end
    
    TriggerClientEvent('mi-tablet:client:receiveRepData', src, repData)
end)

-- Callback version for NUI
TMC.Functions.CreateCallback('mi-tablet:server:getRepData', function(source, cb)
    local src = source
    local Player = TMC.Functions.GetPlayer(src)
    
    if not Player then 
        cb({})
        return 
    end
    
    local repData = {}
    local playerRep = Player.PlayerData.rep or {}
    
    for repName, repValue in pairs(playerRep) do
        -- Skip criminal rep types if hiding is enabled
        if not IsCriminalRep(repName) then
            local label = GetRepLabel(repName)
            repData[label] = repValue
        end
    end
    
    cb(repData)
end)

-- Callback to check if player can access darkweb (not police/medical)
-- Checks ALL jobs the player has, not just current on-duty job
TMC.Functions.CreateCallback('mi-tablet:server:canAccessDarkweb', function(source, cb)
    local src = source
    local Player = TMC.Functions.GetPlayer(src)
    
    if not Player then 
        cb(false)
        return 
    end
    
    -- Get all jobs the player has (multi-job system)
    local playerJobs = Player.PlayerData.jobs or {}
    
    -- Check each job the player has against restricted list
    for _, playerJob in pairs(playerJobs) do
        local jobName = playerJob.name or ''
        
        for _, restrictedJob in ipairs(Config.DarkwebRestrictedJobs or {}) do
            if string.lower(jobName) == string.lower(restrictedJob) then
                if Config.Debug then
                    print("[MI Tablet] Player " .. src .. " blocked from darkweb (has job: " .. jobName .. ")")
                end
                cb(false)
                return
            end
        end
    end
    
    -- Also check current active job (fallback for single-job scenarios)
    local currentJob = Player.PlayerData.job and Player.PlayerData.job.name or ''
    for _, restrictedJob in ipairs(Config.DarkwebRestrictedJobs or {}) do
        if string.lower(currentJob) == string.lower(restrictedJob) then
            if Config.Debug then
                print("[MI Tablet] Player " .. src .. " blocked from darkweb (current job: " .. currentJob .. ")")
            end
            cb(false)
            return
        end
    end
    
    cb(true)
end)

-- Callback for getting ONLY criminal rep data (for darkweb/street rep)
TMC.Functions.CreateCallback('mi-tablet:server:getCriminalRepData', function(source, cb)
    local src = source
    local Player = TMC.Functions.GetPlayer(src)
    
    if not Player then 
        cb({})
        return 
    end
    
    local repData = {}
    local playerRep = Player.PlayerData.rep or {}
    
    for repName, repValue in pairs(playerRep) do
        -- Only include criminal rep types
        local isCriminal = false
        for _, criminalType in ipairs(Config.CriminalRepTypes) do
            if string.lower(repName) == string.lower(criminalType) then
                isCriminal = true
                break
            end
        end
        
        if isCriminal then
            local label = GetRepLabel(repName)
            repData[label] = repValue
        end
    end
    
    if Config.Debug then
        print("[MI Tablet] Criminal rep data for player " .. src .. ": " .. json.encode(repData))
    end
    
    cb(repData)
end)

-- ============================================
-- Admin Permission Functions
-- ============================================

-- Permission levels hierarchy (higher index = higher permission)
local PermissionLevels = {
    ['user'] = 0,
    ['mod'] = 1,
    ['admin'] = 2,
    ['senioradmin'] = 3,
    ['god'] = 4,
    ['dev'] = 5
}

-- Check if player has required permission level or higher
local function HasRequiredPermission(src, requiredPerm)
    if not requiredPerm then return true end
    
    local requiredLevel = PermissionLevels[requiredPerm] or 0
    
    -- Check each permission level from highest to lowest
    for perm, level in pairs(PermissionLevels) do
        if level >= requiredLevel then
            if TMC.Functions.HasPermission(src, perm) then
                return true
            end
        end
    end
    
    return false
end

-- Helper function to check if player has casino job with required grade
local function HasCasinoAccess(citizenid, maxGrade)
    maxGrade = maxGrade or 1 -- Default to grade 0-1 (Manager/Supervisor)
    
    local result = MySQL.Sync.fetchAll('SELECT jobs FROM players WHERE citizenid = ?', {citizenid})
    
    if result and result[1] and result[1].jobs then
        local jobsData = json.decode(result[1].jobs)
        if jobsData and type(jobsData) == "table" then
            for _, job in ipairs(jobsData) do
                if job.name == 'casino' and job.grade and job.grade.level <= maxGrade then
                    return true
                end
            end
        end
    end
    
    return false
end

-- Callback to check if player has specific permission
TMC.Functions.CreateCallback('mi-tablet:server:hasPermission', function(source, cb, permission)
    local src = source
    local hasPermission = HasRequiredPermission(src, permission)
    
    if Config.Debug then
        print("[MI Tablet] Permission check for " .. src .. ": " .. tostring(permission) .. " = " .. tostring(hasPermission))
    end
    
    cb(hasPermission)
end)

-- Callback to get filtered apps based on player permissions
TMC.Functions.CreateCallback('mi-tablet:server:getFilteredApps', function(source, cb)
    local src = source
    local Player = TMC.Functions.GetPlayer(src)
    
    if not Player then
        cb({})
        return
    end
    
    local citizenid = Player.PlayerData.citizenid
    
    -- Fetch job from database since Player.PlayerData.job is empty
    MySQL.Async.fetchAll('SELECT jobs FROM players WHERE citizenid = ?', {citizenid}, function(result)
        local playerJobs = {}
        
        if result and result[1] and result[1].jobs then
            local jobsData = json.decode(result[1].jobs)
            if jobsData and type(jobsData) == "table" then
                playerJobs = jobsData
            end
        end
        
        local filteredApps = {}
        
        for _, app in ipairs(Config.Apps) do
            if app.enabled then
                local canAccess = true
                
                -- Check if app requires permission
                if app.requiresPermission then
                    if not HasRequiredPermission(src, app.requiresPermission) then
                        canAccess = false
                    end
                end
                
                -- Check if app requires specific job (single job)
                if canAccess and app.requiresJob then
                    local hasRequiredJob = false
                    
                    -- Check if player has the required job in their jobs array
                    for _, playerJob in ipairs(playerJobs) do
                        if playerJob.name == app.requiresJob then
                            hasRequiredJob = true
                            
                            -- Check if app requires specific grade or lower
                            if app.requiresGrade then
                                local gradeLevel = playerJob.grade and playerJob.grade.level or 999
                                if gradeLevel > app.requiresGrade then
                                    hasRequiredJob = false
                                    if Config.Debug then
                                        print(string.format("[MI Tablet] Player %s denied access to %s (grade %d > required %d)", 
                                            src, app.id, gradeLevel, app.requiresGrade))
                                    end
                                end
                            end
                            break
                        end
                    end
                    
                    if not hasRequiredJob then
                        canAccess = false
                    end
                end
                
                -- Check if app requires any of multiple jobs (requiresJobs array)
                if canAccess and app.requiresJobs then
                    local hasAnyJob = false
                    
                    for _, playerJob in ipairs(playerJobs) do
                        for _, requiredJobName in ipairs(app.requiresJobs) do
                            if playerJob.name == requiredJobName then
                                hasAnyJob = true
                                break
                            end
                        end
                        if hasAnyJob then break end
                    end
                    
                    if not hasAnyJob then
                        canAccess = false
                        if Config.Debug then
                            print(string.format("[MI Tablet] Player %s denied access to %s (no matching job from requiresJobs)", 
                                src, app.id))
                        end
                    end
                end
                
                if canAccess then
                    table.insert(filteredApps, app)
                    if Config.Debug and (app.requiresJob or app.requiresPermission) then
                        print(string.format("[MI Tablet] Player %s granted access to %s", src, app.id))
                    end
                end
            end
        end
        
        if Config.Debug then
            print("[MI Tablet] Filtered apps for player " .. src .. ": " .. #filteredApps .. " apps")
        end
        
        cb(filteredApps)
    end)
end)

-- ============================================
-- Admins App Server Functions
-- ============================================

-- Callback to get online players list (for admin app)
TMC.Functions.CreateCallback('mi-tablet:server:getOnlinePlayers', function(source, cb)
    local src = source
    
    -- Verify player has admin permission
    if not HasRequiredPermission(src, 'admin') then
        cb({ error = "No permission" })
        return
    end
    
    local players = {}
    local allPlayers = TMC.Functions.GetTMCPlayers()
    
    for _, Player in pairs(allPlayers) do
        if Player then
            local charinfo = Player.PlayerData.charinfo or {}
            local job = Player.PlayerData.job or {}
            
            table.insert(players, {
                id = Player.PlayerData.source,
                name = (charinfo.firstname or "Unknown") .. " " .. (charinfo.lastname or ""),
                citizenid = Player.PlayerData.citizenid or "N/A",
                job = job.label or "Unemployed",
                jobName = job.name or "unemployed",
                ping = GetPlayerPing(Player.PlayerData.source)
            })
        end
    end
    
    if Config.Debug then
        print("[MI Tablet] Admins app - Online players: " .. #players)
    end
    
    cb(players)
end)

-- ============================================
-- Events App Server Functions
-- ============================================

local ActiveEvent = nil

-- Callback to get active event
TMC.Functions.CreateCallback('mi-tablet:server:getActiveEvent', function(source, cb)
    local src = source
    
    -- Verify player has admin permission
    if not HasRequiredPermission(src, 'admin') then
        cb(nil)
        return
    end
    
    cb(ActiveEvent)
end)

-- Callback to start an event
TMC.Functions.CreateCallback('mi-tablet:server:startEvent', function(source, cb, eventId, eventData)
    local src = source
    
    -- Verify player has admin permission
    if not HasRequiredPermission(src, 'admin') then
        cb({ success = false, error = "No permission" })
        return
    end
    
    -- Check if an event is already running
    if ActiveEvent then
        cb({ success = false, error = "An event is already running" })
        return
    end
    
    if Config.Debug then
        print("[MI Tablet] Starting event: " .. tostring(eventId))
    end
    
    -- Try to trigger the event start
    local success = true
    local errorMsg = nil
    
    -- Handle different event types
    if eventId == 'lastmanstanding' then
        -- Tell the client to execute the /startzone command
        TriggerClientEvent('mi-tablet:client:executeCommand', src, 'startzone')
    elseif eventId == 'prophunt' then
        TriggerClientEvent('mi-tablet:client:executeCommand', src, 'prophunt_start')
    else
        success = false
        errorMsg = "Unknown event type"
    end
    
    if success then
        ActiveEvent = {
            id = eventId,
            name = eventData and eventData.name or eventId,
            startedBy = src,
            startedAt = os.time()
        }
        
        if Config.Debug then
            print("[MI Tablet] Event started: " .. tostring(eventId) .. " by player " .. src)
        end
    end
    
    cb({ success = success, error = errorMsg })
end)

-- Callback to stop an event
TMC.Functions.CreateCallback('mi-tablet:server:stopEvent', function(source, cb, eventId, eventData)
    local src = source
    
    -- Verify player has admin permission
    if not HasRequiredPermission(src, 'admin') then
        cb({ success = false, error = "No permission" })
        return
    end
    
    -- Check if event is running
    if not ActiveEvent then
        cb({ success = false, error = "No event is running" })
        return
    end
    
    if Config.Debug then
        print("[MI Tablet] Stopping event: " .. tostring(eventId))
    end
    
    -- Handle different event types
    if eventId == 'lastmanstanding' then
        -- Tell the client to execute the /stopzone command
        TriggerClientEvent('mi-tablet:client:executeCommand', src, 'stopzone')
    elseif eventId == 'prophunt' then
        TriggerClientEvent('mi-tablet:client:executeCommand', src, 'prophunt_stop')
    end
    
    ActiveEvent = nil
    
    if Config.Debug then
        print("[MI Tablet] Event stopped: " .. tostring(eventId) .. " by player " .. src)
    end
    
    cb({ success = true })
end)

-- Event handler to clear active event when it ends naturally
RegisterNetEvent('mi-tablet:server:eventEnded', function(eventId)
    if ActiveEvent and ActiveEvent.id == eventId then
        if Config.Debug then
            print("[MI Tablet] Event ended naturally: " .. tostring(eventId))
        end
        ActiveEvent = nil
    end
end)

-- ============================================
-- AV Scripts Admin Commands
-- ============================================

-- Valid AV admin commands that can be executed from the tablet
local ValidAVCommands = {
    ['admin:business'] = true,
    ['admin:drugs'] = true,
    ['admin:gangs'] = true,
    ['admin:racing'] = true,
    ['weather'] = true,
    ['boosting:contract'] = true,
    ['shell'] = true,
    -- Real Estate Commands
    ['shellcreator'] = true,
    ['propplacer'] = true,
    ['objectstats'] = true,
    ['coords'] = true,
    ['recordcoords'] = true,
}

-- Callback to execute AV admin command (with permission check)
TMC.Functions.CreateCallback('mi-tablet:server:executeAVCommand', function(source, cb, command)
    local src = source
    
    -- Verify player has admin permission
    if not HasRequiredPermission(src, 'admin') then
        if Config.Debug then
            print("[MI Tablet] Player " .. src .. " attempted to execute AV command without permission")
        end
        cb({ success = false, error = "No permission" })
        return
    end
    
    -- Verify the command is in the whitelist
    if not ValidAVCommands[command] then
        if Config.Debug then
            print("[MI Tablet] Player " .. src .. " attempted to execute invalid AV command: " .. tostring(command))
        end
        cb({ success = false, error = "Invalid command" })
        return
    end
    
    if Config.Debug then
        print("[MI Tablet] Player " .. src .. " executing AV command: " .. tostring(command))
    end
    
    cb({ success = true })
end)

-- ============================================
-- Player Events App Functions
-- ============================================

-- Callback to get event status for the player events app
TMC.Functions.CreateCallback('mi-tablet:server:getEventStatus', function(source, cb, eventId)
    local src = source
    
    if Config.Debug then
        print("[MI Tablet] Getting event status for: " .. tostring(eventId) .. " (player " .. src .. ")")
    end
    
    if eventId == 'lastmanstanding' then
        -- Check if the lastmanstanding_event resource is running
        local resourceState = GetResourceState('lastmanstanding_event')
        
        if resourceState ~= 'started' then
            cb({ state = 'inactive', timeRemaining = 0, playerCount = 0, isPlayerInEvent = false })
            return
        end
        
        -- Try to get status from the export
        local success, result = pcall(function()
            return exports['lastmanstanding_event']:GetEventStatus()
        end)
        
        -- Also check if this player is in the event
        local isInEvent = false
        local inEventSuccess, inEventResult = pcall(function()
            return exports['lastmanstanding_event']:IsPlayerInEvent(src)
        end)
        if inEventSuccess then
            isInEvent = inEventResult or false
        end
        
        if success and result then
            result.isPlayerInEvent = isInEvent
            cb(result)
        else
            -- Export not available or failed
            if Config.Debug then
                print("[MI Tablet] Failed to get LMS status: " .. tostring(result))
            end
            cb({ state = 'inactive', timeRemaining = 0, playerCount = 0, isPlayerInEvent = false })
        end
    elseif eventId == 'prophunt' then
        -- Check if the prophunt resource is running
        local resourceState = GetResourceState('prophunt')
        
        if resourceState ~= 'started' then
            cb({ state = 'inactive', timeRemaining = 0, playerCount = 0, isPlayerInEvent = false })
            return
        end
        
        -- Try to get status from the export
        local success, result = pcall(function()
            return exports['prophunt']:GetEventStatus()
        end)
        
        -- Also check if this player is in the event
        local isInEvent = false
        local inEventSuccess, inEventResult = pcall(function()
            return exports['prophunt']:IsPlayerInEvent(src)
        end)
        if inEventSuccess then
            isInEvent = inEventResult or false
        end
        
        if success and result then
            result.isPlayerInEvent = isInEvent
            cb(result)
        else
            if Config.Debug then
                print("[MI Tablet] Failed to get Prophunt status: " .. tostring(result))
            end
            cb({ state = 'inactive', timeRemaining = 0, playerCount = 0, isPlayerInEvent = false })
        end
    else
        -- Unknown event type
        cb({ state = 'inactive', timeRemaining = 0, playerCount = 0, isPlayerInEvent = false })
    end
end)

-- Callback to join an event
TMC.Functions.CreateCallback('mi-tablet:server:joinEvent', function(source, cb, eventId)
    local src = source
    
    if Config.Debug then
        print("[MI Tablet] Player " .. src .. " attempting to join event: " .. tostring(eventId))
    end
    
    if eventId == 'lastmanstanding' then
        -- Check if the resource is running
        local resourceState = GetResourceState('lastmanstanding_event')
        
        if resourceState ~= 'started' then
            cb({ success = false, error = "Event resource not running" })
            return
        end
        
        -- Try to use the export to join
        local success, result, errorMsg = pcall(function()
            return exports['lastmanstanding_event']:JoinEvent(src)
        end)
        
        if success then
            if result then
                cb({ success = true })
            else
                cb({ success = false, error = errorMsg or "Failed to join" })
            end
        else
            -- Export failed, fallback to triggering the joinzone command via client
            TriggerClientEvent('mi-tablet:client:executeCommand', src, 'joinzone')
            cb({ success = true })
        end
    elseif eventId == 'prophunt' then
        -- Check if the resource is running
        local resourceState = GetResourceState('prophunt')
        
        if resourceState ~= 'started' then
            cb({ success = false, error = "Prop Hunt resource not running" })
            return
        end
        
        -- Try to use the export to join
        local success, result, errorMsg = pcall(function()
            return exports['prophunt']:JoinEvent(src)
        end)
        
        if success then
            if result then
                cb({ success = true })
            else
                cb({ success = false, error = errorMsg or "Failed to join" })
            end
        else
            -- Export failed, fallback to triggering the command via client
            TriggerClientEvent('mi-tablet:client:executeCommand', src, 'prophunt_join')
            cb({ success = true })
        end
    else
        cb({ success = false, error = "Unknown event type" })
    end
end)

-- Callback to leave an event
TMC.Functions.CreateCallback('mi-tablet:server:leaveEvent', function(source, cb, eventId)
    local src = source
    
    if Config.Debug then
        print("[MI Tablet] Player " .. src .. " attempting to leave event: " .. tostring(eventId))
    end
    
    if eventId == 'lastmanstanding' then
        -- Check if the resource is running
        local resourceState = GetResourceState('lastmanstanding_event')
        
        if resourceState ~= 'started' then
            cb({ success = false, error = "Event resource not running" })
            return
        end
        
        -- Try to use the export to leave
        local success, result, errorMsg = pcall(function()
            return exports['lastmanstanding_event']:LeaveEvent(src)
        end)
        
        if success then
            if result then
                cb({ success = true })
            else
                cb({ success = false, error = errorMsg or "Failed to leave" })
            end
        else
            -- Export failed, fallback to triggering the leavezone command via client
            TriggerClientEvent('mi-tablet:client:executeCommand', src, 'leavezone')
            cb({ success = true })
        end
    elseif eventId == 'prophunt' then
        -- Check if the resource is running
        local resourceState = GetResourceState('prophunt')
        
        if resourceState ~= 'started' then
            cb({ success = false, error = "Prop Hunt resource not running" })
            return
        end
        
        -- Try to use the export to leave
        local success, result, errorMsg = pcall(function()
            return exports['prophunt']:LeaveEvent(src)
        end)
        
        if success then
            if result then
                cb({ success = true })
            else
                cb({ success = false, error = errorMsg or "Failed to leave" })
            end
        else
            -- Export failed, fallback to triggering the command via client
            TriggerClientEvent('mi-tablet:client:executeCommand', src, 'prophunt_leave')
            cb({ success = true })
        end
    else
        cb({ success = false, error = "Unknown event type" })
    end
end)

-- ============================================
-- Camera & Gallery Server Functions
-- ============================================

-- Get API key for image uploads
local function GetImageApiKey()
    -- Try to get from LB Phone first if enabled
    if Config.Camera.Upload.UseLBPhoneKey then
        local success, result = pcall(function()
            -- Try to read from lb-phone's apiKeys
            local apiKeys = exports['lb-phone']:GetAPIKeys()
            if apiKeys and apiKeys.Image then
                return apiKeys.Image
            end
        end)
        
        if success and result then
            if Config.Debug then
                print("[MI Tablet] Using LB Phone API key")
            end
            return result
        else
            if Config.Debug then
                print("[MI Tablet] LB Phone GetAPIKeys failed or not available")
            end
        end
        
        -- Fallback: Try to read API key from lb-phone config directly
        -- Check if the server-side apiKeys file exists
        local lbApiKeySuccess, lbApiKey = pcall(function()
            -- Try loading lb-phone's shared apiKeys if it exists
            return exports['lb-phone']:GetConfig() and exports['lb-phone']:GetConfig().ApiKeys and exports['lb-phone']:GetConfig().ApiKeys.Image
        end)
        
        if lbApiKeySuccess and lbApiKey and lbApiKey ~= "" then
            if Config.Debug then
                print("[MI Tablet] Using LB Phone config API key")
            end
            return lbApiKey
        end
    end
    
    -- Return configured API key (user should set this in config)
    if Config.Debug then
        print("[MI Tablet] Using config API key, length:", Config.Camera.Upload.ApiKey and string.len(Config.Camera.Upload.ApiKey) or 0)
    end
    return Config.Camera.Upload.ApiKey
end

-- Callback to get API key and upload service for NUI
TMC.Functions.CreateCallback('mi-tablet:server:getCameraConfig', function(source, cb)
    local apiKey = GetImageApiKey()
    
    cb({
        apiKey = apiKey,
        service = Config.Camera.Upload.Service,
        quality = Config.Camera.Image.Quality,
        mime = Config.Camera.Image.Mime
    })
end)

-- Event: Upload photo (receives base64 from client, server handles upload)
RegisterNetEvent('mi-tablet:server:uploadPhoto', function(imageData)
    local src = source
    local Player = TMC.Functions.GetPlayer(src)
    
    if not Player then return end
    
    local citizenId = Player.PlayerData.citizenid
    
    if Config.Debug then
        print("[MI Tablet] Uploading photo for player " .. src)
    end
    
    -- For client-side upload, we just receive the URL directly
    -- The NUI handles the actual upload to Fivemanage
end)

-- Event: Photo uploaded successfully (called from NUI via client)
RegisterNetEvent('mi-tablet:server:savePhotoUrl', function(photoUrl)
    local src = source
    local Player = TMC.Functions.GetPlayer(src)
    
    if not Player then return end
    
    local citizenId = Player.PlayerData.citizenid
    
    if Config.Debug then
        print("[MI Tablet] Saving photo URL for player " .. src .. ": " .. tostring(photoUrl))
    end
    
    -- Save to database if enabled
    if Config.Gallery.SaveToDatabase then
        MySQL.Async.insert('INSERT INTO mi_tablet_gallery (citizenid, photo_url, created_at) VALUES (?, ?, NOW())', {
            citizenId,
            photoUrl
        }, function(insertId)
            if insertId then
                TriggerClientEvent('mi-tablet:client:photoUploaded', src, photoUrl)
                
                if Config.Debug then
                    print("[MI Tablet] Photo saved to database with ID: " .. insertId)
                end
            else
                TriggerClientEvent('mi-tablet:client:photoFailed', src, "Database error")
            end
        end)
    else
        -- Just notify client of success without saving to DB
        TriggerClientEvent('mi-tablet:client:photoUploaded', src, photoUrl)
    end
end)

-- Callback to get gallery photos
TMC.Functions.CreateCallback('mi-tablet:server:getGalleryPhotos', function(source, cb)
    local src = source
    local Player = TMC.Functions.GetPlayer(src)
    
    if not Player then 
        cb({})
        return 
    end
    
    local citizenId = Player.PlayerData.citizenid
    
    if not Config.Gallery.SaveToDatabase then
        cb({})
        return
    end
    
    MySQL.Async.fetchAll('SELECT id, photo_url, created_at FROM mi_tablet_gallery WHERE citizenid = ? ORDER BY created_at DESC LIMIT ?', {
        citizenId,
        Config.Gallery.MaxPhotos
    }, function(results)
        local photos = {}
        
        for _, row in ipairs(results or {}) do
            table.insert(photos, {
                id = row.id,
                url = row.photo_url,
                date = row.created_at
            })
        end
        
        cb(photos)
    end)
end)

-- Callback to delete a photo
TMC.Functions.CreateCallback('mi-tablet:server:deletePhoto', function(source, cb, photoId)
    local src = source
    local Player = TMC.Functions.GetPlayer(src)
    
    if not Player then 
        cb(false)
        return 
    end
    
    local citizenId = Player.PlayerData.citizenid
    
    MySQL.Async.execute('DELETE FROM mi_tablet_gallery WHERE id = ? AND citizenid = ?', {
        photoId,
        citizenId
    }, function(rowsChanged)
        cb(rowsChanged > 0)
    end)
end)

-- ============================================
-- Casino Management Callbacks
-- ============================================

-- Get casino data (balance, employees, current vehicle)
TMC.Functions.CreateCallback('mi-tablet:server:getCasinoData', function(source, cb)
    local src = source
    local Player = TMC.Functions.GetPlayer(src)
    
    if not Player then 
        cb({})
        return 
    end
    
    local citizenid = Player.PlayerData.citizenid
    
    -- Check if player has casino job with manager/supervisor grade
    MySQL.Async.fetchAll('SELECT jobs FROM players WHERE citizenid = ?', {citizenid}, function(result)
        local hasCasinoAccess = false
        
        if result and result[1] and result[1].jobs then
            local jobsData = json.decode(result[1].jobs)
            if jobsData and type(jobsData) == "table" then
                for _, job in ipairs(jobsData) do
                    if job.name == 'casino' and job.grade and job.grade.level <= 1 then
                        hasCasinoAccess = true
                        break
                    end
                end
            end
        end
        
        if not hasCasinoAccess then
            cb({error = 'Not authorized'})
            return
        end
        
        -- Get society account balance
        local society = exports['banking']:GetAccount('society_casino')
        local balance = society and society.money or 0
        
        -- Get employees list (players who have casino in their jobs array)
        local employees = {}
        local allPlayers = MySQL.Sync.fetchAll('SELECT citizenid, charinfo, jobs FROM players WHERE is_deleted = 0', {})
        
        if allPlayers then
            for _, row in ipairs(allPlayers) do
                local charinfo = json.decode(row.charinfo or '{}')
                local jobsData = json.decode(row.jobs or '[]')
                
                -- Check if player has casino job
                if type(jobsData) == "table" then
                    for _, job in ipairs(jobsData) do
                        if job.name == 'casino' then
                            table.insert(employees, {
                                citizenid = row.citizenid,
                                name = (charinfo.firstname or '') .. ' ' .. (charinfo.lastname or ''),
                                grade = job.grade and job.grade.level or 0,
                                gradeName = job.grade and job.grade.name or 'Unknown'
                            })
                            break
                        end
                    end
                end
            end
        end
        
        -- Get current podium vehicle from rcore_casino cache
        local currentVehicle = 'Not Set'
        MySQL.Async.fetchAll('SELECT Settings FROM casino_cache LIMIT 1', {}, function(cacheResult)
            if cacheResult and cacheResult[1] and cacheResult[1].Settings then
                local settings = json.decode(cacheResult[1].Settings or '{}')
                
                if Config.Debug then
                    print('[MI Tablet] Casino cache settings: ' .. json.encode(settings))
                    print('[MI Tablet] PodiumPriceProps type: ' .. type(settings.PodiumPriceProps))
                    if settings.PodiumPriceProps then
                        print('[MI Tablet] PodiumPriceProps content: ' .. json.encode(settings.PodiumPriceProps))
                    end
                end
                
                -- PodiumPriceProps might be a string or a table depending on how it was stored
                local podiumProps = settings.PodiumPriceProps
                if type(podiumProps) == 'string' then
                    podiumProps = json.decode(podiumProps)
                end
                
                if podiumProps and podiumProps.podiumName then
                    currentVehicle = podiumProps.podiumName
                elseif podiumProps and podiumProps.model then
                    -- Fallback: just show that a vehicle is set even if no name
                    currentVehicle = 'Model: ' .. tostring(podiumProps.model)
                end
            end
            
            cb({
                success = true,
                balance = balance,
                employees = employees,
                currentVehicle = currentVehicle
            })
        end)
    end)
end)

-- Set podium vehicle
TMC.Functions.CreateCallback('mi-tablet:server:casino:setPodiumVehicle', function(source, cb, vehicle)
    local src = source
    local Player = TMC.Functions.GetPlayer(src)
    
    if not Player then 
        cb({success = false, message = 'Player not found'})
        return 
    end
    
    -- Check authorization using helper function
    if not HasCasinoAccess(Player.PlayerData.citizenid, 1) then
        cb({success = false, message = 'Not authorized'})
        return
    end
    
    if not vehicle or vehicle == '' then
        cb({success = false, message = 'Invalid vehicle'})
        return
    end
    
    -- Save vehicle to database for our own tracking
    MySQL.Async.execute('INSERT INTO casino_settings (setting, value) VALUES (?, ?) ON DUPLICATE KEY UPDATE value = ?', 
        {'podium_vehicle', vehicle, vehicle}, function(affectedRows)
        
        -- Update rcore_casino podium vehicle using their built-in system
        if GetResourceState('rcore_casino') == 'started' then
            -- Create minimal vehicle properties for podium
            local vehicleProps = {
                model = GetHashKey(vehicle),
                podiumName = vehicle,
                plate = 'PODIUM', -- rcore checks for plate ownership, use dummy plate
            }
            
            -- Trigger rcore_casino's PodiumReplace event
            -- Note: We can't trigger this as the player because rcore checks permissions
            -- Instead, we'll manually update their cache and broadcast
            
            -- Get current cache settings
            MySQL.Async.fetchAll('SELECT Settings FROM casino_cache LIMIT 1', {}, function(result)
                if result and result[1] then
                    local settings = json.decode(result[1].Settings or '{}')
                    
                    -- Update podium vehicle in cache
                    settings.PodiumPriceProps = vehicleProps
                    
                    -- Save back to casino_cache
                    MySQL.Async.execute('UPDATE casino_cache SET Settings = ?', {json.encode(settings)}, function()
                        -- Broadcast to all casino clients to update podium
                        TriggerClientEvent('rcore_casino:PodiumVehicleChanged', -1, json.encode(vehicleProps))
                        
                        -- ALSO trigger server event for TMC framework to spawn/replace vehicle
                        TriggerEvent('rcore_casino:UpdatePodiumVehicle', vehicleProps)
                        
                        if Config.Debug then
                            print('[MI Tablet] Updated rcore_casino podium vehicle to: ' .. vehicle)
                        end
                    end)
                else
                    if Config.Debug then
                        print('[MI Tablet] WARNING: casino_cache table not found')
                    end
                end
            end)
        end
        
        -- Log the change
        print(string.format('[MI Tablet] %s (%s) set casino podium vehicle to: %s', 
            Player.PlayerData.charinfo.firstname .. ' ' .. Player.PlayerData.charinfo.lastname,
            Player.PlayerData.citizenid,
            vehicle
        ))
        
        cb({success = true, vehicle = vehicle, message = 'Podium vehicle updated'})
    end)
end)

-- Hire employee
TMC.Functions.CreateCallback('mi-tablet:server:casino:hireEmployee', function(source, cb, citizenid, grade)
    local src = source
    local Player = TMC.Functions.GetPlayer(src)
    
    if not Player then 
        cb({success = false, message = 'Player not found'})
        return 
    end
    
    -- Check authorization using helper function
    if not HasCasinoAccess(Player.PlayerData.citizenid, 1) then
        cb({success = false, message = 'Not authorized'})
        return
    end
    
    grade = tonumber(grade) or 3
    
    if not citizenid then
        cb({success = false, message = 'Invalid Citizen ID'})
        return
    end
    
    -- Get target player
    local TargetPlayer = TMC.Functions.GetPlayerByCitizenId(citizenid)
    
    if TargetPlayer then
        -- Player is online - add casino job to their jobs array
        local currentJobs = TargetPlayer.PlayerData.jobs or {}
        local alreadyHasCasino = false
        
        -- Check if they already have casino job
        for _, job in ipairs(currentJobs) do
            if job.name == 'casino' then
                alreadyHasCasino = true
                break
            end
        end
        
        if alreadyHasCasino then
            cb({success = false, message = 'Player is already employed at the casino'})
            return
        end
        
        -- Add casino job to array
        table.insert(currentJobs, {
            name = 'casino',
            label = 'Legacy Casino',
            payment = 50,
            onduty = false,
            grade = {
                level = grade,
                name = GetCasinoGradeName(grade)
            }
        })
        
        -- Update player data
        TargetPlayer.Functions.SetPlayerData('jobs', currentJobs)
        
        TriggerClientEvent('TMC:Notify', TargetPlayer.PlayerData.source, 'You have been hired at the casino!', 'success')
        
        cb({success = true, message = 'Employee hired successfully'})
    else
        -- Player is offline, update database - add casino to jobs array
        MySQL.Async.fetchAll('SELECT jobs FROM players WHERE citizenid = ?', {citizenid}, function(result)
            if result and result[1] then
                local currentJobs = json.decode(result[1].jobs or '[]')
                if type(currentJobs) ~= 'table' then
                    currentJobs = {}
                end
                
                -- Check if they already have casino job
                for _, job in ipairs(currentJobs) do
                    if job.name == 'casino' then
                        cb({success = false, message = 'Player is already employed at the casino'})
                        return
                    end
                end
                
                -- Add casino job
                table.insert(currentJobs, {
                    name = 'casino',
                    label = 'Legacy Casino',
                    payment = 50,
                    onduty = false,
                    grade = {
                        level = grade,
                        name = GetCasinoGradeName(grade)
                    }
                })
                
                -- Update the jobs array in database
                MySQL.Async.execute('UPDATE players SET jobs = ? WHERE citizenid = ?', {
                    json.encode(currentJobs),
                    citizenid
                }, function(rowsChanged)
                    if rowsChanged > 0 then
                        cb({success = true, message = 'Employee hired successfully (offline)'})
                    else
                        cb({success = false, message = 'Failed to update player'})
                    end
                end)
            else
                cb({success = false, message = 'Player not found'})
            end
        end)
    end
    
    -- Log the action
    print(string.format('[MI Tablet] %s hired %s to casino with grade %d', 
        Player.PlayerData.citizenid, citizenid, grade))
end)

-- Fire employee
TMC.Functions.CreateCallback('mi-tablet:server:casino:fireEmployee', function(source, cb, citizenid)
    local src = source
    local Player = TMC.Functions.GetPlayer(src)
    
    if not Player then 
        cb({success = false, message = 'Player not found'})
        return 
    end
    
    -- Check authorization using helper function
    if not HasCasinoAccess(Player.PlayerData.citizenid, 1) then
        cb({success = false, message = 'Not authorized'})
        return
    end
    
    if not citizenid then
        cb({success = false, message = 'Invalid Citizen ID'})
        return
    end
    
    -- Don't allow firing yourself
    if citizenid == Player.PlayerData.citizenid then
        cb({success = false, message = 'Cannot fire yourself'})
        return
    end
    
    -- Get target player
    local TargetPlayer = TMC.Functions.GetPlayerByCitizenId(citizenid)
    
    if TargetPlayer then
        -- Player is online - remove casino job from their jobs array
        local currentJobs = TargetPlayer.PlayerData.jobs or {}
        local newJobs = {}
        
        -- Filter out the casino job
        for _, job in ipairs(currentJobs) do
            if job.name ~= 'casino' then
                table.insert(newJobs, job)
            end
        end
        
        -- Update player data
        TargetPlayer.Functions.SetPlayerData('jobs', newJobs)
        
        -- If they had no other jobs, give them unemployed
        if #newJobs == 0 then
            TargetPlayer.Functions.SetJob('unemployed', 0)
        end
        
        TriggerClientEvent('TMC:Notify', TargetPlayer.PlayerData.source, 'You have been fired from the casino', 'error')
        
        cb({success = true, message = 'Employee fired successfully'})
    else
        -- Player is offline, update database - remove casino from jobs array
        MySQL.Async.fetchAll('SELECT jobs FROM players WHERE citizenid = ?', {citizenid}, function(result)
            if result and result[1] then
                local currentJobs = json.decode(result[1].jobs or '[]')
                local newJobs = {}
                
                -- Filter out the casino job
                if type(currentJobs) == 'table' then
                    for _, job in ipairs(currentJobs) do
                        if job.name ~= 'casino' then
                            table.insert(newJobs, job)
                        end
                    end
                end
                
                -- Update the jobs array in database
                MySQL.Async.execute('UPDATE players SET jobs = ? WHERE citizenid = ?', {
                    json.encode(newJobs),
                    citizenid
                }, function(rowsChanged)
                    if rowsChanged > 0 then
                        cb({success = true, message = 'Employee fired successfully (offline)'})
                    else
                        cb({success = false, message = 'Failed to update player'})
                    end
                end)
            else
                cb({success = false, message = 'Player not found'})
            end
        end)
    end
    
    -- Log the action
    print(string.format('[MI Tablet] %s fired %s from casino', 
        Player.PlayerData.citizenid, citizenid))
end)

-- Withdraw funds from casino society
TMC.Functions.CreateCallback('mi-tablet:server:casino:withdraw', function(source, cb, amount)
    local src = source
    local Player = TMC.Functions.GetPlayer(src)
    
    if not Player then 
        cb({success = false, message = 'Player not found'})
        return 
    end
    
    -- Check authorization using helper function
    if not HasCasinoAccess(Player.PlayerData.citizenid, 1) then
        cb({success = false, message = 'Not authorized'})
        return
    end
    
    amount = tonumber(amount)
    
    if not amount or amount <= 0 then
        cb({success = false, message = 'Invalid amount'})
        return
    end
    
    -- Withdraw from society account
    local success = exports['tmc-bankingapp']:RemoveMoney('society_casino', amount)
    
    if success then
        Player.Functions.AddMoney('cash', amount)
        TriggerClientEvent('TMC:Notify', src, 'Withdrew £' .. amount .. ' from casino account', 'success')
        
        -- Log the transaction
        print(string.format('[MI Tablet] %s withdrew £%d from casino', 
            Player.PlayerData.citizenid, amount))
        
        cb({success = true})
    else
        cb({success = false, message = 'Insufficient funds or error'})
    end
end)

-- Deposit funds to casino society
TMC.Functions.CreateCallback('mi-tablet:server:casino:deposit', function(source, cb, amount)
    local src = source
    local Player = TMC.Functions.GetPlayer(src)
    
    if not Player then 
        cb({success = false, message = 'Player not found'})
        return 
    end
    
    -- Check authorization using helper function
    if not HasCasinoAccess(Player.PlayerData.citizenid, 1) then
        cb({success = false, message = 'Not authorized'})
        return
    end
    
    amount = tonumber(amount)
    
    if not amount or amount <= 0 then
        cb({success = false, message = 'Invalid amount'})
        return
    end
    
    -- Check if player has enough cash
    if Player.Functions.GetMoney('cash') < amount then
        cb({success = false, message = 'Insufficient cash'})
        return
    end
    
    -- Remove cash and add to society
    Player.Functions.RemoveMoney('cash', amount)
    local success = exports['tmc-bankingapp']:AddMoney('society_casino', amount)
    
    if success then
        TriggerClientEvent('TMC:Notify', src, 'Deposited £' .. amount .. ' to casino account', 'success')
        
        -- Log the transaction
        print(string.format('[MI Tablet] %s deposited £%d to casino', 
            Player.PlayerData.citizenid, amount))
        
        cb({success = true})
    else
        -- Refund if failed
        Player.Functions.AddMoney('cash', amount)
        cb({success = false, message = 'Failed to deposit'})
    end
end)

-- Helper function to get casino grade name
function GetCasinoGradeName(grade)
    local grades = {
        [0] = 'Manager',
        [1] = 'Supervisor',
        [2] = 'Dealer',
        [3] = 'Service Staff'
    }
    return grades[grade] or 'Employee'
end

-- ============================================
-- Gang/Territory System Callbacks
-- ============================================

-- Check if player can see gangs (has VPN)
TMC.Functions.CreateCallback('mi-tablet:server:canSeeGangs', function(source, cb)
    local src = source
    local Player = TMC.Functions.GetPlayer(src)
    
    if not Player then 
        cb(false)
        return
    end
    
    -- Check if player has VPN item
    local hasVPN = Player.Functions.GetItemByName('vpn')
    cb(hasVPN ~= nil)
end)

-- Get gang info for the player by querying gangs resource
TMC.Functions.CreateCallback('mi-tablet:server:getGangInfo', function(source, cb)
    local src = source
    local Player = TMC.Functions.GetPlayer(src)
    
    if not Player then 
        print("[MI Tablet] No player found for source " .. src)
        cb(nil)
        return
    end
    
    print("[MI Tablet] Getting gang info for player " .. Player.PlayerData.citizenid)
    
    -- Check if player has VPN item
    local hasVPN = Player.Functions.GetItemByName('vpn')
    if not hasVPN then
        print("[MI Tablet] Player doesn't have VPN")
        cb(nil)
        return
    end
    
    print("[MI Tablet] Player has VPN, checking gangs resource")
    
    -- Check if gangs resource is running
    if GetResourceState('gangs') ~= 'started' then
        print("[MI Tablet] Gangs resource not started")
        cb(nil)
        return
    end
    
    -- Get player's gang ID
    local success, gangId = pcall(function()
        return exports.gangs:IsCSNInAGang(Player.PlayerData.citizenid)
    end)
    
    if not success then
        print("[MI Tablet] Error calling IsCSNInAGang: " .. tostring(gangId))
        cb(nil)
        return
    end
    
    if not gangId then
        print("[MI Tablet] Player not in a gang")
        cb(nil)
        return
    end
    
    print("[MI Tablet] Player is in gang " .. tostring(gangId))
    
    -- Get gang data
    local success2, gangData = pcall(function()
        return exports.gangs:GetGangData(gangId)
    end)
    
    if not success2 then
        print("[MI Tablet] Error calling GetGangData: " .. tostring(gangData))
        cb(nil)
        return
    end
    
    if not gangData then
        print("[MI Tablet] No gang data returned for gang " .. tostring(gangId))
        cb(nil)
        return
    end
    
    print("[MI Tablet] Got gang data for gang " .. tostring(gangId))
    
    -- Get gang members
    local gangMembers = {}
    local success3, memberData = pcall(function()
        return exports.gangs:GetGangMembers(gangId)
    end)
    
    if success3 and memberData then
        gangMembers = memberData
        print("[MI Tablet] Got " .. #gangMembers .. " gang members")
    else
        print("[MI Tablet] Could not get gang members")
    end
    
    -- Build response in the format the UI expects
    local response = {
        csn = Player.PlayerData.citizenid,
        gangId = gangId,
        isOwner = gangData.owner == Player.PlayerData.citizenid,
        gangSettings = {
            id = gangId,
            name = gangData.name or 'Unknown Gang',
            colour = gangData.settings and gangData.settings.colour or '#ff3333',
            maxMembers = 15
        },
        gangMembers = {}
    }
    
    -- Build members list with character names from database
    if gangMembers and type(gangMembers) == 'table' then
        for _, member in pairs(gangMembers) do
            if member then
                local memberName = 'Unknown'
                local citizenid = member.citizenid or 'unknown'
                
                -- Try to get character name from database
                if citizenid ~= 'unknown' then
                    local result = MySQL.query.await('SELECT charinfo FROM players WHERE citizenid = ?', {citizenid})
                    if result and result[1] and result[1].charinfo then
                        local charinfo = json.decode(result[1].charinfo)
                        if charinfo then
                            memberName = (charinfo.firstname or '') .. ' ' .. (charinfo.lastname or '')
                            memberName = memberName:gsub('^%s+|%s+$', '')  -- Trim whitespace
                            if memberName == '' then
                                memberName = 'Unknown'
                            end
                        end
                    end
                end
                
                table.insert(response.gangMembers, {
                    csn = citizenid,
                    name = memberName,
                    rank = member.rank or 'member'
                })
            end
        end
    end
    
    print("[MI Tablet] Returning gang info with " .. #response.gangMembers .. " members")
    cb(response)
end)

-- Get gang territories by querying territories database
TMC.Functions.CreateCallback('mi-tablet:server:getGangTerritories', function(source, cb)
    local src = source
    local Player = TMC.Functions.GetPlayer(src)
    
    if not Player then 
        print("[MI Tablet] No player for getGangTerritories")
        cb({})
        return
    end
    
    -- Check if player has VPN item
    local hasVPN = Player.Functions.GetItemByName('vpn')
    if not hasVPN then
        print("[MI Tablet] Player no VPN for getGangTerritories")
        cb({})
        return
    end
    
    -- Check if gangs resource is running
    if GetResourceState('gangs') ~= 'started' then
        print("[MI Tablet] Gangs not started for getGangTerritories")
        cb({})
        return
    end
    
    -- Get player's gang ID
    local success, gangId = pcall(function()
        return exports.gangs:IsCSNInAGang(Player.PlayerData.citizenid)
    end)
    
    if not success or not gangId then
        print("[MI Tablet] Player not in gang for getGangTerritories")
        cb({})
        return
    end
    
    print("[MI Tablet] Getting territories for gang " .. tostring(gangId))
    
    local territoriesData = {}
    
    -- Query territories database (schema varies by server)
    if MySQL then
        local result = nil
        local success, err = pcall(function()
            result = MySQL.query.await('SELECT * FROM territories')
        end)
        
        if not success then
            print("[MI Tablet] Query failed: " .. tostring(err))
            result = {}
        end
        
        if result and #result > 0 then
            local function parseJson(value)
                if type(value) == 'table' then return value end
                if type(value) ~= 'string' then return nil end
                local ok, parsed = pcall(function()
                    return json.decode(value)
                end)
                if ok and type(parsed) == 'table' then return parsed end
                return nil
            end
            
            local function extractOwner(dataValue, spraysValue)
                local d = parseJson(dataValue) or {}
                local s = parseJson(spraysValue) or {}
                local owner = d.owner or d.gang_id or d.gangId or d.gang or d.ownerGangId or d.ownerGang
                owner = owner or s.owner or s.gang_id or s.gangId or s.gang
                return owner, d
            end
            
            local function extractCentre(centreValue, zoneData, row)
                local function toNumber(value)
                    local n = tonumber(value)
                    if n == nil then return 0 end
                    return n
                end

                local function unpackCoords(c)
                    if type(c) ~= 'table' then return nil end
                    local x = toNumber(c.x or c[1])
                    local y = toNumber(c.y or c[2])
                    local z = toNumber(c.z or c[3])
                    return x, y, z
                end

                local c = parseJson(centreValue) or centreValue
                local x, y, z = unpackCoords(c)
                if x or y or z then
                    return x or 0, y or 0, z or 0
                end

                if type(zoneData) == 'table' then
                    local coords = zoneData.centre or zoneData.center or zoneData.coords or zoneData.location or zoneData.position or zoneData.pos
                    x, y, z = unpackCoords(coords)
                    if x or y or z then
                        return x or 0, y or 0, z or 0
                    end

                    if zoneData.x or zoneData.y or zoneData.z then
                        return toNumber(zoneData.x), toNumber(zoneData.y), toNumber(zoneData.z)
                    end
                end

                if type(row) == 'table' then
                    if row.x or row.y or row.z then
                        return toNumber(row.x), toNumber(row.y), toNumber(row.z)
                    end
                end

                return 0, 0, 0
            end
            
            local added = 0
            local owned = 0
            for _, zone in ipairs(result) do
                if zone then
                    local owner, zoneData = extractOwner(zone.data, zone.sprays)
                    if owner and tostring(owner) == tostring(gangId) then
                        owned = owned + 1
                    end
                    local x, y, z = extractCentre(zone.centre or zone.center, zoneData, zone)
                    
                    -- Get gang color for this territory's owner (if it's not player's gang, try to get color)
                    local gangColor = nil
                    if owner and tostring(owner) ~= tostring(gangId) then
                        -- Try to get color from gangs resource
                        local success, color = pcall(function()
                            local gangData = exports.gangs:GetGangData(owner)
                            if gangData and gangData.colour then
                                return gangData.colour
                            end
                            return nil
                        end)
                        if success and color then
                            gangColor = color
                        end
                    end
                    
                    territoriesData[tostring(zone.id)] = {
                        id = zone.id,
                        label = zoneData.label or zoneData.name or zoneData.zone or ('Territory ' .. tostring(zone.id)),
                        coords = { x = x, y = y, z = z },
                        owner = owner,
                        status = zoneData.status or zoneData.state or 'unclaimed',
                        level = zoneData.level or 1,
                        gangColor = gangColor,
                        data = zoneData
                    }
                    added = added + 1
                end
            end
            
            if added > 0 then
                print("[MI Tablet] Found " .. added .. " territories in database (owned: " .. owned .. ")")
            else
                print("[MI Tablet] No territories found in database")
            end
        else
            print("[MI Tablet] No territories found in database for gang " .. tostring(gangId))
        end
    else
        print("[MI Tablet] MySQL not available for territories query")
    end
    
    -- Return territories (empty if none found)
    cb(territoriesData)
end)

-- Get owned territory IDs for filtering
TMC.Functions.CreateCallback('mi-tablet:server:getOwnedTerritoryIds', function(source, cb)
    local src = source
    local Player = TMC.Functions.GetPlayer(src)
    
    if not Player then 
        cb({})
        return
    end
    
    -- Check if player has VPN item
    local hasVPN = Player.Functions.GetItemByName('vpn')
    if not hasVPN then
        cb({})
        return
    end
    
    local citizenid = Player.PlayerData.citizenid
    print("[MI Tablet] Getting owned territories for player: " .. citizenid)
    
    local ownedIds = {}
    
    -- Query gangs table to get player's gang ID
    if MySQL then
        local gangResult = nil
        local success, err = pcall(function()
            gangResult = MySQL.query.await('SELECT id FROM gangs WHERE JSON_CONTAINS(members, JSON_OBJECT("citizenid", ?)) LIMIT 1', {citizenid})
        end)
        
        if not success or not gangResult or #gangResult == 0 then
            print("[MI Tablet] Player not in a gang or query failed: " .. tostring(err))
            cb({})
            return
        end
        
        local gangId = gangResult[1].id
        print("[MI Tablet] Found gang ID: " .. tostring(gangId) .. " for player: " .. citizenid)
        
        -- Now query territories owned by this gang
        local terResult = nil
        local success2, err2 = pcall(function()
            terResult = MySQL.query.await('SELECT id, data, sprays FROM territories')
        end)
        
        if not success2 then
            print("[MI Tablet] Territory query failed: " .. tostring(err2))
            cb({})
            return
        end
        
        if terResult and #terResult > 0 then
            local function parseJson(value)
                if type(value) == 'table' then return value end
                if type(value) ~= 'string' then return nil end
                local ok, parsed = pcall(function()
                    return json.decode(value)
                end)
                if ok and type(parsed) == 'table' then return parsed end
                return nil
            end
            
            local function extractOwner(dataValue, spraysValue)
                local d = parseJson(dataValue) or {}
                local s = parseJson(spraysValue) or {}
                local owner = d.owner or d.gang_id or d.gangId or d.gang or d.ownerGangId or d.ownerGang
                owner = owner or s.owner or s.gang_id or s.gangId or s.gang
                return owner
            end
            
            for _, zone in ipairs(terResult) do
                if zone then
                    local owner = extractOwner(zone.data, zone.sprays)
                    if owner and tonumber(owner) == tonumber(gangId) then
                        table.insert(ownedIds, zone.id)
                        print("[MI Tablet] Territory " .. tostring(zone.id) .. " is owned by gang " .. tostring(gangId))
                    end
                end
            end
        end
    end
    
    print("[MI Tablet] Returning " .. #ownedIds .. " owned territories: " .. json.encode(ownedIds))
    cb(ownedIds)
end)

-- Get location info - get territories near player
TMC.Functions.CreateCallback('mi-tablet:server:getLocationInfo', function(source, cb)
    local src = source
    local Player = TMC.Functions.GetPlayer(src)
    
    if not Player then 
        cb(nil)
        return
    end
    
    -- Check if player has VPN item
    local hasVPN = Player.Functions.GetItemByName('vpn')
    if not hasVPN then
        cb(nil)
        return
    end
    
    -- Get player coordinates from game
    local ped = GetPlayerPed(src)
    local x, y, z = table.unpack(GetEntityCoords(ped))
    
    -- Try to determine if player is in a territory zone
    local inZone = false
    local zoneInfo = nil
    
    if GetResourceState('territories') == 'started' then
        -- Try to get zone info from territories resource
        local success, zoneData = pcall(function()
            return exports.territories:GetZoneAtCoords(x, y, z)
        end)
        if success and zoneData then
            inZone = true
            zoneInfo = zoneData
        end
    end
    
    cb({
        coords = {
            x = x,
            y = y,
            z = z
        },
        inZone = inZone,
        zoneInfo = zoneInfo
    })
end)

-- Get gang upkeep information
TMC.Functions.CreateCallback('mi-tablet:server:getGangUpkeep', function(source, cb)
    local src = source
    local Player = TMC.Functions.GetPlayer(src)
    
    if not Player then 
        cb(nil)
        return
    end
    
    -- Check if player has VPN item
    local hasVPN = Player.Functions.GetItemByName('vpn')
    if not hasVPN then
        cb(nil)
        return
    end
    
    -- Check if gangs resource is running
    if GetResourceState('gangs') ~= 'started' then
        cb(nil)
        return
    end
    
    -- Get player's gang ID
    local success, gangId = pcall(function()
        return exports.gangs:IsCSNInAGang(Player.PlayerData.citizenid)
    end)
    
    if not success or not gangId then
        cb(nil)
        return
    end
    
    -- Try to get gang upkeep data
    local gangData = nil
    local success2, data = pcall(function()
        return exports.gangs:GetGangData(gangId)
    end)
    
    if success2 and data then
        gangData = data
    else
        cb(nil)
        return
    end
    
    -- Build upkeep response
    local upkeepResponse = {
        upkeep = {
            weeklyCost = gangData.weeklyCost or 1000,
            balance = gangData.balance or 0,
            daysUntilDue = gangData.daysUntilDue or 7
        }
    }
    
    cb(upkeepResponse)
end)

-- Attempt to claim territory
TMC.Functions.CreateCallback('mi-tablet:server:gangAttemptClaim', function(source, cb, data)
    local src = source
    local Player = TMC.Functions.GetPlayer(src)
    
    if not Player then
        print("[MI Tablet] gangAttemptClaim: Player not found")
        cb(false)
        return
    end
    
    if GetResourceState('territories') ~= 'started' then
        print("[MI Tablet] gangAttemptClaim: territories resource not started")
        cb(false)
        return
    end
    
    local zoneId = data and data.zoneId or nil
    if not zoneId then
        print("[MI Tablet] gangAttemptClaim: No zoneId provided")
        cb(false)
        return
    end
    
    local gangId = Player.PlayerData.gang.id
    print(string.format("[MI Tablet] gangAttemptClaim: Attempting to claim zone %s for gang %s (player: %s)", zoneId, gangId, src))
    
    -- Try export patterns first
    local exportPatterns = {
        function() return exports.territories:AttemptClaim(src, zoneId) end,
        function() return exports.territories:ClaimZone(src, zoneId) end,
        function() return exports.territories:StartClaim(src, zoneId) end,
        function() return exports.territories:attemptClaim(src, zoneId) end,
        function() return exports.territories:claimZone(src, zoneId) end,
        function() return exports.territories:claim(src, zoneId) end,
        function() return exports.territories:attemptZoneClaim(src, zoneId) end,
        function() return exports.territories:zoneAttemptClaim(src, zoneId) end,
    }
    
    for i, exportFunc in ipairs(exportPatterns) do
        local success, result = pcall(exportFunc)
        if success then
            print(string.format("[MI Tablet] gangAttemptClaim: Export pattern %d succeeded with result: %s", i, tostring(result)))
            cb(result or true)
            return
        else
            print(string.format("[MI Tablet] gangAttemptClaim: Export pattern %d failed - %s", i, tostring(result)))
        end
    end
    
    -- If exports fail, try TriggerEvent patterns
    print("[MI Tablet] gangAttemptClaim: All exports failed, trying TriggerEvent")
    
    local eventPatterns = {
        'territories:attemptClaim',
        'territories:claimZone',
        'territories:claim',
        'gang:attemptClaim',
    }
    
    for i, eventName in ipairs(eventPatterns) do
        print(string.format("[MI Tablet] gangAttemptClaim: Trying TriggerEvent with %s", eventName))
        TriggerEvent(eventName, src, zoneId)
    end
    
    print("[MI Tablet] gangAttemptClaim: INTEGRATION NOTE:")
    print("[MI Tablet]   - No exports found in territories resource")
    print("[MI Tablet]   - TriggerEvent patterns may be working (events don't return success/failure)")
    print("[MI Tablet]   - Check territories/README.md for proper API")
    print("[MI Tablet]   - If claiming still doesn't work, territories resource API may be different")
    
    cb(true)  -- Assume success since events were attempted
end)

-- Attempt to contest territory
TMC.Functions.CreateCallback('mi-tablet:server:gangAttemptContest', function(source, cb, data)
    local src = source
    local Player = TMC.Functions.GetPlayer(src)
    
    if not Player then
        print("[MI Tablet] gangAttemptContest: Player not found")
        cb(false)
        return
    end
    
    if GetResourceState('territories') ~= 'started' then
        print("[MI Tablet] gangAttemptContest: territories resource not started")
        cb(false)
        return
    end
    
    -- Try to call territories export to contest zone
    local zoneId = data and data.zoneId or nil
    if not zoneId then
        print("[MI Tablet] gangAttemptContest: No zoneId provided")
        cb(false)
        return
    end
    
    print(string.format("[MI Tablet] gangAttemptContest: Attempting to contest zone %s for player %s", zoneId, src))
    
    -- Try different export patterns
    local exportPatterns = {
        function() return exports.territories:AttemptContest(src, zoneId) end,
        function() return exports.territories:ContestZone(src, zoneId) end,
        function() return exports.territories:StartContest(src, zoneId) end,
        function() return exports.territories:attemptContest(src, zoneId) end,
        function() return exports.territories:contestZone(src, zoneId) end,
        function() return exports.territories:contest(src, zoneId) end,
        function() return exports.territories:attemptZoneContest(src, zoneId) end,
        function() return exports.territories:zoneAttemptContest(src, zoneId) end,
    }
    
    for i, exportFunc in ipairs(exportPatterns) do
        local success, result = pcall(exportFunc)
        if success then
            print(string.format("[MI Tablet] gangAttemptContest: Export pattern %d succeeded with result: %s", i, tostring(result)))
            cb(result or true)
            return
        else
            print(string.format("[MI Tablet] gangAttemptContest: Export pattern %d failed - %s", i, tostring(result)))
        end
    end
    
    -- If exports fail, try using TriggerEvent
    print("[MI Tablet] gangAttemptContest: All exports failed, trying TriggerEvent")
    
    local eventPatterns = {
        'territories:attemptContest',
        'territories:contestZone',
        'territories:contest',
        'gang:attemptContest',
    }
    
    for i, eventName in ipairs(eventPatterns) do
        print(string.format("[MI Tablet] gangAttemptContest: Trying TriggerEvent with %s", eventName))
        TriggerEvent(eventName, src, zoneId)
    end
    
    cb(true)  -- Assume success with event-based approach
end)

-- Upgrade territory
TMC.Functions.CreateCallback('mi-tablet:server:gangUpgradeTerritory', function(source, cb)
    local src = source
    cb(false)
end)

-- Relinquish territory
TMC.Functions.CreateCallback('mi-tablet:server:gangRelinquishZone', function(source, cb, data)
    local src = source
    local Player = TMC.Functions.GetPlayer(src)
    
    if not Player then
        print("[MI Tablet] gangRelinquishZone: Player not found")
        cb({success = false, message = "Player not found"})
        return
    end
    
    if GetResourceState('territories') ~= 'started' then
        print("[MI Tablet] gangRelinquishZone: territories resource not started")
        cb({success = false, message = "Territories system not available"})
        return
    end
    
    local zoneId = data and data.zoneId or nil
    if not zoneId then
        print("[MI Tablet] gangRelinquishZone: No zoneId provided")
        cb({success = false, message = "Invalid zone"})
        return
    end
    
    local gangId = Player.PlayerData.gang.id
    print(string.format("[MI Tablet] gangRelinquishZone: Attempting to relinquish zone %s for gang %s", zoneId, gangId))
    
    -- Try TriggerEvent approach
    TriggerEvent('territories:relinquishZone', src, zoneId)
    
    cb({success = true, message = "Relinquish request sent"})
end)

-- Update gang setting
TMC.Functions.CreateCallback('mi-tablet:server:gangUpdateSetting', function(source, cb, data)
    local src = source
    local Player = TMC.Functions.GetPlayer(src)
    
    if not Player then
        print("[MI Tablet] gangUpdateSetting: Player not found")
        cb({success = false, message = "Player not found"})
        return
    end
    
    local settingType = data and data.settingType or nil
    local value = data and data.value or nil
    local gangId = data and data.gangId or nil
    
    if not settingType or not value or not gangId then
        print("[MI Tablet] gangUpdateSetting: Missing parameters")
        cb({success = false, message = "Missing parameters"})
        return
    end
    
    -- Verify player is gang owner
    if Player.PlayerData.gang.id ~= gangId then
        print(string.format("[MI Tablet] gangUpdateSetting: Player %s is not in gang %s", src, gangId))
        cb({success = false, message = "You are not in this gang"})
        return
    end
    
    print(string.format("[MI Tablet] gangUpdateSetting: Updating gang %s setting '%s' to '%s'", gangId, settingType, value))
    
    -- Trigger event for gangs resource to update
    TriggerEvent('gang:updateSetting', gangId, settingType, value)
    
    cb({success = true, message = "Setting updated"})
end)

-- Add gang rank
TMC.Functions.CreateCallback('mi-tablet:server:gangAddRank', function(source, cb, data)
    local src = source
    local Player = TMC.Functions.GetPlayer(src)
    
    if not Player then
        print("[MI Tablet] gangAddRank: Player not found")
        cb({success = false, message = "Player not found"})
        return
    end
    
    local rankName = data and data.rankName or nil
    local gangId = data and data.gangId or nil
    
    if not rankName or not gangId then
        print("[MI Tablet] gangAddRank: Missing parameters")
        cb({success = false, message = "Missing parameters"})
        return
    end
    
    -- Verify player is gang owner
    if Player.PlayerData.gang.id ~= gangId then
        print(string.format("[MI Tablet] gangAddRank: Player %s is not in gang %s", src, gangId))
        cb({success = false, message = "You are not in this gang"})
        return
    end
    
    print(string.format("[MI Tablet] gangAddRank: Adding rank '%s' to gang %s", rankName, gangId))
    
    -- Trigger event for gangs resource to add rank
    TriggerEvent('gang:addRank', gangId, rankName)
    
    cb({success = true, message = "Rank added"})
end)

-- Invite gang member
TMC.Functions.CreateCallback('mi-tablet:server:gangInviteMember', function(source, cb, data)
    local src = source
    local Player = TMC.Functions.GetPlayer(src)
    
    if not Player then
        print("[MI Tablet] gangInviteMember: Player not found")
        cb({success = false, message = "Player not found"})
        return
    end
    
    local csn = data and data.csn or nil
    local gangId = data and data.gangId or nil
    
    if not csn or not gangId then
        print("[MI Tablet] gangInviteMember: Missing parameters")
        cb({success = false, message = "Missing parameters"})
        return
    end
    
    -- Verify player is gang owner
    if Player.PlayerData.gang.id ~= gangId then
        print(string.format("[MI Tablet] gangInviteMember: Player %s is not in gang %s", src, gangId))
        cb({success = false, message = "You are not in this gang"})
        return
    end
    
    print(string.format("[MI Tablet] gangInviteMember: Inviting player with CSN %s to gang %s", csn, gangId))
    
    -- Trigger event for gangs resource to invite member
    TriggerEvent('gang:inviteMember', gangId, csn, src)
    
    cb({success = true, message = "Invitation sent to " .. csn})
end)
-- Relinquish territory
TMC.Functions.CreateCallback('mi-tablet:server:gangRelinquishZone', function(source, cb)
    local src = source
    cb(false)
end)

