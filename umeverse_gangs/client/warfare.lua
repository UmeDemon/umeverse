--[[
    Gangs System - Warfare Client
]]

GangWarfareClient = {}

function GangWarfareClient.StartWar(targetGang, territory)
    TriggerServerEvent('umeverse_gangs:declareWar', 'current_gang', targetGang, territory)
end

function GangWarfareClient.EndWar(winner, loser, territory)
    TriggerServerEvent('umeverse_gangs:endWar', winner, loser, territory)
end

Citizen.CreateThread(function()
    while true do
        Wait(1000)
        -- War mechanics
    end
end)
