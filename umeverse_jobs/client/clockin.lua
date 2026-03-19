--[[
    Umeverse Jobs - Clock In / Job Menu
    Handles blip creation and clock-in markers for all jobs
]]

-- ═══════════════════════════════════════
-- Setup blips for all job clock-in locations
-- ═══════════════════════════════════════

local clockInBlips = {}

CreateThread(function()
    if not JobsConfig.BlipDisplay then return end

    Wait(2000) -- Let everything initialize

    local blipData = {
        { cfg = JobsConfig.Garbage,    key = 'garbage' },
        { cfg = JobsConfig.Bus,        key = 'bus' },
        { cfg = JobsConfig.Trucker,    key = 'trucker' },
        { cfg = JobsConfig.Fisherman,  key = 'fisherman' },
        { cfg = JobsConfig.Lumberjack, key = 'lumberjack' },
        { cfg = JobsConfig.Miner,      key = 'miner' },
        { cfg = JobsConfig.Tow,        key = 'tow' },
        { cfg = JobsConfig.Pizza,      key = 'pizza' },
        { cfg = JobsConfig.Reporter,   key = 'reporter' },
        { cfg = JobsConfig.Taxi,       key = 'taxi' },
        { cfg = JobsConfig.HeliTour,   key = 'helitour' },
        { cfg = JobsConfig.Postal,     key = 'postal' },
        { cfg = JobsConfig.DockWorker, key = 'dockworker' },
        { cfg = JobsConfig.Train,      key = 'train' },
        { cfg = JobsConfig.Hunter,     key = 'hunter' },
        { cfg = JobsConfig.Farmer,     key = 'farmer' },
        { cfg = JobsConfig.Diver,      key = 'diver' },
        { cfg = JobsConfig.Vineyard,   key = 'vineyard' },
        { cfg = JobsConfig.Electrician,key = 'electrician' },
        { cfg = JobsConfig.Security,   key = 'security' },
    }

    for _, data in ipairs(blipData) do
        local info = JobsConfig.Blips[data.key]
        if info and data.cfg.clockIn then
            local blip = AddBlipForCoord(data.cfg.clockIn.x, data.cfg.clockIn.y, data.cfg.clockIn.z)
            SetBlipSprite(blip, info.sprite)
            SetBlipDisplay(blip, 4)
            SetBlipScale(blip, 0.7)
            SetBlipColour(blip, info.color)
            SetBlipAsShortRange(blip, true)
            BeginTextCommandSetBlipName('STRING')
            AddTextComponentString(info.label)
            EndTextCommandSetBlipName(blip)
            clockInBlips[#clockInBlips + 1] = blip
        end
    end

    -- Spawn boss NPCs at clock-in points
    SpawnBossNPCs()
end)

-- ═══════════════════════════════════════
-- Clock-In marker and interaction thread
-- ═══════════════════════════════════════

local clockInPoints = {
    { job = 'garbage',     pos = JobsConfig.Garbage.clockIn,     label = 'Garbage Collector' },
    { job = 'bus',         pos = JobsConfig.Bus.clockIn,         label = 'Bus Driver' },
    { job = 'trucker',     pos = JobsConfig.Trucker.clockIn,     label = 'Trucker' },
    { job = 'fisherman',   pos = JobsConfig.Fisherman.clockIn,   label = 'Fisherman' },
    { job = 'lumberjack',  pos = JobsConfig.Lumberjack.clockIn,  label = 'Lumberjack' },
    { job = 'miner',       pos = JobsConfig.Miner.clockIn,       label = 'Miner' },
    { job = 'tow',         pos = JobsConfig.Tow.clockIn,         label = 'Tow Truck Driver' },
    { job = 'pizza',       pos = JobsConfig.Pizza.clockIn,       label = 'Pizza Delivery' },
    { job = 'reporter',    pos = JobsConfig.Reporter.clockIn,    label = 'News Reporter' },
    { job = 'taxi',        pos = JobsConfig.Taxi.clockIn,        label = 'Taxi Driver' },
    { job = 'helitour',    pos = JobsConfig.HeliTour.clockIn,    label = 'Helicopter Tour Pilot' },
    { job = 'postal',      pos = JobsConfig.Postal.clockIn,      label = 'Postal Courier' },
    { job = 'dockworker',  pos = JobsConfig.DockWorker.clockIn,  label = 'Dock Worker' },
    { job = 'train',       pos = JobsConfig.Train.clockIn,       label = 'Train Engineer' },
    { job = 'hunter',      pos = JobsConfig.Hunter.clockIn,      label = 'Hunter' },
    { job = 'farmer',      pos = JobsConfig.Farmer.clockIn,      label = 'Farmer' },
    { job = 'diver',       pos = JobsConfig.Diver.clockIn,       label = 'Diver / Salvager' },
    { job = 'vineyard',    pos = JobsConfig.Vineyard.clockIn,    label = 'Vineyard Worker' },
    { job = 'electrician', pos = JobsConfig.Electrician.clockIn, label = 'Electrician' },
    { job = 'security',    pos = JobsConfig.Security.clockIn,    label = 'Security Guard' },
}

CreateThread(function()
    while true do
        local sleep = 1000
        local myPos = GetEntityCoords(PlayerPedId())

        for _, point in ipairs(clockInPoints) do
            local dist = #(myPos - vector3(point.pos.x, point.pos.y, point.pos.z))

            if dist < JobsConfig.MarkerDrawDistance then
                sleep = 0
                DrawJobMarker(1, vector3(point.pos.x, point.pos.y, point.pos.z), 50, 200, 50, 120)

                if dist < JobsConfig.InteractDistance then
                    ShowHelpText('Press ~INPUT_CONTEXT~ to start work as ~y~' .. point.label)

                    if IsControlJustReleased(0, 38) then -- E key
                        if GetActiveJob() then
                            JobNotify('You must end your current shift first!', 'error')
                        else
                            TriggerServerEvent('umeverse_jobs:server:clockIn', point.job)
                        end
                    end
                end
            end
        end

        Wait(sleep)
    end
end)

-- ═══════════════════════════════════════
-- Clock-in confirmation from server
-- ═══════════════════════════════════════

RegisterNetEvent('umeverse_jobs:client:clockedIn', function(jobName)
    SetActiveJob(jobName)
    JobNotify('You have clocked in as ~g~' .. jobName, 'success')

    -- Request progression data to display stats overlay
    if JobsConfig.Progression and JobsConfig.Progression.enabled then
        TriggerServerEvent('umeverse_jobs:server:getProgression', jobName)
    end

    -- Apply job uniform
    ApplyUniform(jobName)

    -- Request daily challenges
    if JobsConfig.DailyChallenges and JobsConfig.DailyChallenges.enabled then
        TriggerServerEvent('umeverse_jobs:server:getChallenges', jobName)
    end

    -- Request prestige data
    if JobsConfig.Prestige and JobsConfig.Prestige.enabled then
        TriggerServerEvent('umeverse_jobs:server:getPrestige', jobName)
    end

    -- Request perks data
    if JobsConfig.Perks and JobsConfig.Perks.enabled then
        TriggerServerEvent('umeverse_jobs:server:getPerks', jobName)
    end

    -- Check for active contract
    if JobsConfig.Contracts and JobsConfig.Contracts.enabled then
        TriggerServerEvent('umeverse_jobs:server:getContract')
    end

    TriggerEvent('umeverse_jobs:client:startJob_' .. jobName)
end)

-- ═══════════════════════════════════════
-- End shift (command or called by job script)
-- ═══════════════════════════════════════

RegisterNetEvent('umeverse_jobs:client:endShift', function()
    local current = GetActiveJob()
    if not current then
        JobNotify('You are not on a shift.', 'error')
        return
    end

    -- Use the enhanced shift summary system
    EndShiftWithSummary(current)
    JobNotify('You have ended your shift.', 'info')
end)

RegisterCommand('endshift', function()
    TriggerEvent('umeverse_jobs:client:endShift')
end, false)

-- ═══════════════════════════════════════
-- Contract Selection Menu (/contract)
-- ═══════════════════════════════════════

RegisterCommand('contract', function()
    if not JobsConfig.Contracts or not JobsConfig.Contracts.enabled then
        JobNotify('Contracts are not enabled.', 'error')
        return
    end

    local currentJob = GetActiveJob()
    if not currentJob then
        JobNotify('You must be on a shift to accept a contract.', 'error')
        return
    end

    -- Check if already has active contract
    local existing = GetActiveContract()
    if existing then
        JobNotify('You already have an active contract! Complete or abandon it first.', 'error')
        return
    end

    -- Display contract selection menu using text + keys
    local contracts = JobsConfig.Contracts.contracts
    if not contracts or #contracts == 0 then return end

    local selected = 1

    CreateThread(function()
        local choosing = true
        while choosing do
            -- Draw menu background
            DrawRect(0.5, 0.5, 0.35, 0.25, 0, 0, 0, 200)
            DrawScreenText(0.35, 0.40, 0.38, '~y~SELECT CONTRACT', 255, 215, 0, 255)

            for i, c in ipairs(contracts) do
                local prefix = i == selected and '~g~> ' or '~w~  '
                local y = 0.44 + (i * 0.03)
                DrawScreenText(0.35, y, 0.28, prefix .. c.label .. ' ~w~(' .. c.tasks .. ' tasks, ' .. c.timeLimitMins .. ' min) +' .. c.payBonus .. '% pay', 200, 200, 200, 220)
            end

            DrawScreenText(0.35, 0.44 + ((#contracts + 1) * 0.03), 0.22, '~w~UP/DOWN to select, ENTER to accept, BACKSPACE to cancel', 150, 150, 150, 160)

            -- Handle input
            DisableControlAction(0, 200, true) -- ESC
            if IsControlJustReleased(0, 172) then -- UP
                selected = selected - 1
                if selected < 1 then selected = #contracts end
            elseif IsControlJustReleased(0, 173) then -- DOWN
                selected = selected + 1
                if selected > #contracts then selected = 1 end
            elseif IsControlJustReleased(0, 191) then -- ENTER
                TriggerServerEvent('umeverse_jobs:server:acceptContract', currentJob, contracts[selected].id)
                choosing = false
            elseif IsControlJustReleased(0, 194) or IsControlJustReleased(0, 177) then -- BACKSPACE / ESC
                choosing = false
            end

            Wait(0)
        end
    end)
end, false)

-- Abandon active contract
RegisterCommand('abandoncontract', function()
    if not GetActiveContract() then
        JobNotify('You have no active contract.', 'error')
        return
    end
    TriggerServerEvent('umeverse_jobs:server:abandonContract')
end, false)

-- ═══════════════════════════════════════
-- Leaderboard Command (/leaderboard)
-- ═══════════════════════════════════════

RegisterCommand('leaderboard', function()
    if not JobsConfig.Leaderboard or not JobsConfig.Leaderboard.enabled then
        JobNotify('Leaderboard is not enabled.', 'error')
        return
    end
    TriggerServerEvent('umeverse_jobs:server:getFullLeaderboard')
end, false)

-- ═══════════════════════════════════════
-- Prestige Command (/prestige)
-- ═══════════════════════════════════════

RegisterCommand('prestige', function()
    if not JobsConfig.Prestige or not JobsConfig.Prestige.enabled then
        JobNotify('Prestige system is not enabled.', 'error')
        return
    end

    local currentJob = GetActiveJob()
    if not currentJob then
        -- Use player's actual job
        local jobData = GetJobData()
        if jobData then
            currentJob = jobData.name
        end
    end

    if not currentJob then
        JobNotify('You need a job to prestige.', 'error')
        return
    end

    TriggerServerEvent('umeverse_jobs:server:prestige', currentJob)
end, false)

-- ═══════════════════════════════════════
-- Mentorship Command (/mentor)
-- ═══════════════════════════════════════

RegisterCommand('mentor', function()
    if not JobsConfig.Mentorship or not JobsConfig.Mentorship.enabled then
        JobNotify('Mentorship system is not enabled.', 'error')
        return
    end

    if not GetActiveJob() then
        JobNotify('You must be on a shift to request a mentor.', 'error')
        return
    end

    TriggerServerEvent('umeverse_jobs:server:requestMentor')
end, false)

-- ═══════════════════════════════════════
-- Perks Display (from server response)
-- ═══════════════════════════════════════

RegisterNetEvent('umeverse_jobs:client:perksData', function(unlockedPerks, fullTree)
    if not fullTree or #fullTree == 0 then return end

    CreateThread(function()
        local endTime = GetGameTimer() + 8000
        while GetGameTimer() < endTime do
            DrawRect(0.5, 0.50, 0.35, 0.25, 0, 0, 0, 200)
            DrawScreenText(0.35, 0.40, 0.35, '~y~SKILL TREE', 255, 215, 0, 255)

            for i, perk in ipairs(fullTree) do
                local unlocked = false
                for _, up in ipairs(unlockedPerks) do
                    if up.id == perk.id then unlocked = true break end
                end
                local prefix = unlocked and '~g~✓ ' or '~r~✗ '
                local y = 0.43 + (i * 0.025)
                DrawScreenText(0.35, y, 0.25, prefix .. perk.label .. ' ~w~- ' .. perk.description .. ' (XP: ' .. perk.xpRequired .. ')', 200, 200, 200, 200)
            end

            Wait(0)
        end
    end)
end)

-- ═══════════════════════════════════════
-- Market Info Display (from server response)
-- ═══════════════════════════════════════

RegisterNetEvent('umeverse_jobs:client:marketInfo', function(info)
    if not info then return end

    CreateThread(function()
        local endTime = GetGameTimer() + 8000
        while GetGameTimer() < endTime do
            DrawRect(0.5, 0.50, 0.4, 0.35, 0, 0, 0, 200)
            DrawScreenText(0.32, 0.36, 0.35, '~y~JOB MARKET', 255, 215, 0, 255)

            local y = 0.39
            for jobName, data in pairs(info) do
                local multStr = string.format('%.0f%%', data.mult * 100)
                local label = data.label ~= '' and data.label or '~w~Normal'
                DrawScreenText(0.32, y, 0.22, '~w~' .. jobName .. ': ' .. label .. ' ~w~(' .. multStr .. ') [' .. data.players .. ' workers]', 200, 200, 200, 180)
                y = y + 0.02
            end

            Wait(0)
        end
    end)
end)

-- View job market
RegisterCommand('jobmarket', function()
    if not JobsConfig.DynamicPay or not JobsConfig.DynamicPay.enabled then
        JobNotify('Dynamic pay market is not enabled.', 'error')
        return
    end
    TriggerServerEvent('umeverse_jobs:server:getMarketInfo')
end, false)

-- ═══════════════════════════════════════
-- Resource Cleanup: Despawn boss NPCs on stop
-- ═══════════════════════════════════════

AddEventHandler('onResourceStop', function(resource)
    if resource == GetCurrentResourceName() then
        DespawnBossNPCs()
        RestoreOutfit()
    end
end)
