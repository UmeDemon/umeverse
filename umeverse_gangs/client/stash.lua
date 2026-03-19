--[[
    Gangs System - Stash Client
]]

GangStashClient = {}

function GangStashClient.OpenStash()
    TriggerEvent('umeverse_core:notify', 'Gang Stash - Placeholder', 'info')
end

Citizen.CreateThread(function()
    while true do
        Wait(500)
        -- Stash interactions
    end
end)
