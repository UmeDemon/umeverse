--[[
    Umeverse Jobs - Hunter
    Track and hunt animals in the wilderness, skin them, then sell goods
]]

local cfg = JobsConfig.Hunter
local huntActive = false
local animalsSpawned = {}
local carriedItems = {}

RegisterNetEvent('umeverse_jobs:client:startJob_hunter', function()
    huntActive = true
    carriedItems = {}

    JobNotify('Hunting shift started! Head to a ~y~hunting zone~w~ to search for animals.', 'info')
    SetHuntBlips()
    HuntLoop()
end)

function SetHuntBlips()
    ClearJobBlips()
    for i, zone in ipairs(cfg.huntingZones) do
        AddJobBlip(zone.center, 141, 25, 'Hunting Zone ' .. i, false)
    end
    AddJobBlip(cfg.sellLocation.pos, 52, 2, 'Sell Goods', false)
end

function HuntLoop()
    CreateThread(function()
        while GetActiveJob() == 'hunter' do
            local sleep = 500
            local ped = PlayerPedId()
            local myPos = GetEntityCoords(ped)

            -- Check hunting zones
            for _, zone in ipairs(cfg.huntingZones) do
                local dist = #(myPos - zone.center)
                if dist < zone.radius then
                    sleep = 200
                    -- Spawn random animals if none are alive
                    if #animalsSpawned == 0 and not IsPedInAnyVehicle(ped, false) then
                        SpawnAnimals(zone)
                    end
                end
            end

            -- Check for dead animals nearby to skin
            for i = #animalsSpawned, 1, -1 do
                local animal = animalsSpawned[i]
                if DoesEntityExist(animal.ped) then
                    if IsEntityDead(animal.ped) then
                        local animalPos = GetEntityCoords(animal.ped)
                        local dist = #(myPos - animalPos)
                        if dist < 10.0 then
                            sleep = 0
                            DrawJobMarker(1, animalPos - vector3(0, 0, 0.5), 200, 150, 50, 120)
                            if dist < 2.5 then
                                ShowHelpText('Press ~INPUT_CONTEXT~ to skin animal')
                                if IsControlJustReleased(0, 38) then
                                    SkinAnimal(animal, i)
                                end
                            end
                        end
                    end
                else
                    table.remove(animalsSpawned, i)
                end
            end

            -- Sell location
            local sellDist = #(myPos - cfg.sellLocation.pos)
            if sellDist < 15.0 then
                sleep = 0
                DrawJobMarker(1, cfg.sellLocation.pos, 50, 200, 50, 120)
                DrawText3D(cfg.sellLocation.pos + vector3(0, 0, 1.5), 'Sell Hunting Goods')
                if sellDist < 2.5 then
                    ShowHelpText('Press ~INPUT_CONTEXT~ to sell goods')
                    if IsControlJustReleased(0, 38) then
                        TriggerServerEvent('umeverse_jobs:server:sellHunterGoods')
                    end
                end
            end

            Wait(sleep)
        end
        -- Cleanup
        for _, animal in ipairs(animalsSpawned) do
            if DoesEntityExist(animal.ped) then
                DeleteEntity(animal.ped)
            end
        end
        animalsSpawned = {}
    end)
end

function SpawnAnimals(zone)
    local count = math.random(cfg.minAnimals, cfg.maxAnimals)
    local animalTypes = cfg.animalModels

    for i = 1, count do
        local animal = animalTypes[math.random(#animalTypes)]
        local offset = vector3(math.random(-40, 40), math.random(-40, 40), 0)
        local spawnPos = zone.center + offset

        local found, groundZ = GetGroundZFor_3dCoord(spawnPos.x, spawnPos.y, spawnPos.z + 50.0, false)
        if found then
            spawnPos = vector3(spawnPos.x, spawnPos.y, groundZ)
        end

        local hash = GetHashKey(animal.model)
        RequestModel(hash)
        local timeout = 0
        while not HasModelLoaded(hash) and timeout < 50 do
            Wait(100)
            timeout = timeout + 1
        end

        if HasModelLoaded(hash) then
            local animalPed = CreatePed(28, hash, spawnPos.x, spawnPos.y, spawnPos.z, math.random(0, 360) + 0.0, true, false)
            SetEntityAsMissionEntity(animalPed, true, true)
            TaskWanderStandard(animalPed, 10.0, 10)
            SetPedFleeAttributes(animalPed, 0, false) -- Don't flee immediately
            SetModelAsNoLongerNeeded(hash)

            table.insert(animalsSpawned, {
                ped = animalPed,
                type = animal.type,
                pelt = animal.pelt,
                meat = animal.meat
            })
        end
    end
end

function SkinAnimal(animal, index)
    local ped = PlayerPedId()
    TaskTurnPedToFaceEntity(ped, animal.ped, 1000)
    Wait(1000)

    PlayJobAnim('mini@repair', 'fixing_a_ped', cfg.skinDuration, 1)
    Wait(cfg.skinDuration)
    StopJobAnim()

    TriggerServerEvent('umeverse_jobs:server:huntSkinAnimal', animal.pelt, animal.meat)
    OnTaskComplete(0) -- Item collection, no direct pay
    JobNotify('Skinned animal! Got ~y~pelt~w~ and ~y~meat~w~.', 'success')

    if DoesEntityExist(animal.ped) then
        DeleteEntity(animal.ped)
    end
    table.remove(animalsSpawned, index)
end
