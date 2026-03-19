--[[
    Gangs System - Client Blips & Markers
]]

GangClientBlips = {}

function CreateGangBlips()
    for gangName, gangData in pairs(GangsConfig.Gangs) do
        local blip = AddBlipForCoord(gangData.spawnPoint.x, gangData.spawnPoint.y, gangData.spawnPoint.z)
        SetBlipRoute(blip, false)
        SetBlipAsNoGrp(blip, true)
        BeginTextCommandDisplayName('STRING')
        AddTextComponentString(gangData.label)
        EndTextCommandDisplayName(blip)
        SetBlipColour(blip, gangData.color)
        SetBlipScale(blip, 0.8)
        table.insert(GangClientBlips, blip)
    end
end

Citizen.CreateThread(function()
    CreateGangBlips()
end)
