--[[
    Umeverse Drugs - Client Turf System
    Territory capture mechanics, turf blips, and capture progress UI.
]]

local UME = exports['umeverse_core']:GetCoreObject()

local turfOwners = {}   -- [cornerIdx] = citizenid
local turfBlips = {}    -- Managed blips for turfs
local isCapturing = false
local captureProgress = 0

-- ═══════════════════════════════════════
-- Load turf data
-- ═══════════════════════════════════════

CreateThread(function()
    if not DrugConfig.Turf.enabled then return end
    Wait(6000)

    UME.TriggerServerCallback('umeverse_drugs:getTurfs', function(turfs)
        turfOwners = turfs or {}
        UpdateTurfBlips()
    end)
end)

-- ═══════════════════════════════════════
-- Turf update from server
-- ═══════════════════════════════════════

RegisterNetEvent('umeverse_drugs:client:turfUpdate', function(cornerIdx, ownerCid)
    turfOwners[cornerIdx] = ownerCid
    UpdateTurfBlips()
end)

-- ═══════════════════════════════════════
-- Turf Blip Management
-- ═══════════════════════════════════════

function UpdateTurfBlips()
    -- Remove old turf blips
    for _, blip in pairs(turfBlips) do
        if DoesBlipExist(blip) then RemoveBlip(blip) end
    end
    turfBlips = {}

    if not DrugConfig.Turf.enabled then return end

    local pd = UME.GetPlayerData()
    local myCid = pd and pd.citizenid or ''

    for cornerIdx, ownerCid in pairs(turfOwners) do
        local corner = DrugConfig.SellCorners[cornerIdx]
        if corner then
            local pos = corner.coords
            local isOwned = (ownerCid == myCid)
            local blipCfg = isOwned and DrugConfig.Turf.ownedBlip or DrugConfig.Turf.enemyBlip

            local blip = AddBlipForCoord(pos.x, pos.y, pos.z)
            SetBlipSprite(blip, blipCfg.sprite)
            SetBlipDisplay(blip, 4)
            SetBlipScale(blip, blipCfg.scale)
            SetBlipColour(blip, blipCfg.color)
            SetBlipAsShortRange(blip, true)
            BeginTextCommandSetBlipName('STRING')
            AddTextComponentString(blipCfg.label .. ': ' .. corner.label)
            EndTextCommandSetBlipName(blip)

            turfBlips[cornerIdx] = blip
        end
    end
end

-- ═══════════════════════════════════════
-- Turf Capture Interaction
-- ═══════════════════════════════════════

CreateThread(function()
    if not DrugConfig.Turf.enabled then return end
    Wait(7000)

    while true do
        local sleep = 1000
        local myPos = GetEntityCoords(PlayerPedId())

        if not IsBusy() and not isCapturing then
            for i, corner in ipairs(DrugConfig.SellCorners) do
                local pos = vector3(corner.coords.x, corner.coords.y, corner.coords.z)
                local dist = #(myPos - pos)

                if dist < DrugConfig.Turf.captureRadius then
                    sleep = 0

                    local pd = UME.GetPlayerData()
                    local myCid = pd and pd.citizenid or ''
                    local owner = turfOwners[i]

                    if owner == myCid then
                        -- Already owned — show release option
                        if dist < 3.0 then
                            ShowDrugHelp('Your turf: ~g~' .. corner.label .. '~s~\nPress ~INPUT_DETONATE~ to release')
                            if IsControlJustReleased(0, 47) then -- G key
                                TriggerServerEvent('umeverse_drugs:server:releaseTurf', i)
                            end
                        end
                    elseif not HasUnlocked('weed') then
                        -- Not high enough level, do nothing
                    else
                        -- Can capture
                        if dist < 3.0 then
                            ShowDrugHelp('Press and hold ~INPUT_CONTEXT~ to claim turf: ~r~' .. corner.label)
                            if IsControlPressed(0, 38) then
                                StartCapture(i)
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
-- Capture Process
-- ═══════════════════════════════════════

function StartCapture(cornerIdx)
    if isCapturing or IsBusy() then return end
    isCapturing = true
    captureProgress = 0

    local corner = DrugConfig.SellCorners[cornerIdx]
    local pos = vector3(corner.coords.x, corner.coords.y, corner.coords.z)
    local captureTime = DrugConfig.Turf.captureTime

    SetBusy(true)
    FreezeEntityPosition(PlayerPedId(), true)

    CreateThread(function()
        local startTime = GetGameTimer()

        while isCapturing do
            Wait(0)
            local elapsed = (GetGameTimer() - startTime) / 1000
            captureProgress = math.min(100, math.floor((elapsed / captureTime) * 100))

            local myPos = GetEntityCoords(PlayerPedId())
            DrawText3DDrug(vector3(myPos.x, myPos.y, myPos.z + 1.0),
                '~r~Claiming Turf: ' .. corner.label .. '~s~\n[' .. captureProgress .. '%]\nRelease E to cancel')

            -- Check if player moved too far
            if #(myPos - pos) > DrugConfig.Turf.captureRadius then
                isCapturing = false
                DrugNotify('Moved too far — capture cancelled!', 'error')
            end

            -- Check if still holding E (or not)
            if not IsControlPressed(0, 38) and elapsed > 1.0 then
                isCapturing = false
                DrugNotify('Turf capture cancelled', 'info')
            end

            -- Complete
            if elapsed >= captureTime then
                isCapturing = false
                TriggerServerEvent('umeverse_drugs:server:captureTurf', cornerIdx)
            end
        end

        FreezeEntityPosition(PlayerPedId(), false)
        SetBusy(false)
    end)
end

-- Cleanup on resource stop
AddEventHandler('onResourceStop', function(resource)
    if resource == GetCurrentResourceName() then
        for _, blip in pairs(turfBlips) do
            if DoesBlipExist(blip) then RemoveBlip(blip) end
        end
        turfBlips = {}
    end
end)
