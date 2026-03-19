--[[
    Umeverse Framework - Server Player Class
    Player object with all data manipulation methods
]]

UME.PlayerClass = {}
UME.PlayerClass.__index = UME.PlayerClass

--- Load a player from the database and create a Player object
---@param source number
---@param citizenid string
function UME.LoadPlayer(source, citizenid)
    local result = MySQL.query.await('SELECT * FROM umeverse_players WHERE citizenid = ?', { citizenid })

    if not result or #result == 0 then
        UME.Error('Failed to load player: ' .. citizenid)
        return
    end

    local data = result[1]

    --- Safe JSON decode with fallback
    local function safeDecode(str, fallback)
        if not str or str == '' then return fallback end
        local ok, decoded = pcall(json.decode, str)
        if ok and decoded ~= nil then return decoded end
        return fallback
    end

    local self = setmetatable({}, UME.PlayerClass)

    -- Copy all class methods directly onto the instance so they survive
    -- cross-resource export boundaries (FiveM strips metatables on transfer)
    for k, v in pairs(UME.PlayerClass) do
        if type(v) == 'function' then
            self[k] = v
        end
    end

    self.source     = source
    self.citizenid  = data.citizenid
    self.identifier = data.identifier
    self.name       = GetPlayerName(source)
    self.firstname  = data.firstname
    self.lastname   = data.lastname
    self.charinfo   = safeDecode(data.charinfo, {})
    self.money      = safeDecode(data.money, { cash = 0, bank = 0, black = 0 })
    self.job        = safeDecode(data.job, { name = 'unemployed', grade = 0, onduty = false })
    self.position   = safeDecode(data.position, { x = UmeConfig.DefaultSpawn.x, y = UmeConfig.DefaultSpawn.y, z = UmeConfig.DefaultSpawn.z, heading = UmeConfig.DefaultSpawn.w })
    self.inventory  = safeDecode(data.inventory, {})
    self.status     = safeDecode(data.status, { hunger = 100.0, thirst = 100.0 })
    self.skin       = safeDecode(data.skin, {})
    self.metadata   = safeDecode(data.metadata or '{}', {})

    -- Cache job label info
    local jobData = UME.GetJob(self.job.name)
    if jobData then
        self.job.label = jobData.label
        local gradeData = jobData.grades[self.job.grade]
        if gradeData then
            self.job.gradelabel = gradeData.name
        end
    end

    -- Compatibility: QBCore / TMC style scripts access player.PlayerData.*
    self.PlayerData = self

    -- Register player
    UME.Players[source] = self

    -- Notify client
    TriggerClientEvent('umeverse:client:playerLoaded', source, self:GetClientData())
    TriggerEvent('umeverse:server:playerLoaded:done', source)

    UME.Debug('Player loaded: ' .. self.firstname .. ' ' .. self.lastname .. ' (Source: ' .. source .. ')')
end

-- ═══════════════════════════════════════
-- Getters
-- ═══════════════════════════════════════

function UME.PlayerClass:GetSource()
    return self.source
end

function UME.PlayerClass:GetCitizenId()
    return self.citizenid
end

function UME.PlayerClass:GetIdentifier()
    return self.identifier
end

function UME.PlayerClass:GetFullName()
    return self.firstname .. ' ' .. self.lastname
end

function UME.PlayerClass:GetJob()
    return self.job
end

function UME.PlayerClass:GetMoney(moneyType)
    moneyType = moneyType or 'cash'
    return self.money[moneyType] or 0
end

function UME.PlayerClass:GetInventory()
    return self.inventory
end

function UME.PlayerClass:GetStatus()
    return self.status
end

function UME.PlayerClass:GetPosition()
    return self.position
end

function UME.PlayerClass:GetSkin()
    return self.skin
end

function UME.PlayerClass:GetCharInfo()
    return self.charinfo
end

function UME.PlayerClass:GetMetadata(key)
    if key then
        return self.metadata[key]
    end
    return self.metadata
end

--- Get data safe for sending to client
function UME.PlayerClass:GetClientData()
    return {
        source     = self.source,
        citizenid  = self.citizenid,
        name       = self.name,
        firstname  = self.firstname,
        lastname   = self.lastname,
        charinfo   = self.charinfo,
        money      = self.money,
        job        = self.job,
        position   = self.position,
        status     = self.status,
        metadata   = self.metadata,
    }
end

-- ═══════════════════════════════════════
-- Money Management
-- ═══════════════════════════════════════

