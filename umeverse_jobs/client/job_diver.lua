--[[
    Umeverse Jobs - Diver / Salvager
    Dive to underwater markers, salvage items, then sell at dock
]]

local cfg = JobsConfig.Diver
local divesCompleted = 0
local maxDives = 0

RegisterNetEvent('umeverse_jobs:client:startJob_diver', function()
    divesCompleted = 0
    local grade = GetJobGrade()
    maxDives = cfg.divesPerShift[grade + 1] or cfg.divesPerShift[1]

    JobNotify('Diving shift started! Head to a ~y~dive site~w~. Bring a boat!', 'info')
    SetDiveBlips()
    DiveLoop()
end)

function SetDiveBlips()
    ClearJobBlips()
    for i, site in ipairs(cfg.diveSites) do
        AddJobBlip(site.surface, 410, 3, 'Dive Site ' .. i, false)
    end
    AddJobBlip(cfg.sellLocation.pos, 52, 2, 'Sell Salvage', false)
end

function DiveLoop()
    CreateThread(function()
        while GetActiveJob() == 'diver' do
            local sleep = 500
            local ped = PlayerPedId()
            local myPos = GetEntityCoords(ped)

            -- Dive sites
            for siteIdx, site in ipairs(cfg.diveSites) do
                -- Check underwater salvage points
                for _, point in ipairs(site.salvagePoints) do
                    local dist = #(myPos - point)
                    if dist < 15.0 then
                        sleep = 0
                        DrawJobMarker(1, point, 100, 200, 255, 120)
                        if dist < 2.5 then
                            if divesCompleted < maxDives then
                                ShowHelpText('Press ~INPUT_CONTEXT~ to salvage')
                                if IsControlJustReleased(0, 38) then
                                    SalvageItem(point)
                                end
                            else
                                ShowHelpText('Shift complete! Sell your salvage.')
                            end
                        end
                    end
                end
            end

            -- Sell location
            local sellDist = #(myPos - cfg.sellLocation.pos)
            if sellDist < 15.0 then
                sleep = 0
                DrawJobMarker(1, cfg.sellLocation.pos, 50, 200, 50, 120)
                DrawText3D(cfg.sellLocation.pos + vector3(0, 0, 1.5), 'Sell Salvage')
                if sellDist < 2.5 then
                    ShowHelpText('Press ~INPUT_CONTEXT~ to sell salvage')
                    if IsControlJustReleased(0, 38) then
                        TriggerServerEvent('umeverse_jobs:server:sellSalvage')
                    end
                end
            end

            Wait(sleep)
        end
    end)
end

function SalvageItem(point)
    local ped = PlayerPedId()

    -- Salvage animation (reaching/grabbing)
    PlayJobAnim('mini@repair', 'fixing_a_ped', cfg.salvageDuration, 1)
    Wait(cfg.salvageDuration)
    StopJobAnim()

    -- Weighted random item
    local item = WeightedRandom(cfg.salvageItems)
    TriggerServerEvent('umeverse_jobs:server:salvageDive', item.item)
    OnTaskComplete(0) -- Item collection, no direct pay
    divesCompleted = divesCompleted + 1
    JobNotify('Found ~y~' .. item.label .. '~w~! (' .. divesCompleted .. '/' .. maxDives .. ')', 'success')
end
