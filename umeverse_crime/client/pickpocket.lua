--[[
    Crime System - Pickpocket Implementation
]]

local PickpocketConfig = {
    ped = 'a_m_m_business_1',
    locations = {
        { x = 425.5, y = -982.3, z = 29.4 },
        { x = -548.2, y = -914.5, z = 29.3 },
        { x = -59.2, y = 6271.5, z = 31.5 },
    },
    range = 50,
}

local activePeds = {}

-- Spawn pickpocket target
function SpawnPickpocketTarget(location)
    RequestModel(GetHashKey(PickpocketConfig.ped))
    while not HasModelLoaded(GetHashKey(PickpocketConfig.ped)) do Wait(10) end
    
    local ped = CreatePed(4, GetHashKey(PickpocketConfig.ped), location.x, location.y, location.z, 0.0, true, false)
    TaskStartScenarioInPlace(ped, 'WORLD_HUMAN_STUPOR', 0, true)
    
    table.insert(activePeds, ped)
    return ped
end

-- Attempt pickpocket
function AttemptPickpocket(targetPed)
    if not DoesEntityExist(targetPed) then return false end
    
    local success = CrimeUtils.StartCrime('pickpocket')
    if success then
        -- Animation
        CrimeUtils.PlayCrimeAnimation('missheist_jewel', 'mh_stealinv_grab', 5000)
    end
end

-- Main loop for pickpocket locations
Citizen.CreateThread(function()
    while true do
        Wait(500)
        
        local nearCrime = CrimeUtils.GetNearbyCrime(100)
        if nearCrime and nearCrime.type == 'pickpocket' then
            CrimeUtils.DrawMarker(1, nearCrime.x, nearCrime.y, nearCrime.z)
            
            if #(GetEntityCoords(PlayerPedId()) - vector3(nearCrime.x, nearCrime.y, nearCrime.z)) < 15 then
                CrimeUtils.Notify('Press E to pickpocket', 'info')
                
                if IsControlJustReleased(0, 38) then -- E key
                    AttemptPickpocket(targetPed)
                end
            end
        end
    end
end)