--- Add money to a player
---@param moneyType string 'cash' or 'bank'
---@param amount number
---@param reason string|nil
---@return boolean
function UME.PlayerClass:AddMoney(moneyType, amount, reason)
    moneyType = moneyType or 'cash'
    amount = tonumber(amount)

    if not amount or amount <= 0 then return false end
    if not self.money[moneyType] then return false end

    self.money[moneyType] = self.money[moneyType] + amount

    TriggerClientEvent('umeverse:client:updateMoney', self.source, self.money, moneyType, amount, 'add')
    TriggerEvent('umeverse:server:moneyChange', self.source, moneyType, amount, 'add', reason or 'unknown')

    UME.Debug(self:GetFullName() .. ' received $' .. amount .. ' ' .. moneyType .. ' (' .. (reason or 'unknown') .. ')')
    return true
end

--- Remove money from a player
---@param moneyType string 'cash' or 'bank'
---@param amount number
---@param reason string|nil
---@return boolean
function UME.PlayerClass:RemoveMoney(moneyType, amount, reason)
    moneyType = moneyType or 'cash'
    amount = tonumber(amount)

    if not amount or amount <= 0 then return false end
    if not self.money[moneyType] then return false end
    if self.money[moneyType] < amount then return false end

    self.money[moneyType] = self.money[moneyType] - amount

    TriggerClientEvent('umeverse:client:updateMoney', self.source, self.money, moneyType, amount, 'remove')
    TriggerEvent('umeverse:server:moneyChange', self.source, moneyType, amount, 'remove', reason or 'unknown')

    UME.Debug(self:GetFullName() .. ' lost $' .. amount .. ' ' .. moneyType .. ' (' .. (reason or 'unknown') .. ')')
    return true
end

--- Set money directly
---@param moneyType string
---@param amount number
function UME.PlayerClass:SetMoney(moneyType, amount)
    moneyType = moneyType or 'cash'
    amount = tonumber(amount) or 0
    if amount < 0 then amount = 0 end
    local oldAmount = self.money[moneyType] or 0
    self.money[moneyType] = amount
    TriggerClientEvent('umeverse:client:updateMoney', self.source, self.money, moneyType, amount, 'set')
    TriggerEvent('umeverse:server:moneyChange', self.source, moneyType, math.abs(amount - oldAmount), 'set', 'direct')
end

--- Check if player has enough money
---@param moneyType string
---@param amount number
---@return boolean
function UME.PlayerClass:HasMoney(moneyType, amount)
    return (self.money[moneyType] or 0) >= amount
end

-- ═══════════════════════════════════════
-- Job Management
-- ═══════════════════════════════════════

--- Set a player's job
---@param jobName string
---@param grade number
---@return boolean
function UME.PlayerClass:SetJob(jobName, grade)
    local jobData = UME.GetJob(jobName)
    if not jobData then
        UME.Error('Job not found: ' .. jobName)
        return false
    end

    local gradeData = jobData.grades[grade]
    if not gradeData then
        UME.Error('Grade not found: ' .. grade .. ' for job ' .. jobName)
        return false
    end

    self.job = {
        name       = jobName,
        label      = jobData.label,
        grade      = grade,
        gradelabel = gradeData.name,
        onduty     = jobData.defaultDuty or false,
        type       = jobData.type,
    }

    TriggerClientEvent('umeverse:client:updateJob', self.source, self.job)
    TriggerEvent('umeverse:server:jobChange', self.source, self.job)

    UME.Debug(self:GetFullName() .. ' job set to: ' .. jobData.label .. ' (' .. gradeData.name .. ')')
    return true
end

--- Toggle duty status
---@return boolean
function UME.PlayerClass:ToggleDuty()
    self.job.onduty = not self.job.onduty
    TriggerClientEvent('umeverse:client:updateJob', self.source, self.job)
    return self.job.onduty
end

-- ═══════════════════════════════════════
-- Inventory Management
-- ═══════════════════════════════════════

--- Add an item to player inventory
---@param itemName string
---@param amount number
---@param metadata table|nil
---@return boolean
function UME.PlayerClass:AddItem(itemName, amount, metadata)
    local itemData = UME.GetItem(itemName)
    if not itemData then
        UME.Error('Item not found: ' .. itemName)
        return false
    end

    amount = tonumber(amount) or 1
    if amount <= 0 then return false end
    amount = math.floor(amount)

    -- Find existing stack or empty slot
    for i, slot in ipairs(self.inventory) do
        if slot.name == itemName and not itemData.unique then
            self.inventory[i].amount = slot.amount + amount
            self:SyncInventory()
            TriggerClientEvent('umeverse:client:notify', self.source, _T('item_received', amount, itemData.label), 'success')
            TriggerEvent('umeverse:server:itemAdded', self.source, itemName, amount)
            return true
        end
    end

    -- New slot
    self.inventory[#self.inventory + 1] = {
        name     = itemName,
        label    = itemData.label,
        amount   = amount,
        weight   = itemData.weight,
        type     = itemData.type,
        unique   = itemData.unique,
        metadata = metadata or {},
    }

    self:SyncInventory()
    TriggerClientEvent('umeverse:client:notify', self.source, _T('item_received', amount, itemData.label), 'success')
    TriggerEvent('umeverse:server:itemAdded', self.source, itemName, amount)
    return true
