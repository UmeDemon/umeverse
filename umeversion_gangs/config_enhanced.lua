--[[
    ██╗   ██╗███╗   ██╗███████╗██╗   ██╗███████╗██████╗ ███████╗███████╗
    Umeverse Gangs System - Enhanced Configuration
    All enhancements: Territory expansion, Guild infrastructure, Alliances, Perks
]]

GangsConfig = {}

-- ENHANCED GANG DEFINITIONS
GangsConfig.Gangs = {
    ['ballas'] = {
        label = 'The Ballas',
        color = 45,
        territory = 'south_ls',
        founded = 1980,
        description = 'South Los Santos criminal organization',
        spawnPoint = { x = -155.32, y = -1605.43, z = 33.15, h = 140.0 },
        uniqueBonuses = {
            drugSaleBonus = 0.25, -- +25% drug sales
            wantedLevelReduction = 0.15, -- -15% wanted level
            territoryDefenseBonus = 1.0,
        },
    },
    ['families'] = {
        label = 'Families',
        color = 2,
        territory = 'grove_street',
        founded = 1975,
        description = 'Grove Street families crew',
        spawnPoint = { x = -124.83, y = -1569.11, z = 33.15, h = 220.0 },
        uniqueBonuses = {
            robberyRewardBonus = 0.20, -- +20% robbery rewards
            territoryDefenseBonus = 1.10,
            memberLoyalty = 0.10, -- +10% member retention
        },
    },
    ['vagos'] = {
        label = 'Los Santos Vagos',
        color = 75,
        territory = 'east_ls',
        founded = 1992,
        description = 'East Los Santos street gang',
        spawnPoint = { x = 325.45, y = -1006.32, z = 29.44, h = 90.0 },
        uniqueBonuses = {
            vehicleTheftBonus = 0.30, -- +30% vehicle theft rewards
            customizationSpeed = 0.30, -- 30% faster customization
            carReq = true, -- Free motorcycle requisition
        },
    },
    ['lost'] = {
        label = 'The Lost MC',
        color = 1,
        territory = 'north_ls',
        founded = 1985,
        description = 'Motorcycle club',
        spawnPoint = { x = 266.5, y = 374.8, z = 105.9, h = 180.0 },
        uniqueBonuses = {
            motorcycleBonus = 0.50, -- +50% motorcycle perks
            bikeReq = true, -- Free bike requisition
            fuelReduction = 0.20, -- 20% less fuel cost
        },
    },
    ['mexican'] = {
        label = 'Cartel Del Los Santos',
        color = 26,
        territory = 'vinewood',
        founded = 2000,
        description = 'Drug trafficking organization',
        spawnPoint = { x = 1178.5, y = -1455.3, z = 34.7, h = 45.0 },
        uniqueBonuses = {
            drugProductionBonus = 0.40, -- +40% drug production
            warehouseCapacityBonus = 2, -- +2 warehouse slots
            importMissionsUnlock = true,
        },
    },
}

-- ENHANCED RANKS WITH MEMBER PERKS
GangsConfig.Ranks = {
    [0] = {
        label = 'Prospect',
        permissions = {},
        perks = {},
    },
    [1] = {
        label = 'Street Soldier',
        permissions = { 'sell_drugs', 'rob_territory' },
        perks = {
            weaponDamageBonus = 0.10,
            drugSalesBonus = 0.0,
        },
    },
    [2] = {
        label = 'Enforcer',
        permissions = { 'sell_drugs', 'rob_territory', 'recruit', 'manage_stash' },
        perks = {
            weaponDamageBonus = 0.15,
            freeArmorPerHour = true,
            healthRegenBonus = 0.10,
            emergencyCallNPC = false, -- Can't call yet
        },
    },
    [3] = {
        label = 'Lieutenant',
        permissions = { 'sell_drugs', 'rob_territory', 'recruit', 'manage_stash', 'declare_war', 'manage_territory' },
        perks = {
            weaponDamageBonus = 0.20,
            freeArmorPerHour = true,
            healthRegenBonus = 0.15,
            emergencyCallNPC = true, -- Can call NPC backup
            npcBackupCount = 2,
            passiveCrimeRewardBonus = 0.05,
        },
    },
    [4] = {
        label = 'Captain',
        permissions = { 'sell_drugs', 'rob_territory', 'recruit', 'manage_stash', 'declare_war', 'manage_territory', 'disband_war', 'remove_member' },
        perks = {
            weaponDamageBonus = 0.25,
            freeArmorPerHour = true,
            healthRegenBonus = 0.20,
            emergencyCallNPC = true,
            npcBackupCount = 4,
            passiveCrimeRewardBonus = 0.10,
            commandTerritory = true,
        },
    },
    [5] = {
        label = 'Gang Leader',
        permissions = { '*' },
        perks = {
            weaponDamageBonus = 0.30,
            freeArmorPerHour = true,
            healthRegenBonus = 0.25,
            emergencyCallNPC = true,
            npcBackupCount = 6,
            passiveCrimeRewardBonus = 0.15,
            commandTerritory = true,
            infraUpgrades = true,
            declareAlliances = true,
        },
    },
}

