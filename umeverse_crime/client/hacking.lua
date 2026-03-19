--[[
    Crime System - Hacking Implementation
]]

-- Hacking minigame
function AttemptHacking()
    TriggerEvent('umeverse_core:notify', 'Hacking system initiated', 'info')
    -- Placeholder for hacking minigame
end

Citizen.CreateThread(function()
    while true do
        Wait(1000)
        -- Hacking checks would go here
    end
end)
