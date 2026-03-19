--[[
    Umeverse Drugs - Client Utilities
    Shared helper functions for the drug system
]]

local UME = exports['umeverse_core']:GetCoreObject()

local drugBlips = {}
local spawnedNpcs = {}
local isBusy = false

-- ═══════════════════════════════════════
-- Player Data Helpers
-- ═══════════════════════════════════════

--- Get player drug rep from metadata
---@return number
function GetDrugRep()
    local pd = UME.GetPlayerData()
    if pd and pd.metadata and pd.metadata.drugRep then
        return pd.metadata.drugRep
    end
    return 0
end

--- Get player drug level from rep
---@return number level, table levelData
function GetDrugLevel()
    local rep = GetDrugRep()
    local currentLevel = 1
    local currentData = DrugConfig.Progression.levels[1]

    for level = 10, 1, -1 do
        local data = DrugConfig.Progression.levels[level]
        if rep >= data.xp then
            currentLevel = level
            currentData = data
            break
        end
    end

    return currentLevel, currentData
end

--- Check if player has unlocked a specific drug type
---@param drugType string 'weed', 'meth', 'cocaine', 'warehouse'
---@return boolean
function HasUnlocked(drugType)
    local rep = GetDrugRep()
    for level = 1, 10 do
        local data = DrugConfig.Progression.levels[level]
        if data.unlock == drugType then
            return rep >= data.xp
        end
    end
    return false
end

-- ═══════════════════════════════════════
-- Busy State
-- ═══════════════════════════════════════

function SetBusy(state)
    isBusy = state
end

function IsBusy()
    return isBusy
end

-- ═══════════════════════════════════════
-- Blip Management
-- ═══════════════════════════════════════

