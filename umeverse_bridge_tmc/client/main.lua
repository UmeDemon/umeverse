--[[
    Umeverse Bridge - TMC Client
    Emulates TMC client-side API using Umeverse functions

    TMC client scripts typically do:
        local TMC = exports['core']:GetCoreObject()
    or:
        local QBCore = exports['core']:GetCoreObject()

    Then use:
        TMC.Functions.GetPlayerData()
        TMC.Functions.Notify(text, type, duration, icon)
        TMC.Functions.SimpleNotify(text, type)
        TMC.Functions.TriggerCallback(name, cb, ...)
        TMC.Functions.HasItem(items, amount)
        TMC.Functions.GetClosestPlayer(coords, radius)
        TMC.Functions.SpawnVehicle(model, coords, heading, cb)
        TMC.Functions.DeleteVehicle(vehicle)
        TMC.Functions.GetPlate(vehicle)
        TMC.Functions.GetVehicleProperties(vehicle)
        TMC.Functions.SetVehicleProperties(vehicle, props)
        TMC.Functions.DrawText3D(coords, text)
        etc.
]]

local UME = exports['umeverse_core']:GetCoreObject()

-- ═══════════════════════════════════════
-- Player Data Cache
-- ═══════════════════════════════════════

TMC.PlayerData = {}

local function RefreshPlayerData()
    if UME.GetPlayerData then
        local data = UME.GetPlayerData()
        if data then
            local jobData = data.job or {}
            TMC.PlayerData = {
                source    = GetPlayerServerId(PlayerId()),
                citizenid = data.citizenid or '',
                license   = data.identifier or '',
                name      = GetPlayerName(PlayerId()),
                charinfo  = data.charinfo or {},
                money     = data.money or { cash = 0, bank = 0, crypto = 0 },
                job = {
                    name   = jobData.name or 'unemployed',
                    label  = jobData.label or 'Unemployed',
                    grade  = { name = jobData.gradelabel or 'None', level = jobData.grade or 0 },
                    onduty = jobData.onduty or false,
                },
                gang = {
                    name  = 'none',
                    label = 'No Gang',
                    grade = { name = 'None', level = 0 },
                },
                metadata  = data.metadata or {},
                inventory = data.inventory or {},
                permission = 'user',
            }
        end
    end
end

-- ═══════════════════════════════════════
-- TMC.Functions (Client-Side)
-- ═══════════════════════════════════════

-- Player Data
TMC.Functions.GetPlayerData = function(cb)
    RefreshPlayerData()
    if cb then
        cb(TMC.PlayerData)
    end
    return TMC.PlayerData
end

TMC.Functions.GetCoords = function(entity)
    entity = entity or PlayerPedId()
    return GetEntityCoords(entity)
end

-- ── Notifications ──

TMC.Functions.Notify = function(text, texttype, length, icon)
    UME.Notify(text, texttype or 'info', length or 5000)
end

-- SimpleNotify: defined in TMC's obfuscated client.js — we provide a Lua implementation
TMC.Functions.SimpleNotify = function(text, texttype)
    UME.Notify(text, texttype or 'info', 5000)
end

-- TriggerServerEvent: also defined in TMC's obfuscated JS — standard wrapper
TMC.Functions.TriggerServerEvent = function(eventName, ...)
    TriggerServerEvent(eventName, ...)
end

-- ── Server Callbacks ──

local ClientCallbacks = {}
local PendingCallbacks = {}

TMC.Functions.TriggerCallback = function(name, cb, ...)
    PendingCallbacks[name] = cb
    TriggerServerEvent('TMC:Server:TriggerCallback', name, ...)
end

-- Also alias via UME's system when available
if UME.TriggerServerCallback then
    local tmcTriggerCb = TMC.Functions.TriggerCallback
    TMC.Functions.TriggerCallback = function(name, cb, ...)
        -- Try UME first, then fall back to TMC event-based callback
        UME.TriggerServerCallback(name, function(...)
            if cb then cb(...) end
        end, ...)
    end
end

-- Client callback response
RegisterNetEvent('TMC:Client:CallbackResponse', function(name, ...)
    if PendingCallbacks[name] then
        PendingCallbacks[name](...)
        PendingCallbacks[name] = nil
    end
end)

-- QBCore compat client callback
RegisterNetEvent('QBCore:Client:TriggerCallback', function(name, ...)
    if PendingCallbacks[name] then
        PendingCallbacks[name](...)
        PendingCallbacks[name] = nil
    end
end)

-- Client Callbacks (other players or server can trigger)
TMC.Functions.CreateClientCallback = function(name, cb)
    ClientCallbacks[name] = cb
end

TMC.Functions.TriggerClientCallback = function(name, cb, ...)
    if ClientCallbacks[name] then
        ClientCallbacks[name](cb, ...)
    end
end

-- ── Inventory ──

TMC.Functions.HasItem = function(items, amount)
    amount = amount or 1
    if type(items) == 'string' then
        if UME.HasItem then
            return UME.HasItem(items, amount)
        end
        -- Fallback to checking PlayerData
        RefreshPlayerData()
        for _, item in pairs(TMC.PlayerData.inventory or {}) do
            if item.name == items and (item.count or item.amount or 0) >= amount then
                return true
            end
        end
        return false
    elseif type(items) == 'table' then
        for _, itemName in pairs(items) do
            local found = false
            for _, invItem in pairs(TMC.PlayerData.inventory or {}) do
                if invItem.name == itemName and (invItem.count or invItem.amount or 0) >= amount then
                    found = true
                    break
                end
            end
            if not found then return false end
        end
        return true
    end
    return false
end

-- ── Progress Bar ──

