--[[
    Umeverse Gangs System - Communication Client
    Gang message board, challenges, tournaments, safehouse
]]

GangCommunicationClient = {}
GangCommunicationClient.Messages = {}
GangCommunicationClient.Challenges = {}
GangCommunicationClient.CurrentTournament = nil

-- Open gang safehouse menu
function GangCommunicationClient.OpenSafehouse()
    local menuData = {
        title = 'Gang Safehouse',
        subtitle = 'Central hub for gang activities',
        items = {
            {id = 'message_board', title = 'Message Board', description = 'View and post gang messages'},
            {id = 'challenges', title = 'Weekly Challenges', description = 'Earn rewards by completing tasks'},
            {id = 'tournament', title = 'Monthly Tournament', description = 'Compete with gang members'},
            {id = 'rivals', title = 'Rival Activity', description = 'Check on rival gang moves'},
            {id = 'bartender', title = 'Talk to Bartender', description = 'Casual conversation'},
        }
    }
    
    print('Gang Safehouse')
end

-- Message board
function GangCommunicationClient.OpenMessageBoard()
    print('\n^3=== Gang Message Board ===^7')
    
    TriggerServerEvent('umeverse_gangs:getGangMessages')
    
    Wait(300)
    
    if #GangCommunicationClient.Messages == 0 then
        print('^8No messages yet^7')
        return
    end
    
    for i, msg in ipairs(GangCommunicationClient.Messages) do
        print(i .. '. ^3' .. msg.author .. '^7: ' .. msg.title)
        print('   ' .. msg.content)
        print('   ^8Posted: ' .. os.date('%Y-%m-%d %H:%M', msg.posted_at) .. '^7\n')
    end
end

-- Post message to board
function GangCommunicationClient.PostMessage()
    local menuData = {
        title = 'Post Message',
        subtitle = 'Share a message with your gang',
        items = {
            {id = 'title', title = 'Enter Title', type = 'input'},
            {id = 'content', title = 'Enter Message', type = 'input'},
            {id = 'confirm', title = 'Post'},
        }
    }
    
    print('Posting message to board...')
end

-- Confirm post message
function GangCommunicationClient.ConfirmPostMessage(title, content)
    TriggerServerEvent('umeverse_gangs:postGangMessage', title, content)
    print('^2Message posted!^7')
end

-- View weekly challenges
function GangCommunicationClient.ViewChallenges()
    print('\n^3=== Weekly Challenges ===^7')
    
    TriggerServerEvent('umeverse_gangs:getWeeklyChallenges')
    
    Wait(300)
    
    if #GangCommunicationClient.Challenges == 0 then
        print('^8No active challenges^7')
        return
    end
    
    for i, challenge in ipairs(GangCommunicationClient.Challenges) do
        print(i .. '. ' .. challenge.name)
        print('   Objective: ' .. challenge.description)
        print('   Progress: ' .. challenge.currentProgress .. '/' .. challenge.target)
        print('   Reward: $' .. challenge.reward)
    end
end

-- Report challenge progress
function GangCommunicationClient.ReportChallengeProgress(challengeId)
    TriggerServerEvent('umeverse_gangs:reportChallengeProgress', challengeId, 1)
end

-- View monthly tournament
function GangCommunicationClient.ViewTournament()
    print('\n^3=== Monthly Tournament ===^7')
    
    TriggerServerEvent('umeverse_gangs:getTournamentLeaderboard')
    
    Wait(500)
    
    if GangCommunicationClient.CurrentTournament == nil then
        print('^8No active tournament^7')
        return
    end
    
    print('Leaderboard:')
    
    local placement = 1
    for _, entry in ipairs(GangCommunicationClient.CurrentTournament) do
        local medal = placement == 1 and '^3🥇^7' or (placement == 2 and '^8🥈^7' or (placement == 3 and '^1🥉^7' or ''))
        print(medal .. ' #' .. placement .. ': ' .. entry.name .. ' - ' .. entry.points .. ' points')
        
        if placement <= 3 then
            local reward = 10000 * (4 - placement)
            print('   💰 Prize: $' .. reward)
        end
        
        placement = placement + 1
    end
