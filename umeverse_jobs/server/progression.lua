--[[
    Umeverse Jobs - Server Progression
    XP tracking, grade promotion, streak system, and bonus payments
    Persists data in the umeverse_job_progression table via oxmysql
]]

local UME = exports['umeverse_core']:GetCoreObject()

-- ═══════════════════════════════════════
-- In-Memory Cache
-- ═══════════════════════════════════════
-- Keyed by citizenid → { [jobName] = { xp, streak, lastShift, totalShifts, totalEarned } }
local progressionCache = {}

-- ═══════════════════════════════════════
-- Database Helpers
-- ═══════════════════════════════════════

local function GetCitizenId(src)
    local player = UME.GetPlayer(src)
    if not player then return nil end
    local pd = player:GetPlayerData()
    if pd and pd.citizenid then return pd.citizenid end
    return nil
end

--- Load progression data for a player from DB
local function LoadProgression(citizenid)
    if progressionCache[citizenid] then return end

    local rows = exports.oxmysql:executeSync('SELECT * FROM umeverse_job_progression WHERE citizenid = ?', { citizenid })
    progressionCache[citizenid] = {}

    if rows then
        for _, row in ipairs(rows) do
            progressionCache[citizenid][row.job_name] = {
                xp          = row.xp or 0,
                streak      = row.streak_count or 0,
                lastShift   = row.last_shift_time or 0,
                totalShifts = row.total_shifts or 0,
                totalEarned = row.total_earned or 0,
            }
        end
    end
end

--- Save a single job's progression data
local function SaveProgression(citizenid, jobName)
    if not progressionCache[citizenid] or not progressionCache[citizenid][jobName] then return end
    local data = progressionCache[citizenid][jobName]

    exports.oxmysql:execute([[
        INSERT INTO umeverse_job_progression (citizenid, job_name, xp, streak_count, last_shift_time, total_shifts, total_earned)
        VALUES (?, ?, ?, ?, ?, ?, ?)
        ON DUPLICATE KEY UPDATE
            xp = VALUES(xp),
            streak_count = VALUES(streak_count),
            last_shift_time = VALUES(last_shift_time),
            total_shifts = VALUES(total_shifts),
            total_earned = VALUES(total_earned)
    ]], { citizenid, jobName, data.xp, data.streak, data.lastShift, data.totalShifts, data.totalEarned })
end

--- Ensure cache entry exists for a job
local function EnsureJobEntry(citizenid, jobName)
    if not progressionCache[citizenid] then progressionCache[citizenid] = {} end
    if not progressionCache[citizenid][jobName] then
        progressionCache[citizenid][jobName] = {
            xp = 0, streak = 0, lastShift = 0, totalShifts = 0, totalEarned = 0,
        }
    end
end

-- ═══════════════════════════════════════
-- Streak Calculation
-- ═══════════════════════════════════════

--- Get streak multiplier for pay and XP
---@param streak number
---@return number payMult
---@return number xpMult
---@return string label
local function GetStreakMultipliers(streak)
    if not JobsConfig.Streaks or not JobsConfig.Streaks.enabled then
        return 1.0, 1.0, ''
    end

    local payMult, xpMult, label = 1.0, 1.0, ''
    for _, tier in ipairs(JobsConfig.Streaks.tiers) do
        if streak >= tier.minStreak then
            payMult = tier.payMult
            xpMult  = tier.xpMult
            label   = tier.label
        end
    end
    return payMult, xpMult, label
end

--- Increment streak or reset if expired
local function UpdateStreak(citizenid, jobName)
    local data = progressionCache[citizenid][jobName]
    local now = os.time()

    if data.lastShift > 0 then
        local elapsed = (now - data.lastShift) / 60 -- minutes
        if elapsed > (JobsConfig.Streaks.resetAfterMinutes or 120) then
            data.streak = 1 -- Reset
        else
            data.streak = data.streak + 1
        end
    else
        data.streak = 1
    end

    data.lastShift = now
    data.totalShifts = data.totalShifts + 1
end

-- ═══════════════════════════════════════
-- XP & Grade Promotion
-- ═══════════════════════════════════════

