--[[
    Umeverse Jobs - Vineyard Worker
    Pick grapes at vineyard, process them into wine, then sell
]]

local cfg = JobsConfig.Vineyard
local grapesPickedCount = 0
local maxPicks = 0

RegisterNetEvent('umeverse_jobs:client:startJob_vineyard', function()
    grapesPickedCount = 0
    local grade = GetJobGrade()
    maxPicks = cfg.picksPerShift[grade + 1] or cfg.picksPerShift[1]

    JobNotify('Vineyard shift started! Head to the ~y~vineyard~w~ to pick grapes.', 'info')
    SetVineyardBlips()
    VineyardLoop()
end)

function SetVineyardBlips()
    ClearJobBlips()
    AddJobBlip(cfg.vineyardCenter, 473, 27, 'Vineyard', false)
    AddJobBlip(cfg.processLocation.pos, 402, 5, 'Wine Press', false)
    AddJobBlip(cfg.sellLocation.pos, 52, 2, 'Sell Wine', false)
end

function VineyardLoop()
    CreateThread(function()
        while GetActiveJob() == 'vineyard' do
            local sleep = 500
            local ped = PlayerPedId()
            local myPos = GetEntityCoords(ped)

            -- Grape picking points
            for _, point in ipairs(cfg.grapePoints) do
                local dist = #(myPos - point)
                if dist < 10.0 then
                    sleep = 0
                    DrawJobMarker(25, point - vector3(0, 0, 0.5), 100, 0, 150, 120)
                    if dist < 2.0 and not IsPedInAnyVehicle(ped, false) then
                        if grapesPickedCount < maxPicks then
                            ShowHelpText('Press ~INPUT_CONTEXT~ to pick grapes')
                            if IsControlJustReleased(0, 38) then
                                PickGrapes(point)
                            end
                        else
                            ShowHelpText('Done picking! Process or sell your grapes.')
                        end
                    end
                end
            end

            -- Process location (grapes -> wine)
            local procDist = #(myPos - cfg.processLocation.pos)
            if procDist < 15.0 then
                sleep = 0
                DrawJobMarker(1, cfg.processLocation.pos, 150, 0, 200, 120)
                DrawText3D(cfg.processLocation.pos + vector3(0, 0, 1.5), 'Wine Press')
                if procDist < 2.5 and not IsPedInAnyVehicle(ped, false) then
                    ShowHelpText('Press ~INPUT_CONTEXT~ to process grapes into wine (' .. cfg.grapesPerBottle .. ' grapes per bottle)')
                    if IsControlJustReleased(0, 38) then
                        TriggerServerEvent('umeverse_jobs:server:processGrapes')
                    end
                end
            end

            -- Sell location
            local sellDist = #(myPos - cfg.sellLocation.pos)
            if sellDist < 15.0 then
                sleep = 0
                DrawJobMarker(1, cfg.sellLocation.pos, 50, 200, 50, 120)
                DrawText3D(cfg.sellLocation.pos + vector3(0, 0, 1.5), 'Sell Wine')
                if sellDist < 2.5 then
                    ShowHelpText('Press ~INPUT_CONTEXT~ to sell wine')
                    if IsControlJustReleased(0, 38) then
                        TriggerServerEvent('umeverse_jobs:server:sellVineyard')
                    end
                end
            end

            Wait(sleep)
        end
    end)
end

function PickGrapes(point)
    local ped = PlayerPedId()

    PlayJobAnim('amb@world_human_gardener_plant@male@base', 'base', cfg.pickDuration, 1)
    Wait(cfg.pickDuration)
    StopJobAnim()

    local grade = GetJobGrade()
    local yield = cfg.yieldPerGrade[grade + 1] or cfg.yieldPerGrade[1]

    TriggerServerEvent('umeverse_jobs:server:pickGrapes', yield)
    OnTaskComplete(0) -- Item collection, no direct pay
    grapesPickedCount = grapesPickedCount + 1
    JobNotify('Picked ~y~' .. yield .. 'x grapes~w~! (' .. grapesPickedCount .. '/' .. maxPicks .. ')', 'success')
end
