--[[
    Crime System - Store Robbery Implementation
]]

local StoreConfig = {
    stores = {
        { x = -47.7, y = -1097.3, z = 26.4, heading = 340.0 },
        { x = 374.5, y = 326.1, z = 103.6, heading = 110.0 },
        { x = -2968.2, y = 390.1, z = 15.0, heading = 50.0 },
    },
}

-- Attempt store robbery
function AttemptStoreRobbery()
    local success = CrimeUtils.StartCrime('store_robbery')
    if success then
        CrimeUtils.PlayCrimeAnimation('combat@damage@rb_writhe', 'rb_writhe_loop', 3000)
    end
end

-- Main loop
Citizen.CreateThread(function()
    while true do
        Wait(500)
        
        local nearCrime = CrimeUtils.GetNearbyCrime(200)
        if nearCrime and nearCrime.type == 'store_robbery' then
            CrimeUtils.DrawMarker(1, nearCrime.x, nearCrime.y, nearCrime.z, 255, 50, 50)
            
            if #(GetEntityCoords(PlayerPedId()) - vector3(nearCrime.x, nearCrime.y, nearCrime.z)) < 20 then
                CrimeUtils.Notify('Press E to rob store', 'info')
                
                if IsControlJustReleased(0, 38) then -- E key
                    AttemptStoreRobbery()
                end
            end
        end
    end
end)
