--[[
    Crime System - Dispatch & Police Response
]]

DispatchSystem = {}

RegisterNetEvent('umeverse_crime:triggerDispatch')
AddEventHandler('umeverse_crime:triggerDispatch', function(heat)
    local src = source
    -- Send dispatch calls to police players
    TriggerEvent('umeverse_crime:policeAlert', {
        coords = GetEntityCoords(GetPlayerPed(src)),
        heat = heat,
        player = src,
    })
end)

print('^2[Umeverse]^7 Dispatch System loaded')