-- TERRITORY EXPANSION SYSTEM
GangsConfig.TerritoryExpansion = {
    enabled = true,
    expansionMissions = {
        enabled = true,
        missionTypes = {
            ['scout_zone'] = { label = 'Scout Zone', reward = 100, influence = 5, duration = 300 },
            ['recruit_locals'] = { label = 'Recruit Locals', reward = 500, influence = 10, danger = 'medium' },
            ['eliminate_rivals'] = { label = 'Eliminate Rivals', reward = 2000, influence = 25, danger = 'high', teamRequired = true },
            ['establish_foothold'] = { label = 'Establish Foothold', reward = 5000, influence = 50, danger = 'extreme', prep = true },
        },
    },
    passiveInfluence = {
        enabled = true,
        ratePerHour = 2.5, -- 2.5 influence per hour per controlled territory
        memberActivityMultiplier = 0.5, -- +0.5 per active member
        requiresLeaderPresence = false, -- Can passively expand without leader
    },
    adjacentExpansion = {
        enabled = true,
        adjacentBonus = 1.5, -- 1.5x influence gain when expanding to adjacent territory
        costReduction = 0.25, -- 25% cheaper mission cost for adjacent territories
    },
}

-- GANG INFRASTRUCTURE UPGRADES
GangsConfig.Infrastructure = {
    enabled = true,
    upgrades = {
        ['drug_production'] = {
            label = 'Drug Production Facility',
            maxLevel = 10,
            costs = { [1] = 2000, [5] = 5000, [10] = 10000 },
            bonuses = {
                [1] = { productionSpeed = 0.10 },
                [5] = { productionSpeed = 0.30 },
                [10] = { productionSpeed = 0.50 },
            },
        },
        ['police_bribery'] = {
            label = 'Police Bribery Network',
            maxLevel = 5,
            costs = { [1] = 5000, [5] = 15000 },
            bonuses = {
                [1] = { heatReductionPerMinute = 1 },
                [5] = { heatReductionPerMinute = 3 },
            },
            maintenanceCostPerWeek = 5000,
        },
        ['soldier_morale'] = {
            label = 'Soldier Morale',
            maxLevel = 10,
            costs = { [1] = 1000, [5] = 3000, [10] = 5000 },
            bonuses = {
                [1] = { npcMemberBonusStats = 0.10 },
                [5] = { npcMemberBonusStats = 0.30 },
                [10] = { npcMemberBonusStats = 0.50 },
            },
        },
        ['armory'] = {
            label = 'Armory',
            maxLevel = 1,
            costs = { [1] = 10000 },
            bonuses = {
                [1] = { weaponInventory = 50 },
            },
        },
    },
}

-- GANG MEMBER MANAGEMENT
GangsConfig.MemberManagement = {
    recruited = {
        enabled = true,
        npcCost = 500, -- Cost to recruit NPC gang member
        maxNPCPerTerritory = 10,
        npcStats = {
            health = 100,
            armor = 50,
            weaponDamage = 1.0,
        },
    },
    activityTracking = {
        enabled = true,
        inactivityKickTime = 604800, -- 7 days
        autoPromoteInactive = 300, -- 5 days before auto-demotion warning
    },
}

