--[[
    Gangs System - Territories Client
]]

GangTerritoryClient = {}

local territoryBlips = {}

function GangTerritoryClient.CreateTerritoryBlips()
    for territoryName, territory in pairs(GangsConfig.Territories) do
        local blip = AddBlipForCoord(territory.safeHouse.x, territory.safeHouse.y, territory.safeHouse.z)
        SetBlipRoute(blip, false)
        SetBlipAsNoGrp(blip, true)
        BeginTextCommandDisplayName('STRING')
        AddTextComponentString(territory.label .. ' - ' .. GangsConfig.Gangs[territory.gang].label)
        EndTextCommandDisplayName(blip)
        SetBlipColour(blip, GangsConfig.Gangs[territory.gang].color)
        SetBlipScale(blip, 0.9)
        table.insert(territoryBlips, blip)
    end
end

Citizen.CreateThread(function()
    GangTerritoryClient.CreateTerritoryBlips()
end)
