--[[
    ╔══════════════════════════════════════════════════════════════════╗
    ║  LEGACY / STANDALONE resource — kept for backwards compat.     ║
    ║                                                                ║
    ║  If you are using the modular Umeverse framework deployed by   ║
    ║  the txAdmin recipe, do NOT ensure this resource.  Instead,    ║
    ║  ensure umeverse_core (and the other umeverse_* resources).    ║
    ║                                                                ║
    ║  Running both this resource AND umeverse_core simultaneously   ║
    ║  will cause conflicts (duplicate table schemas, duplicate      ║
    ║  events, etc.).                                                ║
    ╚══════════════════════════════════════════════════════════════════╝
]]

fx_version 'cerulean'
game 'gta5'
lua54 'yes'

author 'UmeDemon'
description 'UmeVerse framework'
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
