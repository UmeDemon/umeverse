--[[
    Umeverse Appearance System
]]

fx_version 'cerulean'
game 'gta5'

name 'umeverse_appearance'
author 'Umeverse'
description 'Umeverse Framework - Character appearance & clothing'
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

ui_page 'html/index.html'

files {
    'html/index.html',
    'html/style.css',
    'html/script.js',
}

dependencies {
    'umeverse_core',
}

lua54 'yes'
