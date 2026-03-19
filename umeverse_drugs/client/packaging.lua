--[[
    Umeverse Drugs - Packaging (Enhanced)
    Data-driven packaging of refined drugs into sellable products with:
    - Batch selection (1x/2x/3x/5x based on rep)
    - Quality tier display affecting output
    - Rep + time-of-day speed/yield bonuses
    - Packaging props at work locations
]]

local UME = exports['umeverse_core']:GetCoreObject()

-- ═══════════════════════════════════════
-- Packaging Props Tracking
-- ═══════════════════════════════════════

local nearbyPkgProps = false

local function HandlePackagePropsNear(drugKey, pos, dist)
    if dist < DrugConfig.LabProps.drawDistance and not nearbyPkgProps then
        nearbyPkgProps = true
        SpawnLabProps(drugKey, 'packaging', pos)
    elseif dist >= DrugConfig.LabProps.drawDistance + 10.0 and nearbyPkgProps then
        nearbyPkgProps = false
        CleanupLabProps()
    end
end

-- ═══════════════════════════════════════
-- Package with Batch Selection
-- ═══════════════════════════════════════

local function PackageDrug(drugKey)
    if IsBusy() then return end

    local cfg = DrugConfig.Drugs[drugKey]
    if not cfg then return end

    SelectBatchSize(cfg.packageLabel, function(batchSize)
        if not batchSize then return end

        local recipe = cfg.packageRecipe

        DrugProgressEnhanced(cfg.packageProgress, recipe.time, recipe.anim, batchSize, nil, function()
            TriggerServerEvent('umeverse_drugs:server:package', drugKey, batchSize)
        end)
    end)
end

-- ═══════════════════════════════════════
-- Packaging Interaction Loop (all drugs)
-- ═══════════════════════════════════════

CreateThread(function()
    Wait(4000)
    while true do
        local sleep = 1000
        local myPos = GetEntityCoords(PlayerPedId())

        if not IsBusy() then
            local closestDist = 999.0
            local closestDrugKey = nil
            local closestPos = nil

            for drugKey, cfg in pairs(DrugConfig.Drugs) do
                if HasUnlocked(cfg.unlockKey) then
                    for _, loc in ipairs(cfg.packageLocations) do
                        local pos = vector3(loc.x, loc.y, loc.z)
                        local dist = #(myPos - pos)

                        if dist < closestDist then
                            closestDist = dist
                            closestDrugKey = drugKey
                            closestPos = pos
                        end

                        if dist < DrugConfig.MarkerDrawDistance then
                            sleep = 0
                            local m = cfg.packageMarker
                            DrawDrugMarker(1, pos + vector3(1.5, 0, 0), m.r, m.g, m.b, m.a)

                            -- Info display
                            local quality = GetQualityTier()
                            local batchText = DrugConfig.Batching.enabled and (' ~w~| Batches: x' .. #GetAvailableBatchSizes()) or ''
                            local nightTag = IsNightTime() and ' ~b~[NIGHT]' or ''

                            DrawText3DDrug(vector3(pos.x + 1.5, pos.y, pos.z + 1.0),
                                '~g~' .. cfg.packageLabel ..
                                '\n' .. quality.color .. quality.name .. '~s~' ..
                                batchText .. nightTag
                            )

                            if dist < DrugConfig.InteractDistance + 1.5 then
                                -- Show recipe requirements
                                local recipe = cfg.packageRecipe
                                local helpText = 'Press ~INPUT_PICKUP~ to ' .. cfg.packageHelp .. '\nNeeds:'
                                for _, input in ipairs(recipe.input) do
                                    helpText = helpText .. '\n  ' .. input.amount .. 'x ' .. input.item
                                end
                                ShowDrugHelp(helpText)

                                if IsControlJustReleased(0, 169) then -- INPUT_PICKUP = G key
                                    PackageDrug(drugKey)
                                end
                            end
                        end
                    end
                end
            end

            -- Handle packaging prop spawning
            if closestDrugKey and closestPos then
                HandlePackagePropsNear(closestDrugKey, closestPos, closestDist)
            elseif nearbyPkgProps then
                nearbyPkgProps = false
                CleanupLabProps()
            end
        end

        Wait(sleep)
    end
end)