--- Add XP to a player's job, check for promotion
---@param src number
---@param xpAmount number
local function AddXP(src, xpAmount)
    if not JobsConfig.Progression or not JobsConfig.Progression.enabled then return end

    local citizenid = GetCitizenId(src)
    if not citizenid then return end

    local player = UME.GetPlayer(src)
    if not player then return end

    local job = player:GetJob()
    if not job or not job.name then return end
    local jobName = job.name

    LoadProgression(citizenid)
    EnsureJobEntry(citizenid, jobName)

    -- Apply streak XP multiplier
    local _, xpMult = GetStreakMultipliers(progressionCache[citizenid][jobName].streak)
    local finalXP = math.floor(xpAmount * xpMult)

    progressionCache[citizenid][jobName].xp = progressionCache[citizenid][jobName].xp + finalXP

    -- Check for auto-promotion
    if JobsConfig.Progression.autoPromote then
        local currentGrade = job.grade or 0
        local xpThresholds = JobsConfig.Progression.xpPerGrade
        local totalXP = progressionCache[citizenid][jobName].xp

        -- Calculate cumulative XP for next grade
        local cumulativeNeeded = 0
        for i = 1, currentGrade + 1 do
            cumulativeNeeded = cumulativeNeeded + (xpThresholds[i] or 0)
        end

        if currentGrade < #xpThresholds and totalXP >= cumulativeNeeded then
            local newGrade = currentGrade + 1
            player:SetJob(jobName, newGrade)
            TriggerClientEvent('umeverse:client:notify', src, '~g~PROMOTED! ~w~You are now Grade ' .. newGrade .. '!', 'success')
            TriggerClientEvent('umeverse_jobs:client:promoted', src, jobName, newGrade)
        end
    end

    SaveProgression(citizenid, jobName)
end

-- ═══════════════════════════════════════
-- Server Events
-- ═══════════════════════════════════════

-- Add XP (called from client after each task)
RegisterNetEvent('umeverse_jobs:server:addXP', function(xpAmount)
    local src = source
    -- Sanitize input
    if type(xpAmount) ~= 'number' or xpAmount <= 0 or xpAmount > 500 then return end
    AddXP(src, math.floor(xpAmount))
end)

-- Bonus cash payment (random events, rush orders, etc.)
RegisterNetEvent('umeverse_jobs:server:bonusPay', function(amount, reason)
    local src = source
    if type(amount) ~= 'number' or amount <= 0 or amount > 5000 then return end
    if type(reason) ~= 'string' then reason = 'Job Bonus' end

    local player = UME.GetPlayer(src)
    if not player then return end

    local job = player:GetJob()
    if not job or not job.name then return end

    -- Apply streak pay multiplier
    local citizenid = GetCitizenId(src)
    if citizenid then
        LoadProgression(citizenid)
        EnsureJobEntry(citizenid, job.name)
        local payMult = GetStreakMultipliers(progressionCache[citizenid][job.name].streak)
        amount = math.floor(amount * payMult)
    end

    player:AddMoney('cash', amount, reason)
end)

-- Bonus item (random event: lost & found)
RegisterNetEvent('umeverse_jobs:server:bonusItem', function(itemName, count)
    local src = source
    if type(itemName) ~= 'string' or type(count) ~= 'number' then return end
    if count <= 0 or count > 5 then return end

    -- Whitelist check: only items from the random events config
    local allowed = false
    if JobsConfig.RandomEvents and JobsConfig.RandomEvents.events then
        for _, event in ipairs(JobsConfig.RandomEvents.events) do
            if event.type == 'bonus_item' and event.items then
                for _, itm in ipairs(event.items) do
                    if itm.item == itemName then allowed = true break end
                end
            end
            if allowed then break end
        end
    end
    if not allowed then return end

    local player = UME.GetPlayer(src)
    if not player then return end
    player:AddItem(itemName, count)
end)

-- End of shift: apply bonuses and record stats
RegisterNetEvent('umeverse_jobs:server:endShift', function(summary)
    local src = source
    if type(summary) ~= 'table' then return end

    local player = UME.GetPlayer(src)
    if not player then return end

    local job = player:GetJob()
    if not job or not job.name then return end

    local citizenid = GetCitizenId(src)
    if not citizenid then return end

    LoadProgression(citizenid)
    EnsureJobEntry(citizenid, job.name)

    -- Update streak
    if JobsConfig.Streaks and JobsConfig.Streaks.enabled then
        UpdateStreak(citizenid, job.name)
    end

    -- Pay out end-of-shift bonus (vehicle condition, speed, weather)
    local totalBonus = summary.totalBonus or 0
    if totalBonus > 0 and totalBonus < 50000 then -- Sanity cap
        player:AddMoney('cash', totalBonus, 'Shift Bonuses')
    end

    -- Track earnings
    progressionCache[citizenid][job.name].totalEarned =
        progressionCache[citizenid][job.name].totalEarned + (summary.grandTotal or 0)

    SaveProgression(citizenid, job.name)

    -- Send streak info back to client for display
    local streak = progressionCache[citizenid][job.name].streak
    local payMult, xpMult, streakLabel = GetStreakMultipliers(streak)
    TriggerClientEvent('umeverse_jobs:client:streakUpdate', src, streak, payMult, xpMult, streakLabel)
end)