--- Add a blip to the drug blips list
---@param coords vector3
---@param sprite number
---@param color number
---@param label string
---@param scale number|nil
---@return number blip handle
function AddDrugBlip(coords, sprite, color, label, scale)
    local blip = AddBlipForCoord(coords.x, coords.y, coords.z)
    SetBlipSprite(blip, sprite)
    SetBlipDisplay(blip, 4)
    SetBlipScale(blip, scale or 0.65)
    SetBlipColour(blip, color)
    SetBlipAsShortRange(blip, true)
    BeginTextCommandSetBlipName('STRING')
    AddTextComponentString(label)
    EndTextCommandSetBlipName(blip)
    drugBlips[#drugBlips + 1] = blip
    return blip
end

--- Remove all drug blips
function ClearDrugBlips()
    for _, blip in ipairs(drugBlips) do
        if DoesBlipExist(blip) then
            RemoveBlip(blip)
        end
    end
    drugBlips = {}
end

-- ═══════════════════════════════════════
-- NPC Management
-- ═══════════════════════════════════════

--- Spawn a static NPC at a location
---@param model string
---@param coords vector4
---@return number|nil ped handle
function SpawnDrugNpc(model, coords)
    local hash = GetHashKey(model)
    RequestModel(hash)
    local timeout = 5000
    while not HasModelLoaded(hash) and timeout > 0 do
        Wait(10)
        timeout = timeout - 10
    end
    if not HasModelLoaded(hash) then return nil end

    local ped = CreatePed(4, hash, coords.x, coords.y, coords.z - 1.0, coords.w, false, true)
    SetEntityAsMissionEntity(ped, true, true)
    SetBlockingOfNonTemporaryEvents(ped, true)
    SetPedDiesWhenInjured(ped, false)
    SetPedCanPlayAmbientAnims(ped, true)
    FreezeEntityPosition(ped, true)
    SetEntityInvincible(ped, true)
    SetModelAsNoLongerNeeded(hash)

    spawnedNpcs[#spawnedNpcs + 1] = ped
    return ped
end

--- Clean up all spawned NPCs
function CleanupDrugNpcs()
    for _, ped in ipairs(spawnedNpcs) do
        if DoesEntityExist(ped) then
            DeleteEntity(ped)
        end
    end
    spawnedNpcs = {}
end

-- ═══════════════════════════════════════
-- Animation Helpers
-- ═══════════════════════════════════════

--- Play an animation with timeout
---@param dict string
---@param anim string
---@param duration number ms
---@param flag number
function PlayDrugAnim(dict, anim, duration, flag)
    RequestAnimDict(dict)
    local timeout = 3000
    while not HasAnimDictLoaded(dict) and timeout > 0 do
        Wait(10)
        timeout = timeout - 10
    end
    if not HasAnimDictLoaded(dict) then return end

    local ped = PlayerPedId()
    TaskPlayAnim(ped, dict, anim, 8.0, -8.0, duration, flag, 0, false, false, false)
end

--- Stop current animation
function StopDrugAnim()
    ClearPedTasks(PlayerPedId())
end

-- ═══════════════════════════════════════
-- Drawing Helpers
-- ═══════════════════════════════════════

--- Draw a marker in the world
---@param markerType number
---@param pos vector3
---@param r number
---@param g number
---@param b number
---@param a number
function DrawDrugMarker(markerType, pos, r, g, b, a)
    DrawMarker(markerType, pos.x, pos.y, pos.z - 0.97, 0, 0, 0, 0, 0, 0, 1.0, 1.0, 0.7, r, g, b, a, false, true, 2, nil, nil, false)
end

--- Draw 3D text in world
---@param pos vector3
---@param text string
function DrawText3DDrug(pos, text)
    SetTextScale(0.35, 0.35)
    SetTextFont(4)
    SetTextProportional(true)
    SetTextColour(255, 255, 255, 215)
    SetTextEntry('STRING')
    SetTextCentre(true)
    AddTextComponentString(text)
    SetDrawOrigin(pos.x, pos.y, pos.z, 0)
    DrawText(0.0, 0.0)
    ClearDrawOrigin()
end

--- Show help text
---@param text string
function ShowDrugHelp(text)
    BeginTextCommandDisplayHelp('STRING')
    AddTextComponentSubstringPlayerName(text)
    EndTextCommandDisplayHelp(0, false, true, -1)
end

-- ═══════════════════════════════════════
-- Notification wrapper
-- ═══════════════════════════════════════

function DrugNotify(msg, type)
    TriggerEvent('umeverse:client:notify', msg, type or 'info', 5000)
end

-- ═══════════════════════════════════════
-- Quality System Helpers
-- ═══════════════════════════════════════

--- Get the player's current quality tier based on drug rep level
---@return table tier data { name, color, yieldMult, priceMult }
function GetQualityTier()
    if not DrugConfig.Quality.enabled then
        return { name = 'Standard', color = '~w~', yieldMult = 1.0, priceMult = 1.0 }
    end

    local level = GetDrugLevel()
    for _, tier in ipairs(DrugConfig.Quality.tiers) do
        if level >= tier.minLevel and level <= tier.maxLevel then
            return tier
        end
    end
    return DrugConfig.Quality.tiers[1]
end

--- Get all batch sizes the player can use
---@return table array of { size, requiredLevel }
function GetAvailableBatchSizes()
    if not DrugConfig.Batching.enabled then
        return { { size = 1, requiredLevel = 1 } }
    end

    local level = GetDrugLevel()
    local available = {}
    for _, batch in ipairs(DrugConfig.Batching.sizes) do
        if level >= batch.requiredLevel then
            available[#available + 1] = batch
        end
    end
    return available
end

--- Get time-of-day modifier
---@return table { yieldMult, speedMult }
function GetTimeOfDayMod()
    if not DrugConfig.TimeOfDay.enabled then
        return { yieldMult = 1.0, speedMult = 1.0 }
    end

    local hour = GetClockHours()
    local isNight = hour >= DrugConfig.TimeOfDay.nightStart or hour < DrugConfig.TimeOfDay.nightEnd

    if isNight then
        return DrugConfig.TimeOfDay.nightBonuses
    else
        return DrugConfig.TimeOfDay.dayBonuses
    end
end

--- Check if it's nighttime in-game
---@return boolean
function IsNightTime()
    if not DrugConfig.TimeOfDay.enabled then return false end
    local hour = GetClockHours()
    return hour >= DrugConfig.TimeOfDay.nightStart or hour < DrugConfig.TimeOfDay.nightEnd
end

--- Get rep-based speed multiplier (lower = faster)
---@return number multiplier (0.5 to 1.0)
function GetRepSpeedMult()
    if not DrugConfig.RepBonuses.speedEnabled then return 1.0 end
    local level = GetDrugLevel()
    local bonus = math.min(level * DrugConfig.RepBonuses.speedPerLevel, DrugConfig.RepBonuses.maxSpeedBonus)
    return 1.0 - bonus
end

--- Get rep-based yield multiplier (higher = more output)
---@return number multiplier (1.0 to 1.4)
function GetRepYieldMult()
    if not DrugConfig.RepBonuses.yieldEnabled then return 1.0 end
    local level = GetDrugLevel()
    local bonus = math.min(level * DrugConfig.RepBonuses.yieldPerLevel, DrugConfig.RepBonuses.maxYieldBonus)
    return 1.0 + bonus
end

--- Calculate total adjusted duration for an action
---@param baseDuration number base time in ms
---@param batchSize number|nil number of batches (default 1)
---@return number adjusted duration in ms
function CalcAdjustedDuration(baseDuration, batchSize)
    batchSize = batchSize or 1
    local repSpeed = GetRepSpeedMult()
    local todSpeed = GetTimeOfDayMod().speedMult

    -- First batch = full duration, extra batches = diminishing time
    local totalTime = baseDuration
    if batchSize > 1 and DrugConfig.Batching.enabled then
        local extraTime = baseDuration * DrugConfig.Batching.timePerBatch * (batchSize - 1)
        totalTime = totalTime + extraTime
    end

    return math.floor(totalTime * repSpeed * todSpeed)
end

-- ═══════════════════════════════════════
-- Batch Selection Menu
-- ═══════════════════════════════════════

--- Open a batch size selector before processing/packaging
--- Returns the selected batch size via callback, or nil if cancelled
---@param actionLabel string e.g. "Cook Meth" or "Package Cocaine"
---@param cb function(batchSize) called with selected size, or nil if cancelled
function SelectBatchSize(actionLabel, cb)
    local available = GetAvailableBatchSizes()

    -- If only 1x is available, skip the menu
    if #available <= 1 then
        cb(1)
        return
    end

    local selectedIdx = 1
    local menuOpen = true

    CreateThread(function()
        while menuOpen do
            Wait(0)
            local text = '~b~' .. actionLabel .. '~s~\n~w~Select Batch Size:\n\n'
            for i, batch in ipairs(available) do
                if i == selectedIdx then
                    text = text .. '~y~> ' .. batch.size .. 'x Batch~s~\n'
                else
                    text = text .. '  ' .. batch.size .. 'x Batch\n'
                end
            end

            local quality = GetQualityTier()
            local todMod = GetTimeOfDayMod()
            local nightTag = IsNightTime() and ' ~b~[NIGHT]~s~' or ''
            text = text .. '\nQuality: ' .. quality.color .. quality.name .. '~s~' .. nightTag
            text = text .. '\n\n~INPUT_CELLPHONE_UP~ / ~INPUT_CELLPHONE_DOWN~ Select'
            text = text .. '\n~INPUT_CONTEXT~ Confirm | ~INPUT_FRONTEND_CANCEL~ Cancel'

            local pos = GetEntityCoords(PlayerPedId())
            DrawText3DDrug(vector3(pos.x, pos.y, pos.z + 0.5), text)

            -- Navigate up
            if IsControlJustReleased(0, 172) then
                selectedIdx = selectedIdx - 1
                if selectedIdx < 1 then selectedIdx = #available end
            end

            -- Navigate down
            if IsControlJustReleased(0, 173) then
                selectedIdx = selectedIdx + 1
                if selectedIdx > #available then selectedIdx = 1 end
            end

            -- Confirm
            if IsControlJustReleased(0, 38) then
                menuOpen = false
                cb(available[selectedIdx].size)
            end

            -- Cancel
            if IsControlJustReleased(0, 202) then
                menuOpen = false
                cb(nil)
            end
        end
    end)
end

-- ═══════════════════════════════════════
-- Field Depletion Tracking
-- ═══════════════════════════════════════

local depletionState = {} -- key = drugKey..loc_index, value = { uses, depletedAt }

--- Check if a gathering spot is depleted
---@param drugKey string
---@param locIdx number
---@return boolean isDepleted, number usesLeft
function IsFieldDepleted(drugKey, locIdx)
    if not DrugConfig.Depletion.enabled then return false, DrugConfig.Depletion.maxUses end

    local key = drugKey .. '_' .. locIdx
    local state = depletionState[key]
    if not state then return false, DrugConfig.Depletion.maxUses end

    -- Check if cooldown has passed
    if state.depletedAt and (GetGameTimer() - state.depletedAt) / 1000 >= DrugConfig.Depletion.cooldownTime then
        depletionState[key] = nil
        return false, DrugConfig.Depletion.maxUses
    end

    if state.uses >= DrugConfig.Depletion.maxUses then
        return true, 0
    end

    return false, DrugConfig.Depletion.maxUses - state.uses
end

--- Record a gather use at a field spot
---@param drugKey string
---@param locIdx number
function RecordFieldUse(drugKey, locIdx)
    if not DrugConfig.Depletion.enabled then return end

    local key = drugKey .. '_' .. locIdx
    if not depletionState[key] then
        depletionState[key] = { uses = 0, depletedAt = nil }
    end

    depletionState[key].uses = depletionState[key].uses + 1
    if depletionState[key].uses >= DrugConfig.Depletion.maxUses then
        depletionState[key].depletedAt = GetGameTimer()
    end
end

-- ═══════════════════════════════════════
-- Random Encounter Spawning
-- ═══════════════════════════════════════

local encounterPeds = {}

--- Roll for a random encounter and spawn it if triggered
---@param encounterType string 'gather' or 'process'
function TryRandomEncounter(encounterType)
    if not DrugConfig.RandomEncounters.enabled then return end

    local chance = encounterType == 'gather'
        and DrugConfig.RandomEncounters.gatherChance
        or DrugConfig.RandomEncounters.processChance

    if math.random(100) > chance then return end

    -- Weighted random selection
    local types = DrugConfig.RandomEncounters.types
    local totalWeight = 0
    for _, t in ipairs(types) do totalWeight = totalWeight + t.weight end

    local roll = math.random(totalWeight)
    local cumulative = 0
    local selected = types[1]
    for _, t in ipairs(types) do
        cumulative = cumulative + t.weight
        if roll <= cumulative then
            selected = t
            break
        end
    end

    -- Handle bonus stash (no ped spawn, just extra items)
    if selected.bonusItem then
        DrugNotify('~g~' .. selected.label .. '~s~ You found extra supplies!', 'success')
        TriggerServerEvent('umeverse_drugs:server:bonusFind')
        return
    end

    -- Spawn hostile/neutral peds
    local myPos = GetEntityCoords(PlayerPedId())
    local count = math.random(selected.pedCount[1], selected.pedCount[2])

    DrugNotify('~r~' .. selected.label .. ' spotted nearby!', 'error')

    for i = 1, count do
        local angle = math.rad(math.random(360))
        local dist = selected.radius * 0.5 + math.random() * selected.radius * 0.5
        local spawnPos = vector4(
            myPos.x + math.cos(angle) * dist,
            myPos.y + math.sin(angle) * dist,
            myPos.z,
            math.random(360) + 0.0
        )

        -- Get ground Z
        local foundGround, groundZ = GetGroundZFor_3dCoord(spawnPos.x, spawnPos.y, spawnPos.z + 50.0, false)
        if foundGround then
            spawnPos = vector4(spawnPos.x, spawnPos.y, groundZ, spawnPos.w)
        end

        local hash = GetHashKey(selected.pedModel)
        RequestModel(hash)
        local timeout = 3000
        while not HasModelLoaded(hash) and timeout > 0 do
            Wait(10)
            timeout = timeout - 10
        end

        if HasModelLoaded(hash) then
            local ped = CreatePed(4, hash, spawnPos.x, spawnPos.y, spawnPos.z, spawnPos.w, true, true)
            SetEntityAsMissionEntity(ped, true, true)
            SetModelAsNoLongerNeeded(hash)

            if selected.hostile then
                -- Arm and aggro hostile peds
                GiveWeaponToPed(ped, GetHashKey('WEAPON_PISTOL'), 100, false, true)
                TaskCombatPed(ped, PlayerPedId(), 0, 16)
                SetPedCombatAttributes(ped, 46, true) -- always fight
                SetPedFleeAttributes(ped, 0, false)
            else
                -- Non-hostile: just wander/flee
                TaskWanderStandard(ped, 10.0, 10)
            end

            encounterPeds[#encounterPeds + 1] = { ped = ped, despawnAt = GetGameTimer() + (selected.despawnTime * 1000) }
        end
    end
end

--- Cleanup expired encounter peds (call periodically)
function CleanupEncounterPeds()
    local now = GetGameTimer()
    local alive = {}
    for _, entry in ipairs(encounterPeds) do
        if now < entry.despawnAt and DoesEntityExist(entry.ped) and not IsEntityDead(entry.ped) then
            alive[#alive + 1] = entry
        else
            if DoesEntityExist(entry.ped) then
                DeleteEntity(entry.ped)
            end
        end
    end
    encounterPeds = alive
end

-- ═══════════════════════════════════════
-- Lab Props Management
-- ═══════════════════════════════════════

local labPropEntities = {}

--- Spawn lab props at a location
---@param drugKey string
---@param locType string 'processing' or 'packaging'
---@param basePos vector3
function SpawnLabProps(drugKey, locType, basePos)
    if not DrugConfig.LabProps.enabled then return end

    local propSet = DrugConfig.LabProps[locType]
    if not propSet then return end

    local props = propSet[drugKey] or propSet['default']
    if not props then return end

    for _, propDef in ipairs(props) do
        local hash = GetHashKey(propDef.model)
        RequestModel(hash)
        local timeout = 3000
        while not HasModelLoaded(hash) and timeout > 0 do
            Wait(10)
            timeout = timeout - 10
        end

        if HasModelLoaded(hash) then
            local pos = basePos + propDef.offset
            local obj = CreateObject(hash, pos.x, pos.y, pos.z, false, false, false)
            if obj and obj ~= 0 then
                SetEntityAsMissionEntity(obj, true, true)
                FreezeEntityPosition(obj, true)
                PlaceObjectOnGroundProperly(obj)
                SetModelAsNoLongerNeeded(hash)
                labPropEntities[#labPropEntities + 1] = obj
            end
        end
    end
end

--- Remove all lab props
function CleanupLabProps()
    for _, obj in ipairs(labPropEntities) do
        if DoesEntityExist(obj) then
            DeleteEntity(obj)
        end
    end
    labPropEntities = {}
end

-- ═══════════════════════════════════════
-- Enhanced Progress Bar
-- ═══════════════════════════════════════

--- Run an enhanced progress with quality display, speed bonuses, and encounter rolls
---@param label string
---@param baseDuration number ms (before adjustments)
---@param animData table|nil { dict, anim, flag }
---@param batchSize number
---@param encounterType string|nil 'gather', 'process', or nil for no encounter roll
---@param cb function callback on complete
function DrugProgressEnhanced(label, baseDuration, animData, batchSize, encounterType, cb)
    if IsBusy() then return end
    SetBusy(true)

    local ped = PlayerPedId()
    FreezeEntityPosition(ped, true)

    local duration = CalcAdjustedDuration(baseDuration, batchSize)
    local quality = GetQualityTier()
    local batchTag = batchSize > 1 and (' x' .. batchSize) or ''
    local qualityTag = DrugConfig.Quality.enabled and (' ' .. quality.color .. quality.name .. '~s~') or ''
    local nightTag = IsNightTime() and ' ~b~[NIGHT]~s~' or ''

    if animData then
        PlayDrugAnim(animData.dict, animData.anim, duration, animData.flag or 1)
    end

    -- Roll for random encounter at start
    if encounterType then
        TryRandomEncounter(encounterType)
    end

    local startTime = GetGameTimer()
    CreateThread(function()
        while GetGameTimer() - startTime < duration do
            Wait(0)
            local elapsed = GetGameTimer() - startTime
            local pct = math.floor((elapsed / duration) * 100)
            local pos = GetEntityCoords(ped)
            DrawText3DDrug(vector3(pos.x, pos.y, pos.z + 1.0),
                label .. batchTag .. ' [' .. pct .. '%]' .. qualityTag .. nightTag)
        end

        StopDrugAnim()
        FreezeEntityPosition(ped, false)
        SetBusy(false)

        if cb then cb() end
    end)
end

-- ═══════════════════════════════════════
-- Progress bar helper (legacy, still used for simple actions)
-- ═══════════════════════════════════════

--- Run a progress with animation (freezes player)
---@param label string
---@param duration number ms
---@param animData table|nil { dict, anim, flag }
---@param cb function callback on complete
function DrugProgress(label, duration, animData, cb)
    if IsBusy() then return end
    SetBusy(true)

    local ped = PlayerPedId()
    FreezeEntityPosition(ped, true)

    if animData then
        PlayDrugAnim(animData.dict, animData.anim, duration, animData.flag or 1)
    end

    -- Simple timer-based progress (no NUI needed)
    local startTime = GetGameTimer()
    CreateThread(function()
        while GetGameTimer() - startTime < duration do
            Wait(0)
            -- Draw progress text
            local elapsed = GetGameTimer() - startTime
            local pct = math.floor((elapsed / duration) * 100)
            local pos = GetEntityCoords(ped)
            DrawText3DDrug(vector3(pos.x, pos.y, pos.z + 1.0), label .. ' [' .. pct .. '%]')
        end

        StopDrugAnim()
        FreezeEntityPosition(ped, false)
        SetBusy(false)

        if cb then cb() end
    end)
end

-- ═══════════════════════════════════════
-- Cleanup on resource stop
-- ═══════════════════════════════════════

AddEventHandler('onResourceStop', function(resource)
    if resource == GetCurrentResourceName() then
        ClearDrugBlips()
        CleanupDrugNpcs()
        CleanupLabProps()
        CleanupEncounterPeds()
    end
end)

-- Periodic encounter ped cleanup
CreateThread(function()
    while true do
        Wait(10000)
        CleanupEncounterPeds()
    end
end)
