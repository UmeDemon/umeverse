--[[
    ██╗   ██╗███╗   ███╗███████╗██╗   ██╗███████╗██████╗ ███████╗███████╗
    Umeverse Gangs System Configuration
]]

GangsConfig = {}

-- Gang Definitions
GangsConfig.Gangs = {
    ['ballas'] = {
        label = 'The Ballas',
        color = 45, -- Purple
        territory = 'south_ls',
        founded = 1980,
        description = 'South Los Santos criminal organization',
        spawnPoint = { x = -155.32, y = -1605.43, z = 33.15, h = 140.0 },
    },
    ['families'] = {
        label = 'Families',
        color = 2, -- Green
        territory = 'grove_street',
        founded = 1975,
        description = 'Grove Street families crew',
        spawnPoint = { x = -124.83, y = -1569.11, z = 33.15, h = 220.0 },
    },
    ['vagos'] = {
        label = 'Los Santos Vagos',
        color = 75, -- Yellow
        territory = 'east_ls',
        founded = 1992,
        description = 'East Los Santos street gang',
        spawnPoint = { x = 325.45, y = -1006.32, z = 29.44, h = 90.0 },
    },
    ['lost'] = {
        label = 'The Lost MC',
        color = 1, -- Red
        territory = 'north_ls',
        founded = 1985,
        description = 'Motorcycle club',
        spawnPoint = { x = 266.5, y = 374.8, z = 105.9, h = 180.0 },
    },
    ['mexican'] = {
        label = 'Cartel Del Los Santos',
        color = 26, -- Brown
        territory = 'vinewood',
        founded = 2000,
        description = 'Drug trafficking organization',
        spawnPoint = { x = 1178.5, y = -1455.3, z = 34.7, h = 45.0 },
    },
    ['lspd'] = {
        label = 'LSPD Gang Unit',
        color = 0, -- Blue (Corrupt cops)
        territory = 'pillbox',
        founded = 1985,
        description = 'Corrupt police unit (or player-created)',
        spawnPoint = { x = 441.5, y = -987.3, z = 29.4, h = 270.0 },
    },
}

-- Gang Ranks
GangsConfig.Ranks = {
    [0] = { label = 'Prospect', permissions = {} },
    [1] = { label = 'Street Soldier', permissions = { 'sell_drugs', 'rob_territory' } },
    [2] = { label = 'Enforcer', permissions = { 'sell_drugs', 'rob_territory', 'recruit', 'manage_stash' } },
    [3] = { label = 'Lieutenant', permissions = { 'sell_drugs', 'rob_territory', 'recruit', 'manage_stash', 'declare_war', 'manage_territory' } },
    [4] = { label = 'Captain', permissions = { 'sell_drugs', 'rob_territory', 'recruit', 'manage_stash', 'declare_war', 'manage_territory', 'disband_war', 'remove_member' } },
    [5] = { label = 'Gang Leader', permissions = { '*' } }, -- All permissions
}

-- Territories (Turfs)
GangsConfig.Territories = {
    ['south_ls'] = {
        label = 'South LS',
        gang = 'ballas',
        influence = 100,
        boundingBox = { x1 = -400, y1 = -1650, x2 = 100, y2 = -1200 },
        drugSales = true,
        drugMultiplier = 1.5, -- 50% bonus on drug sales in controlled territory
        criminalActivity = true,
        safeHouse = { x = -155.32, y = -1605.43, z = 33.15 },
        blip = { type = 9, color = 45, scale = 0.9 },
    },
    ['grove_street'] = {
        label = 'Grove Street',
        gang = 'families',
        influence = 100,
        boundingBox = { x1 = -300, y1 = -1450, x2 = 50, y2 = -1050 },
        drugSales = true,
        drugMultiplier = 1.5,
        criminalActivity = true,
        safeHouse = { x = -124.83, y = -1569.11, z = 33.15 },
        blip = { type = 9, color = 2, scale = 0.9 },
    },
    ['east_ls'] = {
        label = 'East LS',
        gang = 'vagos',
        influence = 100,
        boundingBox = { x1 = 100, y1 = -1200, x2 = 500, y2 = -800 },
        drugSales = true,
        drugMultiplier = 1.5,
        criminalActivity = true,
        safeHouse = { x = 325.45, y = -1006.32, z = 29.44 },
        blip = { type = 9, color = 75, scale = 0.9 },
    },
    ['north_ls'] = {
        label = 'North LS',
        gang = 'lost',
        influence = 100,
        boundingBox = { x1 = -200, y1 = 100, x2 = 400, y2 = 600 },
        drugSales = true,
        drugMultiplier = 1.3,
        criminalActivity = true,
        safeHouse = { x = 266.5, y = 374.8, z = 105.9 },
        blip = { type = 9, color = 1, scale = 0.9 },
    },
    ['vinewood'] = {
        label = 'Vinewood',
        gang = 'mexican',
        influence = 100,
        boundingBox = { x1 = 700, y1 = -1200, x2 = 1400, y2 = -600 },
        drugSales = true,
        drugMultiplier = 1.8, -- Cartel gets best rates on drug sales
        criminalActivity = true,
        safeHouse = { x = 1178.5, y = -1455.3, z = 34.7 },
        blip = { type = 9, color = 26, scale = 0.9 },
    },
}

