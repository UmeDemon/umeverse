--[[
    Umeverse Framework - Server Main
    Core server initialization and event handling
]]

local _ready = false

--- Framework ready state
function UME.IsReady()
    return _ready
end

--- Get all loaded players
---@return table
function UME.GetPlayers()
    return UME.Players
end

--- Get a loaded player by server ID
---@param source number
---@return table|nil
function UME.GetPlayer(source)
    return UME.Players[source]
end

--- Get a player by citizen ID
---@param citizenid string
---@return table|nil
function UME.GetPlayerByCitizenId(citizenid)
    for _, player in pairs(UME.Players) do
        if player.citizenid == citizenid then
            return player
        end
    end
    return nil
end

--- Get a player's identifier
---@param source number
---@param idType string
---@return string|nil
function UME.GetIdentifier(source, idType)
    idType = idType or UmeConfig.IdentifierType
    for _, id in ipairs(GetPlayerIdentifiers(source)) do
        if string.find(id, idType .. ':') then
            return id
        end
    end
    return nil
end

--- Get online player count
---@return number
function UME.GetPlayerCount()
    return UME.TableLength(UME.Players)
end

-- ═══════════════════════════════════════
-- Events
-- ═══════════════════════════════════════

--- Player connecting
AddEventHandler('playerConnecting', function(name, setKickReason, deferrals)
    local src = source
    deferrals.defer()
    Wait(0)

    deferrals.update('🔍 Checking your identity...')

    local identifier = UME.GetIdentifier(src)
    if not identifier then
        deferrals.done('Unable to retrieve your identifier. Please restart FiveM.')
        return
    end

    deferrals.update('✅ Welcome to ' .. UmeConfig.ServerName .. '!')
    Wait(500)

    -- Check for bans
    local banned = MySQL.scalar.await('SELECT COUNT(*) FROM umeverse_bans WHERE identifier = ? AND (expires > NOW() OR permanent = 1)', { identifier })
    if banned and banned > 0 then
        deferrals.done('🚫 You are banned from this server.')
        return
    end

    deferrals.done()
end)

--- Player dropped
AddEventHandler('playerDropped', function(reason)
    local src = source
    local playerName = GetPlayerName(src) or 'Unknown'
    local player = UME.GetPlayer(src)

    if player then
        player:Save()
        UME.Players[src] = nil
        UME.Debug('Player dropped: ' .. playerName .. ' (' .. (reason or 'Unknown') .. ')')
        TriggerEvent('umeverse:server:playerDropped', src, reason)
    end
end)

--- Resource start
AddEventHandler('onResourceStart', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    _ready = true
    UME.Success('Umeverse Framework v1.0.0 has started successfully.')
end)

--- Resource stop - save all players
AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    local count = 0
    for _, player in pairs(UME.Players) do
        player:Save()
        count = count + 1
    end
    if count > 0 then
        UME.Debug('Saved ' .. count .. ' player(s) on resource stop.')
    end
end)

-- ═══════════════════════════════════════
-- Client requests
-- ═══════════════════════════════════════

--- Client requests player data after spawn
RegisterNetEvent('umeverse:server:playerLoaded', function()
    local src = source
    local identifier = UME.GetIdentifier(src)

    if not identifier then
        DropPlayer(src, 'Unable to retrieve your identifier.')
        return
    end

    -- Check if player exists in DB
    local result = MySQL.query.await('SELECT * FROM umeverse_players WHERE identifier = ?', { identifier })

    if result and #result > 0 then
        -- Existing player - load their data
        if UmeConfig.EnableMulticharacter then
            -- Send character list to client for selection
            local characters = {}
            for _, row in ipairs(result) do
                characters[#characters + 1] = {
                    citizenid  = row.citizenid,
                    firstname  = row.firstname,
                    lastname   = row.lastname,
                    job        = json.decode(row.job) or {},
                    money      = json.decode(row.money) or {},
                    charinfo   = json.decode(row.charinfo) or {},
                }
            end
            TriggerClientEvent('umeverse:client:selectCharacter', src, characters)
        else
            -- Single character mode - load first character
            UME.LoadPlayer(src, result[1].citizenid)
        end
    else
        -- New player
        if UmeConfig.EnableMulticharacter then
            TriggerClientEvent('umeverse:client:selectCharacter', src, {})
        else
            TriggerClientEvent('umeverse:client:createCharacter', src)
        end
    end
end)

