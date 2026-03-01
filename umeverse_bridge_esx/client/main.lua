--[[
    Umeverse Bridge - ESX Client
    Emulates ESX client-side API using Umeverse functions
]]

local UME = exports['umeverse_core']:GetCoreObject()

-- ═══════════════════════════════════════
-- PlayerData Cache
-- ═══════════════════════════════════════

local function RefreshPlayerData()
    local pd = UME.GetPlayerData()
    if pd then
        ESX.PlayerLoaded = true
        ESX.PlayerData = {
            identifier  = pd.identifier,
            accounts    = {
                { name = 'money',       money = pd.money and pd.money.cash or 0, label = 'Money' },
                { name = 'bank',        money = pd.money and pd.money.bank or 0, label = 'Bank' },
                { name = 'black_money', money = 0, label = 'Dirty Money' },
            },
            coords      = pd.position or vector3(0, 0, 0),
            inventory   = {},
            job = {
                name        = pd.job and pd.job.name or 'unemployed',
                label       = pd.job and pd.job.label or 'Unemployed',
                grade       = pd.job and pd.job.grade or 0,
                grade_name  = pd.job and pd.job.gradelabel or 'None',
                grade_label = pd.job and pd.job.gradelabel or 'None',
                grade_salary = 0,
                skin_male   = {},
                skin_female = {},
            },
            loadout     = {},
            money       = pd.money and pd.money.cash or 0,
            sex         = pd.charinfo and pd.charinfo.gender or 'male',
            firstName   = pd.firstname or '',
            lastName    = pd.lastname or '',
            dateofbirth = pd.charinfo and pd.charinfo.birthdate or '1990-01-01',
            height      = pd.charinfo and pd.charinfo.height or 170,
        }

        -- Map inventory
        if pd.inventory then
            for i, item in ipairs(pd.inventory) do
                ESX.PlayerData.inventory[#ESX.PlayerData.inventory + 1] = {
                    name   = item.name,
                    count  = item.amount,
                    label  = item.label or item.name,
                    weight = item.weight or 0,
                    rare   = false,
                    canRemove = true,
                    usable = true,
                }
            end
        end
    end
    return ESX.PlayerData
end

-- ═══════════════════════════════════════
-- ESX Client Functions
-- ═══════════════════════════════════════

--- Check if player is loaded
function ESX.IsPlayerLoaded()
    return ESX.PlayerLoaded
end

--- Get player data
function ESX.GetPlayerData()
    RefreshPlayerData()
    return ESX.PlayerData
end

--- Set player data (local cache key)
function ESX.SetPlayerData(key, val)
    ESX.PlayerData[key] = val
end

--- Show notification
function ESX.ShowNotification(msg, flash, saveToBrief, hudColorIndex)
    UME.Notify(msg, 'info', 5000)
end

--- Show advanced notification
function ESX.ShowAdvancedNotification(sender, subject, msg, textureDict, iconType, flash, saveToBrief, hudColorIndex)
    UME.Notify(msg, 'info', 5000)
end

--- Show help notification
function ESX.ShowHelpNotification(msg, thisFrame, beep, duration)
    if thisFrame then
        AddTextEntry('esxHelpNotification', msg)
        DisplayHelpTextThisFrame('esxHelpNotification', false)
    else
        BeginTextCommandDisplayHelp('STRING')
        AddTextComponentSubstringPlayerName(msg)
        EndTextCommandDisplayHelp(0, false, beep or true, duration or 5000)
    end
end

--- Show floating help notification
function ESX.ShowFloatingHelpNotification(msg, coords)
    AddTextEntry('esxFloatingHelpNotification', msg)
    SetFloatingHelpTextWorldPosition(1, coords.x, coords.y, coords.z)
    SetFloatingHelpTextStyle(1, 1, 2, -1, 3, 0)
    BeginTextCommandDisplayHelp('esxFloatingHelpNotification')
    EndTextCommandDisplayHelp(2, false, false, -1)
end

--- Trigger a server callback
function ESX.TriggerServerCallback(name, cb, ...)
    UME.TriggerServerCallback(name, cb, ...)
end

--- Get account data
function ESX.GetAccount(name)
    RefreshPlayerData()
    for _, acc in ipairs(ESX.PlayerData.accounts or {}) do
        if acc.name == name then
            return acc
        end
    end
    return nil
end

--- Search inventory
function ESX.SearchInventory(item, count)
    RefreshPlayerData()
    for _, invItem in ipairs(ESX.PlayerData.inventory or {}) do
        if invItem.name == item then
            return invItem.count
        end
    end
    return 0
