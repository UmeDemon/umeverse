--[[
    Umeverse Crime System - Specialization Leveling
    Tracks specialization progression, unlocks, and applies bonuses
]]

CrimeSpecialization = {}
CrimeSpecialization.PlayerSpecs = {}

-- Initialize player specializations
function CrimeSpecialization.InitializePlayer(src, citizenid)
    MySQL.query('SELECT * FROM umeverse_crime_specializations WHERE identifier = ?', { citizenid }, function(result)
        CrimeSpecialization.PlayerSpecs[src] = result and result[1] or { identifier = citizenid, specs = {} }
    end)
end

-- Unlock specialization
function CrimeSpecialization.UnlockSpecialization(src, specType, callback)
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then
        if callback then callback(false, 'Player not found') end
        return false
    end
    
    if not CrimeConfig or not CrimeConfig.Specializations then
        if callback then callback(false, 'Crime config not loaded') end
        return false
    end
    
    local spec = CrimeConfig.Specializations[specType]
    if not spec then
        if callback then callback(false, 'Invalid specialization') end
        return false
    end
    
    local playerMoney = Player.PlayerData.money['black'] or 0
    if playerMoney < spec.unlockCost then
        if callback then callback(false, 'Insufficient black money to unlock specialization') end
        return false, 'Insufficient black money to unlock specialization'
    end
    
    Player.Functions.RemoveMoney('black', spec.unlockCost, 'Specialization Unlock')
    
    MySQL.insert('INSERT INTO umeverse_crime_specializations (identifier, specialization, level, experience) VALUES (?, ?, ?, ?)',
        { Player.PlayerData.citizenid, specType, 1, 0 },
        function(lastId)
            if lastId then
                TriggerClientEvent('umeverse_crime:notify', src, 'success', 'Specialization unlocked: ' .. spec.label)
                if callback then callback(true) end
            else
                TriggerClientEvent('umeverse_crime:notify', src, 'error', 'Failed to unlock specialization')
                if callback then callback(false, 'Database error') end
            end
        end
    )
    
    return true
end

-- Level up specialization
function CrimeSpecialization.LevelUpSpecialization(src, specType, experienceGain, callback)
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then
        if callback then callback(false) end
        return false
    end
    
    if not CrimeConfig or not CrimeConfig.Specializations then
        if callback then callback(false) end
        return false
    end
    
    local spec = CrimeConfig.Specializations[specType]
    if not spec then
        if callback then callback(false) end
        return false
    end
    
    -- Get current level and XP
    MySQL.query('SELECT * FROM umeverse_crime_specializations WHERE identifier = ? AND specialization = ?',
        { Player.PlayerData.citizenid, specType },
        function(result)
            if not result or #result == 0 then
                if callback then callback(false) end
                return
            end
            
            local current = result[1]
            if not current then
                if callback then callback(false) end
                return
            end
            
            local newXp = (current.experience or 0) + (experienceGain or 0)
            local nextLevelXp = (spec.levelCost or 100) * ((current.level or 1) + 1)
            
            if newXp >= nextLevelXp and (current.level or 1) < (spec.maxLevel or 10) then
                -- Level up!
                local newLevel = (current.level or 1) + 1
                local bonuses = spec.levelBonuses and spec.levelBonuses[newLevel]
                
                MySQL.update('UPDATE umeverse_crime_specializations SET level = ?, experience = ? WHERE identifier = ? AND specialization = ?',
                    { newLevel, newXp - nextLevelXp, Player.PlayerData.citizenid, specType },
                    function(affected)
                        if affected > 0 then
                            TriggerClientEvent('umeverse_crime:notify', src, 'success', spec.label .. ' upgraded to level ' .. newLevel .. '!')
                            
                            -- Unlock special abilities
                            if bonuses and bonuses.unlock then
                                TriggerClientEvent('umeverse_crime:unlockAbility', src, bonuses.unlock)
                            end
                            if callback then callback(true) end
                        else
                            if callback then callback(false) end
                        end
                    end
                )
            else
                -- Just add XP
                MySQL.update('UPDATE umeverse_crime_specializations SET experience = ? WHERE identifier = ? AND specialization = ?',
                    { newXp, Player.PlayerData.citizenid, specType },
                    function(affected)
                        if callback then callback(affected > 0) end
                    end
                )
            end
        end
    )
end

-- Get specialization bonuses (callback-based)
function CrimeSpecialization.GetSpecBonuses(citizenid, specType, callback)
    local bonuses = { timeReduction = 0, successBonus = 0, heatReduction = 0, detectionReduction = 0, rewardBonus = 0, damageReduction = 0 }
    
    if not callback then callback = function() end end
    
    if not CrimeConfig or not CrimeConfig.Specializations then
        callback(bonuses)
        return
    end
    
    MySQL.query('SELECT * FROM umeverse_crime_specializations WHERE identifier = ? AND specialization = ?',
        { citizenid, specType },
        function(result)
            if result and #result > 0 then
                local spec = CrimeConfig.Specializations[specType]
                if spec and result[1] and result[1].level and spec.levelBonuses then
                    local levelBonus = spec.levelBonuses[result[1].level]
                    if levelBonus then
                        for k, v in pairs(levelBonus) do
                            if bonuses[k] then bonuses[k] = v end
                        end
                    end
                end
            end
            callback(bonuses)
        end
    )
end

RegisterNetEvent('umeverse_crime:unlockSpecialization')
AddEventHandler('umeverse_crime:unlockSpecialization', function(specType)
    if specType then
        CrimeSpecialization.UnlockSpecialization(source, specType)
    end
end)

RegisterNetEvent('umeverse_crime:crimeCompleted')
AddEventHandler('umeverse_crime:crimeCompleted', function(crimeType)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then return end
    
    if not CrimeConfig or not CrimeConfig.Specializations then return end
    
    -- Add XP to applicable specializations
    for specType, spec in pairs(CrimeConfig.Specializations) do
        if spec and spec.crimeBonus then
            for _, bonusCrime in ipairs(spec.crimeBonus) do
                if bonusCrime == crimeType then
                    CrimeSpecialization.LevelUpSpecialization(source, specType, 50)
                    break
                end
            end
        end
    end
end)

print('^2[Umeverse]^7 Crime Specialization System loaded')
