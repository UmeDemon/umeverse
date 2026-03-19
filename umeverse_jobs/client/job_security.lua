--[[
    Umeverse Jobs - Security Guard
    Patrol between checkpoints, get paid per checkpoint visited
]]

local cfg = JobsConfig.Security
local checkpointsVisited = 0
local currentCheckpoint = 0
local visitedSet = {}

RegisterNetEvent('umeverse_jobs:client:startJob_security', function()
    checkpointsVisited = 0
    currentCheckpoint = 0
    visitedSet = {}

    -- Check night-only restriction
    if cfg.nightOnly then
        local hour = GetClockHours()
        if hour >= 6 and hour < 20 then
            JobNotify('Security shifts are only available at ~r~night~w~ (8PM - 6AM).', 'error')
            return
        end
    end

    JobNotify('Security shift started! Patrol the ~y~checkpoints~w~.', 'info')
    SetNextCheckpoint()
    SecurityLoop()
end)

function SetNextCheckpoint()
    ClearJobBlips()
    -- Find the next unvisited checkpoint
    for i = 1, #cfg.checkpoints do
        if not visitedSet[i] then
            currentCheckpoint = i
            local cp = cfg.checkpoints[i]
            AddJobBlip(cp.pos, 487, 1, cp.label .. ' (' .. (checkpointsVisited + 1) .. '/' .. cfg.checkpointsPerShift .. ')', true)
            return
        end
    end
    -- All visited - reset available ones but keep count
    visitedSet = {}
    currentCheckpoint = 1
    local cp = cfg.checkpoints[1]
    AddJobBlip(cp.pos, 487, 1, cp.label .. ' (' .. (checkpointsVisited + 1) .. '/' .. cfg.checkpointsPerShift .. ')', true)
end

function SecurityLoop()
    CreateThread(function()
        while GetActiveJob() == 'security' do
            local sleep = 500
            local ped = PlayerPedId()
            local myPos = GetEntityCoords(ped)

            -- Night-only enforcement
            if cfg.nightOnly then
                local hour = GetClockHours()
                if hour >= 6 and hour < 20 then
                    JobNotify('Your shift has ended - it is now daytime.', 'info')
                    TriggerEvent('umeverse_jobs:client:endShift')
                    return
                end
            end

            if currentCheckpoint > 0 and currentCheckpoint <= #cfg.checkpoints then
                local cp = cfg.checkpoints[currentCheckpoint]
                local dist = #(myPos - cp.pos)

                if dist < 20.0 then
                    sleep = 0
                    DrawJobMarker(1, cp.pos, 100, 100, 255, 120)
                    DrawText3D(cp.pos + vector3(0, 0, 1.5), cp.label)

                    if dist < 3.0 and not IsPedInAnyVehicle(ped, false) then
                        ShowHelpText('Press ~INPUT_CONTEXT~ to check in at patrol point')
                        if IsControlJustReleased(0, 38) then
                            CheckInAtPoint(cp)
                        end
                    end
                end
            end

            Wait(sleep)
        end
    end)
end

function CheckInAtPoint(cp)
    local ped = PlayerPedId()

    -- Look around animation
    PlayJobAnim('amb@world_human_clipboard@male@base', 'base', cfg.checkDuration, 49)
    Wait(cfg.checkDuration)
    StopJobAnim()

    TriggerServerEvent('umeverse_jobs:server:securityCheckpoint')
    OnTaskComplete(JobsConfig.Security.payPerCheckpoint[GetJobGrade() + 1] or JobsConfig.Security.payPerCheckpoint[1])
    checkpointsVisited = checkpointsVisited + 1
    visitedSet[currentCheckpoint] = true
    JobNotify('Checkpoint ~g~secured~w~! (' .. checkpointsVisited .. '/' .. cfg.checkpointsPerShift .. ')', 'success')

    if checkpointsVisited >= cfg.checkpointsPerShift then
        JobNotify('Patrol complete! Ending shift...', 'success')
        ClearJobBlips()
        Wait(1500)
        TriggerEvent('umeverse_jobs:client:endShift')
    else
        SetNextCheckpoint()
    end
end
