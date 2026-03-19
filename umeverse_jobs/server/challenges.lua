-- ═══════════════════════════════════════════════════════════════════
-- Umeverse Jobs - Daily Challenges System (Server)
-- ═══════════════════════════════════════════════════════════════════

local UME = exports['umeverse_core']:GetCoreObject()

local playerChallenges = {} -- [citizenid][jobName] = { challengeList }

-- ───────────────────────────────────────
-- Helpers
-- ───────────────────────────────────────

local function GetCitizenId(src)
    local player = UME.GetPlayer(src)
    if not player then return nil end
    return player.GetPlayerData().citizenid
end

local function GetTodayDate()
    return os.date('%Y-%m-%d')
end

--- Pick N random challenges from the template pool
local function PickChallenges(count)
    if not JobsConfig.DailyChallenges or not JobsConfig.DailyChallenges.enabled then return {} end
    local pool = JobsConfig.DailyChallenges.templates
    if not pool or #pool == 0 then return {} end

    local shuffled = {}
    for i, v in ipairs(pool) do shuffled[i] = v end
    for i = #shuffled, 2, -1 do
        local j = math.random(1, i)
        shuffled[i], shuffled[j] = shuffled[j], shuffled[i]
    end

    local picked = {}
    for i = 1, math.min(count, #shuffled) do
        picked[#picked + 1] = shuffled[i]
    end
    return picked
end

-- ───────────────────────────────────────
-- DB Operations
-- ───────────────────────────────────────

local function LoadChallenges(citizenid, jobName)
    local today = GetTodayDate()
    local rows = exports.oxmysql:executeSync(
        'SELECT challenge_id, progress, target, completed FROM umeverse_job_challenges WHERE citizenid = ? AND job_name = ? AND assigned_date = ?',
        { citizenid, jobName, today }
    )
    return rows or {}
end

local function AssignChallenges(citizenid, jobName)
    local today = GetTodayDate()
    local count = JobsConfig.DailyChallenges.challengesPerDay or 2
    local challenges = PickChallenges(count)

    local result = {}
    for _, tmpl in ipairs(challenges) do
        exports.oxmysql:execute(
            'INSERT IGNORE INTO umeverse_job_challenges (citizenid, job_name, challenge_id, progress, target, assigned_date) VALUES (?, ?, ?, 0, ?, ?)',
            { citizenid, jobName, tmpl.id, tmpl.target, today }
        )
        result[#result + 1] = {
            id = tmpl.id,
            label = tmpl.label,
            description = tmpl.description,
            type = tmpl.type,
            progress = 0,
            target = tmpl.target,
            completed = false,
        }
    end
    return result
end

local function SaveChallengeProgress(citizenid, jobName, challengeId, progress, completed)
    local today = GetTodayDate()
    exports.oxmysql:execute(
        'UPDATE umeverse_job_challenges SET progress = ?, completed = ? WHERE citizenid = ? AND job_name = ? AND challenge_id = ? AND assigned_date = ?',
        { progress, completed and 1 or 0, citizenid, jobName, challengeId, today }
    )
end

-- ───────────────────────────────────────
-- Get/Ensure Challenges for a Player
-- ───────────────────────────────────────

local function EnsureChallenges(citizenid, jobName)
    if not playerChallenges[citizenid] then playerChallenges[citizenid] = {} end

    if playerChallenges[citizenid][jobName] then
        return playerChallenges[citizenid][jobName]
    end

    -- Try loading from DB
    local rows = LoadChallenges(citizenid, jobName)
    if #rows > 0 then
        -- Map DB rows to full template data
        local templateMap = {}
        for _, tmpl in ipairs(JobsConfig.DailyChallenges.templates) do
            templateMap[tmpl.id] = tmpl
        end

        local challenges = {}
        for _, row in ipairs(rows) do
            local tmpl = templateMap[row.challenge_id]
            if tmpl then
                challenges[#challenges + 1] = {
                    id = tmpl.id,
                    label = tmpl.label,
                    description = tmpl.description,
                    type = tmpl.type,
                    progress = row.progress,
                    target = row.target,
                    completed = row.completed == 1,
                }
            end
        end

        if #challenges > 0 then
            playerChallenges[citizenid][jobName] = challenges
            return challenges
        end
    end

    -- Assign new challenges for today
    local challenges = AssignChallenges(citizenid, jobName)
    playerChallenges[citizenid][jobName] = challenges
    return challenges
end

-- ───────────────────────────────────────
-- Progress Tracking
-- ───────────────────────────────────────

local function UpdateChallengeProgress(src, citizenid, jobName, challengeType, amount)
    if not JobsConfig.DailyChallenges or not JobsConfig.DailyChallenges.enabled then return end
    local challenges = EnsureChallenges(citizenid, jobName)
    if not challenges then return end

    for _, ch in ipairs(challenges) do
        if not ch.completed and ch.type == challengeType then
            ch.progress = math.min(ch.progress + amount, ch.target)

            if ch.progress >= ch.target then
                ch.completed = true
                SaveChallengeProgress(citizenid, jobName, ch.id, ch.progress, true)

                -- Award bonus
                local player = UME.GetPlayer(src)
                if player then
                    local cashBonus = JobsConfig.DailyChallenges.cashBonus or 500
                    local xpBonus = JobsConfig.DailyChallenges.xpBonus or 100
                    player.AddMoney('cash', cashBonus, 'daily-challenge-' .. ch.id)
                    TriggerEvent('umeverse_jobs:server:addXP', src, xpBonus)
                    TriggerClientEvent('umeverse:client:notify', src, '🏆 Challenge Complete: ' .. ch.label .. ' (+$' .. cashBonus .. ', +' .. xpBonus .. ' XP)', 'success')
                    TriggerClientEvent('umeverse_jobs:client:challengeComplete', src, ch)
                end
            else
                SaveChallengeProgress(citizenid, jobName, ch.id, ch.progress, false)
            end
        end
    end

    -- Send updated challenges to client
    TriggerClientEvent('umeverse_jobs:client:challengeUpdate', src, challenges)
end

-- ───────────────────────────────────────
-- Events
-- ───────────────────────────────────────

-- Called when a player clocks in — load/assign their challenges
RegisterNetEvent('umeverse_jobs:server:getChallenges', function(jobName)
    local src = source
    if not JobsConfig.DailyChallenges or not JobsConfig.DailyChallenges.enabled then return end
    local citizenid = GetCitizenId(src)
    if not citizenid then return end

    local challenges = EnsureChallenges(citizenid, jobName)
    TriggerClientEvent('umeverse_jobs:client:challengeUpdate', src, challenges)
end)

-- Called by main.lua when a task is completed
RegisterNetEvent('umeverse_jobs:server:challengeTaskDone', function(jobName, extraData)
    local src = source
    if not JobsConfig.DailyChallenges or not JobsConfig.DailyChallenges.enabled then return end
    local citizenid = GetCitizenId(src)
    if not citizenid then return end

    -- Update task-based challenges
    UpdateChallengeProgress(src, citizenid, jobName, 'tasks', 1)

    -- Update speed-based if applicable
    if extraData and extraData.speedBonus then
        UpdateChallengeProgress(src, citizenid, jobName, 'speed', 1)
    end
end)

-- Called when shift ends
RegisterNetEvent('umeverse_jobs:server:challengeShiftEnd', function(jobName, shiftData)
    local src = source
    if not JobsConfig.DailyChallenges or not JobsConfig.DailyChallenges.enabled then return end
    local citizenid = GetCitizenId(src)
    if not citizenid then return end

    -- Update shift-based challenges
    UpdateChallengeProgress(src, citizenid, jobName, 'shifts', 1)

    -- Update earnings challenges
    if shiftData and shiftData.totalEarned and shiftData.totalEarned > 0 then
        UpdateChallengeProgress(src, citizenid, jobName, 'earnings', shiftData.totalEarned)
    end

    -- Check for perfect vehicle condition
    if shiftData and shiftData.perfectVehicle then
        UpdateChallengeProgress(src, citizenid, jobName, 'perfect', 1)
    end
end)

-- Cleanup on player drop
AddEventHandler('playerDropped', function()
    local src = source
    local citizenid = GetCitizenId(src)
    if citizenid then
        playerChallenges[citizenid] = nil
    end
end)
