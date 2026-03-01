# 🌌 Umeverse Framework

A complete, custom FiveM framework built from scratch with **Lua** (server/client logic) and **JavaScript** (NUI interfaces). Designed for full server management with an integrated economy, inventory, vehicle system, and admin tools.

---

## 📦 Resources

| Resource | Description |
|---|---|
| `umeverse_core` | Core framework — player management, character system, jobs, callbacks, commands, death system, NUI (character select, notifications) |
| `umeverse_inventory` | Grid-based inventory with drag & drop, item drops, stashes, weight system |
| `umeverse_banking` | Full banking with deposits, withdrawals, transfers, transaction history, ATM support |
| `umeverse_vehicles` | Garage system with NUI vehicle selector, impound, fuel decay, seatbelt, key system |
| `umeverse_admin` | Admin panel with player management, bans, quick actions, vehicle spawning |
| `umeverse_weathersync` | Server-authoritative weather & time sync — dynamic weather, admin commands, exports |
| `umeverse_appearance` | Clothing stores & barber shops — full ped component/prop/overlay editor with NUI |
| `umeverse_bridge_qb` | Compatibility bridge — run QBCore/QBox scripts without conversion |
| `umeverse_bridge_esx` | Compatibility bridge — run ESX scripts without conversion |
| `umeverse_bridge_tmc` | Compatibility bridge — run TMC (The Mob City) scripts without conversion |

---

## ⚙️ Requirements

