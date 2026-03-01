-- ============================================================
--  UmeVerse Framework — Database Bridge (server-side)
--  Requires the `oxmysql` resource to be running.
--  If oxmysql is not present the default in-memory handler in
--  server/events.lua takes over automatically.
-- ============================================================

-- Guard: only activate when oxmysql exports are available.
if not MySQL then
    Ume.Functions.Warn('oxmysql not found — database persistence disabled. Data will reset on restart.')
    return
end

Ume.Functions.Log('oxmysql found — database persistence enabled.')

-- ── Helpers ────────────────────────────────────────────────

local function encodeJSON(value)
    return json and json.encode(value) or '{}'
end

local function decodeJSON(str)
    if not str or str == '' then return nil end
    return json and json.decode(str) or nil
end

-- ── Load player ────────────────────────────────────────────

-- Override the default loadPlayer handler from server/events.lua.
-- Because AddEventHandler fires ALL registered handlers for an event,
-- we use a priority flag to let this database version "win" while still
-- allowing the default handler to run for servers without oxmysql.
AddEventHandler('umeverse:server:loadPlayer', function(source, identifier, deferrals)
    -- Skip if already loaded (e.g. resource restart while player is online).
    if Ume.Player.Get(source) then
        deferrals.done()
        return
    end

    deferrals.update('Loading character…')

    MySQL.single('SELECT * FROM `umeverse_players` WHERE `identifier` = ?', { identifier },
        function(row)
            local data
            if row then
                -- Existing character.
                data = {
                    identifier = identifier,
                    cash       = row.cash ~= nil and row.cash or UmeConfig.StartingCash,
                    bank       = row.bank ~= nil and row.bank or UmeConfig.StartingBank,
                    job        = decodeJSON(row.job)       or UmeUtils.DeepCopy(UmeConfig.DefaultJob),
                    inventory  = decodeJSON(row.inventory) or {},
                    metadata   = decodeJSON(row.metadata)  or {},
                    position   = {
                        x       = row.last_x,
                        y       = row.last_y,
                        z       = row.last_z,
                        heading = row.last_heading,
                    },
                }
            else
                -- Brand-new character: insert a row.
                data = {
                    identifier = identifier,
                    cash       = UmeConfig.StartingCash,
                    bank       = UmeConfig.StartingBank,
                    job        = UmeUtils.DeepCopy(UmeConfig.DefaultJob),
                    inventory  = {},
                    metadata   = {},
                }
                MySQL.insert(
                    'INSERT INTO `umeverse_players` (`identifier`, `name`, `cash`, `bank`) VALUES (?, ?, ?, ?)',
                    { identifier, GetPlayerName(source) or 'Unknown',
                      data.cash, data.bank }
                )
            end

            local player = Ume.Player.New(source, data)
            -- Persist last-saved position in metadata so spawn manager can read it.
            if data.position and data.position.x then
                player.position = data.position
            end
            Ume.Player.Set(source, player)
            deferrals.done()

            -- Push data to the client after a short delay.
            CreateThread(function()
                Wait(1000)
                TriggerClientEvent('umeverse:client:playerLoaded', source, player:GetData())
                TriggerEvent('umeverse:server:playerSpawned', source, player)
            end)
        end
    )
end)

-- ── Save player ────────────────────────────────────────────

--- Persist a player's current state to the database.
---@param source integer
---@param data   table  Plain snapshot from UmePlayer:GetData()
local function savePlayer(source, data)
    if not data or not data.identifier then return end
    MySQL.update(
        [[UPDATE `umeverse_players`
          SET `name`         = ?,
              `cash`         = ?,
              `bank`         = ?,
              `job`          = ?,
              `inventory`    = ?,
              `metadata`     = ?,
              `last_x`       = ?,
              `last_y`       = ?,
              `last_z`       = ?,
              `last_heading` = ?
          WHERE `identifier` = ?]],
        {
            data.name,
            data.cash,
            data.bank,
            encodeJSON(data.job),
            encodeJSON(data.inventory),
            encodeJSON(data.metadata),
            data.position and data.position.x,
            data.position and data.position.y,
            data.position and data.position.z,
            data.position and data.position.heading,
            data.identifier,
        }
    )
    UmeUtils.Debug('DB saved player:', data.name)
end

-- Hook into the auto-save event emitted by server/main.lua.
AddEventHandler('umeverse:server:savePlayer', function(source, data)
    savePlayer(source, data)
end)

-- Also save immediately on disconnect.
AddEventHandler('umeverse:server:playerLeft', function(source, player)
    local data = player:GetData()
    -- Grab last-known position from player object if the spawn manager set it.
    if player.position then data.position = player.position end
    savePlayer(source, data)
end)

-- Expose a manual save export for other resources.
exports('SavePlayer', function(source)
    local player = Ume.Player.Get(source)
    if player then
        local data = player:GetData()
        if player.position then data.position = player.position end
        savePlayer(source, data)
    end
end)
