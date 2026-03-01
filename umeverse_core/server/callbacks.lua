--[[
    Umeverse Framework - Server Callbacks
    Allows client to request data from server asynchronously
]]

local pendingCallbacks = {}

--- Register a server callback
---@param name string
---@param cb function
function UME.RegisterServerCallback(name, cb)
    UME.ServerCallbacks[name] = cb
end

--- Handle incoming callback requests from clients
RegisterNetEvent('umeverse:server:triggerCallback', function(name, requestId, ...)
    local src = source

    if not UME.ServerCallbacks[name] then
        UME.Error('Server callback not found: ' .. name)
        return
    end

    UME.ServerCallbacks[name](src, function(...)
        TriggerClientEvent('umeverse:client:callbackResponse', src, requestId, ...)
    end, ...)
end)

-- ═══════════════════════════════════════
-- Built-in Server Callbacks
-- ═══════════════════════════════════════

--- Get player data callback
UME.RegisterServerCallback('umeverse:getPlayerData', function(source, cb)
    local player = UME.GetPlayer(source)
    if player then
        cb(player:GetClientData())
    else
        cb(nil)
    end
end)

--- Get all online players (for admin)
UME.RegisterServerCallback('umeverse:getOnlinePlayers', function(source, cb)
    local players = {}
    for src, player in pairs(UME.Players) do
        players[#players + 1] = {
            source    = src,
            citizenid = player.citizenid,
            name      = player:GetFullName(),
            job       = player.job.label,
        }
    end
    cb(players)
end)

--- Check if player has item
UME.RegisterServerCallback('umeverse:hasItem', function(source, cb, itemName, amount)
    local player = UME.GetPlayer(source)
    if player then
        cb(player:HasItem(itemName, amount))
    else
        cb(false)
    end
end)

--- Get item count
UME.RegisterServerCallback('umeverse:getItemCount', function(source, cb, itemName)
    local player = UME.GetPlayer(source)
    if player then
        cb(player:GetItemCount(itemName))
    else
        cb(0)
    end
end)

--- Get player money
UME.RegisterServerCallback('umeverse:getMoney', function(source, cb, moneyType)
    local player = UME.GetPlayer(source)
    if player then
        cb(player:GetMoney(moneyType))
    else
        cb(0)
    end
end)
