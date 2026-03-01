-- ============================================================
--  UmeVerse Framework — Item Definitions (shared)
--  Registers every item the server knows about.
--  Fields:
--    label   — display name shown in inventory UI
--    weight  — grams per unit (used for inventory weight cap)
--    usable  — whether the item can be "used" client-side
--    stack   — whether identical items stack (default true)
-- ============================================================

UmeItems = {}

local _registry = {
    -- ── Consumables ──────────────────────────────────────────
    water_bottle  = { label = 'Water Bottle',    weight = 250,   usable = true,  stack = true  },
    sandwich      = { label = 'Sandwich',        weight = 300,   usable = true,  stack = true  },
    energy_drink  = { label = 'Energy Drink',    weight = 200,   usable = true,  stack = true  },

    -- ── Medical ──────────────────────────────────────────────
    bandage       = { label = 'Bandage',         weight = 100,   usable = true,  stack = true  },
    first_aid_kit = { label = 'First Aid Kit',   weight = 500,   usable = true,  stack = false },
    painkillers   = { label = 'Painkillers',     weight = 50,    usable = true,  stack = true  },

    -- ── Tools ────────────────────────────────────────────────
    lockpick      = { label = 'Lockpick',        weight = 50,    usable = true,  stack = true  },
    phone         = { label = 'Phone',           weight = 150,   usable = true,  stack = false },
    radio         = { label = 'Radio',           weight = 300,   usable = true,  stack = false },
    toolkit       = { label = 'Toolkit',         weight = 1000,  usable = true,  stack = false },

    -- ── Documents ────────────────────────────────────────────
    id_card       = { label = 'ID Card',         weight = 10,    usable = false, stack = false },
    drivers_license = { label = "Driver's License", weight = 10, usable = false, stack = false },

    -- ── Weapons / Ammo ───────────────────────────────────────
    pistol_ammo   = { label = 'Pistol Ammo',     weight = 30,    usable = false, stack = true  },
    rifle_ammo    = { label = 'Rifle Ammo',      weight = 50,    usable = false, stack = true  },

    -- ── Miscellaneous ────────────────────────────────────────
    money_bag     = { label = 'Money Bag',       weight = 500,   usable = false, stack = false },
    zip_tie       = { label = 'Zip Tie',         weight = 20,    usable = true,  stack = true  },
}

--- Retrieve the definition for a named item, or nil if unknown.
---@param name string
---@return table|nil
function UmeItems.Get(name)
    return _registry[name]
end

--- Return whether an item name is registered.
---@param name string
---@return boolean
function UmeItems.Exists(name)
    return _registry[name] ~= nil
end

--- Return the weight (grams) of a single unit of an item.
---@param name string
---@return integer  0 if item is unknown
function UmeItems.GetWeight(name)
    local item = _registry[name]
    return item and item.weight or 0
end

--- Return the display label for an item.
---@param name string
---@return string  Falls back to the raw name if unregistered
function UmeItems.GetLabel(name)
    local item = _registry[name]
    return item and item.label or name
end

--- Return the full item registry (read-only intent).
---@return table
function UmeItems.GetAll()
    return _registry
end

--- Register a new item at runtime (useful for external resources).
---@param name   string
---@param config table   Must contain at minimum `label` and `weight`.
function UmeItems.Register(name, config)
    assert(type(name) == 'string' and name ~= '', 'UmeItems.Register: name must be a non-empty string')
    assert(type(config) == 'table', 'UmeItems.Register: config must be a table')
    config.stack  = config.stack  ~= false   -- default true
    config.usable = config.usable == true    -- default false
    _registry[name] = config
end
