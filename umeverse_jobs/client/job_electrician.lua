--[[
    Umeverse Jobs - Electrician
    Drive to electrical box locations, repair them, get paid per fix
]]

local cfg = JobsConfig.Electrician
local fixesCompleted = 0

RegisterNetEvent('umeverse_jobs:client:startJob_electrician', function()
    fixesCompleted = 0

    JobNotify('Electrician shift started! Head to a ~y~repair site~w~.', 'info')
    SetElectricianTarget()
    ElectricianLoop()
end)

function SetElectricianTarget()
    ClearJobBlips()
    if fixesCompleted < cfg.fixesPerShift then
        -- Pick a random unfixed location
        local idx = math.random(#cfg.repairLocations)
        local loc = cfg.repairLocations[idx]
        AddJobBlip(loc.pos, 354, 5, 'Electrical Box (' .. (fixesCompleted + 1) .. '/' .. cfg.fixesPerShift .. ')', true)
    end
end

function ElectricianLoop()
    CreateThread(function()
        while GetActiveJob() == 'electrician' do
            local sleep = 500
            local ped = PlayerPedId()
            local myPos = GetEntityCoords(ped)

            for _, loc in ipairs(cfg.repairLocations) do
                local dist = #(myPos - loc.pos)
                if dist < 15.0 then
                    sleep = 0
                    DrawJobMarker(1, loc.pos, 255, 200, 0, 120)
                    DrawText3D(loc.pos + vector3(0, 0, 1.5), loc.label)

                    if dist < 2.5 and not IsPedInAnyVehicle(ped, false) then
                        if fixesCompleted < cfg.fixesPerShift then
                            ShowHelpText('Press ~INPUT_CONTEXT~ to repair electrical box')
                            if IsControlJustReleased(0, 38) then
                                RepairBox(loc)
                            end
                        end
                    end
                end
            end

            Wait(sleep)
        end
    end)
end

function RepairBox(loc)
    local ped = PlayerPedId()

    TaskTurnPedToFaceCoord(ped, loc.pos.x, loc.pos.y, loc.pos.z, 1000)
    Wait(1000)

    JobNotify('Repairing electrical box...', 'info')
    PlayJobAnim('mini@repair', 'fixing_a_ped', cfg.repairDuration, 1)
    Wait(cfg.repairDuration)
    StopJobAnim()

    TriggerServerEvent('umeverse_jobs:server:electricianPay')
    OnTaskComplete(JobsConfig.Electrician.payPerFix[GetJobGrade() + 1] or JobsConfig.Electrician.payPerFix[1])
    fixesCompleted = fixesCompleted + 1
    JobNotify('Repair complete! (' .. fixesCompleted .. '/' .. cfg.fixesPerShift .. ')', 'success')

    if fixesCompleted >= cfg.fixesPerShift then
        JobNotify('All repairs done! Ending shift...', 'success')
        ClearJobBlips()
        Wait(1500)
        TriggerEvent('umeverse_jobs:client:endShift')
    else
        SetElectricianTarget()
        JobNotify('Head to the next repair site.', 'info')
    end
end
