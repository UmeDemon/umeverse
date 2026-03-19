--[[
    Crime System - Car Theft Implementation
]]

-- Attempt car theft
function AttemptCarTheft()
    local success = CrimeUtils.StartCrime('car_theft')
    if success then
        -- Find nearby vehicle
        local ped = PlayerPedId()
        local pedCoords = GetEntityCoords(ped)
        
        local vehicles = {}
        local handle, vehicle = FindFirstVehicle()
        repeat
            local vCoords = GetEntityCoords(vehicle)
            local distance = #(pedCoords - vCoords)
            if distance < 100 then
                table.insert(vehicles, vehicle)
            end
            handle, vehicle = FindNextVehicle(handle)
        until not vehicle
        EndFindVehicle(handle)
        
        if #vehicles > 0 then
            local targetVehicle = vehicles[1]
            CrimeUtils.PlayCrimeAnimation('vehshare@handsup', 'handsup_base', 2000)
        end
    end
end

-- Main loop
Citizen.CreateThread(function()
    while true do
        Wait(1000)
        
        local ped = PlayerPedId()
        local pedCoords = GetEntityCoords(ped)
        
        -- Find nearby vehicles
        local handle, vehicle = FindFirstVehicle()
        repeat
            local vCoords = GetEntityCoords(vehicle)
            local distance = #(pedCoords - vCoords)
            if distance < 50 then
                CrimeUtils.DrawMarker(1, vCoords.x, vCoords.y, vCoords.z + 1, 255, 100, 0)
                
                if distance < 10 then
                    CrimeUtils.Notify('Press E to steal vehicle', 'info')
                    if IsControlJustReleased(0, 38) then
                        AttemptCarTheft()
                    end
                end
            end
        until not FindNextVehicle(handle)
        EndFindVehicle(handle)
    end
end)
