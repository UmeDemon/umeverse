--[[
    Umeverse Gangs System - Alliances Client
    UI for forming, accepting, and managing gang alliances
]]

GangAlliancesClient = {}
GangAlliancesClient.ActiveAlliances = {}
GangAlliancesClient.PendingRequests = {}

-- Open alliances menu
function GangAlliancesClient.OpenAlliancesMenu()
    local menuData = {
        title = 'Gang Alliances',
        subtitle = 'Manage diplomatic relations with other gangs',
        items = {
            {id = 'view_active', title = 'View Active Alliances', description = 'Show current alliance agreements'},
            {id = 'view_pending', title = 'View Pending Requests', description = 'See incoming alliance offers'},
            {id = 'form_alliance', title = 'Form New Alliance', description = 'Request alliance with another gang'},
            {id = 'break_alliance', title = 'Break Alliance', description = 'End an alliance agreement'},
        }
    }
    
    TriggerServerEvent('umeverse_gangs:getAlliances')
    
    Wait(300)
    
    print('Alliance Management Menu')
end

-- View active alliances
function GangAlliancesClient.ViewActiveAlliances()
    print('\n^3=== Active Alliances ===^7')
    
    if #GangAlliancesClient.ActiveAlliances == 0 then
        print('^8No active alliances^7')
        return
    end
    
    for i, alliance in ipairs(GangAlliancesClient.ActiveAlliances) do
        local typeConfig = GangsConfig.Alliances.types and GangsConfig.Alliances.types[alliance.type]
        local otherGang = alliance.gang1 == Config.CurrentGang and alliance.gang2 or alliance.gang1
        
        print(i .. '. ^2' .. otherGang .. '^7 (' .. (alliance.type or 'Unknown') .. ')')
        
        if typeConfig then
            print('   Bonuses:')
            print('   + Crime Rewards: +' .. typeConfig.sharedCrimeRewardBoost .. '%')
            print('   + Defense: +10%')
        end
        
        -- Show time remaining
        local timeRemaining = math.floor((alliance.expiresAt - os.time()) / 3600)
        if timeRemaining > 0 then
            print('   Expires in: ' .. timeRemaining .. ' hours')
        end
    end
end

-- View pending alliance requests
function GangAlliancesClient.ViewPendingRequests()
    print('\n^3=== Pending Alliance Requests ===^7')
    
    if #GangAlliancesClient.PendingRequests == 0 then
        print('^8No pending requests^7')
        return
    end
    
    for i, request in ipairs(GangAlliancesClient.PendingRequests) do
        print(i .. '. ^3' .. request.fromGang .. '^7 is requesting:')
        print('   Type: ' .. request.type)
        print('   Command: /acceptalliance ' .. request.id)
    end
end

-- Form new alliance
function GangAlliancesClient.FormAlliance()
    local menuData = {
        title = 'Form Alliance',
        subtitle = 'Select a gang and alliance type',
        items = {}
    }
    
    -- List available gangs (not including your own)
    for gangName, _ in pairs(GangsConfig.Gangs or {}) do
        if gangName ~= Config.CurrentGang then
            table.insert(menuData.items, {
                id = 'gang_' .. gangName,
                title = gangName,
                args = { targetGang = gangName },
            })
        end
    end
    
    print('Select a gang to ally with')
end

-- Alliance type selection
function GangAlliancesClient.SelectAllianceType(targetGang)
    local menuData = {
        title = 'Alliance Type',
        subtitle = 'Select ' .. targetGang,
        items = {}
    }
    
    for allianceType, config in pairs(GangsConfig.Alliances.types or {}) do
        table.insert(menuData.items, {
            id = 'type_' .. allianceType,
            title = config.label,
            description = 'Cost: $' .. config.initialCost .. ' + $' .. (config.dailyCost or 0) .. '/day | Duration: ' .. config.duration .. ' days',
            args = { 
                targetGang = targetGang, 
                allianceType = allianceType,
            },
        })
    end
    
    print('Select alliance type for ' .. targetGang)
end

-- Confirm and send alliance request
function GangAlliancesClient.ConfirmAlliance(targetGang, allianceType)
    local typeConfig = GangsConfig.Alliances.types and GangsConfig.Alliances.types[allianceType]
    if not typeConfig then return end
    
    local cost = typeConfig.initialCost
    
    print('^3Confirming ' .. allianceType .. ' alliance with ' .. targetGang)
    print('Cost: $' .. cost)
    
    TriggerServerEvent('umeverse_gangs:requestAlliance', targetGang, typeConfig.duration, allianceType)
end

-- Accept alliance request
function GangAlliancesClient.AcceptAlliance(allianceId)
    print('^2Accepting alliance request...^7')
    TriggerServerEvent('umeverse_gangs:acceptAlliance', allianceId)
end

-- Break alliance
function GangAlliancesClient.BreakAlliance(allianceId, otherGang)
    print('^1Breaking alliance with ' .. otherGang .. '...^7')
    TriggerServerEvent('umeverse_gangs:breakAlliance', allianceId)
end

-- Display alliance bonuses in HUD
function GangAlliancesClient.DisplayAllianceBonuses()
    print('\n^3=== Alliance Bonuses ===^7')
    
    for _, alliance in ipairs(GangAlliancesClient.ActiveAlliances) do
        if alliance.active then
            local typeConfig = GangsConfig.Alliances.types and GangsConfig.Alliances.types[alliance.type]
            local otherGang = alliance.gang1 == Config.CurrentGang and alliance.gang2 or alliance.gang1
            
            print('^2' .. otherGang .. '^7 (' .. alliance.type .. ')')
            if typeConfig then
                print('  + Crime Rewards: +' .. typeConfig.sharedCrimeRewardBoost .. '%')
                print('  + Defense: +10%')
                if typeConfig.intelSharing then
                    print('  + Intel Sharing: Available')
                end
            end
        end
    end
end

-- Receive alliances from server
RegisterNetEvent('umeverse_gangs:receiveAlliances')
AddEventHandler('umeverse_gangs:receiveAlliances', function(alliances, pending)
    GangAlliancesClient.ActiveAlliances = alliances
    GangAlliancesClient.PendingRequests = pending or {}
    print('Alliances updated: ' .. #alliances .. ' active, ' .. #GangAlliancesClient.PendingRequests .. ' pending')
end)

-- Alliance accepted notification
RegisterNetEvent('umeverse_gangs:allianceAcceptedNotif')
AddEventHandler('umeverse_gangs:allianceAcceptedNotif', function(otherGang)
    print('^2Alliance formed with ' .. otherGang .. '!^7')
end)

-- Alliance broken notification
RegisterNetEvent('umeverse_gangs:allianceBrokenNotif')
AddEventHandler('umeverse_gangs:allianceBrokenNotif', function(otherGang)
    print('^1Alliance with ' .. otherGang .. ' has ended^7')
end)

-- Insufficient funds for alliance
RegisterNetEvent('umeverse_gangs:allianceInsufficientFunds')
AddEventHandler('umeverse_gangs:allianceInsufficientFunds', function(required)
    print('^1Insufficient gang bank funds! Need: $' .. required .. '^7')
end)

-- Commands
RegisterCommand('alliances', function()
    GangAlliancesClient.OpenAlliancesMenu()
end)

RegisterCommand('acceptalliance', function(source, args)
    if args[1] then
        GangAlliancesClient.AcceptAlliance(args[1])
    end
end)

RegisterCommand('breakalliance', function(source, args)
    if args[1] and args[2] then
        GangAlliancesClient.BreakAlliance(args[1], args[2])
    end
end)

print('^2[Umeverse]^7 Gang Alliances Client loaded')
