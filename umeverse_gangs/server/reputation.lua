--[[
    Gangs System - Reputation System
]]

GangReputation = {}

-- Level up gang member
function GangReputation.LevelUpMember(identifier, gangName)
    local memberData = GangSystem.GetPlayerGang(identifier)
    if not memberData or memberData.gang ~= gangName then
        return false
    end
    
    local reputation = memberData.reputation or 0
    local level = math.floor(reputation / GangsConfig.Reputation.xpPerLevel)
    
    if level > 20 then level = 20 end
    
    return level
end

-- Check for milestone rewards
function GangReputation.CheckMilestones(identifier)
    local gang = GangSystem.GetPlayerGang(identifier)
    if not gang then return end
    
    local rep = gang.reputation or 0
    for level, milestone in pairs(GangsConfig.Reputation.reputationMilestones) do
        if rep >= level * GangsConfig.Reputation.xpPerLevel then
            -- Award milestone
            local player = QBCore.Functions.GetPlayerByCitizenId(identifier)
            if player then
                player.Functions.AddMoney('black', milestone.reward.black_money, 'Gang Milestone - ' .. milestone.label)
                TriggerClientEvent('umeverse_gangs:notify', player.PlayerData.source, 'success', 'Reached ' .. milestone.label .. '!')
            end
        end
    end
end

print('^2[Umeverse]^7 Gang Reputation System loaded')
