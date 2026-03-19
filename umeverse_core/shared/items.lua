--[[
    Umeverse Framework - Items Configuration
    Define all usable/inventory items here
]]

UME.Items = {
    -- Food & Drink
    ['bread']       = { label = 'Bread',       weight = 200,  type = 'food',     image = 'bread.png',       usable = true,  unique = false, description = 'A loaf of bread' },
    ['water']       = { label = 'Water Bottle', weight = 500,  type = 'drink',    image = 'water.png',       usable = true,  unique = false, description = 'A bottle of fresh water' },
    ['burger']      = { label = 'Burger',      weight = 300,  type = 'food',     image = 'burger.png',      usable = true,  unique = false, description = 'A juicy burger' },
    ['cola']        = { label = 'Cola',        weight = 350,  type = 'drink',    image = 'cola.png',        usable = true,  unique = false, description = 'A refreshing cola' },
    ['coffee']      = { label = 'Coffee',      weight = 300,  type = 'drink',    image = 'coffee.png',      usable = true,  unique = false, description = 'Hot coffee' },
    ['donut']       = { label = 'Donut',       weight = 150,  type = 'food',     image = 'donut.png',       usable = true,  unique = false, description = 'A glazed donut' },
    ['sandwich']    = { label = 'Sandwich',    weight = 250,  type = 'food',     image = 'sandwich.png',    usable = true,  unique = false, description = 'A tasty sandwich' },

    -- Medical
    ['bandage']     = { label = 'Bandage',     weight = 100,  type = 'medical',  image = 'bandage.png',     usable = true,  unique = false, description = 'A basic bandage' },
    ['medikit']     = { label = 'First Aid Kit', weight = 500, type = 'medical', image = 'medikit.png',     usable = true,  unique = false, description = 'A first aid kit' },
    ['painkillers'] = { label = 'Painkillers', weight = 50,   type = 'medical',  image = 'painkillers.png', usable = true,  unique = false, description = 'Pain relief pills' },

    -- Tools & Misc
    ['phone']       = { label = 'Phone',       weight = 200,  type = 'misc',     image = 'phone.png',       usable = true,  unique = true,  description = 'A mobile phone' },
    ['radio']       = { label = 'Radio',       weight = 500,  type = 'misc',     image = 'radio.png',       usable = true,  unique = false, description = 'A handheld radio' },
    ['lockpick']    = { label = 'Lockpick',    weight = 100,  type = 'tool',     image = 'lockpick.png',    usable = true,  unique = false, description = 'A lockpick tool' },
    ['repairkit']   = { label = 'Repair Kit',  weight = 2500, type = 'tool',     image = 'repairkit.png',   usable = true,  unique = false, description = 'Vehicle repair kit' },
    ['advancedrepairkit'] = { label = 'Advanced Repair Kit', weight = 3000, type = 'tool', image = 'advancedrepairkit.png', usable = true, unique = false, description = 'Advanced vehicle repair kit' },
    ['mi_tablet']    = { label = 'MI Tablet', weight = 800, type = 'misc', image = 'mi_tablet.png', usable = true, unique = true, description = 'A high-tech tablet' },

    -- ID & Documents
    ['id_card']     = { label = 'ID Card',     weight = 0,    type = 'document', image = 'id_card.png',     usable = true,  unique = true,  description = 'Government issued ID' },
    ['driver_license'] = { label = 'Drivers License', weight = 0, type = 'document', image = 'driver_license.png', usable = true, unique = true, description = 'A valid drivers license' },

    -- Weapons ammo
    ['ammo_pistol']  = { label = 'Pistol Ammo',  weight = 200,  type = 'ammo', image = 'ammo_pistol.png',  usable = false, unique = false, description = '9mm ammunition' },
    ['ammo_rifle']   = { label = 'Rifle Ammo',   weight = 500,  type = 'ammo', image = 'ammo_rifle.png',   usable = false, unique = false, description = '5.56mm ammunition' },
    ['ammo_shotgun'] = { label = 'Shotgun Ammo',  weight = 400,  type = 'ammo', image = 'ammo_shotgun.png', usable = false, unique = false, description = '12 gauge shells' },
    ['ammo_smg']     = { label = 'SMG Ammo',      weight = 300,  type = 'ammo', image = 'ammo_smg.png',     usable = false, unique = false, description = '.45 ACP ammunition' },
}

--- Get an item definition
---@param name string
---@return table|nil
function UME.GetItem(name)
    return UME.Items[name]
end

--- Get item label
---@param name string
---@return string|nil
function UME.GetItemLabel(name)
    local item = UME.Items[name]
    if item then return item.label end
    return nil
end
