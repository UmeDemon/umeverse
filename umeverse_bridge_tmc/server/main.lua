--[[
    Umeverse Bridge - TMC Server
    Emulates TMC server-side API using Umeverse functions

    TMC's API structure:
        TMC.GetPlayer(source)         → returns Player object with Player.PlayerData + Player.Functions
        TMC.GetPlayers()              → returns array of source IDs
        TMC.GetPlayerByCitizenId(cid) → returns Player object
        TMC.Functions.GetPlayer(src)  → same as TMC.GetPlayer
        TMC.Functions.CreateCallback(name, cb)
        TMC.Functions.AddItem(src, item, amount, slot, info)
        TMC.Functions.RemoveItem(src, item, amount, slot)
        TMC.Functions.HasItem(src, item, amount)
        TMC.Functions.AddMoney(src, type, amount, reason)
        TMC.Functions.RemoveMoney(src, type, amount, reason)
        TMC.Functions.GetMoney(src, type)
        TMC.Functions.Notify(src, msg, type, duration)
        TMC.Functions.GetIdentifier(src, idType)
        TMC.Functions.HasPermission(src, permission)
        TMC.Functions.SendDiscordLog(type, title, msg, color, fields)
        TMC.CreatePlayer(src, citizenid, charInfo, money, job, gang, metadata)
]]

local UME = exports['umeverse_core']:GetCoreObject()

-- ═══════════════════════════════════════
-- Populate Shared Data from Umeverse
-- ═══════════════════════════════════════

CreateThread(function()
    -- Map Umeverse items → TMCShared.Items
    if UME.Items then
        for name, item in pairs(UME.Items) do
            TMCShared.Items[name] = {
                name        = name,
                label       = item.label or name,
                weight      = item.weight or 0,
                type        = item.type or 'item',
                image       = name .. '.png',
                unique      = item.unique or false,
                stackable   = not item.unique,
                useable     = item.usable or false,
                shouldClose = true,
                description = item.description or '',
            }
        end
    end
    TMC.Shared.Items = TMCShared.Items

    -- Map Umeverse jobs → TMCShared.Jobs
    if UME.Jobs then
        for name, job in pairs(UME.Jobs) do
            TMCShared.Jobs[name] = job
        end
    end
    TMC.Shared.Jobs = TMCShared.Jobs

    print('[TMC Bridge] Shared data synced from Umeverse')
end)

-- ═══════════════════════════════════════
-- TMC Player Object Wrapper
-- ═══════════════════════════════════════

function TMC.CreatePlayer(source, citizenid, charInfo, money, job, gang, metadata)
    local umePlayer = UME.GetPlayer(source)
    if not umePlayer then return nil end
    return WrapTMCPlayer(umePlayer)
end

local function BuildPlayerData(umePlayer)
    local src = umePlayer:GetSource()
    local jobData = umePlayer:GetJob()

    return {
        source    = src,
        citizenid = umePlayer:GetCitizenId(),
        license   = umePlayer:GetIdentifier(),
        name      = GetPlayerName(src),
        charinfo  = umePlayer:GetCharInfo() or {},
        money     = {
            cash   = umePlayer:GetMoney('cash'),
            bank   = umePlayer:GetMoney('bank'),
            crypto = 0,
        },
        job = {
            name   = jobData.name,
            label  = jobData.label,
            grade  = { name = jobData.gradelabel or 'None', level = jobData.grade or 0 },
            onduty = jobData.onduty or false,
        },
        gang = {
            name  = 'none',
            label = 'No Gang',
            grade = { name = 'None', level = 0 },
        },
        metadata   = umePlayer:GetMetadata() or {},
        inventory  = umePlayer:GetInventory() or {},
        permission = 'user',
    }
end

