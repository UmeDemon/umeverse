-- MI Tablet Client Script
-- Handles NUI and prop/animation management

local TMC = exports['umeverse_core']:GetCoreObject()

local isTabletOpen = false
local tabletProp = nil
local playerData = nil

-- Debug print helper
local function debugPrint(...)
    if Config.Debug then
        print("[MI Tablet]", ...)
    end
end

-- Load animation dictionary
local function loadAnimDict(dict)
    while not HasAnimDictLoaded(dict) do
        RequestAnimDict(dict)
        Wait(5)
    end
end

-- Load model
local function loadModel(model)
    while not HasModelLoaded(model) do
        RequestModel(model)
        Wait(5)
    end
end

-- Create and attach prop to player
local function createTabletProp()
    local ped = PlayerPedId()
    local propModel = GetHashKey(Config.Prop.Model)
    
    loadModel(propModel)
    
    local coords = GetEntityCoords(ped)
    tabletProp = CreateObject(propModel, coords.x, coords.y, coords.z, true, true, false)
    
    local boneIndex = GetPedBoneIndex(ped, Config.Prop.Bone)
    AttachEntityToEntity(tabletProp, ped, boneIndex, 
        Config.Prop.Offset.x, Config.Prop.Offset.y, Config.Prop.Offset.z,
        Config.Prop.Rotation.x, Config.Prop.Rotation.y, Config.Prop.Rotation.z,
        true, true, false, true, 1, true)
    
    SetModelAsNoLongerNeeded(propModel)
    
    debugPrint("Prop created and attached")
end

-- Remove tablet prop
local function removeTabletProp()
    if tabletProp and DoesEntityExist(tabletProp) then
        DeleteObject(tabletProp)
        tabletProp = nil
        debugPrint("Prop removed")
    end
end

-- Play tablet animation
local function playTabletAnimation()
    local ped = PlayerPedId()
    loadAnimDict(Config.Animation.Dict)
    TaskPlayAnim(ped, Config.Animation.Dict, Config.Animation.Anim, 3.0, 3.0, -1, Config.Animation.Flag, 0, false, false, false)
    debugPrint("Animation started")
end

-- Stop tablet animation
local function stopTabletAnimation()
    local ped = PlayerPedId()
    StopAnimTask(ped, Config.Animation.Dict, Config.Animation.Anim, 1.0)
    debugPrint("Animation stopped")
end

