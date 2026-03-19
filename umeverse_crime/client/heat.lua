--[[
    Crime System - Heat & Wanted Level Management
]]

local HeatDisplay = {}

function UpdateHeatDisplay()
    local ped = PlayerPedId()
    local wantedLevel = GetPlayerWantedLevel(PlayerId())
    
    -- Send heat update to server
    TriggerServerEvent('umeverse_crime:getPlayerHeat')
end

Citizen.CreateThread(function()
    while true do
        Wait(5000)
        UpdateHeatDisplay()
    end
end)
