--[[
    Crime System - Crime Reputation
]]

CrimeReputation = {}

-- Add crime reputation
function CrimeReputation.AddReputation(identifier, amount)
    MySQL.update('UPDATE umeverse_crime_stats SET total_earned = total_earned + ? WHERE identifier = ?',
        { amount, identifier })
end

-- Get crime reputation
function CrimeReputation.GetReputation(identifier)
    local reputation = 0
    MySQL.query('SELECT total_earned FROM umeverse_crime_stats WHERE identifier = ?', { identifier }, function(result)
        if result and #result > 0 then
            reputation = result[1].total_earned or 0
        end
    end)
    return reputation
end

print('^2[Umeverse]^7 Crime Reputation System loaded')