-- Open the tablet
local function openTablet()
    if isTabletOpen then return end
    
    isTabletOpen = true
    
    -- Request player data from server
    TriggerServerEvent('mi-tablet:server:getPlayerData')
    
    -- Create prop and play animation
    createTabletProp()
    playTabletAnimation()
    
    -- Get filtered apps based on player permissions
    TMC.Functions.TriggerServerCallback('mi-tablet:server:getFilteredApps', function(filteredApps)
        -- Get saved settings from database
        TMC.Functions.TriggerServerCallback('mi-tablet:server:getSettings', function(savedSettings)
            -- Use saved settings if available, otherwise use defaults
            local settingsToUse = savedSettings or Config.DefaultSettings
            
            -- Open NUI with filtered apps and saved settings
            SetNuiFocus(true, true)
            SendNUIMessage({
                type = "open",
                apps = filteredApps or Config.Apps,
                settings = settingsToUse,
                wallpapers = Config.Wallpapers,
                playerData = playerData
            })
            
            debugPrint("Tablet opened with " .. #(filteredApps or Config.Apps) .. " apps")
        end)
    end)
end

-- Close the tablet
local function closeTablet()
    if not isTabletOpen then return end
    
    isTabletOpen = false
    
    -- Close NUI
    SetNuiFocus(false, false)
    SendNUIMessage({
        type = "close"
    })
    
    -- Remove prop and stop animation
    removeTabletProp()
    stopTabletAnimation()
    
    debugPrint("Tablet closed")
end

-- Toggle tablet state
local function toggleTablet()
    if isTabletOpen then
        closeTablet()
    else
        openTablet()
    end
end

-- Event: Open tablet from server (item use)
RegisterNetEvent('mi-tablet:client:openTablet', function()
    openTablet()
end)

-- Event: Receive player data from server
RegisterNetEvent('mi-tablet:client:receivePlayerData', function(data)
    playerData = data
    
    -- Update NUI if tablet is open
    if isTabletOpen then
        SendNUIMessage({
            type = "updatePlayerData",
            playerData = playerData
        })
    end
    
    debugPrint("Received player data: " .. json.encode(data))
end)

-- Event: Settings saved confirmation
RegisterNetEvent('mi-tablet:client:settingsSaved', function(success)
    if success then
        debugPrint("Settings saved successfully")
    end
end)

-- NUI Callback: Close tablet
RegisterNUICallback('close', function(data, cb)
    closeTablet()
    cb('ok')
end)

-- NUI Callback: Get current time and date
RegisterNUICallback('getTime', function(data, cb)
    local hour = GetClockHours()
    local minute = GetClockMinutes()
    
    cb({
        hour = hour,
        minute = minute,
        formatted = string.format("%02d:%02d", hour, minute)
    })
end)

-- NUI Callback: Get weather
RegisterNUICallback('getWeather', function(data, cb)
    -- Request weather data from server (which gets it from tmc_realtimeweather)
    TMC.Functions.TriggerCallback('mi-tablet:server:getWeather', function(weatherData)
        if weatherData then
            cb(weatherData)
        else
            -- Fallback to local weather if server callback fails
            local weatherHash = GetPrevWeatherTypeHashName()
            local weatherTypes = {
                [`CLEAR`] = "Clear",
                [`EXTRASUNNY`] = "Sunny",
                [`CLOUDS`] = "Cloudy",
                [`OVERCAST`] = "Overcast",
                [`RAIN`] = "Rainy",
                [`CLEARING`] = "Clearing",
                [`THUNDER`] = "Thunderstorm",
                [`SMOG`] = "Smoggy",
                [`FOGGY`] = "Foggy",
                [`XMAS`] = "Snowy",
                [`SNOWLIGHT`] = "Light Snow",
                [`BLIZZARD`] = "Blizzard",
            }
            
            local weather = weatherTypes[weatherHash] or "Unknown"
            
            cb({
                weather = weather,
                hash = weatherHash,
                temperature = 15,
                feelsLike = 14,
                humidity = 65,
                windSpeed = 12,
                visibility = 10,
                uvIndex = 3,
                rainChance = 15,
                pressure = 1013
            })
        end
    end)
end)

-- NUI Callback: Save settings
RegisterNUICallback('saveSettings', function(data, cb)
    TriggerServerEvent('mi-tablet:server:saveSettings', data.settings)
    cb('ok')
end)

-- NUI Callback: Get player data
RegisterNUICallback('getPlayerData', function(data, cb)
    cb(playerData or {
        name = "Unknown",
        job = "Civilian",
        citizenid = "N/A"
    })
end)

-- NUI Callback: App opened (for logging/integration)
RegisterNUICallback('appOpened', function(data, cb)
    debugPrint("App opened: " .. (data.appId or "unknown"))
    cb('ok')
end)

-- NUI Callback: App closed (for logging/integration)
RegisterNUICallback('appClosed', function(data, cb)
    debugPrint("App closed: " .. (data.appId or "unknown"))
    cb('ok')
end)

-- ============================================
-- Crypto Mining App NUI Callbacks
-- ============================================

RegisterNUICallback('crypto:getRigs', function(_, cb)
    TMC.Functions.TriggerServerCallback('tmc-crypto:server:getRigs', function(rigs)
        cb({ rigs = rigs or {} })
    end)
end)

RegisterNUICallback('crypto:toggleMining', function(data, cb)
    TriggerServerEvent('tmc-crypto:server:toggleMining', data.rigId)
    cb('ok')
end)

-- ============================================
-- Rep App NUI Callbacks
-- ============================================

-- NUI Callback: Check if rep app is enabled
RegisterNUICallback('isRepEnabled', function(data, cb)
    cb(Config.RepAppEnabled)
end)

-- NUI Callback: Get current rep data
RegisterNUICallback('getCurrentRep', function(data, cb)
    TMC.Functions.TriggerServerCallback('mi-tablet:server:getRepData', function(repData)
        cb({ repData = repData or {} })
    end)
end)

-- NUI Callback: Get criminal rep data (for darkweb/street rep)
RegisterNUICallback('getCriminalRep', function(data, cb)
    TMC.Functions.TriggerServerCallback('mi-tablet:server:getCriminalRepData', function(repData)
        cb({ repData = repData or {} })
    end)
end)

-- NUI Callback: Check if player can access darkweb
RegisterNUICallback('canAccessDarkweb', function(data, cb)
    TMC.Functions.TriggerServerCallback('mi-tablet:server:canAccessDarkweb', function(canAccess)
        cb({ allowed = canAccess })
    end)
end)

-- Event: Receive rep data from server
RegisterNetEvent('mi-tablet:client:receiveRepData', function(repData)
    SendNUIMessage({
        type = "updateRep",
        repList = repData
    })
    debugPrint("Received rep data: " .. json.encode(repData))
end)

-- ============================================
-- Maps App NUI Callbacks
-- ============================================

-- NUI Callback: Get player location
RegisterNUICallback('getPlayerLocation', function(data, cb)
    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    local heading = GetEntityHeading(ped)
    
    -- Get current zone/area name
    local streetHash, crossingHash = GetStreetNameAtCoord(coords.x, coords.y, coords.z)
    local streetName = GetStreetNameFromHashKey(streetHash)
    local zoneName = GetLabelText(GetNameOfZone(coords.x, coords.y, coords.z))
    
    local locationText = streetName
    if zoneName and zoneName ~= "BLAINE COUNTY" and zoneName ~= "LOS SANTOS" then
        locationText = streetName .. ", " .. zoneName
    end
    
    cb({
        coords = { x = coords.x, y = coords.y, z = coords.z },
        heading = heading,
        zone = locationText
    })
end)

-- NUI Callback: Set waypoint
RegisterNUICallback('setWaypoint', function(data, cb)
    local x = tonumber(data.x) or 0
    local y = tonumber(data.y) or 0
    
    SetNewWaypoint(x, y)
    debugPrint("Waypoint set to: " .. x .. ", " .. y)
    cb('ok')
end)

-- NUI Callback: Clear waypoint
RegisterNUICallback('clearWaypoint', function(data, cb)
    SetWaypointOff()
    debugPrint("Waypoint cleared")
    cb('ok')
end)

-- ============================================
-- Banking App NUI Callbacks
-- ============================================

-- NUI Callback: Fetch bank accounts
RegisterNUICallback('fetchBankAccounts', function(data, cb)
    TMC.Functions.TriggerServerCallback('banking:server:getAccounts', function(accounts)
        cb({ accounts = accounts or {} })
    end)
end)

-- NUI Callback: Fetch bank transactions
RegisterNUICallback('fetchBankTransactions', function(data, cb)
    local accountNumber = data.accountNumber
    local page = data.page or 1
    local recent = data.recent or false
    
    TMC.Functions.TriggerServerCallback('banking:server:getTransactions', function(transactions)
        cb({ transactions = transactions or {} })
    end, { accountNumber = accountNumber, page = page, recent = recent })
end)

-- NUI Callback: Fetch invoices
RegisterNUICallback('fetchBankInvoices', function(data, cb)
    local accountNumber = data.accountNumber
    
    TMC.Functions.TriggerServerCallback('banking:server:getInvoices', function(invoices)
        cb({ invoices = invoices or {} })
    end, { accountNumber = accountNumber })
end)

-- ============================================
-- Permission & Admins App NUI Callbacks
-- ============================================

-- NUI Callback: Check if player has specific permission
RegisterNUICallback('checkPermission', function(data, cb)
    local permission = data.permission
    
    TMC.Functions.TriggerServerCallback('mi-tablet:server:hasPermission', function(hasPermission)
        cb({ hasPermission = hasPermission })
    end, permission)
end)

-- NUI Callback: Get filtered apps based on permissions
RegisterNUICallback('getFilteredApps', function(data, cb)
    TMC.Functions.TriggerServerCallback('mi-tablet:server:getFilteredApps', function(apps)
        cb({ apps = apps or {} })
    end)
end)

-- NUI Callback: Get online players (for admins app)
RegisterNUICallback('getOnlinePlayers', function(data, cb)
    TMC.Functions.TriggerServerCallback('mi-tablet:server:getOnlinePlayers', function(players)
        if players and players.error then
            cb({ error = players.error, players = {} })
        else
            cb({ players = players or {} })
        end
    end)
end)

-- ============================================
-- Events App NUI Callbacks
-- ============================================

-- NUI Callback: Get active event
RegisterNUICallback('getActiveEvent', function(data, cb)
    TMC.Functions.TriggerServerCallback('mi-tablet:server:getActiveEvent', function(activeEvent)
        cb({ activeEvent = activeEvent })
    end)
end)

-- ============================================
-- Player Events App NUI Callbacks
-- ============================================

-- NUI Callback: Get event status for player events app
RegisterNUICallback('getEventStatus', function(data, cb)
    local eventId = data.eventId
    
    TMC.Functions.TriggerServerCallback('mi-tablet:server:getEventStatus', function(result)
        cb(result or { state = 'inactive', timeRemaining = 0, playerCount = 0 })
    end, eventId)
end)

-- NUI Callback: Join an event
RegisterNUICallback('joinEvent', function(data, cb)
    local eventId = data.eventId
    
    TMC.Functions.TriggerServerCallback('mi-tablet:server:joinEvent', function(result)
        if result and result.success then
            cb({ success = true })
        else
            cb({ success = false, error = result and result.error or "Failed to join" })
        end
    end, eventId)
end)

-- NUI Callback: Leave an event
RegisterNUICallback('leaveEvent', function(data, cb)
    local eventId = data.eventId
    
    TMC.Functions.TriggerServerCallback('mi-tablet:server:leaveEvent', function(result)
        if result and result.success then
            cb({ success = true })
        else
            cb({ success = false, error = result and result.error or "Failed to leave" })
        end
    end, eventId)
end)

-- ============================================
-- Admin Events NUI Callbacks
-- ============================================

-- NUI Callback: Start an event
RegisterNUICallback('startEvent', function(data, cb)
    local eventId = data.eventId
    local eventData = data.eventData
    
    TMC.Functions.TriggerServerCallback('mi-tablet:server:startEvent', function(result)
        if result and result.success then
            cb({ success = true })
        else
            cb({ success = false, error = result and result.error or "Unknown error" })
        end
    end, eventId, eventData)
end)

-- NUI Callback: Stop an event
RegisterNUICallback('stopEvent', function(data, cb)
    local eventId = data.eventId
    local eventData = data.eventData
    
    TMC.Functions.TriggerServerCallback('mi-tablet:server:stopEvent', function(result)
        if result and result.success then
            cb({ success = true })
        else
            cb({ success = false, error = result and result.error or "Unknown error" })
        end
    end, eventId, eventData)
end)

-- NUI Callback: Execute AV admin command
RegisterNUICallback('executeAVCommand', function(data, cb)
    local command = data.command
    
    if not command then
        cb({ success = false, error = "No command specified" })
        return
    end
    
    -- Check admin permission via server callback
    TMC.Functions.TriggerServerCallback('mi-tablet:server:executeAVCommand', function(result)
        if result and result.success then
            -- Execute the command on the client
            ExecuteCommand(command)
            debugPrint("Executed AV command: " .. command)
            cb({ success = true })
        else
            cb({ success = false, error = result and result.error or "No permission" })
        end
    end, command)
end)

-- Event: Execute a command from the tablet (for admin events)
RegisterNetEvent('mi-tablet:client:executeCommand', function(command)
    ExecuteCommand(command)
    debugPrint("Executed command: " .. command)
end)

-- Key press handling for closing tablet
CreateThread(function()
    while true do
        Wait(0)
        
        if isTabletOpen then
            -- Disable controls while tablet is open
            DisableControlAction(0, 1, true)   -- Look Left/Right
            DisableControlAction(0, 2, true)   -- Look Up/Down
            DisableControlAction(0, 142, true) -- MeleeAttackAlternate
            DisableControlAction(0, 106, true) -- VehicleMouseControlOverride
            
            -- Close on configured key (backup to ESC in JS)
            if IsDisabledControlJustReleased(0, Config.CloseKey) then
                closeTablet()
            end
        end
    end
end)

-- ============================================
-- Bills App NUI Callbacks
-- ============================================

-- NUI Callback: Execute /billing command
RegisterNUICallback('executeBilling', function(data, cb)
    -- Close tablet first so the billing UI can show
    closeTablet()
    Wait(200)
    ExecuteCommand('billing')
    cb({success = true})
end)

-- Clean up on resource stop
AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() == resourceName then
        if isTabletOpen then
            closeTablet()
        end
        removeTabletProp()
    end
end)

