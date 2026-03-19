--[[
    Umeverse Jobs - Fisherman
    Fish at designated spots, collect fish items, sell at the sell point
]]

local cfg = JobsConfig.Fisherman
local isFishing = false

RegisterNetEvent('umeverse_jobs:client:startJob_fisherman', function()
    JobNotify('You are now on the fishing shift. Head to a ~b~fishing spot~w~ on the coast.', 'info')

    -- Add blips for all fishing spots
    for i, spot in ipairs(cfg.fishingSpots) do
        AddJobBlip(spot, 68, 3, 'Fishing Spot #' .. i, false)
    end
    AddJobBlip(vector3(cfg.sellPoint.x, cfg.sellPoint.y, cfg.sellPoint.z), 52, 2, 'Fish Market (Sell)', false)

    FishermanLoop()
end)

function FishermanLoop()
    CreateThread(function()
        while GetActiveJob() == 'fisherman' do
            local sleep = 500
            local ped = PlayerPedId()
            local myPos = GetEntityCoords(ped)

            -- Check fishing spots
            if not isFishing then
                for _, spot in ipairs(cfg.fishingSpots) do
                    local dist = #(myPos - spot)
                    if dist < JobsConfig.MarkerDrawDistance then
                        sleep = 0
                        DrawJobMarker(1, spot, 0, 100, 200, 120)

                        if dist < JobsConfig.InteractDistance and not IsPedInAnyVehicle(ped, false) then
                            ShowHelpText('Press ~INPUT_CONTEXT~ to fish')
                            if IsControlJustReleased(0, 38) then
                                StartFishing()
                                break
                            end
                        end
                    end
                end
            end

            -- Check sell point
            local sellDist = #(myPos - vector3(cfg.sellPoint.x, cfg.sellPoint.y, cfg.sellPoint.z))
            if sellDist < JobsConfig.MarkerDrawDistance then
                sleep = 0
                DrawJobMarker(1, vector3(cfg.sellPoint.x, cfg.sellPoint.y, cfg.sellPoint.z), 0, 200, 0, 120)
                DrawText3D(vector3(cfg.sellPoint.x, cfg.sellPoint.y, cfg.sellPoint.z + 1.0), 'Fish Market')

                if sellDist < JobsConfig.InteractDistance and not IsPedInAnyVehicle(ped, false) then
                    ShowHelpText('Press ~INPUT_CONTEXT~ to sell fish')
                    if IsControlJustReleased(0, 38) then
                        TriggerServerEvent('umeverse_jobs:server:sellFish')
                    end
                end
            end

            Wait(sleep)
        end
    end)
end

function StartFishing()
    isFishing = true
    local ped = PlayerPedId()

    JobNotify('Casting line...', 'info')

    -- Face water direction and play fishing animation
    PlayJobAnim('amb@world_human_stand_fishing@idle_a', 'idle_c', cfg.animDuration, 1)

    -- Progress timer
    local startTime = GetGameTimer()
    CreateThread(function()
        while isFishing and GetActiveJob() == 'fisherman' do
            local elapsed = GetGameTimer() - startTime
            if elapsed >= cfg.animDuration then
                -- Catch a fish
                StopJobAnim()
                local caught = WeightedRandom(cfg.catches)
                TriggerServerEvent('umeverse_jobs:server:catchFish', caught.item)
                OnTaskComplete(0) -- Item collection, no direct pay

                local itemLabel = caught.item:gsub('_', ' '):gsub('^%l', string.upper)
                JobNotify('You caught a ~g~' .. itemLabel .. '~w~!', 'success')
                isFishing = false
                return
            end
            Wait(100)
        end
        StopJobAnim()
        isFishing = false
    end)
end
