--[[
    Gangs System - Client Utils
]]

GangClientUtils = {}

function GangClientUtils.Notify(message, type)
    type = type or 'info'
    TriggerEvent('umeverse_core:notify', message, type)
end

function GangClientUtils.OpenGangMenu()
    local PlayerGang = exports['umeverse_gangs']:GetPlayerGang()
    if not PlayerGang then
        GangClientUtils.Notify('You are not in a gang', 'error')
        return
    end
    
    local menuOptions = {
        { label = 'View Gang Info', value = 'gang_info' },
        { label = 'Members List', value = 'members' },
        { label = 'Territories', value = 'territories' },
        { label = 'Bank', value = 'bank' },
        { label = 'Enterprises', value = 'enterprises' },
        { label = 'Warfare', value = 'warfare' },
    }
    
    TriggerEvent('umeverse_core:openMenu', {
        title = PlayerGang.label,
        options = menuOptions,
    })
end

-- Gang blips
local GangBlips = {}

function GangClientUtils.CreateGangTerritoriesBlips()
    for territoryName, territory in pairs(GangsConfig.Territories) do
        local blip = AddBlipForCoord(territory.safeHouse.x, territory.safeHouse.y, territory.safeHouse.z)
        SetBlipRoute(blip, false)
        SetBlipAsNoGrp(blip, true)
        BeginTextCommandDisplayName('STRING')
        AddTextComponentString(territory.label)
        EndTextCommandDisplayName(blip)
        SetBlipColour(blip, territory.blip.color)
        SetBlipScale(blip, territory.blip.scale)
        
        table.insert(GangBlips, blip)
    end
end

Citizen.CreateThread(function()
    GangClientUtils.CreateGangTerritoriesBlips()
end)

return GangClientUtils
