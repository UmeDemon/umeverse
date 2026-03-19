--[[
    Umeverse Jobs - Tow Truck Driver
    Pick up broken-down vehicles and tow them to the impound
]]

local cfg = JobsConfig.Tow
local breakdownVeh = nil
local isTowing = false

RegisterNetEvent('umeverse_jobs:client:startJob_tow', function()
    local veh = SpawnJobVehicle(cfg.vehicle.model, cfg.vehicle.spawn)
    if not veh then
        JobNotify('Failed to spawn tow truck.', 'error')
        CleanupJob()
        return
    end

    -- Spawn a random breakdown vehicle at a random location
    local locIdx = math.random(#cfg.breakdownLocations)
    local loc = cfg.breakdownLocations[locIdx]
    local modelName = cfg.breakdownVehicles[math.random(#cfg.breakdownVehicles)]

    local hash = GetHashKey(modelName)
    RequestModel(hash)
    local timeout = 5000
    while not HasModelLoaded(hash) and timeout > 0 do
        Wait(10)
        timeout = timeout - 10
    end

    if HasModelLoaded(hash) then
        breakdownVeh = CreateVehicle(hash, loc.x, loc.y, loc.z, loc.w, true, false)
        SetModelAsNoLongerNeeded(hash)
        SetEntityAsMissionEntity(breakdownVeh, true, true)
        SetVehicleOnGroundProperly(breakdownVeh)
        -- Make it look broken down
        SetVehicleEngineHealth(breakdownVeh, 0.0)
        SetVehicleUndriveable(breakdownVeh, true)
        SetVehicleDoorBroken(breakdownVeh, 0, true)

        ClearJobBlips()
        AddJobBlip(vector3(loc.x, loc.y, loc.z), 68, 1, 'Broken Vehicle', true)
        JobNotify('A broken vehicle needs towing! Follow the GPS.', 'info')
    else
        JobNotify('Failed to spawn breakdown vehicle.', 'error')
        CleanupJob()
        return
    end

    TowLoop()
end)

function TowLoop()
    CreateThread(function()
        while GetActiveJob() == 'tow' do
            local sleep = 500
            local ped = PlayerPedId()
            local myPos = GetEntityCoords(ped)
            local towTruck = GetJobVehicle()

            if not isTowing and breakdownVeh and DoesEntityExist(breakdownVeh) then
                -- Phase 1: Go to the breakdown vehicle
                local bvPos = GetEntityCoords(breakdownVeh)
                local dist = #(myPos - bvPos)

                if dist < 30.0 then
                    sleep = 0
                    DrawJobMarker(1, bvPos, 200, 50, 50, 120)

                    if dist < 8.0 and towTruck and IsPedInVehicle(ped, towTruck, false) then
                        ShowHelpText('Press ~INPUT_CONTEXT~ to hook vehicle')
                        if IsControlJustReleased(0, 38) then
                            HookVehicle()
                        end
                    end
                end
            elseif isTowing then
                -- Phase 2: Deliver to impound
                local impound = cfg.impound
                local dist = #(myPos - vector3(impound.x, impound.y, impound.z))

                if dist < 30.0 then
                    sleep = 0
                    DrawJobMarker(1, vector3(impound.x, impound.y, impound.z), 0, 200, 0, 120)

                    if dist < 10.0 and towTruck and IsPedInVehicle(ped, towTruck, false) then
                        ShowHelpText('Press ~INPUT_CONTEXT~ to drop off vehicle')
                        if IsControlJustReleased(0, 38) then
                            DropOffVehicle()
                            return
                        end
                    end
                end
            end

            Wait(sleep)
        end

        -- Cleanup if job ended early
        if breakdownVeh and DoesEntityExist(breakdownVeh) then
            DeleteEntity(breakdownVeh)
            breakdownVeh = nil
        end
    end)
end

function HookVehicle()
    local towTruck = GetJobVehicle()
    if not towTruck or not breakdownVeh then return end

    JobNotify('Hooking vehicle...', 'info')

    -- Get behind the tow truck to simulate hooking
    TaskLeaveVehicle(PlayerPedId(), towTruck, 0)
    Wait(2500)

    PlayJobAnim('mini@repair', 'fixing_a_ped', 4000, 1)
    Wait(4000)
    StopJobAnim()

    -- Attach breakdown vehicle to tow truck
    AttachEntityToEntity(breakdownVeh, towTruck, 20, 0.0, -1.5, 1.0, 0.0, 0.0, 0.0, true, true, false, false, 2, true)

    isTowing = true
    ClearJobBlips()
    AddJobBlip(vector3(cfg.impound.x, cfg.impound.y, cfg.impound.z), 68, 46, 'Tow Yard (Drop Off)', true)

    -- Get back in truck
    TaskEnterVehicle(PlayerPedId(), towTruck, 5000, -1, 2.0, 1, 0)
    Wait(4000)

    JobNotify('Vehicle hooked! Deliver to the ~y~Tow Yard~w~.', 'success')
end

function DropOffVehicle()
    -- Detach and delete the breakdown vehicle
    if breakdownVeh and DoesEntityExist(breakdownVeh) then
        DetachEntity(breakdownVeh, true, true)
        Wait(500)
        DeleteEntity(breakdownVeh)
        breakdownVeh = nil
    end

    isTowing = false
    TriggerServerEvent('umeverse_jobs:server:towPay')
    OnTaskComplete(JobsConfig.Tow.payPerTow[GetJobGrade() + 1] or JobsConfig.Tow.payPerTow[1])
    JobNotify('Vehicle delivered! Shift complete. Use /endshift or return to clock-in.', 'success')
    ClearJobBlips()
    AddJobBlip(vector3(cfg.clockIn.x, cfg.clockIn.y, cfg.clockIn.z), 68, 46, 'Return to Tow Yard', true)

    -- Wait for return or endshift
    CreateThread(function()
        while GetActiveJob() == 'tow' do
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
