--[[
    Umeverse Jobs - Dock Worker
    Drive forklift moving cargo crates between pickup and dropoff points
]]

local cfg = JobsConfig.DockWorker
local cratesMoved = 0
local hasCarriedCrate = false

RegisterNetEvent('umeverse_jobs:client:startJob_dockworker', function()
    local veh = SpawnJobVehicle(cfg.vehicle.model, cfg.vehicle.spawn)
    if not veh then
        JobNotify('Failed to spawn forklift.', 'error')
        CleanupJob()
        return
    end

    cratesMoved = 0
    hasCarriedCrate = false

    -- Add blips
    for i, pt in ipairs(cfg.pickupPoints) do
        AddJobBlip(pt, 1, 44, 'Cargo Pickup #' .. i, false)
    end
    for i, pt in ipairs(cfg.dropoffPoints) do
        AddJobBlip(pt, 1, 25, 'Cargo Dropoff #' .. i, false)
    end

    JobNotify('Move ~y~' .. cfg.cratesPerShift .. ' crates~w~ from pickup to dropoff! Drive the forklift.', 'info')
    DockWorkerLoop()
end)

function DockWorkerLoop()
    CreateThread(function()
        while GetActiveJob() == 'dockworker' do
            local sleep = 500
            local ped = PlayerPedId()
            local myPos = GetEntityCoords(ped)

            if not hasCarriedCrate then
                -- Phase: pickup a crate
                for _, pt in ipairs(cfg.pickupPoints) do
                    local dist = #(myPos - pt)
                    if dist < 15.0 then
                        sleep = 0
                        DrawJobMarker(1, pt, 200, 150, 0, 120)
                        DrawText3D(pt + vector3(0, 0, 1.0), 'Cargo Pickup')

                        if dist < 4.0 then
                            ShowHelpText('Press ~INPUT_CONTEXT~ to load crate')
                            if IsControlJustReleased(0, 38) then
                                LoadCrate()
                                break
                            end
                        end
                    end
                end
            else
                -- Phase: dropoff the crate
                for _, pt in ipairs(cfg.dropoffPoints) do
                    local dist = #(myPos - pt)
                    if dist < 15.0 then
                        sleep = 0
                        DrawJobMarker(1, pt, 0, 200, 0, 120)
                        DrawText3D(pt + vector3(0, 0, 1.0), 'Cargo Dropoff')

                        if dist < 4.0 then
                            ShowHelpText('Press ~INPUT_CONTEXT~ to unload crate')
                            if IsControlJustReleased(0, 38) then
                                UnloadCrate()
                                break
                            end
                        end
                    end
                end
            end

            Wait(sleep)
        end
    end)
end

function LoadCrate()
    JobNotify('Loading crate...', 'info')
    PlayJobAnim('anim@heists@box_carry@', 'idle', 3000, 49)
    Wait(3000)
    StopJobAnim()

    hasCarriedCrate = true
    JobNotify('Crate loaded! Drive to a ~g~dropoff point~w~.', 'success')
end

function UnloadCrate()
    JobNotify('Unloading crate...', 'info')
    PlayJobAnim('anim@mp_snowball', 'pickup_snowball', 2000, 0)
    Wait(2000)
    StopJobAnim()

    hasCarriedCrate = false
    cratesMoved = cratesMoved + 1

    TriggerServerEvent('umeverse_jobs:server:dockPay')
    OnTaskComplete(JobsConfig.DockWorker.payPerCrate[GetJobGrade() + 1] or JobsConfig.DockWorker.payPerCrate[1])
    JobNotify('Crate delivered! (' .. cratesMoved .. '/' .. cfg.cratesPerShift .. ')', 'success')

    if cratesMoved >= cfg.cratesPerShift then
        JobNotify('Shift quota met! Return to clock-in or /endshift.', 'success')
        ClearJobBlips()
        AddJobBlip(vector3(cfg.clockIn.x, cfg.clockIn.y, cfg.clockIn.z), 427, 44, 'Return to Docks', true)
        WaitForDockReturn()
    end
end

function WaitForDockReturn()
    CreateThread(function()
        while GetActiveJob() == 'dockworker' do
            local dist = #(GetEntityCoords(PlayerPedId()) - vector3(cfg.clockIn.x, cfg.clockIn.y, cfg.clockIn.z))
            if dist < 15.0 then
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