-- GANG COMMUNICATION & EVENTS
GangsConfig.Communication = {
    safeHouse = {
        enabled = true,
        npcBartender = true,
        messageBoard = true, -- Members can leave notes
        headquarters = true,
    },
    events = {
        enabled = true,
        weeklyChallenge = {
            ['most_kills'] = { reward = 5000, reputationReward = 100 },
            ['most_crime_earnings'] = { reward = 10000, reputationReward = 150 },
            ['territory_defense'] = { reward = 8000, reputationReward = 120 },
        },
        monthlyTournament = true, -- Gang vs gang competition
    },
    rivalInteractions = {
        enabled = true,
        npcRivalMembers = true,
        streetFights = true,
        frequency = 'daily', -- Can occur daily at random times
    },
}

-- GANG ALLIANCES SYSTEM
GangsConfig.Alliances = {
    enabled = true,
    allianceTypes = {
        ['temporary'] = {
            label = 'Temporary Alliance',
            duration = 86400, -- 24 hours
            costEstablish = 5000,
            bonuses = {
                sharedCrimeRewards = 0.15,
                mutualDefense = true,
                intellSharing = true,
            },
        },
        ['treaty'] = {
            label = 'Treaty',
            duration = 604800, -- 7 days
            costEstablish = 15000,
            costMaintain = 3000, -- Per day
            bonuses = {
                sharedCrimeRewards = 0.25,
                neutralTerritories = true,
                jointEnterprises = true,
                intellSharing = true,
                noWarAllowed = true,
            },
        },
    },
    multiGangHeists = {
        enabled = true,
        requireAllies = true,
        minAllies = 2,
        maxAllies = 4,
        rewards = {
            rewardMultiplier = 3.0, -- 3x normal heist rewards
            bonusForCoordination = 1.5, -- Extra 1.5x if all succeed  simultaneously
        },
    },
}

-- GANG CUSTOMIZATION
GangsConfig.Customization = {
    vehicles = {
        enabled = true,
        customPaint = true,
        gangMarkers = true,
        uniqueModels = {
            ['families'] = 'sabregt',
            ['ballas'] = 'buccaneer2',
            ['vagos'] = 'phoenix',
            ['lost'] = 'bagger',
            ['mexican'] = 'dubsta2',
        },
    },
    clothing = {
        enabled = true,
        exclusiveOutfits = true,
        gangColors = true,
        tattoos = {
            enabled = true,
            exclusiveDesigns = true,
        },
    },
    flags = {
        enabled = true,
        territoryMarkers = true,
        customColors = true,
    },
    radio = {
        enabled = true,
        customStation = true,
        territoryBroadcast = true,
    },
}

-- GANG CUSTOMIZATION (Unique per gang)
GangsConfig.GangUniqueBonuses = {
    ['ballas'] = {
        label = 'Ballas Street Dealer',
        description = 'Ballas dominate street-level drug distribution',
        drugSalesBonus = 0.25,
        wantedLevelReduction = 0.15,
        territoryDefenseBonus = 1.0,
    },
    ['families'] = {
        label = 'Families Street Muscle',
        description = 'Families are known for robbery expertise',
        robberyRewardBonus = 0.20,
        territoryDefenseBonus = 1.10,
        memberLoyalty = 0.10,
    },
    ['vagos'] = {
        label = 'Vagos Car Thieves',
        description = 'Vagos specialize in vehicle theft',
        vehicleTheftBonus = 0.30,
        customizationSpeedBonus = 0.30,
        bikeRequisition = true,
    },
    ['lost'] = {
        label = 'Lost Motorcycle Club',
        description = 'The Lost dominate motorcycle culture',
        motorcycleBonus = 0.50,
        bikeRequisition = true,
        fuelReduction = 0.20,
    },
    ['mexican'] = {
        label = 'Cartel Drug Empire',
        description = 'Cartel controls major drug operations',
        drugProductionBonus = 0.40,
        warehouseCapacityBonus = 2,
        importMissionsUnlock = true,
    },
}

-- ENHANCED TERRITORIES
GangsConfig.Territories = {
    ['south_ls'] = {
        label = 'South LS',
        gang = 'ballas',
        influence = 100,
        boundingBox = { x1 = -400, y1 = -1650, x2 = 100, y2 = -1200 },
        drugSales = true,
        drugMultiplier = 1.5,
        criminalActivity = true,
        safeHouse = { x = -155.32, y = -1605.43, z = 33.15 },
        blip = { type = 9, color = 45, scale = 0.9 },
        baseInfluence = 100,
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
        baseInfluence = 100,
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
        baseInfluence = 100,
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
        baseInfluence = 100,
    },
    ['vinewood'] = {
        label = 'Vinewood',
        gang = 'mexican',
        influence = 100,
        boundingBox = { x1 = 700, y1 = -1200, x2 = 1400, y2 = -600 },
        drugSales = true,
        drugMultiplier = 1.8,
        criminalActivity = true,
        safeHouse = { x = 1178.5, y = -1455.3, z = 34.7 },
        blip = { type = 9, color = 26, scale = 0.9 },
        baseInfluence = 100,
    },
}

