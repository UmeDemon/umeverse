--[[
    Umeverse Jobs - Miner
    Mine rocks at the quarry, collect ores, sell at the depot
]]

local cfg = JobsConfig.Miner
local isMining = false

RegisterNetEvent('umeverse_jobs:client:startJob_miner', function()
    JobNotify('Mining shift started! Head to the ~y~quarry~w~ to mine rocks.', 'info')

    for i, rock in ipairs(cfg.rocks) do
        AddJobBlip(rock, 618, 44, 'Rock #' .. i, false)
    end
    AddJobBlip(vector3(cfg.sellPoint.x, cfg.sellPoint.y, cfg.sellPoint.z), 52, 2, 'Sell Ores', false)

    MinerLoop()
end)

function MinerLoop()
    CreateThread(function()
        while GetActiveJob() == 'miner' do
            local sleep = 500
            local ped = PlayerPedId()
            local myPos = GetEntityCoords(ped)

            -- Rock mining spots
            if not isMining then
                for _, rock in ipairs(cfg.rocks) do
                    local dist = #(myPos - rock)
                    if dist < JobsConfig.MarkerDrawDistance then
                        sleep = 0
                        DrawJobMarker(1, rock, 128, 128, 128, 120)

                        if dist < JobsConfig.InteractDistance and not IsPedInAnyVehicle(ped, false) then
                            ShowHelpText('Press ~INPUT_CONTEXT~ to mine rock')
                            if IsControlJustReleased(0, 38) then
                                MineRock()
                                break
                            end
                        end
                    end
                end
            end

            -- Sell point
            local sellDist = #(myPos - vector3(cfg.sellPoint.x, cfg.sellPoint.y, cfg.sellPoint.z))
            if sellDist < JobsConfig.MarkerDrawDistance then
                sleep = 0
                DrawJobMarker(1, vector3(cfg.sellPoint.x, cfg.sellPoint.y, cfg.sellPoint.z), 0, 200, 0, 120)
                DrawText3D(vector3(cfg.sellPoint.x, cfg.sellPoint.y, cfg.sellPoint.z + 1.0), 'Ore Buyer')

                if sellDist < JobsConfig.InteractDistance and not IsPedInAnyVehicle(ped, false) then
                    ShowHelpText('Press ~INPUT_CONTEXT~ to sell ores')
                    if IsControlJustReleased(0, 38) then
                        TriggerServerEvent('umeverse_jobs:server:sellOres')
                    end
                end
            end

            Wait(sleep)
        end
    end)
end

function MineRock()
    isMining = true
    JobNotify('Mining...', 'info')

    PlayJobAnim('melee@hatchet@streamed_core', 'plyr_base', cfg.animDuration, 1)

    Wait(cfg.animDuration)
    StopJobAnim()

    local ore = WeightedRandom(cfg.ores)
    TriggerServerEvent('umeverse_jobs:server:mineOre', ore.item)
    OnTaskComplete(0) -- Item collection, no direct pay

    local itemLabel = ore.item:gsub('_', ' '):gsub('^%l', string.upper)
    JobNotify('Collected: ~g~' .. itemLabel, 'success')
    isMining = false
end
