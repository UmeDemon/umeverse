--[[
    Umeverse Drugs - Client Supply Runs
    Route selection, delivery vehicle, timer, waypoint, ambush handling.
]]

local UME = exports['umeverse_core']:GetCoreObject()

local activeRun = nil          -- { routeIdx, vehicle, startTime, blip, timerBlip }
local runMenuOpen = false

-- ═══════════════════════════════════════
-- Supply Run Board (at first warehouse)
-- ═══════════════════════════════════════

local runBoardCoords = nil

CreateThread(function()
    if not DrugConfig.SupplyRuns.enabled then return end
    Wait(5000)

    -- Place supply run board at first warehouse
    if #DrugConfig.Warehouses.locations > 0 then
        local wh = DrugConfig.Warehouses.locations[1]
        runBoardCoords = vector3(wh.coords.x + 3.0, wh.coords.y, wh.coords.z)
    end
end)

CreateThread(function()
    if not DrugConfig.SupplyRuns.enabled then return end
    Wait(6000)

    while true do
        local sleep = 1000
        if not runBoardCoords then Wait(sleep) goto continue end

        local myPos = GetEntityCoords(PlayerPedId())
        local dist = #(myPos - runBoardCoords)

        if not IsBusy() and not activeRun and not runMenuOpen then
            if dist < DrugConfig.MarkerDrawDistance then
                sleep = 0
                DrawDrugMarker(1, runBoardCoords, 255, 200, 0, 120)
                DrawText3DDrug(runBoardCoords + vector3(0, 0, 1.0), '~y~Supply Run Board')

                if dist < DrugConfig.InteractDistance then
                    ShowDrugHelp('Press ~INPUT_CONTEXT~ to view supply runs')
                    if IsControlJustReleased(0, 38) then
                        OpenRunMenu()
                    end
                end
            end
        end

        Wait(sleep)
        ::continue::
    end
end)

-- ═══════════════════════════════════════
-- Route Selection Menu
-- ═══════════════════════════════════════

function OpenRunMenu()
    if IsBusy() or runMenuOpen or activeRun then return end
    runMenuOpen = true

    UME.TriggerServerCallback('umeverse_drugs:getSupplyRoutes', function(data)
        if not data or not data.routes then
            runMenuOpen = false
            return
        end

        if data.onRun then
            runMenuOpen = false
            DrugNotify('Already on a supply run!', 'error')
            return
        end

        if data.cooldown > 0 then
            runMenuOpen = false
            DrugNotify('Cooldown: ' .. math.ceil(data.cooldown / 60) .. ' min remaining', 'warning')
            return
        end

        local routes = data.routes
        local selectedIdx = 1

        CreateThread(function()
            while runMenuOpen do
                Wait(0)

                local text = '~y~Supply Runs~s~\n\n'
                for i, route in ipairs(routes) do
                    local status = route.available and '~g~' or '~r~Lv.' .. route.requiredLevel .. ' '
                    local reward = '$' .. (route.reward.black + route.reward.cash) .. ' + ' .. route.reward.rep .. 'xp'
                    local time = math.floor(route.timeLimit / 60) .. 'min'

                    if i == selectedIdx then
                        text = text .. '~y~> ' .. status .. route.label .. '~s~ (' .. reward .. ', ' .. time .. ')\n'
                    else
                        text = text .. '  ' .. status .. route.label .. '~s~ (' .. reward .. ', ' .. time .. ')\n'
                    end
                end

                text = text .. '\n~INPUT_CELLPHONE_UP~/~INPUT_CELLPHONE_DOWN~ Select'
                text = text .. '\n~INPUT_CONTEXT~ Start | ~INPUT_FRONTEND_CANCEL~ Cancel'

                local pos = GetEntityCoords(PlayerPedId())
                DrawText3DDrug(vector3(pos.x, pos.y, pos.z + 0.5), text)

                if IsControlJustReleased(0, 172) then
                    selectedIdx = selectedIdx - 1
                    if selectedIdx < 1 then selectedIdx = #routes end
                end
                if IsControlJustReleased(0, 173) then
                    selectedIdx = selectedIdx + 1
                    if selectedIdx > #routes then selectedIdx = 1 end
                end

                if IsControlJustReleased(0, 38) then
                    runMenuOpen = false
                    if routes[selectedIdx].available then
                        TriggerServerEvent('umeverse_drugs:server:startSupplyRun', selectedIdx)
                    else
                        DrugNotify('Need Level ' .. routes[selectedIdx].requiredLevel .. '!', 'error')
                    end
                end

                if IsControlJustReleased(0, 202) then
                    runMenuOpen = false
                end
            end
        end)
    end)
end

-- ═══════════════════════════════════════
-- Start Supply Run (from server)
-- ═══════════════════════════════════════

