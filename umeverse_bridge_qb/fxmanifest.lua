--[[
    Umeverse Bridge - QBCore / QBox Compatibility
    Allows scripts written for QBCore/QBox to work on Umeverse
]]

fx_version 'cerulean'
game 'gta5'

name 'umeverse_bridge_qb'
author 'Umeverse'
description 'QBCore/QBox compatibility bridge for Umeverse Framework'
version '1.0.0'

-- This makes exports['qb-core'] route to this resource
provide 'qb-core'

shared_scripts {
    'shared/main.lua',
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
