-- ============================================================
--  UmeVerse Framework — Server Event Handlers
-- ============================================================

-- ── Player connecting ──────────────────────────────────────

AddEventHandler('playerConnecting', function(name, setKickReason, deferrals)
    local source = source  -- luacheck: ignore
    deferrals.defer()
    Wait(0)

    local identifier = Ume.Functions.GetIdentifier(source)
    if not identifier then
        deferrals.done(_T('no_permission'))
        return
    end

    -- Emit an event so a database bridge can load or create the character.
    -- The bridge should respond by triggering 'umeverse:server:playerLoaded'.
    TriggerEvent('umeverse:server:loadPlayer', source, identifier, deferrals)
end)

-- ── Player loaded (called by database bridge or default handler) ──

RegisterNetEvent('umeverse:server:playerLoaded', function(source, data)
    local identifier = Ume.Functions.GetIdentifier(source)
    if not identifier then return end

    data = data or {}
    data.identifier = identifier

    local player = Ume.Player.New(source, data)
    Ume.Player.Set(source, player)

    -- Notify the client that the player data is ready.
    TriggerClientEvent('umeverse:client:playerLoaded', source, player:GetData())
    TriggerEvent('umeverse:server:playerSpawned', source, player)

    Ume.Functions.Log(('Player loaded: %s (%s)'):format(player.name, identifier))
end)

-- Default handler — used when no external database bridge is present.
-- Immediately acknowledges the deferral with default character data.
AddEventHandler('umeverse:server:loadPlayer', function(source, identifier, deferrals)
    if Ume.Player.Get(source) then
        -- Already loaded (e.g. reconnect within same session).
        deferrals.done()
        return
    end

    -- Build a default new-player data record.
    local defaultData = {
        identifier = identifier,
        cash       = UmeConfig.StartingCash,
        bank       = UmeConfig.StartingBank,
        job        = UmeUtils.DeepCopy(UmeConfig.DefaultJob),
        inventory  = {},
        metadata   = {},
    }

    local player = Ume.Player.New(source, defaultData)
    Ume.Player.Set(source, player)

    deferrals.done()

    -- Give the client a moment to finish loading its scripts before we push
    -- player data. Without this brief pause the client-side handler may not
    -- yet be registered when the event fires.
    CreateThread(function()
        Wait(1000)
        TriggerClientEvent('umeverse:client:playerLoaded', source, player:GetData())
        TriggerEvent('umeverse:server:playerSpawned', source, player)
    end)
end)

-- ── Player dropping ───────────────────────────────────────

AddEventHandler('playerDropped', function(reason)
    local source = source  -- luacheck: ignore
    local player = Ume.Player.Get(source)
    if player then
        TriggerEvent('umeverse:server:playerLeft', source, player, reason)
        Ume.Functions.Log(('Player dropped: %s — %s'):format(player.name, reason))
        Ume.Player.Remove(source)
    end
end)

-- ── Server-side callbacks ─────────────────────────────────

-- Allow clients to request the current player data.
Ume.Functions.RegisterCallback('umeverse:getPlayerData', function(source, cb)
    local player = Ume.Player.Get(source)
    cb(player and player:GetData() or nil)
end)
