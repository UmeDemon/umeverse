-- ═══════════════════════════════════════════════════════════════════
-- Umeverse Jobs - Leaderboard System (Server)
-- ═══════════════════════════════════════════════════════════════════

local UME = exports['umeverse_core']:GetCoreObject()

local cachedLeaderboards = {} -- [category] = { entries }
local lastRefresh = 0
local REFRESH_INTERVAL = 60 -- seconds

-- ───────────────────────────────────────
-- Build Leaderboard Queries
-- ───────────────────────────────────────

local function RefreshLeaderboards()
    if not JobsConfig.Leaderboard or not JobsConfig.Leaderboard.enabled then return end
    local topN = JobsConfig.Leaderboard.topN or 10

    -- Top Earners (aggregated across all jobs)
    local earners = exports.oxmysql:executeSync(
        'SELECT citizenid, SUM(total_earned) as total FROM umeverse_job_progression GROUP BY citizenid ORDER BY total DESC LIMIT ?',
        { topN }
    )
    cachedLeaderboards['total_earned'] = earners or {}

    -- Most Dedicated (total shifts across all jobs)
    local dedicated = exports.oxmysql:executeSync(
        'SELECT citizenid, SUM(total_shifts) as total FROM umeverse_job_progression GROUP BY citizenid ORDER BY total DESC LIMIT ?',
        { topN }
    )
    cachedLeaderboards['total_shifts'] = dedicated or {}

    -- Most Productive (total tasks across all jobs)
    local productive = exports.oxmysql:executeSync(
        'SELECT citizenid, SUM(total_tasks) as total FROM umeverse_job_progression GROUP BY citizenid ORDER BY total DESC LIMIT ?',
        { topN }
    )
    cachedLeaderboards['total_tasks'] = productive or {}

    -- Highest Streak (best across any single job)
    local streaks = exports.oxmysql:executeSync(
        'SELECT citizenid, MAX(streak_count) as total FROM umeverse_job_progression GROUP BY citizenid ORDER BY total DESC LIMIT ?',
        { topN }
    )
    cachedLeaderboards['highest_streak'] = streaks or {}

    lastRefresh = os.time()
end

-- ───────────────────────────────────────
-- Resolve Citizen IDs to Names
-- ───────────────────────────────────────

local function ResolveName(citizenid)
    local rows = exports.oxmysql:executeSync(
        'SELECT charinfo FROM umeverse_players WHERE citizenid = ? LIMIT 1',
        { citizenid }
    )
    if rows and rows[1] and rows[1].charinfo then
        local info = json.decode(rows[1].charinfo)
        if info then
            return (info.firstname or '?') .. ' ' .. (info.lastname or '?')
        end
    end
    return 'Unknown'
end

-- ───────────────────────────────────────
-- Events
-- ───────────────────────────────────────

RegisterNetEvent('umeverse_jobs:server:getLeaderboard', function(category)
    local src = source
    if not JobsConfig.Leaderboard or not JobsConfig.Leaderboard.enabled then return end

    -- Refresh if stale
    if os.time() - lastRefresh > REFRESH_INTERVAL then
        RefreshLeaderboards()
    end

    local data = cachedLeaderboards[category]
    if not data then
        TriggerClientEvent('umeverse_jobs:client:leaderboardData', src, category, {})
        return
    end

    -- Resolve names
    local resolved = {}
    for i, entry in ipairs(data) do
        resolved[i] = {
            rank = i,
            name = ResolveName(entry.citizenid),
            value = entry.total or 0,
        }
    end

    TriggerClientEvent('umeverse_jobs:client:leaderboardData', src, category, resolved)
end)

-- Get all categories at once
RegisterNetEvent('umeverse_jobs:server:getFullLeaderboard', function()
    local src = source
    if not JobsConfig.Leaderboard or not JobsConfig.Leaderboard.enabled then return end

    if os.time() - lastRefresh > REFRESH_INTERVAL then
        RefreshLeaderboards()
    end

    local allData = {}
    for _, cat in ipairs(JobsConfig.Leaderboard.categories) do
        local data = cachedLeaderboards[cat.id]
        local resolved = {}
        if data then
            for i, entry in ipairs(data) do
                resolved[i] = {
                    rank = i,
                    name = ResolveName(entry.citizenid),
                    value = entry.total or 0,
                }
            end
        end
        allData[cat.id] = { label = cat.label, entries = resolved }
    end

    TriggerClientEvent('umeverse_jobs:client:fullLeaderboardData', src, allData)
end)

-- Initial refresh on resource start
CreateThread(function()
    Wait(5000) -- Wait for oxmysql to be ready
    RefreshLeaderboards()
end)
