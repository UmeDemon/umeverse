--[[
    Umeverse Drugs - Processing (Enhanced)
    Data-driven conversion of raw materials into refined drugs with:
    - Batch selection (1x/2x/3x/5x based on rep)
    - Quality tier display
    - Failure chance indicator
    - Lab props spawned at process locations
    - Random encounters while processing
    - Rep + time-of-day speed/yield bonuses
]]

local UME = exports['umeverse_core']:GetCoreObject()

-- ═══════════════════════════════════════
-- Lab Props Tracking
-- ═══════════════════════════════════════

local nearbyLabProps = false

-- Spawn lab props when player approaches a processing location
local function HandleLabPropsNear(drugKey, pos, dist)
    if dist < DrugConfig.LabProps.drawDistance and not nearbyLabProps then
        nearbyLabProps = true
        SpawnLabProps(drugKey, 'processing', pos)
    elseif dist >= DrugConfig.LabProps.drawDistance + 10.0 and nearbyLabProps then
        nearbyLabProps = false
        CleanupLabProps()
    end
end

-- ═══════════════════════════════════════
-- Process with Batch Selection
-- ═══════════════════════════════════════

local function ProcessDrug(drugKey)
    if IsBusy() then return end

    local cfg = DrugConfig.Drugs[drugKey]
    if not cfg then return end

    SelectBatchSize(cfg.processLabel, function(batchSize)
        if not batchSize then return end -- Cancelled

        local recipe = cfg.processRecipe
        local quality = GetQualityTier()

        DrugProgressEnhanced(cfg.processProgress, recipe.time, recipe.anim, batchSize, 'process', function()
            TriggerServerEvent('umeverse_drugs:server:process', drugKey, batchSize)
        end)
    end)
end

-- ═══════════════════════════════════════
-- Processing Interaction Loop (all drugs)
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
                    for _, loc in ipairs(cfg.processLocations) do
                        local pos = vector3(loc.x, loc.y, loc.z)
                        local dist = #(myPos - pos)

                        -- Track closest for lab props
                        if dist < closestDist then
                            closestDist = dist
                            closestDrugKey = drugKey
                            closestPos = pos
                        end

                        if dist < DrugConfig.MarkerDrawDistance then
                            sleep = 0
                            local m = cfg.processMarker
                            DrawDrugMarker(1, pos, m.r, m.g, m.b, m.a)

                            -- Info text above marker
                            local quality = GetQualityTier()
                            local failChance = DrugConfig.Failure.enabled
                                and math.max(
                                    DrugConfig.Failure.baseChance - (GetDrugLevel() * DrugConfig.Failure.reductionPerLevel),
                                    DrugConfig.Failure.minChance
                                ) or 0
                            local batchText = DrugConfig.Batching.enabled and (' ~w~| Batches: x' .. #GetAvailableBatchSizes()) or ''
                            local nightTag = IsNightTime() and ' ~b~[NIGHT]' or ''

                            DrawText3DDrug(vector3(pos.x, pos.y, pos.z + 1.0),
                                '~b~' .. cfg.processLabel ..
                                '\n' .. quality.color .. quality.name .. '~s~' ..
                                ' ~r~Fail: ' .. failChance .. '%' ..
                                batchText .. nightTag
                            )

                            if dist < DrugConfig.InteractDistance then
                                -- Show recipe requirements
                                local recipe = cfg.processRecipe
                                local helpText = 'Press ~INPUT_CONTEXT~ to ' .. cfg.processHelp .. '\nNeeds:'
                                for _, input in ipairs(recipe.input) do
                                    helpText = helpText .. '\n  ' .. input.amount .. 'x ' .. input.item
                                end
                                ShowDrugHelp(helpText)

                                if IsControlJustReleased(0, 38) then
                                    ProcessDrug(drugKey)
                                end
                            end
                        end
                    end
                end
            end

            -- Handle lab prop spawning for closest location
            if closestDrugKey and closestPos then
                HandleLabPropsNear(closestDrugKey, closestPos, closestDist)
            elseif nearbyLabProps then
                nearbyLabProps = false
                CleanupLabProps()
            end
        end

        Wait(sleep)
    end
end)