function WrapTMCPlayer(umePlayer)
    if not umePlayer then return nil end

    local self = {}
    self.PlayerData = BuildPlayerData(umePlayer)
    self.Functions = {}

    -- ── Money ──

    self.Functions.AddMoney = function(moneyType, amount, reason)
        if not moneyType or amount <= 0 then return false end
        if moneyType == 'crypto' then return false end
        local result = umePlayer:AddMoney(moneyType, amount, reason)
        if result then
            self.PlayerData.money[moneyType] = umePlayer:GetMoney(moneyType)
            TriggerClientEvent('TMC:Client:OnMoneyChange', self.PlayerData.source, moneyType, amount, 'add')
        end
        return result
    end

    self.Functions.RemoveMoney = function(moneyType, amount, reason)
        if not moneyType or amount <= 0 then return false end
        if moneyType == 'crypto' then return false end
        local result = umePlayer:RemoveMoney(moneyType, amount, reason)
        if result then
            self.PlayerData.money[moneyType] = umePlayer:GetMoney(moneyType)
            TriggerClientEvent('TMC:Client:OnMoneyChange', self.PlayerData.source, moneyType, amount, 'remove')
        end
        return result
    end

    self.Functions.GetMoney = function(moneyType)
        if not moneyType then return 0 end
        if moneyType == 'crypto' then return 0 end
        return umePlayer:GetMoney(moneyType)
    end

    self.Functions.SetMoney = function(moneyType, amount)
        if not moneyType or amount < 0 then return false end
        umePlayer:SetMoney(moneyType, amount)
        self.PlayerData.money[moneyType] = amount
        return true
    end

    -- ── Inventory ──

    self.Functions.AddItem = function(item, amount, slot, info)
        local result = umePlayer:AddItem(item, amount, info)
        if result then
            self.PlayerData.inventory = umePlayer:GetInventory()
            TriggerClientEvent('inventory:client:itemBox', self.PlayerData.source, item, 'add', info, amount)
        end
        return result
    end

    self.Functions.RemoveItem = function(item, amount, slot)
        local result = umePlayer:RemoveItem(item, amount)
        if result then
            self.PlayerData.inventory = umePlayer:GetInventory()
            TriggerClientEvent('inventory:client:itemBox', self.PlayerData.source, item, 'remove', nil, amount)
        end
        return result
    end

    self.Functions.GetItemByName = function(item)
        for _, invItem in pairs(umePlayer:GetInventory()) do
            if invItem.name == item then
                return invItem
            end
        end
        return nil
    end

    self.Functions.GetItemBySlot = function(slot)
        for _, invItem in pairs(umePlayer:GetInventory()) do
            if invItem.slot == slot then
                return invItem
            end
        end
        return nil
    end

    self.Functions.SetItemInfo = function(slot, info)
        -- Stub — slot-based metadata not directly in Umeverse
        return true
    end

    -- ── Job ──

    self.Functions.SetJob = function(jobName, grade)
        local result = umePlayer:SetJob(jobName, grade or 0)
        if result then
            local jobData = umePlayer:GetJob()
            self.PlayerData.job = {
                name   = jobData.name,
                label  = jobData.label,
                grade  = { name = jobData.gradelabel or 'None', level = jobData.grade or 0 },
                onduty = jobData.onduty or false,
            }
            TriggerClientEvent('TMC:Client:SetJob', self.PlayerData.source, self.PlayerData.job)
        end
        return result
    end

    self.Functions.SetGang = function(gangName, grade)
        -- Umeverse doesn't have gangs, no-op
        self.PlayerData.gang.name = gangName or 'none'
        self.PlayerData.gang.grade.level = grade or 0
        TriggerClientEvent('TMC:Client:SetGang', self.PlayerData.source, self.PlayerData.gang)
        return true
    end

    -- ── Metadata ──

    self.Functions.GetMetaData = function(key)
        if not key then return umePlayer:GetMetadata() end
        return umePlayer:GetMetadata(key)
    end

    self.Functions.SetMetaData = function(key, value)
        umePlayer:SetMetadata(key, value)
        self.PlayerData.metadata[key] = value
        TriggerClientEvent('TMC:Client:SetMetaData', self.PlayerData.source, key, value)
        return true
    end

    -- ── Save ──

    self.Functions.Save = function()
        umePlayer:Save()
    end

    return self
