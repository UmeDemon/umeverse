--[[
    ██╗   ██╗███╗   ███╗███████╗██╗   ██╗███████╗██████╗ ███████╗███████╗
    ██║   ██║████╗ ████║██╔════╝██║   ██║██╔════╝██╔══██╗██╔════╝██╔════╝
    ██║   ██║██╔████╔██║█████╗  ██║   ██║█████╗  ██████╔╝███████╗█████╗
    ██║   ██║██║╚██╔╝██║██╔══╝  ╚██╗ ██╔╝██╔══╝  ██╔══██╗╚════██║██╔══╝
    ╚██████╔╝██║ ╚═╝ ██║███████╗ ╚████╔╝ ███████╗██║  ██║███████║███████╗
     ╚═════╝ ╚═╝     ╚═╝╚══════╝  ╚═══╝  ╚══════╝╚═╝  ╚═╝╚══════╝╚══════╝
    
    Umeverse Framework - Core Resource
    A custom FiveM framework
]]

fx_version 'cerulean'
game 'gta5'

name 'umeverse_core'
author 'Umeverse'
description 'Umeverse Framework - Core Resource'
version '1.0.0'

-- Shared scripts (loaded on both server and client)
shared_scripts {
    'config.lua',
    'shared/*.lua',
}

-- Server scripts
server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/main.lua',
    'server/player.lua',
    'server/callbacks.lua',
    'server/commands.lua',
    'server/functions.lua',
}

-- Client scripts
client_scripts {
    'client/main.lua',
    'client/player.lua',
    'client/callbacks.lua',
    'client/functions.lua',
}

-- NUI
ui_page 'html/index.html'

files {
    'html/index.html',
    'html/style.css',
    'html/script.js',
}

-- Dependencies
dependencies {
    'oxmysql',
}

-- Exports
lua54 'yes'