end

--- Get inventory item
function ESX.GetInventoryItem(item)
    RefreshPlayerData()
    for _, invItem in ipairs(ESX.PlayerData.inventory or {}) do
        if invItem.name == item then
            return invItem
        end
    end
    return { name = item, count = 0, label = item, weight = 0, rare = false, canRemove = true }
end

-- ═══════════════════════════════════════
-- ESX.Game - Common game utilities
-- ═══════════════════════════════════════

ESX.Game = {}

--- Get closest player
function ESX.Game.GetClosestPlayer(coords)
    coords = coords or GetEntityCoords(PlayerPedId())
    local closestPlayer, closestDist = -1, -1.0

    local players = GetActivePlayers()
    for _, playerId in ipairs(players) do
        if playerId ~= PlayerId() then
            local ped = GetPlayerPed(playerId)
            local pos = GetEntityCoords(ped)
            local dist = #(coords - pos)
            if closestDist == -1 or dist < closestDist then
                closestPlayer = GetPlayerServerId(playerId)
                closestDist = dist
            end
        end
    end
    return closestPlayer, closestDist
end

--- Get players in area
function ESX.Game.GetPlayersInArea(coords, maxDistance)
    local result = {}
    local players = GetActivePlayers()
    for _, playerId in ipairs(players) do
        local ped = GetPlayerPed(playerId)
        local pos = GetEntityCoords(ped)
        if #(coords - pos) <= maxDistance then
            result[#result + 1] = playerId
        end
    end
    return result
end

--- Get closest vehicle
function ESX.Game.GetClosestVehicle(coords)
    coords = coords or GetEntityCoords(PlayerPedId())
    local vehicles = GetGamePool('CVehicle')
    local closestVeh, closestDist = 0, -1

    for _, veh in ipairs(vehicles) do
        local pos = GetEntityCoords(veh)
        local dist = #(coords - pos)
        if closestDist == -1 or dist < closestDist then
            closestVeh = veh
            closestDist = dist
        end
    end
    return closestVeh, closestDist
end

--- Get closest object
function ESX.Game.GetClosestObject(coords, modelFilter)
    coords = coords or GetEntityCoords(PlayerPedId())
    local objects = GetGamePool('CObject')
    local closestObj, closestDist = 0, -1

    for _, obj in ipairs(objects) do
        local pos = GetEntityCoords(obj)
        local dist = #(coords - pos)
        if closestDist == -1 or dist < closestDist then
            if not modelFilter or GetEntityModel(obj) == joaat(modelFilter) then
                closestObj = obj
                closestDist = dist
            end
        end
    end
    return closestObj, closestDist
end

--- Get closest ped
function ESX.Game.GetClosestPed(coords, ignorePlayerPeds)
    coords = coords or GetEntityCoords(PlayerPedId())
    local peds = GetGamePool('CPed')
    local closestPed, closestDist = 0, -1

    for _, ped in ipairs(peds) do
        if not ignorePlayerPeds or not IsPedAPlayer(ped) then
            if ped ~= PlayerPedId() then
                local pos = GetEntityCoords(ped)
                local dist = #(coords - pos)
                if closestDist == -1 or dist < closestDist then
                    closestPed = ped
                    closestDist = dist
                end
            end
        end
    end
    return closestPed, closestDist
end

--- Get vehicles in area
function ESX.Game.GetVehiclesInArea(coords, maxDistance)
    local result = {}
    local vehicles = GetGamePool('CVehicle')
    for _, veh in ipairs(vehicles) do
        local pos = GetEntityCoords(veh)
        if #(coords - pos) <= maxDistance then
            result[#result + 1] = veh
        end
    end
    return result
end

--- Get peds in area
function ESX.Game.GetPedsInArea(coords, maxDistance)
    local result = {}
    local peds = GetGamePool('CPed')
    for _, ped in ipairs(peds) do
        local pos = GetEntityCoords(ped)
        if #(coords - pos) <= maxDistance then
            result[#result + 1] = ped
        end
    end
    return result
end

--- Is vehicle empty
function ESX.Game.IsVehicleEmpty(vehicle)
    local passengers = GetVehicleNumberOfPassengers(vehicle)
    if IsVehicleSeatFree(vehicle, -1) and passengers == 0 then
        return true
    end
    return false
end

--- Get vehicle properties (mods, colors, etc.)
function ESX.Game.GetVehicleProperties(vehicle)
    if not DoesEntityExist(vehicle) then return nil end

    local colorPrimary, colorSecondary = GetVehicleColours(vehicle)
    local pearlescentColor, wheelColor = GetVehicleExtraColours(vehicle)
    local hasCustomPrimaryColour = GetIsVehiclePrimaryColourCustom(vehicle)
    local hasCustomSecondaryColour = GetIsVehicleSecondaryColourCustom(vehicle)

    local props = {
        model            = GetEntityModel(vehicle),
        plate            = GetVehicleNumberPlateText(vehicle),
        plateIndex       = GetVehicleNumberPlateTextIndex(vehicle),
        bodyHealth       = math.floor(GetVehicleBodyHealth(vehicle) + 0.5),
        engineHealth     = math.floor(GetVehicleEngineHealth(vehicle) + 0.5),
        tankHealth       = math.floor(GetVehiclePetrolTankHealth(vehicle) + 0.5),
        fuelLevel        = math.floor(GetVehicleFuelLevel(vehicle) + 0.5),
        dirtLevel        = math.floor(GetVehicleDirtLevel(vehicle) + 0.5),
        color1           = colorPrimary,
        color2           = colorSecondary,
        pearlescentColor = pearlescentColor,
        wheelColor       = wheelColor,
        dashboardColor   = GetVehicleDashboardColour(vehicle),
        interiorColor    = GetVehicleInteriorColour(vehicle),
        wheels           = GetVehicleWheelType(vehicle),
        windowTint       = GetVehicleWindowTint(vehicle),
        xenonColor       = GetVehicleXenonLightsColour(vehicle),
        neonEnabled      = {
            IsVehicleNeonLightEnabled(vehicle, 0),
            IsVehicleNeonLightEnabled(vehicle, 1),
            IsVehicleNeonLightEnabled(vehicle, 2),
            IsVehicleNeonLightEnabled(vehicle, 3),
        },
        extras  = {},
        modSpoilers        = GetVehicleMod(vehicle, 0),
        modFrontBumper      = GetVehicleMod(vehicle, 1),
        modRearBumper       = GetVehicleMod(vehicle, 2),
        modSideSkirt        = GetVehicleMod(vehicle, 3),
        modExhaust          = GetVehicleMod(vehicle, 4),
        modFrame            = GetVehicleMod(vehicle, 5),
        modGrille           = GetVehicleMod(vehicle, 6),
        modHood             = GetVehicleMod(vehicle, 7),
        modFender           = GetVehicleMod(vehicle, 8),
        modRightFender      = GetVehicleMod(vehicle, 9),
        modRoof             = GetVehicleMod(vehicle, 10),
        modEngine           = GetVehicleMod(vehicle, 11),
        modBrakes           = GetVehicleMod(vehicle, 12),
        modTransmission     = GetVehicleMod(vehicle, 13),
        modHorns            = GetVehicleMod(vehicle, 14),
        modSuspension       = GetVehicleMod(vehicle, 15),
        modArmor            = GetVehicleMod(vehicle, 16),
        modTurbo            = IsToggleModOn(vehicle, 18),
        modSmokeEnabled     = IsToggleModOn(vehicle, 20),
        modXenon            = IsToggleModOn(vehicle, 22),
        modFrontWheels       = GetVehicleMod(vehicle, 23),
        modBackWheels        = GetVehicleMod(vehicle, 24),
        modLivery            = GetVehicleMod(vehicle, 48) == -1 and GetVehicleLivery(vehicle) or GetVehicleMod(vehicle, 48),
    }

    if hasCustomPrimaryColour then
        local r, g, b = GetVehicleCustomPrimaryColour(vehicle)
        props.customPrimaryColor = { r, g, b }
    end

    if hasCustomSecondaryColour then
        local r, g, b = GetVehicleCustomSecondaryColour(vehicle)
        props.customSecondaryColor = { r, g, b }
    end

    local neonR, neonG, neonB = GetVehicleNeonLightsColour(vehicle)
    props.neonColor = { neonR, neonG, neonB }

    local tyreSmokeR, tyreSmokeG, tyreSmokeB = GetVehicleTyreSmokeColor(vehicle)
    props.tyreSmokeColor = { tyreSmokeR, tyreSmokeG, tyreSmokeB }

    for i = 0, 14 do
        if DoesExtraExist(vehicle, i) then
            props.extras[tostring(i)] = IsVehicleExtraTurnedOn(vehicle, i)
        end
    end

    return props
end

--- Set vehicle properties (mods, colors, etc.)
function ESX.Game.SetVehicleProperties(vehicle, props)
    if not DoesEntityExist(vehicle) or not props then return end

    if props.plate then SetVehicleNumberPlateText(vehicle, props.plate) end
    if props.plateIndex then SetVehicleNumberPlateTextIndex(vehicle, props.plateIndex) end
    if props.bodyHealth then SetVehicleBodyHealth(vehicle, props.bodyHealth + 0.0) end
    if props.engineHealth then SetVehicleEngineHealth(vehicle, props.engineHealth + 0.0) end
    if props.tankHealth then SetVehiclePetrolTankHealth(vehicle, props.tankHealth + 0.0) end
    if props.fuelLevel then SetVehicleFuelLevel(vehicle, props.fuelLevel + 0.0) end
    if props.dirtLevel then SetVehicleDirtLevel(vehicle, props.dirtLevel + 0.0) end
    if props.color1 ~= nil and props.color2 ~= nil then SetVehicleColours(vehicle, props.color1, props.color2) end
    if props.pearlescentColor ~= nil and props.wheelColor ~= nil then SetVehicleExtraColours(vehicle, props.pearlescentColor, props.wheelColor) end
    if props.wheels ~= nil then SetVehicleWheelType(vehicle, props.wheels) end
    if props.windowTint ~= nil then SetVehicleWindowTint(vehicle, props.windowTint) end

    if props.neonEnabled then
        SetVehicleNeonLightEnabled(vehicle, 0, props.neonEnabled[1])
        SetVehicleNeonLightEnabled(vehicle, 1, props.neonEnabled[2])
        SetVehicleNeonLightEnabled(vehicle, 2, props.neonEnabled[3])
        SetVehicleNeonLightEnabled(vehicle, 3, props.neonEnabled[4])
    end

    if props.neonColor then SetVehicleNeonLightsColour(vehicle, props.neonColor[1], props.neonColor[2], props.neonColor[3]) end
    if props.xenonColor then SetVehicleXenonLightsColour(vehicle, props.xenonColor) end
    if props.tyreSmokeColor then SetVehicleTyreSmokeColor(vehicle, props.tyreSmokeColor[1], props.tyreSmokeColor[2], props.tyreSmokeColor[3]) end

    if props.customPrimaryColor then SetVehicleCustomPrimaryColour(vehicle, props.customPrimaryColor[1], props.customPrimaryColor[2], props.customPrimaryColor[3]) end
    if props.customSecondaryColor then SetVehicleCustomSecondaryColour(vehicle, props.customSecondaryColor[1], props.customSecondaryColor[2], props.customSecondaryColor[3]) end

    if props.modSpoilers ~= nil then SetVehicleMod(vehicle, 0, props.modSpoilers, false) end
    if props.modFrontBumper ~= nil then SetVehicleMod(vehicle, 1, props.modFrontBumper, false) end
    if props.modRearBumper ~= nil then SetVehicleMod(vehicle, 2, props.modRearBumper, false) end
    if props.modSideSkirt ~= nil then SetVehicleMod(vehicle, 3, props.modSideSkirt, false) end
    if props.modExhaust ~= nil then SetVehicleMod(vehicle, 4, props.modExhaust, false) end
    if props.modFrame ~= nil then SetVehicleMod(vehicle, 5, props.modFrame, false) end
    if props.modGrille ~= nil then SetVehicleMod(vehicle, 6, props.modGrille, false) end
    if props.modHood ~= nil then SetVehicleMod(vehicle, 7, props.modHood, false) end
    if props.modFender ~= nil then SetVehicleMod(vehicle, 8, props.modFender, false) end
    if props.modRightFender ~= nil then SetVehicleMod(vehicle, 9, props.modRightFender, false) end
    if props.modRoof ~= nil then SetVehicleMod(vehicle, 10, props.modRoof, false) end
    if props.modEngine ~= nil then SetVehicleMod(vehicle, 11, props.modEngine, false) end
    if props.modBrakes ~= nil then SetVehicleMod(vehicle, 12, props.modBrakes, false) end
    if props.modTransmission ~= nil then SetVehicleMod(vehicle, 13, props.modTransmission, false) end
    if props.modHorns ~= nil then SetVehicleMod(vehicle, 14, props.modHorns, false) end
    if props.modSuspension ~= nil then SetVehicleMod(vehicle, 15, props.modSuspension, false) end
    if props.modArmor ~= nil then SetVehicleMod(vehicle, 16, props.modArmor, false) end
    if props.modTurbo ~= nil then ToggleVehicleMod(vehicle, 18, props.modTurbo) end
    if props.modSmokeEnabled ~= nil then ToggleVehicleMod(vehicle, 20, props.modSmokeEnabled) end
    if props.modXenon ~= nil then ToggleVehicleMod(vehicle, 22, props.modXenon) end
    if props.modFrontWheels ~= nil then SetVehicleMod(vehicle, 23, props.modFrontWheels, false) end
    if props.modBackWheels ~= nil then SetVehicleMod(vehicle, 24, props.modBackWheels, false) end
    if props.modLivery ~= nil then
        SetVehicleMod(vehicle, 48, props.modLivery, false)
        SetVehicleLivery(vehicle, props.modLivery)
    end

    if props.extras then
        for id, enabled in pairs(props.extras) do
            SetVehicleExtra(vehicle, tonumber(id), not enabled)
        end
    end

    if props.dashboardColor then SetVehicleDashboardColour(vehicle, props.dashboardColor) end
    if props.interiorColor then SetVehicleInteriorColour(vehicle, props.interiorColor) end
end

--- Spawn a vehicle (client-side)
function ESX.Game.SpawnVehicle(modelName, coords, heading, cb, isNetwork, netMissionEntity)
    local model = type(modelName) == 'string' and joaat(modelName) or modelName
    coords = coords or GetEntityCoords(PlayerPedId())
    heading = heading or 0.0

    if not IsModelInCdimage(model) then
        if cb then cb(nil) end
        return
    end

    RequestModel(model)
    local timeout = 0
    while not HasModelLoaded(model) do
        Wait(10)
        timeout = timeout + 10
        if timeout > 5000 then
            if cb then cb(nil) end
            return
        end
    end

    local vehicle = CreateVehicle(model, coords.x, coords.y, coords.z, heading, isNetwork ~= false, netMissionEntity or false)
    SetModelAsNoLongerNeeded(model)

    if cb then cb(vehicle) end
end

--- Spawn local vehicle
function ESX.Game.SpawnLocalVehicle(modelName, coords, heading, cb)
    ESX.Game.SpawnVehicle(modelName, coords, heading, cb, false, false)
end

--- Delete vehicle
function ESX.Game.DeleteVehicle(vehicle)
    SetEntityAsMissionEntity(vehicle, true, true)
    DeleteVehicle(vehicle)
end

--- Get vehicle in direction (raycast)
function ESX.Game.GetVehicleInDirection()
    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    local forward = GetEntityForwardVector(ped)
    local far = coords + forward * 5.0

    local ray = StartShapeTestRay(coords.x, coords.y, coords.z, far.x, far.y, far.z, 10, ped, 0)
    local _, hit, _, _, entity = GetShapeTestResult(ray)

    if hit == 1 and IsEntityAVehicle(entity) then
        return entity
    end
    return nil
end

--- Teleport player
function ESX.Game.Teleport(entity, coords, cb)
    RequestCollisionAtCoord(coords.x, coords.y, coords.z)
    local timeout = 0
    while not HasCollisionLoadedAroundEntity(entity) and timeout < 2000 do
        Wait(10)
        timeout = timeout + 10
    end

    SetEntityCoords(entity, coords.x, coords.y, coords.z, false, false, false, false)
    if coords.w or coords.heading then
        SetEntityHeading(entity, coords.w or coords.heading)
    end

    if cb then cb() end
end

--- Spawn an object
function ESX.Game.SpawnObject(model, coords, cb, isNetwork)
    model = type(model) == 'string' and joaat(model) or model
    RequestModel(model)

    local timeout = 0
    while not HasModelLoaded(model) do
        Wait(10)
        timeout = timeout + 10
        if timeout > 5000 then
            if cb then cb(nil) end
            return
        end
    end

    local obj = CreateObject(model, coords.x, coords.y, coords.z, isNetwork ~= false, false, true)
    SetModelAsNoLongerNeeded(model)

    if cb then cb(obj) end
end

--- Spawn local object
function ESX.Game.SpawnLocalObject(model, coords, cb)
    ESX.Game.SpawnObject(model, coords, cb, false)
end

--- Delete object
function ESX.Game.DeleteObject(object)
    SetEntityAsMissionEntity(object, true, true)
    DeleteObject(object)
end

--- Get hash from string
function ESX.Game.GetHash(str)
    return joaat(str)
end

-- ═══════════════════════════════════════
-- ESX.Streaming Utilities
-- ═══════════════════════════════════════

ESX.Streaming = {}

function ESX.Streaming.RequestModel(model, cb)
    model = type(model) == 'string' and joaat(model) or model
    if not IsModelInCdimage(model) then
        if cb then cb() end
        return
    end
    RequestModel(model)
    local timeout = 0
    while not HasModelLoaded(model) and timeout < 5000 do Wait(10); timeout = timeout + 10 end
    if cb then cb() end
end

function ESX.Streaming.RequestAnimDict(animDict, cb)
    if HasAnimDictLoaded(animDict) then
        if cb then cb() end
        return
    end
    RequestAnimDict(animDict)
    local timeout = 0
    while not HasAnimDictLoaded(animDict) and timeout < 5000 do Wait(10); timeout = timeout + 10 end
    if cb then cb() end
end

function ESX.Streaming.RequestAnimSet(animSet, cb)
    if HasAnimSetLoaded(animSet) then
        if cb then cb() end
        return
    end
    RequestAnimSet(animSet)
    local timeout = 0
    while not HasAnimSetLoaded(animSet) and timeout < 5000 do Wait(10); timeout = timeout + 10 end
    if cb then cb() end
end

function ESX.Streaming.RequestNamedPtfxAsset(ptfxName, cb)
    if HasNamedPtfxAssetLoaded(ptfxName) then
        if cb then cb() end
        return
    end
    RequestNamedPtfxAsset(ptfxName)
    local timeout = 0
    while not HasNamedPtfxAssetLoaded(ptfxName) and timeout < 5000 do Wait(10); timeout = timeout + 10 end
    if cb then cb() end
end

function ESX.Streaming.RequestTextureDict(textureDict, cb)
    if HasStreamedTextureDictLoaded(textureDict) then
        if cb then cb() end
        return
    end
    RequestStreamedTextureDict(textureDict, false)
    local timeout = 0
    while not HasStreamedTextureDictLoaded(textureDict) and timeout < 5000 do Wait(10); timeout = timeout + 10 end
    if cb then cb() end
end

-- ═══════════════════════════════════════
-- ESX.UI
-- ═══════════════════════════════════════

ESX.UI = {}
ESX.UI.Menu = {}
ESX.UI.Menu.Opened = {}

function ESX.UI.Menu.Open(menuType, namespace, name, data, submit, cancel, change, close)
    -- ESX menus are not natively supported, stub
    return nil
end

function ESX.UI.Menu.Close(menuType, namespace, name)
    -- Stub
end

function ESX.UI.Menu.CloseAll()
    -- Stub
end

function ESX.UI.Menu.GetOpened(menuType, namespace, name)
    return nil
end

function ESX.UI.Menu.IsOpen(menuType, namespace, name)
    return false
end

function ESX.UI.ShowInventory()
    -- Trigger Umeverse inventory instead
    TriggerEvent('umeverse:client:openInventory')
end

-- ═══════════════════════════════════════
-- Event Forwarding
-- ═══════════════════════════════════════

-- When Umeverse signals player loaded, fire ESX events
RegisterNetEvent('umeverse:client:playerLoaded:done', function()
    RefreshPlayerData()
    ESX.PlayerLoaded = true
    TriggerEvent('esx:playerLoaded', ESX.PlayerData)
end)

-- When Umeverse signals logout, fire ESX event
RegisterNetEvent('umeverse:client:logout', function()
    ESX.PlayerData = {}
    ESX.PlayerLoaded = false
    TriggerEvent('esx:onPlayerLogout')
end)

-- When Umeverse signals job change, fire ESX event
RegisterNetEvent('umeverse:client:jobChanged', function(job)
    RefreshPlayerData()
    TriggerEvent('esx:setJob', ESX.PlayerData.job)
end)

-- When Umeverse syncs player data, update cache
RegisterNetEvent('umeverse:client:syncPlayerData', function(data)
    RefreshPlayerData()
end)

-- Legacy ESX client-side getSharedObject
RegisterNetEvent('esx:getSharedObject', function()
    -- Handled via export
end)

--- Handle esx:playerLoaded from server bridge
RegisterNetEvent('esx:playerLoaded', function(job, accounts, coords)
    -- PlayerData already synced via RefreshPlayerData()
end)

--- Handle esx:setJob from server bridge
RegisterNetEvent('esx:setJob', function(job)
    if ESX.PlayerData then
        ESX.PlayerData.job = job
    end
end)

-- ═══════════════════════════════════════
-- Exports
-- ═══════════════════════════════════════

exports('getSharedObject', function()
    return ESX
end)

_G.ESX = ESX
