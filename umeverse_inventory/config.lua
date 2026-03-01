--[[
    Umeverse Inventory - Configuration
]]

InvConfig = {}

InvConfig.MaxWeight = 120000       -- Max carry weight (grams)
InvConfig.MaxSlots = 40            -- Max inventory slots
InvConfig.OpenKey = 'F2'           -- Key to open inventory (mapped below)
InvConfig.OpenControl = 289        -- FiveM input control for F2

-- Drop settings
InvConfig.EnableDrops = true
InvConfig.DropDespawnTime = 300    -- Seconds before a drop despawns

-- Stash settings  
InvConfig.Stashes = {
    ['police_stash'] = { label = 'Police Evidence', maxWeight = 500000, maxSlots = 100, job = 'police' },
    ['ems_stash']    = { label = 'EMS Storage',     maxWeight = 300000, maxSlots = 80,  job = 'ambulance' },
}
