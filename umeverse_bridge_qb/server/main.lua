--[[
    Umeverse Bridge - QBCore Server
    Emulates QBCore server-side API using Umeverse functions
]]

local UME = exports['umeverse_core']:GetCoreObject()

-- ═══════════════════════════════════════
-- QBCore Player Object Wrapper
-- ═══════════════════════════════════════

--- Wraps a Umeverse player into a QB-compatible Player object
---@param umePlayer table Umeverse player object
---@return table QB-style player object
local function WrapPlayer(umePlayer)
    if not umePlayer then return nil end

    local self = {}

    -- PlayerData (QB structure)
    self.PlayerData = {
        source      = umePlayer:GetSource(),
        citizenid   = umePlayer:GetCitizenId(),
        license     = umePlayer:GetIdentifier(),
        name        = umePlayer.name or GetPlayerName(umePlayer:GetSource()),
        charinfo    = {
            firstname   = umePlayer.firstname,
            lastname    = umePlayer.lastname,
            birthdate   = umePlayer.charinfo and umePlayer.charinfo.birthdate or '1990-01-01',
            gender      = umePlayer.charinfo and umePlayer.charinfo.gender == 'female' and 1 or 0,
            nationality = umePlayer.charinfo and umePlayer.charinfo.nationality or 'American',
            phone       = umePlayer.charinfo and umePlayer.charinfo.phone or '',
            account     = umePlayer.charinfo and umePlayer.charinfo.account or '',
        },
        money = {
            cash  = umePlayer:GetMoney('cash'),
            bank  = umePlayer:GetMoney('bank'),
            crypto = 0,
        },
        job = {
            name     = umePlayer.job.name,
            label    = umePlayer.job.label,
            payment  = 0,
            type     = umePlayer.job.type,
            onduty   = umePlayer.job.onduty or false,
            isboss   = false,
            grade    = {
                name  = umePlayer.job.gradelabel or 'None',
                level = umePlayer.job.grade or 0,
            },
        },
        gang = {
            name  = 'none',
            label = 'No Gang',
            isboss = false,
            grade = { name = 'none', level = 0 },
        },
        position = umePlayer:GetPosition(),
        metadata = umePlayer:GetMetadata() or {},
        items    = umePlayer:GetInventory() or {},
    }

    self.Functions = {}

    -- ── Money ──

    function self.Functions.AddMoney(moneyType, amount, reason)
        moneyType = string.lower(moneyType or 'cash')
        if moneyType == 'crypto' then return false end
        local result = umePlayer:AddMoney(moneyType, amount, reason)
        if result then
            self.PlayerData.money[moneyType] = umePlayer:GetMoney(moneyType)
        end
        return result
    end

    function self.Functions.RemoveMoney(moneyType, amount, reason)
        moneyType = string.lower(moneyType or 'cash')
        if moneyType == 'crypto' then return false end
        local result = umePlayer:RemoveMoney(moneyType, amount, reason)
        if result then
            self.PlayerData.money[moneyType] = umePlayer:GetMoney(moneyType)
        end
        return result
    end

    function self.Functions.SetMoney(moneyType, amount, reason)
        moneyType = string.lower(moneyType or 'cash')
        umePlayer:SetMoney(moneyType, amount)
        self.PlayerData.money[moneyType] = amount
        return true
    end

    function self.Functions.GetMoney(moneyType)
        moneyType = string.lower(moneyType or 'cash')
        return umePlayer:GetMoney(moneyType)
    end

    -- ── Job ──

    function self.Functions.SetJob(job, grade)
        grade = tonumber(grade) or 0
        local result = umePlayer:SetJob(job, grade)
        if result then
            local jobData = umePlayer:GetJob()
            self.PlayerData.job = {
                name    = jobData.name,
                label   = jobData.label,
                payment = 0,
                type    = jobData.type,
                onduty  = jobData.onduty or false,
                isboss  = false,
                grade   = {
                    name  = jobData.gradelabel or 'None',
                    level = jobData.grade or 0,
                },
            }
            TriggerEvent('QBCore:Server:OnJobUpdate', umePlayer:GetSource(), self.PlayerData.job)
            TriggerClientEvent('QBCore:Client:OnJobUpdate', umePlayer:GetSource(), self.PlayerData.job)
        end
        return result
    end

    function self.Functions.SetGang(gang, grade)
        -- Umeverse doesn't have a gang system; no-op but don't error
        return true
    end

    function self.Functions.GetJob()
        return self.PlayerData.job
    end

    -- ── Inventory ──

    function self.Functions.AddItem(item, amount, slot, info)
        return umePlayer:AddItem(item, amount, info)
    end

    function self.Functions.RemoveItem(item, amount, slot)
        return umePlayer:RemoveItem(item, amount)
    end

    function self.Functions.GetItemByName(item)
        for _, invItem in ipairs(umePlayer:GetInventory()) do
            if invItem.name == item then
                return {
                    name   = invItem.name,
                    amount = invItem.amount,
                    info   = invItem.metadata or {},
                    label  = invItem.label,
                    type   = invItem.type,
                    unique = invItem.unique,
                    useable = true,
                    slot   = _ ,
                    weight = invItem.weight,
                }
            end
        end
        return nil
    end

    function self.Functions.GetItemsByName(item)
        local items = {}
        for i, invItem in ipairs(umePlayer:GetInventory()) do
            if invItem.name == item then
                items[#items + 1] = {
                    name   = invItem.name,
                    amount = invItem.amount,
                    info   = invItem.metadata or {},
                    label  = invItem.label,
                    type   = invItem.type,
                    unique = invItem.unique,
                    useable = true,
                    slot   = i,
                    weight = invItem.weight,
                }
            end
        end
        return items
    end

    function self.Functions.HasItem(item, amount)
        return umePlayer:HasItem(item, amount)
    end

    function self.Functions.GetItemCount(item)
        return umePlayer:GetItemCount(item)
    end

    function self.Functions.ClearInventory(filterItems)
        -- Clear all items (optionally keep filterItems)
        local inv = umePlayer:GetInventory()
        for i = #inv, 1, -1 do
            if not filterItems or not filterItems[inv[i].name] then
                umePlayer:RemoveItem(inv[i].name, inv[i].amount)
            end
        end
    end

    -- ── Metadata ──

    function self.Functions.SetMetaData(key, value)
        umePlayer:SetMetadata(key, value)
        self.PlayerData.metadata[key] = value
    end

    function self.Functions.GetMetaData(key)
        if key then
            return umePlayer:GetMetadata(key)
        end
        return umePlayer:GetMetadata()
    end

    -- ── Misc ──

    function self.Functions.Save()
        umePlayer:Save()
    end

    function self.Functions.Logout()
        umePlayer:Save()
        UME.Players[umePlayer:GetSource()] = nil
        TriggerClientEvent('umeverse:client:logout', umePlayer:GetSource())
    end

    function self.Functions.SetPlayerData(key, value)
        if key == 'job' then
            self.Functions.SetJob(value.name, value.grade and value.grade.level or 0)
        elseif key == 'metadata' then
            for k, v in pairs(value) do
                umePlayer:SetMetadata(k, v)
            end
        end
        self.PlayerData[key] = value
    end

    function self.Functions.GetPlayerData()
        return self.PlayerData
    end

    function self.Functions.UpdatePlayerData()
        TriggerClientEvent('QBCore:Player:SetPlayerData', umePlayer:GetSource(), self.PlayerData)
    end

    return self
