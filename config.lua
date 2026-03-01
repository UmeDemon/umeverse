-- ============================================================
--  UmeVerse Framework — Configuration
--  Adjust these settings to match your server setup.
-- ============================================================

UmeConfig = {}

-- Debug mode: prints extra information to the console.
UmeConfig.Debug = false

-- The identifier type used to look up players in the database.
-- Supported values: 'steam', 'license', 'discord', 'xbl', 'live', 'fivem'
UmeConfig.Identifier = 'license'

-- Starting money amounts for a brand-new character.
UmeConfig.StartingCash   = 500
UmeConfig.StartingBank   = 2000

-- Default character metadata applied to every new player.
UmeConfig.DefaultJob = {
    name   = 'unemployed',
    label  = 'Unemployed',
    grade  = 0,
    salary = 200,
}

-- Maximum weight the player inventory can hold (grams).
UmeConfig.MaxInventoryWeight = 30000

-- How often (in milliseconds) server-side saves run.
UmeConfig.AutoSaveInterval = 300000   -- 5 minutes

-- Locale / language used for server-side translations.
UmeConfig.Locale = 'en'

-- Default spawn point used for brand-new characters (or when no DB position is saved).
-- Coordinates are in the GTA V world-space. Heading is in degrees (0–360).
UmeConfig.SpawnPoint = {
    x       = -269.4,
    y       = -955.3,
    z       =   31.2,
    heading =  205.0,
}

-- Show the HUD (money, health, armour) overlay by default.
UmeConfig.ShowHud = true

