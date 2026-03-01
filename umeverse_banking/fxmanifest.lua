--[[
    Umeverse Banking System
]]

fx_version 'cerulean'
game 'gta5'

name 'umeverse_banking'
author 'Umeverse'
description 'Umeverse Framework - Banking & Economy System'
version '1.0.0'

shared_scripts {
    'config.lua',
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/main.lua',
}

client_scripts {
    'client/main.lua',
}

ui_page 'html/index.html'

files {
    'html/index.html',
    'html/style.css',
    'html/script.js',
}

dependencies {
    'umeverse_core',
    'oxmysql',
}

lua54 'yes'
