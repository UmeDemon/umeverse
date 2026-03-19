--[[
    Umeverse Inventory - Server
]]

local UME = exports['umeverse_core']:GetCoreObject()
local Drops = {}
local Stashes = {}

-- ═══════════════════════════════════════
-- Helpers
-- ═══════════════════════════════════════

--- Calculate total weight of an inventory table
local function CalcWeight(inventory)
    local weight = 0
    for _, item in ipairs(inventory) do
        local itemDef = UME.GetItem(item.name)
        if itemDef then
            weight = weight + (itemDef.weight * (item.amount or 1))
        end
    end
    return weight
end

--- Check if adding an item would exceed max weight
local function CanCarry(inventory, itemName, amount)
    local currentWeight = CalcWeight(inventory)
    local itemDef = UME.GetItem(itemName)
    if not itemDef then return false end
    local addWeight = itemDef.weight * (amount or 1)
    return (currentWeight + addWeight) <= InvConfig.MaxWeight
end

-- ═══════════════════════════════════════
-- Open Inventory
-- ═══════════════════════════════════════

RegisterNetEvent('umeverse_inventory:server:openInventory', function(invType, invId)
    local src = source
    local player = UME.GetPlayer(src)
    if not player then return end

    local playerInv = player:GetInventory()
    local secondaryInv = nil
    local secondaryLabel = nil
    local secondaryMaxWeight = InvConfig.MaxWeight
    local secondaryMaxSlots = InvConfig.MaxSlots

    if invType == 'stash' then
        local stashConfig = InvConfig.Stashes[invId]
        if not stashConfig then return end

        -- Job check
        if stashConfig.job and player:GetJob().name ~= stashConfig.job then
            UME.Notify(src, 'You don\'t have access to this stash.', 'error')
            return
        end

        -- Load from DB or cache
        if not Stashes[invId] then
            local result = MySQL.query.await('SELECT * FROM umeverse_stashes WHERE stash_id = ?', { invId })
            if result and #result > 0 then
                Stashes[invId] = json.decode(result[1].inventory) or {}
            else
                Stashes[invId] = {}
                MySQL.insert.await('INSERT INTO umeverse_stashes (stash_id, inventory) VALUES (?, ?)', { invId, '[]' })
            end
        end

        secondaryInv = Stashes[invId]
        secondaryLabel = stashConfig.label
        secondaryMaxWeight = stashConfig.maxWeight
        secondaryMaxSlots = stashConfig.maxSlots

    elseif invType == 'drop' then
        if Drops[invId] then
            secondaryInv = Drops[invId].items
            secondaryLabel = 'Ground'
            secondaryMaxWeight = 500000
            secondaryMaxSlots = 100
        end

    elseif invType == 'player' then
        local target = UME.GetPlayer(tonumber(invId))
        if target then
            secondaryInv = target:GetInventory()
            secondaryLabel = target:GetFullName()
        end
    end

    -- Build item definitions for display
    local itemDefs = {}
    local function addDefs(inv)
        if not inv then return end
        for _, item in ipairs(inv) do
            if not itemDefs[item.name] then
                itemDefs[item.name] = UME.GetItem(item.name)
            end
        end
    end
    addDefs(playerInv)
    addDefs(secondaryInv)

    TriggerClientEvent('umeverse_inventory:client:openInventory', src, {
        playerInventory = playerInv,
        playerWeight    = CalcWeight(playerInv),
        maxWeight       = InvConfig.MaxWeight,
        maxSlots        = InvConfig.MaxSlots,
        secondary       = secondaryInv,
        secondaryLabel  = secondaryLabel,
        secondaryWeight = secondaryInv and CalcWeight(secondaryInv) or 0,
        secondaryMaxWeight = secondaryMaxWeight,
        secondaryMaxSlots  = secondaryMaxSlots,
        invType         = invType,
        invId           = invId,
        itemDefs        = itemDefs,
    })
end)

-- ═══════════════════════════════════════
-- Move / Transfer Items
-- ═══════════════════════════════════════

