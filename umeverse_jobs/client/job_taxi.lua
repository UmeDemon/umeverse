--[[
    Umeverse Jobs - Taxi Driver
    Pick up NPC passengers and drive them to destinations
]]

local cfg = JobsConfig.Taxi
local currentFares = {}
local currentFareIdx = 0
local farePhase = 'pickup' -- 'pickup' or 'dropoff'
local npcPed = nil

RegisterNetEvent('umeverse_jobs:client:startJob_taxi', function()
    local veh = SpawnJobVehicle(cfg.vehicle.model, cfg.vehicle.spawn)
    if not veh then
        JobNotify('Failed to spawn taxi.', 'error')
        CleanupJob()
        return
    end

    -- Pick random fares
    currentFares = {}
    local available = {}
    for i = 1, #cfg.fares do available[i] = i end
    for _ = 1, math.min(cfg.ridesPerShift, #cfg.fares) do
        local idx = math.random(#available)
        currentFares[#currentFares + 1] = cfg.fares[available[idx]]
        table.remove(available, idx)
    end

    currentFareIdx = 1
    farePhase = 'pickup'
    JobNotify('You have ~y~' .. #currentFares .. ' fares~w~ to complete! Pick up your first passenger.', 'info')
    SetNextTaxiBlip()
    TaxiLoop()
end)

function SetNextTaxiBlip()
    ClearJobBlips()
    if currentFareIdx <= #currentFares then
        local fare = currentFares[currentFareIdx]
        if farePhase == 'pickup' then
            AddJobBlip(fare.pickup, 198, 5, 'Pickup: ' .. fare.name, true)
        else
            AddJobBlip(fare.dropoff, 1, 5, 'Dropoff: ' .. fare.name, true)
        end
    end
end

function TaxiLoop()
    CreateThread(function()
        while GetActiveJob() == 'taxi' do
            local sleep = 500
            local ped = PlayerPedId()
            local myPos = GetEntityCoords(ped)
            local veh = GetJobVehicle()

            if currentFareIdx <= #currentFares then
                local fare = currentFares[currentFareIdx]

                if farePhase == 'pickup' then
                    local dist = #(myPos - fare.pickup)
                    if dist < 30.0 then
                        sleep = 0
                        DrawJobMarker(1, fare.pickup, 200, 200, 0, 120)
                        DrawText3D(fare.pickup + vector3(0, 0, 1.5), 'Passenger Pickup')

                        if dist < 5.0 and veh and IsPedInVehicle(ped, veh, false) then
                            ShowHelpText('Press ~INPUT_CONTEXT~ to pick up passenger')
                            if IsControlJustReleased(0, 38) then
                                PickupPassenger(fare)
                            end
                        end
                    end
                else
                    local dist = #(myPos - fare.dropoff)
                    if dist < 30.0 then
                        sleep = 0
                        DrawJobMarker(1, fare.dropoff, 0, 200, 0, 120)
                        DrawText3D(fare.dropoff + vector3(0, 0, 1.5), 'Drop Off')

                        if dist < 5.0 and veh and IsPedInVehicle(ped, veh, false) then
                            ShowHelpText('Press ~INPUT_CONTEXT~ to drop off passenger')
                            if IsControlJustReleased(0, 38) then
                                DropoffPassenger()
                            end
                        end
                    end
                end
            end

            Wait(sleep)
        end
        -- Cleanup NPC if job ended
        CleanupTaxiNPC()
    end)
end

function PickupPassenger(fare)
    local veh = GetJobVehicle()
    if not veh then return end

    -- Spawn NPC passenger
    local models = { 'a_m_y_business_01', 'a_f_y_tourist_01', 'a_m_m_farmer_01', 'a_f_y_hippie_01' }
    local modelName = models[math.random(#models)]
    local hash = GetHashKey(modelName)
    RequestModel(hash)
    local timeout = 5000
    while not HasModelLoaded(hash) and timeout > 0 do
        Wait(10)
        timeout = timeout - 10
    end

    if HasModelLoaded(hash) then
        npcPed = CreatePed(4, hash, fare.pickup.x, fare.pickup.y, fare.pickup.z, 0.0, true, false)
        SetModelAsNoLongerNeeded(hash)
        SetEntityAsMissionEntity(npcPed, true, true)
        SetBlockingOfNonTemporaryEvents(npcPed, true)
        TaskEnterVehicle(npcPed, veh, 10000, 1, 2.0, 1, 0) -- Passenger front seat
        Wait(5000)
    end

    farePhase = 'dropoff'
    SetNextTaxiBlip()
    JobNotify('Passenger aboard! Drive to ~y~' .. fare.name, 'info')
end

function DropoffPassenger()
    CleanupTaxiNPC()

    TriggerServerEvent('umeverse_jobs:server:taxiPay')
    OnTaskComplete(JobsConfig.Taxi.payPerFare[GetJobGrade() + 1] or JobsConfig.Taxi.payPerFare[1])
    JobNotify('Fare complete! (' .. currentFareIdx .. '/' .. #currentFares .. ')', 'success')

    currentFareIdx = currentFareIdx + 1
    if currentFareIdx > #currentFares then
        JobNotify('All fares completed! Return to depot or /endshift.', 'success')
        ClearJobBlips()
        AddJobBlip(vector3(cfg.clockIn.x, cfg.clockIn.y, cfg.clockIn.z), 198, 5, 'Return to Depot', true)
        WaitForTaxiReturn()
    else
        farePhase = 'pickup'
        SetNextTaxiBlip()
        JobNotify('Next pickup ready!', 'info')
    end
end

function CleanupTaxiNPC()
    if npcPed and DoesEntityExist(npcPed) then
        DeleteEntity(npcPed)
        npcPed = nil
    end
end

function WaitForTaxiReturn()
    CreateThread(function()
        while GetActiveJob() == 'taxi' do
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
