--[[
    Crime System - ATM Robbery Implementation
]]

function AttemptATMRobbery()
    local success = CrimeUtils.StartCrime('atm_robbery')
    if success then
        CrimeUtils.PlayCrimeAnimation('missheist_jewel', 'mh_stealinv_grab', 5000)
    end
end

Citizen.CreateThread(function()
    while true do
        Wait(500)
        
        local nearCrime = CrimeUtils.GetNearbyCrime(100)
        if nearCrime and nearCrime.type == 'atm_robbery' then
            CrimeUtils.DrawMarker(1, nearCrime.x, nearCrime.y, nearCrime.z, 200, 0, 50)
            
            if #(GetEntityCoords(PlayerPedId()) - vector3(nearCrime.x, nearCrime.y, nearCrime.z)) < 15 then
                CrimeUtils.Notify('Press E to rob ATM', 'info')
                
                if IsControlJustReleased(0, 38) then
                    AttemptATMRobbery()
                end
            end
        end
    end
end)
