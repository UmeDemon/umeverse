--[[
    Umeverse Crime System - Bounties Client
    UI for bounty hunting, posting bounties, viewing criminal records
]]

CrimeBountiesClient = {}
CrimeBountiesClient.AvailableBounties = {}
CrimeBountiesClient.PlayerBounties = {}

-- Open bounty board (at police/detective location)
function CrimeBountiesClient.OpenBountyBoard()
    local menuData = {
        title = 'Bounty Board',
        subtitle = 'Active bounties and rewards',
        items = {}
    }
    
    -- Request bounties from server
    TriggerServerEvent('umeverse_crime:getBounties')
    
    Wait(300)
    
    if #CrimeBountiesClient.AvailableBounties == 0 then
        print('^3No active bounties^7')
        return
    end
    
    for i, bounty in ipairs(CrimeBountiesClient.AvailableBounties) do
        table.insert(menuData.items, {
            id = 'bounty_' .. bounty.id,
            title = 'Target: ' .. (bounty.targetName or 'Unknown'),
            description = '$' .. bounty.amount .. ' | Reason: ' .. (bounty.reason or 'Wanted'),
            args = { bountyId = bounty.id },
        })
    end
    
    print('Bounty Board - ' .. #CrimeBountiesClient.AvailableBounties .. ' active bounties')
end

-- Post a bounty on someone
function CrimeBountiesClient.PostBounty()
    local menuData = {
        title = 'Post Bounty',
        subtitle = 'Place a price on someone\'s head',
        items = {
            {id = 'player_input', title = 'Enter Target Identifier'},
            {id = 'amount_input', title = 'Set Bounty Amount ($5,000 - $50,000)'},
            {id = 'reason_input', title = 'Reason for Bounty'},
            {id = 'confirm', title = 'Post Bounty'},
        }
    }
    
    print('Posting bounty...')
    -- Implementation would use framework input system
end

-- Claim a bounty
function CrimeBountiesClient.ClaimBounty(bountyId)
    local function onConfirm(data)
        local targetId = data.target
        
        TriggerServerEvent('umeverse_crime:claimBounty', bountyId, targetId)
    end
    
    print('^2Bounty claimed! Track down your target.^7')
end

-- View criminal record
function CrimeBountiesClient.ViewCriminalRecord(playerIdentifier)
    local menuData = {
        title = 'Criminal Record',
        subtitle = playerIdentifier,
        items = {}
    }
    
    TriggerServerEvent('umeverse_crime:getCriminalRecord', playerIdentifier)
    
    Wait(300)
    
    print('^3=== Criminal Record ===^7')
    print('Identifier: ' .. playerIdentifier)
    print('Last 30 Days Crimes:')
    
    -- Would display actual crimes from server response
    print('- Store Robbery (30 min ago) - $2,500 fine')
    print('- Vehicle Theft (2 hours ago) - $1,200 fine')
end

-- Display bounty notifications
function CrimeBountiesClient.ShowBountyNotification(bountyAmount)
    local notification = {
        type = 'warning',
        title = 'BOUNTY ACTIVE',
        message = 'There is a $' .. bountyAmount .. ' bounty on your head!',
        duration = 10000,
    }
    
    -- TriggerEvent('umeverse_hud:addNotification', notification)
    print('^1BOUNTY ACTIVE: $' .. bountyAmount .. '^7')
end

-- Bounty hunter reputation check
function CrimeBountiesClient.CheckHunterReputation()
    TriggerServerEvent('umeverse_crime:getHunterReputation')
end

-- Bounty expiry warning
function CrimeBountiesClient.CheckBountyExpirations()
    TriggerServerEvent('umeverse_crime:checkBountyExpirations')
end

-- Register event to receive bounties from server
RegisterNetEvent('umeverse_crime:receiveBounties')
AddEventHandler('umeverse_crime:receiveBounties', function(bounties)
    CrimeBountiesClient.AvailableBounties = bounties
    print('Received ' .. #bounties .. ' bounties')
end)

-- Register event to receive criminal record
RegisterNetEvent('umeverse_crime:receiveCriminalRecord')
AddEventHandler('umeverse_crime:receiveCriminalRecord', function(record)
    print('Criminal record retrieved: ' .. #record .. ' entries')
end)

-- Register event for bounty claimed
RegisterNetEvent('umeverse_crime:bountyClaimedNotif')
AddEventHandler('umeverse_crime:bountyClaimedNotif', function(hunterName, amount)
    print('^1BOUNTY CLAIMED by ' .. hunterName .. ' for $' .. amount .. '^7')
end)

-- Register event for safehouse rental
RegisterNetEvent('umeverse_crime:rentSafehouse')
AddEventHandler('umeverse_crime:rentSafehouse', function()
    local menuData = {
        title = 'Rent Safehouse',
        subtitle = '$1,000 per hour (max 1 hour)',
        items = {
            {id = '1h', title = 'Rent for 1 Hour - $1,000'},
            {id = 'cancel', title = 'Cancel'},
        }
    }
    
    print('Safehouse options displayed')
end)

-- Heat amnesty usage (use gang shelter)
RegisterNetEvent('umeverse_crime:useHeatAmnesty')
AddEventHandler('umeverse_crime:useHeatAmnesty', function()
    TriggerServerEvent('umeverse_crime:useHeatAmnesty')
    print('^2Using heat amnesty... (Gang bank: -$5,000)^7')
end)

-- Command to open bounty board
RegisterCommand('bounties', function()
    CrimeBountiesClient.OpenBountyBoard()
end)

print('^2[Umeverse]^7 Crime Bounties Client loaded')
