--[[
    Umeverse Framework - Client Main
    Core client initialization and event handling
]]

local PlayerData = {}
local isLoggedIn = false
local isDead = false

--- Get the current player data on client
---@return table
function UME.GetPlayerData()
    return PlayerData
end

--- Check if player is logged in
---@return boolean
function UME.IsLoggedIn()
    return isLoggedIn
end

--- Check if player is dead
---@return boolean
function UME.IsDead()
    return isDead
end

--- Set player dead state (called from player.lua)
---@param state boolean
function UME.SetDead(state)
    isDead = state
end

-- ═══════════════════════════════════════
-- Initialization
-- ═══════════════════════════════════════

--- On resource start, request player load
AddEventHandler('onClientResourceStart', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    Wait(1000) -- Wait for server scripts to initialize
    TriggerServerEvent('umeverse:server:playerLoaded')
end)

-- ═══════════════════════════════════════
-- Player Data Events
-- ═══════════════════════════════════════

--- Player loaded with character data
RegisterNetEvent('umeverse:client:playerLoaded', function(data)
    PlayerData = data
    isLoggedIn = true

    -- Load player model
    local model = GetHashKey(UmeConfig.DefaultModel)
    RequestModel(model)
    local timeout = 5000
    while not HasModelLoaded(model) and timeout > 0 do
        Wait(10)
        timeout = timeout - 10
    end
    if HasModelLoaded(model) then
        SetPlayerModel(PlayerId(), model)
        SetModelAsNoLongerNeeded(model)
    end

    -- Spawn player at saved position
    local pos = data.position
    if pos then
        local ped = PlayerPedId()

        -- Freeze and set position
        SetEntityCoords(ped, pos.x, pos.y, pos.z, false, false, false, false)
        SetEntityHeading(ped, pos.heading or 0.0)
        FreezeEntityPosition(ped, false)
    end

    -- PvP setting
    SetCanAttackFriendly(PlayerPedId(), UmeConfig.EnablePvP, false)
    NetworkSetFriendlyFireOption(UmeConfig.EnablePvP)

    -- Remove default weapon
    RemoveAllPedWeapons(PlayerPedId(), true)

    -- Notify
    TriggerEvent('umeverse:client:notify', string.format(_T('player_loaded'), UmeConfig.ServerName), 'success')

    -- Trigger loaded event for other resources
    TriggerEvent('umeverse:client:playerLoaded:done', PlayerData)

    UME.Debug('Player loaded on client: ' .. (data.firstname or '') .. ' ' .. (data.lastname or ''))
end)

--- Money updated
RegisterNetEvent('umeverse:client:updateMoney', function(money, moneyType, amount, action)
    PlayerData.money = money
    TriggerEvent('umeverse:client:moneyChanged', moneyType, amount, action)
end)

--- Job updated
RegisterNetEvent('umeverse:client:updateJob', function(job)
    PlayerData.job = job
    TriggerEvent('umeverse:client:jobChanged', job)
end)

--- Inventory updated
RegisterNetEvent('umeverse:client:updateInventory', function(inventory)
    PlayerData.inventory = inventory
end)

--- Status updated
RegisterNetEvent('umeverse:client:updateStatus', function(status)
    PlayerData.status = status
end)

--- Metadata updated
RegisterNetEvent('umeverse:client:updateMetadata', function(metadata)
    PlayerData.metadata = metadata
end)

--- Logout
RegisterNetEvent('umeverse:client:logout', function()
    PlayerData = {}
    isLoggedIn = false
    isDead = false

    -- Return to character select or disconnect
    if UmeConfig.EnableMulticharacter then
        TriggerServerEvent('umeverse:server:playerLoaded')
    else
        TriggerEvent('umeverse:client:notify', _T('player_logout'), 'info')
    end
end)

-- ═══════════════════════════════════════
-- Character Selection / Creation NUI
-- ═══════════════════════════════════════

RegisterNetEvent('umeverse:client:selectCharacter', function(characters)
    SetNuiFocus(true, true)
    SendNUIMessage({
        action     = 'showCharacterSelect',
        characters = characters,
        maxSlots   = UmeConfig.MaxCharacters,
        serverName = UmeConfig.ServerName,
    })
end)

RegisterNetEvent('umeverse:client:createCharacter', function()
    SetNuiFocus(true, true)
    SendNUIMessage({
        action     = 'showCharacterCreate',
        serverName = UmeConfig.ServerName,
    })
end)

--- NUI callbacks
RegisterNUICallback('selectCharacter', function(data, cb)
    SetNuiFocus(false, false)
    TriggerServerEvent('umeverse:server:loadCharacter', data.citizenid)
    cb('ok')
end)

RegisterNUICallback('createCharacter', function(data, cb)
    SetNuiFocus(false, false)
    TriggerServerEvent('umeverse:server:createCharacter', {
        firstname = data.firstname,
        lastname  = data.lastname,
        charinfo  = {
            gender      = data.gender or 'male',
            birthdate   = data.birthdate or '1990-01-01',
            nationality = data.nationality or 'American',
        },
    })
    cb('ok')
end)

RegisterNUICallback('deleteCharacter', function(data, cb)
    TriggerServerEvent('umeverse:server:deleteCharacter', data.citizenid)
    cb('ok')
end)

RegisterNUICallback('closeUI', function(_, cb)
    SetNuiFocus(false, false)
    cb('ok')
end)

-- ═══════════════════════════════════════
-- Position Saving Thread
-- ═══════════════════════════════════════
CreateThread(function()
    while true do
        Wait(30000) -- Every 30 seconds
        if isLoggedIn and not isDead then
            local ped = PlayerPedId()
            local coords = GetEntityCoords(ped)
            local heading = GetEntityHeading(ped)
            TriggerServerEvent('umeverse:server:updatePosition', {
                x = coords.x,
                y = coords.y,
                z = coords.z,
                heading = heading,
            })
        end
    end
end)

-- ═══════════════════════════════════════
-- Exports
-- ═══════════════════════════════════════
exports('GetPlayerData', function()
    return PlayerData
end)

exports('IsLoggedIn', function()
    return isLoggedIn
end)

exports('GetCoreObject', function()
    return UME
end)
