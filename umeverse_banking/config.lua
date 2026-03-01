--[[
    Umeverse Banking - Configuration
]]

BankConfig = {}

-- ATM / Bank locations
BankConfig.ATMs = {
    -- Automatically use in-world ATM prop locations
    -- or define custom coords here
}

BankConfig.BankLocations = {
    { coords = vector3(149.5, -1040.2, 29.4),  label = 'Pacific Standard Bank' },
    { coords = vector3(314.2, -278.8, 54.2),   label = 'Maze Bank' },
    { coords = vector3(-350.9, -49.6, 49.0),   label = 'Fleeca Bank' },
    { coords = vector3(-1212.9, -330.4, 37.8),  label = 'Fleeca Bank' },
    { coords = vector3(-2962.6, 482.9, 15.7),   label = 'Fleeca Bank' },
    { coords = vector3(1175.1, 2706.8, 38.1),   label = 'Fleeca Bank' },
}

BankConfig.InteractDistance = 2.0
BankConfig.BlipSprite = 108
BankConfig.BlipColor = 2
BankConfig.BlipScale = 0.8

-- Transaction limits
BankConfig.MaxTransferAmount = 1000000
BankConfig.MinTransferAmount = 1

-- Transaction log limit
BankConfig.MaxTransactionHistory = 50
