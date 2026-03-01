--[[
    Umeverse Bridge - ESX Server
    Emulates ESX server-side API using Umeverse functions
]]

local UME = exports['umeverse_core']:GetCoreObject()

-- ═══════════════════════════════════════
-- xPlayer Wrapper
-- ═══════════════════════════════════════

--- Wraps a Umeverse player into an ESX-compatible xPlayer object
---@param umePlayer table Umeverse player object
---@return table xPlayer-style object
local function WrapXPlayer(umePlayer)
    if not umePlayer then return nil end

    local xPlayer = {}

    xPlayer.source      = umePlayer:GetSource()
    xPlayer.identifier  = umePlayer:GetIdentifier()
    xPlayer.playerId    = umePlayer:GetSource() -- alias
    xPlayer.group       = 'user'

    -- Determine admin group
    if IsPlayerAceAllowed(xPlayer.source, 'umeverse.owner') then
        xPlayer.group = 'superadmin'
    elseif IsPlayerAceAllowed(xPlayer.source, 'umeverse.admin') then
        xPlayer.group = 'admin'
    elseif IsPlayerAceAllowed(xPlayer.source, 'umeverse.moderator') then
        xPlayer.group = 'mod'
    end

    -- ── Name ──

    function xPlayer.getName()
        return umePlayer:GetFullName()
    end

    function xPlayer.setName(newName)
        -- ESX stub, names are character-bound
    end

    function xPlayer.getGroup()
        return xPlayer.group
    end

    function xPlayer.setGroup(newGroup)
        xPlayer.group = newGroup
    end

    -- ── Money ──

    function xPlayer.getMoney()
        return umePlayer:GetMoney('cash')
    end

    function xPlayer.addMoney(amount, reason)
        umePlayer:AddMoney('cash', amount, reason)
    end

    function xPlayer.removeMoney(amount, reason)
        umePlayer:RemoveMoney('cash', amount, reason)
    end

    function xPlayer.setMoney(amount)
        umePlayer:SetMoney('cash', amount)
    end

    -- ── Accounts (bank, black_money mapped) ──

    function xPlayer.getAccount(account)
        local mapping = {
            bank        = 'bank',
            money       = 'cash',
            black_money = 'cash', -- Umeverse doesn't have dirty money, fall back to cash
        }
        local umeType = mapping[account] or account

        return {
            name   = account,
            money  = umePlayer:GetMoney(umeType),
            label  = account:gsub('^%l', string.upper),
        }
    end

    function xPlayer.getAccounts(minimal)
        local accounts = {}
        local types = { 'money', 'bank', 'black_money' }
        for _, acc in ipairs(types) do
            accounts[#accounts + 1] = xPlayer.getAccount(acc)
        end
        return accounts
    end

    function xPlayer.addAccountMoney(account, amount, reason)
        local mapping = { bank = 'bank', money = 'cash', black_money = 'cash' }
        local umeType = mapping[account] or account
        umePlayer:AddMoney(umeType, amount, reason)
    end

    function xPlayer.removeAccountMoney(account, amount, reason)
        local mapping = { bank = 'bank', money = 'cash', black_money = 'cash' }
        local umeType = mapping[account] or account
        umePlayer:RemoveMoney(umeType, amount, reason)
    end

    function xPlayer.setAccountMoney(account, amount, reason)
        local mapping = { bank = 'bank', money = 'cash', black_money = 'cash' }
        local umeType = mapping[account] or account
        umePlayer:SetMoney(umeType, amount)
    end

    -- ── Job ──

    function xPlayer.getJob()
        local job = umePlayer:GetJob()
        return {
            name   = job.name,
            label  = job.label,
            grade  = job.grade or 0,
            grade_name  = job.gradelabel or 'None',
            grade_label = job.gradelabel or 'None',
            grade_salary = 0,
            skin_male   = {},
            skin_female = {},
        }
    end

    function xPlayer.setJob(name, grade)
        umePlayer:SetJob(name, grade or 0)
        -- Fire ESX events
        TriggerEvent('esx:setJob', xPlayer.source, xPlayer.getJob(), {})
        TriggerClientEvent('esx:setJob', xPlayer.source, xPlayer.getJob(), {})
    end

    function xPlayer.getDuty()
        local job = umePlayer:GetJob()
        return job.onduty or false
    end

    function xPlayer.setDuty(onDuty)
        umePlayer:ToggleDuty()
    end

    -- ── Inventory ──

    function xPlayer.getInventory(minimal)
        local inv = umePlayer:GetInventory() or {}
        local result = {}
        for i, item in ipairs(inv) do
            result[#result + 1] = {
                name   = item.name,
                count  = item.amount,
                label  = item.label or item.name,
                weight = item.weight or 0,
                rare   = false,
                canRemove = true,
            }
        end
        return result
    end

    function xPlayer.getInventoryItem(itemName)
        for _, item in ipairs(umePlayer:GetInventory()) do
            if item.name == itemName then
                return {
                    name   = item.name,
                    count  = item.amount,
                    label  = item.label or item.name,
                    weight = item.weight or 0,
                    rare   = false,
                    canRemove = true,
                }
            end
        end
        return { name = itemName, count = 0, label = itemName, weight = 0, rare = false, canRemove = true }
    end

    function xPlayer.addInventoryItem(itemName, count, metadata, slot)
        umePlayer:AddItem(itemName, count, metadata)
    end

    function xPlayer.removeInventoryItem(itemName, count, metadata, slot)
        umePlayer:RemoveItem(itemName, count)
    end

    function xPlayer.setInventoryItem(itemName, count)
        local current = umePlayer:GetItemCount(itemName)
        if count > current then
            umePlayer:AddItem(itemName, count - current)
        elseif count < current then
            umePlayer:RemoveItem(itemName, current - count)
        end
    end

    function xPlayer.canCarryItem(itemName, count)
        -- Simple check — always true (Umeverse weight system is in inventory resource)
        return true
    end

    function xPlayer.canSwapItem(firstItem, firstItemCount, testItem, testItemCount)
        return true
    end

    function xPlayer.hasItem(itemName, count)
        return umePlayer:HasItem(itemName, count or 1)
    end

    -- ── Status / Metadata ──

    function xPlayer.getCoords(useVector)
        local pos = umePlayer:GetPosition()
        if useVector then
            return vector3(pos.x, pos.y, pos.z)
        end
        return pos
    end

    function xPlayer.setCoords(coords)
        umePlayer:SetPosition(coords.x, coords.y, coords.z, coords.w or 0.0)
    end

    function xPlayer.getMeta(key)
        if key then
            return umePlayer:GetMetadata(key)
        end
        return umePlayer:GetMetadata()
    end

    function xPlayer.setMeta(key, value)
        umePlayer:SetMetadata(key, value)
    end

    function xPlayer.getIdentifier()
        return umePlayer:GetIdentifier()
    end

    -- ── Misc ──

    function xPlayer.kick(reason)
        umePlayer:Kick(reason or 'Kicked from server')
    end

    function xPlayer.showNotification(msg, flash, saveToBrief, hudColorIndex)
        UME.Notify(xPlayer.source, msg, 'info', 5000)
    end

    function xPlayer.showHelpNotification(msg, thisFrame, beep, duration)
        UME.Notify(xPlayer.source, msg, 'info', duration or 5000)
    end

    function xPlayer.triggerEvent(eventName, ...)
        TriggerClientEvent(eventName, xPlayer.source, ...)
    end

    function xPlayer.save()
        umePlayer:Save()
    end

    function xPlayer.set(key, value)
        umePlayer:SetMetadata(key, value)
    end

    function xPlayer.get(key)
        return umePlayer:GetMetadata(key)
    end

    return xPlayer
end

-- ═══════════════════════════════════════
-- ESX Server Functions
-- ═══════════════════════════════════════

--- Get xPlayer by source
function ESX.GetPlayerFromId(source)
    local umePlayer = UME.GetPlayer(source)
    return WrapXPlayer(umePlayer)
end

--- Get xPlayer by identifier
function ESX.GetPlayerFromIdentifier(identifier)
    for src, player in pairs(UME.GetPlayers()) do
        if player:GetIdentifier() == identifier then
            return WrapXPlayer(player)
        end
    end
    return nil
end

--- Get all xPlayers
function ESX.GetPlayers()
    local sources = {}
    for src, _ in pairs(UME.GetPlayers()) do
        sources[#sources + 1] = src
    end
    return sources
end

--- Get extended (all xPlayer objects)
function ESX.GetExtendedPlayers(key, val)
    local result = {}
    for src, player in pairs(UME.GetPlayers()) do
        local xPlayer = WrapXPlayer(player)
        if not key then
            result[#result + 1] = xPlayer
        elseif key == 'job' and xPlayer.getJob().name == val then
            result[#result + 1] = xPlayer
        elseif key == 'group' and xPlayer.group == val then
            result[#result + 1] = xPlayer
        end
    end
    return result
end

--- Register a server callback
function ESX.RegisterServerCallback(name, cb)
    UME.RegisterServerCallback(name, function(source, umeCb, ...)
        cb(source, umeCb, ...)
    end)
end

--- Register a usable item
function ESX.RegisterUsableItem(item, cb)
    UME.RegisterUsableItem(item, function(src, player, itemName)
        cb(src, itemName, player:GetInventory())
    end)
end

--- Create a pickup (stub - not supported)
function ESX.CreatePickup(itemType, name, count, label, playerId, components, tintIndex)
    -- Not supported in Umeverse, no-op
    return nil
end

--- Use item
function ESX.UseItem(source, item, ...)
    TriggerEvent('umeverse:server:useItem', source, item)
end

--- Get item label
function ESX.GetItemLabel(item)
    local itemDef = UME.Items and UME.Items[item]
    if itemDef then
        return itemDef.label or item
    end
    return item
end

--- Get jobs
function ESX.GetJobs()
    return UME.Jobs or {}
end

--- Save player
function ESX.SavePlayer(xPlayer)
    if xPlayer and xPlayer.source then
        local umePlayer = UME.GetPlayer(xPlayer.source)
        if umePlayer then
            umePlayer:Save()
        end
    end
end

--- Save all players
function ESX.SavePlayers()
    for _, player in pairs(UME.GetPlayers()) do
        player:Save()
    end
end

--- Discard (runs right-away cb) no-op in new ESX
function ESX.SetTimeout(ms, cb)
    Citizen.SetTimeout(ms, cb)
end

--- ClearTimeout
function ESX.ClearTimeout(id)
    -- Not easily supported in cfx, no-op
end

--- Trace / log
function ESX.Trace(msg)
    print('[ESX Bridge] ' .. tostring(msg))
end

--- ShowNotification wrapper (server side → triggers client)
function ESX.ShowNotification(source, msg, notifyType, duration)
    UME.Notify(source, msg, notifyType or 'info', duration or 5000)
end

-- ═══════════════════════════════════════
-- Event Forwarding
-- ═══════════════════════════════════════

-- Forward player loaded
RegisterNetEvent('umeverse:server:playerLoaded:done', function(src)
    local xPlayer = ESX.GetPlayerFromId(src)
    if xPlayer then
        TriggerEvent('esx:playerLoaded', src, xPlayer)
        TriggerClientEvent('esx:playerLoaded', src, xPlayer.getJob(), xPlayer.getAccounts(), xPlayer.getCoords(true))
    end
end)

-- Forward player dropped
AddEventHandler('playerDropped', function(reason)
    local src = source
    TriggerEvent('esx:playerDropped', src, reason)
end)

-- Forward job change
RegisterNetEvent('umeverse:server:jobChange', function(src, job)
    local xPlayer = ESX.GetPlayerFromId(src)
    if xPlayer then
        TriggerEvent('esx:setJob', src, xPlayer.getJob(), {})
        TriggerClientEvent('esx:setJob', src, xPlayer.getJob(), {})
    end
end)

-- ═══════════════════════════════════════
-- Exports
-- ═══════════════════════════════════════

exports('getSharedObject', function()
    return ESX
end)

-- Legacy: some old ESX scripts use TriggerEvent('esx:getSharedObject')
AddEventHandler('esx:getSharedObject', function(cb)
    if cb then cb(ESX) end
end)

_G.ESX = ESX
