--[[
    ██╗   ██╗███╗   ███╗███████╗██╗   ██╗███████╗██████╗ ███████╗███████╗
    ██║   ██║████╗ ████║██╔════╝██║   ██║██╔════╝██╔══██╗██╔════╝██╔════╝
    ██║   ██║██╔████╔██║█████╗  ██║   ██║█████╗  ██████╔╝███████╗█████╗
    ██║   ██║██║╚██╔╝██║██╔══╝  ╚██╗ ██╔╝██╔══╝  ██╔══██╗╚════██║██╔══╝
    ╚██████╔╝██║ ╚═╝ ██║███████╗ ╚████╔╝ ███████╗██║  ██║███████║███████╗
     ╚═════╝ ╚═╝     ╚═╝╚══════╝  ╚═══╝  ╚═══╝╚═╝  ╚═╝╚══════╝╚══════╝
    
    Umeverse Framework - Crime System
    Street crimes, burglary, hacking, heat mechanics, and gang integration
]]

fx_version 'cerulean'
game 'gta5'

name 'umeverse_crime'
author 'Umeverse'
description 'Umeverse Framework - Crime System (Street Crimes, Burglary, Hacking, Heat, Gang Integration)'
version '1.0.0'

dependencies {
    'umeverse_core',
    'oxmysql',
    'umeverse_drugs',
}

shared_scripts {
    '@umeverse_core/config.lua',
    'config.lua',
}

client_scripts {
    'client/utils.lua',
    'client/blips.lua',
    'client/pickpocket.lua',
    'client/store_robbery.lua',
    'client/car_theft.lua',
    'client/burglary.lua',
    'client/atm_robbery.lua',
    'client/hacking.lua',
    'client/heat.lua',
    'client/dispatch.lua',
    'client/specializations_menu.lua',
    'client/bounties_menu.lua',
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/main.lua',
    'server/crimes.lua',
    'server/heat.lua',
    'server/dispatch.lua',
    'server/specialization.lua',
    'server/reputation.lua',
    'server/specializations.lua',
    'server/dynamics.lua',
    'server/bounties.lua',
    'server/consequences.lua',
}