RegisterNetEvent('umeverse_drugs:client:startSupplyRun', function(routeIdx)
    local route = DrugConfig.SupplyRuns.routes[routeIdx]
    if not route then return end

    -- Spawn delivery vehicle at pickup
    local vehicleHash = GetHashKey(route.vehicleModel)
    RequestModel(vehicleHash)
    local timeout = 5000
    while not HasModelLoaded(vehicleHash) and timeout > 0 do
        Wait(10)
        timeout = timeout - 10
    end
    if not HasModelLoaded(vehicleHash) then return end

    local pickup = route.pickupCoords
    local veh = CreateVehicle(vehicleHash, pickup.x, pickup.y, pickup.z, pickup.w, true, false)
    SetEntityAsMissionEntity(veh, true, true)
    SetVehicleOnGroundProperly(veh)
    SetModelAsNoLongerNeeded(vehicleHash)

    -- Set waypoint to pickup
    SetNewWaypoint(pickup.x, pickup.y)

    -- Create delivery blip
    local deliveryBlip = AddBlipForCoord(route.deliveryCoords.x, route.deliveryCoords.y, route.deliveryCoords.z)
    SetBlipSprite(deliveryBlip, 501)
    SetBlipDisplay(deliveryBlip, 4)
    SetBlipScale(deliveryBlip, 0.9)
    SetBlipColour(deliveryBlip, 5)
    SetBlipRoute(deliveryBlip, false)
    BeginTextCommandSetBlipName('STRING')
    AddTextComponentString('Delivery Point')
    EndTextCommandSetBlipName(deliveryBlip)

    -- Create vehicle blip
    local vehBlip = AddBlipForEntity(veh)
    SetBlipSprite(vehBlip, 326)
    SetBlipDisplay(vehBlip, 4)
    SetBlipScale(vehBlip, 0.8)
    SetBlipColour(vehBlip, 5)
    BeginTextCommandSetBlipName('STRING')
    AddTextComponentString('Delivery Vehicle')
    EndTextCommandSetBlipName(vehBlip)

    activeRun = {
        routeIdx = routeIdx,
        vehicle = veh,
        startTime = GetGameTimer(),
        timeLimit = route.timeLimit * 1000,
        deliveryCoords = route.deliveryCoords,
        deliveryBlip = deliveryBlip,
        vehicleBlip = vehBlip,
        pickedUp = false,
    }

    DrugNotify('Supply run started! Pick up the vehicle and deliver it.', 'info')

    -- Run monitoring thread
    CreateThread(MonitorSupplyRun)
end)

-- ═══════════════════════════════════════
-- Monitor Active Supply Run
-- ═══════════════════════════════════════

function MonitorSupplyRun()
    while activeRun do
        Wait(0)

        local elapsed = GetGameTimer() - activeRun.startTime
        local remaining = activeRun.timeLimit - elapsed
        local remainSec = math.ceil(remaining / 1000)

        -- Timer display
        local pos = GetEntityCoords(PlayerPedId())
        local timerColor = remainSec > 60 and '~g~' or (remainSec > 30 and '~y~' or '~r~')
        DrawText3DDrug(vector3(pos.x, pos.y, pos.z + 1.3),
            '~y~Supply Run~s~ | ' .. timerColor .. math.floor(remainSec / 60) .. ':' .. string.format('%02d', remainSec % 60))

        -- Check if time ran out
        if remaining <= 0 then
            DrugNotify('Supply run failed — time\'s up!', 'error')
            TriggerServerEvent('umeverse_drugs:server:failSupplyRun')
            CleanupSupplyRun()
            break
        end

        -- Check if vehicle is destroyed
        if activeRun.vehicle and DoesEntityExist(activeRun.vehicle) then
            if IsEntityDead(activeRun.vehicle) then
                DrugNotify('Vehicle destroyed — supply run failed!', 'error')
                TriggerServerEvent('umeverse_drugs:server:failSupplyRun')
                CleanupSupplyRun()
                break
            end

            -- Check if player is in the vehicle
            if IsPedInVehicle(PlayerPedId(), activeRun.vehicle, false) then
                activeRun.pickedUp = true

                -- Set waypoint to delivery
                if not IsWaypointActive() then
                    SetNewWaypoint(activeRun.deliveryCoords.x, activeRun.deliveryCoords.y)
                end
                SetBlipRoute(activeRun.deliveryBlip, true)
            end

            -- Check delivery proximity
            if activeRun.pickedUp then
                local vehPos = GetEntityCoords(activeRun.vehicle)
                local deliveryPos = vector3(activeRun.deliveryCoords.x, activeRun.deliveryCoords.y, activeRun.deliveryCoords.z)
                local dist = #(vehPos - deliveryPos)

                if dist < 10.0 then
                    DrawDrugMarker(1, deliveryPos, 0, 255, 0, 150)
                    DrawText3DDrug(deliveryPos + vector3(0, 0, 1.0), '~g~Delivery Point~s~\nStop vehicle here')

                    if dist < 5.0 and GetEntitySpeed(activeRun.vehicle) < 1.0 then
                        -- Delivered
                        TriggerServerEvent('umeverse_drugs:server:completeSupplyRun', activeRun.routeIdx)
                        CleanupSupplyRun()
                        break
                    end
                end
            end
        else
            -- Vehicle doesn't exist anymore
            DrugNotify('Vehicle lost — supply run failed!', 'error')
            TriggerServerEvent('umeverse_drugs:server:failSupplyRun')
            CleanupSupplyRun()
            break
        end

        -- Ambush check
        if DrugConfig.SupplyRuns.ambush.enabled and activeRun.pickedUp then
            if not activeRun.lastAmbushCheck or GetGameTimer() - activeRun.lastAmbushCheck > DrugConfig.SupplyRuns.ambush.checkInterval * 1000 then
                activeRun.lastAmbushCheck = GetGameTimer()
                if math.random(100) <= DrugConfig.SupplyRuns.ambush.chance then
                    SpawnAmbush()
                end
            end
        end
    end
