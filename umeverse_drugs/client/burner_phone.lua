--[[
    Umeverse Drugs - Client Burner Phone
    Usable burner phone item to request/accept/complete deals.
]]

local UME = exports['umeverse_core']:GetCoreObject()

local phoneOpen = false
local activeDeals = {}         -- synced from server
local activeDealBlips = {}
local activeDealNPCs = {}

-- ═══════════════════════════════════════
-- Open Burner Phone
-- ═══════════════════════════════════════

RegisterNetEvent('umeverse_drugs:client:useBurnerPhone', function()
    if IsBusy() or phoneOpen then return end
    phoneOpen = true

    -- Fetch active deals from server
    UME.TriggerServerCallback('umeverse_drugs:getBurnerDeals', function(data)
        if not data then
            phoneOpen = false
            return
        end

        activeDeals = data.deals or {}
        ShowPhoneMenu()
    end)
end)

-- ═══════════════════════════════════════
-- Phone Menu
-- ═══════════════════════════════════════

function ShowPhoneMenu()
    local selectedIdx = 0 -- 0 = Request New Deal button
    local options = {}

    -- Build menu options
    for i, deal in ipairs(activeDeals) do
        local timeLeft = deal.expiresAt - (os.time())
        if timeLeft > 0 then
            options[#options + 1] = {
                dealIdx = i,
                label = deal.label,
                drug = deal.drugLabel,
                quantity = deal.quantity,
                reward = deal.reward,
                timeLeft = timeLeft,
                state = deal.state, -- 'pending' | 'accepted'
            }
        end
    end

    CreateThread(function()
        while phoneOpen do
            Wait(0)

            local totalOptions = #options + 1 -- +1 for "Request New Deal"
            local text = '~y~BURNER PHONE~s~\n\n'

            -- Request new deal button
            if selectedIdx == 0 then
                text = text .. '~g~> [Request New Deal]~s~\n'
            else
                text = text .. '  [Request New Deal]\n'
            end

            -- Active deals
            for i, opt in ipairs(options) do
                local mins = math.floor(opt.timeLeft / 60)
                local secs = opt.timeLeft % 60
                local stateText = opt.state == 'accepted' and '~g~ACTIVE' or '~y~PENDING'
                local line = stateText .. '~s~ ' .. opt.label .. ': ' .. opt.quantity .. 'x ' .. opt.drug .. ' ($' .. opt.reward .. ', ' .. mins .. ':' .. string.format('%02d', secs) .. ')'
                if selectedIdx == i then
                    text = text .. '~g~> ' .. line .. '\n'
                else
                    text = text .. '  ' .. line .. '\n'
                end
            end

            text = text .. '\n~INPUT_CELLPHONE_UP~/~INPUT_CELLPHONE_DOWN~ Select'
            text = text .. '\n~INPUT_CONTEXT~ Confirm | ~INPUT_FRONTEND_CANCEL~ Close'

            local pos = GetEntityCoords(PlayerPedId())
            DrawText3DDrug(vector3(pos.x, pos.y, pos.z + 0.5), text)

            -- Navigation
            if IsControlJustReleased(0, 172) then
                selectedIdx = selectedIdx - 1
                if selectedIdx < 0 then selectedIdx = #options end
            end
            if IsControlJustReleased(0, 173) then
                selectedIdx = selectedIdx + 1
                if selectedIdx > #options then selectedIdx = 0 end
            end

            -- Confirm
            if IsControlJustReleased(0, 38) then
                if selectedIdx == 0 then
                    -- Request new deal
                    TriggerServerEvent('umeverse_drugs:server:requestDeal')
                    phoneOpen = false
                else
                    local deal = options[selectedIdx]
                    if deal and deal.state == 'pending' then
                        TriggerServerEvent('umeverse_drugs:server:acceptDeal', deal.dealIdx)
                        phoneOpen = false
                    elseif deal and deal.state == 'accepted' then
                        -- Set waypoint to meet location
                        local d = activeDeals[deal.dealIdx]
                        if d and d.meetCoords then
                            SetNewWaypoint(d.meetCoords.x, d.meetCoords.y)
                            DrugNotify('Waypoint set to meet location', 'info')
                        end
                        phoneOpen = false
                    end
                end
            end

            -- Cancel
            if IsControlJustReleased(0, 202) then
                phoneOpen = false
            end
        end
    end)
end

-- ═══════════════════════════════════════
-- Deal Accepted — spawn buyer NPC + blip
-- ═══════════════════════════════════════

