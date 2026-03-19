# 🌌 Umeverse Framework - Comprehensive Guide

A complete, production-ready FiveM framework built from scratch with **Lua** (server/client logic) and **JavaScript** (NUI interfaces). Designed for full server management with an integrated economy, inventory, vehicle system, criminal progression, and admin tools.

**Version:** 1.0.0 | **Language:** Lua 5.4 + JavaScript | **Target:** GTA V (FiveM)

---

## 📑 Table of Contents

1. [Quick Start](#-quick-start)
2. [Architecture Overview](#%EF%B8%8F-architecture-overview)
3. [Core Systems](#-core-systems)
4. [Installation & Setup](#-installation--setup)
5. [Configuration](#%EF%B8%8F-configuration)
6. [Systems Guide](#-systems-guide)
7. [Commands Reference](#-commands-reference)
8. [Database Schema](#-database-schema)
9. [Development Guide](#-development-guide)
10. [Troubleshooting](#-troubleshooting)

---

## 🚀 Quick Start

### Prerequisites
- FiveM Server (latest recommended build)
- MySQL 8.0+ or MariaDB 10.5+
- Node.js (for any additional tooling)
- Basic Lua/JavaScript knowledge (for customization)

### 5-Minute Setup

1. **Download and Install**
   ```bash
   git clone https://github.com/UmeDemon/umeverse.git
   cd umeverse
   ```

2. **Import Database**
   ```bash
   mysql -u root -p your_database < umeverse.sql
   ```

3. **Configure Server**
   - Copy `server.cfg.example` to your server's `server.cfg`
   - Update MySQL connection string: `set mysql_connection_string "mysql://user:pass@host/db"`
   - Set FiveM license key: `sv_licenseKey "YOUR_KEY"`

4. **Copy Resources**
   ```bash
   # Copy all umeverse_* folders to your server's resources/ directory
   cp -r umeverse_* /path/to/server/resources/
   ```

5. **Start Server**
   - All resources will auto-load with correct server.cfg configuration

---

## 🏗️ Architecture Overview

### Resource Hierarchy

```
┌─────────────────────────────────────────────────────────────┐
│  STANDALONE SCRIPTS (Third-party compatibility)             │
│  └─ umeverse_bridge_qb, umeverse_bridge_esx, bridge_tmc     │
├─────────────────────────────────────────────────────────────┤
│  ENTERPRISE SYSTEMS (Complex, interdependent)               │
│  ├─ umeverse_crime       (Street-level crimes, heat)        │
│  ├─ umeverse_gangs       (Gang management, territories)     │
│  ├─ umeverse_drugs       (Production, sales, laundering)    │
│  └─ umeverse_jobs        (20 civilian jobs + progression)   │
├─────────────────────────────────────────────────────────────┤
│  COMMERCE & ECONOMY (Player interaction systems)            │
│  ├─ umeverse_inventory   (Grid-based items, weight)         │
│  ├─ umeverse_banking     (Deposits, transfers, history)     │
│  ├─ umeverse_vehicles    (Garage, fuel, impound, keys)      │
│  └─ umeverse_appearance  (Clothing stores, barber shops)    │
├─────────────────────────────────────────────────────────────┤
│  CORE FRAMEWORK (Foundation for all systems)                │
│  ├─ umeverse_core        (Players, characters, events)      │
│  ├─ umeverse_admin       (Admin panel, management)          │
│  ├─ umeverse_weathersync (Environment, time sync)           │
│  └─ umeverse_hud         (Screen overlays, UI)              │
├─────────────────────────────────────────────────────────────┤
│  DEPENDENCIES (Third-party libraries)                       │
│  ├─ oxmysql              (MySQL driver)                     │
│  ├─ ox_lib               (Utility library)                  │
│  └─ pma-voice            (Voice chat)                       │
└─────────────────────────────────────────────────────────────┘
```

### Load Order (server.cfg)
1. Dependencies (oxmysql, ox_lib, pma-voice)
2. Core framework (umeverse_core)
3. Economy systems (banking, inventory, vehicles)
4. Job systems (jobs, appearance)
5. Enterprise systems (drugs, crime, gangs)
6. Admin & utilities (admin, hud, weathersync)
7. Optional bridges (for third-party script compatibility)

---

## 📦 Core Systems

### 1. **Core Framework** (`umeverse_core`)
**Purpose:** Foundation for all player management and features

**Key Functions:**
- Player authentication and data persistence
- Character system with multi-character support
- Job management and salary payments
- Death system and respawn
- Command registration
- Event broadcasting
- NUI communication layer

**Key Exports:**
```lua
UME.GetPlayer(source)                  -- Get player object
UME.GetJob(jobName)                    -- Get job definition
UME.IsReady()                          -- Check framework ready
UME.GetPlayers()                       -- Get all players
UME.GetPlayerCount()                   -- Player count
```

**UI Components:**
- Character selection screen
- Player notifications
- Loading screens

---

### 2. **Inventory System** (`umeverse_inventory`)
**Purpose:** Grid-based item management with drag-and-drop interface

**Features:**
- Grid-based inventory (12 slots default)
- Weight-based capacity system (30kg default)
- Item drops in world
- Stash management (safes, lockboxes, etc.)
- Drag-and-drop NUI interface
- Item sorting and organization
- Drop proximity system

**Database:** `umeverse_inventory_items` table
- Tracks player items, slots, weight
- Stash/container contents

**Key Commands:**
```
/inventory          Open inventory
/drop [quantity]     Drop item from inventory
```

---

### 3. **Banking System** (`umeverse_banking`)
**Purpose:** Financial transactions and currency management

**Features:**
- Bank deposits and withdrawals
- Player-to-player transfers
- Transaction history (with timestamps)
- ATM network
- Check deposits
- Overdraft protection (configurable)
- Banking UI with real-time balance updates

**Database:** 
- `umeverse_players` (cash/bank fields)
- `umeverse_transactions` (transaction log)

**Key Commands:**
```
/bank               Open banking menu
/transfer [id] [amount]  Transfer to player
/atm                Access ATM
/checkbalance       View balance
```

---

### 4. **Vehicle System** (`umeverse_vehicles`)
**Purpose:** Vehicle ownership, garage management, and key sharing

**Features:**
- Vehicle garage system with NUI vehicle selector
- Impound system for abandoned/violation vehicles
- Fuel decay system
- Vehicle key sharing
- Seatbelt system
- Damage state persistence
- Vehicle customization locks

**Database:**
- `umeverse_vehicles` (owned vehicles)
- `umeverse_vehicle_keys` (shared key access)

**Key Commands:**
```
/garage             Access personal garage
/impound            View impounded vehicles
/carkeys [id]       Give car keys to player
/fuelcar [amount]   Add fuel to vehicle
/customizecar       Open customization menu
```

---

### 5. **Job System** (`umeverse_jobs`)
**Purpose:** Employment system with 20+ civilian job types

**Features:**
- 20 civilian jobs with unique mechanics
- XP-based progression system (auto-promotion through grades)
- Streak system (consecutive shifts = multiplier bonuses)
- Random events during shifts (tips, bonuses, flat tires, etc.)
- Vehicle condition tracking (bonus/deduction at shift end)
- Environmental bonuses (night +15%, rain +10%)
- Shift completion summary overlay
- NPC helpers for immersion

**Jobs Available:**
```
Tier 1: Garbage Collector, Bus Driver, Taxi, Pizza Delivery
Tier 2: Trucker, Fisherman, Lumberjack, Miner
Tier 3: Tow Truck Operator, Reporter, Helicopter Tour
Tier 4: Postal Worker, Dock Worker, Train Operator
Tier 5: Hunter, Farmer, Diver, Vineyard Worker, Electrician, Security Guard
```

**Progression System:**
- Grade 0-5 based on XP accumulation
- Automatic promotions every 1000 XP
- Streak bonuses: 2 shifts (1.2x), 4 shifts (1.5x), 7 shifts (2.0x), 10+ shifts (2.5x)

**Database:** 
- `umeverse_job_progression` (XP, grades, streaks)

**Key Commands:**
```
/job [jobname]      Clock in/out of job
/jobstats           View progression stats
/available          List available jobs
```

---

### 6. **Appearance System** (`umeverse_appearance`)
**Purpose:** Character customization via barber and clothing stores

**Features:**
- Full ped customization (faces, bodies, overlays)
- Clothing store with outfit creation
- Barber shop with hair/facial hair customization
- Props management (hats, glasses, etc.)
- Component/overlay editor via NUI
- Price system for services
- Outfit saving and reloading

**Database:** `umeverse_players` (ped_data, customization fields)

**Key Commands:**
```
/barber             Visit barber shop
/clothing           Visit clothing store
/appearance         Open appearance editor
```

---

### 7. **Crime System** (`umeverse_crime`)
**Purpose:** Street-level criminal activities with progression

**Features:**
- 6 distinct crime types:
  - Pickpocketing (low risk, $100-300)
  - Store robbery (medium risk, $500-1000)
  - Car theft (medium risk, $800-1200)
  - Burglary (high risk, $1500-2500)
  - ATM robbery (extreme risk, $2000-4000)
  - Jewelry heist (extreme risk, $5000-10000)
  
- **Specialization System:**
  - Lockpicking (10-30% bonus to safe breaks)
  - Hacking (10-30% bonus to electronics)
  - Stealth (10-30% increased detection evasion)
  - Brawler (10-30% combat effectiveness)
  - Unlock cost: $500-750 each
  - XP progression (10 levels per specialization)

- **Heat Mechanics:**
  - Accumulates with crimes (1-5 star wanted levels)
  - Decays over time (60 seconds per level)
  - Cooldown on locations (30 min before repeat)
  - Police dispatch triggered at high heat
  - Safehouse amnesty ($1000/hour)
  
- **Dynamic Crime Mechanics:**
  - Complications (15% chance during crime)
  - Witness generation (20% chance)
  - Time-based bonuses (early morning +15%)
  - Weather effects (rain -20% detection)
  - Bounty system ($5k-$50k range)
  - Bounty claiming (75% payout, rep requirement 5)
  - Consequences system (fines, jail time, reputation loss)

**Database:**
- `umeverse_crime_stats` (player crime records)
- `umeverse_crime_specializations` (specialization levels)
- `umeverse_crime_heat` (wanted level tracking)
- Tables for specializations, bounties, consequences

**Key Commands:**
```
/crimespec          Open specializations menu
/bounties           Open bounty board
/startcrime         Begin crime objective
/evadeheat          Use safehouse/amnesty
/crimeheat          Check wanted level
```

---

### 8. **Gang System** (`umeverse_gangs`)
**Purpose:** Organized crime groups with territories and warfare

**Features:**
- **5 Predefined Gangs:**
  - The Ballas, Families, Vagos, Lost MC, Cartel Del Los Santos
  
- **Gang Ranks:**
  - Prospect (0) → Member (1) → Enforcer (2) → Lieutenant (3) → Captain (4) → Leader (5)
  - Permission system per rank
  - Automatic demotion on inactivity
  
- **Territory System:**
  - 5 controllable territories
  - Gang control affects:
    - Crime rewards (1.3-1.5x multiplier in controlled turf)
    - Drug sales multipliers (1.3-1.8x)
    - Drug production speed (1.3x) and capacity (1.2x)
  - Territory influence battles
  - Contested territory mechanics
  
- **Gang Infrastructure:**
  - Upgradeable gang bases with perks
  - Member bonuses per upgrade level
  - Warehouse capacity expansion
  - Equipment access (weapons, armor)
  - Safehouses with stash storage
  
- **Criminal Enterprises:**
  - Gang-exclusive crime missions
  - Types: Drug Runs, Protection Rackets, Territory Defense, Heists
  - Rewards: 100-200% vs street crimes
  - Require minimum rank/reputation
  
- **Gang Warfare:**
  - Declare wars on rival gangs (cost: $10k)
  - Kill-based scoring system
  - 3-10 day wars with daily influence shifts
  - Victory rewards territory control
  - Auto-revenge eligibility after loss
  - Peace negotiation system
  
- **Alliances & Diplomacy:**
  - Temporary alliances (24-48 hours)
  - Treaties with shared crime rewards
  - Mutual defense agreements
  - Alliance messages board
  
- **Member Perks:**
  - Grade-based salary bonuses
  - Gang bank access (repository for money)
  - Vehicle spawning rights
  - Weapon discounts
  - Safe zone protection
  
- **Communication:**
  - Gang message board
  - Weekly challenges with leaderboards
  - Monthly tournament ($10k-$30k prizes)
  - Rival activity notifications
  
- **Gang Bank:**
  - Shared money storage
  - 2% deposit fee
  - Member withdrawal permissions
  - Balance history logging

**Database:**
- `umeverse_gang_members` (membership records)
- `umeverse_gang_territories` (territory control)
- `umeverse_gang_wars` (active conflicts)
- `umeverse_gang_infrastructure` (base upgrades)
- `umeverse_gang_banks` (shared funds)
- `umeverse_gang_alliances` (diplomatic relations)
- `umeverse_gang_enterprises` (mission tracking)
- Additional tables for communications, perks, challenges

**Key Commands:**
```
/gang                Gang management menu
/ganginfra           Gang infrastructure upgrades
/alliances           Alliance management
/startwar [gang]     Declare war ($10k)
/negotiatepeace      Propose peace terms
/gangbank            Access gang bank
/safehouse           Open gang safehouse
/gangboard           View message board
/gangchallenges      View weekly challenges
/gangtournament      View monthly tournament
/acceptalliance [id] Accept alliance request
/breakalliance [id]  End alliance
```

---

### 9. **Drug System** (`umeverse_drugs`)
**Purpose:** Drug production, sales, and money laundering

**Features:**
- Drug production in warehouses
- Street-level drug dealing
- Wholesale operations
- Money laundering system
- Territory-based multipliers (from gang system)
- Police heat and dispatch
- Rival gang disruption mechanics
- Market prices affected by supply/demand

**Integration Points:**
- Gang territories provide 1.3-1.8x sales multiplier
- Crime system complements through heat mechanics
- Banking system for money laundering
- Inventory system for drug storage

---

### 10. **Admin System** (`umeverse_admin`)
**Purpose:** Server management and player administration tools

**Features:**
- Admin panel with player management
- Ban/unban system
- Quick actions (teleport, heal, freeze)
- Vehicle spawning for admins
- Server announcements
- Player kick/warn system
- Permission-based access (moderator → owner)

**Permission Levels:**
```
umeverse.moderator    - Basic moderation
umeverse.admin        - Full admin access
umeverse.superadmin   - Server management
umeverse.owner        - Complete control
```

**Key Commands:**
```
/admin               Open admin panel
/ban [id] [reason]   Ban player
/unban [id]          Unban player
/kick [id] [reason]  Kick player
/teleport [id]       Teleport to player
/tele2me [id]        Teleport player to you
/heal                Heal yourself/target
/announce [msg]      Server announcement
```

---

### 11. **Weather & Time** (`umeverse_weathersync`)
**Purpose:** Server-authoritative environmental synchronization

**Features:**
- Dynamic weather system
- Time synchronization across all players
- Weather progression effects
- Default weather configurations
- Admin commands for weather management

**Key Commands:**
```
/weather [type]      Change weather
/time [hour]:[min]   Set server time
/weatherlist         List available weather
```

---

### 12. **Bridges** (`umeverse_bridge_qb`, `umeverse_bridge_esx`, `umeverse_bridge_tmc`)
**Purpose:** Compatibility layers for legacy scripts

**Capabilities:**
- Allows QBCore/QBox scripts to run without modification
- Allows ESX scripts to run without modification
- Allows TMC (The Mob City) scripts to run without modification
- Provides framework-agnostic APIs
- Prevents conflicts with native Umeverse systems

**Load Order:** After `umeverse_core`

---

## 💾 Installation & Setup

### Step 1: Database Import

```bash
# From command line
mysql -u root -p your_database < umeverse.sql
```

**Or manually in your database tool (HeidiSQL, phpMyAdmin, etc.):**
1. Open `umeverse.sql`
2. Execute all commands
3. Verify tables created (30+ tables)

**Tables Created:**
- Core: `umeverse_players`, `umeverse_bans`, `umeverse_jobs`
- Inventory: `umeverse_inventory_items`
- Banking: `umeverse_transactions`
- Vehicles: `umeverse_vehicles`, `umeverse_vehicle_keys`
- Crime: `umeverse_crime_stats`, `umeverse_crime_specializations`, etc.
- Gangs: `umeverse_gang_members`, `umeverse_gang_territories`, etc.
- Drugs: `umeverse_drug_warehouses`, `umeverse_drug_sales`, etc.

### Step 2: Resource Installation

```bash
# Copy all resources to your server
cp -r umeverse_* /path/to/server/resources/
cp -r oxmysql ox_lib pma-voice /path/to/server/resources/
```

### Step 3: Server Configuration

Create or update `server.cfg`:

```cfg
# ─────────────────────────────────────
# Core Configuration
# ─────────────────────────────────────
sv_hostname "Umeverse RP"
sv_maxclients 64
set onesync on
sv_licenseKey "YOUR_FIVEM_LICENSE_HERE"
set mysql_connection_string "mysql://user:password@host:3306/database?charset=utf8mb4"

# ─────────────────────────────────────
# Dependencies (FIRST)
# ─────────────────────────────────────
ensure oxmysql
ensure ox_lib
ensure pma-voice

# ─────────────────────────────────────
# Umeverse Framework (ORDER MATTERS)
# ─────────────────────────────────────
ensure umeverse_core          # Core framework (MUST BE FIRST)
ensure umeverse_inventory     # Player inventory
ensure umeverse_banking       # Banking system
ensure umeverse_vehicles      # Vehicle management
ensure umeverse_admin         # Admin panel
ensure umeverse_weathersync   # Weather/time sync
ensure umeverse_appearance    # Clothing & barber
ensure umeverse_jobs          # Job system
ensure umeverse_drugs         # Drug system

# Enterprise systems (can be optional)
ensure umeverse_crime         # Crime system
ensure umeverse_gangs         # Gang system
ensure umeverse_hud           # HUD overlay

# ─────────────────────────────────────
# Optional: Compatibility Bridges
# ─────────────────────────────────────
# ensure umeverse_bridge_qb    # QBCore/QBox compatibility
# ensure umeverse_bridge_esx   # ESX compatibility
# ensure umeverse_bridge_tmc   # TMC compatibility

# ─────────────────────────────────────
# Admin Permissions (ACE)
# ─────────────────────────────────────
add_ace identifier.license:XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX umeverse.owner allow
add_ace identifier.license:XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX umeverse.superadmin allow
add_ace identifier.license:XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX umeverse.admin allow
add_ace identifier.license:XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX umeverse.moderator allow
```

### Step 4: Admin Setup

Replace license identifiers in `server.cfg` with your own. Get your identifier by:
1. Connecting to server
2. Type `status` in console
3. Copy your license identifier
4. Add ACE permissions

---

## ⚙️ Configuration

### Main Configuration File (`config.lua`)

Located in the root directory. Key settings:

```lua
-- Identifier type: 'steam', 'license', 'discord', 'xbl', 'live', 'fivem'
UmeConfig.Identifier = 'license'

-- Starting money
UmeConfig.StartingCash = 500
UmeConfig.StartingBank = 2000
UmeConfig.DefaultJob = { name = 'unemployed', salary = 200 }

-- Inventory capacity (grams)
UmeConfig.MaxInventoryWeight = 30000

-- Auto-save interval (milliseconds)
UmeConfig.AutoSaveInterval = 300000  -- 5 minutes

-- Default spawn point
UmeConfig.SpawnPoint = {
    x = -269.4,
    y = -955.3,
    z = 31.2,
    heading = 205.0,
}

-- HUD visibility
UmeConfig.ShowHud = true

-- Debug console output
UmeConfig.Debug = false
```

### Per-System Configuration

**Jobs** (`umeverse_jobs/config.lua`)
- Individual job settings: blip locations, vehicle types, payment rates, xp requirements

**Crime** (`umeverse_crime/config.lua` & `config_enhanced.lua`)
- Crime types, rewards, heat mechanics, specialization costs

**Gangs** (`umeverse_gangs/config.lua` & `config_enhanced.lua`)
- Gang definitions, territory locations, upgrade costs, war mechanics

**Drugs** (`umeverse_drugs/config.lua`)
- Production rates, selling locations, laundry locations, market prices

---

## 📖 Systems Guide

### Crime System Deep Dive

**Criminal Progression Path:**

1. **Beginner Criminal**
   - Access pickpocketing and store robberies
   - Low reward, low risk
   - Build heat slowly
   - Earn black money

2. **Established Criminal**
   - Unlock specializations ($500-750 each)
   - Access car theft and burglary
   - Higher rewards, higher heat
   - Build reputation and record

3. **Dangerous Individual**
   - Reach 100+ crime reputation
   - Access ATM and jewelry heists
   - Join gang for enterprise crimes
   - 30-50% bonus rewards as gang member

4. **Crime Kingpin**
   - Gang leader or high rank
   - 100-200% bonus rewards in enterprises
   - Territory control bonuses (1.5x)
   - Direct profits from gang operations

**Heat Management:**
- Heat accumulates per crime (1-5 star system)
- Decays at 1 star per 60 seconds
- Location cooling: 30-minute cooldown before repeat
- High heat triggers police dispatch
- Safehouse for amnesty ($1000/hr)
- Gang heat amnesty ($5000 from gang bank)

**Specializations:**
- Cost: $500-750 per unlock
- Progression: 10 levels per specialization
- Bonuses: 10-30% effectiveness increase
- XP earned through successful crimes

---

### Gang System Deep Dive

**Gang Lifecycle:**

1. **Join Gang**
   - Start as Prospect (rank 0)
   - Access basic gang bank
   - 30% crime reward bonus

2. **Rank Up**
   - Earn reputation through crimes
   - Automatic promotion every milestone
   - Enforcer+ unlocks leader roles
   - Captain/Leader runs gang

3. **Territory Control**
   - Gangs control 1-5 territories
   - Controlled territory: 1.5x crime bonus
   - Contested: 0.7x crime penalty
   - War zone: 2.0x crime bonus

4. **Business Operations**
   - Criminal enterprises (Drug Runs, Rackets)
   - Gang bank for shared funds (2% fee)
   - Infrastructure upgrades
   - Drug operation bonuses

5. **Gang Warfare**
   - Declare war ($10k cost)
   - Kill-based scoring (3-10 day wars)
   - Winner takes territory
   - Influence shifts daily during war

**Gang Bonuses:**
```
Prospect (Rank 0):  30% crime rewards
Member (Rank 1):    40% crime rewards
Enforcer (Rank 2):  50% crime rewards, leader perks
Lieutenant (Rank 3): Territory bonus (1.5x), enterprise access
Captain (Rank 4):   War bonuses (2.0x), all perks
Leader (Rank 5):    Full gang control, diplomacy
```

---

### Drug System Integration

**Territory Multipliers:**
- Non-gang members: 1.0x base sales
- Gang members: 1.3x-1.8x in controlled territories
- Contested territories: 0.7x during disputes
- War zones: 0% (operations paused)

**Black Money Loop:**
```
Crime Earnings (dirty money)
  ↓
Deposit in bank/gang bank
  ↓
Use for gang enterprises
  ↓
Enterprise payouts (increased)
  ↓
Drug dealing with territory bonus
  ↓
Launder through banking system
  ↓
Clean bank money
```

---

## 🎮 Commands Reference

### Player Commands

#### General
```
/help               Show all available commands
/status             Check player status
/car                Spawn a car (if allowed)
/me [action]        Perform emote/action
/do [desc]          Describe action outcome
/say [message]      Local chat
```

#### Jobs
```
/job [jobname]      Clock in/out of job
/jobstats           View job progression
/available          List available jobs
/endshift           End current shift
```

#### Inventory & Items
```
/inventory          Open inventory
/drop [qty]         Drop item
/use [item]         Use item
/info [item]        Item information
```

#### Banking
```
/bank               Open banking menu
/balance            Check balance
/transfer [id] [amt]  Send money to player
/atm                Use ATM
/checkhistory       View transaction log
```

#### Vehicles
```
/garage             Access vehicle garage
/impound            View impounded vehicles
/carkeys [id]       Give keys to player
/fuelcar [amt]      Add fuel to vehicle
/park               Park vehiclefor storage
/carinfo            Vehicle information
```

#### Appearance
```
/barber             Visit barber shop
/clothing           Visit clothing store
/appearance         Appearance editor
/removeoutfit       Remove current outfit
```

#### Crime
```
/crimespec          Specializations menu
/bounties           Bounty board
/startcrime         Begin crime
/evadeheat          Use safehouse/amnesty
/crimeheat          Check wanted level
/criminal           Criminal record
```

#### Gangs
```
/gang               Gang management
/gang invite [id]   Invite player
/gang kick [id]     Remove member
/gang demote [id]   Reduce rank
/ganginfra          Infrastructure menu
/alliances          Alliance management
/gangbank           Access bank
/safehouse          Safehouse
/gangboard          Message board
/gangchallenges     Weekly challenges
/gangtournament     Monthly tournament
/startwar [gang]    Declare war
/negotiatepeace     Peace terms
/acceptalliance [id] Accept alliance
/breakalliance [id] End alliance
```

### Admin Commands

#### Player Management
```
/ban [id] [reason]     Ban player permanently
/bantemp [id] [hrs] [reason]  Ban for hours
/unban [id]            Remove ban
/kick [id] [reason]    Remove from server
/warn [id] [reason]    Issue warning
```

#### Actions
```
/teleport [id]         Teleport to player
/tele2me [id]          Bring player to you
/freeze [id]           Freeze player
/unfreeze [id]         Unfreeze player
/heal [id]             Heal player
/armor [id]            Add armor
/kill [id]             Kill player
```

#### Server
```
/announce [message]    Server announcement
/players               List online players
/ids                   Player IDs
/weather [type]        Change weather
/time [hr]:[min]       Set time
```

#### Crime/Gang Admin (umeverse.admin+)
```
/setcriminalheat [id] [lvl]    Set wanted level
/clearheat [id]                Clear wanted level
/checkrecord [id]              View criminal record
/admingivelevel [id] [spec] [lvl]  Set specialization
/adminclearspec [id]           Clear specializations
/setgangrep [id] [amt]         Set gang reputation
/declarewar [gang1] [gang2]    Force war
/endwar [gang1] [gang2]        End war
/addterritory [gang] [terr]    Give territory
```

---

## 💾 Database Schema

### Player & Core Tables

**umeverse_players**
```sql
id, identifier (license/steam), citizenid, firstname, lastname,
ped_data, job_name, job_grade, salary, cash, bank,
hours_played, created_at, updated_at
```

**umeverse_jobs**
```sql
id, name, label, type (leo|ems|job|law), default_duty, 
grades (JSON array), created_at
```

**umeverse_bans**
```sql
id, identifier, reason, banner_id, banned_at, expires, permanent
```

### Inventory & Commerce

**umeverse_inventory_items**
```sql
id, owner_id, item_name, item_count, item_metadata, slot, 
container_id, weight, created_at
```

**umeverse_transactions**
```sql
id, from_id, to_id, amount, type (transfer|deposit|withdraw),
reason, timestamp
```

**umeverse_vehicles**
```sql
id, owner_id, plate, model, vin, customization_data, 
fuel, mileage, location, created_at, updated_at
```

**umeverse_vehicle_keys**
```sql
id, vehicle_id, owner_id, shared_with_id (shared person),
created_at
```

### Crime System

**umeverse_crime_stats**
```sql
id, player_id, crimes_completed, total_earnings, specialization_xp,
current_heat, criminal_record, created_at, updated_at
```

**umeverse_crime_specializations**
```sql
id, player_id, specialization (lockpicking|hacking|stealth|brawler),
level, xp, unlocked_at
```

**umeverse_crime_heat**
```sql
id, player_id, heat_level, last_crime_location, cooldown_expires,
created_at
```

**umeverse_crime_bounties**
```sql
id, target_id, bounty_amount, posted_by, created_at, expires_at
```

### Gang System

**umeverse_gang_members**
```sql
id, player_id, gang_name, rank (0-5), reputation, joined_at,
last_activity, permissions (JSON)
```

**umeverse_gang_territories**
```sql
id, gang_name, territory_location, influence, contested,
controller_gang, created_at, last_disputed
```

**umeverse_gang_banks**
```sql
id, gang_name, balance, last_transaction, created_at
```

**umeverse_gang_wars**
```sql
id, initiator_gang, defender_gang, territory, start_time, end_time,
winner, attacker_score, defender_score, status
```

**umeverse_gang_infrastructure**
```sql
id, gang_name, upgrade_type, level, bonus_percentage, cost,
installed_at
```

**umeverse_gang_enterprises**
```sql
id, gang_name, mission_type, target_player, reward, status, 
created_at
```

---

## 🛠️ Development Guide

### Adding a Custom System

1. **Create Resource Folder**
   ```
   your_resource/
   ├── fxmanifest.lua       (Resource metadata)
   ├── shared/
   │   ├── config.lua       (Configuration)
   │   └── utils.lua        (Shared functions)
   ├── client/
   │   ├── main.lua         (Client initialization)
   │   └── events.lua       (Client event listeners)
   ├── server/
   │   ├── main.lua         (Server initialization)
   │   └── events.lua       (Server event listeners)
   ├── sql/
   │   └── init.sql         (Database schema)
   └── html/
       ├── index.html       (NUI interface)
       ├── js/
       └── css/
   ```

2. **fxmanifest.lua Template**
   ```lua
   fx_version 'cerulean'
   game 'gta5'
   lua54 'yes'
   
   author 'Your Name'
   description 'Your Resource Description'
   version '1.0.0'
   
   shared_scripts {
       'shared/config.lua',
       'shared/utils.lua',
   }
   
   client_scripts {
       'client/main.lua',
       'client/events.lua',
   }
   
   server_scripts {
       'server/main.lua',
       'server/events.lua',
   }
   
   files {
       'html/index.html',
       'html/js/*.js',
       'html/css/*.css',
   }
   
   ui_page 'html/index.html'
   
   dependencies {
       'umeverse_core',
       'oxmysql',
   }
   ```

3. **Hook into Umeverse**
   ```lua
   -- Wait for framework ready
   while not UME or not UME.IsReady() do
       Wait(100)
   end
   
   -- Access player functions
   local player = UME.GetPlayer(source)
   print("Player job: " .. player.job.name)
   
   -- Listen to events
   RegisterNetEvent('umeverse:server:playerDropped', function(source, reason)
       print("Player " .. source .. " dropped: " .. reason)
   end)
   
   -- Export functions
   exports('YourExport', function()
       return "Your Value"
   end)
   ```

### Using Umeverse Exports

```lua
-- Core functions
local player = exports.umeverse_core:GetPlayer(source)
local job = exports.umeverse_core:GetJob('police')

-- Inventory functions
exports.umeverse_inventory:AddItem(source, 'item_name', 1)
exports.umeverse_inventory:RemoveItem(source, 'item_name', 1)

-- Banking functions
exports.umeverse_banking:AddMoney(source, 1000)
exports.umeverse_banking:RemoveMoney(source, 1000)

-- Job functions
exports.umeverse_jobs:GetPlayerJob(source)
exports.umeverse_jobs:AddXP(source, 100)
```

### Creating Commands

```lua
-- Register command
RegisterCommand('mycommand', function(source, args, rawCommand)
    local player = UME.GetPlayer(source)
    if not player then 
        return TriggerClientEvent('chat:addMessage', source, {
            arg1 = "System",
            args = { "^1Error: ^7Player not loaded" }
        })
    end
    
    -- Do something
    TriggerClientEvent('chat:addMessage', source, {
        arg1 = "Info",
        args = { "Command executed!" }
    })
end, false)
```

### Database Queries

```lua
-- Single value
local balance = MySQL.scalar.await(
    'SELECT bank FROM umeverse_players WHERE identifier = ?',
    { playerIdentifier }
)

-- Multiple rows
local vehicles = MySQL.query.await(
    'SELECT * FROM umeverse_vehicles WHERE owner_id = ?',
    { playerId }
)

-- Update/Insert
MySQL.update.await(
    'UPDATE umeverse_players SET bank = ? WHERE identifier = ?',
    { newBalance, playerIdentifier }
)

-- Insert with return
local insertId = MySQL.insert.await(
    'INSERT INTO umeverse_inventory_items (owner_id, item_name, item_count) VALUES (?, ?, ?)',
    { playerId, 'item_name', 1 }
)
```

---

## ❓ Troubleshooting

### Common Issues

**Issue: "Waiting for framework" in console**
- Solution: Ensure `umeverse_core` started before other resources
- Check server.cfg load order
- Verify oxmysql connection string is correct

**Issue: Players not saving**
- Solution: Check MySQL connection
- Verify `umeverse_players` table exists and is accessible
- Check server logs for database errors

**Issue: NUI interfaces not showing**
- Solution: Verify HTML files exist and are referenced in fxmanifest.lua
- Check browser console for JavaScript errors
- Ensure ui_page is correctly set

**Issue: Job progression not working**
- Solution: Verify `umeverse_job_progression` table exists
- Check that player has valid job assigned
- Clear player data and re-login to reset

**Issue: Crime crimes not triggering**
- Solution: Verify crime system loaded
- Check that player has unlocked specializations (if required)
- Verify heat mechanics are responding

**Issue: Gang wars not starting**
- Solution: Ensure both gangs have at least 3 members
- Verify territory exists and is assigned
- Check gang war configuration in config_enhanced.lua

### Debug Mode

Enable debug output in `config.lua`:
```lua
UmeConfig.Debug = true
```

This will:
- Print player loading/unloading
- Show job payment events
- Display crime completion logs
- Log gang operations
- Show database queries (warning: verbose)

### Logs Location

- **Server Console:** `/logs/` directory
- **Error Logs:** Check server logs or FiveM server UI
- **Database:** Check MySQL error log

### Getting Help

1. Check existing documentation in resource folders
2. Review ENHANCEMENTS.md and QUICK_REFERENCE.md for recent changes
3. Check GitHub issues for known problems
4. Enable debug mode and check console output

---

## 📊 Performance Optimization

### Database
- Enable query caching where applicable
- Index frequently queried columns
- Consider archiving old transaction data
- Monitor database connection pool usage

### Client-Side
- Minimize NUI rendering when not visible
- Cache frequently accessed data
- Use garbage collection efficiently
- Profile with FiveM profiler for optimization points

### Server-Side
- Use MySQL async operations (don't block)
- Implement cooldowns for expensive operations
- Use exports over triggers for better performance
- Profile resource usage with FiveM console

---

## 📝 License & Credits

**Umeverse Framework**
- **Author:** UmeDemon
- **Version:** 1.0.0
- **License:** Specify your license here

**Dependencies:**
- **oxmysql:** [GitHub - overextended](https://github.com/overextended/oxmysql)
- **ox_lib:** [GitHub - overextended](https://github.com/overextended/ox_lib)
- **pma-voice:** [GitHub - AvarianKnight](https://github.com/AvarianKnight/pma-voice)

---

## 🔄 Updates & Maintenance

### Regular Tasks
- Backup database regularly
- Review and prune old logs
- Monitor server performance
- Check for Framework updates
- Update dependencies as needed

### Version History
- **1.0.0** - Initial release
  - Core framework
  - All base systems
  - Crime & Gangs integration
  - Full documentation

---

## 🤝 Contributing

To contribute improvements:
1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Submit a pull request
5. Include documentation for new features

---

**Last Updated:** March 2026  
**Maintained By:** UmeDemon  
**Community:** [GitHub Discussions & Issues](https://github.com/UmeDemon/umeverse)

---

## Quick Links

- [Installation Guide](#-installation--setup)
- [Configuration Reference](#%EF%B8%8F-configuration)
- [Commands List](#-commands-reference)
- [Database Schema](#-database-schema)
- [Development Guide](#-development-guide)
- [Troubleshooting](#-troubleshooting)