RegisterNetEvent('umeverse_inventory:server:moveItem', function(data)
    local src = source
    local player = UME.GetPlayer(src)
    if not player then return end

    local fromType = data.from     -- 'player' or 'secondary'
    local toType = data.to         -- 'player' or 'secondary'
    local itemName = data.item
    local amount = tonumber(data.amount) or 1

    -- Validate amount (prevent negative / zero exploits)
    if amount <= 0 then return end
    amount = math.floor(amount)

    if fromType == 'player' and toType == 'player' then
        -- Just reorder within inventory (no-op on server)
        return
    end

    if fromType == 'player' and toType == 'secondary' then
        if player:HasItem(itemName, amount) then
            player:RemoveItem(itemName, amount)

            -- Add to secondary
            if data.invType == 'stash' then
                AddToInventory(Stashes[data.invId], itemName, amount)
                SaveStash(data.invId)
            elseif data.invType == 'drop' then
                if Drops[data.invId] then
                    AddToInventory(Drops[data.invId].items, itemName, amount)
                end
            end
        end

    elseif fromType == 'secondary' and toType == 'player' then
        -- Weight check
        if not CanCarry(player:GetInventory(), itemName, amount) then
            UME.Notify(src, 'Too heavy to carry.', 'error')
            return
        end

        local removed = false
        if data.invType == 'stash' then
            removed = RemoveFromInventory(Stashes[data.invId], itemName, amount)
            SaveStash(data.invId)
        elseif data.invType == 'drop' then
            if Drops[data.invId] then
                removed = RemoveFromInventory(Drops[data.invId].items, itemName, amount)
            end
        end

        if removed then
            player:AddItem(itemName, amount)
        end
    end

    -- Re-sync inventory to client
    RefreshInventory(src, data.invType, data.invId)
end)

-- ═══════════════════════════════════════
-- Refresh Inventory Helper
-- ═══════════════════════════════════════

function RefreshInventory(src, invType, invId)
    local player = UME.GetPlayer(src)
    if not player then return end

    local playerInv = player:GetInventory()
    local secondaryInv = nil
    local secondaryLabel = nil
    local secondaryMaxWeight = InvConfig.MaxWeight
    local secondaryMaxSlots = InvConfig.MaxSlots

    if invType == 'stash' then
        local stashConfig = InvConfig.Stashes[invId]
        secondaryInv = Stashes[invId] or {}
        secondaryLabel = stashConfig and stashConfig.label or 'Stash'
        secondaryMaxWeight = stashConfig and stashConfig.maxWeight or InvConfig.MaxWeight
        secondaryMaxSlots = stashConfig and stashConfig.maxSlots or InvConfig.MaxSlots
    elseif invType == 'drop' then
        if Drops[invId] then
            secondaryInv = Drops[invId].items
            secondaryLabel = 'Ground'
            secondaryMaxWeight = 500000
            secondaryMaxSlots = 100
        end
    end

    local itemDefs = {}
    local function addDefs(inv)
        if not inv then return end
        for _, item in ipairs(inv) do
            if not itemDefs[item.name] then
                itemDefs[item.name] = UME.GetItem(item.name)
            end
        end
    end
    addDefs(playerInv)
    addDefs(secondaryInv)

    TriggerClientEvent('umeverse_inventory:client:openInventory', src, {
        playerInventory = playerInv,
        playerWeight    = CalcWeight(playerInv),
        maxWeight       = InvConfig.MaxWeight,
        maxSlots        = InvConfig.MaxSlots,
        secondary       = secondaryInv,
        secondaryLabel  = secondaryLabel,
        secondaryWeight = secondaryInv and CalcWeight(secondaryInv) or 0,
        secondaryMaxWeight = secondaryMaxWeight,
        secondaryMaxSlots  = secondaryMaxSlots,
        invType         = invType,
        invId           = invId,
        itemDefs        = itemDefs,
    })
end

-- ═══════════════════════════════════════
-- Use Item
-- ═══════════════════════════════════════

RegisterNetEvent('umeverse_inventory:server:useItem', function(itemName)
    local src = source
    local player = UME.GetPlayer(src)
    if not player then return end

    -- Sanitize: only allow registered item names (alphanumeric + underscore)
    if type(itemName) ~= 'string' or not itemName:match('^[%w_%-]+$') then return end

    -- Only trigger if the item is actually registered and player has it
    local itemDef = UME.GetItem(itemName)
    if not itemDef then return end

    if player:HasItem(itemName) then
        TriggerEvent('umeverse:server:useItem:' .. itemName, src)
    end
end)

