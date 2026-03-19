--[[
    ██╗   ██╗███╗   ███╗███████╗██╗   ██╗███████╗██████╗ ███████╗███████╗
    ██║   ██║████╗ ████║██╔════╝██║   ██║██╔════╝██╔══██╗██╔════╝██╔════╝
    ██║   ██║██╔████╔██║█████╗  ██║   ██║█████╗  ██████╔╝███████╗█████╗
    ██║   ██║██║╚██╔╝██║██╔══╝  ╚██╗ ██╔╝██╔══╝  ██╔══██╗╚════██║██╔══╝
    ╚██████╔╝██║ ╚═╝ ██║███████╗ ╚████╔╝ ███████╗██║  ██║███████║███████╗
     ╚═════╝ ╚═╝     ╚═╝╚══════╝  ╚═══╝  ╚═════╝╚═╝  ╚═╝╚══════╝╚══════╝
    
    Umeverse Framework - Civilian Jobs
    Base city jobs using vanilla GTA V natives
]]

fx_version 'cerulean'
game 'gta5'

name 'umeverse_jobs'
author 'Umeverse'
description 'Umeverse Framework - Civilian Jobs (20 jobs: Garbage, Bus, Trucker, Fishing, Lumber, Mining, Tow, Pizza, Reporter, Taxi, Heli Tour, Postal, Dock Worker, Train, Hunter, Farmer, Diver, Vineyard, Electrician, Security)'
version '1.0.0'

shared_scripts {
    '@umeverse_core/config.lua',
    'config.lua',
}

client_scripts {
    'client/utils.lua',
    'client/clockin.lua',
    'client/job_garbage.lua',
    'client/job_bus.lua',
    'client/job_trucker.lua',
    'client/job_fisherman.lua',
    'client/job_lumberjack.lua',
    'client/job_miner.lua',
    'client/job_tow.lua',
    'client/job_pizza.lua',
    'client/job_reporter.lua',
    'client/job_taxi.lua',
    'client/job_helitour.lua',
    'client/job_postal.lua',
    'client/job_dockworker.lua',
    'client/job_train.lua',
    'client/job_hunter.lua',
    'client/job_farmer.lua',
    'client/job_diver.lua',
    'client/job_vineyard.lua',
    'client/job_electrician.lua',
    'client/job_security.lua',
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/main.lua',
    'server/progression.lua',
    'server/challenges.lua',
    'server/contracts.lua',
    'server/milestones.lua',
    'server/leaderboard.lua',
    'server/market.lua',
}

dependencies {
    'umeverse_core',
    'oxmysql',
}