end

-- ═══════════════════════════════════════
-- TMC Core Functions (top-level)
-- ═══════════════════════════════════════

function TMC.GetPlayer(source)
    local umePlayer = UME.GetPlayer(source)
    return WrapTMCPlayer(umePlayer)
end

function TMC.GetPlayers()
    local sources = {}
    for src, _ in pairs(UME.GetPlayers()) do
        table.insert(sources, src)
    end
    return sources
end

function TMC.GetPlayerByCitizenId(citizenid)
    local umePlayer = UME.GetPlayerByCitizenId(citizenid)
    return WrapTMCPlayer(umePlayer)
end

-- ═══════════════════════════════════════
-- TMC.Functions (Server)
-- ═══════════════════════════════════════

TMC.Functions.GetPlayer = function(source)
    return TMC.GetPlayer(source)
end

TMC.Functions.GetPlayers = function()
    return TMC.GetPlayers()
end

TMC.Functions.GetPlayerByCitizenId = function(citizenid)
    return TMC.GetPlayerByCitizenId(citizenid)
end

-- Server callbacks
local ServerCallbacks = {}

TMC.Functions.CreateCallback = function(name, cb)
    ServerCallbacks[name] = cb
    -- Also register in Umeverse's callback system
    UME.RegisterServerCallback(name, function(source, umeCb, ...)
        cb(source, umeCb, ...)
    end)
end

RegisterNetEvent('TMC:Server:TriggerCallback', function(name, ...)
    local src = source
    if ServerCallbacks[name] then
        ServerCallbacks[name](src, function(...)
            TriggerClientEvent('TMC:Client:CallbackResponse', src, name, ...)
        end, ...)
    end
end)

-- QBCore compat callback (TMC has these built-in)
RegisterNetEvent('QBCore:Server:TriggerClientCallback', function(name, ...)
    local src = source
    if ServerCallbacks[name] then
        ServerCallbacks[name](src, function(...)
            TriggerClientEvent('QBCore:Client:TriggerCallback', src, name, ...)
        end, ...)
    end
end)

-- Item management
TMC.Functions.AddItem = function(source, item, amount, slot, info)
    local Player = TMC.GetPlayer(source)
    if not Player then return false end
    return Player.Functions.AddItem(item, amount, slot, info)
end

TMC.Functions.RemoveItem = function(source, item, amount, slot)
    local Player = TMC.GetPlayer(source)
    if not Player then return false end
    return Player.Functions.RemoveItem(item, amount, slot)
end

TMC.Functions.HasItem = function(source, item, amount)
    local umePlayer = UME.GetPlayer(source)
    if not umePlayer then return false end
    return umePlayer:HasItem(item, amount or 1)
end

-- Money management
TMC.Functions.AddMoney = function(source, moneyType, amount, reason)
    local Player = TMC.GetPlayer(source)
    if not Player then return false end
    return Player.Functions.AddMoney(moneyType, amount, reason)
end

TMC.Functions.RemoveMoney = function(source, moneyType, amount, reason)
    local Player = TMC.GetPlayer(source)
    if not Player then return false end
    return Player.Functions.RemoveMoney(moneyType, amount, reason)
end

TMC.Functions.GetMoney = function(source, moneyType)
    local umePlayer = UME.GetPlayer(source)
    if not umePlayer then return 0 end
    return umePlayer:GetMoney(moneyType)
end

-- Notifications
TMC.Functions.Notify = function(source, message, notifyType, duration)
    UME.Notify(source, message, notifyType or 'info', duration or 5000)
end

-- Identifier
TMC.Functions.GetIdentifier = function(source, idType)
    return UME.GetIdentifier(source, idType)
end

-- Coords
TMC.Functions.GetCoords = function(source)
    local ped = GetPlayerPed(source)
    if DoesEntityExist(ped) then
        return GetEntityCoords(ped)
    end
    return vector3(0, 0, 0)
