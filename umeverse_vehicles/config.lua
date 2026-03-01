--[[
    Umeverse Vehicles - Configuration
]]

VehConfig = {}

-- Garage locations
VehConfig.Garages = {
    ['legion'] = {
        label    = 'Legion Square Garage',
        coords   = vector3(215.8, -810.2, 30.7),
        spawn    = vector4(223.2, -803.3, 30.5, 70.0),
        blip     = { sprite = 357, color = 3, scale = 0.7 },
        type     = 'car',
    },
    ['pillbox'] = {
        label    = 'Pillbox Garage',
        coords   = vector3(65.7, -886.8, 30.5),
        spawn    = vector4(56.3, -886.2, 30.2, 340.0),
        blip     = { sprite = 357, color = 3, scale = 0.7 },
        type     = 'car',
    },
    ['airport'] = {
        label    = 'Airport Parking',
        coords   = vector3(-796.5, -2024.8, 9.6),
        spawn    = vector4(-802.3, -2024.8, 9.3, 320.0),
        blip     = { sprite = 357, color = 3, scale = 0.7 },
        type     = 'car',
    },
    ['police_garage'] = {
        label    = 'Police Garage',
        coords   = vector3(454.6, -1017.4, 28.4),
        spawn    = vector4(447.4, -1025.3, 28.5, 4.0),
        blip     = { sprite = 357, color = 3, scale = 0.7 },
        type     = 'car',
        job      = 'police',
    },
}

-- Impound
VehConfig.ImpoundLocation = vector3(409.1, -1622.8, 29.3)
VehConfig.ImpoundSpawn = vector4(406.8, -1631.5, 29.3, 230.0)
VehConfig.ImpoundPrice = 500

-- Fuel
VehConfig.EnableFuel = true
VehConfig.FuelDecayRate = 0.15 -- per 100m driven

-- Vehicle interaction distance
VehConfig.InteractDistance = 3.0

-- Keys
VehConfig.EnableKeys = true
