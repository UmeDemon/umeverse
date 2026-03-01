-- ============================================================
--  UmeVerse Framework — Server-side Player Object
-- ============================================================

-- Internal table: source (player net id) → player object.
local Players = {}

---@class UmePlayer
local UmePlayer = {}
UmePlayer.__index = UmePlayer

--- Construct a new player object.
---@param source  integer   FiveM player net id.
---@param data    table     Row loaded from the database (or defaults for new players).
---@return UmePlayer
function UmePlayer.New(source, data)
    local self = setmetatable({}, UmePlayer)

    self.source     = source
    self.identifier = data.identifier
    self.name       = GetPlayerName(source) or 'Unknown'
    self.job        = data.job       or UmeUtils.DeepCopy(UmeConfig.DefaultJob)
    self.cash       = data.cash      or UmeConfig.StartingCash
    self.bank       = data.bank      or UmeConfig.StartingBank
    self.inventory  = data.inventory or {}
    self.metadata   = data.metadata  or {}
    self.weight     = 0   -- recalculated when inventory changes

    return self
end

-- ── Money ──────────────────────────────────────────────────

--- Add cash to the player's wallet.
---@param amount integer
---@return boolean
function UmePlayer:AddCash(amount)
    if type(amount) ~= 'number' or amount <= 0 then return false end
    self.cash = self.cash + amount
    self:TriggerEvent('umeverse:client:moneyUpdate', 'cash', self.cash)
    return true
end

--- Remove cash from the player's wallet.
---@param amount integer
---@return boolean
function UmePlayer:RemoveCash(amount)
    if type(amount) ~= 'number' or amount <= 0 then return false end
    if self.cash < amount then return false end
    self.cash = self.cash - amount
    self:TriggerEvent('umeverse:client:moneyUpdate', 'cash', self.cash)
    return true
end

--- Add money to the player's bank account.
---@param amount integer
---@return boolean
function UmePlayer:AddBank(amount)
    if type(amount) ~= 'number' or amount <= 0 then return false end
    self.bank = self.bank + amount
    self:TriggerEvent('umeverse:client:moneyUpdate', 'bank', self.bank)
    return true
end

--- Remove money from the player's bank account.
---@param amount integer
---@return boolean
function UmePlayer:RemoveBank(amount)
    if type(amount) ~= 'number' or amount <= 0 then return false end
    if self.bank < amount then return false end
    self.bank = self.bank - amount
    self:TriggerEvent('umeverse:client:moneyUpdate', 'bank', self.bank)
    return true
end

-- ── Inventory ──────────────────────────────────────────────

--- Recalculate the total carried weight from the inventory.
function UmePlayer:RecalcWeight()
    local total = 0
    for _, item in pairs(self.inventory) do
        total = total + ((item.weight or 0) * (item.count or 1))
    end
    self.weight = total
end

--- Add an item (or stack) to the player's inventory.
---@param name   string
---@param count  integer
---@param weight integer   Weight per unit in grams.
---@return boolean, string  success, reason
function UmePlayer:AddItem(name, count, weight)
    count  = count  or 1
    weight = weight or 0
    local newWeight = self.weight + (weight * count)
    if newWeight > UmeConfig.MaxInventoryWeight then
        return false, 'inventory_full'
    end
    local slot = self.inventory[name]
    if slot then
        slot.count = slot.count + count
    else
        self.inventory[name] = { name = name, count = count, weight = weight }
    end
    self.weight = newWeight
    self:TriggerEvent('umeverse:client:inventoryUpdate', self.inventory)
    return true, 'ok'
end

--- Remove an item (or stack) from the player's inventory.
---@param name  string
---@param count integer
---@return boolean, string  success, reason
function UmePlayer:RemoveItem(name, count)
    count = count or 1
    local slot = self.inventory[name]
    if not slot or slot.count < count then
        return false, 'item_not_found'
    end
    slot.count = slot.count - count
    if slot.count <= 0 then
        self.inventory[name] = nil
    end
    self:RecalcWeight()
    self:TriggerEvent('umeverse:client:inventoryUpdate', self.inventory)
    return true, 'ok'
end

--- Check whether the player has at least `count` of an item.
---@param name  string
---@param count integer
---@return boolean
function UmePlayer:HasItem(name, count)
    count = count or 1
    local slot = self.inventory[name]
    return slot ~= nil and slot.count >= count
end

-- ── Job ────────────────────────────────────────────────────

--- Update the player's job.
---@param jobName  string
---@param label    string
---@param grade    integer
---@param salary   integer
function UmePlayer:SetJob(jobName, label, grade, salary)
    self.job = {
        name   = jobName,
        label  = label  or jobName,
        grade  = grade  or 0,
        salary = salary or 0,
    }
    self:TriggerEvent('umeverse:client:jobUpdate', self.job)
end

-- ── Metadata ───────────────────────────────────────────────

--- Set an arbitrary metadata key.
---@param key   string
---@param value any
function UmePlayer:SetMetadata(key, value)
    self.metadata[key] = value
    self:TriggerEvent('umeverse:client:metadataUpdate', key, value)
end

--- Get a metadata value.
---@param key string
---@return any
function UmePlayer:GetMetadata(key)
    return self.metadata[key]
end

-- ── Helpers ────────────────────────────────────────────────

--- Send a notification to this player.
---@param msg   string
---@param type  string|nil  'success'|'error'|'info'|'warning'
function UmePlayer:Notify(msg, notifType)
    self:TriggerEvent('umeverse:client:notify', msg, notifType or 'info')
end

--- Trigger a client event on this player.
---@param event string
---@param ...   any
function UmePlayer:TriggerEvent(event, ...)
    TriggerClientEvent(event, self.source, ...)
end

--- Return a plain-table snapshot of the player data (safe to pass over the network).
---@return table
function UmePlayer:GetData()
    return {
        source     = self.source,
        identifier = self.identifier,
        name       = self.name,
        job        = UmeUtils.DeepCopy(self.job),
        cash       = self.cash,
        bank       = self.bank,
        inventory  = UmeUtils.DeepCopy(self.inventory),
        metadata   = UmeUtils.DeepCopy(self.metadata),
        weight     = self.weight,
    }
end

-- ── Registry ───────────────────────────────────────────────

--- Store a player object in the registry.
---@param source integer
---@param player UmePlayer
function UmePlayer.Set(source, player)
    Players[source] = player
end

--- Retrieve a player object from the registry.
---@param source integer
---@return UmePlayer|nil
function UmePlayer.Get(source)
    return Players[source]
end

--- Remove a player from the registry.
---@param source integer
function UmePlayer.Remove(source)
    Players[source] = nil
end

--- Return all currently-loaded player objects.
---@return table<integer, UmePlayer>
function UmePlayer.GetAll()
    return Players
end

-- Expose on the framework table so other resources can use it.
Ume.Player = UmePlayer
