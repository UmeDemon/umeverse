-- ============================================================
--  UmeVerse Framework — Server Functions
-- ============================================================

local registeredCallbacks = {}

--- Register a server-side callback that clients can invoke.
---@param name    string
---@param handler function  Receives (source, cb, ...) — call cb(...) to respond.
function Ume.Functions.RegisterCallback(name, handler)
    registeredCallbacks[name] = handler
end

--- Trigger a registered server callback from within server code.
---@param name   string
---@param source integer
---@param cb     function
---@param ...    any
function Ume.Functions.TriggerCallback(name, source, cb, ...)
    local handler = registeredCallbacks[name]
    if handler then
        handler(source, cb, ...)
    else
        Ume.Functions.Warn('TriggerCallback: unknown callback "' .. name .. '"')
    end
end

-- Internal: clients request callbacks via this event.
RegisterNetEvent('umeverse:server:triggerCallback', function(name, requestId, ...)
    local source = source  -- luacheck: ignore
    local handler = registeredCallbacks[name]
    if not handler then
        Ume.Functions.Warn('Client requested unknown callback: ' .. name)
        return
    end
    handler(source, function(...)
        TriggerClientEvent('umeverse:client:callbackResponse', source, requestId, ...)
    end, ...)
end)

--- Get the primary identifier string for a connected player.
---@param source integer
---@return string|nil
function Ume.Functions.GetIdentifier(source)
    local idType = UmeConfig.Identifier
    for i = 0, GetNumPlayerIdentifiers(source) - 1 do
        local id = GetPlayerIdentifier(source, i)
        if id and id:find('^' .. idType .. ':') then
            return id
        end
    end
    return nil
end

--- Return the UmePlayer object for a connected player, or nil.
---@param source integer
---@return UmePlayer|nil
function Ume.Functions.GetPlayer(source)
    return Ume.Player.Get(source)
end

--- Return all currently-loaded player objects.
---@return table<integer, UmePlayer>
function Ume.Functions.GetPlayers()
    return Ume.Player.GetAll()
end

--- Broadcast a notification to every online player.
---@param msg      string
---@param notifType string|nil
function Ume.Functions.NotifyAll(msg, notifType)
    TriggerClientEvent('umeverse:client:notify', -1, msg, notifType or 'info')
end

-- Export core functions so other resources can consume them.
exports('GetCoreObject',  function() return Ume end)
exports('GetPlayer',      function(source) return Ume.Functions.GetPlayer(source) end)
exports('GetPlayers',     function() return Ume.Functions.GetPlayers() end)
exports('GetIdentifier',  function(source) return Ume.Functions.GetIdentifier(source) end)
