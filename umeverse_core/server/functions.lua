--[[
    Umeverse Framework - Server Functions
    Utility functions for server-side operations
]]

--- Log an action to Discord webhook
---@param title string
---@param message string
---@param color number|nil
function UME.Log(title, message, color)
    if not UmeConfig.EnableLogging or UmeConfig.LogWebhook == '' then return end

    color = color or 3447003 -- Blue default

    PerformHttpRequest(UmeConfig.LogWebhook, function() end, 'POST', json.encode({
        embeds = {{
            title       = title,
            description = message,
            color       = color,
            footer      = { text = 'Umeverse Framework | ' .. os.date('%Y-%m-%d %H:%M:%S') },
        }},
    }), { ['Content-Type'] = 'application/json' })
end

--- Send a notification to a specific player
---@param source number
---@param message string
---@param type string 'success' | 'error' | 'info' | 'warning'
---@param duration number|nil
function UME.Notify(source, message, type, duration)
    TriggerClientEvent('umeverse:client:notify', source, message, type or 'info', duration or 5000)
end

--- Send a notification to all players
---@param message string
---@param type string
function UME.NotifyAll(message, type)
    TriggerClientEvent('umeverse:client:notify', -1, message, type or 'info')
end

--- Transfer money between two players
---@param senderId number
---@param receiverId number
---@param amount number
---@param moneyType string
---@return boolean
function UME.TransferMoney(senderId, receiverId, amount, moneyType)
    moneyType = moneyType or 'cash'
    local sender = UME.GetPlayer(senderId)
    local receiver = UME.GetPlayer(receiverId)

    if not sender or not receiver then return false end
    if not sender:HasMoney(moneyType, amount) then return false end

    sender:RemoveMoney(moneyType, amount, 'Transfer to ' .. receiver:GetFullName())
    receiver:AddMoney(moneyType, amount, 'Transfer from ' .. sender:GetFullName())

    return true
end

--- Get all players with a specific job
---@param jobName string
---@return table
function UME.GetPlayersWithJob(jobName)
    local result = {}
    for src, player in pairs(UME.Players) do
        if player.job.name == jobName then
            result[#result + 1] = player
        end
    end
    return result
end

--- Get all players on duty for a job
---@param jobName string
---@return table
function UME.GetOnDutyPlayers(jobName)
    local result = {}
    for src, player in pairs(UME.Players) do
        if player.job.name == jobName and player.job.onduty then
            result[#result + 1] = player
        end
    end
    return result
end

--- Count on duty players for a job type (e.g. 'leo', 'ems')
---@param jobType string
---@return number
function UME.GetOnDutyCountByType(jobType)
    local count = 0
    for _, player in pairs(UME.Players) do
        if player.job.type == jobType and player.job.onduty then
            count = count + 1
        end
    end
    return count
end

--- Register a usable item (server-side callback when item is used)
---@param itemName string
---@param cb function
function UME.RegisterUsableItem(itemName, cb)
    RegisterNetEvent('umeverse:server:useItem:' .. itemName, function(forwardedSource)
        -- Source can come from direct client trigger or from inventory forwarding
        local src = forwardedSource or source
        local player = UME.GetPlayer(src)
        if player and player:HasItem(itemName) then
            cb(src, player, itemName)
        end
    end)
end

-- ═══════════════════════════════════════
-- Built-in Usable Items
-- ═══════════════════════════════════════

--- Food items restore hunger
UME.RegisterUsableItem('bread', function(src, player)
    player:RemoveItem('bread', 1)
    player:AddStatus('hunger', 25)
    UME.Notify(src, _T('item_used', 'Bread'), 'success')
end)

UME.RegisterUsableItem('burger', function(src, player)
    player:RemoveItem('burger', 1)
    player:AddStatus('hunger', 40)
    UME.Notify(src, _T('item_used', 'Burger'), 'success')
end)

UME.RegisterUsableItem('sandwich', function(src, player)
    player:RemoveItem('sandwich', 1)
    player:AddStatus('hunger', 35)
    UME.Notify(src, _T('item_used', 'Sandwich'), 'success')
end)

UME.RegisterUsableItem('donut', function(src, player)
    player:RemoveItem('donut', 1)
    player:AddStatus('hunger', 15)
    UME.Notify(src, _T('item_used', 'Donut'), 'success')
end)

--- Drink items restore thirst
UME.RegisterUsableItem('water', function(src, player)
    player:RemoveItem('water', 1)
    player:AddStatus('thirst', 35)
    UME.Notify(src, _T('item_used', 'Water Bottle'), 'success')
end)

UME.RegisterUsableItem('cola', function(src, player)
    player:RemoveItem('cola', 1)
    player:AddStatus('thirst', 25)
    UME.Notify(src, _T('item_used', 'Cola'), 'success')
end)

UME.RegisterUsableItem('coffee', function(src, player)
    player:RemoveItem('coffee', 1)
    player:AddStatus('thirst', 30)
    UME.Notify(src, _T('item_used', 'Coffee'), 'success')
end)

--- Medical items
UME.RegisterUsableItem('bandage', function(src, player)
    player:RemoveItem('bandage', 1)
    TriggerClientEvent('umeverse:client:heal', src, 15)
    UME.Notify(src, _T('item_used', 'Bandage'), 'success')
end)

UME.RegisterUsableItem('medikit', function(src, player)
    player:RemoveItem('medikit', 1)
    TriggerClientEvent('umeverse:client:heal', src, 50)
    UME.Notify(src, _T('item_used', 'First Aid Kit'), 'success')
end)

UME.RegisterUsableItem('painkillers', function(src, player)
    player:RemoveItem('painkillers', 1)
    TriggerClientEvent('umeverse:client:heal', src, 25)
    UME.Notify(src, _T('item_used', 'Painkillers'), 'success')
end)
