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
