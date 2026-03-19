--[[
    Umeverse Jobs - Lumberjack
    Chop trees for logs, process into planks, sell at lumber yard
]]

local cfg = JobsConfig.Lumberjack
local isChopping = false
local isProcessing = false

RegisterNetEvent('umeverse_jobs:client:startJob_lumberjack', function()
    JobNotify('Lumberjack shift started! Head to the ~y~trees~w~ to chop wood.', 'info')

    for i, tree in ipairs(cfg.trees) do
        AddJobBlip(tree, 77, 21, 'Tree #' .. i, false)
    end
    AddJobBlip(vector3(cfg.processPoint.x, cfg.processPoint.y, cfg.processPoint.z), 365, 21, 'Process Logs', false)
    AddJobBlip(vector3(cfg.sellPoint.x, cfg.sellPoint.y, cfg.sellPoint.z), 52, 2, 'Sell Wood', false)

    LumberjackLoop()
end)

function LumberjackLoop()
    CreateThread(function()
        while GetActiveJob() == 'lumberjack' do
            local sleep = 500
            local ped = PlayerPedId()
            local myPos = GetEntityCoords(ped)

            -- Tree chopping spots
            if not isChopping and not isProcessing then
                for _, tree in ipairs(cfg.trees) do
                    local dist = #(myPos - tree)
                    if dist < JobsConfig.MarkerDrawDistance then
                        sleep = 0
                        DrawJobMarker(1, tree, 139, 90, 43, 120)

                        if dist < JobsConfig.InteractDistance and not IsPedInAnyVehicle(ped, false) then
                            ShowHelpText('Press ~INPUT_CONTEXT~ to chop tree')
                            if IsControlJustReleased(0, 38) then
                                ChopTree()
                                break
                            end
                        end
                    end
                end
            end

            -- Process point
            if not isChopping and not isProcessing then
                local processDist = #(myPos - vector3(cfg.processPoint.x, cfg.processPoint.y, cfg.processPoint.z))
                if processDist < JobsConfig.MarkerDrawDistance then
                    sleep = 0
                    DrawJobMarker(1, vector3(cfg.processPoint.x, cfg.processPoint.y, cfg.processPoint.z), 200, 200, 0, 120)
                    DrawText3D(vector3(cfg.processPoint.x, cfg.processPoint.y, cfg.processPoint.z + 1.0), 'Process Logs')

                    if processDist < JobsConfig.InteractDistance and not IsPedInAnyVehicle(ped, false) then
                        ShowHelpText('Press ~INPUT_CONTEXT~ to process logs into planks')
                        if IsControlJustReleased(0, 38) then
                            ProcessLogs()
                        end
                    end
                end
            end

            -- Sell point
            local sellDist = #(myPos - vector3(cfg.sellPoint.x, cfg.sellPoint.y, cfg.sellPoint.z))
            if sellDist < JobsConfig.MarkerDrawDistance then
                sleep = 0
                DrawJobMarker(1, vector3(cfg.sellPoint.x, cfg.sellPoint.y, cfg.sellPoint.z), 0, 200, 0, 120)
                DrawText3D(vector3(cfg.sellPoint.x, cfg.sellPoint.y, cfg.sellPoint.z + 1.0), 'Sell Wood')

                if sellDist < JobsConfig.InteractDistance and not IsPedInAnyVehicle(ped, false) then
                    ShowHelpText('Press ~INPUT_CONTEXT~ to sell wood')
                    if IsControlJustReleased(0, 38) then
                        TriggerServerEvent('umeverse_jobs:server:sellWood')
                    end
                end
            end

            Wait(sleep)
        end
    end)
end

function ChopTree()
    isChopping = true
    JobNotify('Chopping tree...', 'info')

    PlayJobAnim('melee@hatchet@streamed_core', 'plyr_base', cfg.animDuration, 1)

    Wait(cfg.animDuration)
    StopJobAnim()

    TriggerServerEvent('umeverse_jobs:server:chopTree')
    OnTaskComplete(0) -- Item collection, no direct pay
    JobNotify('Log collected!', 'success')
    isChopping = false
end

function ProcessLogs()
    isProcessing = true
    JobNotify('Processing logs into planks...', 'info')

    PlayJobAnim('mini@repair', 'fixing_a_ped', cfg.processDuration, 1)

    Wait(cfg.processDuration)
    StopJobAnim()

    TriggerServerEvent('umeverse_jobs:server:processLogs')
    isProcessing = false
end
