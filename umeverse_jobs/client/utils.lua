--[[
    Umeverse Jobs - Client Utilities
    Shared helper functions, progression, events, bonuses, and systems for all job scripts
]]

local UME = exports['umeverse_core']:GetCoreObject()
local activeJob = nil
local jobVehicle = nil
local jobBlips = {}

-- ═══════════════════════════════════════
-- Shift Tracking State
-- ═══════════════════════════════════════
local shiftData = {
    startTime     = 0,
    tasksCompleted = 0,
    totalEarned   = 0,
    xpEarned      = 0,
    rushActive     = false,
    rushDeadline   = 0,
    rushMultiplier = 1.0,
    vehicleStartHealth = 1000.0,
    npcEntities   = {},
}

-- ═══════════════════════════════════════
-- Core Job Data Helpers
-- ═══════════════════════════════════════

--- Check if player has a specific job
---@param jobName string
---@return boolean
function HasJob(jobName)
    local pd = UME.GetPlayerData()
    return pd and pd.job and pd.job.name == jobName
end

--- Get current player job data
---@return table|nil
function GetJobData()
    local pd = UME.GetPlayerData()
    return pd and pd.job
end

--- Get current job grade (0-indexed)
---@return number
function GetJobGrade()
    local pd = UME.GetPlayerData()
    if pd and pd.job then return pd.job.grade end
    return 0
end

--- Set the active job state and initialize shift tracking
---@param name string|nil
function SetActiveJob(name)
    activeJob = name
    if name then
        shiftData.startTime      = GetGameTimer()
        shiftData.tasksCompleted  = 0
        shiftData.totalEarned     = 0
        shiftData.xpEarned        = 0
        shiftData.rushActive      = false
        shiftData.rushDeadline    = 0
        shiftData.rushMultiplier  = 1.0
        shiftData.vehicleStartHealth = 1000.0
        -- Record vehicle health at shift start
        if jobVehicle and DoesEntityExist(jobVehicle) then
            shiftData.vehicleStartHealth = GetEntityHealth(jobVehicle)
        end
    end
end

--- Get the active job state
---@return string|nil
function GetActiveJob()
    return activeJob
end

--- Get the current shift data (read-only copy)
---@return table
function GetShiftData()
    return shiftData
end

-- ═══════════════════════════════════════
-- Vehicle Management
-- ═══════════════════════════════════════

--- Spawn a job vehicle and store reference
---@param model string
---@param pos vector4
---@return number|nil vehicle entity
function SpawnJobVehicle(model, pos)
    if jobVehicle and DoesEntityExist(jobVehicle) then
        DeleteEntity(jobVehicle)
        jobVehicle = nil
    end

    local hash = GetHashKey(model)
    RequestModel(hash)
    local timeout = 5000
    while not HasModelLoaded(hash) and timeout > 0 do
        Wait(10)
        timeout = timeout - 10
    end
    if not HasModelLoaded(hash) then return nil end

    jobVehicle = CreateVehicle(hash, pos.x, pos.y, pos.z, pos.w, true, false)
    SetModelAsNoLongerNeeded(hash)
    SetVehicleOnGroundProperly(jobVehicle)
    SetEntityAsMissionEntity(jobVehicle, true, true)
    SetVehicleDoorsLocked(jobVehicle, 1)
    SetVehicleNumberPlateText(jobVehicle, 'UME JOB')

    TaskWarpPedIntoVehicle(PlayerPedId(), jobVehicle, -1)

    -- Track starting health for condition system
    shiftData.vehicleStartHealth = GetEntityHealth(jobVehicle)

    return jobVehicle
end

--- Delete current job vehicle
function DeleteJobVehicle()
    if jobVehicle and DoesEntityExist(jobVehicle) then
        DeleteEntity(jobVehicle)
    end
    jobVehicle = nil
end

--- Get the job vehicle entity
---@return number|nil
function GetJobVehicle()
    return jobVehicle
end

-- ═══════════════════════════════════════
-- Drawing & UI Helpers
-- ═══════════════════════════════════════

--- Draw a 3D marker at position
---@param type number
---@param pos vector3
---@param r number
---@param g number
---@param b number
---@param a number
function DrawJobMarker(type, pos, r, g, b, a)
    DrawMarker(type, pos.x, pos.y, pos.z - 1.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
        1.5, 1.5, 1.0, r, g, b, a or 120, false, false, 2, true, nil, nil, false)
end

--- Draw floating help text at position (3D)
---@param pos vector3
---@param text string
function DrawText3D(pos, text)
    SetTextScale(0.35, 0.35)
    SetTextFont(4)
    SetTextProportional(true)
    SetTextEntry('STRING')
    SetTextCentre(true)
    AddTextComponentString(text)
    SetDrawOrigin(pos.x, pos.y, pos.z, 0)
    DrawText(0.0, 0.0)
    ClearDrawOrigin()
end

--- Display help text on screen (top-left style)
---@param text string
function ShowHelpText(text)
    BeginTextCommandDisplayHelp('STRING')
    AddTextComponentSubstringPlayerName(text)
    EndTextCommandDisplayHelp(0, false, true, -1)
end

--- Draw on-screen text (for HUD overlays like shift timer, streak)
---@param x number 0.0-1.0
---@param y number 0.0-1.0
---@param scale number
---@param text string
---@param r number
---@param g number
---@param b number
---@param a number
function DrawScreenText(x, y, scale, text, r, g, b, a)
    SetTextFont(4)
    SetTextScale(scale, scale)
    SetTextColour(r or 255, g or 255, b or 255, a or 255)
    SetTextOutline()
    SetTextEntry('STRING')
    AddTextComponentString(text)
    DrawText(x, y)
end

-- ═══════════════════════════════════════
-- Animation Helpers
-- ═══════════════════════════════════════

--- Play an animation on the player ped (with timeout safety)
---@param dict string
---@param anim string
---@param duration number ms
---@param flag number
function PlayJobAnim(dict, anim, duration, flag)
    local ped = PlayerPedId()
    RequestAnimDict(dict)
    local timeout = 3000
    while not HasAnimDictLoaded(dict) and timeout > 0 do
        Wait(10)
        timeout = timeout - 10
    end
    if not HasAnimDictLoaded(dict) then return end -- Safety: don't play if not loaded
    TaskPlayAnim(ped, dict, anim, 8.0, -8.0, duration or -1, flag or 1, 0, false, false, false)
end

--- Stop all animations
function StopJobAnim()
    ClearPedTasks(PlayerPedId())
end

-- ═══════════════════════════════════════
-- Blip Management
-- ═══════════════════════════════════════

