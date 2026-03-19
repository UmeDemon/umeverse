--[[
    Gangs System - Ranks & Permissions
]]

GangRanks = {}

-- Promote member
function GangRanks.PromoteMember(identifier, gangName, newRank)
    if newRank > 5 or newRank < 0 then
        return false, 'Invalid rank'
    end
    
    MySQL.update('UPDATE umeverse_gang_members SET rank = ? WHERE identifier = ? AND gang_name = ?',
        { newRank, identifier, gangName },
        function(rowsChanged)
            if rowsChanged > 0 then
                GangSystem.PlayerGangs[identifier].rank = newRank
            end
        end
    )
    
    return true
end

-- Demote member
function GangRanks.DemoteMember(identifier, gangName)
    local member = GangSystem.PlayerGangs[identifier]
    if not member or member.gang ~= gangName then
        return false
    end
    
    local currentRank = member.rank
    if currentRank == 0 then
        return false, 'Cannot demote below Prospect'
    end
    
    return GangRanks.PromoteMember(identifier, gangName, currentRank - 1)
end

-- Check permission
function GangRanks.HasPermission(identifier, permission)
    local member = GangSystem.PlayerGangs[identifier]
    if not member then return false end
    
    local rankData = GangsConfig.Ranks[member.rank]
    if not rankData then return false end
    
    if rankData.permissions[permission] or rankData.permissions['*'] then
        return true
    end
    
    return false
end

-- Get member rank label
function GangRanks.GetRankLabel(rank)
    local rankData = GangsConfig.Ranks[rank]
    return rankData and rankData.label or 'Unknown'
end

print('^2[Umeverse]^7 Gang Ranks System loaded')