end

-- ═══════════════════════════════════════
-- Ambush Spawning
-- ═══════════════════════════════════════

local ambushPeds = {}

function SpawnAmbush()
    if not activeRun then return end

    local myPos = GetEntityCoords(PlayerPedId())
    local ambushCfg = DrugConfig.SupplyRuns.ambush

    -- Spawn chase vehicle
    local vehHash = GetHashKey(ambushCfg.vehicleModel)
    local pedHash = GetHashKey(ambushCfg.pedModel)
    RequestModel(vehHash)
    RequestModel(pedHash)

    local timeout = 3000
    while (not HasModelLoaded(vehHash) or not HasModelLoaded(pedHash)) and timeout > 0 do
        Wait(10)
        timeout = timeout - 10
    end
    if not HasModelLoaded(vehHash) or not HasModelLoaded(pedHash) then return end

    local angle = math.rad(math.random(360))
    local spawnDist = 60.0
    local spawnPos = vector3(
        myPos.x + math.cos(angle) * spawnDist,
        myPos.y + math.sin(angle) * spawnDist,
        myPos.z
    )

    local foundGround, groundZ = GetGroundZFor_3dCoord(spawnPos.x, spawnPos.y, spawnPos.z + 50.0, false)
    if foundGround then spawnPos = vector3(spawnPos.x, spawnPos.y, groundZ) end

    local chaseVeh = CreateVehicle(vehHash, spawnPos.x, spawnPos.y, spawnPos.z, math.random(360) + 0.0, true, false)
    SetEntityAsMissionEntity(chaseVeh, true, true)
    SetVehicleOnGroundProperly(chaseVeh)

    local count = math.random(ambushCfg.pedCount[1], ambushCfg.pedCount[2])
    for i = 1, count do
        local seat = i - 2 -- -1 = driver, 0 = passenger, etc
        local ped = CreatePedInsideVehicle(chaseVeh, 4, pedHash, seat, true, false)
        if ped and ped ~= 0 then
            SetEntityAsMissionEntity(ped, true, true)
            GiveWeaponToPed(ped, GetHashKey('WEAPON_MICROSMG'), 200, false, true)
            SetPedCombatAttributes(ped, 46, true)
            SetPedFleeAttributes(ped, 0, false)

            if i == 1 then
                TaskVehicleChase(ped, PlayerPedId())
            else
                TaskCombatPed(ped, PlayerPedId(), 0, 16)
            end

            ambushPeds[#ambushPeds + 1] = { ped = ped, despawnAt = GetGameTimer() + 120000 }
        end
    end

    SetModelAsNoLongerNeeded(vehHash)
    SetModelAsNoLongerNeeded(pedHash)

    DrugNotify('~r~Ambush! Hostiles incoming!', 'error')
end

-- ═══════════════════════════════════════
-- Cleanup
-- ═══════════════════════════════════════

function CleanupSupplyRun()
    if activeRun then
        if activeRun.deliveryBlip and DoesBlipExist(activeRun.deliveryBlip) then
            RemoveBlip(activeRun.deliveryBlip)
        end
        if activeRun.vehicleBlip and DoesBlipExist(activeRun.vehicleBlip) then
            RemoveBlip(activeRun.vehicleBlip)
        end
        -- Don't delete the vehicle — leave it for the player or let it despawn naturally
        activeRun = nil
    end
end

-- Cleanup ambush peds periodically
CreateThread(function()
    while true do
        Wait(15000)
        local now = GetGameTimer()
        local alive = {}
        for _, entry in ipairs(ambushPeds) do
            if now < entry.despawnAt and DoesEntityExist(entry.ped) and not IsEntityDead(entry.ped) then
                alive[#alive + 1] = entry
            else
                if DoesEntityExist(entry.ped) then DeleteEntity(entry.ped) end
            end
        end
        ambushPeds = alive
    end
end)

AddEventHandler('onResourceStop', function(resource)
    if resource == GetCurrentResourceName() then
        CleanupSupplyRun()
        for _, entry in ipairs(ambushPeds) do
            if DoesEntityExist(entry.ped) then DeleteEntity(entry.ped) end
        end
        ambushPeds = {}
    end
end)
