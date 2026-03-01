-- ============================================================
--  UmeVerse Framework — Server Entry Point
-- ============================================================

Ume.Functions.Log(('Version %s starting…'):format(Ume.Version))

-- Load the locale file server-side.
local lang = UmeConfig.Locale or 'en'
local raw  = LoadResourceFile(GetCurrentResourceName(), 'locale/' .. lang .. '.lua')
if raw then
    local fn, err = load(raw, 'locale/' .. lang .. '.lua', 't', _ENV)
    if fn then
        fn()
    else
        Ume.Functions.Error('Failed to load locale: ' .. tostring(err))
    end
end

-- ── Auto-save loop ─────────────────────────────────────────

CreateThread(function()
    while true do
        Wait(UmeConfig.AutoSaveInterval)
        for source, player in pairs(Ume.Player.GetAll()) do
            -- Emit an event so other resources (e.g. a database bridge) can
            -- persist the player data. The event carries a plain-table snapshot.
            TriggerEvent('umeverse:server:savePlayer', source, player:GetData())
            UmeUtils.Debug('Auto-saved player', player.name, '(' .. source .. ')')
        end
    end
end)

Ume.Functions.Log('Framework ready.')
