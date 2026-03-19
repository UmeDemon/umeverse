--[[
    Umeverse Gangs System - Communication
    Safehouse, message board, challenges, weekly/monthly events
]]

GangCommunication = {}
GangCommunication.Challenges = {}
GangCommunication.Tournaments = {}
GangCommunication.MessageCache = {}

-- Post message to gang board (async)
function GangCommunication.PostMessage(src, gangName, title, content, callback)
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then
        if callback then callback(false) end
        return false
    end
    
    local gang = GangSystem.GetPlayerGang(Player.PlayerData.citizenid)
    if not gang or gang.gang ~= gangName then
        if callback then callback(false) end
        return false
    end
    
    MySQL.insert('INSERT INTO umeverse_gang_messages (gang_name, author, title, content, posted_at) VALUES (?, ?, ?, ?, ?)',
        {gangName, Player.PlayerData.name, title, content, os.time()},
        function(lastId)
            if lastId then
                TriggerClientEvent('umeverse_gangs:notify', src, 'success', 'Message posted to gang board')
                GangCommunication.MessageCache[gangName] = nil -- Clear cache
                if callback then callback(true) end
            else
                TriggerClientEvent('umeverse_gangs:notify', src, 'error', 'Failed to post message')
                if callback then callback(false) end
            end
        end
    )
    
    return true
end

-- Get gang board messages (cached, async-friendly)
function GangCommunication.GetMessages(gangName, limit, callback)
    limit = limit or 10
    
    -- Return cached messages immediately
    if GangCommunication.MessageCache[gangName] then
        if callback then
            callback(GangCommunication.MessageCache[gangName])
        end
        return GangCommunication.MessageCache[gangName] or {}
    end
    
    -- Fetch from database asynchronously
    MySQL.query('SELECT * FROM umeverse_gang_messages WHERE gang_name = ? ORDER BY posted_at DESC LIMIT ?',
        {gangName, limit},
        function(result)
            local messages = result or {}
            GangCommunication.MessageCache[gangName] = messages
            if callback then callback(messages) end
        end
    )
    
    return {}
end

-- Weekly challenges (async)
function GangCommunication.StartWeeklyChallenge(gangName, challengeType, target, reward, callback)
    local challenge = {
        id = 'challenge_' .. gangName .. '_' .. os.time(),
        gang = gangName,
        type = challengeType,
        target = target,
        reward = reward,
        startTime = os.time(),
        endTime = os.time() + 604800, -- 7 days
        progress = {},
    }
    
    GangCommunication.Challenges[challenge.id] = challenge
    
    MySQL.insert('INSERT INTO umeverse_gang_challenges (gang_name, type, target, reward, start_time, end_time) VALUES (?, ?, ?, ?, ?, ?)',
        {gangName, challengeType, target, reward, challenge.startTime, challenge.endTime},
        function(lastId)
            if callback then callback(lastId and challenge.id or nil) end
        end
    )
    
    return challenge.id
end

-- Report challenge progress
function GangCommunication.ReportChallengeProgress(src, challengeId, amount)
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return false end
    
    local challenge = GangCommunication.Challenges[challengeId]
    if not challenge then
        return false, 'Challenge not found'
    end
    
    local playerIdentifier = Player.PlayerData.citizenid
    
    if not challenge.progress[playerIdentifier] then
        challenge.progress[playerIdentifier] = 0
    end
    
    challenge.progress[playerIdentifier] = challenge.progress[playerIdentifier] + amount
    
    -- Check if player reached target
    if challenge.progress[playerIdentifier] >= challenge.target then
        Player.Functions.AddMoney('black', challenge.reward, 'Weekly Challenge Reward')
        
        TriggerClientEvent('umeverse_gangs:notify', src, 'success', 'Challenge complete! +$' .. challenge.reward)
        
        challenge.progress[playerIdentifier] = nil -- Reset for next week
    end
    
    return true
end