end

-- Leaderboard tracking
function GangCommunicationClient.UpdatePersonalStats(stat, amount)
    -- Automatically update when completing crimes/activities
    -- This is called by crime system events
    TriggerServerEvent('umeverse_gangs:updateTournamentScore', amount)
end

-- Bartender interaction
function GangCommunicationClient.TalkToBartender()
    local dialogues = {
        "What'll it be?",
        "Looks like things are heating up out there.",
        "Ever thought about moving up the ranks?",
        "Heard about the new infrastructure upgrades?",
        "The cops have been extra busy today.",
    }
    
    local randomDialogue = dialogues[math.random(#dialogues)]
    print('^3Bartender^7: ' .. randomDialogue)
end

-- Rival gang activity reporter
function GangCommunicationClient.CheckRivalActivity()
    print('\n^3=== Rival Gang Activity ===^7')
    
    TriggerServerEvent('umeverse_gangs:getRivalActivity')
    
    Wait(300)
    
    print('Recent Activity:')
    print('- Ballas taken 15% influence in Strawberry')
    print('- Vagos completed 3 vehicle thefts')
    print('- Families established alliance with Strikers')
end

-- Receive messages from server
RegisterNetEvent('umeverse_gangs:receiveMessages')
AddEventHandler('umeverse_gangs:receiveMessages', function(messages)
    GangCommunicationClient.Messages = messages
    print('Messages received: ' .. #messages)
end)

-- Receive challenges from server
RegisterNetEvent('umeverse_gangs:receiveChallenges')
AddEventHandler('umeverse_gangs:receiveChallenges', function(challenges)
    GangCommunicationClient.Challenges = challenges
    print('Challenges received: ' .. #challenges)
end)

-- Receive tournament leaderboard
RegisterNetEvent('umeverse_gangs:receiveTournamentLeaderboard')
AddEventHandler('umeverse_gangs:receiveTournamentLeaderboard', function(leaderboard)
    GangCommunicationClient.CurrentTournament = leaderboard
    print('Tournament leaderboard updated')
end)

-- Challenge completed notification
RegisterNetEvent('umeverse_gangs:challengeCompletedNotif')
AddEventHandler('umeverse_gangs:challengeCompletedNotif', function(challengeName, reward)
    print('^2Challenge Complete: ' .. challengeName .. ' +$' .. reward .. '^7')
end)

-- Tournament rank update notification
RegisterNetEvent('umeverse_gangs:tournamentRankUpdate')
AddEventHandler('umeverse_gangs:tournamentRankUpdate', function(rank, points)
    if rank == 1 then
        print('^2🎯 You are #1 in the tournament!^7')
    else
        print('Tournament Position: #' .. rank .. ' (' .. points .. ' points)')
    end
end)

-- Message posted notification
RegisterNetEvent('umeverse_gangs:messagePostedNotif')
AddEventHandler('umeverse_gangs:messagePostedNotif', function()
    print('^2Message posted to gang board!^7')
end)

-- New message notification
RegisterNetEvent('umeverse_gangs:newMessageNotif')
AddEventHandler('umeverse_gangs:newMessageNotif', function(author, title)
    print('^3New message from ' .. author .. ': ' .. title .. '^7')
end)

-- Commands
RegisterCommand('safehouse', function()
    GangCommunicationClient.OpenSafehouse()
end)

RegisterCommand('gangboard', function()
    GangCommunicationClient.OpenMessageBoard()
end)

RegisterCommand('gangchallenges', function()
    GangCommunicationClient.ViewChallenges()
end)

RegisterCommand('gangtournament', function()
    GangCommunicationClient.ViewTournament()
end)

print('^2[Umeverse]^7 Gang Communication Client loaded')
