--[[
    Umeverse Inventory - Client
]]

local UME = exports['umeverse_core']:GetCoreObject()
local isOpen = false
local currentInvType = nil
local currentInvId = nil
local drops = {}

-- ═══════════════════════════════════════
-- Open / Close (rebindable via FiveM Settings > Key Bindings)
-- ═══════════════════════════════════════

RegisterCommand('+umeverse_inventory', function()
    if UME.IsLoggedIn() and not UME.IsDead() then
        if isOpen then
            CloseInventory()
        else
            TriggerServerEvent('umeverse_inventory:server:openInventory', nil, nil)
        end
    end
end, false)
RegisterCommand('-umeverse_inventory', function() end, false)
RegisterKeyMapping('+umeverse_inventory', 'Open Inventory', 'keyboard', InvConfig.OpenKey or 'F2')

-- ═══════════════════════════════════════
-- Hotbar Keys (1-5 → use item in that inventory slot)
-- ═══════════════════════════════════════

for i = 1, 5 do
    RegisterCommand('+umeverse_hotbar_' .. i, function()
        if UME.IsLoggedIn() and not UME.IsDead() and not isOpen then
            TriggerServerEvent('umeverse_inventory:server:useHotbarSlot', i)
        end
    end, false)
    RegisterCommand('-umeverse_hotbar_' .. i, function() end, false)
    RegisterKeyMapping('+umeverse_hotbar_' .. i, 'Hotbar Slot ' .. i, 'keyboard', tostring(i))
end

RegisterNetEvent('umeverse_inventory:client:openInventory', function(data)
    isOpen = true
    currentInvType = data.invType
    currentInvId = data.invId

    SetNuiFocus(true, true)
    SendNUIMessage({
        action = 'openInventory',
        data   = data,
    })
end)

function CloseInventory()
    isOpen = false
    currentInvType = nil
    currentInvId = nil
    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'closeInventory' })
end

-- ═══════════════════════════════════════
-- NUI Callbacks
-- ═══════════════════════════════════════

RegisterNUICallback('closeInventory', function(_, cb)
    CloseInventory()
    cb('ok')
end)

RegisterNUICallback('moveItem', function(data, cb)
    TriggerServerEvent('umeverse_inventory:server:moveItem', {
        from    = data.from,
        to      = data.to,
        item    = data.item,
        amount  = data.amount,
        invType = currentInvType,
        invId   = currentInvId,
    })
    cb('ok')
end)

RegisterNUICallback('useItem', function(data, cb)
    TriggerServerEvent('umeverse_inventory:server:useItem', data.item)
    cb('ok')
end)

RegisterNUICallback('dropItem', function(data, cb)
    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    TriggerServerEvent('umeverse_inventory:server:dropItem', data.item, data.amount, {
        x = coords.x, y = coords.y, z = coords.z,
    })
    cb('ok')
end)

-- ═══════════════════════════════════════
-- Drop Points (World markers)
-- ═══════════════════════════════════════

RegisterNetEvent('umeverse_inventory:client:createDropPoint', function(dropId, coords)
    drops[dropId] = coords
end)

RegisterNetEvent('umeverse_inventory:client:removeDropPoint', function(dropId)
    drops[dropId] = nil
end)

--- Draw drop markers and allow interaction
CreateThread(function()
    while true do
        local sleep = 1000
        local myCoords = GetEntityCoords(PlayerPedId())

        for dropId, coords in pairs(drops) do
            local dist = #(myCoords - vector3(coords.x, coords.y, coords.z))
            if dist < 50.0 then
                sleep = 0
                DrawMarker(2, coords.x, coords.y, coords.z - 0.5, 0, 0, 0, 0, 0, 0, 0.2, 0.2, 0.15, 59, 130, 246, 180, false, false, 2, false, nil, nil, false)

                if dist < 2.0 then
                    UME.ShowHelpText('Press ~INPUT_CONTEXT~ to pick up items')
                    if IsControlJustPressed(0, 38) then -- E
                        TriggerServerEvent('umeverse_inventory:server:openInventory', 'drop', dropId)
                    end
                end
            end
        end

        Wait(sleep)
    end
end)

-- ═══════════════════════════════════════
-- Exports
-- ═══════════════════════════════════════

exports('IsOpen', function()
    return isOpen
end)
