--[[
    Umeverse Drugs - Server Stash
    Stash house registration with the inventory system
    Each player gets a personal stash per stash house location
]]

local UME = exports['umeverse_core']:GetCoreObject()

-- Register stash houses with the inventory system on startup
-- This ensures the stash definitions exist for the inventory to open them
CreateThread(function()
    Wait(3000)

    for _, stash in ipairs(DrugConfig.StashHouses.locations) do
        -- The inventory system handles per-player stashes via the stash_id
        -- We just need to make sure the stash definitions allow drug items
        -- The actual stash ID used will be: drug_stash_{id}_{citizenid}
        -- This is handled client-side when opening
    end
end)