RegisterNetEvent('umeverse_drugs:client:dealAccepted', function(dealIdx, meetCoords, buyerModel)
    if not meetCoords then return end

    -- Create meet location blip
    local blip = AddBlipForCoord(meetCoords.x, meetCoords.y, meetCoords.z)
    SetBlipSprite(blip, 480)
    SetBlipDisplay(blip, 4)
    SetBlipScale(blip, 0.8)
    SetBlipColour(blip, 5)
    SetBlipRoute(blip, true)
    BeginTextCommandSetBlipName('STRING')
    AddTextComponentString('Buyer Meet')
    EndTextCommandSetBlipName(blip)
    activeDealBlips[dealIdx] = blip

    -- Spawn buyer NPC
    local modelHash = GetHashKey(buyerModel)
    RequestModel(modelHash)
    local timeout = 5000
    while not HasModelLoaded(modelHash) and timeout > 0 do
        Wait(10)
        timeout = timeout - 10
    end
    if not HasModelLoaded(modelHash) then return end

    local ped = CreatePed(4, modelHash, meetCoords.x, meetCoords.y, meetCoords.z - 1.0, meetCoords.w or 0.0, false, true)
    SetEntityAsMissionEntity(ped, true, true)
    SetBlockingOfNonTemporaryEvents(ped, true)
    SetPedFleeAttributes(ped, 0, false)
    FreezeEntityPosition(ped, true)
    SetModelAsNoLongerNeeded(modelHash)

    activeDealNPCs[dealIdx] = ped

    DrugNotify('Deal accepted! Meet the buyer at the marked location.', 'info')

    -- Start monitoring for deal completion
    CreateThread(function()
        MonitorDealCompletion(dealIdx, meetCoords, ped)
    end)
end)

-- ═══════════════════════════════════════
-- Monitor Deal Completion (proximity to buyer)
-- ═══════════════════════════════════════

function MonitorDealCompletion(dealIdx, meetCoords, buyerPed)
    local meetPos = vector3(meetCoords.x, meetCoords.y, meetCoords.z)

    while activeDealNPCs[dealIdx] do
        Wait(0)

        if not DoesEntityExist(buyerPed) then break end

        local myPos = GetEntityCoords(PlayerPedId())
        local dist = #(myPos - meetPos)

        if dist < 30.0 then
            DrawDrugMarker(1, meetPos, 100, 200, 255, 100)
        end

        if dist < 3.0 then
            DrawText3DDrug(meetPos + vector3(0, 0, 1.0), '~g~Buyer~s~\nPress ~INPUT_CONTEXT~ to complete deal')

            if IsControlJustReleased(0, 38) and not IsBusy() then
                SetBusy(true)

                -- Play handoff animation
                TaskStartScenarioInPlace(PlayerPedId(), 'WORLD_HUMAN_DRUG_DEALER', 0, true)
                Wait(3000)
                ClearPedTasks(PlayerPedId())

                TriggerServerEvent('umeverse_drugs:server:completeDeal', dealIdx)

                SetBusy(false)
                break
            end
        end

        Wait(0)
    end
end

-- ═══════════════════════════════════════
-- Deal Completed / Failed / Expired
-- ═══════════════════════════════════════

RegisterNetEvent('umeverse_drugs:client:dealCompleted', function(dealIdx)
    CleanupDeal(dealIdx)
    DrugNotify('Deal completed! Payment received.', 'success')
end)

RegisterNetEvent('umeverse_drugs:client:dealExpired', function(dealIdx)
    CleanupDeal(dealIdx)
    DrugNotify('Deal expired — buyer left.', 'error')
end)

function CleanupDeal(dealIdx)
    if activeDealBlips[dealIdx] and DoesBlipExist(activeDealBlips[dealIdx]) then
        RemoveBlip(activeDealBlips[dealIdx])
    end
    activeDealBlips[dealIdx] = nil

    if activeDealNPCs[dealIdx] and DoesEntityExist(activeDealNPCs[dealIdx]) then
        DeleteEntity(activeDealNPCs[dealIdx])
    end
    activeDealNPCs[dealIdx] = nil
end

-- ═══════════════════════════════════════
-- New Deal Received notification
-- ═══════════════════════════════════════

RegisterNetEvent('umeverse_drugs:client:newDealAvailable', function(dealLabel)
    DrugNotify('New burner deal: ' .. (dealLabel or 'Unknown'), 'info')
end)

-- ═══════════════════════════════════════
-- Cleanup
-- ═══════════════════════════════════════

AddEventHandler('onResourceStop', function(resource)
    if resource == GetCurrentResourceName() then
        for idx, _ in pairs(activeDealBlips) do
            CleanupDeal(idx)
        end
        phoneOpen = false
    end
end)
