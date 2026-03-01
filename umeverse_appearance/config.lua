--[[
    Umeverse Appearance - Configuration
]]

AppearConfig = {}

-- Clothing store locations
AppearConfig.ClothingStores = {
    vector3(  72.3, -1399.1, 29.4),
    vector3( -703.8,  -152.3, 37.4),
    vector3(-1193.4,  -767.2, 17.3),
    vector3( 428.7,  -800.1, 29.5),
    vector3(-167.9,  -299.0, 39.7),
    vector3(  75.4,  -729.6, 33.2),
    vector3(-829.4,  -1073.7, 11.3),
    vector3(  -0.5,  6511.5, 31.9),
    vector3(1696.3,  4829.3, 42.1),
    vector3( 614.1,  2763.6, 42.1),
    vector3(1190.6,  2713.4, 38.2),
    vector3(-1108.4,  2708.9, 19.1),
}

-- Barber shops
AppearConfig.BarberShops = {
    vector3(-814.3,  -183.8, 37.6),
    vector3(136.8,   -1708.4, 29.3),
    vector3(-1282.6, -1116.8, 6.99),
    vector3(1931.5,   3729.7, 32.8),
    vector3(1212.8,  -472.9, 66.2),
    vector3(-32.9,   -152.3, 57.1),
    vector3(-278.1,  6228.5, 31.7),
}

-- Blip settings
AppearConfig.Blips = {
    clothing = { sprite = 73, color = 3, scale = 0.7 },
    barber   = { sprite = 71, color = 4, scale = 0.7 },
}

-- Interaction distance
AppearConfig.InteractDistance = 2.0

-- Camera settings for appearance menu
AppearConfig.CameraOffset = vector3(0.0, 0.8, 0.3)
AppearConfig.CamFov = 40.0