-- Force-hide tablet on resource start (clears stuck UI after restart)
AddEventHandler('onResourceStart', function(resourceName)
    if GetCurrentResourceName() == resourceName then
        isTabletOpen = false
        SetNuiFocus(false, false)
        SetNuiFocusKeepInput(false)
        SendNUIMessage({action = 'hideTablet'})
        removeTabletProp()
        stopTabletAnimation()
        print('[MI Tablet] Forced UI hide on resource start')
    end
end)

RegisterCommand('forceclosetablet', function()
    print('[MI Tablet] Force close command executed')
    isTabletOpen = false
    SetNuiFocus(false, false)
    SetNuiFocusKeepInput(false)
    SendNUIMessage({action = 'hideTablet'})
    removeTabletProp()
    stopTabletAnimation()
    Wait(100)
    DisplayRadar(true)
    print('[MI Tablet] Tablet UI force closed')
end, false)

-- Emergency event (can be triggered from F8: TriggerEvent('mi-tablet:client:forceClose'))
RegisterNetEvent('mi-tablet:client:forceClose', function()
    ExecuteCommand('forceclosetablet')
end)

-- Emergency keybind (F10)
RegisterCommand('+emergencyclosetablet', function()
    ExecuteCommand('forceclosetablet')
end, false)
RegisterCommand('-emergencyclosetablet', function() end, false)
RegisterKeyMapping('+emergencyclosetablet', 'Emergency Close Tablet', 'keyboard', 'F10')

-- Alias command
RegisterCommand('closetablet', function()
    if isTabletOpen then
        closeTablet()
    else
        ExecuteCommand('forceclosetablet')
    end
end, false)

-- Clean up on player death
AddEventHandler('gameEventTriggered', function(name, args)
    if name == 'CEventNetworkEntityDamage' then
        local victim = args[1]
        local isDead = args[4]
        
        if victim == PlayerPedId() and isDead and isTabletOpen then
            closeTablet()
        end
    end
end)

debugPrint("Client script loaded successfully")
