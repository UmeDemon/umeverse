-- ============================================================
--  UmeVerse Framework — Spawn Manager (client-side)
--  Spawns the local player ped once server data has loaded.
-- ============================================================

local _spawned = false

-- ── Default spawn point ────────────────────────────────────
-- Coordinates in config.lua can override this fallback.
local DEFAULT_SPAWN = { x = -269.4, y = -955.3, z = 31.2, heading = 205.0 }

--- Spawn or teleport the player ped to the given coordinates.
---@param x       number
---@param y       number
---@param z       number
---@param heading number
local function spawnPlayer(x, y, z, heading)
    -- Request the default multiplayer ped model.
    local model = GetHashKey('mp_m_freemode_01')
    RequestModel(model)
    while not HasModelLoaded(model) do
        Wait(10)
    end

    -- Freeze world, fade out, reposition.
    Ume.Functions.FadeOut(500)
    Wait(600)

    SetEntityCoords(PlayerPedId(), x, y, z, false, false, false, false)

    SetEntityHeading(PlayerPedId(), heading)
    SetModelAsNoLongerNeeded(model)
    NetworkResurrectLocalPlayer(x, y, z, heading, true, false)

    -- Un-freeze and fade back in.
    Wait(200)
    Ume.Functions.FadeIn(500)

    _spawned = true
    TriggerEvent('umeverse:client:spawned', x, y, z, heading)
    UmeUtils.Debug('Player spawned at', x, y, z)
end

-- ── Listen for player-data ready ──────────────────────────

AddEventHandler('umeverse:client:ready', function(data)
    if _spawned then return end

    -- Prefer the last saved position from the server; otherwise use config / default.
    local pos = data.position
    local cfg = UmeConfig.SpawnPoint or DEFAULT_SPAWN

    local x       = (pos and pos.x)       or cfg.x
    local y       = (pos and pos.y)       or cfg.y
    local z       = (pos and pos.z)       or cfg.z
    local heading = (pos and pos.heading) or cfg.heading

    CreateThread(function()
        spawnPlayer(x, y, z, heading)
    end)
end)

-- ── Periodically report position to the server ────────────
-- The server stores it so the player can log back in at the same spot.

CreateThread(function()
    while true do
        Wait(30000)   -- every 30 seconds
        if _spawned then
            local ped = PlayerPedId()
            local coords  = GetEntityCoords(ped)
            local heading = GetEntityHeading(ped)
            TriggerServerEvent('umeverse:server:updatePosition',
                coords.x, coords.y, coords.z, heading)
        end
    end
end)