-- Client requests progression data (for display on clock-in)
RegisterNetEvent('umeverse_jobs:server:getProgression', function(jobName)
    local src = source
    if type(jobName) ~= 'string' then return end

    local citizenid = GetCitizenId(src)
    if not citizenid then return end

    LoadProgression(citizenid)
    EnsureJobEntry(citizenid, jobName)

    local data = progressionCache[citizenid][jobName]
    local player = UME.GetPlayer(src)
    local currentGrade = 0
    if player then
        local job = player:GetJob()
        if job then currentGrade = job.grade or 0 end
    end

    -- Calculate XP to next grade
    local xpThresholds = JobsConfig.Progression.xpPerGrade or {}
    local cumulativeNeeded = 0
    for i = 1, currentGrade + 1 do
        cumulativeNeeded = cumulativeNeeded + (xpThresholds[i] or 0)
    end
    local xpToNext = math.max(0, cumulativeNeeded - data.xp)

    -- Streak info
    local streak = data.streak
    local now = os.time()
    if data.lastShift > 0 then
        local elapsed = (now - data.lastShift) / 60
        if elapsed > (JobsConfig.Streaks.resetAfterMinutes or 120) then
            streak = 0
        end
    end
    local payMult, xpMult, streakLabel = GetStreakMultipliers(streak)

    TriggerClientEvent('umeverse_jobs:client:progressionData', src, {
        xp          = data.xp,
        xpToNext    = xpToNext,
        grade       = currentGrade,
        maxGrade    = #xpThresholds,
        streak      = streak,
        payMult     = payMult,
        xpMult      = xpMult,
        streakLabel = streakLabel,
        totalShifts = data.totalShifts,
        totalEarned = data.totalEarned,
    })
end)

-- ═══════════════════════════════════════
-- Load progression on player join
-- ═══════════════════════════════════════

RegisterNetEvent('umeverse:server:playerLoaded', function()
    local src = source
    local citizenid = GetCitizenId(src)
    if citizenid then
        LoadProgression(citizenid)
    end
end)

-- Clean cache on drop
AddEventHandler('playerDropped', function()
    local src = source
    local citizenid = GetCitizenId(src)
    if citizenid and progressionCache[citizenid] then
        -- Save all before clearing
        for jobName in pairs(progressionCache[citizenid]) do
            SaveProgression(citizenid, jobName)
        end
        progressionCache[citizenid] = nil
    end
    -- Clean mentorship cache
    activeMentorships[src] = nil
    for mentor, mentees in pairs(activeMentorships) do
        for i = #mentees, 1, -1 do
            if mentees[i] == src then table.remove(mentees, i) end
        end
    end
end)

-- ═══════════════════════════════════════
-- Prestige System
-- ═══════════════════════════════════════

local prestigeCache = {} -- [citizenid][jobName] = prestige level

local function LoadPrestige(citizenid)
    if prestigeCache[citizenid] then return end
    prestigeCache[citizenid] = {}
    local rows = exports.oxmysql:executeSync(
        'SELECT job_name, prestige FROM umeverse_job_progression WHERE citizenid = ?',
        { citizenid }
    )
    if rows then
        for _, row in ipairs(rows) do
            prestigeCache[citizenid][row.job_name] = row.prestige or 0
        end
    end
end

local function GetPrestige(citizenid, jobName)
    if not prestigeCache[citizenid] then LoadPrestige(citizenid) end
    return (prestigeCache[citizenid] and prestigeCache[citizenid][jobName]) or 0
end

function GetPrestigePayMultiplier(citizenid, jobName)
    if not JobsConfig.Prestige or not JobsConfig.Prestige.enabled then return 1.0 end
    local level = GetPrestige(citizenid, jobName)
    return 1.0 + (level * (JobsConfig.Prestige.payBonusPerLevel or 5) / 100)
