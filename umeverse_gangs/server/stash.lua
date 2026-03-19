--[[
    Gangs System - Stash Management
]]

GangStash = {}

-- Deposit items to gang stash
function GangStash.DepositItems(src, gangName, items)
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return false end
    
    for itemName, amount in pairs(items) do
        Player.Functions.RemoveItem(itemName, amount)
    end
    
    MySQL.insert('INSERT INTO umeverse_gang_stash (gang_name, items) VALUES (?, ?) ON DUPLICATE KEY UPDATE items = JSON_SET(items, ?, ?)',
        { gangName, json.encode(items), '$.' .. key, amount })
    
    return true
end

-- Withdraw items from gang stash
function GangStash.WithdrawItems(src, gangName, items)
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return false end
    
    for itemName, amount in pairs(items) do
        Player.Functions.AddItem(itemName, amount)
    end
    
    return true
end

print('^2[Umeverse]^7 Gang Stash System loaded')
