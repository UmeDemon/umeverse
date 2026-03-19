--[[
    Umeverse Jobs - Garbage Collector
    Drive a garbage truck along a route and collect trash bags at each stop
]]

local cfg = JobsConfig.Garbage
local currentRoute = nil
local currentStop = 0
local routeBlip = nil

RegisterNetEvent('umeverse_jobs:client:startJob_garbage', function()
    -- Pick a random route
    local routeIdx = math.random(#cfg.routes)
    currentRoute = cfg.routes[routeIdx]
    currentStop = 1

    -- Spawn garbage truck
    local veh = SpawnJobVehicle(cfg.vehicle.model, cfg.vehicle.spawn)
    if not veh then
        JobNotify('Failed to spawn vehicle.', 'error')
        CleanupJob()
        return
    end

    JobNotify('Garbage route assigned! Follow the GPS to each pickup.', 'info')
    SetNextGarbageBlip()
    GarbageLoop()
end)

function SetNextGarbageBlip()
    ClearJobBlips()
    if currentStop <= #currentRoute then
        local stop = currentRoute[currentStop]
        AddJobBlip(stop, 1, 25, 'Trash Pickup #' .. currentStop, true)
    end
end

function GarbageLoop()
    CreateThread(function()
        while GetActiveJob() == 'garbage' do
            local sleep = 500
            local myPos = GetEntityCoords(PlayerPedId())

            if currentStop <= #currentRoute then
                local stop = currentRoute[currentStop]
                local dist = #(myPos - stop)

                if dist < 20.0 then
                    sleep = 0
                    DrawJobMarker(1, stop, 200, 150, 0, 120)

                    if dist < 3.0 then
                        local veh = GetJobVehicle()
                        if veh and IsPedInVehicle(PlayerPedId(), veh, false) then
                            ShowHelpText('Press ~INPUT_CONTEXT~ to exit and collect trash')
                            if IsControlJustReleased(0, 38) then
                                TaskLeaveVehicle(PlayerPedId(), veh, 0)
                                Wait(2000)
                                CollectTrash(stop)
                            end
                        else
                            ShowHelpText('Press ~INPUT_CONTEXT~ to pick up trash bag')
                            if IsControlJustReleased(0, 38) then
                                CollectTrash(stop)
                            end
                        end
                    end
                end
            end

            Wait(sleep)
        end
    end)
end

function CollectTrash(pos)
    -- Walk to position
    TaskGoToCoordAnyMeans(PlayerPedId(), pos.x, pos.y, pos.z, 1.0, 0, false, 786603, 0xbf800000)
    Wait(1500)

    -- Pick up animation
    PlayJobAnim('anim@mp_snowball', 'pickup_snowball', 2000, 0)
    Wait(2500)
    StopJobAnim()

    -- Carry animation back
    PlayJobAnim('missfinale_c2mcs_1', 'fin_c2_mcs_1_camman', 3000, 49)
    Wait(1000)

    -- Walk back to vehicle
    local veh = GetJobVehicle()
    if veh and DoesEntityExist(veh) then
        local vehPos = GetEntityCoords(veh)
        TaskGoToCoordAnyMeans(PlayerPedId(), vehPos.x, vehPos.y, vehPos.z, 1.0, 0, false, 786603, 0xbf800000)
        Wait(3000)
        StopJobAnim()
        TaskEnterVehicle(PlayerPedId(), veh, 5000, -1, 2.0, 1, 0)
        Wait(4000)
    else
        StopJobAnim()
    end

    -- Pay for this bag
    TriggerServerEvent('umeverse_jobs:server:garbagePay')
    OnTaskComplete(JobsConfig.Garbage.payPerBag[GetJobGrade() + 1] or JobsConfig.Garbage.payPerBag[1])
    JobNotify('Trash collected! (' .. currentStop .. '/' .. #currentRoute .. ')', 'success')

    currentStop = currentStop + 1
    if currentStop > #currentRoute then
        -- Route complete
        JobNotify('Route complete! Return to the depot or use /endshift.', 'success')
        ClearJobBlips()
        AddJobBlip(vector3(cfg.clockIn.x, cfg.clockIn.y, cfg.clockIn.z), 1, 25, 'Return to Depot', true)
        WaitForDepotReturn()
    else
        SetNextGarbageBlip()
    end
end

function WaitForDepotReturn()
    CreateThread(function()
        while GetActiveJob() == 'garbage' do
            local dist = #(GetEntityCoords(PlayerPedId()) - vector3(cfg.clockIn.x, cfg.clockIn.y, cfg.clockIn.z))
            if dist < 10.0 then
                DrawJobMarker(1, vector3(cfg.clockIn.x, cfg.clockIn.y, cfg.clockIn.z), 50, 200, 50, 120)
                if dist < 4.0 then
                    ShowHelpText('Press ~INPUT_CONTEXT~ to end shift')
                    if IsControlJustReleased(0, 38) then
                        TriggerEvent('umeverse_jobs:client:endShift')
                        return
                    end
                end
            end
            Wait(500)
        end
    end)
end