end

function GetPrestigeXPMultiplier(citizenid, jobName)
    if not JobsConfig.Prestige or not JobsConfig.Prestige.enabled then return 1.0 end
    local level = GetPrestige(citizenid, jobName)
    return 1.0 + (level * (JobsConfig.Prestige.xpBonusPerLevel or 10) / 100)
end

exports('GetPrestigePayMultiplier', function(citizenid, jobName) return GetPrestigePayMultiplier(citizenid, jobName) end)
exports('GetPrestigeXPMultiplier', function(citizenid, jobName) return GetPrestigeXPMultiplier(citizenid, jobName) end)

-- Prestige request
RegisterNetEvent('umeverse_jobs:server:prestige', function(jobName)
    local src = source
    if not JobsConfig.Prestige or not JobsConfig.Prestige.enabled then return end
    if type(jobName) ~= 'string' then return end

    local citizenid = GetCitizenId(src)
    if not citizenid then return end
    local player = UME.GetPlayer(src)
    if not player then return end

    local job = player:GetJob()
    if not job or job.name ~= jobName then return end

    -- Must be at max grade
    local maxGrade = #(JobsConfig.Progression.xpPerGrade or {})
    if (job.grade or 0) < maxGrade then
        TriggerClientEvent('umeverse:client:notify', src, 'You must be at max grade to prestige!', 'error')
        return
    end

    LoadPrestige(citizenid)
    local currentPrestige = GetPrestige(citizenid, jobName)
    local maxPrestige = JobsConfig.Prestige.maxPrestige or 3

    if currentPrestige >= maxPrestige then
        TriggerClientEvent('umeverse:client:notify', src, 'You are already at max prestige!', 'error')
        return
    end

    -- Check cash cost
    local costs = JobsConfig.Prestige.cashCost or {}
    local cost = costs[currentPrestige + 1] or 0
    if cost > 0 then
        local playerData = player:GetPlayerData()
        local cash = playerData.money and playerData.money.cash or 0
        if cash < cost then
            TriggerClientEvent('umeverse:client:notify', src, 'You need $' .. cost .. ' to prestige!', 'error')
            return
        end
        player:RemoveMoney('cash', cost, 'prestige-' .. jobName)
    end

    -- Apply prestige: reset grade to 0 and XP to 0
    local newPrestige = currentPrestige + 1
    prestigeCache[citizenid][jobName] = newPrestige

    -- Reset progression
    LoadProgression(citizenid)
    EnsureJobEntry(citizenid, jobName)
    progressionCache[citizenid][jobName].xp = 0
    SaveProgression(citizenid, jobName)

    -- Save prestige
    exports.oxmysql:execute(
        'UPDATE umeverse_job_progression SET prestige = ?, xp = 0 WHERE citizenid = ? AND job_name = ?',
        { newPrestige, citizenid, jobName }
    )

    -- Reset grade in-game
    player:SetJob(jobName, 0)

    local prestigeInfo = JobsConfig.Prestige.levels[newPrestige]
    local pLabel = prestigeInfo and prestigeInfo.name or ('Prestige ' .. newPrestige)

    TriggerClientEvent('umeverse:client:notify', src, '🌟 PRESTIGE! You are now ' .. pLabel .. '! Grade reset, permanent bonuses active!', 'success')
    TriggerClientEvent('umeverse_jobs:client:prestiged', src, jobName, newPrestige)
end)

-- Get prestige info for client
RegisterNetEvent('umeverse_jobs:server:getPrestige', function(jobName)
    local src = source
    if not JobsConfig.Prestige or not JobsConfig.Prestige.enabled then return end
    local citizenid = GetCitizenId(src)
    if not citizenid then return end

    LoadPrestige(citizenid)
    local level = GetPrestige(citizenid, jobName)
    TriggerClientEvent('umeverse_jobs:client:prestigeData', src, jobName, level)
end)

-- ═══════════════════════════════════════
-- Task Tracking (for milestones & challenges)
-- ═══════════════════════════════════════