end

-- Vehicle spawn (server-side)
TMC.Functions.SpawnVehicle = function(source, model, coords, heading)
    local veh = CreateVehicle(model, coords.x, coords.y, coords.z, heading or 0.0, true, true)
    local timeout = 0
    while not DoesEntityExist(veh) and timeout < 5000 do
        Wait(10)
        timeout = timeout + 10
    end
    return veh
end

-- Permission check
TMC.Functions.HasPermission = function(source, permission)
    local umePlayer = UME.GetPlayer(source)
    if not umePlayer then return false end

    if IsPlayerAceAllowed(source, permission) then return true end
    if IsPlayerAceAllowed(source, 'umeverse.owner') then return true end
    if IsPlayerAceAllowed(source, 'umeverse.admin') then return true end
    if permission == 'mod' or permission == 'helper' then
        if IsPlayerAceAllowed(source, 'umeverse.moderator') then return true end
    end

    return false
end

-- Discord logging (stub — logs to console)
TMC.Discord = {}

TMC.Discord.SendMessage = function(webhookType, title, message, color, fields)
    print(string.format('[TMC Bridge Log] [%s] %s: %s', webhookType or 'default', title or '', message or ''))
end

TMC.Functions.SendDiscordLog = function(webhookType, title, message, color, fields)
    TMC.Discord.SendMessage(webhookType, title, message, color, fields)
end

-- ═══════════════════════════════════════
-- Event Handlers (TMC-specific events)
-- ═══════════════════════════════════════

-- Handle TMC:Server:AddItem (validate server-side, amount must be positive)
RegisterNetEvent('TMC:Server:AddItem', function(item, amount)
    local src = source
    amount = tonumber(amount)
    if not amount or amount <= 0 or amount > 100 then return end
    if type(item) ~= 'string' or not item:match('^[%w_]+$') then return end
    TMC.Functions.AddItem(src, item, math.floor(amount))
end)

-- Handle TMC:Server:RemoveItem (validate)
RegisterNetEvent('TMC:Server:RemoveItem', function(item, amount, slot, index)
    local src = source
    amount = tonumber(amount)
    if not amount or amount <= 0 then return end
    if type(item) ~= 'string' or not item:match('^[%w_]+$') then return end
    TMC.Functions.RemoveItem(src, item, math.floor(amount), slot)
end)

-- QBCore compat
RegisterNetEvent('QBCore:Server:RemoveItem', function(item, amount, slot, index)
    local src = source
    amount = tonumber(amount)
    if not amount or amount <= 0 then return end
    if type(item) ~= 'string' or not item:match('^[%w_]+$') then return end
    TMC.Functions.RemoveItem(src, item, math.floor(amount), slot)
end)

-- TMC:UpdatePlayer
RegisterNetEvent('TMC:UpdatePlayer', function()
    local src = source
    local umePlayer = UME.GetPlayer(src)
    if umePlayer then umePlayer:Save() end
end)

RegisterNetEvent('QBCore:UpdatePlayer', function()
    local src = source
    local umePlayer = UME.GetPlayer(src)
    if umePlayer then umePlayer:Save() end
end)

-- TMC:Server:SetMetaData (only allow safe metadata keys)
local allowedMetaKeys = { ['hunger'] = true, ['thirst'] = true, ['stress'] = true, ['armor'] = true, ['phone'] = true, ['isdead'] = true, ['injail'] = true, ['jailtimer'] = true, ['inlaststand'] = true, ['tracker'] = true }
RegisterNetEvent('TMC:Server:SetMetaData', function(key, value)
    local src = source
    if type(key) ~= 'string' or not allowedMetaKeys[key] then return end
    local umePlayer = UME.GetPlayer(src)
    if umePlayer then umePlayer:SetMetadata(key, value) end
end)

