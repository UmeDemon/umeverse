--[[
    Umeverse Crime System - Specializations Client
    UI for viewing and unlocking crime specializations
]]

CrimeSpecializationsClient = {}
CrimeSpecializationsClient.PlayerSpecs = {}
CrimeSpecializationsClient.OpenMenu = false

-- Open specializations menu
function CrimeSpecializationsClient.OpenSpecMenu()
    local menuData = {
        title = "Crime Specializations",
        subtitle = "Unlock and level up your criminal skills",
        flags = {locked = false, enableMouse = true},
        items = {}
    }
    
    -- Get player specializations from server
    TriggerServerEvent('umeverse_crime:getPlayerSpecs')
    
    Wait(300) -- Wait for server response
    
    for specType, spec in pairs(GangsConfig.CrimeSpecializations or {}) do
        table.insert(menuData.items, {
            id = 'spec_' .. specType,
            title = spec.label,
            description = 'Level: ' .. (spec.level or 1) .. '/' .. spec.maxLevel .. ' | XP: ' .. (spec.xp or 0) .. '/' .. spec.xpPerLevel,
            args = {
                specType = specType,
            },
            icon = 'fas fa-star',
        })
    end
    
    -- Would use your framework's menu system (e.g., qb-menu, ox_lib, etc.)
    -- This is a simplified example structure
    print('Specialization Menu:')
    for _, item in ipairs(menuData.items) do
        print('- ' .. item.title .. ' (Level ' .. (item.args.specType or 'N/A') .. ')')
    end
    
    CrimeSpecializationsClient.OpenMenu = true
end

-- View specialization details
function CrimeSpecializationsClient.ViewSpecDetails(specType)
    local spec = GangsConfig.CrimeSpecializations and GangsConfig.CrimeSpecializations[specType]
    if not spec then return end
    
    print('^3=== ' .. spec.label .. ' ===^7')
    print('Current Level: ' .. (spec.level or 1) .. '/' .. spec.maxLevel)
    print('XP Progress: ' .. (spec.xp or 0) .. '/' .. spec.xpPerLevel)
    print('')
    print('^2Unlocked Abilities:^7')
    
    if spec.abilities then
        for level, ability in ipairs(spec.abilities) do
            local isUnlocked = (spec.level or 1) >= level
            local status = isUnlocked and '^2✓^7' or '^1✗^7'
            print(status .. ' Level ' .. level .. ': ' .. ability.name .. ' - ' .. ability.description)
        end
    end
    
    print('')
    print('Unlock Cost: $' .. (spec.unlockCost or 500))
end

-- Unlock specialization
function CrimeSpecializationsClient.UnlockSpecialization(specType)
    local menuData = {
        title = 'Unlock Specialization?',
        subtitle = 'Cost: $' .. GangsConfig.CrimeSpecializations[specType].unlockCost,
        items = {
            {id = 'confirm', title = 'Confirm'},
            {id = 'cancel', title = 'Cancel'},
        }
    }
    
    -- Implementation would use framework menu system
    -- This shows the structure
    
    TriggerServerEvent('umeverse_crime:unlockSpecialization', specType)
end

-- Display current specialization bonuses in HUD
function CrimeSpecializationsClient.DisplayBonuses()
    local bonuses = GangsConfig.CrimeSpecializations or {}
    
    if next(bonuses) == nil then return end
    
    local bonusText = '^2Criminal Skills:^7\n'
    
    for specType, spec in pairs(bonuses) do
        if spec.level and spec.level > 1 then
            bonusText = bonusText .. spec.label .. ' (L' .. spec.level .. ')\n'
        end
    end
    
    -- Would render to screen using your HUD system
    -- TriggerEvent('umeverse_hud:addNotification', bonusText)
end

-- Update player specs from server
RegisterNetEvent('umeverse_crime:updatePlayerSpecs')
AddEventHandler('umeverse_crime:updatePlayerSpecs', function(specs)
    CrimeSpecializationsClient.PlayerSpecs = specs
    CrimeSpecializationsClient.DisplayBonuses()
end)

-- Open menu command
RegisterCommand('crimespec', function()
    CrimeSpecializationsClient.OpenSpecMenu()
end)

-- Keybind for specializations menu (example with ox_lib)
--[[
local function setupKeybinds()
    if GetResourceState('ox_lib') ~= 'started' then return end
    
    lib.addKeybind({
        name = 'crime_specializations',
        description = 'Open Crime Specializations Menu',
        defaultKey = 'F6',
        canRepeat = false,
        onPressed = function(held)
            if not held then
                CrimeSpecializationsClient.OpenSpecMenu()
            end
        end,
    })
end

setupKeybinds()
]]

print('^2[Umeverse]^7 Crime Specializations Client loaded')
