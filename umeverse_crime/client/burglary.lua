--[[
    Crime System - Burglary Implementation  
]]

local BurglaryConfig = {
    houses = {
        { x = -456.5, y = 6226.1, z = 31.5, heading = 315.0 },
        { x = 1190.5, y = -783.3, z = 57.6, heading = 200.0 },
    },
}

function AttemptBurglary()
    local success = CrimeUtils.StartCrime('burglary')
    if success then
        CrimeUtils.PlayCrimeAnimation('missheist_jewel', 'mh_stealinv_grab', 5000)
    end
end

Citizen.CreateThread(function()
    while true do
        Wait(500)
        
        local nearCrime = CrimeUtils.GetNearbyCrime(150)
        if nearCrime and nearCrime.type == 'burglary' then
            CrimeUtils.DrawMarker(1, nearCrime.x, nearCrime.y, nearCrime.z + 1, 100, 50, 150)
            
            if #(GetEntityCoords(PlayerPedId()) - vector3(nearCrime.x, nearCrime.y, nearCrime.z)) < 20 then
                CrimeUtils.Notify('Press E to burglarize house', 'info')
                
                if IsControlJustReleased(0, 38) then
                    AttemptBurglary()
                end
            end
        end
    end
end)
