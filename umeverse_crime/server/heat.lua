--[[
    Crime System - Server Heat Management
]]

CrimeHeat = {}

-- Police dispatch based on heat
RegisterNetEvent('umeverse_crime:policeDispatch')
AddEventHandler('umeverse_crime:policeDispatch', function(src, responseLevel, heat)
    -- Trigger police dispatch events
    local Player = QBCore.Functions.GetPlayer(src)
    if Player then
        if responseLevel == 'high' then
            SetPlayerWantedLevel(src, 5)
        elseif responseLevel == 'medium' then
            SetPlayerWantedLevel(src, 3)
        else
            SetPlayerWantedLevel(src, 1)
        end
    end
end)

print('^2[Umeverse]^7 Crime Heat System loaded')
