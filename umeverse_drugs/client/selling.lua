--[[
    Umeverse Drugs - Selling
    Sell packaged drugs to NPCs on street corners
    Includes police alert system and dynamic pricing
]]

local UME = exports['umeverse_core']:GetCoreObject()

local cornerNpcs = {}
local sellCooldowns = {}

-- ═══════════════════════════════════════
-- Spawn Corner NPCs
-- ═══════════════════════════════════════

CreateThread(function()
    Wait(5000)

    for i, corner in ipairs(DrugConfig.SellCorners) do
        local ped = SpawnDrugNpc(corner.npcModel, corner.coords)
        if ped then
            cornerNpcs[i] = ped
        end
    end
end)

-- ═══════════════════════════════════════
-- Selling Interaction Loop
-- ═══════════════════════════════════════

CreateThread(function()
    Wait(6000)
    while true do
        local sleep = 1000
        local myPos = GetEntityCoords(PlayerPedId())

        if not IsBusy() then
            for i, corner in ipairs(DrugConfig.SellCorners) do
                local pos = vector3(corner.coords.x, corner.coords.y, corner.coords.z)
                local dist = #(myPos - pos)

                if dist < DrugConfig.MarkerDrawDistance then
                    sleep = 0
                    DrawDrugMarker(1, pos, 200, 0, 0, 100)
                    DrawText3DDrug(vector3(pos.x, pos.y, pos.z + 1.2), '~r~' .. corner.label)

                    if dist < DrugConfig.InteractDistance then
                        -- Check cooldown
                        local now = GetGameTimer()
                        if sellCooldowns[i] and now - sellCooldowns[i] < (DrugConfig.SellCooldown * 1000) then
                            local remaining = math.ceil((DrugConfig.SellCooldown * 1000 - (now - sellCooldowns[i])) / 1000)
                            ShowDrugHelp('Come back in ~r~' .. remaining .. 's~s~')
                        else
                            -- Show available drugs for this corner
                            local drugList = ''
                            for _, drug in ipairs(corner.drugs) do
                                local info = DrugConfig.DrugSellItems[drug]
                                if info then
                                    drugList = drugList .. info.drug .. ', '
                                end
                            end
                            drugList = drugList:sub(1, -3)

                            ShowDrugHelp('Press ~INPUT_CONTEXT~ to sell drugs\nAvailable: ' .. drugList)

                            if IsControlJustReleased(0, 38) then
                                OpenSellMenu(i)
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
-- Sell Menu (Enhanced with demand, buyer rep, turf)
-- ═══════════════════════════════════════

local sellMenuOpen = false

function OpenSellMenu(cornerIdx)
    if IsBusy() or sellMenuOpen then return end

    local corner = DrugConfig.SellCorners[cornerIdx]
    if not corner then return end

    sellMenuOpen = true
    local selectedIdx = 1
    local drugs = corner.drugs

    -- Fetch demand + buyer rep + turf data from server
    local extraData = nil
    UME.TriggerServerCallback('umeverse_drugs:getSellInfo', function(data)
        extraData = data or {}
    end, cornerIdx)

    CreateThread(function()
        -- Wait briefly for callback (max 2s)
        local waitTime = 0
        while not extraData and waitTime < 2000 do
            Wait(50)
            waitTime = waitTime + 50
        end
        if not extraData then extraData = {} end

        while sellMenuOpen do
            Wait(0)

            local text = '~r~Drug Sale~s~'

            -- Turf indicator
            if extraData.ownsTurf then
                text = text .. ' ~g~[YOUR TURF +' .. math.floor((extraData.turfBonus or 0) * 100) .. '%]~s~'
            end

            -- Buyer rep indicator
            if extraData.buyerLevel and extraData.buyerLevel > 1 then
                text = text .. ' ~p~[Rep: ' .. (extraData.buyerLevelLabel or 'Unknown') .. ']~s~'
            end

            text = text .. '\n\n'

            for i, drugItem in ipairs(drugs) do
                local info = DrugConfig.DrugSellItems[drugItem]
                local cfg = DrugConfig.Drugs[info.config]
                local priceRange = cfg and ('$' .. cfg.sellPrice.min .. '-$' .. cfg.sellPrice.max) or '???'

                -- Demand indicator
                local demandTag = ''
                if extraData.demand and extraData.demand[info.config] then
                    local d = extraData.demand[info.config]
                    if d >= 80 then demandTag = ' ~g~HIGH'
                    elseif d >= 50 then demandTag = ' ~y~MED'
                    elseif d >= 25 then demandTag = ' ~o~LOW'
                    else demandTag = ' ~r~DEAD' end
                end

                if i == selectedIdx then
                    text = text .. '~y~> ' .. info.drug .. ' (' .. priceRange .. ')' .. demandTag .. '~s~\n'
                else
                    text = text .. '  ' .. info.drug .. ' (' .. priceRange .. ')' .. demandTag .. '~s~\n'
                end
            end
            text = text .. '\n~INPUT_CELLPHONE_UP~ / ~INPUT_CELLPHONE_DOWN~ Select\n~INPUT_CONTEXT~ Sell | ~INPUT_FRONTEND_CANCEL~ Cancel'

            local pos = GetEntityCoords(PlayerPedId())
            DrawText3DDrug(vector3(pos.x, pos.y, pos.z + 0.5), text)

            -- Navigate
            if IsControlJustReleased(0, 172) then
                selectedIdx = selectedIdx - 1
                if selectedIdx < 1 then selectedIdx = #drugs end
            end
            if IsControlJustReleased(0, 173) then
                selectedIdx = selectedIdx + 1
                if selectedIdx > #drugs then selectedIdx = 1 end
            end

            -- Sell
            if IsControlJustReleased(0, 38) then
                sellMenuOpen = false
                SellDrug(cornerIdx, drugs[selectedIdx])
            end

            -- Cancel
            if IsControlJustReleased(0, 202) then
                sellMenuOpen = false
            end
        end
    end)
end

-- ═══════════════════════════════════════
-- Execute Sale
-- ═══════════════════════════════════════

function SellDrug(cornerIdx, drugItem)
    if IsBusy() then return end

    -- Play handoff animation
    DrugProgress('Making the deal...', 5000, { dict = 'mp_common', anim = 'givetake1_a', flag = 49 }, function()
        TriggerServerEvent('umeverse_drugs:server:sellDrug', cornerIdx, drugItem)
    end)

    -- Set cooldown on this corner
    sellCooldowns[cornerIdx] = GetGameTimer()
end

-- ═══════════════════════════════════════
-- Police Alert (Client-side for on-duty LEOs)
-- ═══════════════════════════════════════

RegisterNetEvent('umeverse_drugs:client:policeAlert', function(coords, radius)
    -- Only show if player is LEO and on duty
    local pd = UME.GetPlayerData()
    if not pd or not pd.job then return end
    if pd.job.type ~= 'leo' or not pd.job.onduty then return end

    -- Add alert blip
    local blip = AddBlipForRadius(coords.x, coords.y, coords.z, radius)
    SetBlipHighDetail(blip, true)
    SetBlipColour(blip, 1) -- Red
    SetBlipAlpha(blip, 128)

    local pointBlip = AddBlipForCoord(coords.x, coords.y, coords.z)
    SetBlipSprite(pointBlip, 161) -- Drug pin
    SetBlipDisplay(pointBlip, 4)
    SetBlipScale(pointBlip, 0.9)
    SetBlipColour(pointBlip, 1)
    BeginTextCommandSetBlipName('STRING')
    AddTextComponentString('Suspicious Activity')
    EndTextCommandSetBlipName(pointBlip)

    DrugNotify('Suspicious activity reported in the area!', 'warning')

    -- Remove after duration
    local duration = DrugConfig.PoliceAlert.alertDuration * 1000
    SetTimeout(duration, function()
        if DoesBlipExist(blip) then RemoveBlip(blip) end
        if DoesBlipExist(pointBlip) then RemoveBlip(pointBlip) end
    end)
end)

-- ═══════════════════════════════════════
-- Sale result feedback
-- ═══════════════════════════════════════

RegisterNetEvent('umeverse_drugs:client:saleComplete', function(amount, drugName)
    DrugNotify('Sold ' .. drugName .. ' for ~g~$' .. amount, 'success')
end)
