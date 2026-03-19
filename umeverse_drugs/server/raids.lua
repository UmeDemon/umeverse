--[[
    Umeverse Drugs - Raid Events (Server)
    High heat + lots of activity triggers police raids on labs/stashes.
    Players get a warning and limited time to evacuate or defend.
]]

local UME = exports['umeverse_core']:GetCoreObject()

-- Track active raids: [raidId] = { target, coords, startedAt, warned }
local activeRaids = {}
local raidIdCounter = 0

-- ═══════════════════════════════════════
-- Raid Check Thread
-- ═══════════════════════════════════════

CreateThread(function()
    if not DrugConfig.Raids.enabled then return end
    Wait(60000) -- Wait 1 min before first check

    while true do
        Wait(DrugConfig.Raids.checkInterval * 1000)

        local players = UME.GetPlayers()
        for _, player in pairs(players) do
            local citizenid = player:GetCitizenId()
            local heat = GetPlayerHeat(citizenid)

            if heat >= DrugConfig.Raids.heatThreshold then
                -- Scale chance with heat above threshold
                local heatOverThreshold = heat - DrugConfig.Raids.heatThreshold
                local maxOverThreshold = DrugConfig.Heat.maxHeat - DrugConfig.Raids.heatThreshold
                local scaledChance = DrugConfig.Raids.baseChance + (heatOverThreshold / maxOverThreshold) * 20
                scaledChance = math.min(scaledChance, 50) -- Cap at 50%

                if math.random(100) <= scaledChance then
                    TriggerRaid(player)
                end
            end
        end
    end
end)

-- ═══════════════════════════════════════
-- Trigger a Raid
-- ═══════════════════════════════════════

function TriggerRaid(player)
    local src = player:GetSource()
    local citizenid = player:GetCitizenId()

    -- Pick random raid target type
    local targetTypes = DrugConfig.Raids.targets
    local targetType = targetTypes[math.random(#targetTypes)]

    local raidCoords = nil
    local targetLabel = 'Unknown Location'

    if targetType == 'processLocations' then
        -- Pick a random processing location from any drug
        local allLocs = {}
        for drugKey, cfg in pairs(DrugConfig.Drugs) do
            for _, loc in ipairs(cfg.processLocations) do
                allLocs[#allLocs + 1] = { coords = loc, label = cfg.processLabel }
            end
        end
        if #allLocs > 0 then
            local chosen = allLocs[math.random(#allLocs)]
            raidCoords = vector3(chosen.coords.x, chosen.coords.y, chosen.coords.z)
            targetLabel = chosen.label
        end
    elseif targetType == 'stashHouse' then
        local stashes = DrugConfig.StashHouses.locations
        if #stashes > 0 then
            local chosen = stashes[math.random(#stashes)]
            raidCoords = vector3(chosen.coords.x, chosen.coords.y, chosen.coords.z)
            targetLabel = chosen.label
        end
    elseif targetType == 'warehouse' then
        local warehouses = DrugConfig.Warehouses.locations
        if #warehouses > 0 then
            local chosen = warehouses[math.random(#warehouses)]
            raidCoords = vector3(chosen.coords.x, chosen.coords.y, chosen.coords.z)
            targetLabel = chosen.label
        end
    end

    if not raidCoords then return end

    raidIdCounter = raidIdCounter + 1
    local raidId = raidIdCounter

    activeRaids[raidId] = {
        target = targetType,
        targetLabel = targetLabel,
        coords = raidCoords,
        startedAt = os.time(),
        citizenid = citizenid,
        src = src,
    }

    -- Warn the player
    TriggerClientEvent('umeverse_drugs:client:raidWarning', src, raidId, raidCoords, targetLabel, DrugConfig.Raids.warningTime)

    -- After warning time, start the raid
    SetTimeout(DrugConfig.Raids.warningTime * 1000, function()
        if not activeRaids[raidId] then return end -- Raid may have been cancelled

        -- Start raid (spawn police at location)
        TriggerClientEvent('umeverse_drugs:client:raidStart', src, raidId, raidCoords, DrugConfig.Raids.raidDuration)

        -- After raid duration, check results
        SetTimeout(DrugConfig.Raids.raidDuration * 1000, function()
            if not activeRaids[raidId] then return end

            -- Raid over — check if player evaded
            local raid = activeRaids[raidId]
            local evaded = true -- Assume evaded unless client reports caught

            if evaded then
                local p = UME.GetPlayer(raid.src)
                if p then
                    AddDrugRep(p, DrugConfig.Raids.evadeRepBonus, raid.src)
                    TriggerClientEvent('umeverse:client:notify', raid.src,
                        'Raid at ' .. raid.targetLabel .. ' is over. You got away!', 'success', 8000)
                end
            end

            -- Seizure check
            if DrugConfig.Raids.seizureEnabled and math.random(100) <= DrugConfig.Raids.seizureChance then
                -- Flag the stash/warehouse for seizure notification
                TriggerClientEvent('umeverse_drugs:client:raidSeizure', raid.src, raid.targetLabel)
            end

            activeRaids[raidId] = nil
        end)
    end)

    UME.Log('Police Raid', 'Raid triggered at ' .. targetLabel .. ' for ' .. player:GetFullName() .. ' (Heat: ' .. GetPlayerHeat(citizenid) .. ')', 16711680)
end

-- ═══════════════════════════════════════
-- Player caught during raid
-- ═══════════════════════════════════════

RegisterNetEvent('umeverse_drugs:server:raidCaught', function(raidId)
    local src = source
    if not DrugConfig.Raids.enabled then return end

    local raid = activeRaids[raidId]
    if not raid or raid.src ~= src then return end

    local player = UME.GetPlayer(src)
    if not player then return end

    local citizenid = player:GetCitizenId()

    -- Apply consequences
    AddPlayerHeat(citizenid, DrugConfig.Raids.heatOnCaught, src)

    -- Rep loss
    local currentRep = GetPlayerDrugRep(player)
    local newRep = math.max(0, currentRep - DrugConfig.Raids.repLossOnCaught)
    player:SetMetadata('drugRep', newRep)

    TriggerClientEvent('umeverse:client:notify', src,
        'Caught in a raid! Lost ' .. DrugConfig.Raids.repLossOnCaught .. ' drug rep!', 'error', 8000)

    activeRaids[raidId] = nil
end)

-- ═══════════════════════════════════════
-- Callback: Check if any raid is active near player
-- ═══════════════════════════════════════

UME.RegisterServerCallback('umeverse_drugs:getActiveRaids', function(source, cb)
    if not DrugConfig.Raids.enabled then cb({}) return end

    local result = {}
    for raidId, raid in pairs(activeRaids) do
        if raid.src == source then
            result[#result + 1] = {
                id = raidId,
                coords = raid.coords,
                targetLabel = raid.targetLabel,
                elapsed = os.time() - raid.startedAt,
            }
        end
    end
    cb(result)
end)
