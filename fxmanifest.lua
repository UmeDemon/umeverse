fx_version 'cerulean'
game 'gta5'
lua54 'yes'

author 'UmeDemon'
description 'UmeVerse - Custom FiveM Framework'
version '1.0.0'

shared_scripts {
    'shared/locale.lua',
    'shared/utils.lua',
    'shared/jobs.lua',
    'shared/items.lua',
    'shared/main.lua',
    'config.lua',
}

client_scripts {
    'client/main.lua',
    'client/functions.lua',
    'client/events.lua',
    'client/spawn.lua',
    'client/hud.lua',
}

server_scripts {
    'server/player.lua',
    'server/functions.lua',
    'server/main.lua',
    'server/events.lua',
    'server/database.lua',
    'server/commands.lua',
}

ui_page 'html/index.html'

files {
    'html/index.html',
    'locale/en.lua',
}

-- oxmysql is optional; the framework falls back to in-memory storage without it.
dependency '/assetpacks'
