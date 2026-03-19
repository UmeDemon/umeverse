--[[
    Umeverse Crime System - Bounty System
    Bounties on wanted criminals, bounty hunters, criminal records
]]

BountySystem = {}
BountySystem.Bounties = {}
BountySystem.CriminalRecords = {}
BountySystem.HeatRecords = {}

-- Post bounty on player
function BountySystem.PostBounty(src, targetIdentifier, amount, reason)
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return false end
    
    if amount < CrimeConfig.BountySystem.minBounty or amount > CrimeConfig.BountySystem.maxBounty then
        return false, 'Bounty must be between $' .. CrimeConfig.BountySystem.minBounty .. ' and $' .. CrimeConfig.BountySystem.maxBounty
    end
    
    local bountyId = 'bounty_' .. targetIdentifier .. '_' .. os.time()
    
    BountySystem.Bounties[bountyId] = {
        id = bountyId,
        target = targetIdentifier,
        poster = Player.PlayerData.citizenid,
        amount = amount,
        reason = reason or 'Criminal Activity',
        posted = os.time(),
        expires = os.time() + CrimeConfig.BountySystem.bountyDuration,
        claimed = false,
    }
    
    Player.Functions.RemoveMoney('black', amount, 'Bounty Posted')
    
    MySQL.insert('INSERT INTO umeverse_bounties (target_id, poster_id, amount, reason, posted_date, expiry_date) VALUES (?, ?, ?, ?, ?, ?)',
        { targetIdentifier, Player.PlayerData.citizenid, amount, reason, os.time(), os.time() + CrimeConfig.BountySystem.bountyDuration })
    
    return true, 'Bounty posted for $' .. amount
end

-- Claim bounty (kill target)
function BountySystem.ClaimBounty(src, bountyId)
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return false end
    
    if not CrimeConfig.BountySystem.bountyHunters.enabled then
        return false, 'Bounty hunting is disabled'
    end
    
    local crimeRep = Player.PlayerData.metadata.crimeRep or 0
    if crimeRep < CrimeConfig.BountySystem.bountyHunters.hunterLevel then
        return false, 'You need ' .. CrimeConfig.BountySystem.bountyHunters.hunterLevel .. ' crime reputation to claim bounties'
    end
    
    local bounty = BountySystem.Bounties[bountyId]
    if not bounty or bounty.claimed then
        return false, 'Bounty no longer available'
    end
    
    if os.time() > bounty.expires then
        return false, 'Bounty expired'
    end
    
    local reward = math.floor(bounty.amount * CrimeConfig.BountySystem.bountyHunters.hunterReward)
    Player.Functions.AddMoney('black', reward, 'Bounty Claimed')
    
    BountySystem.Bounties[bountyId].claimed = true
    
    MySQL.update('UPDATE umeverse_bounties SET claimed = 1, claimed_by = ?, claimed_date = ? WHERE id = ?',
        { Player.PlayerData.citizenid, os.time(), bountyId })
    
    return true, 'Bounty claimed! Earned $' .. reward
end

-- Log crime to criminal record
function BountySystem.LogCriminalRecord(identifier, crimeType, reward)
    if not CrimeConfig.CriminalRecords.enabled then return end
    
    local record = {
        identifier = identifier,
        crime_type = crimeType,
        reward = reward,
        date = os.time(),
    }
    
    MySQL.insert('INSERT INTO umeverse_criminal_records (identifier, crime_type, reward, crime_date) VALUES (?, ?, ?, ?)',
        { record.identifier, record.crime_type, record.reward, record.date })
end

-- Get criminal record summary
function BountySystem.GetCriminalRecord(identifier)
    local record = { totalCrimes = 0, totalReward = 0, wanted = false, prisonTime = 0 }
    
    MySQL.query('SELECT COUNT(*) as count, SUM(reward) as totalReward FROM umeverse_criminal_records WHERE identifier = ? AND crime_date > ?',
        { identifier, os.time() - (86400 * 30) }, -- Last 30 days
        function(result)
            if result and #result > 0 then
                record.totalCrimes = result[1].count or 0
                record.totalReward = result[1].totalReward or 0
            end
        end
    )
    
    return record
end

-- Heat amnesty (gang protection)
function BountySystem.UseHeatAmnesty(src, gangName)
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return false end
    
    if not CrimeConfig.HeatAmnestySystem.enabled then
        return false, 'Heat amnesty disabled'
    end
    
    local gang = GangSystem and GangSystem.GetPlayerGang(Player.PlayerData.citizenid)
    if not gang or gang.gang ~= gangName then
        return false, 'You must be a gang member to use amnesty'
    end
    
    local gangInfo = GangSystem.GetGangInfo(gangName)
    if (gangInfo.bank or 0) < CrimeConfig.HeatAmnestySystem.amnestyCost then
        return false, 'Gang bank insufficient funds'
    end
    
    -- Deduct from gang bank
    gangInfo.bank = (gangInfo.bank or 0) - CrimeConfig.HeatAmnestySystem.amnestyCost
    
    -- Reduce player heat
    local currentHeat = CrimeSystem.PlayerHeat[src] or 0
    CrimeSystem.PlayerHeat[src] = math.floor(currentHeat * CrimeConfig.HeatAmnestySystem.amnestyPercentage)
    
    TriggerClientEvent('umeverse_crime:notify', src, 'success', 'Heat amnesty activated! Heat reduced by ' ..  math.floor(CrimeConfig.HeatAmnestySystem.amnestyPercentage * 100) .. '%')
    
    return true
end

-- Rent safehouse
function BountySystem.RentSafehouse(src, safehouseIndex, hours)
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return false end
    
    local safehouse = CrimeConfig.SafeHouses.locations[safehouseIndex]
    if not safehouse then return false, 'Safehouse not found' end
    
    local cost = CrimeConfig.SafeHouses.rentCost * hours
    if hours > (CrimeConfig.SafeHouses.maxDuration / 3600) then
        return false, 'Max rental duration is ' .. (CrimeConfig.SafeHouses.maxDuration / 3600) .. ' hours'
    end
    
    local playerMoney = Player.PlayerData.money['black'] or 0
    if playerMoney < cost then
        return false, 'Insufficient black money'
    end
    
    Player.Functions.RemoveMoney('black', cost, 'Safehouse Rental')
    
    local expiryTime = os.time() + (hours * 3600)
    MySQL.insert('INSERT INTO umeverse_safehouse_rentals (player_id, safehouse_id, expiry_time) VALUES (?, ?, ?)',
        { Player.PlayerData.citizenid, safehouseIndex, expiryTime })
    
    TriggerClientEvent('umeverse_crime:notify', src, 'success', 'Rented safehouse for ' .. hours .. ' hours. Cost: $' .. cost)
    
    return true
end

RegisterNetEvent('umeverse_crime:postBounty')
AddEventHandler('umeverse_crime:postBounty', function(targetId, amount, reason)
    local success, msg = BountySystem.PostBounty(source, targetId, amount, reason)
    TriggerClientEvent('umeverse_crime:notify', source, success and 'success' or 'error', msg)
end)

RegisterNetEvent('umeverse_crime:claimBounty')
AddEventHandler('umeverse_crime:claimBounty', function(bountyId)
    local success, msg = BountySystem.ClaimBounty(source, bountyId)
    TriggerClientEvent('umeverse_crime:notify', source, success and 'success' or 'error', msg)
end)

print('^2[Umeverse]^7 Bounty System loaded')