TMC.Functions.Progressbar = function(name, label, duration, useWhileDead, canCancel, disableControls, animation, prop, propTwo, onFinish, onCancel)
    -- Basic progress bar implementation using NUI or print
    -- Many TMC servers use custom progressbar resources — this is a fallback
    if animation and animation.animDict and animation.anim then
        RequestAnimDict(animation.animDict)
        local waitTime = 0
        while not HasAnimDictLoaded(animation.animDict) and waitTime < 3000 do
            Wait(10)
            waitTime = waitTime + 10
        end
        TaskPlayAnim(PlayerPedId(), animation.animDict, animation.anim, 8.0, -8.0, duration, animation.flags or 1, 0, false, false, false)
    end

    if disableControls then
        CreateThread(function()
            local endTime = GetGameTimer() + duration
            while GetGameTimer() < endTime do
                if disableControls.disableMovement then
                    DisableControlAction(0, 30, true)  -- MoveLeftRight
                    DisableControlAction(0, 31, true)  -- MoveUpDown
                end
                if disableControls.disableCombat then
                    DisableControlAction(0, 24, true)  -- Attack
                    DisableControlAction(0, 25, true)  -- Aim
                    DisableControlAction(0, 47, true)  -- Weapon
                    DisableControlAction(0, 58, true)  -- Weapon2
                    DisablePlayerFiring(PlayerId(), true)
                end
                if disableControls.disableCarMovement then
                    DisableControlAction(0, 63, true)   -- VehMoveLeftRight
                    DisableControlAction(0, 64, true)   -- VehMoveUpDown
                    DisableControlAction(0, 71, true)   -- VehAccelerate
                    DisableControlAction(0, 72, true)   -- VehBrake
                end
                Wait(0)
            end
        end)
    end

    SetTimeout(duration, function()
        ClearPedTasks(PlayerPedId())
        if onFinish then onFinish() end
    end)
end

-- ── World Entity Query ──

TMC.Functions.GetVehicles = function()
    return GetGamePool('CVehicle')
end

TMC.Functions.GetObjects = function()
    return GetGamePool('CObject')
end

TMC.Functions.GetPlayers = function()
    return GetActivePlayers()
end

