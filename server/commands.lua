-- ============================================================
--  UmeVerse Framework — Server Commands
-- ============================================================

-- ── Helpers ────────────────────────────────────────────────

--- Require the caller to be in the ACE group 'umeverse.admin'.
---@param source integer  0 = server console.
---@return boolean
local function isAdmin(source)
    if source == 0 then return true end   -- console always allowed
    return IsPlayerAceAllowed(source, 'umeverse.admin')
end

--- Resolve a target player from a string (net-id or partial name).
---@param str string
---@return integer|nil  net-id, or nil if not found
local function resolvePlayer(str)
    local id = tonumber(str)
    if id and GetPlayerName(id) then return id end
    -- Partial name search.
    local lower = str:lower()
    for _, pid in ipairs(GetPlayers()) do
        if GetPlayerName(pid):lower():find(lower, 1, true) then
            return tonumber(pid)
        end
    end
    return nil
end

--- Parse an integer argument, returning nil on failure.
---@param str string
---@return integer|nil
local function parseInt(str)
    local n = tonumber(str)
    return (n and math.floor(n) == n) and math.floor(n) or nil
end

-- ── Player commands ────────────────────────────────────────

-- /me <action>   — Roleplay action in proximity chat.
RegisterCommand('me', function(source, args)
    if source == 0 then return end
    if #args == 0 then return end
    local action  = table.concat(args, ' ')
    local name    = GetPlayerName(source) or 'Unknown'
    local msg     = ('* %s %s'):format(name, action)
    -- Broadcast to everyone for simplicity; replace with proximity filter if needed.
    TriggerClientEvent('chat:addMessage', -1, {
        color  = { 180, 120, 220 },
        multiline = true,
        args   = { '[ME]', msg },
    })
end, false)

-- /ooc <message>  — Out-of-character global chat.
RegisterCommand('ooc', function(source, args)
    if source == 0 then return end
    if #args == 0 then return end
    local msg  = table.concat(args, ' ')
    local name = GetPlayerName(source) or 'Unknown'
    TriggerClientEvent('chat:addMessage', -1, {
        color  = { 120, 180, 255 },
        multiline = true,
        args   = { '[OOC] ' .. name, msg },
    })
end, false)

-- /id  — Show your own server ID.
RegisterCommand('id', function(source)
    if source == 0 then return end
    local player = Ume.Player.Get(source)
    if player then
        TriggerClientEvent('chat:addMessage', source, {
            args = { '[SERVER]', ('Your server ID is: %d'):format(source) },
        })
    end
end, false)

-- ── Admin commands ─────────────────────────────────────────

-- /kick <id> [reason]
RegisterCommand('kick', function(source, args)
    if not isAdmin(source) then
        if source ~= 0 then
            TriggerClientEvent('umeverse:client:notify', source, _T('no_permission'), 'error')
        end
        return
    end
    local target = resolvePlayer(args[1] or '')
    if not target then
        if source ~= 0 then
            TriggerClientEvent('umeverse:client:notify', source, _T('player_not_found'), 'error')
        else
            print('[UmeVerse] Player not found.')
        end
        return
    end
    table.remove(args, 1)
    local reason = #args > 0 and table.concat(args, ' ') or 'Kicked by an admin.'
    DropPlayer(target, reason)
    Ume.Functions.Log(('Admin %s kicked player %d: %s'):format(
        source == 0 and 'CONSOLE' or GetPlayerName(source), target, reason))
end, false)

-- /setjob <id> <jobName> <grade>
RegisterCommand('setjob', function(source, args)
    if not isAdmin(source) then
        if source ~= 0 then
            TriggerClientEvent('umeverse:client:notify', source, _T('no_permission'), 'error')
        end
        return
    end
    local target  = resolvePlayer(args[1] or '')
    local jobName = args[2] or ''
    local grade   = parseInt(args[3] or '0') or 0

    if not target then
        if source ~= 0 then
            TriggerClientEvent('umeverse:client:notify', source, _T('player_not_found'), 'error')
        else
            print('[UmeVerse] Player not found.')
        end
        return
    end

    if not UmeJobs.IsValid(jobName, grade) then
        local msg = ('Unknown job "%s" / grade %d.'):format(jobName, grade)
        if source ~= 0 then
            TriggerClientEvent('umeverse:client:notify', source, msg, 'error')
        else
            print('[UmeVerse] ' .. msg)
        end
        return
    end

    local player = Ume.Player.Get(target)
    if not player then
        if source ~= 0 then
            TriggerClientEvent('umeverse:client:notify', source, _T('player_not_found'), 'error')
        end
        return
    end

    local gradeData = UmeJobs.GetGrade(jobName, grade)
    player:SetJob(jobName, UmeJobs[jobName].label, grade, gradeData.salary)
    player:Notify(_T('job_updated', { job = UmeJobs[jobName].label, grade = grade }), 'success')

    local adminName = source == 0 and 'CONSOLE' or GetPlayerName(source)
    Ume.Functions.Log(('%s set %s job to %s grade %d'):format(
        adminName, player.name, jobName, grade))
end, false)

