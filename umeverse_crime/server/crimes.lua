--[[
    Crime System - Crime Handlers
]]

CrimeHandlers = {}

-- Handle different crime types
function CrimeHandlers.HandlePickpocket(src)
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end
    
    -- Reward items
    Player.Functions.AddItem('cash_bundle', 1)
    TriggerClientEvent('umeverse_crime:notify', src, 'success', 'Pickpocketed $50-$300')
end

function CrimeHandlers.HandleStoreRobbery(src)
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end
    
    -- Add wanted level
    SetPlayerWantedLevel(src, 3)
end

function CrimeHandlers.HandleCarTheft(src)
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end
    
    SetPlayerWantedLevel(src, 2)
end

function CrimeHandlers.HandleBurglary(src)
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end
    
    Player.Functions.AddItem('jewelry', math.random(1, 3))
    SetPlayerWantedLevel(src, 4)
end

function CrimeHandlers.HandleATMRobbery(src)
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end
    
    SetPlayerWantedLevel(src, 5)
end

print('^2[Umeverse]^7 Crime Handlers loaded')
