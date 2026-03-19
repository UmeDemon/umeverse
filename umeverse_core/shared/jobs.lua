--[[
    Umeverse Framework - Jobs Configuration
    Define all jobs and their grades here
]]

UME.Jobs = {
    ['unemployed'] = {
        label = 'Unemployed',
        type = 'none',
        defaultDuty = true,
        grades = {
            [0] = { name = 'Unemployed', payment = 0 },
        },
    },

    ['police'] = {
        label = 'Police',
        type = 'leo',
        defaultDuty = false,
        grades = {
            [0] = { name = 'Cadet',       payment = 350 },
            [1] = { name = 'Officer',      payment = 450 },
            [2] = { name = 'Sergeant',     payment = 550 },
            [3] = { name = 'Lieutenant',   payment = 650 },
            [4] = { name = 'Captain',      payment = 750 },
            [5] = { name = 'Chief',        payment = 900 },
        },
    },

    ['ambulance'] = {
        label = 'EMS',
        type = 'ems',
        defaultDuty = false,
        grades = {
            [0] = { name = 'EMT',              payment = 300 },
            [1] = { name = 'Paramedic',         payment = 400 },
            [2] = { name = 'Doctor',            payment = 550 },
            [3] = { name = 'Surgeon',           payment = 650 },
            [4] = { name = 'Chief of Medicine', payment = 800 },
        },
    },

    ['mechanic'] = {
        label = 'Mechanic',
        type = 'job',
        defaultDuty = false,
        grades = {
            [0] = { name = 'Trainee',  payment = 200 },
            [1] = { name = 'Mechanic', payment = 300 },
            [2] = { name = 'Senior',   payment = 400 },
            [3] = { name = 'Manager',  payment = 500 },
            [4] = { name = 'Owner',    payment = 650 },
        },
    },

    ['taxi'] = {
        label = 'Taxi',
        type = 'job',
        defaultDuty = false,
        grades = {
            [0] = { name = 'Driver',    payment = 200 },
            [1] = { name = 'Senior',    payment = 300 },
            [2] = { name = 'Dispatcher', payment = 350 },
            [3] = { name = 'Manager',   payment = 400 },
            [4] = { name = 'Owner',     payment = 500 },
        },
    },

    ['realestate'] = {
        label = 'Real Estate',
        type = 'job',
        defaultDuty = false,
        grades = {
            [0] = { name = 'Trainee', payment = 250 },
            [1] = { name = 'Agent',   payment = 400 },
            [2] = { name = 'Broker',  payment = 550 },
            [3] = { name = 'Manager', payment = 650 },
            [4] = { name = 'Owner',   payment = 800 },
        },
    },

    ['judge'] = {
        label = 'Judge',
        type = 'law',
        defaultDuty = true,
        grades = {
            [0] = { name = 'Associate Judge', payment = 700 },
            [1] = { name = 'Senior Judge',    payment = 900 },
            [2] = { name = 'Chief Justice',   payment = 1100 },
        },
    },

    -- ═══════════════════════════════════════
    -- Civilian Jobs (self-service / clock-in)
    -- ═══════════════════════════════════════

    ['garbage'] = {
        label = 'Garbage Collector',
        type = 'job',
        defaultDuty = false,
        grades = {
            [0] = { name = 'Trainee',    payment = 150 },
            [1] = { name = 'Collector',   payment = 250 },
            [2] = { name = 'Driver',      payment = 350 },
            [3] = { name = 'Supervisor',  payment = 450 },
        },
    },

    ['bus'] = {
        label = 'Bus Driver',
        type = 'job',
        defaultDuty = false,
        grades = {
            [0] = { name = 'Trainee',     payment = 150 },
            [1] = { name = 'Driver',      payment = 250 },
            [2] = { name = 'Senior',      payment = 350 },
            [3] = { name = 'Supervisor',  payment = 450 },
        },
    },

    ['trucker'] = {
        label = 'Trucker',
        type = 'job',
        defaultDuty = false,
        grades = {
            [0] = { name = 'Trainee',     payment = 150 },
            [1] = { name = 'Driver',      payment = 275 },
            [2] = { name = 'Long Haul',   payment = 400 },
            [3] = { name = 'Supervisor',  payment = 500 },
        },
    },

    ['fisherman'] = {
        label = 'Fisherman',
        type = 'job',
        defaultDuty = false,
        grades = {
            [0] = { name = 'Novice',       payment = 100 },
            [1] = { name = 'Fisherman',    payment = 200 },
            [2] = { name = 'Experienced',  payment = 300 },
            [3] = { name = 'Master',       payment = 400 },
        },
    },

    ['lumberjack'] = {
        label = 'Lumberjack',
        type = 'job',
        defaultDuty = false,
        grades = {
            [0] = { name = 'Trainee',     payment = 125 },
            [1] = { name = 'Chopper',     payment = 225 },
            [2] = { name = 'Foreman',     payment = 350 },
            [3] = { name = 'Manager',     payment = 450 },
        },
    },

    ['miner'] = {
        label = 'Miner',
        type = 'job',
        defaultDuty = false,
        grades = {
            [0] = { name = 'Trainee',     payment = 150 },
            [1] = { name = 'Miner',       payment = 275 },
            [2] = { name = 'Driller',     payment = 375 },
            [3] = { name = 'Foreman',     payment = 500 },
        },
    },

    ['tow'] = {
        label = 'Tow Truck Driver',
        type = 'job',
        defaultDuty = false,
        grades = {
            [0] = { name = 'Trainee',     payment = 150 },
            [1] = { name = 'Driver',      payment = 275 },
            [2] = { name = 'Senior',      payment = 375 },
            [3] = { name = 'Supervisor',  payment = 475 },
        },
    },

    ['pizza'] = {
        label = 'Pizza Delivery',
        type = 'job',
        defaultDuty = false,
        grades = {
            [0] = { name = 'Trainee',     payment = 100 },
            [1] = { name = 'Delivery',    payment = 200 },
            [2] = { name = 'Senior',      payment = 300 },
            [3] = { name = 'Manager',     payment = 400 },
        },
    },

    ['reporter'] = {
        label = 'News Reporter',
        type = 'job',
        defaultDuty = false,
        grades = {
            [0] = { name = 'Intern',       payment = 125 },
            [1] = { name = 'Reporter',     payment = 250 },
            [2] = { name = 'Journalist',   payment = 375 },
            [3] = { name = 'Anchor',       payment = 500 },
        },
    },

    ['helitour'] = {
        label = 'Helicopter Tour',
        type = 'job',
        defaultDuty = false,
        grades = {
            [0] = { name = 'Trainee Pilot',  payment = 200 },
            [1] = { name = 'Pilot',           payment = 350 },
            [2] = { name = 'Senior Pilot',    payment = 500 },
            [3] = { name = 'Chief Pilot',     payment = 650 },
        },
    },

    ['postal'] = {
        label = 'Postal Courier',
        type = 'job',
        defaultDuty = false,
        grades = {
            [0] = { name = 'Trainee',     payment = 125 },
            [1] = { name = 'Courier',     payment = 225 },
            [2] = { name = 'Senior',      payment = 325 },
            [3] = { name = 'Supervisor',  payment = 425 },
        },
    },

    ['dockworker'] = {
        label = 'Dock Worker',
        type = 'job',
        defaultDuty = false,
        grades = {
            [0] = { name = 'Laborer',     payment = 150 },
            [1] = { name = 'Operator',    payment = 275 },
            [2] = { name = 'Foreman',     payment = 400 },
            [3] = { name = 'Supervisor',  payment = 525 },
        },
    },

    ['train'] = {
        label = 'Train Engineer',
        type = 'job',
        defaultDuty = false,
        grades = {
            [0] = { name = 'Trainee',     payment = 175 },
            [1] = { name = 'Engineer',    payment = 300 },
            [2] = { name = 'Senior',      payment = 425 },
            [3] = { name = 'Conductor',   payment = 550 },
        },
    },

    ['hunter'] = {
        label = 'Hunter',
        type = 'job',
        defaultDuty = false,
        grades = {
            [0] = { name = 'Novice',       payment = 100 },
            [1] = { name = 'Hunter',       payment = 225 },
            [2] = { name = 'Tracker',      payment = 350 },
            [3] = { name = 'Master',       payment = 475 },
        },
    },

    ['farmer'] = {
        label = 'Farmer',
        type = 'job',
        defaultDuty = false,
        grades = {
            [0] = { name = 'Trainee',     payment = 100 },
            [1] = { name = 'Farmhand',    payment = 200 },
            [2] = { name = 'Farmer',      payment = 300 },
            [3] = { name = 'Ranch Owner', payment = 425 },
        },
    },

    ['diver'] = {
        label = 'Salvage Diver',
        type = 'job',
        defaultDuty = false,
        grades = {
            [0] = { name = 'Trainee',     payment = 150 },
            [1] = { name = 'Diver',       payment = 300 },
            [2] = { name = 'Deep Diver',  payment = 450 },
            [3] = { name = 'Master',      payment = 600 },
        },
    },

    ['vineyard'] = {
        label = 'Vineyard Worker',
        type = 'job',
        defaultDuty = false,
        grades = {
            [0] = { name = 'Picker',      payment = 100 },
            [1] = { name = 'Worker',      payment = 200 },
            [2] = { name = 'Vintner',     payment = 325 },
            [3] = { name = 'Manager',     payment = 450 },
        },
    },

    ['electrician'] = {
        label = 'Electrician',
        type = 'job',
        defaultDuty = false,
        grades = {
            [0] = { name = 'Apprentice',  payment = 150 },
            [1] = { name = 'Electrician', payment = 300 },
            [2] = { name = 'Senior',      payment = 425 },
            [3] = { name = 'Master',      payment = 550 },
        },
    },

    ['security'] = {
        label = 'Security Guard',
        type = 'job',
        defaultDuty = false,
        grades = {
            [0] = { name = 'Trainee',     payment = 125 },
            [1] = { name = 'Guard',       payment = 225 },
            [2] = { name = 'Senior',      payment = 350 },
            [3] = { name = 'Supervisor',  payment = 475 },
        },
    },
}

--- Get a job by name
---@param name string
---@return table|nil
function UME.GetJob(name)
    return UME.Jobs[name]
end

--- Get a job grade
---@param name string
---@param grade number
---@return table|nil
function UME.GetJobGrade(name, grade)
    local job = UME.Jobs[name]
    if job then
        return job.grades[grade]
    end
    return nil
end
