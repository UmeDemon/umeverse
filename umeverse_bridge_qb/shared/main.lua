--[[
    Umeverse Bridge - QBCore Shared
    Initializes the QBCore compatibility object
]]

QBCore = {}
QBCore.Functions = {}
QBCore.PlayerData = {}
QBCore.Config = {}
QBCore.Shared = {}

-- Map shared data from Umeverse
local UME = exports['umeverse_core']:GetCoreObject()

QBCore.Shared.Jobs = UME.Jobs or {}
QBCore.Shared.Items = UME.Items or {}
QBCore.Shared.Vehicles = {}
QBCore.Shared.Weapons = {}
QBCore.Shared.Gangs = {}

-- Config mappings
QBCore.Config.DefaultSpawn = UmeConfig and UmeConfig.DefaultSpawn or vector4(-269.4, -955.3, 31.2, 205.8)
QBCore.Config.Money = UmeConfig and {
    Cash = UmeConfig.StartingCash or 500,
    Bank = UmeConfig.StartingBank or 5000,
} or { Cash = 500, Bank = 5000 }
