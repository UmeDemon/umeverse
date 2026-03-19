--[[
    ██╗   ██╗███╗   ███╗███████╗██╗   ██╗███████╗██████╗ ███████╗███████╗
    ██║   ██║████╗ ████║██╔════╝██║   ██║██╔════╝██╔══██╗██╔════╝██╔════╝
    ██║   ██║██╔████╔██║█████╗  ██║   ██║█████╗  ██████╔╝███████╗█████╗
    ██║   ██║██║╚██╔╝██║██╔══╝  ╚██╗ ██╔╝██╔══╝  ██╔══██╗╚════██║██╔══╝
    ╚██████╔╝██║ ╚═╝ ██║███████╗ ╚████╔╝ ███████╗██║  ██║███████║███████╗
     ╚═════╝ ╚═╝     ╚═╝╚══════╝  ╚═══╝  ╚═══╝╚═╝  ╚═╝╚══════╝╚══════╝
    
    Umeverse Framework - Gangs System
    Gang management, territories, influence, warfare, and criminal enterprises
]]

fx_version 'cerulean'
game 'gta5'

name 'umeverse_gangs'
author 'Umeverse'
description 'Umeverse Framework - Gangs System (Gang Management, Territories, Influence, Warfare, Enterprises)'
version '1.0.0'

dependencies {
    'umeverse_core',
    'oxmysql',
    'umeverse_crime',
    'umeverse_drugs',
}

shared_scripts {
    '@umeverse_core/config.lua',
    'config.lua',
}

client_scripts {
    'client/utils.lua',
    'client/blips.lua',
    'client/menu.lua',
    'client/territories.lua',
    'client/enterprises.lua',
    'client/warfare.lua',
    'client/stash.lua',
    'client/infrastructure_menu.lua',
    'client/alliances_menu.lua',
    'client/communication_menu.lua',
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/main.lua',
    'server/gangs.lua',
    'server/territories.lua',
    'server/enterprises.lua',
    'server/warfare.lua',
    'server/stash.lua',
    'server/reputation.lua',
    'server/ranks.lua',
    'server/territory_expansion.lua',
    'server/infrastructure.lua',
    'server/alliances.lua',
    'server/member_perks.lua',
    'server/siege.lua',
    'server/communication.lua',
}
