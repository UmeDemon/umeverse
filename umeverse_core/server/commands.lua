--[[
    Umeverse Framework - Server Commands
    Built-in admin and player commands
]]

-- ═══════════════════════════════════════
-- Permission checking
-- ═══════════════════════════════════════

local AdminPermissions = {
    -- identifier = permission level
    -- Add your admins here or load from DB
}

--- Check admin permission (uses ace permissions or hardcoded)
---@param source number
---@param permission string
---@return boolean
function UME.HasPermission(source, permission)
    -- Check FiveM ace permissions (native expects string source)
    if IsPlayerAceAllowed(tostring(source), permission) then
        return true
    end

    -- Check hardcoded
    local identifier = UME.GetIdentifier(source)
    if AdminPermissions[identifier] then
        return true
    end

    return false
end

-- ═══════════════════════════════════════
-- Player Commands
-- ═══════════════════════════════════════

RegisterCommand('cash', function(source)
    local player = UME.GetPlayer(source)
    if not player then return end
    TriggerClientEvent('umeverse:client:notify', source, 'Cash: £' .. player:GetMoney('cash'), 'info')
end, false)

RegisterCommand('bank', function(source)
    local player = UME.GetPlayer(source)
    if not player then return end
    TriggerClientEvent('umeverse:client:notify', source, 'Bank: £' .. player:GetMoney('bank'), 'info')
end, false)

RegisterCommand('job', function(source)
    local player = UME.GetPlayer(source)
    if not player then return end
    local job = player:GetJob()
    TriggerClientEvent('umeverse:client:notify', source, 'Job: ' .. (job.label or job.name) .. ' | Grade: ' .. (job.gradelabel or job.grade), 'info')
end, false)

RegisterCommand('logout', function(source)
    local player = UME.GetPlayer(source)
    if not player then return end
    player:Save()
    UME.Players[source] = nil
    TriggerClientEvent('umeverse:client:logout', source)
end, false)

-- ═══════════════════════════════════════
-- Admin Commands
-- ═══════════════════════════════════════

--- Give money to a player
RegisterCommand('givemoney', function(source, args)
    if not UME.HasPermission(source, 'umeverse.admin') then
        TriggerClientEvent('umeverse:client:notify', source, _T('admin_no_permission'), 'error')
        return
    end

    local targetId = tonumber(args[1])
    local moneyType = args[2] or 'cash'
    local amount = tonumber(args[3])

    if not targetId or not amount then
        TriggerClientEvent('umeverse:client:notify', source, 'Usage: /givemoney [id] [cash/bank] [amount]', 'error')
        return
    end

    local target = UME.GetPlayer(targetId)
    if not target then
        TriggerClientEvent('umeverse:client:notify', source, 'Player not found.', 'error')
        return
    end

    target:AddMoney(moneyType, amount, 'Admin give')
    TriggerClientEvent('umeverse:client:notify', source, 'Gave £' .. amount .. ' ' .. moneyType .. ' to ' .. target:GetFullName(), 'success')
end, false)

--- Set a player's job
RegisterCommand('setjob', function(source, args)
    if not UME.HasPermission(source, 'umeverse.admin') then
        TriggerClientEvent('umeverse:client:notify', source, _T('admin_no_permission'), 'error')
        return
    end

    local targetId = tonumber(args[1])
    local jobName = args[2]
    local grade = tonumber(args[3]) or 0

    if not targetId or not jobName then
        TriggerClientEvent('umeverse:client:notify', source, 'Usage: /setjob [id] [job] [grade]', 'error')
        return
    end

    local target = UME.GetPlayer(targetId)
    if not target then
        TriggerClientEvent('umeverse:client:notify', source, 'Player not found.', 'error')
        return
    end

    if target:SetJob(jobName, grade) then
        TriggerClientEvent('umeverse:client:notify', source, 'Set ' .. target:GetFullName() .. '\'s job to ' .. jobName .. ' (Grade: ' .. grade .. ')', 'success')
    else
        TriggerClientEvent('umeverse:client:notify', source, 'Invalid job or grade.', 'error')
    end
end, false)

