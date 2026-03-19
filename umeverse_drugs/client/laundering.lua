--[[
    Umeverse Drugs - Money Laundering
    Convert dirty money (black money) into clean bank money at a cut
    Higher drug rep = better conversion rates
]]

local UME = exports['umeverse_core']:GetCoreObject()

local launderNpcs = {}
local launderCooldowns = {}

-- ═══════════════════════════════════════
-- Spawn Laundering NPCs
-- ═══════════════════════════════════════

CreateThread(function()
    Wait(5000)

    for i, loc in ipairs(DrugConfig.Laundering.locations) do
        local ped = SpawnDrugNpc(loc.npcModel, loc.coords)
        if ped then
            launderNpcs[i] = ped
        end
    end
end)

-- ═══════════════════════════════════════
-- Laundering Interaction Loop
-- ═══════════════════════════════════════

CreateThread(function()
    Wait(6000)
    while true do
        local sleep = 1000
        local myPos = GetEntityCoords(PlayerPedId())

        if not IsBusy() then
            for i, loc in ipairs(DrugConfig.Laundering.locations) do
                local pos = vector3(loc.coords.x, loc.coords.y, loc.coords.z)
                local dist = #(myPos - pos)

                if dist < DrugConfig.MarkerDrawDistance then
                    sleep = 0
                    DrawDrugMarker(1, pos, 50, 200, 50, 100)
                    DrawText3DDrug(vector3(pos.x, pos.y, pos.z + 1.0), '~g~' .. loc.label)

                    if dist < DrugConfig.InteractDistance then
                        -- Check cooldown
                        local now = GetGameTimer()
                        if launderCooldowns[i] and now - launderCooldowns[i] < (DrugConfig.Laundering.cooldown * 1000) then
                            local remaining = math.ceil((DrugConfig.Laundering.cooldown * 1000 - (now - launderCooldowns[i])) / 1000)
                            ShowDrugHelp('Come back in ~r~' .. remaining .. 's~s~')
                        else
                            local level = GetDrugLevel()
                            local rate = DrugConfig.Laundering.rates[level] or 0.55
                            local pct = math.floor(rate * 100)

                            ShowDrugHelp('Press ~INPUT_CONTEXT~ to launder money\nRate: ~g~' .. pct .. '%~s~ (Level ' .. level .. ')')

                            if IsControlJustReleased(0, 38) then
                                OpenLaunderMenu(i)
                            end
                        end
                    end
                end
            end
        end

        Wait(sleep)
    end
end)

-- ═══════════════════════════════════════
-- Laundering Menu (Amount Selection)
-- ═══════════════════════════════════════

local launderMenuOpen = false

function OpenLaunderMenu(locationIdx)
    if IsBusy() or launderMenuOpen then return end

    launderMenuOpen = true

    local level = GetDrugLevel()
    local rate = DrugConfig.Laundering.rates[level] or 0.55
    local pct = math.floor(rate * 100)

    -- Preset amounts
    local amounts = {
        DrugConfig.Laundering.minAmount,
        1000,
        2500,
        5000,
        10000,
        25000,
        DrugConfig.Laundering.maxAmount,
    }
    local selectedIdx = 1

    CreateThread(function()
        while launderMenuOpen do
            Wait(0)

            local text = '~g~Money Laundering~s~ (Rate: ' .. pct .. '%)\n\n'
            for i, amount in ipairs(amounts) do
                local cleanAmount = math.floor(amount * rate)
                if i == selectedIdx then
                    text = text .. '~y~> $' .. amount .. ' dirty → $' .. cleanAmount .. ' clean~s~\n'
                else
                    text = text .. '  $' .. amount .. ' dirty → $' .. cleanAmount .. ' clean\n'
                end
            end
            text = text .. '\n~INPUT_CELLPHONE_UP~ / ~INPUT_CELLPHONE_DOWN~ Amount\n~INPUT_CONTEXT~ Launder | ~INPUT_FRONTEND_CANCEL~ Cancel'

            local pos = GetEntityCoords(PlayerPedId())
            DrawText3DDrug(vector3(pos.x, pos.y, pos.z + 0.5), text)

            if IsControlJustReleased(0, 172) then
                selectedIdx = selectedIdx - 1
                if selectedIdx < 1 then selectedIdx = #amounts end
            end
            if IsControlJustReleased(0, 173) then
                selectedIdx = selectedIdx + 1
                if selectedIdx > #amounts then selectedIdx = 1 end
            end

            if IsControlJustReleased(0, 38) then
                launderMenuOpen = false
                LaunderMoney(locationIdx, amounts[selectedIdx])
            end

            if IsControlJustReleased(0, 202) then
                launderMenuOpen = false
            end
        end
    end)
end

-- ═══════════════════════════════════════
-- Execute Laundering
-- ═══════════════════════════════════════

function LaunderMoney(locationIdx, amount)
    if IsBusy() then return end

    local loc = DrugConfig.Laundering.locations[locationIdx]
    if not loc then return end

    DrugProgress('Laundering money...', DrugConfig.Laundering.animTime, { dict = 'mp_common', anim = 'givetake1_a', flag = 49 }, function()
        TriggerServerEvent('umeverse_drugs:server:launderMoney', locationIdx, amount)
    end)

    launderCooldowns[locationIdx] = GetGameTimer()
end

-- ═══════════════════════════════════════
-- Laundering result feedback
-- ═══════════════════════════════════════

RegisterNetEvent('umeverse_drugs:client:launderComplete', function(dirtyAmount, cleanAmount)
    DrugNotify('Laundered ~r~$' .. dirtyAmount .. '~s~ dirty → ~g~$' .. cleanAmount .. '~s~ clean', 'success')
end)
