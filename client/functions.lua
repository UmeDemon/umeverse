-- ============================================================
--  UmeVerse Framework — Client Functions
-- ============================================================

local _callbackCounter = 0
local _pendingCallbacks = {}

--- Trigger a named server-side callback and handle the response asynchronously.
---@param name string
---@param cb   function  Called with the server's response values.
---@param ...  any       Extra arguments forwarded to the server handler.
function Ume.Functions.TriggerCallback(name, cb, ...)
    _callbackCounter = _callbackCounter + 1
    local requestId  = _callbackCounter
    _pendingCallbacks[requestId] = cb
    TriggerServerEvent('umeverse:server:triggerCallback', name, requestId, ...)
end

-- Internal: receive callback responses from the server.
RegisterNetEvent('umeverse:client:callbackResponse', function(requestId, ...)
    local cb = _pendingCallbacks[requestId]
    if cb then
        _pendingCallbacks[requestId] = nil
        cb(...)
    end
end)

--- Display an on-screen notification.
--- Uses SendNUIMessage so the HTML overlay can render styled toasts.
---@param msg      string
---@param notifType string|nil  'success'|'error'|'info'|'warning'
function Ume.Functions.Notify(msg, notifType)
    SendNUIMessage({
        action  = 'notify',
        message = msg,
        type    = notifType or 'info',
    })
end

--- Display a help text hint above the minimap.
---@param msg string
function Ume.Functions.ShowHelpText(msg)
    BeginTextCommandDisplayHelp('STRING')
    AddTextComponentSubstringPlayerName(msg)
    EndTextCommandDisplayHelp(0, false, true, -1)
end

--- Draw 3-D text at a world position.
---@param x     number
---@param y     number
---@param z     number
---@param text  string
---@param scale number|nil  Default 0.4
function Ume.Functions.DrawText3D(x, y, z, text, scale)
    scale = scale or 0.4
    local onScreen, screenX, screenY = World3dToScreen2d(x, y, z)
    if not onScreen then return end

    SetTextScale(scale, scale)
    SetTextFont(4)
    SetTextProportional(true)
    SetTextColour(255, 255, 255, 215)
    SetTextEntry('STRING')
    SetTextCentre(true)
    AddTextComponentString(text)
    DrawText(screenX, screenY)
end

--- Fade the screen in over `ms` milliseconds.
---@param ms integer
function Ume.Functions.FadeIn(ms)
    DoScreenFadeIn(ms)
end

--- Fade the screen out over `ms` milliseconds.
---@param ms integer
function Ume.Functions.FadeOut(ms)
    DoScreenFadeOut(ms)
end
