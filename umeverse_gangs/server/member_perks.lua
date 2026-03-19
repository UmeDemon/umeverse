--[[
    Umeverse Gangs System - Member Perks
    Apply rank-based perks to gang members
]]

GangMemberPerks = {}

-- Get member perks based on rank
function GangMemberPerks.GetRankPerks(gangName, rank)
    if not GangsConfig.Gangs[gangName] then return {} end
    
    local rankConfig = GangsConfig.Ranks and GangsConfig.Ranks[rank]
    if not rankConfig then return {} end
    
    return rankConfig.memberPerks or {}
end

-- Apply weapon perks
function GangMemberPerks.ApplyWeaponPerks(src, gangName, rank)
    local perks = GangMemberPerks.GetRankPerks(gangName, rank)
    
    if perks.weaponBonus then
        TriggerClientEvent('umeverse_gangs:applyWeaponBonus', src, perks.weaponBonus)
    end
end

-- Apply armor/health perks
function GangMemberPerks.ApplyHealthPerks(src, gangName, rank)
    local perks = GangMemberPerks.GetRankPerks(gangName, rank)
    
    if perks.armorBonus then
        TriggerClientEvent('umeverse_gangs:applyArmorBonus', src, perks.armorBonus)
    end
end

-- Let's spawn NPC backup
function GangMemberPerks.SpawnNPCBackup(src, npcCount)
    if npcCount <= 0 then return end
    
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end
    
    TriggerClientEvent('umeverse_gangs:spawnNPCBackup', src, npcCount)
end

-- Apply all perks to player
function GangMemberPerks.ApplyAllPerks(src, gangName, rank)
    GangMemberPerks.ApplyWeaponPerks(src, gangName, rank)
    GangMemberPerks.ApplyHealthPerks(src, gangName, rank)
    
    local perks = GangMemberPerks.GetRankPerks(gangName, rank)
    if perks.npcBackup and perks.npcBackup > 0 then
        GangMemberPerks.SpawnNPCBackup(src, perks.npcBackup)
    end
end

-- Apply passive crime reward bonus
function GangMemberPerks.GetCrimeRewardBonus(gangName, rank)
    local perks = GangMemberPerks.GetRankPerks(gangName, rank)
    
    return perks.passiveCrimeBonus or 0
end

-- Check if member has specific perk
function GangMemberPerks.HasPerk(gangName, rank, perkName)
    local perks = GangMemberPerks.GetRankPerks(gangName, rank)
    
    if perkName == 'weaponBonus' then return perks.weaponBonus ~= nil end
    if perkName == 'armorBonus' then return perks.armorBonus ~= nil end
    if perkName == 'npcBackup' then return perks.npcBackup and perks.npcBackup > 0 end
    
    return false
end

-- Update player perks when joining/changing rank
RegisterNetEvent('umeverse_gangs:updateMemberPerks')
AddEventHandler('umeverse_gangs:updateMemberPerks', function(gangName, rank)
    GangMemberPerks.ApplyAllPerks(source, gangName, rank)
end)

-- On gang member login, apply perks
RegisterNetEvent('umeverse_gangs:memberLogin')
AddEventHandler('umeverse_gangs:memberLogin', function()
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then return end
    
    local gang = GangSystem.GetPlayerGang(Player.PlayerData.citizenid)
    if gang then
        GangMemberPerks.ApplyAllPerks(source, gang.gang, gang.rank)
    end
end)

exports('getMemberPerkCrimeBonus', function(gangName, rank)
    return GangMemberPerks.GetCrimeRewardBonus(gangName, rank)
end)

exports('getMemberHasPerk', function(gangName, rank, perkName)
    return GangMemberPerks.HasPerk(gangName, rank, perkName)
end)

print('^2[Umeverse]^7 Gang Member Perks System loaded')
