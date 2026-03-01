--[[
    Umeverse Bridge - TMC (The Modding Collective) Compatibility Layer
    Allows TMC scripts to run on Umeverse without modification

    TMC's resource name is "core" and scripts call:
        local TMC = exports['core']:GetCoreObject()
    TMC also has heavy QBCore compatibility built in, so many TMC scripts
    use QBCore events (QBCore:Client:OnPlayerLoaded, etc.) alongside TMC ones.
]]

fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'umeverse_bridge_tmc'
description 'TMC (The Modding Collective) compatibility bridge for Umeverse Framework'
author 'Umeverse'
version '1.0.0'

-- This tells FiveM "I am core"
-- exports['core'] will route here
provide 'core'

dependencies {
    'umeverse_core',
    'oxmysql',
}

shared_scripts {
    'shared/main.lua',
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/main.lua',
}

client_scripts {
    'client/main.lua',
}
