--[[
    Umeverse Framework - Client Player
    Client-side player management: death, status, spawning
]]

local deathTimer = 0
local lastDeath = 0

-- ═══════════════════════════════════════
-- Death System
-- ═══════════════════════════════════════

--- Monitor player death
CreateThread(function()
    while true do
        Wait(1000)
        if UME.IsLoggedIn() then
            local ped = PlayerPedId()

            if IsEntityDead(ped) and not UME.IsDead() then
                -- Player just died
                UME.SetDead(true)
                deathTimer = UmeConfig.RespawnTime
                lastDeath = GetGameTimer()

                TriggerServerEvent('umeverse:server:playerDied', GetEntityCoords(ped))
                TriggerEvent('umeverse:client:onDeath')
            end

            -- Death timer countdown
            if UME.IsDead() then
                if deathTimer > 0 then
                    deathTimer = deathTimer - 1

                    -- Show death screen
                    SendNUIMessage({
                        action = 'showDeathScreen',
                        timer = deathTimer,
                    })
                end
            end
        end
    end
end)

-- UME.SetDead(state) is defined in client/main.lua where isDead variable lives

--- Respawn
RegisterNUICallback('respawn', function(_, cb)
    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'hideDeathScreen' })

    UME.SetDead(false)
    deathTimer = 0

    local ped = PlayerPedId()
    local coords = UmeConfig.HospitalSpawn

    NetworkResurrectLocalPlayer(coords.x, coords.y, coords.z, coords.w, 0, false)
    SetEntityHealth(ped, GetEntityMaxHealth(ped))
    ClearPedBloodDamage(ped)

    TriggerServerEvent('umeverse:server:playerRespawned')
    TriggerEvent('umeverse:client:notify', _T('death_respawned'), 'info')

    cb('ok')
end)

--- Admin revive
RegisterNetEvent('umeverse:client:revive', function()
    UME.SetDead(false)
    deathTimer = 0

    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)

    NetworkResurrectLocalPlayer(coords.x, coords.y, coords.z, GetEntityHeading(ped), 0, false)
    SetEntityHealth(ped, GetEntityMaxHealth(ped))
    ClearPedBloodDamage(ped)

    SendNUIMessage({ action = 'hideDeathScreen' })
    SetNuiFocus(false, false)

    TriggerEvent('umeverse:client:notify', 'You have been revived.', 'success')
end)

-- ═══════════════════════════════════════
-- Status System (Hunger/Thirst)
-- ═══════════════════════════════════════

CreateThread(function()
    while true do
        Wait(60 * 1000) -- Every minute
        if UME.IsLoggedIn() and not UME.IsDead() and UmeConfig.EnableStatus then
            local playerData = UME.GetPlayerData()
            local status = playerData.status or {}

            -- Decay hunger and thirst
            TriggerServerEvent('umeverse:server:decayStatus')

            -- Client-side warnings
            if status.hunger and status.hunger < 25 then
                TriggerEvent('umeverse:client:notify', _T('status_hungry'), 'warning')
            end
            if status.thirst and status.thirst < 25 then
                TriggerEvent('umeverse:client:notify', _T('status_thirsty'), 'warning')
            end

            -- Damage if critically low
            if status.hunger and status.hunger <= UmeConfig.StatusDamageThreshold then
                local ped = PlayerPedId()
                SetEntityHealth(ped, GetEntityHealth(ped) - 3)
            end
            if status.thirst and status.thirst <= UmeConfig.StatusDamageThreshold then
                local ped = PlayerPedId()
                SetEntityHealth(ped, GetEntityHealth(ped) - 3)
            end
        end
    end
end)

-- ═══════════════════════════════════════
-- Heal Event
-- ═══════════════════════════════════════
RegisterNetEvent('umeverse:client:heal', function(amount)
    local ped = PlayerPedId()
    local currentHealth = GetEntityHealth(ped)
    local maxHealth = GetEntityMaxHealth(ped)
    local newHealth = math.min(currentHealth + amount, maxHealth)
    SetEntityHealth(ped, newHealth)
end)
