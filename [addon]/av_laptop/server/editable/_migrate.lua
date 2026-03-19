-- Used for people who wants to migrate their existing data from origen_inventory to ox_inventory without losing any info...

-- remove the stash_ prefix that origen_inventory adds to stash names ?
-- old name: stash_avscripts / new name: avscripts
local removeStashPrefix = true -- true or false
local vehiclesTable = "player_vehicles" -- "player_vehicles" for qb-core OR "owned_vehicles" for ESX

local defaultValues = { -- Default values just in case some of your stashes doesn't have weight or slots
    ['glovebox'] = {
        weight = 20000, -- 20kg
        slots = 20
    },
    ['stashes'] = {
        weight = 20000, -- 20kg
        slots = 20
    },
    ['trunk'] = { -- 20kg
        weight = 20000,
        slots = 20
    },
}

RegisterCommand("origen:migrate", function(source,args)
    if source and tonumber(source) == 0 then
        migrateOrigen()
    else
        print("This command can only be used from TxAdmin console.")
    end
end,true)

function migrateOrigen()
    print("^3Migrating DB please don't restart the resource..^7")
    local glovebox = MySQL.query.await('SELECT * FROM `gloveboxitems`', {})
    local stashes = MySQL.query.await('SELECT * FROM `stashitems`', {})
    local trunks = MySQL.query.await('SELECT * FROM `trunkitems`', {})
    if glovebox and next(glovebox) then
        print("^3Migrating gloveboxitems...^7")
        local updated = 0
        local notFound = 0
        for _, inventory in pairs(glovebox) do
            local plate = inventory['plate'] or ""
            local slots = inventory['slots'] or defaultValues['glovebox']['slots'] or 20
            local weight = inventory['weight'] or defaultValues['glovebox']['weight'] or 20000
            local label = inventory['label'] or plate or "Glovebox"
            local temp_items = inventory['items'] and json.decode(inventory['items']) or {}
            local exists = MySQL.scalar.await('SELECT `plate` FROM `'..vehiclesTable..'` WHERE `plate` = ? LIMIT 1', {
                plate
            })
            if exists then
                local items = {}
                for k, v in pairs(temp_items) do
                    local slot = #items+1 or 1
                    items[#items+1] = {
                        name = v['name'],
                        count = v['amount'] or v['count'] or 1,
                        metadata = v['metadata'] or v['info'] or {},
                        slot = slot,
                    }
                end
                MySQL.update.await('UPDATE `'..vehiclesTable..'` SET glovebox = ? WHERE plate = ?', {
                    json.encode(items), plate
                })
                updated += 1
            else
--                print("^3Vehicle with plate "..plate.." doesn't exist in "..vehiclesTable..", skipping...^7")
                notFound += 1
            end
        end
        print("^3Updated: ^7"..updated..", ^1Not found:^7 "..notFound)
        print("^2Glovebox migration ended...")
    end
    if stashes and next(stashes) then
        print("^3Migrating stashes...^7")
        local updated = 0
        for k, inventory in pairs(stashes) do
            local name = removePrefix(inventory['stash']) or false
            local label = inventory['label'] or name
            local slots = inventory['slots'] or defaultValues['stashes']['slots'] or 20
            local weight = inventory['weight'] or defaultValues['stashes']['weight'] or 20000
            local temp_items = inventory['items'] and json.decode(inventory['items']) or {}
--            print("RegisterStash(name, label, slots, weight)", name, label, slots, weight)
            exports.ox_inventory:RegisterStash(name, label, slots, weight)
            for k, v in pairs(temp_items) do
                local slot = v['slot'] or #items+1 or 1
                exports.ox_inventory:AddItem(name, v['name'], v['amount'] or v['count'] or 1, v['metadata'] or v['info'] or {}, slot)
            end
            updated += 1
        end
        print("^3Updated: ^7"..updated.." stashes.")
        print("^2Stashes migration ended...")
    end
    if trunks and next(trunks) then
        print("^3Migrating trunkitems...^7")
        local updated = 0
        local notFound = 0
        for _, inventory in pairs(trunks) do
            local plate = inventory['plate'] or ""
            local slots = inventory['slots'] or defaultValues['trunk']['slots'] or 20
            local weight = inventory['weight'] or defaultValues['trunk']['weight'] or 20000
            local label = inventory['label'] or plate or "Trunk"
            local temp_items = inventory['items'] and json.decode(inventory['items']) or {}
            local exists = MySQL.scalar.await('SELECT `plate` FROM `'..vehiclesTable..'` WHERE `plate` = ? LIMIT 1', {
                plate
            })
            if exists then
                local items = {}
                for k, v in pairs(temp_items) do
                    local slot = #items+1 or 1
                    items[#items+1] = {
                        name = v['name'],
                        count = v['amount'] or v['count'] or 1,
                        metadata = v['metadata'] or v['info'] or {},
                        slot = slot,
                    }
                end
                MySQL.update.await('UPDATE `'..vehiclesTable..'` SET trunk = ? WHERE plate = ?', {
                    json.encode(items), plate
                })
                updated += 1
            else
--                print("^3Vehicle with plate "..plate.." doesn't exist in "..vehiclesTable..", skipping...^7")
                notFound += 1
            end
        end
        print("^3Updated: ^7"..updated..", ^1Not found:^7 "..notFound)
        print("^2Trunk migration ended...")
    end
    print([[
       ^2 Migration ended, please restart your server and don't run this command again. :)
    ]])
end

function removePrefix(name)
    if removeStashPrefix then
        local prefix = "stash_"
        if string.sub(name, 1, #prefix) == prefix then
            name = string.sub(name, #prefix + 1)
        end
    end
    return name
end