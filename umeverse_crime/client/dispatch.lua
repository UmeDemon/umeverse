--[[
    Crime System - Dispatch & Police Response
]]

-- Police dispatch calls
function DispatchPolice(heat)
    TriggerServerEvent('umeverse_crime:triggerDispatch', heat)
end

RegisterNetEvent('umeverse_crime:policeDispatch')
AddEventHandler('umeverse_crime:policeDispatch', function(responseLevel, heat)
    if responseLevel == 'high' then
        AddTextEntry('STRING', 'Armed Robbery in Progress')
    elseif responseLevel == 'medium' then
        AddTextEntry('STRING', 'Felony Detected')
    else
        AddTextEntry('STRING', 'Suspicious Activity Reported')
    end
end)