-- GANG WARFARE (ENHANCED)
GangsConfig.GangWar = {
    enabled = true,
    minDuration = 600,
    maxDuration = 1800,
    siegeMechanics = {
        enabled = true,
        siegeDuration = 259200, -- 3 days for siege
        dailyInfluenceShift = 10, -- Territory influence shifts 10 per day
        defenderBonus = 1.5, -- Defenders get 1.5x bonus in their territory
    },
    territoryRewardMultiplier = 2.0,
    crimeRewardBonus = 1.5,
    maxSimultaneousWars = 3, -- Can have up to 3 concurrent wars
    warCooldown = 3600,
    truce = {
        enabled = true,
        costToNegotiate = 10000,
        territoryExchange = true,
        moneyExchange = true,
    },
    revenge = {
        enabled = true,
        autoTriggerOnBetrayal = true,
        revengeWaitTime = 1800, -- 30 minutes after betrayal before can trigger
    },
}

-- CRIMINAL ENTERPRISES (ENHANCED)
GangsConfig.Enterprises = {
    ['drug_runs'] = { label = 'Drug Supply Runs', tier = 1, rewards = { black_money = { min = 500, max = 1500 }, reputation = 25 }, duration = 900, gangBonus = 1.3 },
    ['protection_racket'] = { label = 'Protection Racket', tier = 1, rewards = { black_money = { min = 800, max = 2000 }, reputation = 40 }, duration = 1200, gangBonus = 1.5 },
    ['territory_defense'] = { label = 'Defend Territory', tier = 2, rewards = { black_money = { min = 2000, max = 5000 }, reputation = 60 }, duration = 1800, gangBonus = 2.0, requiresTeam = true },
    ['heist_planning'] = { label = 'Plan Heist', tier = 3, rewards = { black_money = { min = 10000, max = 30000 }, reputation = 150 }, duration = 3600, gangBonus = 2.5, requiresTeam = true },
    ['import_shipment'] = { label = 'Import Shipment', tier = 3, rewards = { black_money = { min = 15000, max = 40000 }, reputation = 200 }, duration = 2700, gangBonus = 3.0, requiresTeam = true, cartelOnly = true },
}

-- REPUTATION & LEVELING (ENHANCED)
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
    leaderboard = {
        enabled = true,
        rankBy = { 'wealth', 'killCount', 'territoryControl', 'drugRevenue' },
        seasonDuration = 2592000, -- 30 days
        seasonRewards = {
            [1] = { black_money = 100000 },
            [2] = { black_money = 75000 },
            [3] = { black_money = 50000 },
        },
    },
}

-- GANG BANK/STASH
GangsConfig.StashSystem = {
    maxCapacity = 500000,
    depositFee = 0.02,
    withdrawFee = 0.05,
    weaponStorage = true,
    maxWeapons = 50, -- Enhanced from 20
}

-- PERMANENT CONSEQUENCES
GangsConfig.Consequences = {
    territoryLossRecession = {
        enabled = true,
        incomePenalty = 0.20, -- 20% income reduction
        duration = 86400, -- 24 hours
    },
    gangDissolution = {
        enabled = true,
        triggerThreshold = 0.25, -- Lose 75% territory (25% remain)
        allowVoteDisbandment = true,
    },
    memberDeathRevenge = {
        enabled = true,
        hireDetectiveOnKill = true,
        revengeAutomated = true,
    },
}

-- INTEGRATION WITH DRUGS
GangsConfig.DrugIntegration = {
    territoryBonus = {
        productionSpeed = 1.3,
        salePrice = 1.5,
        warehouseCapacity = 1.2,
    },
    warEffects = {
        disruptSupply = true,
        priceFluctuation = true,
    },
    gangDealers = {
        enabled = true,
        requirement = 'gang_member',
        exclusiveDeals = true,
    },
}

return GangsConfig
