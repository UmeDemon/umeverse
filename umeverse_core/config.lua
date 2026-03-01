--[[
    Umeverse Framework - Core Configuration
]]

UmeConfig = {}

-- Server Info
UmeConfig.ServerName = 'Umeverse RP'
UmeConfig.MaxCharacters = 3           -- Max characters per player
UmeConfig.DefaultSpawn = vector4(-269.4, -955.3, 31.2, 205.8) -- Default spawn location

-- Money
UmeConfig.StartingCash = 5000
UmeConfig.StartingBank = 10000

-- Character Defaults
UmeConfig.DefaultModel = 'mp_m_freemode_01'
UmeConfig.DefaultJob = 'unemployed'
UmeConfig.DefaultJobGrade = 0

-- Multicharacter
UmeConfig.EnableMulticharacter = true

-- Auto-save interval (in minutes)
UmeConfig.AutoSaveInterval = 5

-- Death
UmeConfig.RespawnTime = 300 -- 5 minutes in seconds
UmeConfig.RespawnCost = 2500
UmeConfig.HospitalSpawn = vector4(311.7, -590.1, 43.3, 70.0)

-- PvP
UmeConfig.EnablePvP = true

-- Status (hunger, thirst)
UmeConfig.EnableStatus = true
UmeConfig.HungerDecayRate = 0.5   -- per minute
UmeConfig.ThirstDecayRate = 0.65  -- per minute
UmeConfig.StatusDamageThreshold = 10 -- Below this %, take damage

-- Logging
UmeConfig.EnableLogging = true
UmeConfig.LogWebhook = '' -- Discord webhook URL

-- Identifier
UmeConfig.IdentifierType = 'license' -- license, steam, discord, fivem
