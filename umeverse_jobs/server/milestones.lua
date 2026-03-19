-- ═══════════════════════════════════════════════════════════════════
-- Umeverse Jobs - Milestones / Achievements System (Server)
-- ═══════════════════════════════════════════════════════════════════

local UME = exports['umeverse_core']:GetCoreObject()

local playerMilestones = {} -- [citizenid] = { [achievementId_jobName] = true }
local globalStats = {}      -- [citizenid] = { night_shifts, speed_bonuses, perfect_shifts, unique_jobs }

-- ───────────────────────────────────────
-- Helpers
-- ───────────────────────────────────────

local function GetCitizenId(src)
    local player = UME.GetPlayer(src)
    if not player then return nil end
    return player.GetPlayerData().citizenid
end

local function MilestoneKey(achievementId, jobName)
    return achievementId .. '_' .. (jobName or 'global')
end

-- ───────────────────────────────────────
-- DB Operations
-- ───────────────────────────────────────

local function LoadMilestones(citizenid)
    local rows = exports.oxmysql:executeSync(
        'SELECT achievement_id, job_name FROM umeverse_job_milestones WHERE citizenid = ?',
        { citizenid }
    )
    local map = {}
    if rows then
        for _, row in ipairs(rows) do
            map[MilestoneKey(row.achievement_id, row.job_name)] = true
        end
    end
    return map
end

local function SaveMilestone(citizenid, achievementId, jobName)
    exports.oxmysql:execute(
        'INSERT IGNORE INTO umeverse_job_milestones (citizenid, achievement_id, job_name) VALUES (?, ?, ?)',
        { citizenid, achievementId, jobName }
    )
end

local function LoadGlobalStats(citizenid)
    local rows = exports.oxmysql:executeSync(
        'SELECT night_shifts, speed_bonuses, perfect_shifts, unique_jobs FROM umeverse_job_global_stats WHERE citizenid = ?',
        { citizenid }
    )
    if rows and rows[1] then
        local row = rows[1]
        local uniqueJobs = {}
        if row.unique_jobs then
            uniqueJobs = json.decode(row.unique_jobs) or {}
        end
        return {
            night_shifts = row.night_shifts or 0,
            speed_bonuses = row.speed_bonuses or 0,
            perfect_shifts = row.perfect_shifts or 0,
            unique_jobs = uniqueJobs,
        }
    end
    return { night_shifts = 0, speed_bonuses = 0, perfect_shifts = 0, unique_jobs = {} }
end

local function SaveGlobalStats(citizenid)
    local stats = globalStats[citizenid]
    if not stats then return end
    local uniqueJobsJson = json.encode(stats.unique_jobs or {})
    exports.oxmysql:execute(
        'INSERT INTO umeverse_job_global_stats (citizenid, night_shifts, speed_bonuses, perfect_shifts, unique_jobs) VALUES (?, ?, ?, ?, ?) ON DUPLICATE KEY UPDATE night_shifts = ?, speed_bonuses = ?, perfect_shifts = ?, unique_jobs = ?',
        { citizenid, stats.night_shifts, stats.speed_bonuses, stats.perfect_shifts, uniqueJobsJson,
          stats.night_shifts, stats.speed_bonuses, stats.perfect_shifts, uniqueJobsJson }
    )
end

local function EnsureGlobalStats(citizenid)
    if not globalStats[citizenid] then
        globalStats[citizenid] = LoadGlobalStats(citizenid)
    end
    return globalStats[citizenid]
end

local function EnsureMilestones(citizenid)
    if not playerMilestones[citizenid] then
        playerMilestones[citizenid] = LoadMilestones(citizenid)
    end
    return playerMilestones[citizenid]
end

-- ───────────────────────────────────────
-- Check and Award Milestones
-- ───────────────────────────────────────