--- Client selected a character
RegisterNetEvent('umeverse:server:loadCharacter', function(citizenid)
    local src = source
    local identifier = UME.GetIdentifier(src)
    if not identifier then return end

    -- Verify character belongs to this player
    local check = MySQL.scalar.await(
        'SELECT COUNT(*) FROM umeverse_players WHERE citizenid = ? AND identifier = ?',
        { citizenid, identifier }
    )
    if not check or check == 0 then
        UME.Error('Player ' .. GetPlayerName(src) .. ' tried to load character ' .. citizenid .. ' that does not belong to them.')
        return
    end

    UME.LoadPlayer(src, citizenid)
end)

--- Client wants to create a character
RegisterNetEvent('umeverse:server:createCharacter', function(data)
    local src = source
    local identifier = UME.GetIdentifier(src)

    if not identifier then return end

    -- Check character limit
    if UmeConfig.EnableMulticharacter then
        local count = MySQL.scalar.await('SELECT COUNT(*) FROM umeverse_players WHERE identifier = ?', { identifier })
        if count >= UmeConfig.MaxCharacters then
            TriggerClientEvent('umeverse:client:notify', src, _T('char_slots_full'), 'error')
            return
        end
    end

    local citizenid
    local maxAttempts = 10
    for _ = 1, maxAttempts do
        citizenid = UME.GenerateId():sub(1, 8):upper()
        local exists = MySQL.scalar.await('SELECT COUNT(*) FROM umeverse_players WHERE citizenid = ?', { citizenid })
        if not exists or exists == 0 then break end
        citizenid = nil
    end

    if not citizenid then
        TriggerClientEvent('umeverse:client:notify', src, 'Failed to generate unique character ID. Please try again.', 'error')
        return
    end

    -- Sanitize input
    local firstname = tostring(data.firstname or 'John'):sub(1, 50):gsub('[^%w%s%-]', '')
    local lastname = tostring(data.lastname or 'Doe'):sub(1, 50):gsub('[^%w%s%-]', '')
    if #firstname == 0 then firstname = 'John' end
    if #lastname == 0 then lastname = 'Doe' end

    local playerData = {
        identifier = identifier,
        citizenid  = citizenid,
        firstname  = firstname,
        lastname   = lastname,
        charinfo   = json.encode(data.charinfo or {}),
        money      = json.encode({ cash = UmeConfig.StartingCash, bank = UmeConfig.StartingBank, black = 0 }),
        job        = json.encode({ name = UmeConfig.DefaultJob, grade = UmeConfig.DefaultJobGrade, onduty = false }),
        position   = json.encode({ x = UmeConfig.DefaultSpawn.x, y = UmeConfig.DefaultSpawn.y, z = UmeConfig.DefaultSpawn.z, heading = UmeConfig.DefaultSpawn.w }),
        inventory  = json.encode({}),
        status     = json.encode({ hunger = 100.0, thirst = 100.0 }),
        skin       = json.encode({}),
    }

    MySQL.insert.await('INSERT INTO umeverse_players (identifier, citizenid, firstname, lastname, charinfo, money, job, position, inventory, status, skin) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)', {
        playerData.identifier,
        playerData.citizenid,
        playerData.firstname,
        playerData.lastname,
        playerData.charinfo,
        playerData.money,
        playerData.job,
        playerData.position,
        playerData.inventory,
        playerData.status,
        playerData.skin,
    })

    UME.LoadPlayer(src, citizenid)
    UME.Debug('New character created: ' .. data.firstname .. ' ' .. data.lastname .. ' (' .. citizenid .. ')')
end)

--- Delete a character
RegisterNetEvent('umeverse:server:deleteCharacter', function(citizenid)
    local src = source
    local identifier = UME.GetIdentifier(src)

    if not identifier then return end

    MySQL.query.await('DELETE FROM umeverse_players WHERE identifier = ? AND citizenid = ?', { identifier, citizenid })
    TriggerClientEvent('umeverse:client:notify', src, _T('char_deleted'), 'success')
    UME.Debug('Character deleted: ' .. citizenid)

    -- Refresh character list by re-fetching from DB
    local result = MySQL.query.await('SELECT * FROM umeverse_players WHERE identifier = ?', { identifier })
    local characters = {}
    if result then
        for _, row in ipairs(result) do
            characters[#characters + 1] = {
                citizenid  = row.citizenid,
                firstname  = row.firstname,
                lastname   = row.lastname,
                job        = json.decode(row.job) or {},
                money      = json.decode(row.money) or {},
                charinfo   = json.decode(row.charinfo) or {},
            }
        end
    end
    TriggerClientEvent('umeverse:client:selectCharacter', src, characters)
end)

