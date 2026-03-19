--[[
    Umeverse Drugs - Gathering (Enhanced)
    Data-driven raw material collection with:
    - Field depletion & regeneration
    - Rep-based yield bonuses
    - Quality tier display
    - Time-of-day modifiers
    - Random encounters while gathering
    - Enhanced progress bar with all info
]]

local UME = exports['umeverse_core']:GetCoreObject()

-- ═══════════════════════════════════════
-- Gather from a drug (shared handler)
-- ═══════════════════════════════════════

local function GatherDrug(drugKey, locIdx)
    if IsBusy() then return end

    local cfg = DrugConfig.Drugs[drugKey]
    if not cfg then return end

    -- Track depletion for field types
    if cfg.gatherType == 'field' then
        RecordFieldUse(drugKey, locIdx)
    end

    DrugProgressEnhanced(cfg.gatherProgress, cfg.gatherTime, cfg.gatherAnim, 1, 'gather', function()
        TriggerServerEvent('umeverse_drugs:server:gather', drugKey)
    end)
end

-- ═══════════════════════════════════════
-- NPC Supplier Spawning (for 'npc' gather type drugs)
-- ═══════════════════════════════════════

local gatherNpcs = {}

CreateThread(function()
    Wait(4000)

    for drugKey, cfg in pairs(DrugConfig.Drugs) do
        if cfg.gatherType == 'npc' then
            gatherNpcs[drugKey] = {}
            for i, loc in ipairs(cfg.gatherLocations) do
                if loc.npc then
                    local ped = SpawnDrugNpc(loc.model, loc.coords)
                    if ped then
                        gatherNpcs[drugKey][i] = ped
                    end
                end
            end
        end
    end
end)

-- ═══════════════════════════════════════
-- Field Gathering Loop (radius-based picking with depletion)
-- ═══════════════════════════════════════

CreateThread(function()
    Wait(4000)
    while true do
        local sleep = 1000
        local myPos = GetEntityCoords(PlayerPedId())

        if not IsBusy() then
            for drugKey, cfg in pairs(DrugConfig.Drugs) do
                if cfg.gatherType == 'field' and HasUnlocked(cfg.unlockKey) then
                    for locIdx, field in ipairs(cfg.gatherLocations) do
                        local dist = #(myPos - field.coords)

                        if dist < field.radius + 20.0 then
                            sleep = 500
                        end

                        if dist < field.radius then
                            sleep = 0

                            local depleted, usesLeft = IsFieldDepleted(drugKey, locIdx)

                            if depleted then
                                -- Show depleted marker (red, dimmed)
                                DrawDrugMarker(25, field.coords, 180, 30, 30, 40)
                                if dist < 3.0 then
                                    ShowDrugHelp('~r~This spot is depleted. Come back later.')
                                end
                            else
                                -- Normal gathering marker with depletion indicator
                                local m = cfg.gatherMarker
                                DrawDrugMarker(25, field.coords, m.r, m.g, m.b, m.a)

                                if dist < 3.0 then
                                    local quality = GetQualityTier()
                                    local nightTag = IsNightTime() and ' ~b~[Night Bonus]' or ''
                                    local depletionTag = DrugConfig.Depletion.enabled
                                        and (' ~w~[' .. usesLeft .. '/' .. DrugConfig.Depletion.maxUses .. ']')
                                        or ''
                                    ShowDrugHelp(
                                        'Press ~INPUT_CONTEXT~ to ' .. cfg.gatherLabel ..
                                        '\nQuality: ' .. quality.color .. quality.name ..
                                        depletionTag .. nightTag
                                    )
                                    if IsControlJustReleased(0, 38) then
                                        GatherDrug(drugKey, locIdx)
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end

        Wait(sleep)
    end
end)

-- ═══════════════════════════════════════
-- NPC Gathering Loop (buy from NPCs with quality info)
-- ═══════════════════════════════════════

