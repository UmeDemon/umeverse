--[[
    Umeverse Appearance - Server
    Saves/loads appearance data to the player's skin column
]]

local UME = exports['umeverse_core']:GetCoreObject()

-- Save appearance
RegisterNetEvent('umeverse_appearance:server:saveAppearance', function(appearanceData)
    local src = source
    local player = UME.GetPlayer(src)
    if not player then return end

    player:SetSkin(appearanceData)
    player:Save()

    TriggerClientEvent('umeverse:client:notify', src, 'Appearance saved.', 'success')
end)

-- Load appearance (called when player spawns)
UME.RegisterServerCallback('umeverse_appearance:getAppearance', function(source, cb)
    local player = UME.GetPlayer(source)
    if not player then cb(nil); return end

    local skin = player:GetSkin()
    cb(skin)
end)
