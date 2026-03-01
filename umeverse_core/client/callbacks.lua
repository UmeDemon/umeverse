--[[
    Umeverse Framework - Client Callbacks
    Client-side callback system to request data from server
]]

local callbackRequests = {}
local requestId = 0

--- Trigger a server callback from client
---@param name string
---@param cb function
---@vararg any
function UME.TriggerServerCallback(name, cb, ...)
    requestId = requestId + 1
    callbackRequests[requestId] = cb
    TriggerServerEvent('umeverse:server:triggerCallback', name, requestId, ...)
end

--- Handle server callback response
RegisterNetEvent('umeverse:client:callbackResponse', function(reqId, ...)
    if callbackRequests[reqId] then
        callbackRequests[reqId](...)
        callbackRequests[reqId] = nil
    end
end)

-- ═══════════════════════════════════════
-- Client Callbacks (Server can request from client)
-- ═══════════════════════════════════════

--- Register a client callback
---@param name string
---@param cb function
function UME.RegisterClientCallback(name, cb)
    UME.ClientCallbacks[name] = cb
end

--- Handle server requesting a client callback
RegisterNetEvent('umeverse:client:triggerCallback', function(name, reqId, ...)
    if not UME.ClientCallbacks[name] then
        UME.Error('Client callback not found: ' .. name)
        return
    end

    UME.ClientCallbacks[name](function(...)
        TriggerServerEvent('umeverse:server:clientCallbackResponse', reqId, ...)
    end, ...)
end)

-- ═══════════════════════════════════════
-- Built-in Client Callbacks
-- ═══════════════════════════════════════

--- Get player position
UME.RegisterClientCallback('umeverse:getPosition', function(cb)
    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    local heading = GetEntityHeading(ped)
    cb(coords.x, coords.y, coords.z, heading)
end)

--- Get closest player
UME.RegisterClientCallback('umeverse:getClosestPlayer', function(cb, maxDistance)
    maxDistance = maxDistance or 3.0
    local myPed = PlayerPedId()
    local myCoords = GetEntityCoords(myPed)
    local closestPlayer = -1
    local closestDist = maxDistance

    for _, playerId in ipairs(GetActivePlayers()) do
        if playerId ~= PlayerId() then
            local targetPed = GetPlayerPed(playerId)
            local targetCoords = GetEntityCoords(targetPed)
            local dist = #(myCoords - targetCoords)
            if dist < closestDist then
                closestDist = dist
                closestPlayer = GetPlayerServerId(playerId)
            end
        end
    end

    cb(closestPlayer, closestDist)
end)
