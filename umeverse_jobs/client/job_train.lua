--[[
    Umeverse Jobs - Train Engineer
    Travel between stations along train lines, "operating" the train
]]

local cfg = JobsConfig.Train
local currentRoute = nil
local currentStation = 0

RegisterNetEvent('umeverse_jobs:client:startJob_train', function()
    -- Pick a random route
    local routeIdx = math.random(#cfg.routes)
    currentRoute = cfg.routes[routeIdx]
    currentStation = 1

    JobNotify('Assigned route: ~y~' .. currentRoute.label .. '~w~! Head to the first station.', 'info')
    SetNextTrainStation()
    TrainLoop()
end)

function SetNextTrainStation()
    ClearJobBlips()
    if currentStation <= #currentRoute.stations then
        local station = currentRoute.stations[currentStation]
        AddJobBlip(station.coords, 513, 15, station.name .. ' (' .. currentStation .. '/' .. #currentRoute.stations .. ')', true)
    end
end

function TrainLoop()
    CreateThread(function()
        while GetActiveJob() == 'train' do
            local sleep = 500
            local ped = PlayerPedId()
            local myPos = GetEntityCoords(ped)

            if currentStation <= #currentRoute.stations then
                local station = currentRoute.stations[currentStation]
                local dist = #(myPos - station.coords)

                if dist < 20.0 then
                    sleep = 0
                    DrawJobMarker(1, station.coords, 100, 100, 200, 120)
                    DrawText3D(station.coords + vector3(0, 0, 1.5), station.name)

                    if dist < 4.0 and not IsPedInAnyVehicle(ped, false) then
                        ShowHelpText('Press ~INPUT_CONTEXT~ to operate station stop')
                        if IsControlJustReleased(0, 38) then
                            StationStop(station)
                        end
                    end
                end
            end

            Wait(sleep)
        end
    end)
end

function StationStop(station)
    local ped = PlayerPedId()

    JobNotify('Arrived at ~y~' .. station.name .. '~w~. Operating station...', 'info')

    -- Station operation animation (clipboard/check)
    PlayJobAnim('missheistdockssetup1clipboard@base', 'base', cfg.waitDuration, 49)
    Wait(cfg.waitDuration)
    StopJobAnim()

    TriggerServerEvent('umeverse_jobs:server:trainPay')
    OnTaskComplete(JobsConfig.Train.payPerStation[GetJobGrade() + 1] or JobsConfig.Train.payPerStation[1])
    JobNotify('Station complete! (' .. currentStation .. '/' .. #currentRoute.stations .. ')', 'success')

    currentStation = currentStation + 1
    if currentStation > #currentRoute.stations then
        JobNotify('Route ~g~' .. currentRoute.label .. '~w~ complete! Use /endshift to finish.', 'success')
        ClearJobBlips()
        AddJobBlip(vector3(cfg.clockIn.x, cfg.clockIn.y, cfg.clockIn.z), 513, 15, 'Return to Station', true)
        WaitForTrainReturn()
    else
        SetNextTrainStation()
        JobNotify('Next stop: ~y~' .. currentRoute.stations[currentStation].name, 'info')
    end
end

function WaitForTrainReturn()
    CreateThread(function()
        while GetActiveJob() == 'train' do
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