--- Add a blip to the job blips list
---@param coords vector3
---@param sprite number
---@param color number
---@param label string
---@param route boolean|nil
---@return number blip
function AddJobBlip(coords, sprite, color, label, route)
    local blip = AddBlipForCoord(coords.x, coords.y, coords.z)
    SetBlipSprite(blip, sprite or 1)
    SetBlipDisplay(blip, 4)
    SetBlipScale(blip, 0.8)
    SetBlipColour(blip, color or 1)
    SetBlipAsShortRange(blip, true)
    BeginTextCommandSetBlipName('STRING')
    AddTextComponentString(label or 'Job')
    EndTextCommandSetBlipName(blip)
    if route then
        SetBlipRoute(blip, true)
        SetBlipRouteColour(blip, color or 1)
    end
    jobBlips[#jobBlips + 1] = blip
    return blip
end

--- Remove all active job blips
function ClearJobBlips()
    for _, blip in ipairs(jobBlips) do
        if DoesBlipExist(blip) then
            RemoveBlip(blip)
        end
    end
    jobBlips = {}
end

-- ═══════════════════════════════════════
-- Random Utilities
-- ═══════════════════════════════════════

--- Random weighted selection from a table of { item/id, weight }
---@param tbl table
---@return table entry (the full entry, not just item)
function WeightedRandom(tbl)
    local totalWeight = 0
    for _, entry in ipairs(tbl) do
        totalWeight = totalWeight + entry.weight
    end
    local roll = math.random(1, totalWeight)
    local cumulative = 0
    for _, entry in ipairs(tbl) do
        cumulative = cumulative + entry.weight
        if roll <= cumulative then
            return entry
        end
    end
    return tbl[1]
end

-- ═══════════════════════════════════════
-- Task Completion (Central Hook)
-- ═══════════════════════════════════════
-- Call this after every job action (collect, deliver, mine, etc.)
-- It handles: XP gain, streak tracking, random events, rush order check

--- Report a task completion to all enhancement systems
---@param payAmount number|nil The cash earned for this task (for tracking)
function OnTaskComplete(payAmount)
    shiftData.tasksCompleted = shiftData.tasksCompleted + 1
    shiftData.totalEarned = shiftData.totalEarned + (payAmount or 0)

    -- XP reward
    if JobsConfig.Progression and JobsConfig.Progression.enabled then
        local xp = JobsConfig.Progression.xpRewards.task_complete or 15
        TriggerServerEvent('umeverse_jobs:server:addXP', xp)
        shiftData.xpEarned = shiftData.xpEarned + xp
        if JobsConfig.Progression.showXPGain then
            JobNotify('+' .. xp .. ' XP', 'info')
        end
    end

    -- Rush order check
    if shiftData.rushActive then
        if GetGameTimer() <= shiftData.rushDeadline then
            -- Made it in time!
            local bonusPay = math.floor((payAmount or 0) * (shiftData.rushMultiplier - 1.0))
            if bonusPay > 0 then
                TriggerServerEvent('umeverse_jobs:server:bonusPay', bonusPay, 'Rush Order Bonus')
                JobNotify('~g~Rush Order complete! +$' .. bonusPay .. ' bonus!', 'success')
            end
        end
        shiftData.rushActive = false
    end

    -- Random event roll
    if JobsConfig.RandomEvents and JobsConfig.RandomEvents.enabled then
        local roll = math.random(1, 100)
        if roll <= JobsConfig.RandomEvents.triggerChance then
            TriggerRandomEvent()
        end
    end

    -- Job-specific random event roll (independent from base events)
    if JobsConfig.JobSpecificEvents and JobsConfig.JobSpecificEvents.enabled then
        local roll = math.random(1, 100)
        if roll <= (JobsConfig.RandomEvents and JobsConfig.RandomEvents.triggerChance or 15) then
            TriggerJobSpecificEvent()
        end
    end

    -- Speed bonus tracking for challenge system
    local isSpeed = IsSpeedBonus()
    local extraData = { speedBonus = isSpeed }

    -- Forward task to contract system
    if activeContract and GetActiveJob() then
        TriggerServerEvent('umeverse_jobs:server:contractTaskDone', GetActiveJob())
    end
end

-- ═══════════════════════════════════════
-- Random Events
-- ═══════════════════════════════════════

function TriggerRandomEvent()
    local events = JobsConfig.RandomEvents.events
    local event = WeightedRandom(events)
    if not event then return end

    if event.type == 'bonus_cash' then
        local amount = math.random(event.cashMin, event.cashMax)
        TriggerServerEvent('umeverse_jobs:server:bonusPay', amount, event.label)
        JobNotify('~g~' .. event.label .. '~w~ +$' .. amount .. '!', 'success')

    elseif event.type == 'bonus_xp' then
        TriggerServerEvent('umeverse_jobs:server:addXP', event.xpAmount)
        shiftData.xpEarned = shiftData.xpEarned + event.xpAmount
        JobNotify('~b~' .. event.label .. '~w~ +' .. event.xpAmount .. ' XP!', 'success')

    elseif event.type == 'timed_bonus' then
        -- Activate rush order for next task
        shiftData.rushActive = true
        shiftData.rushDeadline = GetGameTimer() + (event.timeLimit * 1000)
        shiftData.rushMultiplier = event.payMultiplier
        JobNotify('~o~' .. event.label .. '~w~! Complete next task in ~y~' .. event.timeLimit .. 's~w~ for ' .. math.floor(event.payMultiplier * 100) .. '%% pay!', 'info')
        StartRushTimer(event.timeLimit)

    elseif event.type == 'hazard' then
        HandleHazardEvent(event)

    elseif event.type == 'bonus_item' then
        local itemEntry = WeightedRandom(event.items)
        if itemEntry then
            TriggerServerEvent('umeverse_jobs:server:bonusItem', itemEntry.item, 1)
            JobNotify('~p~' .. event.label .. '~w~ Found a ~y~' .. itemEntry.label .. '~w~!', 'success')
        end
    end
end

--- Start a countdown timer display for rush orders
function StartRushTimer(seconds)
    CreateThread(function()
        local deadline = GetGameTimer() + (seconds * 1000)
        while shiftData.rushActive and GetGameTimer() < deadline and GetActiveJob() do
            local remaining = math.ceil((deadline - GetGameTimer()) / 1000)
            DrawScreenText(0.5, 0.02, 0.5, '~o~RUSH ORDER: ~w~' .. remaining .. 's', 255, 165, 0, 255)
            Wait(0)
        end
        if shiftData.rushActive then
            shiftData.rushActive = false
            JobNotify('Rush order expired!', 'error')
        end
    end)
end

--- Handle hazard events (flat tire, etc.)
function HandleHazardEvent(event)
    if event.id == 'flat_tire' then
        local veh = GetJobVehicle()
        if veh and DoesEntityExist(veh) then
            -- Burst a random tire
            local tireIdx = math.random(0, 3)
            SetVehicleTyreBurst(veh, tireIdx, false, 1000.0)
            JobNotify('~r~' .. event.label .. '~w~ ' .. event.description, 'error')

            -- Start repair prompt thread
            CreateThread(function()
                while GetActiveJob() and veh and DoesEntityExist(veh) and IsVehicleTyreBurst(veh, tireIdx, true) do
                    local ped = PlayerPedId()
                    if not IsPedInAnyVehicle(ped, false) then
                        local dist = #(GetEntityCoords(ped) - GetEntityCoords(veh))
                        if dist < 4.0 then
                            ShowHelpText('Press ~INPUT_CONTEXT~ to repair tire')
                            if IsControlJustReleased(0, 38) then
                                PlayJobAnim('mini@repair', 'fixing_a_ped', event.repairDuration, 1)
                                Wait(event.repairDuration)
                                StopJobAnim()
                                SetVehicleTyreFixed(veh, tireIdx)
                                JobNotify('Tire repaired!', 'success')
                                -- Bonus XP for handling hazard
                                TriggerServerEvent('umeverse_jobs:server:addXP', JobsConfig.Progression.xpRewards.bonus_task or 25)
                                return
                            end
                        end
                    end
                    Wait(0)
                end
            end)
        end
    end
end

-- ═══════════════════════════════════════
-- Vehicle Condition Tracking
-- ═══════════════════════════════════════

--- Get vehicle health percentage (0-100)
---@return number
function GetVehicleHealthPercent()
    local veh = GetJobVehicle()
    if not veh or not DoesEntityExist(veh) then return 100.0 end
    local bodyHealth = GetVehicleBodyHealth(veh)
    return math.floor((bodyHealth / 1000.0) * 100.0)
end

--- Calculate vehicle condition bonus/deduction for end of shift
---@return number multiplier (e.g., 1.15 for bonus, 0.70 for 30% deduction)
---@return string label
function GetVehicleConditionResult()
    if not JobsConfig.VehicleCondition or not JobsConfig.VehicleCondition.enabled then
        return 1.0, 'N/A'
    end

    local veh = GetJobVehicle()
    if not veh or not DoesEntityExist(veh) then return 1.0, 'No Vehicle' end

    local healthPct = GetVehicleHealthPercent()

    if healthPct >= JobsConfig.VehicleCondition.perfectThreshold then
        local bonus = 1.0 + (JobsConfig.VehicleCondition.perfectBonusPercent / 100.0)
        return bonus, '~g~Perfect Condition (+' .. JobsConfig.VehicleCondition.perfectBonusPercent .. '%)'
    end

    for _, tier in ipairs(JobsConfig.VehicleCondition.damageDeductions) do
        if healthPct >= tier.minHealth and healthPct <= tier.maxHealth then
            local mult = 1.0 - (tier.deductPercent / 100.0)
            if tier.deductPercent > 0 then
                return mult, '~r~Damaged (-' .. tier.deductPercent .. '%)'
            else
                return mult, '~y~Minor Wear'
            end
        end
    end

    return 1.0, 'Unknown'
end

-- ═══════════════════════════════════════
-- Weather & Time Bonuses
-- ═══════════════════════════════════════

--- Check if current time/weather qualifies for bonuses
---@return number multiplier
---@return string[] labels
function GetEnvironmentBonuses()
    if not JobsConfig.WeatherBonus or not JobsConfig.WeatherBonus.enabled then
        return 1.0, {}
    end

    local mult = 1.0
    local labels = {}

    -- Night bonus
    local hour = GetClockHours()
    local ns = JobsConfig.WeatherBonus.nightHours.start
    local nf = JobsConfig.WeatherBonus.nightHours.finish
    local isNight = (ns > nf) and (hour >= ns or hour < nf) or (hour >= ns and hour < nf)
    if isNight then
        mult = mult + (JobsConfig.WeatherBonus.nightBonusPercent / 100.0)
        labels[#labels + 1] = '~b~Night Shift (+' .. JobsConfig.WeatherBonus.nightBonusPercent .. '%)'
    end

    -- Rain bonus
    if GetRainLevel() > 0.0 then
        mult = mult + (JobsConfig.WeatherBonus.rainBonusPercent / 100.0)
        labels[#labels + 1] = '~c~Rain Bonus (+' .. JobsConfig.WeatherBonus.rainBonusPercent .. '%)'
    end

    return mult, labels
end

-- ═══════════════════════════════════════
-- Shift Timer & Speed Bonus
-- ═══════════════════════════════════════

--- Get elapsed shift time in seconds
---@return number
function GetShiftElapsed()
    if shiftData.startTime == 0 then return 0 end
    return math.floor((GetGameTimer() - shiftData.startTime) / 1000)
end

--- Get formatted shift time string (MM:SS)
---@return string
function GetShiftTimeString()
    local elapsed = GetShiftElapsed()
    local mins = math.floor(elapsed / 60)
    local secs = elapsed % 60
    return string.format('%02d:%02d', mins, secs)
end

--- Check if shift was completed under speed threshold
---@param customThreshold number|nil seconds
---@return boolean
function IsSpeedBonus(customThreshold)
    if not JobsConfig.ShiftTimer or not JobsConfig.ShiftTimer.enabled then return false end
    local threshold = customThreshold or JobsConfig.ShiftTimer.defaultSpeedThreshold
    return GetShiftElapsed() <= threshold
end

-- ═══════════════════════════════════════
-- NPC Helpers
-- ═══════════════════════════════════════

--- Spawn a job NPC at position
---@param model string
---@param pos vector4
---@param scenario string|nil
---@return number ped
function SpawnJobNPC(model, pos, scenario)
    local hash = GetHashKey(model)
    RequestModel(hash)
    local timeout = 5000
    while not HasModelLoaded(hash) and timeout > 0 do
        Wait(10)
        timeout = timeout - 10
    end
    if not HasModelLoaded(hash) then return 0 end

    local ped = CreatePed(4, hash, pos.x, pos.y, pos.z, pos.w or 0.0, false, true)
    SetModelAsNoLongerNeeded(hash)
    SetEntityAsMissionEntity(ped, true, true)
    SetBlockingOfNonTemporaryEvents(ped, true)
    SetPedFleeAttributes(ped, 0, false)
    SetEntityInvincible(ped, true)
    FreezeEntityPosition(ped, true)

    if scenario then
        TaskStartScenarioInPlace(ped, scenario, 0, true)
    end

    shiftData.npcEntities[#shiftData.npcEntities + 1] = ped
    return ped
end

--- Clean up all spawned job NPCs
function CleanupJobNPCs()
    for _, ped in ipairs(shiftData.npcEntities) do
        if DoesEntityExist(ped) then
            DeleteEntity(ped)
        end
    end
    shiftData.npcEntities = {}
end

-- ═══════════════════════════════════════
-- Shift Summary & End-of-Shift
-- ═══════════════════════════════════════

--- End the shift with a full summary, bonuses calculated and applied
---@param jobLabel string|nil Display name for the summary
function EndShiftWithSummary(jobLabel)
    if not GetActiveJob() then return end

    local summary = CalculateShiftSummary(jobLabel)
    local jobName = GetActiveJob()

    -- Apply end-of-shift bonuses server-side
    TriggerServerEvent('umeverse_jobs:server:endShift', summary)

    -- Determine shift stats for milestones
    local vehMult = GetVehicleConditionResult()
    local perfectVehicle = vehMult >= 1.0 + ((JobsConfig.VehicleCondition and JobsConfig.VehicleCondition.perfectBonusPercent or 15) / 100.0) - 0.01
    local isNight = false
    if JobsConfig.WeatherBonus and JobsConfig.WeatherBonus.enabled then
        local hour = GetClockHours()
        local nightStart = JobsConfig.WeatherBonus.nightHours.start
        local nightEnd = JobsConfig.WeatherBonus.nightHours.finish
        isNight = hour >= nightStart or hour < nightEnd
    end

    local shiftStats = {
        isNight = isNight,
        speedBonusCount = IsSpeedBonus() and 1 or 0,
        perfectVehicle = perfectVehicle,
        totalEarned = summary.grandTotal,
    }

    -- Trigger challenge shift-end
    TriggerServerEvent('umeverse_jobs:server:challengeShiftEnd', jobName, shiftStats)

    -- Trigger milestone check
    TriggerServerEvent('umeverse_jobs:server:checkMilestones', jobName, shiftStats)

    -- Display summary on screen
    if JobsConfig.ShiftSummary and JobsConfig.ShiftSummary.enabled then
        DisplayShiftSummary(summary)
    end

    -- Cleanup
    CleanupJob()
end

--- Calculate all shift bonuses and build summary table
---@param jobLabel string|nil
---@return table
function CalculateShiftSummary(jobLabel)
    local summary = {
        jobName       = GetActiveJob() or 'unknown',
        jobLabel      = jobLabel or (GetActiveJob() or 'Job'),
        duration      = GetShiftTimeString(),
        durationSecs  = GetShiftElapsed(),
        tasksCompleted = shiftData.tasksCompleted,
        basePay       = shiftData.totalEarned,
        xpEarned      = shiftData.xpEarned,
        bonuses       = {},
        totalBonus    = 0,
    }

    -- Vehicle condition bonus/deduction
    local vehMult, vehLabel = GetVehicleConditionResult()
    if vehMult ~= 1.0 then
        local vehBonus = math.floor(summary.basePay * (vehMult - 1.0))
        summary.bonuses[#summary.bonuses + 1] = { label = vehLabel, amount = vehBonus }
        summary.totalBonus = summary.totalBonus + vehBonus
    end

    -- Speed bonus
    if IsSpeedBonus() then
        local speedBonus = math.floor(summary.basePay * (JobsConfig.ShiftTimer.speedBonusPercent / 100.0))
        summary.bonuses[#summary.bonuses + 1] = { label = '~y~Speed Bonus (+' .. JobsConfig.ShiftTimer.speedBonusPercent .. '%)', amount = speedBonus }
        summary.totalBonus = summary.totalBonus + speedBonus

        -- Speed XP bonus
        TriggerServerEvent('umeverse_jobs:server:addXP', JobsConfig.Progression.xpRewards.speed_bonus or 20)
        summary.xpEarned = summary.xpEarned + (JobsConfig.Progression.xpRewards.speed_bonus or 20)
    end

    -- Weather/time bonuses
    local envMult, envLabels = GetEnvironmentBonuses()
    if envMult > 1.0 then
        local envBonus = math.floor(summary.basePay * (envMult - 1.0))
        for _, lbl in ipairs(envLabels) do
            summary.bonuses[#summary.bonuses + 1] = { label = lbl, amount = math.floor(envBonus / #envLabels) }
        end
        summary.totalBonus = summary.totalBonus + envBonus
    end

    -- Perfect shift XP (no damage + all tasks)
    if vehMult >= 1.0 + (JobsConfig.VehicleCondition.perfectBonusPercent / 100.0) - 0.01 then
        TriggerServerEvent('umeverse_jobs:server:addXP', JobsConfig.Progression.xpRewards.perfect_shift or 75)
        summary.xpEarned = summary.xpEarned + (JobsConfig.Progression.xpRewards.perfect_shift or 75)
    end

    -- Shift complete XP
    if JobsConfig.Progression and JobsConfig.Progression.enabled then
        TriggerServerEvent('umeverse_jobs:server:addXP', JobsConfig.Progression.xpRewards.shift_complete or 50)
        summary.xpEarned = summary.xpEarned + (JobsConfig.Progression.xpRewards.shift_complete or 50)
    end

    summary.grandTotal = summary.basePay + summary.totalBonus
    return summary
end

--- Display shift summary on screen
---@param summary table
function DisplayShiftSummary(summary)
    local duration = JobsConfig.ShiftSummary.displayDuration or 8000

    CreateThread(function()
        local endTime = GetGameTimer() + duration
        while GetGameTimer() < endTime do
            -- Dark background
            DrawRect(0.5, 0.35, 0.30, 0.35, 0, 0, 0, 180)

            -- Title
            DrawScreenText(0.5 - 0.12, 0.20, 0.55, '~y~SHIFT COMPLETE', 255, 200, 0, 255)
            DrawScreenText(0.5 - 0.12, 0.24, 0.35, summary.jobLabel .. ' | ' .. summary.duration, 255, 255, 255, 200)

            -- Stats
            local y = 0.29
            DrawScreenText(0.5 - 0.12, y, 0.32, 'Tasks: ~w~' .. summary.tasksCompleted, 200, 200, 200, 255)
            y = y + 0.025
            DrawScreenText(0.5 - 0.12, y, 0.32, 'Base Pay: ~g~$' .. summary.basePay, 200, 200, 200, 255)
            y = y + 0.025

            -- Bonuses
            for _, bonus in ipairs(summary.bonuses) do
                local sign = bonus.amount >= 0 and '+' or ''
                DrawScreenText(0.5 - 0.12, y, 0.30, bonus.label .. ' ~w~' .. sign .. '$' .. bonus.amount, 200, 200, 200, 255)
                y = y + 0.022
            end

            y = y + 0.01
            DrawScreenText(0.5 - 0.12, y, 0.38, '~g~Total: $' .. summary.grandTotal, 100, 255, 100, 255)
            y = y + 0.025
            DrawScreenText(0.5 - 0.12, y, 0.32, '~b~XP Earned: +' .. summary.xpEarned, 100, 150, 255, 255)

            Wait(0)
        end
    end)
end

-- ═══════════════════════════════════════
-- Shift HUD (Timer + Rush + Streak)
-- ═══════════════════════════════════════
-- Persistent HUD thread that shows shift info while on duty

CreateThread(function()
    while true do
        if GetActiveJob() then
            -- Shift timer in top-right
            local prestigeLabel = GetPrestigeLabel()
            local shiftLabel = prestigeLabel ~= '' and (prestigeLabel .. ' ~w~Shift: ~y~' .. GetShiftTimeString()) or ('~w~Shift: ~y~' .. GetShiftTimeString())
            DrawScreenText(0.87, 0.02, 0.33, shiftLabel, 255, 255, 255, 200)
            DrawScreenText(0.87, 0.045, 0.28, '~w~Tasks: ~y~' .. shiftData.tasksCompleted, 255, 255, 255, 180)

            -- Vehicle health bar (if in vehicle)
            local veh = GetJobVehicle()
            if veh and DoesEntityExist(veh) then
                local hp = GetVehicleHealthPercent()
                local col = hp > 70 and '~g~' or (hp > 40 and '~y~' or '~r~')
                DrawScreenText(0.87, 0.065, 0.28, '~w~Vehicle: ' .. col .. hp .. '%', 255, 255, 255, 180)
            end

            -- Co-Op HUD (lightweight check)
            DrawCoOpHUD()

            -- Daily Challenges HUD
            DrawChallengeHUD()

            -- Contract HUD
            DrawContractHUD()

            Wait(0)
        else
            Wait(1000)
        end
    end
end)

-- ═══════════════════════════════════════
-- Cleanup Everything
-- ═══════════════════════════════════════

--- Cleanup everything when ending a job
function CleanupJob()
    ClearJobBlips()
    DeleteJobVehicle()
    StopJobAnim()
    CleanupJobNPCs()
    RestoreOutfit()
    ClearMentorship()
    HideLeaderboard()
    currentChallenges = {}
    activeContract = nil
    currentPrestige = 0
    SetActiveJob(nil)
end

--- Notify wrapper
---@param msg string
---@param type string
function JobNotify(msg, type)
    TriggerEvent('umeverse:client:notify', msg, type or 'info')
end

-- ═══════════════════════════════════════
-- Client Event Listeners
-- ═══════════════════════════════════════

-- Server tells us how much we just got paid (for shift tracking)
RegisterNetEvent('umeverse_jobs:client:taskPaid', function(amount)
    -- Tracked via OnTaskComplete in each job, this is a fallback
end)

-- Streak update from server at end of shift
RegisterNetEvent('umeverse_jobs:client:streakUpdate', function(streak, payMult, xpMult, label)
    if streak >= 2 and label ~= '' then
        JobNotify(label .. '~w~ Streak: ' .. streak .. ' | Pay x' .. payMult .. ' | XP x' .. xpMult, 'info')
    end
end)

-- Promotion notification
RegisterNetEvent('umeverse_jobs:client:promoted', function(jobName, newGrade)
    -- Play a celebratory effect
    local ped = PlayerPedId()
    local pos = GetEntityCoords(ped)
    RequestNamedPtfxAsset('scr_indep_fireworks')
    local timeout = 3000
    while not HasNamedPtfxAssetLoaded('scr_indep_fireworks') and timeout > 0 do
        Wait(10)
        timeout = timeout - 10
    end
    if HasNamedPtfxAssetLoaded('scr_indep_fireworks') then
        UseParticleFxAsset('scr_indep_fireworks')
        StartNetworkedParticleFxNonLoopedAtCoord('scr_indep_firework_burst_spawn', pos.x, pos.y, pos.z + 2.0, 0.0, 0.0, 0.0, 1.0, false, false, false, false)
        RemoveNamedPtfxAsset('scr_indep_fireworks')
    end
end)

-- Progression data from server (for clock-in display)
RegisterNetEvent('umeverse_jobs:client:progressionData', function(data)
    if not data then return end

    -- Display progression overlay at clock-in
    CreateThread(function()
        local endTime = GetGameTimer() + 6000
        while GetGameTimer() < endTime do
            DrawRect(0.5, 0.78, 0.28, 0.18, 0, 0, 0, 170)

            DrawScreenText(0.38, 0.71, 0.35, '~y~JOB STATS', 255, 200, 0, 255)
            DrawScreenText(0.38, 0.735, 0.28, '~w~Grade: ~y~' .. data.grade .. '/' .. data.maxGrade .. '  ~w~XP: ~b~' .. data.xp, 255, 255, 255, 200)
            DrawScreenText(0.38, 0.755, 0.28, '~w~XP to next: ~b~' .. data.xpToNext, 255, 255, 255, 200)

            if data.streak >= 2 then
                DrawScreenText(0.38, 0.775, 0.28, data.streakLabel .. ' ~w~Streak: ' .. data.streak .. ' | Pay x' .. data.payMult, 255, 255, 255, 200)
            end

            DrawScreenText(0.38, 0.795, 0.25, '~w~Total Shifts: ' .. data.totalShifts .. ' | Earned: ~g~$' .. data.totalEarned, 200, 200, 200, 180)

            Wait(0)
        end
    end)
end)

-- ═══════════════════════════════════════
-- Uniform System (Client)
-- ═══════════════════════════════════════

local savedOutfit = nil -- Store player's original outfit before uniform

--- Save the player's current outfit components
function SaveCurrentOutfit()
    local ped = PlayerPedId()
    local outfit = {}
    for idx = 0, 11 do
        outfit[idx] = {
            drawable = GetPedDrawableVariation(ped, idx),
            texture = GetPedTextureVariation(ped, idx),
        }
    end
    savedOutfit = outfit
end

--- Apply a job uniform
---@param jobName string
function ApplyUniform(jobName)
    if not JobsConfig.Uniforms or not JobsConfig.Uniforms.enabled then return end
    local outfits = JobsConfig.Uniforms.outfits[jobName]
    if not outfits then return end

    -- Save original outfit first
    SaveCurrentOutfit()

    local ped = PlayerPedId()
    local isMale = GetEntityModel(ped) == GetHashKey('mp_m_freemode_01')
    local components = isMale and outfits.male or outfits.female
    if not components then return end

    for _, comp in ipairs(components) do
        SetPedComponentVariation(ped, comp.idx, comp.drawable, comp.texture, 0)
    end

    JobNotify('Changed into ' .. (outfits.label or 'work uniform'), 'info')
end

--- Restore original outfit on clock-out
function RestoreOutfit()
    if not savedOutfit then return end
    local ped = PlayerPedId()
    for idx, data in pairs(savedOutfit) do
        SetPedComponentVariation(ped, idx, data.drawable, data.texture, 0)
    end
    savedOutfit = nil
end

-- ═══════════════════════════════════════
-- Boss NPC System (Client)
-- ═══════════════════════════════════════

local bossNPCs = {} -- { jobName = entity }

--- Spawn all boss NPCs at their clock-in locations
function SpawnBossNPCs()
    if not JobsConfig.BossNPCs or not JobsConfig.BossNPCs.enabled then return end

    for jobName, bossData in pairs(JobsConfig.BossNPCs.bosses) do
        -- Find the clock-in point for this job from the clockInPoints table defined in clockin.lua
        -- We use the shared config directly
        local jobConfig = JobsConfig[jobName:sub(1,1):upper() .. jobName:sub(2)]
        if not jobConfig then
            -- Try alternate casing patterns
            local keyMap = {
                garbage = 'Garbage', bus = 'Bus', trucker = 'Trucker', fisherman = 'Fisherman',
                lumberjack = 'Lumberjack', miner = 'Miner', tow = 'Tow', pizza = 'Pizza',
                reporter = 'Reporter', taxi = 'Taxi', helitour = 'HeliTour', postal = 'Postal',
                dockworker = 'DockWorker', train = 'Train', hunter = 'Hunter', farmer = 'Farmer',
                diver = 'Diver', vineyard = 'Vineyard', electrician = 'Electrician', security = 'Security',
            }
            jobConfig = JobsConfig[keyMap[jobName]]
        end

        if jobConfig and jobConfig.clockIn and bossData.model then
            local basePos = jobConfig.clockIn
            local offset = bossData.offset
            local npcPos = vector3(basePos.x + offset.x, basePos.y + offset.y, basePos.z + offset.z)
            local heading = offset.w or 180.0

            local hash = GetHashKey(bossData.model)
            RequestModel(hash)
            local timeout = 5000
            while not HasModelLoaded(hash) and timeout > 0 do
                Wait(10)
                timeout = timeout - 10
            end

            if HasModelLoaded(hash) then
                local npc = CreatePed(4, hash, npcPos.x, npcPos.y, npcPos.z, heading, false, true)
                SetEntityAsMissionEntity(npc, true, false)
                SetBlockingOfNonTemporaryEvents(npc, true)
                SetPedFleeAttributes(npc, 0, false)
                FreezeEntityPosition(npc, true)
                SetEntityInvincible(npc, true)
                SetPedKeepTask(npc, true)

                if bossData.scenario then
                    TaskStartScenarioInPlace(npc, bossData.scenario, 0, true)
                end

                bossNPCs[jobName] = npc
                SetModelAsNoLongerNeeded(hash)
            end
        end
    end
end

--- Remove all boss NPCs
function DespawnBossNPCs()
    for jobName, entity in pairs(bossNPCs) do
        if DoesEntityExist(entity) then
            DeleteEntity(entity)
        end
    end
    bossNPCs = {}
end

-- ═══════════════════════════════════════
-- Daily Challenges HUD (Client)
-- ═══════════════════════════════════════

local currentChallenges = {}

RegisterNetEvent('umeverse_jobs:client:challengeUpdate', function(challenges)
    currentChallenges = challenges or {}
end)

RegisterNetEvent('umeverse_jobs:client:challengeComplete', function(challenge)
    if not challenge then return end
    -- Flash a big text on screen
    CreateThread(function()
        local endTime = GetGameTimer() + 4000
        while GetGameTimer() < endTime do
            DrawRect(0.5, 0.35, 0.3, 0.08, 0, 0, 0, 180)
            DrawScreenText(0.38, 0.325, 0.38, '~g~CHALLENGE COMPLETE!', 100, 255, 100, 255)
            DrawScreenText(0.38, 0.355, 0.28, '~w~' .. challenge.label, 255, 255, 255, 220)
            Wait(0)
        end
    end)
end)

--- Draw challenge progress on HUD (called in HUD thread)
function DrawChallengeHUD()
    if not JobsConfig.DailyChallenges or not JobsConfig.DailyChallenges.enabled then return end
    if not currentChallenges or #currentChallenges == 0 then return end

    local y = 0.09
    DrawScreenText(0.87, y, 0.25, '~y~Daily Challenges:', 255, 200, 0, 180)
    y = y + 0.02

    for _, ch in ipairs(currentChallenges) do
        local color = ch.completed and '~g~' or '~w~'
        local status = ch.completed and 'DONE' or (ch.progress .. '/' .. ch.target)
        DrawScreenText(0.87, y, 0.22, color .. ch.label .. ' ~w~[' .. status .. ']', 200, 200, 200, 160)
        y = y + 0.018
    end
end

-- ═══════════════════════════════════════
-- Milestones (Client)
-- ═══════════════════════════════════════

RegisterNetEvent('umeverse_jobs:client:milestoneUnlocked', function(milestone)
    if not milestone then return end
    -- Big celebration effect
    CreateThread(function()
        -- Play firework effect
        local ped = PlayerPedId()
        local pos = GetEntityCoords(ped)
        RequestNamedPtfxAsset('scr_indep_fireworks')
        local timeout = 3000
        while not HasNamedPtfxAssetLoaded('scr_indep_fireworks') and timeout > 0 do
            Wait(10)
            timeout = timeout - 10
        end
        if HasNamedPtfxAssetLoaded('scr_indep_fireworks') then
            UseParticleFxAsset('scr_indep_fireworks')
            StartNetworkedParticleFxNonLoopedAtCoord('scr_indep_firework_burst_spawn', pos.x, pos.y, pos.z + 3.0, 0.0, 0.0, 0.0, 1.5, false, false, false, false)
            RemoveNamedPtfxAsset('scr_indep_fireworks')
        end

        -- Display achievement banner
        local endTime = GetGameTimer() + 5000
        while GetGameTimer() < endTime do
            DrawRect(0.5, 0.15, 0.35, 0.10, 0, 0, 0, 200)
            DrawScreenText(0.35, 0.115, 0.42, '~y~🏅 ACHIEVEMENT UNLOCKED!', 255, 215, 0, 255)
            DrawScreenText(0.35, 0.15, 0.32, '~w~' .. milestone.label, 255, 255, 255, 230)
            DrawScreenText(0.35, 0.175, 0.25, '~w~' .. milestone.description, 200, 200, 200, 180)
            Wait(0)
        end
    end)
end)

-- ═══════════════════════════════════════
-- Prestige (Client)
-- ═══════════════════════════════════════

local currentPrestige = 0

RegisterNetEvent('umeverse_jobs:client:prestigeData', function(jobName, level)
    currentPrestige = level or 0
end)

RegisterNetEvent('umeverse_jobs:client:prestiged', function(jobName, newLevel)
    currentPrestige = newLevel or 0
    -- Big prestige celebration
    CreateThread(function()
        local ped = PlayerPedId()
        local pos = GetEntityCoords(ped)

        -- Play multiple fireworks
        RequestNamedPtfxAsset('scr_indep_fireworks')
        local timeout = 3000
        while not HasNamedPtfxAssetLoaded('scr_indep_fireworks') and timeout > 0 do
            Wait(10)
            timeout = timeout - 10
        end
        if HasNamedPtfxAssetLoaded('scr_indep_fireworks') then
            for i = 1, 3 do
                UseParticleFxAsset('scr_indep_fireworks')
                StartNetworkedParticleFxNonLoopedAtCoord('scr_indep_firework_burst_spawn', pos.x + math.random(-2, 2), pos.y + math.random(-2, 2), pos.z + 3.0 + i, 0.0, 0.0, 0.0, 2.0, false, false, false, false)
                Wait(500)
            end
            RemoveNamedPtfxAsset('scr_indep_fireworks')
        end

        -- Display prestige banner
        local endTime = GetGameTimer() + 6000
        local prestigeInfo = JobsConfig.Prestige and JobsConfig.Prestige.levels and JobsConfig.Prestige.levels[newLevel]
        local pLabel = prestigeInfo and prestigeInfo.name or ('Prestige ' .. newLevel)
        local stars = prestigeInfo and prestigeInfo.label or '★'

        while GetGameTimer() < endTime do
            DrawRect(0.5, 0.30, 0.35, 0.12, 10, 10, 40, 210)
            DrawScreenText(0.35, 0.26, 0.45, '~y~PRESTIGE UP!', 255, 215, 0, 255)
            DrawScreenText(0.35, 0.30, 0.38, stars .. ' ~w~' .. pLabel, 255, 255, 255, 240)
            DrawScreenText(0.35, 0.33, 0.25, '~w~Grade reset — Permanent bonuses active!', 200, 200, 200, 180)
            Wait(0)
        end
    end)
end)

--- Get prestige label for HUD display
function GetPrestigeLabel()
    if not JobsConfig.Prestige or not JobsConfig.Prestige.enabled or currentPrestige <= 0 then return '' end
    local info = JobsConfig.Prestige.levels[currentPrestige]
    return info and info.label or ''
end

-- ═══════════════════════════════════════
-- Contract System (Client)
-- ═══════════════════════════════════════

local activeContract = nil

RegisterNetEvent('umeverse_jobs:client:contractAccepted', function(contract)
    activeContract = contract
end)

RegisterNetEvent('umeverse_jobs:client:contractProgress', function(contract)
    activeContract = contract
end)

RegisterNetEvent('umeverse_jobs:client:contractComplete', function(contract)
    activeContract = nil
    -- Celebration
    CreateThread(function()
        local endTime = GetGameTimer() + 4000
        while GetGameTimer() < endTime do
            DrawRect(0.5, 0.35, 0.3, 0.08, 0, 0, 0, 180)
            DrawScreenText(0.38, 0.325, 0.38, '~g~CONTRACT COMPLETE!', 100, 255, 100, 255)
            DrawScreenText(0.38, 0.355, 0.28, '~w~' .. (contract and contract.label or 'Unknown'), 255, 255, 255, 220)
            Wait(0)
        end
    end)
end)

RegisterNetEvent('umeverse_jobs:client:contractFailed', function(contract)
    activeContract = nil
    JobNotify('Contract expired: ' .. (contract and contract.label or ''), 'error')
end)

RegisterNetEvent('umeverse_jobs:client:contractAbandoned', function()
    activeContract = nil
end)

function GetActiveContract()
    return activeContract
end

--- Draw contract progress on HUD
function DrawContractHUD()
    if not activeContract then return end

    local timeLeft = activeContract.expiresAt - os.time()
    if timeLeft < 0 then
        activeContract = nil
        return
    end

    local mins = math.floor(timeLeft / 60)
    local secs = timeLeft % 60
    local timeStr = string.format('%d:%02d', mins, secs)
    local timeColor = timeLeft < 60 and '~r~' or (timeLeft < 180 and '~y~' or '~w~')

    local y = 0.16
    DrawScreenText(0.87, y, 0.25, '~o~Contract: ~w~' .. activeContract.label, 255, 200, 100, 180)
    y = y + 0.018
    DrawScreenText(0.87, y, 0.22, '~w~Tasks: ~y~' .. activeContract.tasksDone .. '/' .. activeContract.tasksRequired, 200, 200, 200, 160)
    y = y + 0.018
    DrawScreenText(0.87, y, 0.22, '~w~Time: ' .. timeColor .. timeStr, 200, 200, 200, 160)
end

-- ═══════════════════════════════════════
-- Expanded Job-Specific Random Events (Client)
-- ═══════════════════════════════════════

--- Trigger a job-specific random event (called alongside the base TriggerRandomEvent)
function TriggerJobSpecificEvent()
    if not JobsConfig.JobSpecificEvents or not JobsConfig.JobSpecificEvents.enabled then return end
    local currentJob = GetActiveJob()
    if not currentJob then return end

    local events = JobsConfig.JobSpecificEvents.events[currentJob]
    if not events or #events == 0 then return end

    -- Roll weighted random
    local totalWeight = 0
    for _, ev in ipairs(events) do
        totalWeight = totalWeight + (ev.weight or 10)
    end

    local roll = math.random(1, totalWeight)
    local cumulative = 0
    local chosen = nil
    for _, ev in ipairs(events) do
        cumulative = cumulative + (ev.weight or 10)
        if roll <= cumulative then
            chosen = ev
            break
        end
    end

    if not chosen then return end

    -- Apply event
    if chosen.type == 'bonus_cash' then
        local amount = math.random(chosen.cashMin, chosen.cashMax)
        TriggerServerEvent('umeverse_jobs:server:bonusPay', amount, 'Job Event: ' .. chosen.label)
        JobNotify('⚡ ' .. chosen.label .. ': ' .. chosen.description .. ' (+$' .. amount .. ')', 'success')
    elseif chosen.type == 'bonus_xp' then
        TriggerServerEvent('umeverse_jobs:server:addXP', chosen.xpAmount)
        JobNotify('⚡ ' .. chosen.label .. ': ' .. chosen.description .. ' (+' .. chosen.xpAmount .. ' XP)', 'info')
    end
end

-- ═══════════════════════════════════════
-- Leaderboard Display (Client)
-- ═══════════════════════════════════════

local leaderboardData = nil
local showLeaderboard = false

RegisterNetEvent('umeverse_jobs:client:fullLeaderboardData', function(data)
    leaderboardData = data
    showLeaderboard = true

    CreateThread(function()
        local endTime = GetGameTimer() + 15000 -- Show for 15 seconds
        while GetGameTimer() < endTime and showLeaderboard do
            if not leaderboardData then break end

            DrawRect(0.5, 0.5, 0.5, 0.55, 0, 0, 0, 210)
            DrawScreenText(0.28, 0.26, 0.42, '~y~SERVER LEADERBOARD', 255, 215, 0, 255)

            local x = 0.28
            local catIdx = 0
            for catId, catData in pairs(leaderboardData) do
                local baseY = 0.30 + (catIdx * 0.13)
                DrawScreenText(x, baseY, 0.30, '~o~' .. catData.label, 255, 180, 50, 220)

                for i, entry in ipairs(catData.entries) do
                    if i <= 5 then -- Show top 5 per category
                        local rankColor = i == 1 and '~y~' or (i <= 3 and '~w~' or '~c~')
                        local valStr = catId == 'total_earned' and '$' .. entry.value or tostring(entry.value)
                        DrawScreenText(x, baseY + (i * 0.018), 0.22, rankColor .. '#' .. entry.rank .. ' ~w~' .. entry.name .. ' - ' .. valStr, 200, 200, 200, 180)
                    end
                end

                catIdx = catIdx + 1
            end

            Wait(0)
        end
        showLeaderboard = false
    end)
end)

function HideLeaderboard()
    showLeaderboard = false
    leaderboardData = nil
end

-- Single-category leaderboard response
RegisterNetEvent('umeverse_jobs:client:leaderboardData', function(category, data)
    if not data then return end
    leaderboardData = { [category] = { label = category, entries = data } }
    showLeaderboard = true

    CreateThread(function()
        local endTime = GetGameTimer() + 10000
        while GetGameTimer() < endTime and showLeaderboard do
            DrawRect(0.5, 0.5, 0.35, 0.3, 0, 0, 0, 210)
            DrawScreenText(0.35, 0.38, 0.35, '~y~LEADERBOARD: ' .. string.upper(category), 255, 215, 0, 255)

            for i, entry in ipairs(data) do
                if i <= 10 then
                    local rankColor = i == 1 and '~y~' or (i <= 3 and '~w~' or '~c~')
                    DrawScreenText(0.35, 0.42 + (i * 0.02), 0.22, rankColor .. '#' .. entry.rank .. ' ~w~' .. entry.name .. ' - ' .. tostring(entry.value), 200, 200, 200, 180)
                end
            end

            Wait(0)
        end
        showLeaderboard = false
    end)
end)

-- Milestones data response (list of unlocked milestones + global stats)
RegisterNetEvent('umeverse_jobs:client:milestonesData', function(milestones, gStats)
    if not milestones then return end

    CreateThread(function()
        local endTime = GetGameTimer() + 10000
        while GetGameTimer() < endTime do
            DrawRect(0.5, 0.5, 0.4, 0.4, 0, 0, 0, 210)
            DrawScreenText(0.32, 0.34, 0.35, '~y~MILESTONES & ACHIEVEMENTS', 255, 215, 0, 255)

            local y = 0.38
            local count = 0
            for _, m in pairs(milestones) do
                count = count + 1
            end

            DrawScreenText(0.32, y, 0.25, '~g~Unlocked: ' .. count .. ' / ' .. #JobsConfig.Milestones.achievements, 100, 255, 100, 200)
            y = y + 0.025

            if gStats then
                DrawScreenText(0.32, y, 0.22, '~w~Night Shifts: ' .. (gStats.night_shifts or 0) .. '  |  Speed Bonuses: ' .. (gStats.speed_bonuses or 0) .. '  |  Perfect Shifts: ' .. (gStats.perfect_shifts or 0), 200, 200, 200, 180)
                y = y + 0.025
            end

            -- Show recent unlocks
            local unlockList = {}
            for achId, _ in pairs(milestones) do
                unlockList[#unlockList + 1] = achId
            end
            table.sort(unlockList)

            for i, achId in ipairs(unlockList) do
                if i <= 8 then
                    DrawScreenText(0.32, y, 0.22, '~g~✓ ~w~' .. achId, 200, 200, 200, 160)
                    y = y + 0.02
                end
            end

            Wait(0)
        end
    end)
end)

-- ═══════════════════════════════════════
-- Mentorship (Client)
-- ═══════════════════════════════════════

local isMentored = false
local mentorPartner = nil

RegisterNetEvent('umeverse_jobs:client:mentorshipStarted', function(partnerId, asMentee)
    isMentored = true
    mentorPartner = partnerId
end)

function IsMentored()
    return isMentored
end

function ClearMentorship()
    isMentored = false
    mentorPartner = nil
end

-- ═══════════════════════════════════════
-- Co-Op Display (Client)
-- ═══════════════════════════════════════

--- Draw co-op bonus indicator on HUD (checks nearby players)
function DrawCoOpHUD()
    if not JobsConfig.CoOp or not JobsConfig.CoOp.enabled then return end
    if not GetActiveJob() then return end

    -- Only check every ~2 seconds to avoid performance hit
    -- Use a simple frame counter approach
    local partnerCount = 0
    local nearbyDist = JobsConfig.CoOp.nearbyDistance or 100.0
    local myPed = PlayerPedId()
    local myCoords = GetEntityCoords(myPed)

    for _, playerId in ipairs(GetActivePlayers()) do
        if playerId ~= PlayerId() then
            local otherPed = GetPlayerPed(playerId)
            if DoesEntityExist(otherPed) then
                local dist = #(myCoords - GetEntityCoords(otherPed))
                if dist <= nearbyDist then
                    partnerCount = partnerCount + 1
                end
            end
        end
    end

    if partnerCount > 0 then
        local maxP = JobsConfig.CoOp.maxPartners or 3
        local capped = math.min(partnerCount, maxP)
        local bonusPct = capped * (JobsConfig.CoOp.bonusPerPartner or 10)
        DrawScreenText(0.87, 0.085, 0.22, '~b~Co-Op: +' .. bonusPct .. '% (' .. capped .. ' nearby)', 100, 180, 255, 160)
    end
end
