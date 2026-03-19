--[[
    Umeverse Drugs - Blip Setup
    Creates world blips for sell corners, warehouses, stash houses, laundering, and suppliers
]]

CreateThread(function()
    if not DrugConfig.BlipDisplay then return end
    Wait(3000)

    -- Sell corner blips
    local sellBlip = DrugConfig.Blips.sellCorner
    for _, corner in ipairs(DrugConfig.SellCorners) do
        AddDrugBlip(vector3(corner.coords.x, corner.coords.y, corner.coords.z), sellBlip.sprite, sellBlip.color, corner.label, sellBlip.scale)
    end

    -- Stash house blips
    local stashBlip = DrugConfig.Blips.stash
    for _, stash in ipairs(DrugConfig.StashHouses.locations) do
        AddDrugBlip(vector3(stash.coords.x, stash.coords.y, stash.coords.z), stashBlip.sprite, stashBlip.color, stash.label, stashBlip.scale)
    end

    -- Warehouse blips
    local whBlip = DrugConfig.Blips.warehouse
    for _, wh in ipairs(DrugConfig.Warehouses.locations) do
        AddDrugBlip(wh.blip, whBlip.sprite, whBlip.color, wh.label, whBlip.scale)
    end

    -- Laundering blips
    for _, loc in ipairs(DrugConfig.Laundering.locations) do
        AddDrugBlip(vector3(loc.coords.x, loc.coords.y, loc.coords.z), loc.blip.sprite, loc.blip.color, loc.blip.label, 0.7)
    end

    -- Supply shop blips
    local supBlip = DrugConfig.Blips.supplier
    for _, shop in ipairs(DrugConfig.SupplyShops) do
        AddDrugBlip(vector3(shop.coords.x, shop.coords.y, shop.coords.z), supBlip.sprite, supBlip.color, shop.label, supBlip.scale)
    end
end)