- **FiveM Server** (latest recommended artifacts)
- **[oxmysql](https://github.com/overextended/oxmysql)** — MySQL driver
- **MySQL 8.0+** or **MariaDB 10.5+**

---

## 🚀 Installation

### 1. Database Setup

Import the SQL schema into your database:

```sql
mysql -u root -p your_database < umeverse.sql
```

Or open `umeverse.sql` in your database management tool (HeidiSQL, phpMyAdmin, etc.) and execute it. This creates:

- `umeverse_players` — Player/character data
- `umeverse_bans` — Ban records
- `umeverse_vehicles` — Owned vehicles
- `umeverse_stashes` — Stash inventories
- `umeverse_transactions` — Banking transaction log
- `umeverse_vehicle_keys` — Shared vehicle key access

### 2. Install Resources

Copy all `umeverse_*` folders into your server's `resources/` directory:

```
resources/
├── [umeverse_core]/
├── [umeverse_inventory]/
├── [umeverse_banking]/
├── [umeverse_vehicles]/
├── [umeverse_admin]/
├── [umeverse_weathersync]/
├── [umeverse_appearance]/
├── [umeverse_bridge_qb]/    (optional — for QBCore/QBox script compatibility)
├── [umeverse_bridge_esx]/   (optional — for ESX script compatibility)
└── [umeverse_bridge_tmc]/   (optional — for TMC script compatibility)
```

### 3. Server Configuration

Add the following to your `server.cfg`:

```cfg
# Umeverse Framework
ensure oxmysql
ensure umeverse_core
ensure umeverse_inventory
ensure umeverse_banking
ensure umeverse_vehicles
ensure umeverse_admin
ensure umeverse_weathersync
ensure umeverse_appearance

# Optional: Compatibility Bridges (add AFTER umeverse_core)
# ensure umeverse_bridge_qb    # Enables QBCore/QBox scripts
# ensure umeverse_bridge_esx   # Enables ESX scripts
# ensure umeverse_bridge_tmc   # Enables TMC scripts
```

> **Important:** `umeverse_core` must start before all other Umeverse resources.

### 4. Admin Permissions

Grant admin access using Ace Permissions in `server.cfg`:

```cfg
# Admin levels: moderator, admin, superadmin, owner
add_ace identifier.license:xxxxx umeverse.moderator allow
add_ace identifier.license:xxxxx umeverse.admin allow
add_ace identifier.license:xxxxx umeverse.superadmin allow
add_ace identifier.license:xxxxx umeverse.owner allow

# Required for admin commands
add_ace identifier.license:xxxxx command allow
```

Replace `xxxxx` with the player's license identifier.

---

## 🎮 Default Keybinds

| Key | Action |
|---|---|
| `F2` | Toggle Inventory |
| `F7` | Toggle Admin Panel |
| `E` | Interact (bank, garage, ATM, items, clothing store, barber) |
| `K` | Toggle Seatbelt |
| `Escape` | Close any open UI |

---

## 📖 Exports & API

### Core Exports (Server)

```lua
-- Get the framework object
local UME = exports['umeverse_core']:GetCoreObject()

-- Get a player
local Player = UME.Functions.GetPlayer(source)

-- Player money
Player.Functions.AddMoney('cash', 500)
Player.Functions.RemoveMoney('bank', 200)
Player.Functions.GetMoney('cash')

-- Player job
Player.Functions.SetJob('police', 2)
Player.PlayerData.job.name

-- Player inventory
Player.Functions.AddItem('water', 3)
Player.Functions.RemoveItem('bread', 1)
Player.Functions.HasItem('phone')
Player.Functions.GetItemCount('lockpick')

-- Register a server callback
UME.Functions.RegisterServerCallback('myresource:getData', function(source, cb, ...)
    cb({ result = true })
end)

-- Register a usable item
UME.Functions.RegisterUsableItem('phone', function(source, item)
    -- Phone logic
end)
```

### Core Exports (Client)

```lua
-- Get the framework object
local UME = exports['umeverse_core']:GetCoreObject()

-- Get player data
local data = UME.Functions.GetPlayerData()

-- Trigger a server callback
UME.Functions.TriggerServerCallback('myresource:getData', function(result)
    print(result)
end)

-- Check login state
local loggedIn = exports['umeverse_core']:IsLoggedIn()
```

### Events

```lua
-- Server events
RegisterNetEvent('UME:Server:PlayerLoaded', function(Player) end)
RegisterNetEvent('UME:Server:PlayerDropped', function(Player) end)
RegisterNetEvent('UME:Server:OnMoneyChange', function(source, moneyType, amount, operation) end)
RegisterNetEvent('UME:Server:OnJobUpdate', function(source, job) end)

-- Client events
RegisterNetEvent('UME:Client:PlayerLoaded', function(PlayerData) end)
RegisterNetEvent('UME:Client:PlayerUnloaded', function() end)
RegisterNetEvent('UME:Client:OnMoneyChange', function(moneyType, amount, operation, success) end)
RegisterNetEvent('UME:Client:OnJobUpdate', function(job) end)
```

### Weather Sync Exports (Server)

```lua
-- Get current weather type
exports['umeverse_weathersync']:GetCurrentWeather() -- returns string e.g. 'CLEAR'

-- Get current time
exports['umeverse_weathersync']:GetCurrentTime() -- returns { hour, minute }

-- Check if time is frozen
exports['umeverse_weathersync']:IsTimeFrozen() -- returns bool

-- Set weather (syncs to all clients)
exports['umeverse_weathersync']:SetWeather('RAIN')

-- Set time (syncs to all clients)
exports['umeverse_weathersync']:SetTime(14, 30)
```

### Admin Commands (Weather/Time)

| Command | Usage | Permission |
|---|---|---|
| `/weather [type]` | Set weather (CLEAR, RAIN, THUNDER, etc.) | `umeverse.admin` |
| `/time [hour] [minute]` | Set server time | `umeverse.admin` |
| `/freezetime` | Toggle time freeze | `umeverse.admin` |

---

## 🛠️ Configuration

Each resource has its own `config.lua` with all adjustable settings:

- **umeverse_core/config.lua** — Spawn location, starting money, death timer, status decay rates, PvP toggle, auto-save interval
- **umeverse_inventory/config.lua** — Max weight, max slots, drop settings, hotbar keybind
- **umeverse_banking/config.lua** — Bank/ATM locations, transaction limits
- **umeverse_vehicles/config.lua** — Garage locations, impound settings, fuel decay rate, seatbelt damage
- **umeverse_admin/config.lua** — Permission levels, action-level requirements
- **umeverse_weathersync/config.lua** — Time speed, weather change interval, transition duration, weather pool weights, blacklisted weather types
- **umeverse_appearance/config.lua** — Clothing store & barber shop locations, blip settings, interaction distance

---

## 💼 Jobs

Jobs are defined in `umeverse_core/shared/jobs.lua`. Default jobs:

| Job | Grades | Type |
|---|---|---|
| Unemployed | Freelancer | Civilian |
| Police | Recruit → Chief | LEO |
| Ambulance | EMT → Chief | Medical |
| Mechanic | Trainee → Owner | Service |
| Taxi | Driver → Boss | Service |
| Real Estate | Trainee → CEO | Business |
| Judge | Junior → Chief Justice | Government |

Add new jobs by following the existing pattern in the jobs file.

---

## 📦 Items

Items are defined in `umeverse_core/shared/items.lua`. Each item has:

- `label` — Display name
- `weight` — Weight in grams
- `type` — `item` or `weapon`
- `usable` — Can be used/consumed
- `unique` — One per stack
- `description` — Tooltip text

---

## 🏦 Money Types

| Type | Description |
|---|---|
| `cash` | Physical cash, carried on person |
| `bank` | Bank balance, used for transfers |
| `black` | Dirty money, for illegal activities |

---

## � Compatibility Bridges

Umeverse includes optional bridge resources that let you run scripts written for **QBCore**, **QBox**, and **ESX** frameworks **without any code changes**.

### How It Works

FiveM's `provide` directive lets a resource claim another resource's identity. When you start `umeverse_bridge_qb`, it tells FiveM "I am `qb-core`" — so any script calling `exports['qb-core']:GetCoreObject()` gets a Umeverse-backed `QBCore` object. Same principle for ESX.

### Supported Frameworks

| Bridge Resource | Provides | Covers |
|---|---|---|
| `umeverse_bridge_qb` | `qb-core` | QBCore scripts, QBox scripts |
| `umeverse_bridge_esx` | `es_extended` | ESX scripts (legacy & modern) |
| `umeverse_bridge_tmc` | `core` | TMC (The Mob City) scripts |

> **QBox** is QBCore-compatible, so the QB bridge handles QBox scripts automatically.
>
> **TMC** has built-in QBCore aliases, so the TMC bridge also provides QBCore-style globals — TMC scripts using either `TMC` or `QBCore` patterns will work.

### Setup

1. **Uncomment** the bridge(s) you need in `server.cfg`:

```cfg
ensure umeverse_bridge_qb    # For QBCore/QBox scripts
ensure umeverse_bridge_esx   # For ESX scripts
ensure umeverse_bridge_tmc   # For TMC scripts
```

2. **Do NOT** start the original framework alongside the bridge. If you have `qb-core` installed, remove or don't `ensure` it — `umeverse_bridge_qb` replaces it.

3. **Drop in** your QB/ESX scripts as normal. They'll call the bridge without knowing Umeverse is behind it.

### What's Bridged

**QBCore Bridge — Server:**
- `QBCore.Functions.GetPlayer(source)` → Full player wrapper with `PlayerData`, `Player.Functions.AddMoney()`, `RemoveMoney()`, `GetMoney()`, `AddItem()`, `RemoveItem()`, `SetJob()`, `SetMetaData()`, `Save()`, etc.
- `QBCore.Functions.GetPlayerByCitizenId()`
- `QBCore.Functions.GetPlayers()`
- `QBCore.Functions.CreateCallback()` → server callbacks
- `QBCore.Functions.CreateUseableItem()` → usable items
- `QBCore.Functions.Notify()`
- `QBCore.Functions.Kick()`
- `QBCore.Shared.Jobs`, `QBCore.Shared.Items`

**QBCore Bridge — Client:**
- `QBCore.Functions.GetPlayerData()`
- `QBCore.Functions.Notify()`
- `QBCore.Functions.TriggerCallback()`
- `QBCore.Functions.HasItem()`
- `QBCore.Functions.GetClosestPlayer()`
- `QBCore.Functions.SpawnVehicle()`, `DeleteVehicle()`, `GetPlate()`
- `QBCore.Functions.DrawText3D()`, `LoadModel()`, `LoadAnimDict()`
- All QB events: `QBCore:Client:OnPlayerLoaded`, `OnPlayerUnload`, `OnJobUpdate`, `OnMoneyChange`

**ESX Bridge — Server:**
- `ESX.GetPlayerFromId(source)` → Full xPlayer wrapper with `getName()`, `getMoney()`, `addMoney()`, `removeMoney()`, `getAccount()`, `addAccountMoney()`, `getJob()`, `setJob()`, `getInventory()`, `addInventoryItem()`, `removeInventoryItem()`, `kick()`, etc.
- `ESX.GetPlayerFromIdentifier()`
- `ESX.GetPlayers()`, `ESX.GetExtendedPlayers()`
- `ESX.RegisterServerCallback()` → server callbacks
- `ESX.RegisterUsableItem()` → usable items
- `ESX.GetJobs()`, `ESX.GetItemLabel()`
- Legacy `esx:getSharedObject` event support

**ESX Bridge — Client:**
- `ESX.GetPlayerData()`, `ESX.IsPlayerLoaded()`
- `ESX.ShowNotification()`, `ESX.ShowHelpNotification()`
- `ESX.TriggerServerCallback()`
- `ESX.GetAccount()`, `ESX.SearchInventory()`
- `ESX.Game.*` — `GetClosestPlayer()`, `GetClosestVehicle()`, `SpawnVehicle()`, `DeleteVehicle()`, `GetVehicleProperties()`, `SetVehicleProperties()`, `Teleport()`, etc.
- `ESX.Streaming.*` — `RequestModel()`, `RequestAnimDict()`, `RequestAnimSet()`, etc.
- All ESX events: `esx:playerLoaded`, `esx:onPlayerLogout`, `esx:setJob`

**TMC Bridge — Server:**
- `TMC.GetPlayer(source)` → Full player wrapper with `PlayerData`, `Player.Functions.AddMoney()`, `RemoveMoney()`, `GetMoney()`, `SetMoney()`, `AddItem()`, `RemoveItem()`, `GetItemByName()`, `GetItemBySlot()`, `SetJob()`, `SetGang()`, `GetMetaData()`, `SetMetaData()`, `Save()`
- `TMC.GetPlayers()`, `TMC.GetPlayerByCitizenId()`
- `TMC.Functions.CreateCallback()` → server callbacks
- `TMC.Functions.AddItem()`, `RemoveItem()`, `HasItem()`, `AddMoney()`, `RemoveMoney()`, `GetMoney()`
- `TMC.Functions.Notify()`, `GetIdentifier()`, `HasPermission()`, `SpawnVehicle()`
- `TMC.Functions.SendDiscordLog()`, `TMC.Discord.SendMessage()`
- `TMC.Common.*` — Full utility library (50+ functions)
- All TMC events: `TMC:Server:TriggerCallback`, `TMC:UpdatePlayer`, `TMC:Server:SetMetaData`, `TMC:SetEntityStateBag`, `TMC:SendToPlayer`, `TMC:RequestVehicleDelete`
- QBCore aliases: `QBCore = TMC`, all `QBCore:*` event variants handled

**TMC Bridge — Client:**
- `TMC.Functions.GetPlayerData()`, `GetCoords()`
- `TMC.Functions.Notify()`, `SimpleNotify()` (Lua implementation of obfuscated JS)
- `TMC.Functions.TriggerCallback()` → server callbacks
- `TMC.Functions.HasItem()`, `Progressbar()`
- `TMC.Functions.GetClosestPlayer()`, `GetClosestVehicle()`, `GetClosestPed()`, `GetClosestObject()`
- `TMC.Functions.SpawnVehicle()`, `DeleteVehicle()`, `GetPlate()`, `GetVehicleLabel()`
- `TMC.Functions.GetVehicleProperties()`, `SetVehicleProperties()` — massive mod-by-mod fidelity
- `TMC.Functions.DrawText3D()`, `RequestAnimDict()`, `LoadModel()`, `LoadAnimSet()`
- `TMC.Functions.PlayAnim()`, `AttachProp()`, `LookAtEntity()`, `GetStreetNameAtCoords()`, `GetZoneAtCoords()`
- `TMC.Functions.StartParticleAtCoord()`, `StartParticleOnEntity()`
- `TMC.Natives.*` — `GetOffsetFromCoordsInDirection()`, `GetDlcVehicleData()`, `GetDlcWeaponData()`
- All TMC events: `TMC:Client:OnPlayerLoaded`, `OnPlayerUnload`, `SetJob`, `SetGang`, `SetMetaData`, `OnMoneyChange`
- QBCore client aliases: all `QBCore:Client:*` events

### Limitations

- **NUI menus** — Native ESX menus (`ESX.UI.Menu.Open`) are stubbed. Scripts using ox_lib menus or custom NUI work fine.
- **Gang system** — QBCore/TMC gang functions are no-op stubs (Umeverse doesn't have a gang system).
- **Weapons/Loadout** — ESX weapon loadout functions are not bridged. Use Umeverse inventory for weapons.
- **Black money** — ESX `black_money` account maps to cash (Umeverse has no dirty money type).
- **Progress bars** — QB/TMC `Progressbar()` is a simple timer; for full UI progress bars, use ox_lib or similar.
- **Crypto currency** — TMC's `crypto` money type always returns 0 (Umeverse doesn't have crypto).
- **Discord webhooks** — TMC's `SendDiscordLog` logs to server console; implement webhooks separately if needed.
- **TMC obfuscated JS** — `SimpleNotify` and `TriggerServerEvent` (defined in TMC's obfuscated client.js) are re-implemented in Lua.

---

## �📝 License

This framework is provided as-is for personal/server use. Modify freely for your own FiveM server.

---

## 🤝 Credits

- **oxmysql** — Database driver by Overextended
- Built with ❤️ for the FiveM community

---

*Umeverse Framework v1.0.0*
