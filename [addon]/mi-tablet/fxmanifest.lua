fx_version 'cerulean'
games { 'gta5' }

author 'Legacy Network x UmeDemon'
description 'MI Tablet - Modern Tablet Interface'
version '1.1.0'

lua54 'yes'

shared_scripts {
    'config.lua'
}

client_scripts {
    'client/*.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/*.lua'
}

files {
    'html/**/*.js',
    'html/**/*.html',
    'html/**/*.css',
    'html/**/*.png',
    'html/**/*.jpg'
}

ui_page 'html/index.html'

dependencies {
    'core',
    'oxmysql'
}

escrow_ignore {
    'config.lua',
    'server/*.lua',
    'client/*.lua'
}
