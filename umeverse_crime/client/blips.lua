--[[
    Crime System - Blips Management
]]

local CrimeBlips = {}

function CreateCrimeBlips()
    for _, crime in ipairs(CrimeConfig.CrimeBlips) do
        local blip = AddBlipForCoord(crime.x, crime.y, crime.z)
        SetBlipRoute(blip, false)
        SetBlipAsNoGrp(blip, true)
        BeginTextCommandDisplayName('STRING')
        AddTextComponentString(crime.label)
        EndTextCommandDisplayName(blip)
        SetBlipDisplay(blip, 4)
        SetBlipColour(blip, 1)
        SetBlipScale(blip, 0.6)
        
        table.insert(CrimeBlips, blip)
    end
end

Citizen.CreateThread(function()
    CreateCrimeBlips()
end)
