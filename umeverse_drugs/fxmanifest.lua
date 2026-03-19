--[[
    ██╗   ██╗███╗   ███╗███████╗██╗   ██╗███████╗██████╗ ███████╗███████╗
    ██║   ██║████╗ ████║██╔════╝██║   ██║██╔════╝██╔══██╗██╔════╝██╔════╝
    ██║   ██║██╔████╔██║█████╗  ██║   ██║█████╗  ██████╔╝███████╗█████╗
    ██║   ██║██║╚██╔╝██║██╔══╝  ╚██╗ ██╔╝██╔══╝  ██╔══██╗╚════██║██╔══╝
    ╚██████╔╝██║ ╚═╝ ██║███████╗ ╚████╔╝ ███████╗██║  ██║███████║███████╗
     ╚═════╝ ╚═╝     ╚═╝╚══════╝  ╚═══╝  ╚════╝╚═╝  ╚═╝╚══════╝╚══════╝
    
    Umeverse Framework - Drug System
    Comprehensive drug production, distribution, and money laundering
]]

fx_version 'cerulean'
game 'gta5'

name 'umeverse_drugs'
author 'Umeverse'
description 'Umeverse Framework - Drug System (Production, Warehouses, Stash Houses, Street Sales, Money Laundering)'
version '1.0.0'

dependencies {
    'umeverse_core',
    'oxmysql',
}

shared_scripts {
    '@umeverse_core/config.lua',
    'config.lua',
}

client_scripts {
    'client/utils.lua',
    'client/blips.lua',
    'client/gathering.lua',
    'client/processing.lua',
    'client/packaging.lua',
    'client/selling.lua',
    'client/warehouse.lua',
    'client/stash.lua',
    'client/laundering.lua',
    'client/heat.lua',
    'client/turf.lua',
    'client/cutting.lua',
    'client/supply_runs.lua',
    'client/burner_phone.lua',
    'client/raids.lua',
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/main.lua',
    'server/warehouse.lua',
    'server/stash.lua',
    'server/selling.lua',
    'server/laundering.lua',
    'server/heat.lua',
    'server/specialization.lua',
    'server/dynamic_pricing.lua',
    'server/turf.lua',
    'server/buyer_rep.lua',
    'server/cutting.lua',
    'server/supply_runs.lua',
    'server/burner_phone.lua',
    'server/raids.lua',
}