CreateThread(function()
    Wait(5000)
    while true do
        local sleep = 1000
        local myPos = GetEntityCoords(PlayerPedId())

        if not IsBusy() then
            for drugKey, cfg in pairs(DrugConfig.Drugs) do
                if cfg.gatherType == 'npc' and HasUnlocked(cfg.unlockKey) then
                    for _, loc in ipairs(cfg.gatherLocations) do
                        local pos = vector3(loc.coords.x, loc.coords.y, loc.coords.z)
                        local dist = #(myPos - pos)

                        if dist < 15.0 then
                            sleep = 0
                            local m = cfg.gatherMarker
                            DrawDrugMarker(1, pos, m.r, m.g, m.b, m.a)

                            if dist < DrugConfig.InteractDistance then
                                local costText = cfg.gatherCost and ' ($' .. cfg.gatherCost .. ')' or ''
                                local quality = GetQualityTier()
                                local nightTag = IsNightTime() and '\n~b~Night Bonus Active' or ''
                                ShowDrugHelp(
                                    'Press ~INPUT_CONTEXT~ to ' .. cfg.gatherLabel .. costText ..
                                    '\nQuality: ' .. quality.color .. quality.name ..
                                    nightTag
                                )
                                if IsControlJustReleased(0, 38) then
                                    GatherDrug(drugKey, 0)
                                end
                            end
                        end
                    end
                end
            end
        end

        Wait(sleep)
    end
end)

-- ═══════════════════════════════════════
-- Supply Shop (Buy packaging materials)
-- ═══════════════════════════════════════

local shopNpcs = {}
local shopMenuOpen = false

CreateThread(function()
    Wait(4000)

    for i, shop in ipairs(DrugConfig.SupplyShops) do
        local ped = SpawnDrugNpc(shop.npcModel, shop.coords)
        if ped then
            shopNpcs[i] = ped
        end
    end
end)

CreateThread(function()
    Wait(5000)
    while true do
        local sleep = 1000
        local myPos = GetEntityCoords(PlayerPedId())

        if not IsBusy() then
            for i, shop in ipairs(DrugConfig.SupplyShops) do
                local pos = vector3(shop.coords.x, shop.coords.y, shop.coords.z)
                local dist = #(myPos - pos)

                if dist < 15.0 then
                    sleep = 0
                    DrawDrugMarker(1, pos, 160, 32, 240, 120)
                    DrawText3DDrug(vector3(pos.x, pos.y, pos.z + 1.0), shop.label)

                    if dist < DrugConfig.InteractDistance then
                        ShowDrugHelp('Press ~INPUT_CONTEXT~ to browse supplies')
                        if IsControlJustReleased(0, 38) then
                            OpenSupplyShop(i)
                        end
                    end
                end
            end
        end

        Wait(sleep)
    end
end)

function OpenSupplyShop(shopIdx)
    if IsBusy() or shopMenuOpen then return end

    local shop = DrugConfig.SupplyShops[shopIdx]
    if not shop then return end

    shopMenuOpen = true

    -- Simple menu using help text cycling
    local selectedIdx = 1
    local items = shop.items

    CreateThread(function()
        while shopMenuOpen do
            Wait(0)
            local item = items[selectedIdx]
            local text = '~b~' .. shop.label .. '~s~\n\n'
            for i, it in ipairs(items) do
                if i == selectedIdx then
                    text = text .. '~y~> ' .. it.label .. ' - $' .. it.price .. '~s~\n'
                else
                    text = text .. '  ' .. it.label .. ' - $' .. it.price .. '\n'
                end
            end
            text = text .. '\n~INPUT_CELLPHONE_UP~ / ~INPUT_CELLPHONE_DOWN~ Navigate\n~INPUT_CONTEXT~ Buy | ~INPUT_FRONTEND_CANCEL~ Close'

            local pos = GetEntityCoords(PlayerPedId())
            DrawText3DDrug(vector3(pos.x, pos.y, pos.z + 0.5), text)

            -- Navigate up
            if IsControlJustReleased(0, 172) then
                selectedIdx = selectedIdx - 1
                if selectedIdx < 1 then selectedIdx = #items end
            end

            -- Navigate down
            if IsControlJustReleased(0, 173) then
                selectedIdx = selectedIdx + 1
                if selectedIdx > #items then selectedIdx = 1 end
            end

            -- Buy
            if IsControlJustReleased(0, 38) then
                local buyItem = items[selectedIdx]
                TriggerServerEvent('umeverse_drugs:server:buySupply', buyItem.item, buyItem.price)
            end

            -- Close
            if IsControlJustReleased(0, 202) then
                shopMenuOpen = false
            end
        end
    end)
end
