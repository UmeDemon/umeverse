--[[
    Umeverse Bridge - ESX Compatibility Layer
    Allows ESX scripts to run on Umeverse without modification
]]

fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'umeverse_bridge_esx'
description 'ESX compatibility bridge for Umeverse Framework'
author 'Umeverse'
version '1.0.0'

-- This tells FiveM "I am es_extended"
-- exports['es_extended'] will route here
provide 'es_extended'

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
