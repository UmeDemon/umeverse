--[[
    Gangs System - Enterprises Client
]]

GangEnterprisesClient = {}

function GangEnterprisesClient.StartEnterprise(enterpriseType)
    TriggerServerEvent('umeverse_gangs:startEnterprise', 'current_gang', enterpriseType)
end

Citizen.CreateThread(function()
    while true do
        Wait(1000)
        -- Enterprise activities
    end
end)