-- Monthly tournament (all gang crimes) (async)
function GangCommunication.StartMonthlyTournament(gangName, callback)
    local tournament = {
        id = 'tournament_' .. gangName .. '_' .. os.time(),
        gang = gangName,
        startTime = os.time(),
        endTime = os.time() + 2592000, -- 30 days
        leaderboard = {},
    }
    
    GangCommunication.Tournaments[tournament.id] = tournament
    
    MySQL.insert('INSERT INTO umeverse_gang_tournaments (gang_name, start_time, end_time) VALUES (?, ?, ?)',
        {gangName, tournament.startTime, tournament.endTime},
        function(lastId)
            if callback then callback(lastId and tournament.id or nil) end
        end
    )
    
    return tournament.id
end

-- Update tournament leaderboard
function GangCommunication.UpdateTournamentScore(src, tournamentId, points)
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return false end
    
    local tournament = GangCommunication.Tournaments[tournamentId]
    if not tournament then return false end
    
    local playerIdentifier = Player.PlayerData.citizenid
    
    if not tournament.leaderboard[playerIdentifier] then
        tournament.leaderboard[playerIdentifier] = {
            name = Player.PlayerData.name,
            points = 0,
        }
    end
    
    tournament.leaderboard[playerIdentifier].points = tournament.leaderboard[playerIdentifier].points + points
    
    return true
end

-- Get tournament leaderboard
function GangCommunication.GetTournamentLeaderboard(tournamentId, limit)
    limit = limit or 10
    
    local tournament = GangCommunication.Tournaments[tournamentId]
    if not tournament then return {} end
    
    -- Sort by points
    local sorted = {}
    for _, entry in pairs(tournament.leaderboard) do
        table.insert(sorted, entry)
    end
    
    table.sort(sorted, function(a, b)
        return a.points > b.points
    end)
    
    local top = {}
    for i = 1, math.min(limit, #sorted) do
        table.insert(top, sorted[i])
    end
    
    return top
end

-- NPC safehouse bartender interactions
function GangCommunication.InteractWithBartender(src, gangName)
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return false end
    
    local gang = GangSystem.GetPlayerGang(Player.PlayerData.citizenid)
    if not gang or gang.gang ~= gangName then
        return false, 'Not a member of this gang'
    end
    
    TriggerClientEvent('umeverse_gangs:openBartenderMenu', src, gangName)
    
    return true
end

-- Expire challenges and tournaments
Citizen.CreateThread(function()
    while true do
        Wait(3600000) -- Every hour
        
        -- Check for expired challenges
        for challengeId, challenge in pairs(GangCommunication.Challenges) do
            if os.time() >= challenge.endTime then
                GangCommunication.Challenges[challengeId] = nil
            end
        end
        
        -- Check for expired tournaments
        for tournamentId, tournament in pairs(GangCommunication.Tournaments) do
            if os.time() >= tournament.endTime then
                -- Award top 3 prizes (async)
                local leaderboard = GangCommunication.GetTournamentLeaderboard(tournamentId, 3)
                
                for rank, entry in ipairs(leaderboard) do
                    if entry.citizenid then
                        local reward = 10000 * (4 - rank) -- 1st: $30k, 2nd: $20k, 3rd: $10k
                        
                        MySQL.update('UPDATE umeverse_players SET black_money = black_money + ? WHERE citizenid = ?',
                            {reward, entry.citizenid},
                            function(affected)
                                if affected > 0 then
                                    print('^2[Umeverse]^7 Tournament reward processed for ' .. entry.citizenid)
                                end
                            end
                        )
                    end
                end
                
                GangCommunication.Tournaments[tournamentId] = nil
            end
        end
    end
end)

RegisterNetEvent('umeverse_gangs:postGangMessage')
AddEventHandler('umeverse_gangs:postGangMessage', function(gangName, title, content)
    GangCommunication.PostMessage(source, gangName, title, content)
end)

RegisterNetEvent('umeverse_gangs:reportChallengeProgress')
AddEventHandler('umeverse_gangs:reportChallengeProgress', function(challengeId, amount)
    GangCommunication.ReportChallengeProgress(source, challengeId, amount)
end)

RegisterNetEvent('umeverse_gangs:interactBartender')
AddEventHandler('umeverse_gangs:interactBartender', function(gangName)
    GangCommunication.InteractWithBartender(source, gangName)
end)

exports('getGangBoardMessages', function(gangName, limit)
    return GangCommunication.GetMessages(gangName, limit)
end)

print('^2[Umeverse]^7 Gang Communication System loaded')
