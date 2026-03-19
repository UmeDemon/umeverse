--[[
    Umeverse Drugs - Client Cutting System
    UI for selecting drugs and cutting agents at stash houses.
]]

local UME = exports['umeverse_core']:GetCoreObject()

local cutMenuOpen = false

-- ═══════════════════════════════════════
-- Cutting Interaction at Stash Houses
-- ═══════════════════════════════════════

CreateThread(function()
    if not DrugConfig.Cutting.enabled then return end
    Wait(6000)

    while true do
        local sleep = 1000
        local myPos = GetEntityCoords(PlayerPedId())

        if not IsBusy() and not cutMenuOpen and DrugConfig.Cutting.useStashLocations then
            for _, stash in ipairs(DrugConfig.StashHouses.locations) do
                local pos = vector3(stash.coords.x, stash.coords.y, stash.coords.z)
                local dist = #(myPos - pos)

                if dist < DrugConfig.MarkerDrawDistance then
                    sleep = 0

                    -- Draw cutting station marker (offset from stash marker)
                    local cutPos = pos + vector3(-1.5, 0, 0)
                    DrawDrugMarker(1, cutPos, 255, 165, 0, 100)
                    DrawText3DDrug(vector3(cutPos.x, cutPos.y, cutPos.z + 1.0), '~o~Cutting Station')

                    if #(myPos - cutPos) < DrugConfig.InteractDistance + 1.0 then
                        ShowDrugHelp('Press ~INPUT_DETONATE~ to cut drugs')
                        if IsControlJustReleased(0, 47) then -- G key
                            OpenCutMenu()
                        end
                    end
                end
            end
        end

        Wait(sleep)
    end
end)

-- ═══════════════════════════════════════
-- Cutting Menu
-- ═══════════════════════════════════════

function OpenCutMenu()
    if IsBusy() or cutMenuOpen then return end
    cutMenuOpen = true

    -- Build list of compatible drug+agent combos player has
    local combos = {}
    for _, agent in ipairs(DrugConfig.Cutting.agents) do
        for _, drugItem in ipairs(agent.compatibleDrugs) do
            local info = DrugConfig.DrugSellItems[drugItem]
            if info then
                combos[#combos + 1] = {
                    drugItem = drugItem,
                    drugLabel = info.drug,
                    agentItem = agent.item,
                    agentLabel = agent.label,
                    quantityMult = agent.quantityMult,
                    purityLoss = agent.purityLoss,
                }
            end
        end
    end

    if #combos == 0 then
        cutMenuOpen = false
        DrugNotify('No cutting combinations available', 'info')
        return
    end

    local selectedIdx = 1
    local quantity = 1

    CreateThread(function()
        while cutMenuOpen do
            Wait(0)

            local combo = combos[selectedIdx]
            local multPct = math.floor((combo.quantityMult - 1) * 100)

            local text = '~o~Cutting Station~s~\n\n'
            for i, c in ipairs(combos) do
                local mPct = math.floor((c.quantityMult - 1) * 100)
                if i == selectedIdx then
                    text = text .. '~y~> ' .. c.drugLabel .. ' + ' .. c.agentLabel .. ' (+' .. mPct .. '% qty, -' .. c.purityLoss .. ' purity)~s~\n'
                else
                    text = text .. '  ' .. c.drugLabel .. ' + ' .. c.agentLabel .. ' (+' .. mPct .. '% qty, -' .. c.purityLoss .. ' purity)\n'
                end
            end

            text = text .. '\n~w~Amount: ~y~' .. quantity .. 'x~s~'
            text = text .. '\n\n~INPUT_CELLPHONE_UP~/~INPUT_CELLPHONE_DOWN~ Select'
            text = text .. '\n~INPUT_CELLPHONE_LEFT~/~INPUT_CELLPHONE_RIGHT~ Amount'
            text = text .. '\n~INPUT_CONTEXT~ Cut | ~INPUT_FRONTEND_CANCEL~ Cancel'

            local pos = GetEntityCoords(PlayerPedId())
            DrawText3DDrug(vector3(pos.x, pos.y, pos.z + 0.5), text)

            -- Navigate
            if IsControlJustReleased(0, 172) then
                selectedIdx = selectedIdx - 1
                if selectedIdx < 1 then selectedIdx = #combos end
            end
            if IsControlJustReleased(0, 173) then
                selectedIdx = selectedIdx + 1
                if selectedIdx > #combos then selectedIdx = 1 end
            end

            -- Adjust quantity
            if IsControlJustReleased(0, 174) then -- Left
                quantity = math.max(1, quantity - 1)
            end
            if IsControlJustReleased(0, 175) then -- Right
                quantity = quantity + 1
            end

            -- Confirm
            if IsControlJustReleased(0, 38) then
                cutMenuOpen = false
                ExecuteCut(combos[selectedIdx], quantity)
            end

            -- Cancel
            if IsControlJustReleased(0, 202) then
                cutMenuOpen = false
            end
        end
    end)
end

-- ═══════════════════════════════════════
-- Execute Cutting
-- ═══════════════════════════════════════

function ExecuteCut(combo, quantity)
    if IsBusy() then return end

    DrugProgress('Cutting ' .. combo.drugLabel .. '...', DrugConfig.Cutting.cutTime,
        DrugConfig.Cutting.cutAnim, function()
            TriggerServerEvent('umeverse_drugs:server:cutDrug', combo.drugItem, combo.agentItem, quantity)
        end)
end

-- ═══════════════════════════════════════
-- Cut complete feedback
-- ═══════════════════════════════════════

RegisterNetEvent('umeverse_drugs:client:cutComplete', function(drugItem, outputQty, newPurity)
    local label = DrugConfig.DrugSellItems[drugItem] and DrugConfig.DrugSellItems[drugItem].drug or drugItem
    DrugNotify('Cut complete: ' .. outputQty .. 'x ' .. label .. ' (Purity: ' .. newPurity .. '%)', 'success')
end)
