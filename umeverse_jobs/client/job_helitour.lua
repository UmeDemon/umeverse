--[[
    Umeverse Jobs - Helicopter Tour
    Fly tourists along scenic routes hitting waypoints
]]

local cfg = JobsConfig.HeliTour
local currentRoute = nil
local currentWP = 0

RegisterNetEvent('umeverse_jobs:client:startJob_helitour', function()
    local veh = SpawnJobVehicle(cfg.vehicle.model, cfg.vehicle.spawn)
    if not veh then
        JobNotify('Failed to spawn helicopter.', 'error')
        CleanupJob()
        return
    end

    -- Pick random route
    local routeIdx = math.random(#cfg.routes)
    currentRoute = cfg.routes[routeIdx]
    currentWP = 1

    JobNotify('Tour: ~y~' .. currentRoute.label .. '~w~! Fly to each waypoint.', 'info')
    SetNextHeliWaypoint()
    HeliTourLoop()
end)

function SetNextHeliWaypoint()
    ClearJobBlips()
    if currentWP <= #currentRoute.waypoints then
        local wp = currentRoute.waypoints[currentWP]
        AddJobBlip(wp.coords, 43, 4, wp.name .. ' (' .. currentWP .. '/' .. #currentRoute.waypoints .. ')', true)
    end
end

function HeliTourLoop()
    CreateThread(function()
        while GetActiveJob() == 'helitour' do
            local sleep = 500
            local ped = PlayerPedId()
            local myPos = GetEntityCoords(ped)

            if currentWP <= #currentRoute.waypoints then
                local wp = currentRoute.waypoints[currentWP]
                local dist = #(myPos - wp.coords)

                if dist < 200.0 then
                    sleep = 0
                    -- Draw 3D text at waypoint
                    if dist < 100.0 then
                        DrawText3D(wp.coords, '~y~' .. wp.name)
                    end

                    if dist < cfg.waypointRadius then
                        -- Waypoint reached!
                        JobNotify('Waypoint reached: ~g~' .. wp.name .. '~w~ (' .. currentWP .. '/' .. #currentRoute.waypoints .. ')', 'success')
                        TriggerServerEvent('umeverse_jobs:server:heliTourWaypoint')
                        local tourPay = JobsConfig.HeliTour.payPerTour[GetJobGrade() + 1] or JobsConfig.HeliTour.payPerTour[1]
                        OnTaskComplete(math.floor(tourPay / 3))

                        currentWP = currentWP + 1
                        if currentWP > #currentRoute.waypoints then
                            JobNotify('Tour ~g~' .. currentRoute.label .. '~w~ complete! Return to helipad or /endshift.', 'success')
                            ClearJobBlips()
                            AddJobBlip(vector3(cfg.clockIn.x, cfg.clockIn.y, cfg.clockIn.z), 43, 4, 'Return to Helipad', true)
                            WaitForHeliReturn()
                            return
                        else
                            SetNextHeliWaypoint()
                        end
                    end
                end
            end

            Wait(sleep)
        end
    end)
end

function WaitForHeliReturn()
    CreateThread(function()
        while GetActiveJob() == 'helitour' do
            local dist = #(GetEntityCoords(PlayerPedId()) - vector3(cfg.clockIn.x, cfg.clockIn.y, cfg.clockIn.z))
            if dist < 30.0 then
                DrawJobMarker(1, vector3(cfg.clockIn.x, cfg.clockIn.y, cfg.clockIn.z), 50, 200, 50, 120)
                if dist < 10.0 then
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
