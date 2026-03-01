# UmeVerse

A custom **FiveM** roleplay framework written in Lua 5.4.

---

## Features

| Area | Details |
|------|---------|
| **Player management** | Server-side player objects with money, inventory, job, and metadata |
| **Callback system** | Bidirectional client ↔ server callbacks with async response handling |
| **Inventory** | Weight-based inventory with per-slot item stacking; 20+ built-in item definitions |
| **Job system** | `shared/jobs.lua` with grade labels & salaries for 5 default jobs |
| **Item registry** | `shared/items.lua` with `Register`, `Get`, `GetWeight`, `GetLabel` helpers |
| **Database persistence** | Optional oxmysql bridge (`server/database.lua`); falls back to in-memory if absent |
| **Spawn manager** | Spawns ped at last-saved DB position or config default; reports position every 30 s |
| **HUD** | Bottom-left NUI overlay: health bar, armour bar, live money counter |
| **Notifications** | NUI toast notifications (info / success / warning / error) |
| **Commands** | Player: `/me`, `/ooc`, `/id` — Admin: `/kick`, `/setjob`, `/givemoney`, `/setcash`, `/giveitem`, `/players` |
| **Locale / i18n** | Key-based translation system with `{placeholder}` substitution |
| **Auto-save** | Configurable periodic `umeverse:server:savePlayer` event |
| **Exports** | `GetCoreObject`, `GetPlayer`, `GetPlayers`, `GetIdentifier`, `SavePlayer` |

---

## Directory structure

```
umeverse/
├── fxmanifest.lua        # FiveM resource manifest
├── config.lua            # Server configuration
├── sql/
│   └── umeverse.sql      # MySQL/MariaDB players table schema
├── shared/
│   ├── locale.lua        # Locale/translation helpers
│   ├── utils.lua         # Shared utility functions
│   ├── jobs.lua          # Job + grade definitions
│   ├── items.lua         # Item registry
│   └── main.lua          # Core Ume table
├── server/
│   ├── player.lua        # UmePlayer class + registry
│   ├── functions.lua     # Server helper functions & exports
│   ├── main.lua          # Server entry point
│   ├── events.lua        # Server event handlers
│   ├── database.lua      # oxmysql persistence bridge
│   └── commands.lua      # Player + admin commands
├── client/
│   ├── main.lua          # Client entry point
│   ├── functions.lua     # Client helper functions
│   ├── events.lua        # Client event handlers
│   ├── spawn.lua         # Spawn manager
│   └── hud.lua           # HUD tick controller
├── locale/
│   └── en.lua            # English translations
└── html/
    └── index.html        # NUI overlay (HUD + notification toasts)
```

---

## Installation

### Without a database (development / testing)
1. Copy the `umeverse` folder into your FiveM server's `resources` directory.
2. Add `ensure umeverse` to your `server.cfg`.

All player data is stored in memory and resets on server restart.

### With persistent storage (production)
1. Import the schema into your MySQL / MariaDB database:
   ```bash
   mysql -u root -p your_database < sql/umeverse.sql
   ```
