--[[
    Umeverse Banking - Client
]]

local UME = exports['umeverse_core']:GetCoreObject()
local isBankOpen = false
local nearBank = false

-- ═══════════════════════════════════════
-- Blips
-- ═══════════════════════════════════════

CreateThread(function()
    for _, bank in ipairs(BankConfig.BankLocations) do
        local blip = AddBlipForCoord(bank.coords.x, bank.coords.y, bank.coords.z)
        SetBlipSprite(blip, BankConfig.BlipSprite)
        SetBlipDisplay(blip, 4)
        SetBlipScale(blip, BankConfig.BlipScale)
        SetBlipColour(blip, BankConfig.BlipColor)
        SetBlipAsShortRange(blip, true)
        BeginTextCommandSetBlipName('STRING')
        AddTextComponentString(bank.label)
        EndTextCommandSetBlipName(blip)
    end
end)

-- ═══════════════════════════════════════
-- Bank Interaction
-- ═══════════════════════════════════════

CreateThread(function()
    -- Pre-hash ATM models once
    local atmModels = {
        GetHashKey('prop_atm_01'),
        GetHashKey('prop_atm_02'),
        GetHashKey('prop_atm_03'),
        GetHashKey('prop_fleeca_atm'),
    }

    while true do
        local sleep = 1000
        if UME.IsLoggedIn() and not UME.IsDead() then
            local myCoords = GetEntityCoords(PlayerPedId())
            nearBank = false

            for _, bank in ipairs(BankConfig.BankLocations) do
                local dist = #(myCoords - bank.coords)
                if dist < 10.0 then
                    sleep = 0
                    if dist < BankConfig.InteractDistance then
                        nearBank = true
                        UME.ShowHelpText('Press ~INPUT_CONTEXT~ to access the bank')

                        if IsControlJustPressed(0, 38) then -- E
                            if not isBankOpen then
                                TriggerServerEvent('umeverse_banking:server:openBank')
                            end
                        end
                    end
                end
            end

            -- ATM interaction (only check when not already near a bank)
            if not nearBank then
                local foundAtm = false
                for _, model in ipairs(atmModels) do
                    local atm = GetClosestObjectOfType(myCoords.x, myCoords.y, myCoords.z, 1.5, model, false, false, false)
                    if atm ~= 0 then
                        foundAtm = true
                        sleep = 0
                        nearBank = true
                        UME.ShowHelpText('Press ~INPUT_CONTEXT~ to use ATM')

                        if IsControlJustPressed(0, 38) then
                            if not isBankOpen then
                                TriggerServerEvent('umeverse_banking:server:openBank')
                            end
                        end
                        break
                    end
                end
            end
        end

        Wait(sleep)
    end
end)

-- ═══════════════════════════════════════
-- Open / Close Bank UI
-- ═══════════════════════════════════════

RegisterNetEvent('umeverse_banking:client:openBank', function(data)
    isBankOpen = true
    SetNuiFocus(true, true)
    SendNUIMessage({
        action = 'openBank',
        data = data,
    })
end)

function CloseBank()
    isBankOpen = false
    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'closeBank' })
end

-- ═══════════════════════════════════════
-- NUI Callbacks
-- ═══════════════════════════════════════

RegisterNUICallback('closeBank', function(_, cb)
    CloseBank()
    cb('ok')
end)

RegisterNUICallback('deposit', function(data, cb)
    TriggerServerEvent('umeverse_banking:server:deposit', data.amount)
    cb('ok')
end)

RegisterNUICallback('withdraw', function(data, cb)
    TriggerServerEvent('umeverse_banking:server:withdraw', data.amount)
    cb('ok')
end)

RegisterNUICallback('transfer', function(data, cb)
    TriggerServerEvent('umeverse_banking:server:transfer', data.targetId, data.amount)
    cb('ok')
end)

RegisterNUICallback('getPlayerList', function(_, cb)
    UME.TriggerServerCallback('umeverse_banking:getPlayerList', function(players)
        cb(players)
    end)
end)
