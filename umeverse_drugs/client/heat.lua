--[[
    Umeverse Drugs - Client Heat System
    Tracks and displays heat level, handles patrol spawns.
]]

local UME = exports['umeverse_core']:GetCoreObject()

local playerHeat = 0
local patrolPeds = {}

-- ═══════════════════════════════════════
-- Sync heat from server
-- ═══════════════════════════════════════

RegisterNetEvent('umeverse_drugs:client:syncHeat', function(heat)
    playerHeat = heat or 0
end)

-- Request heat on load
CreateThread(function()
    if not DrugConfig.Heat.enabled then return end
    Wait(5000)
    TriggerServerEvent('umeverse_drugs:server:requestHeat')
end)

-- ═══════════════════════════════════════
-- Public getter
-- ═══════════════════════════════════════

function GetClientHeat()
    return playerHeat
end

--- Get heat status label
---@return string label, string color
function GetHeatLabel()
    if not DrugConfig.Heat.enabled then return 'Cool', '~w~' end

    local best = nil
    for _, threshold in ipairs(DrugConfig.Heat.thresholds) do
        if playerHeat >= threshold.heat then
            best = threshold
        end
    end

    if best then
        return best.label, '~r~'
    end
    return 'Cool', '~g~'
end

-- ═══════════════════════════════════════
-- Patrol Spawn Thread (high heat)
-- ═══════════════════════════════════════

CreateThread(function()
    if not DrugConfig.Heat.enabled then return end
    Wait(10000)

    while true do
        Wait(DrugConfig.Heat.patrolCheckInterval * 1000)

        if playerHeat >= DrugConfig.Heat.patrolSpawnThreshold then
            local threshold = nil
            for _, t in ipairs(DrugConfig.Heat.thresholds) do
                if playerHeat >= t.heat then
                    threshold = t
                end
            end

            local encMult = threshold and threshold.encounterMult or 1.0
            local chance = math.floor(DrugConfig.Heat.patrolChance * encMult)

            if math.random(100) <= chance then
                SpawnPatrol()
            end
        end
    end
end)

function SpawnPatrol()
    local myPos = GetEntityCoords(PlayerPedId())

    local angle = math.rad(math.random(360))
    local dist = 40.0 + math.random() * 30.0
    local spawnPos = vector3(
        myPos.x + math.cos(angle) * dist,
        myPos.y + math.sin(angle) * dist,
        myPos.z
    )

    local foundGround, groundZ = GetGroundZFor_3dCoord(spawnPos.x, spawnPos.y, spawnPos.z + 50.0, false)
    if foundGround then
        spawnPos = vector3(spawnPos.x, spawnPos.y, groundZ)
    end

    local model = 's_m_y_cop_01'
    local hash = GetHashKey(model)
    RequestModel(hash)
    local timeout = 3000
    while not HasModelLoaded(hash) and timeout > 0 do
        Wait(10)
        timeout = timeout - 10
    end
    if not HasModelLoaded(hash) then return end

    local count = math.random(1, 2)
    for i = 1, count do
        local offset = vector3(math.random(-3, 3), math.random(-3, 3), 0)
        local ped = CreatePed(4, hash, spawnPos.x + offset.x, spawnPos.y + offset.y, spawnPos.z, math.random(360) + 0.0, true, true)
        if ped and ped ~= 0 then
            SetEntityAsMissionEntity(ped, true, true)
            GiveWeaponToPed(ped, GetHashKey('WEAPON_PISTOL'), 100, false, true)
            TaskGoToEntity(ped, PlayerPedId(), -1, 5.0, 2.0, 0, 0)
            SetPedCombatAttributes(ped, 46, true)

            patrolPeds[#patrolPeds + 1] = { ped = ped, despawnAt = GetGameTimer() + 90000 }
        end
    end
    SetModelAsNoLongerNeeded(hash)

    DrugNotify('~r~Police patrol spotted nearby!', 'error')
end

-- Cleanup expired patrol peds
CreateThread(function()
    if not DrugConfig.Heat.enabled then return end

    while true do
        Wait(15000)
        local now = GetGameTimer()
        local alive = {}
        for _, entry in ipairs(patrolPeds) do
            if now < entry.despawnAt and DoesEntityExist(entry.ped) and not IsEntityDead(entry.ped) then
                alive[#alive + 1] = entry
            else
                if DoesEntityExist(entry.ped) then
                    DeleteEntity(entry.ped)
                end
            end
        end
        patrolPeds = alive
    end
end)

-- Cleanup on resource stop
AddEventHandler('onResourceStop', function(resource)
    if resource == GetCurrentResourceName() then
        for _, entry in ipairs(patrolPeds) do
            if DoesEntityExist(entry.ped) then
                DeleteEntity(entry.ped)
            end
        end
        patrolPeds = {}
    end
end)