2. Install and start [oxmysql](https://github.com/overextended/oxmysql).
3. Add to `server.cfg` **before** `ensure umeverse`:
   ```
   ensure oxmysql
   ensure umeverse
   ```

### Admin permissions (ACE)
Grant the `umeverse.admin` ace to anyone who should use admin commands:
```
add_ace identifier.license:YOUR_LICENSE umeverse.admin allow
```

---

## Configuration (`config.lua`)

| Key | Default | Description |
|-----|---------|-------------|
| `Debug` | `false` | Print extra console output |
| `Identifier` | `'license'` | Identifier type used to look up players |
| `StartingCash` | `500` | Cash given to new characters |
| `StartingBank` | `2000` | Bank balance given to new characters |
| `DefaultJob` | `unemployed` | Job assigned to new characters |
| `MaxInventoryWeight` | `30000` | Maximum inventory weight in grams |
| `AutoSaveInterval` | `300000` | Auto-save interval in milliseconds (5 min) |
| `Locale` | `'en'` | Active locale file |
| `SpawnPoint` | Sandy Shores area | Default spawn coords `{x, y, z, heading}` |
| `ShowHud` | `true` | Show the HUD overlay on spawn |

---

## NUI / HUD

The NUI overlay (`html/index.html`) shows a **bottom-left HUD** and **bottom-right toast notifications**.

![UmeVerse HUD preview](https://github.com/user-attachments/assets/ac2b0504-2e4f-4da8-9320-9bee552a9394)

The HUD updates every 500 ms driven by `client/hud.lua`. It hides automatically on player death and reappears on respawn. Toggle it programmatically:
```lua
Ume.Functions.SetHudVisible(false)
```

---

## API

### Server

```lua
-- Access from another resource:
local Ume = exports['umeverse']:GetCoreObject()

-- Get a player object
local player = Ume.Functions.GetPlayer(source)

-- Money
player:AddCash(500)
player:RemoveCash(100)
player:AddBank(1000)
player:RemoveBank(250)

-- Inventory (uses UmeItems.GetWeight for automatic weight lookup)
local weight = UmeItems.GetWeight('water_bottle')
player:AddItem('water_bottle', 2, weight)
player:RemoveItem('water_bottle', 1)
local has = player:HasItem('water_bottle', 1)

-- Job (validated against UmeJobs definitions)
player:SetJob('police', UmeJobs['police'].label, 2, UmeJobs.GetSalary('police', 2))

-- Metadata
player:SetMetadata('hunger', 80)
local hunger = player:GetMetadata('hunger')

-- Notification
player:Notify('You received $500!', 'success')

-- Manual DB save
exports['umeverse']:SavePlayer(source)
```

### Shared — Jobs

```lua
-- Check validity
UmeJobs.IsValid('police', 2)                      -- true
UmeJobs.GetGradeLabel('police', 2)                -- 'Detective'
UmeJobs.GetSalary('police', 2)                    -- 5000
```

### Shared — Items

```lua
-- Query items
UmeItems.Exists('bandage')                        -- true
UmeItems.GetLabel('bandage')                      -- 'Bandage'
UmeItems.GetWeight('bandage')                     -- 100 (grams)

-- Register a custom item from another resource
UmeItems.Register('custom_item', {
    label  = 'My Custom Item',
    weight = 300,
    usable = true,
})
```

### Client

```lua
local Ume = exports['umeverse']:GetCoreObject()

-- Get cached player data
local pd = Ume.Functions.GetPlayerData()
print(pd.name, pd.cash)

-- Server callback
Ume.Functions.TriggerCallback('umeverse:getPlayerData', function(data)
    print(data.name)
end)

-- Notification
Ume.Functions.Notify('Hello world!', 'info')

-- HUD
Ume.Functions.SetHudVisible(false)
```

### Commands

| Command | Access | Description |
|---------|--------|-------------|
| `/me <action>` | Everyone | Roleplay action in chat |
| `/ooc <msg>` | Everyone | Out-of-character global chat |
| `/id` | Everyone | Show your own server net-id |
| `/kick <id> [reason]` | Admin | Kick a player |
| `/setjob <id> <job> <grade>` | Admin | Set a player's job |
| `/givemoney <id> <amount>` | Admin | Give cash to a player |
| `/setcash <id> <amount>` | Admin | Set a player's exact cash balance |
| `/giveitem <id> <item> [count]` | Admin | Give an item to a player |
| `/players` | Admin | List all online players |

---

### Events fired

| Event | Side | Payload |
|-------|------|---------|
| `umeverse:client:ready` | Client | `playerData` table |
| `umeverse:client:spawned` | Client | `x`, `y`, `z`, `heading` |
| `umeverse:client:moneyUpdated` | Client | `account`, `amount` |
| `umeverse:client:inventoryUpdated` | Client | `inventory` table |
| `umeverse:client:jobUpdated` | Client | `job` table |
| `umeverse:client:metadataUpdated` | Client | `key`, `value` |
| `umeverse:server:playerSpawned` | Server | `source`, `UmePlayer` |
| `umeverse:server:playerLeft` | Server | `source`, `UmePlayer`, `reason` |
| `umeverse:server:savePlayer` | Server | `source`, `playerData` snapshot |
| `umeverse:server:loadPlayer` | Server | `source`, `identifier`, `deferrals` |

---

## Adding a locale

1. Create `locale/<lang>.lua` (copy `locale/en.lua` as a template).
2. Set `UmeConfig.Locale = '<lang>'` in `config.lua`.
3. Add the new file to the `files` block in `fxmanifest.lua`.

## Adding a job

Edit `shared/jobs.lua` and add an entry to the `UmeJobs` table following the existing pattern.

## Adding an item

Edit `shared/items.lua` and add an entry to the `_registry` table, or call `UmeItems.Register(name, config)` from any resource at runtime.

