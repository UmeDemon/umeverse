fx_version 'cerulean'
game 'gta5'
lua54 'yes'

author 'UmeDemon'
description 'UmeVerse - Custom FiveM Framework'
version '1.0.0'

shared_scripts {
    'shared/locale.lua',
    'shared/utils.lua',
    'shared/main.lua',
    'config.lua',
}

client_scripts {
    'client/main.lua',
    'client/functions.lua',
    'client/events.lua',
}

server_scripts {
    'server/player.lua',
    'server/functions.lua',
    'server/main.lua',
    'server/events.lua',
}

ui_page 'html/index.html'

files {
    'html/index.html',
    'locale/en.lua',
}
