-- ============================================================
--  UmeVerse Framework — Job Definitions (shared)
--  Add your server's jobs here. Each job has grades with
--  labels and salaries. Grade keys are integers (0 = lowest).
-- ============================================================

UmeJobs = {
    unemployed = {
        label  = 'Unemployed',
        grades = {
            [0] = { label = 'Civilian', salary = 200 },
        },
    },

    police = {
        label  = 'Police Department',
        grades = {
            [0] = { label = 'Cadet',      salary = 3000 },
            [1] = { label = 'Officer',    salary = 4000 },
            [2] = { label = 'Detective',  salary = 5000 },
            [3] = { label = 'Sergeant',   salary = 6000 },
            [4] = { label = 'Lieutenant', salary = 7000 },
            [5] = { label = 'Chief',      salary = 9000 },
        },
    },

    ambulance = {
        label  = 'Emergency Medical Services',
        grades = {
            [0] = { label = 'Trainee',   salary = 3000 },
            [1] = { label = 'EMT',       salary = 4000 },
            [2] = { label = 'Paramedic', salary = 5500 },
            [3] = { label = 'Doctor',    salary = 7000 },
            [4] = { label = 'Director',  salary = 9000 },
        },
    },

    mechanic = {
        label  = 'Mechanic',
        grades = {
            [0] = { label = 'Apprentice', salary = 2500 },
            [1] = { label = 'Mechanic',   salary = 3500 },
            [2] = { label = 'Senior',     salary = 4500 },
            [3] = { label = 'Manager',    salary = 6000 },
        },
    },

    taxi = {
        label  = 'Taxi Driver',
        grades = {
            [0] = { label = 'Driver',     salary = 2000 },
            [1] = { label = 'Senior',     salary = 3000 },
            [2] = { label = 'Dispatcher', salary = 4000 },
        },
    },
}

--- Look up a grade entry for the given job / grade combination.
---@param jobName string
---@param grade   integer
---@return table|nil  { label, salary }
function UmeJobs.GetGrade(jobName, grade)
    local job = UmeJobs[jobName]
    if not job then return nil end
    return job.grades[grade]
end

--- Return the salary for the given job and grade, or 0 if unknown.
---@param jobName string
---@param grade   integer
---@return integer
function UmeJobs.GetSalary(jobName, grade)
    local g = UmeJobs.GetGrade(jobName, grade)
    return g and g.salary or 0
end

--- Return the grade label for the given job and grade.
---@param jobName string
---@param grade   integer
---@return string
function UmeJobs.GetGradeLabel(jobName, grade)
    local g = UmeJobs.GetGrade(jobName, grade)
    return g and g.label or ('Grade ' .. tostring(grade))
end

--- Validate that a job name and grade exist in the definitions.
---@param jobName string
---@param grade   integer
---@return boolean
function UmeJobs.IsValid(jobName, grade)
    return UmeJobs.GetGrade(jobName, grade) ~= nil
end
