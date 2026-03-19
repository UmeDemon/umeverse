--[[
    Umeverse Jobs - Bus Driver
    Drive a bus along a route, stopping at each bus stop for passengers
]]

local cfg = JobsConfig.Bus
local currentRoute = nil
local currentStopIdx = 0

RegisterNetEvent('umeverse_jobs:client:startJob_bus', function()
    -- Pick a random route
    local routeIdx = math.random(#cfg.routes)
    currentRoute = cfg.routes[routeIdx]
    currentStopIdx = 1

    local veh = SpawnJobVehicle(cfg.vehicle.model, cfg.vehicle.spawn)
    if not veh then
        JobNotify('Failed to spawn bus.', 'error')
        CleanupJob()
        return
    end

    JobNotify('Route: ~y~' .. currentRoute.label .. '~w~ assigned! Follow the GPS.', 'info')
    SetNextBusStop()
    BusLoop()
end)

function SetNextBusStop()
    ClearJobBlips()
    if currentStopIdx <= #currentRoute.stops then
        local stop = currentRoute.stops[currentStopIdx]
        AddJobBlip(stop.coords, 513, 5, stop.name, true)
    end
end

function BusLoop()
    CreateThread(function()
        while GetActiveJob() == 'bus' do
            local sleep = 500
            local myPos = GetEntityCoords(PlayerPedId())

            if currentStopIdx <= #currentRoute.stops then
                local stop = currentRoute.stops[currentStopIdx]
                local dist = #(myPos - stop.coords)

                if dist < 30.0 then
                    sleep = 0
                    DrawJobMarker(1, stop.coords, 50, 100, 200, 120)
                    DrawText3D(stop.coords + vector3(0, 0, 2.0), stop.name)

                    if dist < 6.0 then
                        local veh = GetJobVehicle()
                        if veh and IsPedInVehicle(PlayerPedId(), veh, false) then
                            ShowHelpText('Press ~INPUT_CONTEXT~ to stop for passengers')
                            if IsControlJustReleased(0, 38) then
                                BoardPassengers()
                            end
                        end
                    end
                end
            end

            Wait(sleep)
        end
    end)
end

function BoardPassengers()
    local ped = PlayerPedId()
    local veh = GetJobVehicle()
    if not veh then return end

    -- Stop the bus
    TaskVehicleTempAction(ped, veh, 1, 3000)
    JobNotify('Passengers boarding at ~y~' .. currentRoute.stops[currentStopIdx].name, 'info')

    -- Open doors animation
    SetVehicleDoorOpen(veh, 0, false, false)
    Wait(4000)
    SetVehicleDoorShut(veh, 0, false)

    -- Pay for this stop
    TriggerServerEvent('umeverse_jobs:server:busPay')
    OnTaskComplete(JobsConfig.Bus.payPerStop[GetJobGrade() + 1] or JobsConfig.Bus.payPerStop[1])

    currentStopIdx = currentStopIdx + 1
    if currentStopIdx > #currentRoute.stops then
        JobNotify('Route ~g~' .. currentRoute.label .. '~w~ complete! Return to the depot or /endshift.', 'success')
        ClearJobBlips()
        AddJobBlip(vector3(cfg.clockIn.x, cfg.clockIn.y, cfg.clockIn.z), 513, 5, 'Return to Depot', true)
        WaitForBusReturn()
    else
        SetNextBusStop()
        JobNotify('Next stop: ~y~' .. currentRoute.stops[currentStopIdx].name, 'info')
    end
end

function WaitForBusReturn()
    CreateThread(function()
        while GetActiveJob() == 'bus' do
            local dist = #(GetEntityCoords(PlayerPedId()) - vector3(cfg.clockIn.x, cfg.clockIn.y, cfg.clockIn.z))
            if dist < 15.0 then
                DrawJobMarker(1, vector3(cfg.clockIn.x, cfg.clockIn.y, cfg.clockIn.z), 50, 200, 50, 120)
                if dist < 5.0 then
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
