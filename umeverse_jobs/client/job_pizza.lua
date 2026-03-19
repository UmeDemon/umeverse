--[[
    Umeverse Jobs - Pizza Delivery
    Deliver pizzas via scooter to random houses around LS
]]

local cfg = JobsConfig.Pizza
local deliveries = {}
local currentDelivery = 0

RegisterNetEvent('umeverse_jobs:client:startJob_pizza', function()
    local veh = SpawnJobVehicle(cfg.vehicle.model, cfg.vehicle.spawn)
    if not veh then
        JobNotify('Failed to spawn delivery scooter.', 'error')
        CleanupJob()
        return
    end

    -- Pick random delivery destinations
    deliveries = {}
    local available = {}
    for i = 1, #cfg.deliveryLocations do available[i] = i end

    for _ = 1, math.min(cfg.deliveriesPerRound, #cfg.deliveryLocations) do
        local idx = math.random(#available)
        deliveries[#deliveries + 1] = cfg.deliveryLocations[available[idx]]
        table.remove(available, idx)
    end

    currentDelivery = 1
    JobNotify('You have ~y~' .. #deliveries .. ' deliveries~w~ to make! Follow the GPS.', 'info')
    SetNextDeliveryBlip()
    PizzaLoop()
end)

function SetNextDeliveryBlip()
    ClearJobBlips()
    if currentDelivery <= #deliveries then
        local del = deliveries[currentDelivery]
        AddJobBlip(del.coords, 93, 1, del.name .. ' (' .. currentDelivery .. '/' .. #deliveries .. ')', true)
    end
end

function PizzaLoop()
    CreateThread(function()
        while GetActiveJob() == 'pizza' do
            local sleep = 500
            local ped = PlayerPedId()
            local myPos = GetEntityCoords(ped)

            if currentDelivery <= #deliveries then
                local del = deliveries[currentDelivery]
                local dist = #(myPos - del.coords)

                if dist < 20.0 then
                    sleep = 0
                    DrawJobMarker(1, del.coords, 200, 50, 50, 120)
                    DrawText3D(del.coords + vector3(0, 0, 1.5), del.name)

                    if dist < 3.0 then
                        ShowHelpText('Press ~INPUT_CONTEXT~ to deliver pizza')
                        if IsControlJustReleased(0, 38) then
                            DeliverPizza()
                        end
                    end
                end
            end

            Wait(sleep)
        end
    end)
end

function DeliverPizza()
    local ped = PlayerPedId()
    local veh = GetJobVehicle()

    -- Exit vehicle if in one
    if veh and IsPedInVehicle(ped, veh, false) then
        TaskLeaveVehicle(ped, veh, 0)
        Wait(2000)
    end

    -- Knock on door animation
    PlayJobAnim('timetable@floyd@clean_kitchen@base', 'base', 3000, 49)
    Wait(3000)
    StopJobAnim()

    -- Hand over pizza
    PlayJobAnim('mp_common', 'givetake1_a', 2000, 0)
    Wait(2000)
    StopJobAnim()

    TriggerServerEvent('umeverse_jobs:server:pizzaPay')
    OnTaskComplete(JobsConfig.Pizza.payPerDelivery[GetJobGrade() + 1] or JobsConfig.Pizza.payPerDelivery[1])
    JobNotify('Pizza delivered! (' .. currentDelivery .. '/' .. #deliveries .. ')', 'success')

    currentDelivery = currentDelivery + 1
    if currentDelivery > #deliveries then
        JobNotify('All deliveries complete! Return to shop or /endshift.', 'success')
        ClearJobBlips()
        AddJobBlip(vector3(cfg.clockIn.x, cfg.clockIn.y, cfg.clockIn.z), 93, 1, 'Return to Shop', true)
        WaitForPizzaReturn()
    else
        SetNextDeliveryBlip()
    end

    -- Get back on scooter
    if veh and DoesEntityExist(veh) then
        TaskEnterVehicle(ped, veh, 5000, -1, 2.0, 1, 0)
    end
end

function WaitForPizzaReturn()
    CreateThread(function()
        while GetActiveJob() == 'pizza' do
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
