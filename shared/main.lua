-- ============================================================
--  UmeVerse Framework — Shared Core Object
--  Exposes the top-level `Ume` table used throughout the framework.
-- ============================================================

Ume = {
    -- Framework metadata
    Name    = 'UmeVerse',
    Version = '1.0.0',

    -- Sub-namespaces populated by server/client scripts.
    Functions = {},
    Callbacks = {},
    Config    = UmeConfig,
    Utils     = UmeUtils,
    Locale    = Locale,
}

--- Register a named callback that can be triggered from the opposite side.
--- On the server, handlers receive (source, cb, ...).
--- On the client,  handlers receive (cb, ...).
---@param name    string
---@param handler function
function Ume.Callbacks:Register(name, handler)
    self[name] = handler
end

--- Log an informational message with a framework prefix.
---@param msg string
function Ume.Functions.Log(msg)
    print(('[UmeVerse] %s'):format(tostring(msg)))
end

--- Log a warning message.
---@param msg string
function Ume.Functions.Warn(msg)
    print(('[UmeVerse][WARN] %s'):format(tostring(msg)))
end

--- Log an error message.
---@param msg string
function Ume.Functions.Error(msg)
    print(('[UmeVerse][ERROR] %s'):format(tostring(msg)))
end

-- Load the locale file selected in config (server will also load via files[]).
-- On the client the locale data is embedded via the `files` directive.
if IsDuplicityVersion ~= nil and not IsDuplicityVersion() then
    -- Client-side: locale file is available through LoadResourceFile.
    local lang = (UmeConfig and UmeConfig.Locale) or 'en'
    local raw  = LoadResourceFile(GetCurrentResourceName(), 'locale/' .. lang .. '.lua')
    if raw then
        local fn, err = load(raw, 'locale/' .. lang .. '.lua', 't', _ENV)
        if fn then fn() else Ume.Functions.Warn('Locale load error: ' .. tostring(err)) end
    end
end