--- Give an item to a player
RegisterCommand('giveitem', function(source, args)
    if not UME.HasPermission(source, 'umeverse.admin') then
        TriggerClientEvent('umeverse:client:notify', source, _T('admin_no_permission'), 'error')
        return
    end

    local targetId = tonumber(args[1])
    local itemName = args[2]
    local amount = tonumber(args[3]) or 1

    if not targetId or not itemName then
        TriggerClientEvent('umeverse:client:notify', source, 'Usage: /giveitem [id] [item] [amount]', 'error')
        return
    end

    local target = UME.GetPlayer(targetId)
    if not target then
        TriggerClientEvent('umeverse:client:notify', source, 'Player not found.', 'error')
        return
    end

    if target:AddItem(itemName, amount) then
        TriggerClientEvent('umeverse:client:notify', source, 'Gave ' .. amount .. 'x ' .. itemName .. ' to ' .. target:GetFullName(), 'success')
    else
        TriggerClientEvent('umeverse:client:notify', source, 'Invalid item.', 'error')
    end
end, false)

--- Kick a player
RegisterCommand('kick', function(source, args)
    if not UME.HasPermission(source, 'umeverse.admin') then
        TriggerClientEvent('umeverse:client:notify', source, _T('admin_no_permission'), 'error')
        return
    end

    local targetId = tonumber(args[1])
    local reason = (#args >= 2 and table.concat(args, ' ', 2)) or 'No reason provided'

    if not targetId then
        TriggerClientEvent('umeverse:client:notify', source, 'Usage: /kick [id] [reason]', 'error')
        return
    end

    local target = UME.GetPlayer(targetId)
    if target then
        target:Kick(reason)
        UME.Debug(_T('admin_player_kicked', target:GetFullName(), reason))
    end
end, false)

--- Ban a player
RegisterCommand('ban', function(source, args)
    if not UME.HasPermission(source, 'umeverse.admin') then
        TriggerClientEvent('umeverse:client:notify', source, _T('admin_no_permission'), 'error')
        return
    end

    local targetId = tonumber(args[1])
    local duration = tonumber(args[2]) or 0 -- 0 = permanent, else hours
    local reason = (#args >= 3 and table.concat(args, ' ', 3)) or 'No reason provided'

    if not targetId then
        TriggerClientEvent('umeverse:client:notify', source, 'Usage: /ban [id] [hours/0=perm] [reason]', 'error')
        return
    end

    local target = UME.GetPlayer(targetId)
    if not target then
        TriggerClientEvent('umeverse:client:notify', source, 'Player not found.', 'error')
        return
    end

    local permanent = duration == 0
    local expires = nil
    if not permanent then
        -- Calculate expiry
        expires = os.date('!%Y-%m-%d %H:%M:%S', os.time() + (duration * 3600))
    end

    MySQL.insert.await('INSERT INTO umeverse_bans (identifier, citizenid, reason, banned_by, permanent, expires) VALUES (?, ?, ?, ?, ?, ?)', {
        target:GetIdentifier(),
        target:GetCitizenId(),
        reason,
        UME.GetIdentifier(source) or 'Console',
        permanent and 1 or 0,
        expires,
    })

    target:Kick('You have been banned: ' .. reason)
    UME.Debug(_T('admin_player_banned', target:GetFullName(), reason))
    TriggerClientEvent('umeverse:client:notify', source, 'Banned ' .. target:GetFullName() .. ': ' .. reason, 'success')
end, false)

--- Teleport to waypoint (admin)
RegisterCommand('tp', function(source)
    if not UME.HasPermission(source, 'umeverse.admin') then
        TriggerClientEvent('umeverse:client:notify', source, _T('admin_no_permission'), 'error')
        return
    end
    TriggerClientEvent('umeverse:client:teleportToWaypoint', source)
end, false)

--- Revive a player
RegisterCommand('revive', function(source, args)
    if not UME.HasPermission(source, 'umeverse.admin') then
        TriggerClientEvent('umeverse:client:notify', source, _T('admin_no_permission'), 'error')
        return
    end

    local targetId = tonumber(args[1]) or source
    TriggerClientEvent('umeverse:client:revive', targetId)
    TriggerClientEvent('umeverse:client:notify', source, 'Player revived.', 'success')
end, false)

--- Toggle noclip
RegisterCommand('noclip', function(source)
    if not UME.HasPermission(source, 'umeverse.admin') then
        TriggerClientEvent('umeverse:client:notify', source, _T('admin_no_permission'), 'error')
        return
    end
    TriggerClientEvent('umeverse:client:toggleNoclip', source)
end, false)

--- Toggle god mode
RegisterCommand('god', function(source)
    if not UME.HasPermission(source, 'umeverse.admin') then
        TriggerClientEvent('umeverse:client:notify', source, _T('admin_no_permission'), 'error')
        return
    end
    TriggerClientEvent('umeverse:client:toggleGodMode', source)
end, false)

--- Teleport to a player
RegisterCommand('goto', function(source, args)
    if not UME.HasPermission(source, 'umeverse.admin') then
        TriggerClientEvent('umeverse:client:notify', source, _T('admin_no_permission'), 'error')
        return
    end

    local targetId = tonumber(args[1])
    if not targetId then
        TriggerClientEvent('umeverse:client:notify', source, 'Usage: /goto [id]', 'error')
        return
    end

    local targetPed = GetPlayerPed(targetId)
    if targetPed and DoesEntityExist(targetPed) then
        local coords = GetEntityCoords(targetPed)
        TriggerClientEvent('umeverse:client:teleport', source, coords.x, coords.y, coords.z)
    end
end, false)

--- Bring a player to you
RegisterCommand('bring', function(source, args)
    if not UME.HasPermission(source, 'umeverse.admin') then
        TriggerClientEvent('umeverse:client:notify', source, _T('admin_no_permission'), 'error')
        return
    end

    local targetId = tonumber(args[1])
    if not targetId then
        TriggerClientEvent('umeverse:client:notify', source, 'Usage: /bring [id]', 'error')
        return
    end

    local myPed = GetPlayerPed(source)
    if myPed and DoesEntityExist(myPed) then
        local coords = GetEntityCoords(myPed)
        TriggerClientEvent('umeverse:client:teleport', targetId, coords.x, coords.y, coords.z)
    end
end, false)

--- Give a vehicle to a player (inserts into DB)
RegisterCommand('givevehicle', function(source, args)
    if not UME.HasPermission(source, 'umeverse.admin') then
        TriggerClientEvent('umeverse:client:notify', source, _T('admin_no_permission'), 'error')
        return
    end

    local targetId = tonumber(args[1])
    local model = args[2]
    local garageId = args[3] or 'legion'

    if not targetId or not model then
        TriggerClientEvent('umeverse:client:notify', source, 'Usage: /givevehicle [id] [model] [garage]', 'error')
        return
    end

    local target = UME.GetPlayer(targetId)
    if not target then
        TriggerClientEvent('umeverse:client:notify', source, 'Player not found.', 'error')
        return
    end

    -- Generate a random plate
    local plate = string.upper(UME.GenerateId():sub(1, 8))

    MySQL.insert.await('INSERT INTO umeverse_vehicles (citizenid, plate, model, state, garage) VALUES (?, ?, ?, ?, ?)', {
        target:GetCitizenId(), plate, model, 1, garageId,
    })

    TriggerClientEvent('umeverse:client:notify', source, 'Gave vehicle ' .. model .. ' [' .. plate .. '] to ' .. target:GetFullName(), 'success')
    TriggerClientEvent('umeverse:client:notify', targetId, 'You received a new vehicle: ' .. model .. '. Check your garage!', 'success')
end, false)
