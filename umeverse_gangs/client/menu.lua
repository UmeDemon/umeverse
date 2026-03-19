--[[
    Gangs System - Client Menu
]]

GangMenu = {}

function GangMenu.OpenMain()
    TriggerEvent('umeverse_core:notify', 'Gang Menu - Placeholder', 'info')
end

function GangMenu.OpenMembers()
    TriggerEvent('umeverse_core:notify', 'Members List - Placeholder', 'info')
end

function GangMenu.OpenTerritories()
    TriggerEvent('umeverse_core:notify', 'Territories - Placeholder', 'info')
end

function GangMenu.OpenBank()
    TriggerEvent('umeverse_core:notify', 'Gang Bank - Placeholder', 'info')
end

Citizen.CreateThread(function()
    while true do
        Wait(0)
        -- Menu loop
    end
end)
