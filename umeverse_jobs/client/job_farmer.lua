--[[
    Umeverse Jobs - Farmer
    Harvest crops at farm fields, carry them to storage, then sell
]]

local cfg = JobsConfig.Farmer
local harvestActive = false
local harvestedCount = 0
local maxHarvest = 0

RegisterNetEvent('umeverse_jobs:client:startJob_farmer', function()
    harvestActive = true
    harvestedCount = 0
    local grade = GetJobGrade()
    maxHarvest = cfg.harvestsPerShift[grade + 1] or cfg.harvestsPerShift[1]

    JobNotify('Farming shift started! Head to a ~y~field~w~ and start harvesting.', 'info')
    SetFarmBlips()
    FarmLoop()
end)

function SetFarmBlips()
    ClearJobBlips()
    for i, field in ipairs(cfg.fields) do
        AddJobBlip(field.center, 88, 25, 'Farm Field ' .. i, false)
    end
    AddJobBlip(cfg.sellLocation.pos, 52, 2, 'Sell Crops', false)
end

function FarmLoop()
    CreateThread(function()
        while GetActiveJob() == 'farmer' do
            local sleep = 500
            local ped = PlayerPedId()
            local myPos = GetEntityCoords(ped)

            -- Show harvest points in fields
            for _, field in ipairs(cfg.fields) do
                local fieldDist = #(myPos - field.center)
                if fieldDist < field.radius + 10.0 then
                    for _, point in ipairs(field.harvestPoints) do
                        local dist = #(myPos - point)
                        if dist < 10.0 then
                            sleep = 0
                            DrawJobMarker(25, point - vector3(0, 0, 0.5), 50, 200, 50, 120)
                            if dist < 2.0 and not IsPedInAnyVehicle(ped, false) then
                                if harvestedCount < maxHarvest then
                                    ShowHelpText('Press ~INPUT_CONTEXT~ to harvest crop')
                                    if IsControlJustReleased(0, 38) then
                                        HarvestCrop(field, point)
                                    end
                                else
                                    ShowHelpText('Shift complete! Sell your crops.')
                                end
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
                DrawText3D(cfg.sellLocation.pos + vector3(0, 0, 1.5), 'Sell Crops')
                if sellDist < 2.5 then
                    ShowHelpText('Press ~INPUT_CONTEXT~ to sell crops')
                    if IsControlJustReleased(0, 38) then
                        TriggerServerEvent('umeverse_jobs:server:sellCrops')
                    end
                end
            end

            Wait(sleep)
        end
    end)
end

function HarvestCrop(field, point)
    local ped = PlayerPedId()
    local cropType = cfg.cropTypes[math.random(#cfg.cropTypes)]

    -- Kneel and harvest
    PlayJobAnim('amb@world_human_gardener_plant@male@base', 'base', cfg.harvestDuration, 1)
    Wait(cfg.harvestDuration)
    StopJobAnim()

    local grade = GetJobGrade()
    local yield = cfg.yieldPerGrade[grade + 1] or cfg.yieldPerGrade[1]

    TriggerServerEvent('umeverse_jobs:server:harvestCrop', cropType.item, yield)
    OnTaskComplete(0) -- Item collection, no direct pay
    harvestedCount = harvestedCount + 1
    JobNotify('Harvested ~y~' .. yield .. 'x ' .. cropType.label .. '~w~! (' .. harvestedCount .. '/' .. maxHarvest .. ')', 'success')
end
