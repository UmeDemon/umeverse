--[[
    Umeverse Bridge - QBCore Client
    Emulates QBCore client-side API using Umeverse functions
]]

local UME = exports['umeverse_core']:GetCoreObject()

-- ═══════════════════════════════════════
-- PlayerData Cache
-- ═══════════════════════════════════════

QBCore.PlayerData = {}

local function RefreshPlayerData()
    local pd = UME.GetPlayerData()
    if pd then
        QBCore.PlayerData = {
            source      = pd.source or GetPlayerServerId(PlayerId()),
            citizenid   = pd.citizenid,
            license     = pd.identifier,
            name        = pd.name or '',
            charinfo    = {
                firstname   = pd.firstname or '',
                lastname    = pd.lastname or '',
                birthdate   = pd.charinfo and pd.charinfo.birthdate or '1990-01-01',
                gender      = pd.charinfo and pd.charinfo.gender == 'female' and 1 or 0,
                nationality = pd.charinfo and pd.charinfo.nationality or 'American',
                phone       = pd.charinfo and pd.charinfo.phone or '',
                account     = pd.charinfo and pd.charinfo.account or '',
            },
            money = {
                cash   = pd.money and pd.money.cash or 0,
                bank   = pd.money and pd.money.bank or 0,
                crypto = 0,
            },
            job = {
                name    = pd.job and pd.job.name or 'unemployed',
                label   = pd.job and pd.job.label or 'Unemployed',
                payment = 0,
                type    = pd.job and pd.job.type or nil,
                onduty  = pd.job and pd.job.onduty or false,
                isboss  = false,
                grade   = {
                    name  = pd.job and pd.job.gradelabel or 'None',
                    level = pd.job and pd.job.grade or 0,
                },
            },
            gang = {
                name   = 'none',
                label  = 'No Gang',
                isboss = false,
                grade  = { name = 'none', level = 0 },
            },
            position = pd.position,
            metadata = pd.metadata or {},
            items    = pd.inventory or {},
        }
    end
    return QBCore.PlayerData
end

-- ═══════════════════════════════════════
-- QBCore.Functions (Client)
-- ═══════════════════════════════════════

--- Get player data
function QBCore.Functions.GetPlayerData(cb)
    RefreshPlayerData()
    if cb then
        cb(QBCore.PlayerData)
    end
    return QBCore.PlayerData
end

--- Notify the player
function QBCore.Functions.Notify(text, notifyType, duration, subTitle, notifyPosition, notifyStyle, notifyIcon)
    if type(text) == 'table' then
        -- QB can pass {text, type} tables
        UME.Notify(text.text or text[1], text.type or text[2], text.length or duration)
    else
        UME.Notify(text, notifyType, duration)
    end
end

--- Trigger a server callback
function QBCore.Functions.TriggerCallback(name, cb, ...)
    UME.TriggerServerCallback(name, cb, ...)
end

--- Check if player has an item
function QBCore.Functions.HasItem(item, amount)
    amount = amount or 1
    RefreshPlayerData()
    if type(item) == 'table' then
        for _, itemName in ipairs(item) do
            local found = false
            for _, invItem in ipairs(QBCore.PlayerData.items or {}) do
                if invItem.name == itemName and invItem.amount >= amount then
                    found = true
                    break
                end
            end
            if not found then return false end
        end
        return true
    else
        for _, invItem in ipairs(QBCore.PlayerData.items or {}) do
            if invItem.name == item and invItem.amount >= amount then
                return true
            end
        end
        return false
    end
end

--- Progress bar (simplified)
function QBCore.Functions.Progressbar(name, label, duration, useWhileDead, canCancel, disableControls, animation, prop, propTwo, onFinish, onCancel)
    -- Simple timer-based progress
    Citizen.SetTimeout(duration, function()
        if onFinish then onFinish() end
    end)
end

