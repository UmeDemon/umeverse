--[[
    Umeverse Jobs - News Reporter
    Travel to news scenes, record stories, and return for payment
]]

local cfg = JobsConfig.Reporter
local currentScene = nil
local isRecording = false

RegisterNetEvent('umeverse_jobs:client:startJob_reporter', function()
    local veh = SpawnJobVehicle(cfg.vehicle.model, cfg.vehicle.spawn)
    if not veh then
        JobNotify('Failed to spawn news van.', 'error')
        CleanupJob()
        return
    end

    -- Assign a random story
    AssignNewStory()
    ReporterLoop()
end)

function AssignNewStory()
    local sceneIdx = math.random(#cfg.scenes)
    currentScene = cfg.scenes[sceneIdx]

    ClearJobBlips()
    AddJobBlip(currentScene.coords, 459, 4, currentScene.label, true)
    JobNotify('Story assigned: ~y~' .. currentScene.label .. '~w~. Head to the scene!', 'info')
end

function ReporterLoop()
    CreateThread(function()
        while GetActiveJob() == 'reporter' do
            local sleep = 500
            local ped = PlayerPedId()
            local myPos = GetEntityCoords(ped)

            if currentScene and not isRecording then
                local dist = #(myPos - currentScene.coords)

                if dist < 20.0 then
                    sleep = 0
                    DrawJobMarker(1, currentScene.coords, 200, 50, 200, 120)
                    DrawText3D(currentScene.coords + vector3(0, 0, 1.5), currentScene.label)

                    if dist < 3.0 and not IsPedInAnyVehicle(ped, false) then
                        ShowHelpText('Press ~INPUT_CONTEXT~ to record story')
                        if IsControlJustReleased(0, 38) then
                            RecordStory()
                        end
                    end
                end
            end

            Wait(sleep)
        end
    end)
end

function RecordStory()
    isRecording = true
    local ped = PlayerPedId()

    JobNotify('Recording: ~y~' .. currentScene.label .. '~w~...', 'info')

    -- Camera/recording animation
    PlayJobAnim('amb@world_human_paparazzi@male@idle_a', 'idle_c', cfg.recordDuration, 1)

    Wait(cfg.recordDuration)
    StopJobAnim()

    TriggerServerEvent('umeverse_jobs:server:reporterPay')
    OnTaskComplete(JobsConfig.Reporter.payPerStory[GetJobGrade() + 1] or JobsConfig.Reporter.payPerStory[1])
    JobNotify('Story recorded! ~g~' .. currentScene.label, 'success')

    isRecording = false
    currentScene = nil

    -- Offer choice: another story or end shift
    ClearJobBlips()
    AddJobBlip(vector3(cfg.clockIn.x, cfg.clockIn.y, cfg.clockIn.z), 459, 4, 'Return to Station', false)

    JobNotify('Return to station and press E for another story, or /endshift to finish.', 'info')
    WaitForStationReturn()
end

function WaitForStationReturn()
    CreateThread(function()
        while GetActiveJob() == 'reporter' do
            local dist = #(GetEntityCoords(PlayerPedId()) - vector3(cfg.clockIn.x, cfg.clockIn.y, cfg.clockIn.z))
            if dist < 15.0 then
                DrawJobMarker(1, vector3(cfg.clockIn.x, cfg.clockIn.y, cfg.clockIn.z), 50, 200, 50, 120)
                if dist < 4.0 then
                    ShowHelpText('Press ~INPUT_CONTEXT~ for new story, ~INPUT_DETONATE~ to end shift')
                    if IsControlJustReleased(0, 38) then
                        -- New story
                        AssignNewStory()
                        ReporterLoop()
                        return
                    elseif IsControlJustReleased(0, 47) then -- G key
                        TriggerEvent('umeverse_jobs:client:endShift')
                        return
                    end
                end
            end
            Wait(500)
        end
    end)
end