RegisterNetEvent('QBCore:Server:SetMetaData', function(key, value)
    local src = source
    if type(key) ~= 'string' or not allowedMetaKeys[key] then return end
    local umePlayer = UME.GetPlayer(src)
    if umePlayer then umePlayer:SetMetadata(key, value) end
end)

-- Entity state bag
RegisterNetEvent('TMC:SetEntityStateBag', function(netId, key, value)
    local entity = NetworkGetEntityFromNetworkId(netId)
    if DoesEntityExist(entity) then
        Entity(entity).state:set(key, value, true)
    end
end)

RegisterNetEvent('QBCore:SetEntityStateBag', function(netId, key, value)
    local entity = NetworkGetEntityFromNetworkId(netId)
    if DoesEntityExist(entity) then
        Entity(entity).state:set(key, value, true)
    end
end)

-- Send to player (admin-only to prevent arbitrary event injection)
RegisterNetEvent('TMC:SendToPlayer', function(targetId, eventName, ...)
    local src = source
    if not IsPlayerAceAllowed(src, 'umeverse.admin') then return end
    TriggerClientEvent(eventName, targetId, ...)
end)

RegisterNetEvent('QBCore:SendToPlayer', function(targetId, eventName, ...)
    local src = source
    if not IsPlayerAceAllowed(src, 'umeverse.admin') then return end
    TriggerClientEvent(eventName, targetId, ...)
end)

-- Send to entity owner
RegisterNetEvent('TMC:SendToEntityOwner', function(netId, checkOwner, eventName, ...)
    local entity = NetworkGetEntityFromNetworkId(netId)
    if DoesEntityExist(entity) then
        local owner = NetworkGetEntityOwner(entity)
        if owner and owner > 0 then
            TriggerClientEvent(eventName, owner, ...)
        end
    end
end)

-- Routing bucket reset
RegisterNetEvent('TMC:ResetRoutingBucket', function(playerId, reason)
    SetPlayerRoutingBucket(playerId, 0)
end)

-- Vehicle delete (only allow owner or admin)
RegisterNetEvent('TMC:RequestVehicleDelete', function(netId)
    local src = source
    local vehicle = NetworkGetEntityFromNetworkId(netId)
    if DoesEntityExist(vehicle) then
        local owner = NetworkGetEntityOwner(vehicle)
        if owner == src or IsPlayerAceAllowed(src, 'umeverse.admin') then
            DeleteEntity(vehicle)
        end
    end
end)

-- Discord log from client
RegisterNetEvent('tmc:log', function(webhookType, title, message, color, options)
    local src = source
    TMC.Functions.SendDiscordLog(webhookType or 'default', title or '', message or '', color)
end)

-- ═══════════════════════════════════════
-- Forward Umeverse events → TMC events
-- ═══════════════════════════════════════

RegisterNetEvent('umeverse:server:playerLoaded:done', function(src)
    local tmcPlayer = TMC.GetPlayer(src)
    if tmcPlayer then
        TriggerClientEvent('TMC:Client:PlayerLoaded', src, tmcPlayer.PlayerData)
        TriggerClientEvent('TMC:Client:OnPlayerLoaded', src)
        -- Also fire QBCore equivalent that TMC scripts listen for
        TriggerClientEvent('QBCore:Client:OnPlayerLoaded', src)
    end
end)

AddEventHandler('playerDropped', function(reason)
    local src = source
    TriggerClientEvent('TMC:Client:OnPlayerUnload', src)
    TriggerClientEvent('QBCore:Client:OnPlayerUnload', src)
end)

RegisterNetEvent('umeverse:server:jobChange', function(src, job)
    local tmcPlayer = TMC.GetPlayer(src)
    if tmcPlayer then
        TriggerClientEvent('TMC:Client:SetJob', src, tmcPlayer.PlayerData.job)
    end
end)

-- ═══════════════════════════════════════
-- Exports
-- ═══════════════════════════════════════

exports('GetCoreObject', function()
    return TMC
end)

_G.TMC = TMC
_G.QBCore = TMC
