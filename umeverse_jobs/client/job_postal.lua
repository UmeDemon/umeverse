--[[
    Umeverse Jobs - Postal Courier
    Deliver packages in a Boxville to various addresses
]]

local cfg = JobsConfig.Postal
local deliveries = {}
local currentDelivery = 0

RegisterNetEvent('umeverse_jobs:client:startJob_postal', function()
    local veh = SpawnJobVehicle(cfg.vehicle.model, cfg.vehicle.spawn)
    if not veh then
        JobNotify('Failed to spawn delivery van.', 'error')
        CleanupJob()
        return
    end

    -- Pick random delivery destinations
    deliveries = {}
    local available = {}
    for i = 1, #cfg.deliveryLocations do available[i] = i end
    for _ = 1, math.min(cfg.packagesPerRound, #cfg.deliveryLocations) do
        local idx = math.random(#available)
        deliveries[#deliveries + 1] = cfg.deliveryLocations[available[idx]]
        table.remove(available, idx)
    end

    currentDelivery = 1
    JobNotify('You have ~y~' .. #deliveries .. ' packages~w~ to deliver! Follow the GPS.', 'info')
    SetNextPostalBlip()
    PostalLoop()
end)

function SetNextPostalBlip()
    ClearJobBlips()
    if currentDelivery <= #deliveries then
        local del = deliveries[currentDelivery]
        AddJobBlip(del.coords, 478, 47, del.name .. ' (' .. currentDelivery .. '/' .. #deliveries .. ')', true)
    end
end

function PostalLoop()
    CreateThread(function()
        while GetActiveJob() == 'postal' do
            local sleep = 500
            local ped = PlayerPedId()
            local myPos = GetEntityCoords(ped)

            if currentDelivery <= #deliveries then
                local del = deliveries[currentDelivery]
                local dist = #(myPos - del.coords)

                if dist < 20.0 then
                    sleep = 0
                    DrawJobMarker(1, del.coords, 150, 100, 0, 120)
                    DrawText3D(del.coords + vector3(0, 0, 1.5), del.name)

                    if dist < 3.0 then
                        ShowHelpText('Press ~INPUT_CONTEXT~ to deliver package')
                        if IsControlJustReleased(0, 38) then
                            DeliverPackage()
                        end
                    end
                end
            end

            Wait(sleep)
        end
    end)
end

function DeliverPackage()
    local ped = PlayerPedId()
    local veh = GetJobVehicle()

    if veh and IsPedInVehicle(ped, veh, false) then
        TaskLeaveVehicle(ped, veh, 0)
        Wait(2000)
    end

    -- Carry package animation
    PlayJobAnim('anim@heists@box_carry@', 'idle', 2000, 49)
    Wait(2500)
    StopJobAnim()

    -- Place down
    PlayJobAnim('anim@mp_snowball', 'pickup_snowball', 1500, 0)
    Wait(1500)
    StopJobAnim()

    TriggerServerEvent('umeverse_jobs:server:postalPay')
    OnTaskComplete(JobsConfig.Postal.payPerPackage[GetJobGrade() + 1] or JobsConfig.Postal.payPerPackage[1])
    JobNotify('Package delivered! (' .. currentDelivery .. '/' .. #deliveries .. ')', 'success')

    currentDelivery = currentDelivery + 1
    if currentDelivery > #deliveries then
        JobNotify('All packages delivered! Return to depot or /endshift.', 'success')
        ClearJobBlips()
        AddJobBlip(vector3(cfg.clockIn.x, cfg.clockIn.y, cfg.clockIn.z), 478, 47, 'Return to Depot', true)
        WaitForPostalReturn()
    else
        SetNextPostalBlip()
    end

    if veh and DoesEntityExist(veh) then
        TaskEnterVehicle(ped, veh, 5000, -1, 2.0, 1, 0)
    end
end

function WaitForPostalReturn()
    CreateThread(function()
        while GetActiveJob() == 'postal' do
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