local function CheckMilestones(src, citizenid, jobName, progressionData)
    if not JobsConfig.Milestones or not JobsConfig.Milestones.enabled then return end

    local milestones = EnsureMilestones(citizenid)
    local gStats = EnsureGlobalStats(citizenid)

    for _, ach in ipairs(JobsConfig.Milestones.achievements) do
        local key = MilestoneKey(ach.id, ach.scope == 'per_job' and jobName or nil)

        -- Skip already unlocked
        if not milestones[key] then
            local current = 0

            if ach.scope == 'per_job' and progressionData then
                if ach.type == 'total_shifts' then
                    current = progressionData.total_shifts or 0
                elseif ach.type == 'total_tasks' then
                    current = progressionData.total_tasks or 0
                elseif ach.type == 'total_earned' then
                    current = progressionData.total_earned or 0
                elseif ach.type == 'streak' then
                    current = progressionData.streak_count or 0
                end
            elseif ach.scope == 'global' then
                if ach.type == 'night_shifts' then
                    current = gStats.night_shifts or 0
                elseif ach.type == 'speed_bonuses' then
                    current = gStats.speed_bonuses or 0
                elseif ach.type == 'perfect_shifts' then
                    current = gStats.perfect_shifts or 0
                elseif ach.type == 'unique_jobs' then
                    current = #(gStats.unique_jobs or {})
                end
            end

            if current >= ach.target then
                -- Unlock!
                milestones[key] = true
                SaveMilestone(citizenid, ach.id, ach.scope == 'per_job' and jobName or nil)

                -- Award rewards
                local player = UME.GetPlayer(src)
                if player then
                    local cashReward = JobsConfig.Milestones.cashReward or 200
                    local xpReward = JobsConfig.Milestones.xpReward or 150
                    player.AddMoney('cash', cashReward, 'milestone-' .. ach.id)
                    TriggerEvent('umeverse_jobs:server:addXP', src, xpReward)
                end

                TriggerClientEvent('umeverse_jobs:client:milestoneUnlocked', src, {
                    id = ach.id,
                    label = ach.label,
                    description = ach.description,
                })
                TriggerClientEvent('umeverse:client:notify', src, '🏅 Achievement Unlocked: ' .. ach.label .. '!', 'success')
            end
        end
    end
end

-- ───────────────────────────────────────
-- Events
-- ───────────────────────────────────────

-- Called after each shift ends to check milestones
RegisterNetEvent('umeverse_jobs:server:checkMilestones', function(jobName, shiftStats)
    local src = source
    if not JobsConfig.Milestones or not JobsConfig.Milestones.enabled then return end

    local citizenid = GetCitizenId(src)
    if not citizenid then return end

    -- Load progression data from DB for per-job checks
    local progRows = exports.oxmysql:executeSync(
        'SELECT total_shifts, total_tasks, total_earned, streak_count FROM umeverse_job_progression WHERE citizenid = ? AND job_name = ?',
        { citizenid, jobName }
    )
    local progressionData = progRows and progRows[1] or {}

    -- Update global stats
    local gStats = EnsureGlobalStats(citizenid)

    if shiftStats then
        if shiftStats.isNight then
            gStats.night_shifts = gStats.night_shifts + 1
        end
        if shiftStats.speedBonusCount then
            gStats.speed_bonuses = gStats.speed_bonuses + shiftStats.speedBonusCount
        end
        if shiftStats.perfectVehicle then
            gStats.perfect_shifts = gStats.perfect_shifts + 1
        end
    end

    -- Track unique jobs
    local found = false
    for _, j in ipairs(gStats.unique_jobs) do
        if j == jobName then found = true; break end
    end
    if not found then
        gStats.unique_jobs[#gStats.unique_jobs + 1] = jobName
    end

    SaveGlobalStats(citizenid)

    -- Run milestone checks
    CheckMilestones(src, citizenid, jobName, progressionData)
end)

-- Get player's unlocked milestones
RegisterNetEvent('umeverse_jobs:server:getMilestones', function()
    local src = source
    local citizenid = GetCitizenId(src)
    if not citizenid then return end

    local milestones = EnsureMilestones(citizenid)
    local gStats = EnsureGlobalStats(citizenid)
    TriggerClientEvent('umeverse_jobs:client:milestonesData', src, milestones, gStats)
end)

-- ───────────────────────────────────────
-- Cleanup
-- ───────────────────────────────────────

AddEventHandler('playerDropped', function()
    local src = source
    local citizenid = GetCitizenId(src)
    if citizenid then
        playerMilestones[citizenid] = nil
        globalStats[citizenid] = nil
    end
end)
