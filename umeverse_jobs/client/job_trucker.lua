--[[
    Umeverse Jobs - Trucker
    Pick up a trailer at the port and deliver it across the map
]]

local cfg = JobsConfig.Trucker
local trailer = nil
local deliveryTarget = nil

RegisterNetEvent('umeverse_jobs:client:startJob_trucker', function()
    local veh = SpawnJobVehicle(cfg.vehicle.model, cfg.vehicle.spawn)
    if not veh then
        JobNotify('Failed to spawn truck.', 'error')
        CleanupJob()
        return
    end

    -- Spawn trailer at pickup point
    local pickupIdx = math.random(#cfg.pickups)
    local pickupPos = cfg.pickups[pickupIdx]

    local trailerHash = GetHashKey(cfg.trailer)
    RequestModel(trailerHash)
    local timeout = 5000
    while not HasModelLoaded(trailerHash) and timeout > 0 do
        Wait(10)
        timeout = timeout - 10
    end

    if HasModelLoaded(trailerHash) then
        trailer = CreateVehicle(trailerHash, pickupPos.x, pickupPos.y + 8.0, pickupPos.z, pickupPos.w, true, false)
        SetModelAsNoLongerNeeded(trailerHash)
        SetEntityAsMissionEntity(trailer, true, true)
        SetVehicleOnGroundProperly(trailer)
    end

    -- Pick a random delivery destination
    local deliveryIdx = math.random(#cfg.deliveries)
    deliveryTarget = cfg.deliveries[deliveryIdx]

    ClearJobBlips()
    if trailer then
        AddJobBlip(vector3(pickupPos.x, pickupPos.y + 8.0, pickupPos.z), 479, 47, 'Attach Trailer', true)
    end

    JobNotify('Pick up the trailer and deliver to ~y~' .. deliveryTarget.name, 'info')
    TruckerLoop()
end)

function TruckerLoop()
    local attachedTrailer = false

    CreateThread(function()
        while GetActiveJob() == 'trucker' do
            local sleep = 500
            local ped = PlayerPedId()
            local myPos = GetEntityCoords(ped)
            local veh = GetJobVehicle()

            if not attachedTrailer and trailer and DoesEntityExist(trailer) then
                -- Phase 1: Go attach the trailer
                local trailerPos = GetEntityCoords(trailer)
                local dist = #(myPos - trailerPos)
                if dist < 20.0 then
                    sleep = 0
                    DrawJobMarker(1, trailerPos, 200, 150, 0, 120)
                    if dist < 6.0 and veh and IsPedInVehicle(ped, veh, false) then
                        ShowHelpText('Press ~INPUT_CONTEXT~ to attach trailer')
                        if IsControlJustReleased(0, 38) then
                            AttachVehicleToTrailer(veh, trailer, 2.0)
                            Wait(1000)
                            if IsVehicleAttachedToTrailer(veh) then
                                attachedTrailer = true
                                ClearJobBlips()
                                AddJobBlip(deliveryTarget.coords, 1, 47, deliveryTarget.name, true)
                                JobNotify('Trailer attached! Deliver to ~y~' .. deliveryTarget.name, 'success')
                            else
                                JobNotify('Failed to attach trailer. Try getting closer.', 'error')
                            end
                        end
                    end
                end
            elseif attachedTrailer then
                -- Phase 2: Deliver
                local dest = deliveryTarget.coords
                local dist = #(myPos - vector3(dest.x, dest.y, dest.z))
                if dist < 30.0 then
                    sleep = 0
                    DrawJobMarker(1, vector3(dest.x, dest.y, dest.z), 0, 200, 0, 120)
                    if dist < 10.0 and veh and IsPedInVehicle(ped, veh, false) then
                        ShowHelpText('Press ~INPUT_CONTEXT~ to deliver cargo')
                        if IsControlJustReleased(0, 38) then
                            -- Detach and cleanup trailer
                            DetachVehicleFromTrailer(veh)
                            Wait(500)
                            if trailer and DoesEntityExist(trailer) then
                                DeleteEntity(trailer)
                                trailer = nil
                            end

                            TriggerServerEvent('umeverse_jobs:server:truckerPay')
                            OnTaskComplete(JobsConfig.Trucker.payPerDelivery[GetJobGrade() + 1] or JobsConfig.Trucker.payPerDelivery[1])
                            JobNotify('Delivery complete! Return to depot or /endshift.', 'success')
                            ClearJobBlips()
                            AddJobBlip(vector3(cfg.clockIn.x, cfg.clockIn.y, cfg.clockIn.z), 477, 47, 'Return to Depot', true)
                            WaitForTruckerReturn()
                            return
                        end
                    end
                end
            end

            Wait(sleep)
        end

        -- Cleanup trailer if job ended early
        if trailer and DoesEntityExist(trailer) then
            DeleteEntity(trailer)
            trailer = nil
        end
    end)
end

function WaitForTruckerReturn()
    CreateThread(function()
        while GetActiveJob() == 'trucker' do
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
