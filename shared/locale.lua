-- ============================================================
--  UmeVerse Framework — Locale helpers
--  Loaded on both client and server before all other scripts.
-- ============================================================

Locale = {}

-- Loaded translation table, populated by locale/<lang>.lua.
local _translations = {}

--- Load a translation table into the locale system.
---@param translations table  Key/value pairs of translation strings.
function Locale.Load(translations)
    for k, v in pairs(translations) do
        _translations[k] = v
    end
end

--- Translate a key, substituting named placeholders.
--- Placeholders use the {key} syntax, e.g. "Hello {name}!"
---@param key string
---@param vars table|nil   Optional substitution variables.
---@return string
function Locale.T(key, vars)
    local str = _translations[key] or key
    if vars then
        for k, v in pairs(vars) do
            str = str:gsub('{' .. k .. '}', tostring(v))
        end
    end
    return str
end

-- Convenient shorthand alias.
_T = Locale.T
