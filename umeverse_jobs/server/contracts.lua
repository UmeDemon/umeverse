-- ═══════════════════════════════════════════════════════════════════
-- Umeverse Jobs - Contract System (Server)
-- ═══════════════════════════════════════════════════════════════════

local UME = exports['umeverse_core']:GetCoreObject()

local activeContracts = {} -- [src] = { contractData }

-- ───────────────────────────────────────
-- Helpers
-- ───────────────────────────────────────

local function GetCitizenId(src)
    local player = UME.GetPlayer(src)
    if not player then return nil end
    return player.GetPlayerData().citizenid
end

local function GetContractTemplate(contractId)
    if not JobsConfig.Contracts or not JobsConfig.Contracts.contracts then return nil end
    for _, c in ipairs(JobsConfig.Contracts.contracts) do
        if c.id == contractId then return c end
    end
    return nil
end

-- ───────────────────────────────────────
-- Accept Contract
-- ───────────────────────────────────────

RegisterNetEvent('umeverse_jobs:server:acceptContract', function(jobName, contractId)
    local src = source
    if not JobsConfig.Contracts or not JobsConfig.Contracts.enabled then return end

    local citizenid = GetCitizenId(src)
    if not citizenid then return end

    -- Check if already has an active contract
    if activeContracts[src] then
        TriggerClientEvent('umeverse:client:notify', src, 'You already have an active contract!', 'error')
        return
    end

    local tmpl = GetContractTemplate(contractId)
    if not tmpl then
        TriggerClientEvent('umeverse:client:notify', src, 'Invalid contract!', 'error')
        return
    end

    local now = os.time()
    local expiresAt = now + (tmpl.timeLimitMins * 60)

    -- Save to DB
    exports.oxmysql:execute(
        'INSERT INTO umeverse_job_contracts (citizenid, job_name, contract_id, tasks_done, tasks_required, started_at, expires_at, status) VALUES (?, ?, ?, 0, ?, ?, ?, ?)',
        { citizenid, jobName, contractId, tmpl.tasks, now, expiresAt, 'active' }
    )

    local contract = {
        id = contractId,
        label = tmpl.label,
        description = tmpl.description,
        jobName = jobName,
        tasksDone = 0,
        tasksRequired = tmpl.tasks,
        startedAt = now,
        expiresAt = expiresAt,
        payBonus = tmpl.payBonus,
        xpBonus = tmpl.xpBonus,
    }

    activeContracts[src] = contract
    TriggerClientEvent('umeverse_jobs:client:contractAccepted', src, contract)
    TriggerClientEvent('umeverse:client:notify', src, '📋 Contract accepted: ' .. tmpl.label .. ' (' .. tmpl.tasks .. ' tasks, ' .. tmpl.timeLimitMins .. ' min)', 'success')
end)

-- ───────────────────────────────────────
-- Task Progress
-- ───────────────────────────────────────

RegisterNetEvent('umeverse_jobs:server:contractTaskDone', function(jobName)
    local src = source
    if not JobsConfig.Contracts or not JobsConfig.Contracts.enabled then return end

    local contract = activeContracts[src]
    if not contract or contract.jobName ~= jobName then return end

    -- Check expiry
    if os.time() > contract.expiresAt then
        activeContracts[src] = nil
        -- Update DB
        local citizenid = GetCitizenId(src)
        if citizenid then
            exports.oxmysql:execute(
                'UPDATE umeverse_job_contracts SET status = ? WHERE citizenid = ? AND status = ?',
                { 'failed', citizenid, 'active' }
            )
        end
        TriggerClientEvent('umeverse_jobs:client:contractFailed', src, contract)
        TriggerClientEvent('umeverse:client:notify', src, '⏰ Contract expired: ' .. contract.label, 'error')
        return
    end

    contract.tasksDone = contract.tasksDone + 1

    -- Update DB progress
    local citizenid = GetCitizenId(src)
    if citizenid then
        exports.oxmysql:execute(
            'UPDATE umeverse_job_contracts SET tasks_done = ? WHERE citizenid = ? AND status = ?',
            { contract.tasksDone, citizenid, 'active' }
        )
    end

    TriggerClientEvent('umeverse_jobs:client:contractProgress', src, contract)

    -- Check completion
    if contract.tasksDone >= contract.tasksRequired then
        activeContracts[src] = nil

        if citizenid then
            exports.oxmysql:execute(
                'UPDATE umeverse_job_contracts SET tasks_done = ?, status = ? WHERE citizenid = ? AND status = ?',
                { contract.tasksDone, 'completed', citizenid, 'active' }
            )
        end

        -- Award bonuses
        local player = UME.GetPlayer(src)
        if player then
            local tmpl = GetContractTemplate(contract.id)
            if tmpl then
                local bonusCash = math.floor((contract.payBonus / 100) * 500)  -- Base contract completion bonus
                player.AddMoney('cash', bonusCash, 'contract-completion-' .. contract.id)
                TriggerEvent('umeverse_jobs:server:addXP', src, contract.xpBonus)
            end
        end

        TriggerClientEvent('umeverse_jobs:client:contractComplete', src, contract)
        TriggerClientEvent('umeverse:client:notify', src, '🎉 Contract Complete: ' .. contract.label .. '! Bonus awarded!', 'success')
    end
end)

-- ───────────────────────────────────────
-- Abandon Contract
-- ───────────────────────────────────────

RegisterNetEvent('umeverse_jobs:server:abandonContract', function()
    local src = source
    if not JobsConfig.Contracts or not JobsConfig.Contracts.enabled then return end

    local contract = activeContracts[src]
    if not contract then return end

    activeContracts[src] = nil

    local citizenid = GetCitizenId(src)
    if citizenid then
        exports.oxmysql:execute(
            'UPDATE umeverse_job_contracts SET status = ? WHERE citizenid = ? AND status = ?',
            { 'abandoned', citizenid, 'active' }
        )
    end

    TriggerClientEvent('umeverse_jobs:client:contractAbandoned', src)
    TriggerClientEvent('umeverse:client:notify', src, '❌ Contract abandoned.', 'error')
end)

-- ───────────────────────────────────────
-- Get Active Contract (client request)
-- ───────────────────────────────────────

RegisterNetEvent('umeverse_jobs:server:getContract', function()
    local src = source
    local contract = activeContracts[src]
    if contract then
        -- Check if expired
        if os.time() > contract.expiresAt then
            activeContracts[src] = nil
            local citizenid = GetCitizenId(src)
            if citizenid then
                exports.oxmysql:execute(
                    'UPDATE umeverse_job_contracts SET status = ? WHERE citizenid = ? AND status = ?',
                    { 'failed', citizenid, 'active' }
                )
            end
            TriggerClientEvent('umeverse_jobs:client:contractFailed', src, contract)
            return
        end
        TriggerClientEvent('umeverse_jobs:client:contractAccepted', src, contract)
    end
end)

-- ───────────────────────────────────────
-- Get Pay Multiplier for Active Contract
-- ───────────────────────────────────────

--- Returns the contract pay multiplier for a source, or 1.0 if none
function GetContractPayMultiplier(src)
    local contract = activeContracts[src]
    if not contract then return 1.0 end
    if os.time() > contract.expiresAt then return 1.0 end
    return 1.0 + (contract.payBonus / 100)
end

-- Export for use in main.lua
exports('GetContractPayMultiplier', GetContractPayMultiplier)

-- ───────────────────────────────────────
-- Cleanup
-- ───────────────────────────────────────

AddEventHandler('playerDropped', function()
    local src = source
    activeContracts[src] = nil
end)