-- ═══════════════════════════════════════
-- Player State Events
-- ═══════════════════════════════════════

--- Client sends updated position every 30 seconds
RegisterNetEvent('umeverse:server:updatePosition', function(coords)
    local src = source
    local player = UME.GetPlayer(src)
    if player and coords then
        -- Validate coordinate types to prevent NaN / nil injection
        local x = tonumber(coords.x)
        local y = tonumber(coords.y)
        local z = tonumber(coords.z)
        local heading = tonumber(coords.heading or coords.w)
        if x and y and z and heading then
            player:SetPosition({ x = x, y = y, z = z, heading = heading })
        end
    end
end)

--- Server-driven status decay (runs per-player, not client-triggered)
CreateThread(function()
    while true do
        Wait(60 * 1000) -- Every minute
        if UmeConfig.EnableStatus then
            for _, player in pairs(UME.Players) do
                player:RemoveStatus('hunger', UmeConfig.HungerDecayRate)
                player:RemoveStatus('thirst', UmeConfig.ThirstDecayRate)
            end
        end
    end
end)

--- Player died
RegisterNetEvent('umeverse:server:playerDied', function(coords)
    local src = source
    local player = UME.GetPlayer(src)
    if player then
        MySQL.update('UPDATE umeverse_players SET is_dead = 1 WHERE citizenid = ?', { player:GetCitizenId() })
        UME.Debug(player:GetFullName() .. ' has died.')
        TriggerEvent('umeverse:server:onPlayerDeath', src, coords)
    end
end)

--- Player respawned
RegisterNetEvent('umeverse:server:playerRespawned', function()
    local src = source
    local player = UME.GetPlayer(src)
    if player then
        MySQL.update('UPDATE umeverse_players SET is_dead = 0 WHERE citizenid = ?', { player:GetCitizenId() })

        -- Update position to hospital
        local hospital = UmeConfig.HospitalSpawn
        player:SetPosition({ x = hospital.x, y = hospital.y, z = hospital.z, heading = hospital.w })

        -- Deduct respawn cost if configured
        if UmeConfig.RespawnCost > 0 then
            if player:HasMoney('bank', UmeConfig.RespawnCost) then
                player:RemoveMoney('bank', UmeConfig.RespawnCost, 'Hospital bill')
            elseif player:HasMoney('cash', UmeConfig.RespawnCost) then
                player:RemoveMoney('cash', UmeConfig.RespawnCost, 'Hospital bill')
            end
        end

        UME.Debug(player:GetFullName() .. ' has respawned.')
    end
end)

-- ═══════════════════════════════════════
-- Auto-save loop
-- ═══════════════════════════════════════
CreateThread(function()
    while true do
        Wait(UmeConfig.AutoSaveInterval * 60 * 1000)
        local count = 0
        for _, player in pairs(UME.Players) do
            player:SaveAsync() -- Non-blocking save for batch operations
            count = count + 1
        end
        if count > 0 then
            UME.Debug('Auto-saved ' .. count .. ' player(s).')
        end
    end
end)

-- ═══════════════════════════════════════
-- Paycheck loop
-- ═══════════════════════════════════════
CreateThread(function()
    while true do
        Wait(15 * 60 * 1000) -- Every 15 minutes
        for src, player in pairs(UME.Players) do
            local job = player:GetJob()
            if job and job.name ~= 'unemployed' then
                local gradeData = UME.GetJobGrade(job.name, job.grade)
                if gradeData and gradeData.payment > 0 and job.onduty then
                    player:AddMoney('bank', gradeData.payment, 'Paycheck')
                    TriggerClientEvent('umeverse:client:notify', src, _T('paycheck_received', gradeData.payment), 'success')
                end
            end
        end
    end
end)

-- ═══════════════════════════════════════
-- Exports
-- ═══════════════════════════════════════
exports('GetCoreObject', function()
    return UME
end)
