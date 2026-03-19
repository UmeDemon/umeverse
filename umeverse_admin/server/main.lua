--[[
    Umeverse Admin - Server
]]

local UME = exports['umeverse_core']:GetCoreObject()

--- Get admin level for a player (returns highest matching level)
local function GetAdminLevel(source)
    local highestLevel = 0
    local highestLabel = nil
    for permName, permData in pairs(AdminConfig.Permissions) do
        if IsPlayerAceAllowed(source, 'umeverse.' .. permName) then
            if permData.level > highestLevel then
                highestLevel = permData.level
                highestLabel = permData.label
            end
        end
    end
    return highestLevel, highestLabel
end

--- Check if player has permission for an action
local function HasActionPermission(source, action)
    local level = GetAdminLevel(source)
    local required = AdminConfig.ActionPermissions[action] or 999
    return level >= required
end

-- ═══════════════════════════════════════
-- Open Admin Panel
-- ═══════════════════════════════════════

RegisterNetEvent('umeverse_admin:server:openPanel', function()
    local src = source
    local level, label = GetAdminLevel(src)

    if level <= 0 then
        UME.Notify(src, UME.Translate('admin_no_permission'), 'error')
        return
    end

    -- Get online players
    local players = {}
    for id, player in pairs(UME.GetPlayers()) do
        players[#players + 1] = {
            id        = id,
            name      = player:GetFullName(),
            citizenid = player.citizenid,
            job       = player.job.label or player.job.name,
            cash      = player:GetMoney('cash'),
            bank      = player:GetMoney('bank'),
            ping      = GetPlayerPing(id),
        }
    end

    -- Get recent bans
    local bans = MySQL.query.await('SELECT * FROM umeverse_bans ORDER BY created_at DESC LIMIT 20') or {}

    -- Get available jobs
    local jobs = {}
    for name, data in pairs(UME.Jobs) do
        local grades = {}
        for grade, gradeData in pairs(data.grades) do
            grades[#grades + 1] = { grade = grade, name = gradeData.name }
        end
        table.sort(grades, function(a, b) return a.grade < b.grade end)
        jobs[#jobs + 1] = { name = name, label = data.label, grades = grades }
    end
    table.sort(jobs, function(a, b) return a.label < b.label end)

    -- Get available items
    local items = {}
    for name, data in pairs(UME.Items) do
        items[#items + 1] = { name = name, label = data.label }
    end
    table.sort(items, function(a, b) return a.label < b.label end)

    TriggerClientEvent('umeverse_admin:client:openPanel', src, {
        adminLevel = level,
        adminLabel = label,
        players    = players,
        bans       = bans,
        jobs       = jobs,
        items      = items,
        permissions = AdminConfig.ActionPermissions,
    })
end)

-- ═══════════════════════════════════════
-- Admin Actions
-- ═══════════════════════════════════════

RegisterNetEvent('umeverse_admin:server:action', function(action, data)
    local src = source

    if not HasActionPermission(src, action) then
        UME.Notify(src, UME.Translate('admin_no_permission'), 'error')
        return
    end

    local adminName = GetPlayerName(src) or 'Unknown'

    if action == 'kick' then
        local target = UME.GetPlayer(data.targetId)
        if target then
            target:Kick(data.reason or 'Kicked by admin')
            UME.Notify(src, 'Player kicked.', 'success')
            UME.Log('Admin Kick', adminName .. ' kicked ' .. target:GetFullName() .. ': ' .. (data.reason or 'No reason'), 16711680)
        end

    elseif action == 'ban' then
        local target = UME.GetPlayer(data.targetId)
        if target then
            local permanent = (data.duration or 0) == 0
            local expires = nil
            if not permanent then
                expires = os.date('!%Y-%m-%d %H:%M:%S', os.time() + (data.duration * 3600))
            end

            MySQL.insert('INSERT INTO umeverse_bans (identifier, citizenid, reason, banned_by, permanent, expires) VALUES (?, ?, ?, ?, ?, ?)', {
                target:GetIdentifier(), target:GetCitizenId(),
                data.reason or 'No reason',
                UME.GetIdentifier(src) or 'Console',
                permanent and 1 or 0, expires,
            })

            target:Kick('Banned: ' .. (data.reason or 'No reason'))
            UME.Notify(src, 'Player banned.', 'success')
            UME.Log('Admin Ban', adminName .. ' banned ' .. target:GetFullName() .. ': ' .. (data.reason or 'No reason'), 16711680)
        end

    elseif action == 'unban' then
        MySQL.query('DELETE FROM umeverse_bans WHERE id = ?', { data.banId })
        UME.Notify(src, 'Ban removed.', 'success')

    elseif action == 'teleport' then
        TriggerClientEvent('umeverse:client:teleportToWaypoint', src)

    elseif action == 'goto_player' then
        local targetPed = GetPlayerPed(data.targetId)
        if targetPed and DoesEntityExist(targetPed) then
            local coords = GetEntityCoords(targetPed)
            TriggerClientEvent('umeverse:client:teleport', src, coords.x, coords.y, coords.z)
        end

    elseif action == 'bring_player' then
        local myPed = GetPlayerPed(src)
        if myPed and DoesEntityExist(myPed) then
            local coords = GetEntityCoords(myPed)
            TriggerClientEvent('umeverse:client:teleport', data.targetId, coords.x, coords.y, coords.z)
        end

    elseif action == 'revive' then
        TriggerClientEvent('umeverse:client:revive', data.targetId or src)

    elseif action == 'noclip' then
        TriggerClientEvent('umeverse:client:toggleNoclip', src)

    elseif action == 'godmode' then
        TriggerClientEvent('umeverse:client:toggleGodMode', src)

    elseif action == 'give_money' then
        local target = UME.GetPlayer(data.targetId)
        if target then
            target:AddMoney(data.moneyType or 'cash', data.amount, 'Admin give')
            UME.Notify(src, 'Money given.', 'success')
        end

    elseif action == 'set_job' then
        local target = UME.GetPlayer(data.targetId)
        if target then
            target:SetJob(data.job, data.grade or 0)
            UME.Notify(src, 'Job set.', 'success')
        end

    elseif action == 'give_item' then
        local target = UME.GetPlayer(data.targetId)
        if target then
            target:AddItem(data.item, data.amount or 1)
            UME.Notify(src, 'Item given.', 'success')
        end

    elseif action == 'spawn_vehicle' then
        TriggerClientEvent('umeverse_admin:client:spawnVehicle', src, data.model)

    elseif action == 'despawn_vehicle' then
        TriggerClientEvent('umeverse_admin:client:despawnVehicle', src)

    elseif action == 'heal' then
        local targetId = data.targetId or src
        local target = UME.GetPlayer(targetId)
        if target then
            target:SetStatus('hunger', 100)
            target:SetStatus('thirst', 100)
            TriggerClientEvent('umeverse:client:heal', targetId, 999)
            UME.Notify(src, 'Player fully healed.', 'success')
            UME.Notify(targetId, 'You have been fully healed by an admin.', 'success')
        end

    elseif action == 'remove_money' then
        local target = UME.GetPlayer(data.targetId)
        if target then
            target:RemoveMoney(data.moneyType or 'cash', data.amount, 'Admin remove')
            UME.Notify(src, 'Money removed.', 'success')
        end

    elseif action == 'clear_inventory' then
        local target = UME.GetPlayer(data.targetId)
        if target then
            target.inventory = {}
            TriggerClientEvent('umeverse:client:updateInventory', data.targetId, {})
            UME.Notify(src, 'Inventory cleared.', 'success')
            UME.Notify(data.targetId, 'Your inventory has been cleared by an admin.', 'error')
            UME.Log('Admin Clear Inventory', adminName .. ' cleared inventory of ' .. target:GetFullName(), 16711680)
        end

    elseif action == 'invisible' then
        TriggerClientEvent('umeverse_admin:client:toggleInvisible', src)

    elseif action == 'teleport_coords' then
        local x = tonumber(data.x)
        local y = tonumber(data.y)
        local z = tonumber(data.z)
        if x and y and z then
            TriggerClientEvent('umeverse:client:teleport', src, x, y, z)
        end

    elseif action == 'announce' then
        local msg = data.message
        if msg and msg ~= '' then
            TriggerClientEvent('umeverse:client:notify', -1, '📢 ' .. msg, 'info', 10000)
            UME.Log('Admin Announce', adminName .. ': ' .. msg, 3447003)
        end

    elseif action == 'set_weather' then
        local weather = data.weather
        if weather and weather ~= '' then
            TriggerClientEvent('umeverse_admin:client:setWeather', -1, weather)
            UME.Notify(src, 'Weather set to: ' .. weather, 'success')
        end

    elseif action == 'set_time' then
        local hour = tonumber(data.hour)
        local minute = tonumber(data.minute) or 0
        if hour then
            TriggerClientEvent('umeverse_admin:client:setTime', -1, hour, minute)
            UME.Notify(src, string.format('Time set to %02d:%02d', hour, minute), 'success')
        end

    elseif action == 'freeze' then
        TriggerClientEvent('umeverse_admin:client:freezePlayer', data.targetId)

    elseif action == 'spectate' then
        TriggerClientEvent('umeverse_admin:client:spectatePlayer', src, data.targetId)
    end
end)
