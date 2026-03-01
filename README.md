# UmeVerse

A custom **FiveM** roleplay framework written in Lua 5.4.

---

## Features

| Area | Details |
|------|---------|
| **Player management** | Server-side player objects with money, inventory, job, and metadata |
| **Callback system** | Bidirectional client ↔ server callbacks with async response handling |
| **Inventory** | Weight-based inventory with per-slot item stacking |
| **Notifications** | NUI toast notifications (info / success / warning / error) |
| **Locale / i18n** | Key-based translation system with placeholder substitution |
| **Auto-save** | Configurable periodic `umeverse:server:savePlayer` event for database bridges |
| **Exports** | `GetCoreObject`, `GetPlayer`, `GetPlayers`, `GetIdentifier` |

---

## Directory structure

```
umeverse/
├── fxmanifest.lua        # FiveM resource manifest
├── config.lua            # Server configuration
├── shared/
│   ├── locale.lua        # Locale/translation helpers
│   ├── utils.lua         # Shared utility functions
│   └── main.lua          # Core Ume table
├── server/
│   ├── player.lua        # UmePlayer class + registry
│   ├── functions.lua     # Server helper functions & exports
│   ├── main.lua          # Server entry point
│   └── events.lua        # Server event handlers
├── client/
│   ├── main.lua          # Client entry point
│   ├── functions.lua     # Client helper functions
│   └── events.lua        # Client event handlers
├── locale/
│   └── en.lua            # English translations
└── html/
    └── index.html        # NUI overlay (notification toasts)
```

---

## Installation

1. Copy the `umeverse` folder into your FiveM server's `resources` directory.
2. Add `ensure umeverse` to your `server.cfg`.
3. *(Optional)* Connect a database bridge resource that listens to:
   - `umeverse:server:loadPlayer` — load / create a character from persistent storage.
   - `umeverse:server:savePlayer` — persist player data on the auto-save tick.

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

-- Inventory
player:AddItem('water_bottle', 2, 250)   -- name, count, weight (grams)
player:RemoveItem('water_bottle', 1)
local has = player:HasItem('water_bottle', 1)

-- Job
player:SetJob('police', 'Police Officer', 2, 5000)

-- Metadata
player:SetMetadata('hunger', 80)
local hunger = player:GetMetadata('hunger')

-- Notification
player:Notify('You received $500!', 'success')
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
```

### Events fired

| Event | Side | Payload |
|-------|------|---------|
| `umeverse:client:ready` | Client | `playerData` table |
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
