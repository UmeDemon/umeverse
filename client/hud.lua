-- ============================================================
--  UmeVerse Framework — HUD Controller (client-side)
--  Sends player stats to the NUI HUD on a regular tick.
-- ============================================================

local _hudVisible = true
local _lastCash   = -1
local _lastHealth = -1
local _lastArmour = -1

--- Show or hide the HUD overlay.
---@param state boolean
function Ume.Functions.SetHudVisible(state)
    _hudVisible = state
    SendNUIMessage({ action = 'hudVisible', visible = state })
end

-- ── Tick: push stats to NUI ────────────────────────────────

CreateThread(function()
    while true do
        Wait(500)   -- update every 500 ms

        if not Ume.Functions.IsPlayerLoaded() then goto continue end
        if not _hudVisible then goto continue end

        local ped    = PlayerPedId()
        local maxHp  = math.max(1, GetEntityMaxHealth(ped) - 100)
        local health = math.floor(math.max(0, GetEntityHealth(ped) - 100) / maxHp * 100)
        local armour = GetPedArmour(ped)
        local cash   = Ume.Functions.GetPlayerData().cash or 0

        -- Only push a NUI message when something changed, to reduce CPU usage.
        if health ~= _lastHealth or armour ~= _lastArmour or cash ~= _lastCash then
            _lastHealth = health
            _lastArmour = armour
            _lastCash   = cash

            SendNUIMessage({
                action = 'hudUpdate',
                health = health,
                armour = armour,
                cash   = UmeUtils.FormatMoney(cash),
            })
        end

        ::continue::
    end
end)

-- Hide HUD on death; show it again on respawn.
AddEventHandler('gameEventTriggered', function(name, args)
    if name == 'CEventNetworkEntityDamage' then
        local ped = PlayerPedId()
        if IsPedDeadOrDying(ped, true) then
            Ume.Functions.SetHudVisible(false)
        end
    end
end)

AddEventHandler('umeverse:client:spawned', function()
    Ume.Functions.SetHudVisible(true)
end)
