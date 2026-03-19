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

    -- Job Items - Fishing
    ['fish_common']    = { label = 'Common Fish',    weight = 500,  type = 'material', image = 'fish_common.png',    usable = false, unique = false, description = 'A common freshwater fish' },
    ['fish_uncommon']  = { label = 'Uncommon Fish',  weight = 600,  type = 'material', image = 'fish_uncommon.png',  usable = false, unique = false, description = 'An uncommon catch' },
    ['fish_rare']      = { label = 'Rare Fish',      weight = 800,  type = 'material', image = 'fish_rare.png',      usable = false, unique = false, description = 'A rare prized fish' },

    -- Job Items - Lumberjack
    ['wood_log']       = { label = 'Wood Log',       weight = 2000, type = 'material', image = 'wood_log.png',       usable = false, unique = false, description = 'A freshly cut log' },
    ['wood_plank']     = { label = 'Wood Plank',     weight = 1000, type = 'material', image = 'wood_plank.png',     usable = false, unique = false, description = 'A processed wood plank' },

    -- Job Items - Mining
    ['stone']          = { label = 'Stone',          weight = 1500, type = 'material', image = 'stone.png',          usable = false, unique = false, description = 'A chunk of stone' },
    ['iron_ore']       = { label = 'Iron Ore',       weight = 2000, type = 'material', image = 'iron_ore.png',       usable = false, unique = false, description = 'Raw iron ore' },
    ['gold_ore']       = { label = 'Gold Ore',       weight = 2500, type = 'material', image = 'gold_ore.png',       usable = false, unique = false, description = 'Raw gold ore' },

    -- Job Items - Reporter
    ['news_camera']    = { label = 'News Camera',    weight = 1500, type = 'tool',     image = 'news_camera.png',    usable = true,  unique = true,  description = 'A professional news camera' },
    ['news_mic']       = { label = 'Microphone',     weight = 300,  type = 'tool',     image = 'news_mic.png',       usable = true,  unique = true,  description = 'A handheld microphone' },

    -- Job Items - Hunter
    ['deer_pelt']      = { label = 'Deer Pelt',      weight = 2000, type = 'material', image = 'deer_pelt.png',      usable = false, unique = false, description = 'A fresh deer pelt' },
    ['boar_pelt']      = { label = 'Boar Pelt',      weight = 2500, type = 'material', image = 'boar_pelt.png',      usable = false, unique = false, description = 'A fresh boar pelt' },
    ['raw_venison']    = { label = 'Raw Venison',    weight = 1000, type = 'material', image = 'raw_venison.png',    usable = false, unique = false, description = 'Raw deer meat' },
    ['raw_pork']       = { label = 'Raw Pork',       weight = 1200, type = 'material', image = 'raw_pork.png',       usable = false, unique = false, description = 'Raw boar meat' },

    -- Job Items - Farmer
    ['wheat']          = { label = 'Wheat',          weight = 500,  type = 'material', image = 'wheat.png',          usable = false, unique = false, description = 'Harvested wheat' },
    ['corn']           = { label = 'Corn',           weight = 400,  type = 'material', image = 'corn.png',           usable = false, unique = false, description = 'Fresh corn on the cob' },
    ['tomato']         = { label = 'Tomato',         weight = 300,  type = 'material', image = 'tomato.png',         usable = false, unique = false, description = 'A ripe tomato' },
    ['lettuce']        = { label = 'Lettuce',        weight = 250,  type = 'material', image = 'lettuce.png',        usable = false, unique = false, description = 'Fresh lettuce' },

    -- Job Items - Diver/Salvager
    ['scrap_metal']    = { label = 'Scrap Metal',    weight = 2000, type = 'material', image = 'scrap_metal.png',    usable = false, unique = false, description = 'Salvaged scrap metal' },
    ['sea_pearl']      = { label = 'Sea Pearl',      weight = 100,  type = 'material', image = 'sea_pearl.png',      usable = false, unique = false, description = 'A pearl from the ocean floor' },
    ['ancient_coin']   = { label = 'Ancient Coin',   weight = 50,   type = 'material', image = 'ancient_coin.png',   usable = false, unique = false, description = 'An ancient sunken coin' },

    -- Job Items - Vineyard
    ['grapes']         = { label = 'Grapes',         weight = 400,  type = 'material', image = 'grapes.png',         usable = false, unique = false, description = 'Fresh picked grapes' },
    ['wine_bottle']    = { label = 'Wine Bottle',    weight = 800,  type = 'material', image = 'wine_bottle.png',    usable = false, unique = false, description = 'A bottle of wine' },

    -- Drug Items - Raw Materials
    ['weed_leaf']      = { label = 'Weed Leaf',      weight = 100,  type = 'drug_material', image = 'weed_leaf.png',      usable = false, unique = false, description = 'A raw cannabis leaf' },
    ['coca_leaf']      = { label = 'Coca Leaf',      weight = 80,   type = 'drug_material', image = 'coca_leaf.png',      usable = false, unique = false, description = 'A raw coca plant leaf' },
    ['pseudoephedrine'] = { label = 'Pseudoephedrine', weight = 150, type = 'drug_material', image = 'pseudoephedrine.png', usable = false, unique = false, description = 'Chemical precursor' },
    ['sassafras_oil']  = { label = 'Sassafras Oil',  weight = 200,  type = 'drug_material', image = 'sassafras_oil.png',  usable = false, unique = false, description = 'Essential oil precursor for MDMA' },
    ['ergot_fungus']   = { label = 'Ergot Fungus',   weight = 60,   type = 'drug_material', image = 'ergot_fungus.png',   usable = false, unique = false, description = 'Parasitic grain fungus' },
    ['opium_poppy']    = { label = 'Opium Poppy',    weight = 120,  type = 'drug_material', image = 'opium_poppy.png',    usable = false, unique = false, description = 'Raw opium poppy pod' },
    ['baking_soda']    = { label = 'Baking Soda',    weight = 100,  type = 'drug_material', image = 'baking_soda.png',    usable = false, unique = false, description = 'Sodium bicarbonate' },

    -- Drug Items - Chemicals / Supplies
    ['methylamine']    = { label = 'Methylamine',    weight = 500,  type = 'drug_material', image = 'methylamine.png',    usable = false, unique = false, description = 'Industrial chemical compound' },
    ['acetone']        = { label = 'Acetone',        weight = 400,  type = 'drug_material', image = 'acetone.png',        usable = false, unique = false, description = 'Chemical solvent' },
    ['rolling_papers'] = { label = 'Rolling Papers', weight = 20,   type = 'drug_material', image = 'rolling_papers.png', usable = false, unique = false, description = 'Papers for rolling' },
    ['small_baggy']    = { label = 'Small Baggy',    weight = 10,   type = 'drug_material', image = 'small_baggy.png',    usable = false, unique = false, description = 'A small sealable bag' },
    ['pill_press_die'] = { label = 'Pill Press Die', weight = 300,  type = 'drug_material', image = 'pill_press_die.png', usable = false, unique = false, description = 'A die for pressing pills' },
    ['diethylamine']   = { label = 'Diethylamine',   weight = 350,  type = 'drug_material', image = 'diethylamine.png',   usable = false, unique = false, description = 'Organic chemistry reagent' },
    ['blotter_paper']  = { label = 'Blotter Paper',  weight = 15,   type = 'drug_material', image = 'blotter_paper.png',  usable = false, unique = false, description = 'Absorbent art paper' },
    ['acetic_anhydride'] = { label = 'Acetic Anhydride', weight = 450, type = 'drug_material', image = 'acetic_anhydride.png', usable = false, unique = false, description = 'Industrial acetylating agent' },
    ['glass_vial']     = { label = 'Glass Vial',     weight = 30,   type = 'drug_material', image = 'glass_vial.png',     usable = false, unique = false, description = 'Small glass container' },

    -- Drug Items - Processed (Intermediate)
    ['dried_weed']     = { label = 'Dried Weed',     weight = 80,   type = 'drug', image = 'dried_weed.png',     usable = false, unique = false, description = 'Dried cannabis buds' },
    ['raw_meth']       = { label = 'Raw Meth',       weight = 120,  type = 'drug', image = 'raw_meth.png',       usable = false, unique = false, description = 'Uncut crystal methamphetamine' },
    ['raw_cocaine']    = { label = 'Raw Cocaine',    weight = 100,  type = 'drug', image = 'raw_cocaine.png',    usable = false, unique = false, description = 'Uncut cocaine paste' },
    ['raw_mdma']       = { label = 'Raw MDMA',       weight = 110,  type = 'drug', image = 'raw_mdma.png',       usable = false, unique = false, description = 'MDMA crystal powder' },
    ['liquid_lsd']     = { label = 'Liquid LSD',     weight = 20,   type = 'drug', image = 'liquid_lsd.png',     usable = false, unique = false, description = 'Concentrated lysergic acid solution' },
    ['crack_rocks']    = { label = 'Crack Rocks',    weight = 90,   type = 'drug', image = 'crack_rocks.png',    usable = false, unique = false, description = 'Freebase cocaine rocks' },
    ['raw_heroin']     = { label = 'Raw Heroin',     weight = 100,  type = 'drug', image = 'raw_heroin.png',     usable = false, unique = false, description = 'Uncut brown heroin' },

    -- Drug Items - Packaged (Sellable)
    ['weed_baggy']     = { label = 'Weed Baggy',     weight = 50,   type = 'drug', image = 'weed_baggy.png',     usable = false, unique = false, description = 'A packaged bag of weed' },
    ['meth_baggy']     = { label = 'Meth Baggy',     weight = 60,   type = 'drug', image = 'meth_baggy.png',     usable = false, unique = false, description = 'A bag of crystal meth' },
    ['cocaine_baggy']  = { label = 'Cocaine Baggy',  weight = 50,   type = 'drug', image = 'cocaine_baggy.png',  usable = false, unique = false, description = 'A bag of cocaine' },
    ['ecstasy_baggy']  = { label = 'Ecstasy Pills',  weight = 40,   type = 'drug', image = 'ecstasy_baggy.png',  usable = false, unique = false, description = 'A bag of pressed ecstasy pills' },
    ['lsd_tab']        = { label = 'LSD Tab',        weight = 5,    type = 'drug', image = 'lsd_tab.png',        usable = false, unique = false, description = 'A sheet of LSD blotter tabs' },
    ['crack_baggy']    = { label = 'Crack Vial',     weight = 45,   type = 'drug', image = 'crack_baggy.png',    usable = false, unique = false, description = 'A vial of crack rocks' },
    ['heroin_baggy']   = { label = 'Heroin Baggy',   weight = 50,   type = 'drug', image = 'heroin_baggy.png',   usable = false, unique = false, description = 'A bag of brown heroin' },

    -- Drug Cutting Agents
    ['creatine_powder'] = { label = 'Creatine Powder', weight = 80,  type = 'material', image = 'creatine_powder.png', usable = false, unique = false, description = 'Bulk fitness supplement powder' },
    ['lactose_powder']  = { label = 'Lactose Powder',  weight = 80,  type = 'material', image = 'lactose_powder.png',  usable = false, unique = false, description = 'Fine white sugar powder' },
    ['caffeine_pills']  = { label = 'Caffeine Pills',  weight = 30,  type = 'material', image = 'caffeine_pills.png',  usable = false, unique = false, description = 'Over-the-counter stimulant pills' },
    ['oregano']         = { label = 'Oregano',         weight = 20,  type = 'material', image = 'oregano.png',         usable = false, unique = false, description = 'Dried herb, looks like something else...' },

    -- Burner Phone
    ['burner_phone']    = { label = 'Burner Phone',    weight = 100, type = 'tool',     image = 'burner_phone.png',    usable = true,  unique = true,  description = 'Untraceable disposable phone for deals' },
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