RegisterNetEvent('umeverse_jobs:server:taskCompleted', function(jobName, extraData)
    local src = source
    if type(jobName) ~= 'string' then return end

    local citizenid = GetCitizenId(src)
    if not citizenid then return end

    LoadProgression(citizenid)
    EnsureJobEntry(citizenid, jobName)
    progressionCache[citizenid][jobName].totalTasks = (progressionCache[citizenid][jobName].totalTasks or 0) + 1

    -- Update DB total_tasks column
    exports.oxmysql:execute(
        'UPDATE umeverse_job_progression SET total_tasks = total_tasks + 1 WHERE citizenid = ? AND job_name = ?',
        { citizenid, jobName }
    )

    -- Forward to challenges
    TriggerEvent('umeverse_jobs:server:challengeTaskDone', jobName, extraData)

    -- Forward to contracts
    TriggerEvent('umeverse_jobs:server:contractTaskDone', jobName)

    SaveProgression(citizenid, jobName)
end)

-- ═══════════════════════════════════════
-- Mentorship System
-- ═══════════════════════════════════════

activeMentorships = {} -- [mentorSrc] = { menteeSrcs }

RegisterNetEvent('umeverse_jobs:server:requestMentor', function()
    local src = source
    if not JobsConfig.Mentorship or not JobsConfig.Mentorship.enabled then return end

    local player = UME.GetPlayer(src)
    if not player then return end
    local job = player:GetJob()
    if not job or not job.name then return end
    local jobName = job.name

    -- Find a nearby mentor
    local myPed = GetPlayerPed(src)
    local myCoords = GetEntityCoords(myPed)
    local players = UME.GetPlayers()
    local nearbyDist = JobsConfig.Mentorship.nearbyDistance or 150.0
    local minGrade = JobsConfig.Mentorship.mentorMinGrade or 3

    for _, otherSrc in ipairs(players) do
        if otherSrc ~= src then
            local otherPlayer = UME.GetPlayer(otherSrc)
            if otherPlayer then
                local otherJob = otherPlayer:GetJob()
                if otherJob and otherJob.name == jobName and (otherJob.grade or 0) >= minGrade then
                    local otherPed = GetPlayerPed(otherSrc)
                    local otherCoords = GetEntityCoords(otherPed)
                    local dist = #(myCoords - otherCoords)

                    if dist <= nearbyDist then
                        -- Check max mentees
                        if not activeMentorships[otherSrc] then activeMentorships[otherSrc] = {} end
                        local maxMentees = JobsConfig.Mentorship.maxMentees or 2
                        if #activeMentorships[otherSrc] < maxMentees then
                            -- Check not already mentored
                            local already = false
                            for _, m in ipairs(activeMentorships[otherSrc]) do
                                if m == src then already = true break end
                            end
                            if not already then
                                activeMentorships[otherSrc][#activeMentorships[otherSrc] + 1] = src
                                TriggerClientEvent('umeverse:client:notify', src, '👨‍🏫 You are now being mentored! Bonus pay & XP!', 'success')
                                TriggerClientEvent('umeverse:client:notify', otherSrc, '👨‍🏫 You are now mentoring a colleague! Bonus pay & XP!', 'success')
                                TriggerClientEvent('umeverse_jobs:client:mentorshipStarted', src, otherSrc, true)
                                TriggerClientEvent('umeverse_jobs:client:mentorshipStarted', otherSrc, src, false)
                                return
                            end
                        end
                    end
                end
            end
        end
    end

    TriggerClientEvent('umeverse:client:notify', src, 'No available mentor nearby.', 'error')
end)

--- Get mentorship pay multiplier for a source
function GetMentorshipPayMultiplier(src)
    if not JobsConfig.Mentorship or not JobsConfig.Mentorship.enabled then return 1.0 end

    -- Check if they are a mentor with active mentees
    if activeMentorships[src] and #activeMentorships[src] > 0 then
        return 1.0 + (JobsConfig.Mentorship.mentorPayBonus or 15) / 100
    end

    -- Check if they are a mentee
    for mentorSrc, mentees in pairs(activeMentorships) do
        for _, menteeSrc in ipairs(mentees) do
            if menteeSrc == src then
                return 1.0 + (JobsConfig.Mentorship.mentorPayBonus or 15) / 100
            end
        end
    end

    return 1.0
end

function GetMentorshipXPMultiplier(src)
    if not JobsConfig.Mentorship or not JobsConfig.Mentorship.enabled then return 1.0 end

    if activeMentorships[src] and #activeMentorships[src] > 0 then
        return 1.0 + (JobsConfig.Mentorship.mentorXPBonus or 25) / 100
    end

    for mentorSrc, mentees in pairs(activeMentorships) do
        for _, menteeSrc in ipairs(mentees) do
            if menteeSrc == src then
                return 1.0 + (JobsConfig.Mentorship.mentorXPBonus or 25) / 100
            end
        end
    end

    return 1.0
end

exports('GetMentorshipPayMultiplier', function(src) return GetMentorshipPayMultiplier(src) end)
exports('GetMentorshipXPMultiplier', function(src) return GetMentorshipXPMultiplier(src) end)

-- ═══════════════════════════════════════
-- Co-op Bonuses
-- ═══════════════════════════════════════

--- Count nearby players working the same job
function GetCoOpInfo(src)
    if not JobsConfig.CoOp or not JobsConfig.CoOp.enabled then return 0, 1.0, 1.0 end

    local player = UME.GetPlayer(src)
    if not player then return 0, 1.0, 1.0 end
    local job = player:GetJob()
    if not job or not job.name then return 0, 1.0, 1.0 end

    local myPed = GetPlayerPed(src)
    local myCoords = GetEntityCoords(myPed)
    local nearbyDist = JobsConfig.CoOp.nearbyDistance or 100.0
    local maxPartners = JobsConfig.CoOp.maxPartners or 3
    local bonusPer = JobsConfig.CoOp.bonusPerPartner or 10
    local xpPer = JobsConfig.CoOp.xpBonusPerPartner or 5

    local partnerCount = 0
    local players = UME.GetPlayers()

    for _, otherSrc in ipairs(players) do
        if otherSrc ~= src then
            local otherPlayer = UME.GetPlayer(otherSrc)
            if otherPlayer then
                local otherJob = otherPlayer:GetJob()
                if otherJob and otherJob.name == job.name and otherJob.onduty then
                    local otherPed = GetPlayerPed(otherSrc)
                    local otherCoords = GetEntityCoords(otherPed)
                    if #(myCoords - otherCoords) <= nearbyDist then
                        partnerCount = partnerCount + 1
                        if partnerCount >= maxPartners then break end
                    end
                end
            end
        end
    end

    local payMult = 1.0 + (partnerCount * bonusPer / 100)
    local xpMult = 1.0 + (partnerCount * xpPer / 100)
    return partnerCount, payMult, xpMult
end

exports('GetCoOpInfo', function(src) return GetCoOpInfo(src) end)

-- ═══════════════════════════════════════
-- Perks Lookup
-- ═══════════════════════════════════════

--- Get unlocked perks for a player's job based on their XP
function GetUnlockedPerks(src, jobName)
    if not JobsConfig.Perks or not JobsConfig.Perks.enabled then return {} end
    if not jobName then return {} end

    local citizenid = GetCitizenId(src)
    if not citizenid then return {} end

    LoadProgression(citizenid)
    EnsureJobEntry(citizenid, jobName)

    local xp = progressionCache[citizenid][jobName].xp
    local tree = JobsConfig.Perks.trees[jobName]
    if not tree then return {} end

    local unlocked = {}
    for _, perk in ipairs(tree) do
        if xp >= perk.xpRequired then
            unlocked[#unlocked + 1] = perk
        end
    end
    return unlocked
end

--- Get the total pay bonus from perks
function GetPerkPayBonus(src, jobName)
    local perks = GetUnlockedPerks(src, jobName)
    local bonus = 0
    for _, perk in ipairs(perks) do
        if perk.effect == 'pay_bonus' then
            bonus = bonus + perk.value
        end
    end
    return bonus
end

--- Get the total XP bonus from perks
function GetPerkXPBonus(src, jobName)
    local perks = GetUnlockedPerks(src, jobName)
    local bonus = 0
    for _, perk in ipairs(perks) do
        if perk.effect == 'xp_bonus' then
            bonus = bonus + perk.value
        end
    end
    return bonus
end

exports('GetUnlockedPerks', function(src, jobName) return GetUnlockedPerks(src, jobName) end)
exports('GetPerkPayBonus', function(src, jobName) return GetPerkPayBonus(src, jobName) end)
exports('GetPerkXPBonus', function(src, jobName) return GetPerkXPBonus(src, jobName) end)

-- Client requests perk data
RegisterNetEvent('umeverse_jobs:server:getPerks', function(jobName)
    local src = source
    if not JobsConfig.Perks or not JobsConfig.Perks.enabled then return end
    local perks = GetUnlockedPerks(src, jobName)
    local tree = JobsConfig.Perks.trees[jobName] or {}
    TriggerClientEvent('umeverse_jobs:client:perksData', src, perks, tree)
end)
