-- ============================================================
--  UmeVerse Framework — Client Entry Point
-- ============================================================

-- Local player data cache, populated once the server sends it.
local PlayerData = {}
local PlayerLoaded = false

--- Return the local player data table (read-only snapshot from server).
---@return table
function Ume.Functions.GetPlayerData()
    return PlayerData
end

--- Return whether the local player has been fully loaded.
---@return boolean
function Ume.Functions.IsPlayerLoaded()
    return PlayerLoaded
end

--- Set the player-loaded flag (used internally by the event handlers).
---@param state boolean
function Ume.Functions.SetPlayerLoaded(state)
    PlayerLoaded = state
end

-- Inform the server that this client is ready.
AddEventHandler('onClientResourceStart', function(resourceName)
    if resourceName ~= GetCurrentResourceName() then return end
    TriggerServerEvent('umeverse:server:playerLoaded', GetPlayerServerId(PlayerId()), {})
end)
