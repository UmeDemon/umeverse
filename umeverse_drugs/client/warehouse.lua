--[[
    Umeverse Drugs - Warehouse
    Rent and manage drug warehouses for bulk storage
    Requires Rep Level 7 (Underboss)
]]

local UME = exports['umeverse_core']:GetCoreObject()

-- ═══════════════════════════════════════
-- Warehouse Interaction Loop
-- ═══════════════════════════════════════

CreateThread(function()
    Wait(5000)
    while true do
        local sleep = 1000
        local myPos = GetEntityCoords(PlayerPedId())

        for _, wh in ipairs(DrugConfig.Warehouses.locations) do
            local pos = vector3(wh.coords.x, wh.coords.y, wh.coords.z)
            local dist = #(myPos - pos)

            if dist < DrugConfig.MarkerDrawDistance then
                sleep = 0
                DrawDrugMarker(1, pos, 200, 150, 0, 120)
                DrawText3DDrug(vector3(pos.x, pos.y, pos.z + 1.0), '~o~' .. wh.label)

                if dist < DrugConfig.InteractDistance then
                    if not HasUnlocked('warehouse') then
                        ShowDrugHelp('Requires ~r~Rep Level 7~s~ to access')
                    else
                        ShowDrugHelp('Press ~INPUT_CONTEXT~ to access warehouse')
                        if IsControlJustReleased(0, 38) then
                            OpenWarehouseMenu(wh.id)
                        end
                    end
                end
            end
        end

        Wait(sleep)
    end
end)

-- ═══════════════════════════════════════
-- Warehouse Menu
-- ═══════════════════════════════════════

local warehouseMenuOpen = false

function OpenWarehouseMenu(warehouseId)
    if IsBusy() or warehouseMenuOpen then return end

    warehouseMenuOpen = true

    -- Request warehouse state from server
    UME.TriggerServerCallback('umeverse_drugs:getWarehouseState', function(data)
        if not data then
            DrugNotify('Failed to access warehouse.', 'error')
            warehouseMenuOpen = false
            return
        end

        ShowWarehouseUI(warehouseId, data)
    end, warehouseId)
end

function ShowWarehouseUI(warehouseId, data)
    local selectedIdx = 1
    local options = {}

    if data.owned then
        options = {
            { label = 'Open Storage', action = 'open' },
            { label = 'Check Rent Status', action = 'status' },
            { label = 'Cancel Rent', action = 'cancel' },
            { label = 'Close', action = 'close' },
        }
    else
        -- Find warehouse config for price
        local whCfg = nil
        for _, wh in ipairs(DrugConfig.Warehouses.locations) do
            if wh.id == warehouseId then whCfg = wh break end
        end

        options = {
            { label = 'Rent Warehouse ($' .. (whCfg and whCfg.rentCost or '???') .. '/day)', action = 'rent' },
            { label = 'Close', action = 'close' },
        }
    end

    CreateThread(function()
        while warehouseMenuOpen do
            Wait(0)

            local text = '~o~Warehouse~s~\n\n'
            for i, opt in ipairs(options) do
                if i == selectedIdx then
                    text = text .. '~y~> ' .. opt.label .. '~s~\n'
                else
                    text = text .. '  ' .. opt.label .. '\n'
                end
            end
            text = text .. '\n~INPUT_CELLPHONE_UP~ / ~INPUT_CELLPHONE_DOWN~ Navigate\n~INPUT_CONTEXT~ Select | ~INPUT_FRONTEND_CANCEL~ Close'

            local pos = GetEntityCoords(PlayerPedId())
            DrawText3DDrug(vector3(pos.x, pos.y, pos.z + 0.5), text)

            if IsControlJustReleased(0, 172) then
                selectedIdx = selectedIdx - 1
                if selectedIdx < 1 then selectedIdx = #options end
            end
            if IsControlJustReleased(0, 173) then
                selectedIdx = selectedIdx + 1
                if selectedIdx > #options then selectedIdx = 1 end
            end

            if IsControlJustReleased(0, 38) then
                local action = options[selectedIdx].action
                warehouseMenuOpen = false

                if action == 'open' then
                    TriggerServerEvent('umeverse_drugs:server:openWarehouse', warehouseId)
                elseif action == 'rent' then
                    TriggerServerEvent('umeverse_drugs:server:rentWarehouse', warehouseId)
                elseif action == 'status' then
                    TriggerServerEvent('umeverse_drugs:server:warehouseStatus', warehouseId)
                elseif action == 'cancel' then
                    TriggerServerEvent('umeverse_drugs:server:cancelWarehouse', warehouseId)
                end
            end

            if IsControlJustReleased(0, 202) then
                warehouseMenuOpen = false
            end
        end
    end)
end

-- ═══════════════════════════════════════
-- Warehouse feedback events
-- ═══════════════════════════════════════

RegisterNetEvent('umeverse_drugs:client:warehouseRented', function(label)
    DrugNotify('Rented ' .. label .. ' successfully!', 'success')
end)

RegisterNetEvent('umeverse_drugs:client:warehouseStatus', function(label, expiresIn)
    DrugNotify(label .. ' - Expires in ' .. expiresIn, 'info')
end)

RegisterNetEvent('umeverse_drugs:client:warehouseCanceled', function(label)
    DrugNotify(label .. ' rent canceled.', 'warning')
end)

RegisterNetEvent('umeverse_drugs:client:openWarehouseStash', function(warehouseId)
    -- Open as a stash using the inventory system
    TriggerServerEvent('umeverse_inventory:server:openInventory', 'stash', 'drug_warehouse_' .. warehouseId)
end)
