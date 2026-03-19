--[[
    Umeverse Drugs - Stash Houses
    Free hidden locations to stash drugs and dirty money
    Each player gets their own stash per location
]]

local UME = exports['umeverse_core']:GetCoreObject()

-- ═══════════════════════════════════════
-- Stash House Interaction Loop
-- ═══════════════════════════════════════

CreateThread(function()
    Wait(5000)
    while true do
        local sleep = 1000
        local myPos = GetEntityCoords(PlayerPedId())

        for _, stash in ipairs(DrugConfig.StashHouses.locations) do
            local pos = vector3(stash.coords.x, stash.coords.y, stash.coords.z)
            local dist = #(myPos - pos)

            if dist < DrugConfig.MarkerDrawDistance then
                sleep = 0
                DrawDrugMarker(1, pos, 100, 50, 150, 100)
                DrawText3DDrug(vector3(pos.x, pos.y, pos.z + 1.0), '~p~' .. stash.label)

                if dist < DrugConfig.InteractDistance then
                    ShowDrugHelp('Press ~INPUT_CONTEXT~ to access stash')
                    if IsControlJustReleased(0, 38) then
                        if not IsBusy() then
                            OpenStashHouse(stash.id)
                        end
                    end
                end
            end
        end

        Wait(sleep)
    end
end)

-- ═══════════════════════════════════════
-- Open Stash
-- ═══════════════════════════════════════

function OpenStashHouse(stashId)
    if IsBusy() then return end

    -- Play a quick search animation
    DrugProgress('Accessing stash...', 3000, { dict = 'anim@gangops@morgue@table@', anim = 'body_search', flag = 1 }, function()
        -- Open as a personal stash using inventory system
        -- StashId includes citizenid so each player has their own
        local pd = UME.GetPlayerData()
        if not pd then return end
        local personalStashId = 'drug_stash_' .. stashId .. '_' .. pd.citizenid
        TriggerServerEvent('umeverse_inventory:server:openInventory', 'stash', personalStashId)
    end)
end