end

-- ═══════════════════════════════════════
-- QBCore.Functions (Server)
-- ═══════════════════════════════════════

--- Get a player by server ID
function QBCore.Functions.GetPlayer(source)
    local umePlayer = UME.GetPlayer(source)
    return WrapPlayer(umePlayer)
end

--- Get a player by citizenid
function QBCore.Functions.GetPlayerByCitizenId(citizenid)
    local umePlayer = UME.GetPlayerByCitizenId(citizenid)
    return WrapPlayer(umePlayer)
end

--- Get a player by phone number (stub - returns nil)
function QBCore.Functions.GetPlayerByPhone(phone)
    return nil
end

--- Get all online players
function QBCore.Functions.GetPlayers()
    local sources = {}
    for src, _ in pairs(UME.GetPlayers()) do
        sources[#sources + 1] = src
    end
    return sources
end

--- Get QBCore object (for exports['qb-core']:GetCoreObject())
function QBCore.Functions.GetCoreObject()
    return QBCore
end

--- Create a server callback
function QBCore.Functions.CreateCallback(name, cb)
    UME.RegisterServerCallback(name, function(source, umeCb, ...)
        cb(source, umeCb, ...)
    end)
end

--- Trigger a client callback (stub)
function QBCore.Functions.TriggerClientCallback(name, source, cb, ...)
    -- Not commonly used server→client, stub it
    if cb then cb(nil) end
end

--- Create a useable/usable item
function QBCore.Functions.CreateUseableItem(item, cb)
    UME.RegisterUsableItem(item, function(src, player, itemName)
        -- QB passes (source, item) where item is the inventory item data
        local itemData = player:HasItem(itemName) and {
            name   = itemName,
            amount = player:GetItemCount(itemName),
            info   = {},
            label  = UME.GetItemLabel(itemName) or itemName,
        } or nil
        cb(src, itemData)
    end)
end

--- Check if an item is useable
function QBCore.Functions.CanUseItem(item)
    local itemDef = UME.GetItem(item)
    return itemDef and itemDef.usable
end

--- Notify a player
function QBCore.Functions.Notify(source, text, notifyType, duration)
    if type(source) == 'table' then
        -- Broadcast to multiple
        for _, src in ipairs(source) do
            UME.Notify(src, text, notifyType, duration)
        end
    else
        UME.Notify(source, text, notifyType, duration)
    end
end

--- Kick a player with reason
function QBCore.Functions.Kick(source, reason, setKickReason, deferrals)
    local player = UME.GetPlayer(source)
    if player then
        player:Kick(reason or 'Kicked from server')
    else
        DropPlayer(source, reason or 'Kicked from server')
    end
end

--- Get player identifier
function QBCore.Functions.GetIdentifier(source, idType)
    return UME.GetIdentifier(source, idType)
end

--- Check if source is whitelisted (stub - always true)
function QBCore.Functions.IsWhitelisted(source)
    return true
end

--- Add permission (stub)
function QBCore.Functions.AddPermission(source, permission)
end

--- Remove permission (stub)
function QBCore.Functions.RemovePermission(source, permission)
end

--- Has permission
function QBCore.Functions.HasPermission(source, permission)
    return IsPlayerAceAllowed(source, permission)
end

--- Get permission (returns highest)
function QBCore.Functions.GetPermission(source)
    if IsPlayerAceAllowed(source, 'umeverse.owner') then return 'god' end
    if IsPlayerAceAllowed(source, 'umeverse.superadmin') then return 'admin' end
    if IsPlayerAceAllowed(source, 'umeverse.admin') then return 'admin' end
    if IsPlayerAceAllowed(source, 'umeverse.moderator') then return 'mod' end
    return 'user'
end

--- Is player online
function QBCore.Functions.IsPlayerOnline(source)
    return UME.GetPlayer(source) ~= nil
end

-- ═══════════════════════════════════════
-- QB Events (Server → forward to Umeverse)
-- ═══════════════════════════════════════

-- Forward QB player loaded event
RegisterNetEvent('umeverse:server:playerLoaded:done', function(src)
    local qbPlayer = QBCore.Functions.GetPlayer(src)
    if qbPlayer then
        TriggerClientEvent('QBCore:Client:OnPlayerLoaded', src)
        TriggerEvent('QBCore:Server:PlayerLoaded', qbPlayer)
    end
end)

-- Forward player dropped
AddEventHandler('playerDropped', function(reason)
    local src = source
    TriggerEvent('QBCore:Server:OnPlayerUnload', src)
end)

-- Forward job update
RegisterNetEvent('umeverse:server:jobChange', function(src, job)
    local qbPlayer = QBCore.Functions.GetPlayer(src)
    if qbPlayer then
        TriggerEvent('QBCore:Server:OnJobUpdate', src, qbPlayer.PlayerData.job)
        TriggerClientEvent('QBCore:Client:OnJobUpdate', src, qbPlayer.PlayerData.job)
    end
end)

-- Forward money change
RegisterNetEvent('umeverse:server:moneyChange', function(src, moneyType, amount, action, reason)
    TriggerEvent('QBCore:Server:OnMoneyChange', src, moneyType, amount, action, reason)
    TriggerClientEvent('QBCore:Client:OnMoneyChange', src, moneyType, amount, action, reason)
end)

-- Handle QB-style set player data from client
RegisterNetEvent('QBCore:Server:SetMetaData', function(key, value)
    local src = source
    local player = UME.GetPlayer(src)
    if player then
        player:SetMetadata(key, value)
    end
end)

-- Handle QB UpdateObject request (returns QBCore table)
RegisterNetEvent('QBCore:Server:UpdateObject', function()
    -- No-op, QB object is always in sync
end)

-- ═══════════════════════════════════════
-- Exports
-- ═══════════════════════════════════════

exports('GetCoreObject', function()
    return QBCore
end)

-- Also provide the object as a global for scripts that cache it
_G.QBCore = QBCore
