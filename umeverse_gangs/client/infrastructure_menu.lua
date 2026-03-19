--[[
    Umeverse Gangs System - Infrastructure Client
    UI for purchasing and managing gang infrastructure upgrades
]]

GangInfrastructureClient = {}
GangInfrastructureClient.GangInfra = {}
GangInfrastructureClient.SelectedType = nil

-- Open infrastructure menu
function GangInfrastructureClient.OpenInfraMenu()
    local menuData = {
        title = 'Gang Infrastructure',
        subtitle = 'Upgrade your gang\'s operations',
        items = {}
    }
    
    TriggerServerEvent('umeverse_gangs:getInfrastructureStatus')
    
    Wait(300)
    
    -- Display infrastructure types
    for infraType, config in pairs(GangsConfig.Infrastructure.types or {}) do
        local currentLevel = GangInfrastructureClient.GangInfra[infraType] or {level = 1}
        local nextCost = config.costPerLevel * currentLevel.level
        
        table.insert(menuData.items, {
            id = 'infra_' .. infraType,
            title = config.label,
            description = 'Level ' .. currentLevel.level .. '/' .. config.maxLevel .. ' | Next Cost: $' .. nextCost,
            args = { infraType = infraType },
        })
    end
    
    print('Gang Infrastructure Menu:')
    for _, item in ipairs(menuData.items) do
        print('- ' .. item.title .. ' (Level ' .. (item.args.infraType or 'N/A') .. ')')
    end
end

-- View specific infrastructure details
function GangInfrastructureClient.ViewInfraDetails(infraType)
    local config = GangsConfig.Infrastructure.types and GangsConfig.Infrastructure.types[infraType]
    if not config then return end
    
    local current = GangInfrastructureClient.GangInfra[infraType] or {level = 1}
    
    print('\n^3=== ' .. config.label .. ' ===^7')
    print('Current Level: ' .. current.level .. '/' .. config.maxLevel)
    print('Bonus Per Level: +' .. config.bonusPerLevel .. '%')
    print('Max Bonus: ' .. ((config.maxLevel - 1) * config.bonusPerLevel) .. '%')
    print('')
    print('Level Progression:')
    
    for level = 1, config.maxLevel do
        local cost = config.costPerLevel * (level - 1)
        local bonus = (level - 1) * config.bonusPerLevel
        local isCurrentOrPassed = level <= current.level
        local status = isCurrentOrPassed and '^2✓^7' or '^8○^7'
        
        print(status .. ' Level ' .. level .. ' - Bonus: ' .. bonus .. '% - Cost: $' .. cost)
    end
end

-- Upgrade infrastructure
function GangInfrastructureClient.UpgradeInfra(infraType)
    local config = GangsConfig.Infrastructure.types and GangsConfig.Infrastructure.types[infraType]
    if not config then return end
    
    local current = GangInfrastructureClient.GangInfra[infraType] or {level = 1}
    
    if current.level >= config.maxLevel then
        print('^1This infrastructure is already maxed out!^7')
        return
    end
    
    local nextCost = config.costPerLevel * current.level
    
    local menuData = {
        title = 'Confirm Upgrade',
        subtitle = config.label .. ' Level ' .. (current.level + 1),
        items = {
            {id = 'confirm', title = 'Upgrade for $' .. nextCost},
            {id = 'cancel', title = 'Cancel'},
        }
    }
    
    print('^3Upgrading ' .. config.label .. ' to level ' .. (current.level + 1) .. ' for $' .. nextCost .. '^7')
    TriggerServerEvent('umeverse_gangs:upgradeInfrastructure', infraType)
end

-- Display infrastructure effects on crimes
function GangInfrastructureClient.ShowInfraBonuses()
    print('\n^2=== Active Infrastructure Bonuses ===^7')
    
    for infraType, current in pairs(GangInfrastructureClient.GangInfra or {}) do
        if current.level > 1 then
            local config = GangsConfig.Infrastructure.types and GangsConfig.Infrastructure.types[infraType]
            if config then
                local bonus = (current.level - 1) * config.bonusPerLevel
                print('+ ' .. config.label .. ' (L' .. current.level .. '): +'  .. bonus .. '%')
            end
        end
    end
end

-- Infrastructure progress display (for HUD)
function GangInfrastructureClient.DisplayProgressBar(infraType, currentXP, maxXP)
    -- Visual representation of upgrade progress
    local percentage = math.floor((currentXP / maxXP) * 100)
    local bars = math.floor(percentage / 10)
    
    local progressBar = '^2['
    for i = 1, 10 do
        if i <= bars then
            progressBar = progressBar .. '█'
        else
            progressBar = progressBar .. '░'
        end
    end
    progressBar = progressBar .. '] ' .. percentage .. '%^7'
    
    print(infraType .. ' Progress: ' .. progressBar)
end

-- Notify on infrastructure upgrade
RegisterNetEvent('umeverse_gangs:infraUpgradeNotif')
AddEventHandler('umeverse_gangs:infraUpgradeNotif', function(infraType, newLevel)
    print('^2Infrastructure upgraded! ' .. infraType .. ' is now Level ' .. newLevel .. '^7')
    TriggerServerEvent('umeverse_gangs:getInfrastructureStatus')
end)

-- Receive infrastructure status from server
RegisterNetEvent('umeverse_gangs:receiveInfraStatus')
AddEventHandler('umeverse_gangs:receiveInfraStatus', function(infraStatus)
    GangInfrastructureClient.GangInfra = infraStatus
    print('Infrastructure status updated')
end)

-- Insufficient funds notification
RegisterNetEvent('umeverse_gangs:infraInsufficientFunds')
AddEventHandler('umeverse_gangs:infraInsufficientFunds', function(required)
    print('^1Gang bank insufficient! Required: $' .. required .. '^7')
end)

-- Command to open infrastructure menu
RegisterCommand('ganginfra', function()
    GangInfrastructureClient.OpenInfraMenu()
end)

-- Alt command
RegisterCommand('infra', function()
    GangInfrastructureClient.OpenInfraMenu()
end)

print('^2[Umeverse]^7 Gang Infrastructure Client loaded')