-- /givemoney <id> <amount>
RegisterCommand('givemoney', function(source, args)
    if not isAdmin(source) then
        if source ~= 0 then
            TriggerClientEvent('umeverse:client:notify', source, _T('no_permission'), 'error')
        end
        return
    end
    local target = resolvePlayer(args[1] or '')
    local amount = parseInt(args[2] or '')
    if not target or not amount or amount <= 0 then
        if source ~= 0 then
            TriggerClientEvent('umeverse:client:notify', source, _T('invalid_args'), 'error')
        else
            print('[UmeVerse] Usage: /givemoney <id> <amount>')
        end
        return
    end
    local player = Ume.Player.Get(target)
    if not player then
        if source ~= 0 then
            TriggerClientEvent('umeverse:client:notify', source, _T('player_not_found'), 'error')
        end
        return
    end
    player:AddCash(amount)
    player:Notify(_T('money_added', { amount = UmeUtils.FormatMoney(amount) }), 'success')

    local adminName = source == 0 and 'CONSOLE' or GetPlayerName(source)
    Ume.Functions.Log(('%s gave %s $%d cash'):format(adminName, player.name, amount))
end, false)

-- /setcash <id> <amount>
RegisterCommand('setcash', function(source, args)
    if not isAdmin(source) then
        if source ~= 0 then
            TriggerClientEvent('umeverse:client:notify', source, _T('no_permission'), 'error')
        end
        return
    end
    local target = resolvePlayer(args[1] or '')
    local amount = parseInt(args[2] or '')
    if not target or not amount or amount < 0 then
        if source ~= 0 then
            TriggerClientEvent('umeverse:client:notify', source, _T('invalid_args'), 'error')
        else
            print('[UmeVerse] Usage: /setcash <id> <amount>')
        end
        return
    end
    local player = Ume.Player.Get(target)
    if not player then
        if source ~= 0 then
            TriggerClientEvent('umeverse:client:notify', source, _T('player_not_found'), 'error')
        end
        return
    end
    player.cash = amount
    player:TriggerEvent('umeverse:client:moneyUpdate', 'cash', amount)

    local adminName = source == 0 and 'CONSOLE' or GetPlayerName(source)
    Ume.Functions.Log(('%s set %s cash to $%d'):format(adminName, player.name, amount))
end, false)

-- /giveitem <id> <item> [count]
RegisterCommand('giveitem', function(source, args)
    if not isAdmin(source) then
        if source ~= 0 then
            TriggerClientEvent('umeverse:client:notify', source, _T('no_permission'), 'error')
        end
        return
    end
    local target   = resolvePlayer(args[1] or '')
    local itemName = args[2] or ''
    local count    = parseInt(args[3] or '1') or 1

    if not target or not UmeItems.Exists(itemName) or count <= 0 then
        if source ~= 0 then
            TriggerClientEvent('umeverse:client:notify', source, _T('invalid_args'), 'error')
        else
            print('[UmeVerse] Usage: /giveitem <id> <item> [count]')
        end
        return
    end

    local player = Ume.Player.Get(target)
    if not player then
        if source ~= 0 then
            TriggerClientEvent('umeverse:client:notify', source, _T('player_not_found'), 'error')
        end
        return
    end

    local ok, reason = player:AddItem(itemName, count, UmeItems.GetWeight(itemName))
    if ok then
        player:Notify(_T('item_added', { count = count, item = UmeItems.GetLabel(itemName) }), 'success')
    else
        if source ~= 0 then
            TriggerClientEvent('umeverse:client:notify', source, _T(reason), 'error')
        else
            print('[UmeVerse] Could not give item: ' .. reason)
        end
    end
end, false)

-- /players  — List online players (admin).
RegisterCommand('players', function(source)
    if not isAdmin(source) then
        if source ~= 0 then
            TriggerClientEvent('umeverse:client:notify', source, _T('no_permission'), 'error')
        end
        return
    end
    local lines = { '[UmeVerse] Online players:' }
    for id, player in pairs(Ume.Player.GetAll()) do
        lines[#lines + 1] = ('  [%d] %s (%s)'):format(id, player.name, player.identifier)
    end
    local output = table.concat(lines, '\n')
    if source == 0 then
        print(output)
    else
        TriggerClientEvent('chat:addMessage', source, { args = { '[SERVER]', output } })
    end
end, false)
