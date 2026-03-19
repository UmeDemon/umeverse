--[[
    Umeverse Drugs - Client Raids
    Warning notification, SWAT spawning, caught detection, cleanup.
]]

local UME = exports['umeverse_core']:GetCoreObject()

local activeRaid = nil      -- { blip, peds = {}, endTime, location }
local raidWarning = false

-- ═══════════════════════════════════════
-- Raid Warning
-- ═══════════════════════════════════════

RegisterNetEvent('umeverse_drugs:client:raidWarning', function(raidData)
    if not raidData or not raidData.coords then return end

    raidWarning = true

    -- Flash warning
    DrugNotify('~r~WARNING: Law enforcement raid incoming! (' .. DrugConfig.Raids.warningTime .. 's)', 'error')

    -- Warning blip (temporary)
    local warningBlip = AddBlipForCoord(raidData.coords.x, raidData.coords.y, raidData.coords.z)
    SetBlipSprite(warningBlip, 161)
    SetBlipDisplay(warningBlip, 4)
    SetBlipScale(warningBlip, 1.2)
    SetBlipColour(warningBlip, 1)
    SetBlipFlashes(warningBlip, true)
    BeginTextCommandSetBlipName('STRING')
    AddTextComponentString('RAID INCOMING')
    EndTextCommandSetBlipName(warningBlip)

    -- Remove warning blip after warning time
    SetTimeout(DrugConfig.Raids.warningTime * 1000, function()
        if DoesBlipExist(warningBlip) then
            RemoveBlip(warningBlip)
        end
        raidWarning = false
    end)
end)

-- ═══════════════════════════════════════
-- Raid Start — spawn SWAT
-- ═══════════════════════════════════════

RegisterNetEvent('umeverse_drugs:client:raidStart', function(raidData)
    if not raidData or not raidData.coords then return end

    DrugNotify('~r~RAID IN PROGRESS! Stay away or get caught!', 'error')

    local raidCoords = vector3(raidData.coords.x, raidData.coords.y, raidData.coords.z)

    -- Create raid blip
    local raidBlip = AddBlipForCoord(raidCoords.x, raidCoords.y, raidCoords.z)
    SetBlipSprite(raidBlip, 161)
    SetBlipDisplay(raidBlip, 4)
    SetBlipScale(raidBlip, 1.0)
    SetBlipColour(raidBlip, 1)
    BeginTextCommandSetBlipName('STRING')
    AddTextComponentString('Police Raid')
    EndTextCommandSetBlipName(raidBlip)

    -- Spawn SWAT peds
    local raidPeds = {}
    local swatModel = GetHashKey('s_m_y_swat_01')
    RequestModel(swatModel)
    local timeout = 5000
    while not HasModelLoaded(swatModel) and timeout > 0 do
        Wait(10)
        timeout = timeout - 10
    end

    if HasModelLoaded(swatModel) then
        local officerCount = math.random(DrugConfig.Raids.swatOfficers[1], DrugConfig.Raids.swatOfficers[2])
        for i = 1, officerCount do
            local angle = (i / officerCount) * math.pi * 2
            local spawnOffset = vector3(
                math.cos(angle) * 8.0,
                math.sin(angle) * 8.0,
                0.0
            )
            local spawnPos = raidCoords + spawnOffset

            local ped = CreatePed(4, swatModel, spawnPos.x, spawnPos.y, spawnPos.z - 1.0, math.random(360) + 0.0, true, true)
            if ped and ped ~= 0 then
                SetEntityAsMissionEntity(ped, true, true)
                GiveWeaponToPed(ped, GetHashKey('WEAPON_CARBINERIFLE'), 200, false, true)
                SetPedArmour(ped, 100)
                SetPedCombatAttributes(ped, 46, true)
                SetPedFleeAttributes(ped, 0, false)

                -- Guard the area
                TaskGuardCurrentPosition(ped, 10.0, 10.0, true)

                raidPeds[#raidPeds + 1] = ped
            end
        end
        SetModelAsNoLongerNeeded(swatModel)
    end

    activeRaid = {
        blip = raidBlip,
        peds = raidPeds,
        endTime = GetGameTimer() + (DrugConfig.Raids.raidDuration * 1000),
        location = raidCoords,
    }

    -- Monitor raid (caught detection + cleanup)
    CreateThread(MonitorRaid)
end)

-- ═══════════════════════════════════════
-- Monitor Raid (caught detection & cleanup)
-- ═══════════════════════════════════════

function MonitorRaid()
    if not activeRaid then return end

    local caughtNotified = false

    while activeRaid do
        Wait(500)

        local now = GetGameTimer()

        -- Check if raid is over
        if now >= activeRaid.endTime then
            CleanupRaid()
            DrugNotify('The raid is over. Police are leaving the area.', 'info')
            break
        end

        -- Draw raid marker
        if activeRaid.location then
            local dist = #(GetEntityCoords(PlayerPedId()) - activeRaid.location)
            if dist < 100.0 then
                DrawDrugMarker(1, activeRaid.location, 255, 0, 0, 80)
            end

            -- Caught detection — player is too close
            if dist < 15.0 and not caughtNotified then
                caughtNotified = true
                DrugNotify('~r~You\'ve been spotted at the raid location!', 'error')
                TriggerServerEvent('umeverse_drugs:server:raidCaught')

                -- SWAT targets the player
                for _, ped in ipairs(activeRaid.peds) do
                    if DoesEntityExist(ped) and not IsEntityDead(ped) then
                        TaskCombatPed(ped, PlayerPedId(), 0, 16)
                    end
                end
            end
        end

        -- Timer display when close
        if activeRaid.location then
            local dist = #(GetEntityCoords(PlayerPedId()) - activeRaid.location)
            if dist < 80.0 then
                local remainSec = math.ceil((activeRaid.endTime - now) / 1000)
                local pos = activeRaid.location + vector3(0, 0, 3.0)
                DrawText3DDrug(pos, '~r~POLICE RAID~s~\n' .. remainSec .. 's remaining')
            end
        end
    end
end

-- ═══════════════════════════════════════
-- Raid Ended (from server)
-- ═══════════════════════════════════════

RegisterNetEvent('umeverse_drugs:client:raidEnded', function()
    CleanupRaid()
    DrugNotify('The raid has ended.', 'info')
end)

-- ═══════════════════════════════════════
-- Seizure notification
-- ═══════════════════════════════════════

RegisterNetEvent('umeverse_drugs:client:raidSeizure', function(targetType)
    local locations = {
        processLocation = 'processing lab',
        stashHouse = 'stash house',
        warehouse = 'warehouse',
    }
    local label = locations[targetType] or 'location'
    DrugNotify('~r~Police seized contraband from your ' .. label .. '!', 'error')
end)

-- ═══════════════════════════════════════
-- Cleanup
-- ═══════════════════════════════════════

function CleanupRaid()
    if activeRaid then
        if activeRaid.blip and DoesBlipExist(activeRaid.blip) then
            RemoveBlip(activeRaid.blip)
        end
        for _, ped in ipairs(activeRaid.peds) do
            if DoesEntityExist(ped) then
                DeleteEntity(ped)
            end
        end
        activeRaid = nil
    end
end

AddEventHandler('onResourceStop', function(resource)
    if resource == GetCurrentResourceName() then
        CleanupRaid()
    end
end)