TMC.Functions.GetPeds = function(ignoreList)
    local result = {}
    local ignoreSet = {}
    if ignoreList then
        for _, v in pairs(ignoreList) do
            ignoreSet[v] = true
        end
    end
    for _, ped in ipairs(GetGamePool('CPed')) do
        if not ignoreSet[ped] then
            result[#result + 1] = ped
        end
    end
    return result
end

TMC.Functions.GetPlayersFromCoords = function(coords, distance)
    coords = coords or GetEntityCoords(PlayerPedId())
    distance = distance or 5.0
    local result = {}
    for _, player in ipairs(GetActivePlayers()) do
        local ped = GetPlayerPed(player)
        local playerCoords = GetEntityCoords(ped)
        if #(coords - playerCoords) <= distance then
            result[#result + 1] = player
        end
    end
    return result
end

TMC.Functions.GetClosestPlayer = function(coords)
    coords = coords or GetEntityCoords(PlayerPedId())
    local closestId, closestDist = -1, -1
    for _, player in ipairs(GetActivePlayers()) do
        if player ~= PlayerId() then
            local ped = GetPlayerPed(player)
            local dist = #(coords - GetEntityCoords(ped))
            if closestDist == -1 or dist < closestDist then
                closestId = player
                closestDist = dist
            end
        end
    end
    return closestId, closestDist
end

TMC.Functions.GetClosestVehicle = function(coords)
    coords = coords or GetEntityCoords(PlayerPedId())
    local closestVeh, closestDist = -1, -1
    for _, veh in ipairs(GetGamePool('CVehicle')) do
        local dist = #(coords - GetEntityCoords(veh))
        if closestDist == -1 or dist < closestDist then
            closestVeh = veh
            closestDist = dist
        end
    end
    return closestVeh, closestDist
end

TMC.Functions.GetClosestPed = function(coords, ignoreList)
    coords = coords or GetEntityCoords(PlayerPedId())
    local ignoreSet = {}
    if ignoreList then
        for _, v in pairs(ignoreList) do ignoreSet[v] = true end
    end
    local closestPed, closestDist = -1, -1
    for _, ped in ipairs(GetGamePool('CPed')) do
        if not IsPedAPlayer(ped) and not ignoreSet[ped] then
            local dist = #(coords - GetEntityCoords(ped))
            if closestDist == -1 or dist < closestDist then
                closestPed = ped
                closestDist = dist
            end
        end
    end
    return closestPed, closestDist
end

TMC.Functions.GetClosestObject = function(coords)
    coords = coords or GetEntityCoords(PlayerPedId())
    local closestObj, closestDist = -1, -1
    for _, obj in ipairs(GetGamePool('CObject')) do
        local dist = #(coords - GetEntityCoords(obj))
        if closestDist == -1 or dist < closestDist then
            closestObj = obj
            closestDist = dist
        end
    end
    return closestObj, closestDist
end

TMC.Functions.GetClosestBone = function(entity, list)
    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    local closestBone, closestDist, closestCoords = -1, -1, nil
    for _, bone in pairs(list) do
        local boneIndex = GetEntityBoneIndexByName(entity, bone)
        if boneIndex ~= -1 then
            local boneCoords = GetWorldPositionOfEntityBone(entity, boneIndex)
            local dist = #(coords - boneCoords)
            if closestDist == -1 or dist < closestDist then
                closestBone = bone
                closestDist = dist
                closestCoords = boneCoords
            end
        end
    end
    return closestBone, closestDist, closestCoords
end

TMC.Functions.GetBoneDistance = function(entity, boneType, boneIndex)
    local coords = GetEntityCoords(PlayerPedId())
    local boneCoords = GetWorldPositionOfEntityBone(entity, boneIndex)
    return #(coords - boneCoords)
end

-- ── Vehicle Functions ──

TMC.Functions.LoadModel = function(model)
    if type(model) == 'string' then model = joaat(model) end
    if not IsModelValid(model) then return false end
    RequestModel(model)
    local waitTime = 0
    while not HasModelLoaded(model) and waitTime < 10000 do
        Wait(10)
        waitTime = waitTime + 10
    end
    return HasModelLoaded(model)
end

TMC.Functions.SpawnVehicle = function(model, coords, heading, cb, isNetwork)
    if type(model) == 'string' then model = joaat(model) end
    isNetwork = isNetwork == nil and true or isNetwork
    TMC.Functions.LoadModel(model)

    local veh = CreateVehicle(model, coords.x, coords.y, coords.z, heading or 0.0, isNetwork, false)
    local waitTime = 0
    while not DoesEntityExist(veh) and waitTime < 5000 do
        Wait(10)
        waitTime = waitTime + 10
    end

    SetModelAsNoLongerNeeded(model)
    if cb then cb(veh) end
    return veh
end

TMC.Functions.DeleteVehicle = function(vehicle)
    if DoesEntityExist(vehicle) then
        SetEntityAsMissionEntity(vehicle, true, true)
        DeleteVehicle(vehicle)
    end
end

TMC.Functions.GetPlate = function(vehicle)
    if not DoesEntityExist(vehicle) then return '' end
    return TMC.Shared.Trim(GetVehicleNumberPlateText(vehicle))
end

TMC.Functions.GetVehicleLabel = function(vehicle)
    if not DoesEntityExist(vehicle) then return '' end
    return GetLabelText(GetDisplayNameFromVehicleModel(GetEntityModel(vehicle)))
end

TMC.Functions.SpawnClear = function(coords, radius)
    coords = coords or GetEntityCoords(PlayerPedId())
    radius = radius or 5.0
    for _, veh in ipairs(GetGamePool('CVehicle')) do
        if #(coords - GetEntityCoords(veh)) < radius then
            return false
        end
    end
    return true
end

-- ── Massive GetVehicleProperties / SetVehicleProperties ──

TMC.Functions.GetVehicleProperties = function(vehicle)
    if not DoesEntityExist(vehicle) then return nil end

    local colorPrimary, colorSecondary = GetVehicleColours(vehicle)
    local pearlescentColor, wheelColor = GetVehicleExtraColours(vehicle)
    local interiorColor = GetVehicleInteriorColour(vehicle)
    local dashboardColor = GetVehicleDashboardColour(vehicle)

    local extras = {}
    for i = 0, 20 do
        if DoesExtraExist(vehicle, i) then
            extras[tostring(i)] = IsVehicleExtraTurnedOn(vehicle, i)
        end
    end

    local modLivery = GetVehicleMod(vehicle, 48)
    local livery = GetVehicleLivery(vehicle)

    local neons = {}
    for i = 0, 3 do
        neons[i + 1] = IsVehicleNeonLightEnabled(vehicle, i)
    end
    local neonR, neonG, neonB = GetVehicleNeonLightsColour(vehicle)
    local tyreSmokeR, tyreSmokeG, tyreSmokeB = GetVehicleTyreSmokeColor(vehicle)
    local xenonColor = GetVehicleXenonLightsColour(vehicle)

    local mods = {}
    for i = 0, 49 do
        mods[i] = GetVehicleMod(vehicle, i)
    end

    local customPrimary = GetIsVehiclePrimaryColourCustom(vehicle)
    local customSecondary = GetIsVehicleSecondaryColourCustom(vehicle)
    local cPrimaryR, cPrimaryG, cPrimaryB = 0, 0, 0
    local cSecondaryR, cSecondaryG, cSecondaryB = 0, 0, 0
    if customPrimary then cPrimaryR, cPrimaryG, cPrimaryB = GetVehicleCustomPrimaryColour(vehicle) end
    if customSecondary then cSecondaryR, cSecondaryG, cSecondaryB = GetVehicleCustomSecondaryColour(vehicle) end

    local windowTint = GetVehicleWindowTint(vehicle)
    local plateIndex = GetVehicleNumberPlateTextIndex(vehicle)
    local tyreBurstState = {}
    local tyreBurstCompletely = {}
    for i = 0, 7 do
        tyreBurstState[i] = IsVehicleTyreBurst(vehicle, i, false)
        tyreBurstCompletely[i] = IsVehicleTyreBurst(vehicle, i, true)
    end

    local doors = {}
    for i = 0, 5 do
        doors[i] = IsVehicleDoorDamaged(vehicle, i)
    end

    local windows = {}
    for i = 0, 7 do
        windows[i] = not IsVehicleWindowIntact(vehicle, i)
    end

    return {
        model             = GetEntityModel(vehicle),
        plate             = TMC.Shared.Trim(GetVehicleNumberPlateText(vehicle)),
        plateIndex        = plateIndex,
        bodyHealth        = TMC.Shared.Round(GetVehicleBodyHealth(vehicle), 1),
        engineHealth      = TMC.Shared.Round(GetVehicleEngineHealth(vehicle), 1),
        tankHealth        = TMC.Shared.Round(GetVehiclePetrolTankHealth(vehicle), 1),
        fuelLevel         = TMC.Shared.Round(GetVehicleFuelLevel(vehicle), 1),
        dirtLevel         = TMC.Shared.Round(GetVehicleDirtLevel(vehicle), 1),
        color1            = colorPrimary,
        color2            = colorSecondary,
        customPrimaryColor = customPrimary and {cPrimaryR, cPrimaryG, cPrimaryB} or nil,
        customSecondaryColor = customSecondary and {cSecondaryR, cSecondaryG, cSecondaryB} or nil,
        pearlescentColor  = pearlescentColor,
        wheelColor        = wheelColor,
        interiorColor     = interiorColor,
        dashboardColor    = dashboardColor,
        wheels            = GetVehicleWheelType(vehicle),
        windowTint        = windowTint,
        xenonColor        = xenonColor,
        neonEnabled       = neons,
        neonColor         = { neonR, neonG, neonB },
        extras            = extras,
        tyreSmokeColor    = { tyreSmokeR, tyreSmokeG, tyreSmokeB },
        modSpoilers       = mods[0],
        modFrontBumper    = mods[1],
        modRearBumper     = mods[2],
        modSideSkirt      = mods[3],
        modExhaust        = mods[4],
        modFrame          = mods[5],
        modGrille         = mods[6],
        modHood           = mods[7],
        modFender         = mods[8],
        modRightFender    = mods[9],
        modRoof           = mods[10],
        modEngine         = mods[11],
        modBrakes         = mods[12],
        modTransmission   = mods[13],
        modHorns          = mods[14],
        modSuspension     = mods[15],
        modArmor          = mods[16],
        modTurbo          = IsToggleModOn(vehicle, 18),
        modSmokeEnabled   = IsToggleModOn(vehicle, 20),
        modXenon          = IsToggleModOn(vehicle, 22),
        modFrontWheels    = mods[23],
        modBackWheels     = mods[24],
        modPlateHolder    = mods[25],
        modVanityPlate    = mods[26],
        modTrimA          = mods[27],
        modOrnaments      = mods[28],
        modDashboard      = mods[29],
        modDial           = mods[30],
        modDoorSpeaker    = mods[31],
        modSeats          = mods[32],
        modSteeringWheel  = mods[33],
        modShifterLeavers = mods[34],
        modAPlate         = mods[35],
        modSpeakers       = mods[36],
        modTrunk          = mods[37],
        modHydrolic       = mods[38],
        modEngineBlock    = mods[39],
        modAirFilter      = mods[40],
        modStruts         = mods[41],
        modArchCover      = mods[42],
        modAerials        = mods[43],
        modTrimB          = mods[44],
        modTank           = mods[45],
        modWindows        = mods[46],
        modLivery         = modLivery,
        livery            = livery,
        tyreBurst         = tyreBurstState,
        tyreBurstCompletely = tyreBurstCompletely,
        doorsBroken       = doors,
        windowsBroken     = windows,
    }
end

TMC.Functions.SetVehicleProperties = function(vehicle, props)
    if not DoesEntityExist(vehicle) or not props then return end

    if props.plate then SetVehicleNumberPlateText(vehicle, props.plate) end
    if props.plateIndex then SetVehicleNumberPlateTextIndex(vehicle, props.plateIndex) end
    if props.bodyHealth then SetVehicleBodyHealth(vehicle, props.bodyHealth + 0.0) end
    if props.engineHealth then SetVehicleEngineHealth(vehicle, props.engineHealth + 0.0) end
    if props.tankHealth then SetVehiclePetrolTankHealth(vehicle, props.tankHealth + 0.0) end
    if props.fuelLevel then SetVehicleFuelLevel(vehicle, props.fuelLevel + 0.0) end
    if props.dirtLevel then SetVehicleDirtLevel(vehicle, props.dirtLevel + 0.0) end

    if props.color1 ~= nil and props.color2 ~= nil then
        SetVehicleColours(vehicle, props.color1, props.color2)
    end
    if props.customPrimaryColor then
        SetVehicleCustomPrimaryColour(vehicle, props.customPrimaryColor[1], props.customPrimaryColor[2], props.customPrimaryColor[3])
    end
    if props.customSecondaryColor then
        SetVehicleCustomSecondaryColour(vehicle, props.customSecondaryColor[1], props.customSecondaryColor[2], props.customSecondaryColor[3])
    end
    if props.pearlescentColor ~= nil and props.wheelColor ~= nil then
        SetVehicleExtraColours(vehicle, props.pearlescentColor, props.wheelColor)
    end
    if props.interiorColor then SetVehicleInteriorColour(vehicle, props.interiorColor) end
    if props.dashboardColor then SetVehicleDashboardColour(vehicle, props.dashboardColor) end
    if props.wheels ~= nil then SetVehicleWheelType(vehicle, props.wheels) end
    if props.windowTint ~= nil then SetVehicleWindowTint(vehicle, props.windowTint) end

    -- Neons
    if props.neonEnabled then
        for i = 1, 4 do
            SetVehicleNeonLightEnabled(vehicle, i - 1, props.neonEnabled[i] or false)
        end
    end
    if props.neonColor then
        SetVehicleNeonLightsColour(vehicle, props.neonColor[1] or 0, props.neonColor[2] or 0, props.neonColor[3] or 0)
    end

    -- Tyre smoke
    if props.tyreSmokeColor then
        SetVehicleTyreSmokeColor(vehicle, props.tyreSmokeColor[1] or 0, props.tyreSmokeColor[2] or 0, props.tyreSmokeColor[3] or 0)
    end

    -- Xenon
    if props.xenonColor ~= nil then
        SetVehicleXenonLightsColour(vehicle, props.xenonColor)
    end

    -- Mods
    SetVehicleModKit(vehicle, 0)

    local modMap = {
        modSpoilers = 0, modFrontBumper = 1, modRearBumper = 2, modSideSkirt = 3,
        modExhaust = 4, modFrame = 5, modGrille = 6, modHood = 7,
        modFender = 8, modRightFender = 9, modRoof = 10, modEngine = 11,
        modBrakes = 12, modTransmission = 13, modHorns = 14, modSuspension = 15,
        modArmor = 16, modFrontWheels = 23, modBackWheels = 24,
        modPlateHolder = 25, modVanityPlate = 26, modTrimA = 27,
        modOrnaments = 28, modDashboard = 29, modDial = 30, modDoorSpeaker = 31,
        modSeats = 32, modSteeringWheel = 33, modShifterLeavers = 34,
        modAPlate = 35, modSpeakers = 36, modTrunk = 37, modHydrolic = 38,
        modEngineBlock = 39, modAirFilter = 40, modStruts = 41, modArchCover = 42,
        modAerials = 43, modTrimB = 44, modTank = 45, modWindows = 46,
        modLivery = 48,
    }

    for propName, modIndex in pairs(modMap) do
        if props[propName] ~= nil and props[propName] ~= -1 then
            SetVehicleMod(vehicle, modIndex, props[propName], false)
        end
    end

    -- Toggle mods
    if props.modTurbo ~= nil then ToggleVehicleMod(vehicle, 18, props.modTurbo) end
    if props.modSmokeEnabled ~= nil then ToggleVehicleMod(vehicle, 20, props.modSmokeEnabled) end
    if props.modXenon ~= nil then ToggleVehicleMod(vehicle, 22, props.modXenon) end

    -- Livery
    if props.livery ~= nil then
        SetVehicleLivery(vehicle, props.livery)
    end

    -- Extras
    if props.extras then
        for id, enabled in pairs(props.extras) do
            id = tonumber(id)
            if id and DoesExtraExist(vehicle, id) then
                SetVehicleExtra(vehicle, id, not enabled)
            end
        end
    end

    -- Tyre burst
    if props.tyreBurst then
        for i, burst in pairs(props.tyreBurst) do
            if burst then
                SetVehicleTyreBurst(vehicle, tonumber(i), props.tyreBurstCompletely and props.tyreBurstCompletely[i] or false, 1000.0)
            end
        end
    end

    -- Door damage
    if props.doorsBroken then
        for i, broken in pairs(props.doorsBroken) do
            if broken then
                SetVehicleDoorBroken(vehicle, tonumber(i), true)
            end
        end
    end

    -- Window damage
    if props.windowsBroken then
        for i, broken in pairs(props.windowsBroken) do
            if broken then
                SmashVehicleWindow(vehicle, tonumber(i))
            end
        end
    end
end

-- ── State Bag Utilities ──

TMC.Functions.GetStateBag = function(entity)
    if not DoesEntityExist(entity) then return nil end
    return Entity(entity).state
end

TMC.Functions.SetStateBag = function(entity, key, value)
    if not DoesEntityExist(entity) then return false end
    Entity(entity).state:set(key, value, true)
    return true
end

TMC.Functions.GetStateBagValue = function(entity, key)
    if not DoesEntityExist(entity) then return nil end
    return Entity(entity).state[key]
end

TMC.Functions.GetPlayerStateBag = function(player)
    player = player or PlayerId()
    local ped = GetPlayerPed(player)
    if not DoesEntityExist(ped) then return nil end
    return Entity(ped).state
end

-- ── Area Utilities ──

TMC.Functions.IsPlayerInArea = function(coords, range, checkSelf)
    local playerCoords = GetEntityCoords(PlayerPedId())
    local inArea = #(playerCoords - coords) <= range
    return inArea
end

TMC.Functions.GetPlayersInAreaRadius = function(coords, range)
    local result = {}
    for _, player in ipairs(GetActivePlayers()) do
        local ped = GetPlayerPed(player)
        if DoesEntityExist(ped) then
            local playerCoords = GetEntityCoords(ped)
            if #(playerCoords - coords) <= range then
                table.insert(result, player)
            end
        end
    end
    return result
end

TMC.Functions.GetClientPlayers = function()
    return GetActivePlayers()
end

-- ── Draw Text Extensions ──

TMC.Functions.Draw3DTextAlt = function(x, y, z, text, fontId, scale, rgba)
    fontId = fontId or 1
    scale = scale or 1.0
    rgba = rgba or {r = 255, g = 255, b = 255, a = 255}
    
    SetTextFont(fontId)
    SetTextProportional(false)
    SetTextScale(scale, scale)
    SetTextColour(rgba.r, rgba.g, rgba.b, rgba.a)
    SetTextOutline()
    SetTextEntry("STRING")
    AddTextComponentString(text)
    DrawText(x, y)
end

TMC.Functions.Draw3DText = function(coords, text, ...)
    local args = {...}
    local distance = args[1] or 50.0
    local r, g, b, a = args[2] or 255, args[3] or 255, args[4] or 255, args[5] or 255
    
    local playerCoords = GetEntityCoords(PlayerPedId())
    if #(playerCoords - coords) > distance then return end
    
    local screenCoords = GetScreenCoordFromWorldCoord(coords.x, coords.y, coords.z)
    if not screenCoords then return end
    
    TMC.Functions.Draw3DTextAlt(screenCoords[1], screenCoords[2], 0, text, 1, 0.5, {r = r, g = g, b = b, a = a})
end

-- ── Animation / Streaming ──

TMC.Functions.RequestAnimDict = function(animDict)
    if HasAnimDictLoaded(animDict) then return true end
    RequestAnimDict(animDict)
    local waitTime = 0
    while not HasAnimDictLoaded(animDict) and waitTime < 5000 do
        Wait(10)
        waitTime = waitTime + 10
    end
    return HasAnimDictLoaded(animDict)
end

TMC.Functions.LoadAnimSet = function(animSet)
    if HasAnimSetLoaded(animSet) then return true end
    RequestAnimSet(animSet)
    local waitTime = 0
    while not HasAnimSetLoaded(animSet) and waitTime < 5000 do
        Wait(10)
        waitTime = waitTime + 10
    end
    return HasAnimSetLoaded(animSet)
end

TMC.Functions.LoadParticleDictionary = function(dict)
    if HasNamedPtfxAssetLoaded(dict) then return true end
    RequestNamedPtfxAsset(dict)
    local waitTime = 0
    while not HasNamedPtfxAssetLoaded(dict) and waitTime < 5000 do
        Wait(10)
        waitTime = waitTime + 10
    end
    return HasNamedPtfxAssetLoaded(dict)
end

-- ── Draw / Text ──

TMC.Functions.DrawText = function(x, y, width, height, scale, r, g, b, a, text)
    SetTextFont(4)
    SetTextProportional(false)
    SetTextScale(scale, scale)
    SetTextColour(r, g, b, a)
    SetTextDropShadow(0, 0, 0, 0, 255)
    SetTextEdge(2, 0, 0, 0, 255)
    SetTextDropShadow()
    SetTextOutline()
    SetTextEntry('STRING')
    AddTextComponentString(text)
    DrawText(x - width / 2, y - height / 2 + 0.005)
end

TMC.Functions.DrawText3D = function(x, y, z, text)
    SetTextScale(0.35, 0.35)
    SetTextFont(4)
    SetTextProportional(true)
    SetTextColour(255, 255, 255, 215)
    SetTextEntry('STRING')
    SetTextCentre(true)
    AddTextComponentString(text)
    SetDrawOrigin(x, y, z, 0)
    DrawText(0.0, 0.0)
    local factor = (string.len(text)) / 370
    DrawRect(0.0, 0.0 + 0.0125, 0.017 + factor, 0.03, 0, 0, 0, 75)
    ClearDrawOrigin()
end

-- ── Misc Utility Functions ──

TMC.Functions.PlayAnim = function(animDict, animName, upperbodyOnly, duration)
    TMC.Functions.RequestAnimDict(animDict)
    local flags = upperbodyOnly and 16 or 0
    TaskPlayAnim(PlayerPedId(), animDict, animName, 8.0, -8.0, duration or -1, flags, 0, false, false, false)
end

TMC.Functions.AttachProp = function(ped, model, boneId, x, y, z, xR, yR, zR, vertex)
    TMC.Functions.LoadModel(model)
    local boneIndex = GetPedBoneIndex(ped, boneId)
    local prop = CreateObject(model, 1.0, 1.0, 1.0, true, true, true)
    AttachEntityToEntity(prop, ped, boneIndex, x or 0.0, y or 0.0, z or 0.0, xR or 0.0, yR or 0.0, zR or 0.0, true, true, false, true, vertex and 0 or 1, true)
    SetModelAsNoLongerNeeded(model)
    return prop
end

TMC.Functions.LookAtEntity = function(entity, timeout)
    timeout = timeout or 5000
    local coords = GetEntityCoords(entity)
    TaskLookAtCoord(PlayerPedId(), coords.x, coords.y, coords.z, timeout, 2048, 3)
end

TMC.Functions.GetStreetNameAtCoords = function(coords)
    local streetHash, crossHash = GetStreetNameAtCoord(coords.x, coords.y, coords.z)
    return GetStreetNameFromHashKey(streetHash)
end

TMC.Functions.GetZoneAtCoords = function(coords)
    return GetLabelText(GetNameOfZone(coords.x, coords.y, coords.z))
end

TMC.Functions.GetPlayerJob = function()
    RefreshPlayerData()
    return TMC.PlayerData.job
end

TMC.Functions.GetPlayerGang = function()
    RefreshPlayerData()
    return TMC.PlayerData.gang
end

TMC.Functions.GetPlayerMoney = function(type)
    RefreshPlayerData()
    return TMC.PlayerData.money[type] or 0
end

TMC.Functions.GetPlayerInventory = function()
    RefreshPlayerData()
    return TMC.PlayerData.inventory
end

TMC.Functions.GetPlayerIdentifier = function()
    RefreshPlayerData()
    return TMC.PlayerData.citizenid
end

TMC.Functions.GetPlayerSex = function()
    RefreshPlayerData()
    return TMC.PlayerData.charinfo and TMC.PlayerData.charinfo.sex or 'M'
end

TMC.Functions.GetPlayerPhoneNumber = function()
    RefreshPlayerData()
    return TMC.PlayerData.charinfo and TMC.PlayerData.charinfo.phone or ''
end

-- ── Drawing utilities organized in TMC.Utils ──

TMC.Utils = {}

TMC.Utils.DrawRect3D = function(x, y, z, width, height, r, g, b, a)
    a = a or 255
    DrawRect(x, y, width, height, r, g, b, a)
end

TMC.Utils.DrawMarker = function(type, x, y, z, dirX, dirY, dirZ, rotX, rotY, rotZ, scaleX, scaleY, scaleZ, r, g, b, a, bobUpAndDown, faceCamera, p19, rotate, textureDict, textureName, drawOnEnts)
    DrawMarker(type, x, y, z, dirX, dirY, dirZ, rotX, rotY, rotZ, scaleX, scaleY, scaleZ, r, g, b, a, bobUpAndDown, faceCamera, p19, rotate, textureDict, textureName, drawOnEnts)
end

TMC.Utils.GetDistanceBetween = function(c1, c2)
    return #(c1 - c2)
end

TMC.Utils.IsPlayerNearPosition = function(coords, distance)
    local playerCoords = GetEntityCoords(PlayerPedId())
    return #(playerCoords - coords) <= distance
end

TMC.Utils.IsModelValid = function(model)
    if type(model) == 'string' then model = joaat(model) end
    return IsModelValid(model)
end

TMC.Utils.CycleJob = function(currentJob)
    RefreshPlayerData()
    if TMC.PlayerData.job.name == currentJob then
        return true
    end
    return false
end

TMC.Utils.CyclePermission = function(permission)
    -- Check players perm
    return true
end

-- ── Ped/Entity utilities ──

TMC.Functions.CreatePedLocal = function(model, coords, heading, freeze, invincible)
    TMC.Functions.LoadModel(model)
    local ped = CreatePed(4, model, coords.x, coords.y, coords.z, heading or 0.0, false, false)
    if freeze then FreezeEntityPosition(ped, true) end
    if invincible then SetEntityInvincible(ped, true) end
    SetModelAsNoLongerNeeded(model)
    return ped
end

TMC.Functions.CreateObjectLocal = function(model, coords, heading)
    TMC.Functions.LoadModel(model)
    local obj = CreateObject(model, coords.x, coords.y, coords.z, false, true, false)
    if heading then SetEntityHeading(obj, heading) end
    SetModelAsNoLongerNeeded(model)
    return obj
end

TMC.Functions.TeleportPlayer = function(vector, heading)
    RequestCollisionAtCoord(vector.x, vector.y, vector.z)
    SetEntityCoords(PlayerPedId(), vector.x, vector.y, vector.z, false, false, false, false)
    if heading then SetEntityHeading(PlayerPedId(), heading) end
end

-- ── Input utilities ──

TMC.Functions.IsKeyPressed = function(key)
    return IsControlPressed(0, GetHashKey(key) or key)
end

TMC.Functions.IsKeyJustPressed = function(key)
    return IsControlJustPressed(0, GetHashKey(key) or key)
end

TMC.Functions.IsKeyJustReleased = function(key)
    return IsControlJustReleased(0, GetHashKey(key) or key)
end

-- ── Raycast utilities ──

TMC.Functions.RaycastFromCamera = function(distance)
    local cam = GetGameplayCamCoord()
    local direction = GetGameplayCamRot(2)
    local rotation = vector3(
        (direction.x) * math.pi / 180.0,
        (direction.y) * math.pi / 180.0,
        (direction.z) * math.pi / 180.0
    )
    local ahead = vector3(
        cam.x + math.sin(rotation.z) * math.cos(rotation.x) * distance,
        cam.y + math.cos(rotation.z) * math.cos(rotation.x) * distance,
        cam.z + math.sin(rotation.x) * distance
    )
    return cam, ahead
end

TMC.Functions.Raycast = function(startCoords, endCoords, flags, ignore)
    local ray = StartShapeTestRay(startCoords, endCoords, flags, ignore, 4)
    local hit, endCoords, surfaceNormal, entityHit = GetShapeTestResult(ray)
    return hit, endCoords, surfaceNormal, entityHit
end

-- ── Blip utilities ──

TMC.Functions.CreateBlip = function(label, sprite, color, coords, scale, shortrange)
    local blip = AddBlipForCoord(coords)
    SetBlipSprite(blip, sprite)
    SetBlipColour(blip, color)
    SetBlipAsShortRange(blip, shortrange)
    SetBlipScale(blip, scale)
    AddTextEntry(label, label)
    SetBlipName(blip, label)
    return blip
end

TMC.Functions.RemoveBlip = function(blip)
    if DoesBlipExist(blip) then RemoveBlip(blip) end
end


TMC.Functions.GetCardinalDirection = function(entity)
    entity = entity or PlayerPedId()
    local heading = GetEntityHeading(entity)
    if heading >= 315.0 or heading < 45.0 then return 'North'
    elseif heading >= 45.0 and heading < 135.0 then return 'West'
    elseif heading >= 135.0 and heading < 225.0 then return 'South'
    else return 'East'
    end
end

TMC.Functions.GetCurrentTime = function()
    local hours = GetClockHours()
    local minutes = GetClockMinutes()
    return string.format('%02d:%02d', hours, minutes)
end

TMC.Functions.GetGroundZCoord = function(coords)
    local retval, groundZ = GetGroundZFor_3dCoord(coords.x, coords.y, coords.z, false)
    if retval then
        return vector3(coords.x, coords.y, groundZ)
    end
    return coords
end

TMC.Functions.GetGroundHash = function(entity)
    entity = entity or PlayerPedId()
    local coords = GetEntityCoords(entity)
    local retval, groundZ, normal = GetGroundZAndNormalFor_3dCoord(coords.x, coords.y, coords.z)
    if retval then
        return GetHashOfMapAreaAtCoords(coords.x, coords.y, groundZ)
    end
    return 0
end

TMC.Functions.IsWearingGloves = function()
    local ped = PlayerPedId()
    local armIndex = GetPedDrawableVariation(ped, 3)
    local armTexture = GetPedTextureVariation(ped, 3)
    -- Most standard glove drawable IDs — varies by model
    return false
end

TMC.Functions.StartParticleAtCoord = function(dict, ptfx, looped, coords, rotation, scale, alpha, color, duration)
    TMC.Functions.LoadParticleDictionary(dict)
    UseParticleFxAssetNextCall(dict)
    local handle
    if looped then
        handle = StartParticleFxLoopedAtCoord(ptfx, coords.x, coords.y, coords.z, (rotation or {}).x or 0.0, (rotation or {}).y or 0.0, (rotation or {}).z or 0.0, scale or 1.0, false, false, false, false)
    else
        handle = StartParticleFxNonLoopedAtCoord(ptfx, coords.x, coords.y, coords.z, (rotation or {}).x or 0.0, (rotation or {}).y or 0.0, (rotation or {}).z or 0.0, scale or 1.0, false, false, false)
    end
    if alpha and handle then SetParticleFxLoopedAlpha(handle, alpha) end
    if color and handle then SetParticleFxLoopedColour(handle, color.r or 1.0, color.g or 1.0, color.b or 1.0, false) end
    if duration and looped and handle then
        SetTimeout(duration, function()
            StopParticleFxLooped(handle, false)
        end)
    end
    return handle
end

TMC.Functions.StartParticleOnEntity = function(dict, ptfx, looped, entity, offset, rotation, scale, alpha, color, duration)
    TMC.Functions.LoadParticleDictionary(dict)
    UseParticleFxAssetNextCall(dict)
    offset = offset or {}
    rotation = rotation or {}
    local handle
    if looped then
        handle = StartParticleFxLoopedOnEntity(ptfx, entity, offset.x or 0.0, offset.y or 0.0, offset.z or 0.0, rotation.x or 0.0, rotation.y or 0.0, rotation.z or 0.0, scale or 1.0, false, false, false)
    else
        StartParticleFxNonLoopedOnEntity(ptfx, entity, offset.x or 0.0, offset.y or 0.0, offset.z or 0.0, rotation.x or 0.0, rotation.y or 0.0, rotation.z or 0.0, scale or 1.0, false, false, false)
    end
    if alpha and handle then SetParticleFxLoopedAlpha(handle, alpha) end
    if color and handle then SetParticleFxLoopedColour(handle, color.r or 1.0, color.g or 1.0, color.b or 1.0, false) end
    if duration and looped and handle then
        SetTimeout(duration, function()
            StopParticleFxLooped(handle, false)
        end)
    end
    return handle
end

-- ── TMC.Natives stubs ──

TMC.Natives = TMC.Natives or {}

TMC.Natives.GetOffsetFromCoordsInDirection = function(coords, heading, distance)
    local rads = math.rad(heading)
    return vector3(
        coords.x + (-math.sin(rads) * distance),
        coords.y + (math.cos(rads) * distance),
        coords.z
    )
end

-- ── Weapon Utilities ──

TMC.Functions.GiveWeapon = function(weaponName, ammo)
    ammo = ammo or 250
    local weapon = joaat(weaponName)
    GiveWeaponToPed(PlayerPedId(), weapon, ammo, false, true)
end

TMC.Functions.RemoveWeapon = function(weaponName)
    local weapon = joaat(weaponName)
    RemoveWeaponFromPed(PlayerPedId(), weapon)
end

TMC.Functions.RemoveAllWeapons = function()
    RemoveAllPedWeapons(PlayerPedId(), true)
end

TMC.Functions.GetCurrentWeapon = function()
    local _, weapon = GetCurrentPedWeapon(PlayerPedId())
    return weapon
end

TMC.Functions.GiveAmmo = function(weaponName, ammo)
    local weapon = joaat(weaponName)
    local ped = PlayerPedId()
    if HasPedGotWeapon(ped, weapon, false) then
        AddAmmoToPed(ped, weapon, ammo)
    end
end

TMC.Functions.GetWeaponAmmo = function(weaponName)
    local weapon = joaat(weaponName)
    return GetAmmoInPedWeapon(PlayerPedId(), weapon)
end

-- ── Vehicle Client Utilities ──

TMC.Functions.GetClosestVehicleEx = function(distance)
    distance = distance or 50.0
    local playerCoords = GetEntityCoords(PlayerPedId())
    local closestVeh = nil
    local closestDist = distance
    
    for _, veh in ipairs(GetGamePool('CVehicle')) do
        local dist = #(playerCoords - GetEntityCoords(veh))
        if dist < closestDist then
            closestVeh = veh
            closestDist = dist
        end
    end
    
    return closestVeh, closestDist
end

TMC.Functions.IsPlayerInVehicle = function()
    return GetVehiclePedIsIn(PlayerPedId(), false) ~= 0
end

TMC.Functions.GetPlayerVehicle = function()
    local veh = GetVehiclePedIsIn(PlayerPedId(), false)
    if veh ~= 0 then return veh end
    return nil
end

TMC.Functions.GetVehicleSpeed = function(vehicle)
    if not DoesEntityExist(vehicle) then return 0 end
    local speed = GetEntitySpeed(vehicle)
    return math.ceil(speed * 3.6 * 10) / 10 -- Convert to km/h
end

TMC.Functions.IsVehicleDriveable = function(vehicle)
    if not DoesEntityExist(vehicle) then return false end
    return (GetVehicleEngineHealth(vehicle) + 0.0) > 100.0
end

-- ── Advanced Location & Traversal ──

TMC.Functions.GetLocationName = function(coords)
    local zoneName = GetLabelText(GetNameOfZone(coords.x, coords.y, coords.z))
    local streetName, crossingRoad = GetStreetNameAtCoord(coords.x, coords.y, coords.z)
    return GetStreetNameFromHashKey(streetName)
end

TMC.Functions.GetCardinalDirection = function(entity)
    entity = entity or PlayerPedId()
    local heading = GetEntityHeading(entity)
    if heading >= 315.0 or heading < 45.0 then return 'North'
    elseif heading >= 45.0 and heading < 135.0 then return 'West'
    elseif heading >= 135.0 and heading < 225.0 then return 'South'
    else return 'East'
    end
end

TMC.Functions.GetPlayersNearPlayer = function(distance)
    distance = distance or 50.0
    local playerCoords = GetEntityCoords(PlayerPedId())
    local nearbyPlayers = {}
    
    for _, player in ipairs(GetActivePlayers()) do
        if player ~= PlayerId() then
            local ped = GetPlayerPed(player)
            if DoesEntityExist(ped) then
                local dist = #(playerCoords - GetEntityCoords(ped))
                if dist < distance then
                    table.insert(nearbyPlayers, {player = player, dist = dist})
                end
            end
        end
    end
    
    table.sort(nearbyPlayers, function(a, b) return a.dist < b.dist end)
    return nearbyPlayers
end

-- ═══════════════════════════════════════
-- Event Handlers (Forward UME → TMC)
-- ═══════════════════════════════════════

-- Player loaded
RegisterNetEvent('umeverse:client:playerLoaded:done', function(playerData)
    RefreshPlayerData()
    TriggerEvent('TMC:Client:OnPlayerLoaded')
    TriggerEvent('QBCore:Client:OnPlayerLoaded')
    TriggerEvent('TMC:Client:PlayerLoaded', TMC.PlayerData)
end)

-- Player logout
RegisterNetEvent('umeverse:client:logout', function()
    TMC.PlayerData = {}
    TriggerEvent('TMC:Client:OnPlayerUnload')
    TriggerEvent('QBCore:Client:OnPlayerUnload')
end)

-- Job change
RegisterNetEvent('TMC:Client:SetJob', function(job)
    TMC.PlayerData.job = job
    TriggerEvent('QBCore:Client:SetJob', job)
end)

RegisterNetEvent('TMC:Client:SetGang', function(gang)
    TMC.PlayerData.gang = gang
    TriggerEvent('QBCore:Client:SetGang', gang)
end)

-- Player data sync
RegisterNetEvent('TMC:Client:OnPlayerLoaded', function()
    RefreshPlayerData()
end)

RegisterNetEvent('QBCore:Player:SetPlayerData', function(data)
    if data then
        TMC.PlayerData = data
    else
        RefreshPlayerData()
    end
end)

-- Metadata change from server
RegisterNetEvent('TMC:Client:SetMetaData', function(key, value)
    TMC.PlayerData.metadata = TMC.PlayerData.metadata or {}
    TMC.PlayerData.metadata[key] = value
end)

RegisterNetEvent('TMC:Client:SyncMetaData', function(key, value)
    TMC.PlayerData.metadata = TMC.PlayerData.metadata or {}
    TMC.PlayerData.metadata[key] = value
end)

-- Money change
RegisterNetEvent('TMC:Client:OnMoneyChange', function(moneyType, amount, operation)
    RefreshPlayerData()
end)

-- Simple notify (triggered via event)
RegisterNetEvent('TMC:SimpleNotify', function(text, texttype)
    TMC.Functions.SimpleNotify(text, texttype)
end)

-- ═══════════════════════════════════════
-- Export
-- ═══════════════════════════════════════

exports('GetCoreObject', function()
    return TMC
end)

-- Initial data load on resource start
CreateThread(function()
    Wait(1000)
    RefreshPlayerData()
    print('[TMC Bridge] Client initialized')
end)