-- Criminal Enterprises (Gang-specific crime missions)
GangsConfig.Enterprises = {
    ['drug_runs'] = {
        label = 'Drug Supply Runs',
        tier = 1,
        rewards = { black_money = { min = 500, max = 1500 }, reputation = 25 },
        duration = 900, -- 15 minutes
        gangBonus = 1.3, -- Gang members get 30% bonus
    },
    ['protection_racket'] = {
        label = 'Protection Racket',
        tier = 1,
        rewards = { black_money = { min = 800, max = 2000 }, reputation = 40 },
        duration = 1200,
        gangBonus = 1.5,
    },
    ['territory_defense'] = {
        label = 'Defend Territory',
        tier = 2,
        rewards = { black_money = { min = 2000, max = 5000 }, reputation = 60 },
        duration = 1800,
        gangBonus = 2.0,
        requiresTeam = true,
    },
    ['heist_planning'] = {
        label = 'Plan Heist',
        tier = 3,
        rewards = { black_money = { min = 10000, max = 30000 }, reputation = 150 },
        duration = 3600,
        gangBonus = 2.5,
        requiresTeam = true,
    },
}

-- Gang War System
GangsConfig.GangWar = {
    enabled = true,
    minDuration = 600, -- 10 minutes
    maxDuration = 1800, -- 30 minutes
    territoryRewardMultiplier = 2.0,
    crimeRewardBonus = 1.5,
    maxSimultaneousWars = 2,
    warCooldown = 3600, -- 1 hour between wars
}

-- Gang Bank/Stash
GangsConfig.StashSystem = {
    maxCapacity = 500000, -- Max black money in gang stash
    depositFee = 0.02, -- 2% fee on deposits
    withdrawFee = 0.05, -- 5% fee on withdrawals
    weaponStorage = true,
    maxWeapons = 20,
}

-- Reputation & Leveling
GangsConfig.Reputation = {
    maxLevel = 20,
    xpPerLevel = 1000,
    prestigeAvailable = true,
    prestigeMultiplier = 1.5,
    reputationMilestones = {
        [5] = { label = 'Associate', reward = { black_money = 5000 } },
        [10] = { label = 'Made Man', reward = { black_money = 15000 } },
        [15] = { label = 'Elite Member', reward = { black_money = 30000 } },
        [20] = { label = 'Mafia Elite', reward = { black_money = 50000 } },
    },
}

-- Integration with Drug System
GangsConfig.DrugIntegration = {
    territoryBonus = {
        productionSpeed = 1.3, -- 30% faster production in controlled territory
        salePrice = 1.5, -- 50% better prices in controlled territory
        warehouseCapacity = 1.2, -- 20% more warehouse capacity
    },
    warEffects = {
        disruptSupply = true, -- War disrupts enemy drug supply
        priceFluctuation = true, -- Prices change based on territory control
    },
    gangDealers = {
        enabled = true,
        requirement = 'gang_member',
        exclusiveDeals = true, -- Only gang members can sell in territory
    },
}

return GangsConfig