end

--- Remove an item from player inventory
---@param itemName string
---@param amount number
---@return boolean
function UME.PlayerClass:RemoveItem(itemName, amount)
    amount = tonumber(amount) or 1
    if amount <= 0 then return false end
    amount = math.floor(amount)

    for i, slot in ipairs(self.inventory) do
        if slot.name == itemName then
            if slot.amount > amount then
                self.inventory[i].amount = slot.amount - amount
                self:SyncInventory()
                TriggerEvent('umeverse:server:itemRemoved', self.source, itemName, amount)
                return true
            elseif slot.amount == amount then
                table.remove(self.inventory, i)
                self:SyncInventory()
                TriggerEvent('umeverse:server:itemRemoved', self.source, itemName, amount)
                return true
            else
                return false -- Not enough
            end
        end
    end
    return false
end

--- Get item count
---@param itemName string
---@return number
function UME.PlayerClass:GetItemCount(itemName)
    for _, slot in ipairs(self.inventory) do
        if slot.name == itemName then
            return slot.amount
        end
    end
    return 0
end

--- Check if player has an item
---@param itemName string
---@param amount number|nil
---@return boolean
function UME.PlayerClass:HasItem(itemName, amount)
    amount = amount or 1
    return self:GetItemCount(itemName) >= amount
end

--- Sync inventory to client
function UME.PlayerClass:SyncInventory()
    TriggerClientEvent('umeverse:client:updateInventory', self.source, self.inventory)
end

-- ═══════════════════════════════════════
-- Status Management
-- ═══════════════════════════════════════

--- Set a status value
---@param statusType string 'hunger' or 'thirst'
---@param value number
function UME.PlayerClass:SetStatus(statusType, value)
    value = math.max(0, math.min(100, value))
    self.status[statusType] = value
    TriggerClientEvent('umeverse:client:updateStatus', self.source, self.status)
end

--- Add to a status value
---@param statusType string
---@param amount number
function UME.PlayerClass:AddStatus(statusType, amount)
    local current = self.status[statusType] or 0
    self:SetStatus(statusType, current + amount)
end

--- Remove from a status value
---@param statusType string
---@param amount number
function UME.PlayerClass:RemoveStatus(statusType, amount)
    local current = self.status[statusType] or 0
    self:SetStatus(statusType, current - amount)
end

-- ═══════════════════════════════════════
-- Position & Skin
-- ═══════════════════════════════════════

--- Update player position
---@param coords vector4|table
function UME.PlayerClass:SetPosition(coords)
    self.position = {
        x = coords.x or coords[1],
        y = coords.y or coords[2],
        z = coords.z or coords[3],
        heading = coords.w or coords.heading or coords[4] or 0.0,
    }
end

--- Set player skin data
---@param skinData table
function UME.PlayerClass:SetSkin(skinData)
    self.skin = skinData
end

-- ═══════════════════════════════════════
-- Metadata
-- ═══════════════════════════════════════

--- Set a metadata value
---@param key string
---@param value any
function UME.PlayerClass:SetMetadata(key, value)
    self.metadata[key] = value
    TriggerClientEvent('umeverse:client:updateMetadata', self.source, self.metadata)
end

-- ═══════════════════════════════════════
-- Persistence
-- ═══════════════════════════════════════

--- Save player data to database (blocking)
function UME.PlayerClass:Save()
    MySQL.update.await('UPDATE umeverse_players SET money = ?, job = ?, position = ?, inventory = ?, status = ?, skin = ?, charinfo = ?, metadata = ? WHERE citizenid = ?', {
        json.encode(self.money),
        json.encode(self.job),
        json.encode(self.position),
        json.encode(self.inventory),
        json.encode(self.status),
        json.encode(self.skin),
        json.encode(self.charinfo),
        json.encode(self.metadata),
        self.citizenid,
    })
end

--- Save player data to database (non-blocking, for batch saves)
function UME.PlayerClass:SaveAsync()
    MySQL.update('UPDATE umeverse_players SET money = ?, job = ?, position = ?, inventory = ?, status = ?, skin = ?, charinfo = ?, metadata = ? WHERE citizenid = ?', {
        json.encode(self.money),
        json.encode(self.job),
        json.encode(self.position),
        json.encode(self.inventory),
        json.encode(self.status),
        json.encode(self.skin),
        json.encode(self.charinfo),
        json.encode(self.metadata),
        self.citizenid,
    })
end

--- Kick the player
---@param reason string
function UME.PlayerClass:Kick(reason)
    self:Save()
    DropPlayer(self.source, reason or 'Kicked from the server.')
end