-- ═══════════════════════════════════════
-- Hotbar (keys 1-5 → use item in that slot)
-- ═══════════════════════════════════════

RegisterNetEvent('umeverse_inventory:server:useHotbarSlot', function(slot)
    local src = source
    local player = UME.GetPlayer(src)
    if not player then return end

    -- Validate slot (1-5)
    if type(slot) ~= 'number' or slot < 1 or slot > 5 then return end

    local inventory = player:GetInventory()
    local item = inventory[slot]
    if not item or not item.name then return end

    local itemDef = UME.GetItem(item.name)
    if not itemDef or not itemDef.usable then return end

    TriggerEvent('umeverse:server:useItem:' .. item.name, src)
end)

-- ═══════════════════════════════════════
-- Drop System
-- ═══════════════════════════════════════

RegisterNetEvent('umeverse_inventory:server:dropItem', function(itemName, amount, coords)
    local src = source
    local player = UME.GetPlayer(src)
    if not player then return end

    amount = tonumber(amount) or 1

    -- Validate amount (prevent negative / zero exploits)
    if amount <= 0 then return end
    amount = math.floor(amount)

    -- Validate coords are near the player (anti-teleport drop)
    if coords then
        local ped = GetPlayerPed(src)
        if ped and DoesEntityExist(ped) then
            local playerCoords = GetEntityCoords(ped)
            local dist = #(vector3(coords.x, coords.y, coords.z) - playerCoords)
            if dist > 10.0 then
                UME.Notify(src, 'Too far away to drop items here.', 'error')
                return
            end
        end
    end

    if not player:HasItem(itemName, amount) then return end

    player:RemoveItem(itemName, amount)

    local dropId = 'drop_' .. UME.GenerateId():sub(1, 8)
    Drops[dropId] = {
        items = {},
        coords = coords,
        createdAt = os.time(),
    }
    AddToInventory(Drops[dropId].items, itemName, amount)

    -- Notify nearby players
    TriggerClientEvent('umeverse_inventory:client:createDropPoint', -1, dropId, coords)

    -- Auto despawn
    if InvConfig.DropDespawnTime > 0 then
        SetTimeout(InvConfig.DropDespawnTime * 1000, function()
            if Drops[dropId] then
                Drops[dropId] = nil
                TriggerClientEvent('umeverse_inventory:client:removeDropPoint', -1, dropId)
            end
        end)
    end
end)

-- ═══════════════════════════════════════
-- Inventory Helpers
-- ═══════════════════════════════════════

function AddToInventory(inv, itemName, amount)
    local itemDef = UME.GetItem(itemName)
    if not itemDef then return end

    for i, slot in ipairs(inv) do
        if slot.name == itemName and not itemDef.unique then
            inv[i].amount = slot.amount + amount
            return
        end
    end

    inv[#inv + 1] = {
        name   = itemName,
        label  = itemDef.label,
        amount = amount,
        weight = itemDef.weight,
        type   = itemDef.type,
    }
end

function RemoveFromInventory(inv, itemName, amount)
    for i, slot in ipairs(inv) do
        if slot.name == itemName then
            if slot.amount > amount then
                inv[i].amount = slot.amount - amount
                return true
            elseif slot.amount == amount then
                table.remove(inv, i)
                return true
            end
        end
    end
    return false
end

function SaveStash(stashId)
    MySQL.update.await('UPDATE umeverse_stashes SET inventory = ? WHERE stash_id = ?', {
        json.encode(Stashes[stashId] or {}), stashId,
    })
end

-- ═══════════════════════════════════════
-- Exports
-- ═══════════════════════════════════════

exports('CanCarry', function(src, itemName, amount)
    local player = UME.GetPlayer(src)
    if not player then return false end
    return CanCarry(player:GetInventory(), itemName, amount)
end)

exports('GetWeight', function(src)
    local player = UME.GetPlayer(src)
    if not player then return 0 end
    return CalcWeight(player:GetInventory())
end)