--- Get closest player
function QBCore.Functions.GetClosestPlayer(coords)
    coords = coords or GetEntityCoords(PlayerPedId())
    local closestPlayer, closestDist = -1, -1

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
function QBCore.Functions.GetPlayersFromCoords(coords, distance)
    coords = coords or GetEntityCoords(PlayerPedId())
    distance = distance or 5.0
    local result = {}

    local players = GetActivePlayers()
    for _, playerId in ipairs(players) do
        local ped = GetPlayerPed(playerId)
        local pos = GetEntityCoords(ped)
        if #(coords - pos) <= distance then
            result[#result + 1] = GetPlayerServerId(playerId)
        end
    end
    return result
end

--- Get ped by server id
function QBCore.Functions.GetPed(serverId)
    return GetPlayerPed(GetPlayerFromServerId(serverId))
end

--- Draw text on screen (3D)
function QBCore.Functions.DrawText3D(x, y, z, text)
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

--- Get the closest entity of a given type
function QBCore.Functions.GetClosestObject(coords)
    return QBCore.Functions.GetClosestEntity(coords, 3) -- OBJECT
end

function QBCore.Functions.GetClosestVehicle(coords)
    return QBCore.Functions.GetClosestEntity(coords, 2) -- VEHICLE
end

function QBCore.Functions.GetClosestPed(coords)
    return QBCore.Functions.GetClosestEntity(coords, 1) -- PED
end

function QBCore.Functions.GetClosestEntity(coords, entityType)
    coords = coords or GetEntityCoords(PlayerPedId())
    local entities, closest, closestDist = {}, 0, -1

    if entityType == 1 then
        entities = GetGamePool('CPed')
    elseif entityType == 2 then
        entities = GetGamePool('CVehicle')
    elseif entityType == 3 then
        entities = GetGamePool('CObject')
    end

    for _, entity in ipairs(entities) do
        local pos = GetEntityCoords(entity)
        local dist = #(coords - pos)
        if closestDist == -1 or dist < closestDist then
            closest = entity
            closestDist = dist
        end
    end
    return closest, closestDist
end

--- Get street name label at coords
function QBCore.Functions.GetStreetNametAtCoords(coords)
    local streetHash, crossHash = GetStreetNameAtCoord(coords.x, coords.y, coords.z)
    return { main = GetStreetNameFromHashKey(streetHash), cross = GetStreetNameFromHashKey(crossHash) }
end

--- Get zone at coords
function QBCore.Functions.GetZoneAtCoords(coords)
    return GetLabelText(GetNameOfZone(coords.x, coords.y, coords.z))
end

--- Spawn a vehicle (client-side)
function QBCore.Functions.SpawnVehicle(model, cb, coords, isNetwork, netMissionEntity)
    model = type(model) == 'string' and joaat(model) or model
    coords = coords or GetEntityCoords(PlayerPedId())

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

    local veh = CreateVehicle(model, coords.x, coords.y, coords.z, coords.w or 0.0, isNetwork ~= false, netMissionEntity or false)
    SetModelAsNoLongerNeeded(model)

    if cb then cb(veh) end
end

--- Delete a vehicle
function QBCore.Functions.DeleteVehicle(vehicle)
    SetEntityAsMissionEntity(vehicle, true, true)
    DeleteVehicle(vehicle)
end

--- Get plate from vehicle
function QBCore.Functions.GetPlate(vehicle)
    if vehicle and vehicle ~= 0 then
        return string.trim(GetVehicleNumberPlateText(vehicle))
    end
    return nil
end

--- Spawn clear area of vehicles
function QBCore.Functions.SpawnClear(coords, radius)
    coords = coords or GetEntityCoords(PlayerPedId())
    radius = radius or 5.0
    local vehicles = GetGamePool('CVehicle')
    for _, veh in ipairs(vehicles) do
        local pos = GetEntityCoords(veh)
        if #(coords - pos) < radius then
            return false
        end
    end
    return true
end

--- Load model utility
function QBCore.Functions.LoadModel(model)
    model = type(model) == 'string' and joaat(model) or model
    if IsModelInCdimage(model) then
        RequestModel(model)
        while not HasModelLoaded(model) do
            Wait(0)
        end
    end
end

--- Load animation dict utility
function QBCore.Functions.LoadAnimDict(animDict)
    if HasAnimDictLoaded(animDict) then return end
    RequestAnimDict(animDict)
    while not HasAnimDictLoaded(animDict) do
        Wait(0)
    end
end

--- Load particle dict utility
function QBCore.Functions.LoadParticleDictionary(dict)
    if HasNamedPtfxAssetLoaded(dict) then return end
    RequestNamedPtfxAsset(dict)
    while not HasNamedPtfxAssetLoaded(dict) do
        Wait(0)
    end
end

--- string.trim utility (used by GetPlate)
if not string.trim then
    function string.trim(s)
        return s:match('^%s*(.-)%s*$')
    end
end

-- ═══════════════════════════════════════
-- Event Forwarding
-- ═══════════════════════════════════════

-- When Umeverse signals player loaded, fire QB event
RegisterNetEvent('umeverse:client:playerLoaded:done', function()
    RefreshPlayerData()
    TriggerEvent('QBCore:Client:OnPlayerLoaded')
end)

-- When Umeverse signals logout, fire QB event
RegisterNetEvent('umeverse:client:logout', function()
    QBCore.PlayerData = {}
    TriggerEvent('QBCore:Client:OnPlayerUnload')
end)

-- When Umeverse signals job change, fire QB event
RegisterNetEvent('umeverse:client:jobChanged', function(job)
    RefreshPlayerData()
    TriggerEvent('QBCore:Client:OnJobUpdate', QBCore.PlayerData.job)
end)

-- When Umeverse syncs player data, update cache and fire QB event
RegisterNetEvent('umeverse:client:syncPlayerData', function(data)
    RefreshPlayerData()
    TriggerEvent('QBCore:Player:SetPlayerData', QBCore.PlayerData)
end)

-- QB UpdateObject handler
RegisterNetEvent('QBCore:Client:UpdateObject', function()
    -- QBCore object is always in sync via our bridge
end)

-- QB SetPlayerData handler (from server)
RegisterNetEvent('QBCore:Player:SetPlayerData', function(val)
    QBCore.PlayerData = val
end)

-- Handle QBCore:Client:OnMoneyChange forwarding
RegisterNetEvent('QBCore:Client:OnMoneyChange', function(moneyType, amount, action, reason)
    RefreshPlayerData()
end)

-- ═══════════════════════════════════════
-- Export
-- ═══════════════════════════════════════

exports('GetCoreObject', function()
    return QBCore
end)

_G.QBCore = QBCore
