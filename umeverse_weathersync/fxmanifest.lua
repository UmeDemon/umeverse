--[[
    Umeverse Weather & Time Sync
]]

fx_version 'cerulean'
game 'gta5'

name 'umeverse_weathersync'
author 'Umeverse'
description 'Umeverse Framework - Server-synchronized weather & time'
version '1.0.0'

shared_scripts {
    'config.lua',
}

server_scripts {
    'server/main.lua',
}

client_scripts {
    'client/main.lua',
}

dependencies {
    'umeverse_core',
}

lua54 'yes'
