Config = {}

-- Debug mode - enables console logging
Config.Debug = true

-- Item configurationt/t
Config.Item = {
    Name = "mi_tablet",           -- The item name that triggers the tablet
    RequireItem = true,           -- Whether the player needs the item to use the tablet
}

-- Tablet appearance settings
Config.Tablet = {
    Width = 1024,                 -- Tablet UI width in pixels
    Height = 768,                 -- Tablet UI height in pixels
    Scale = 0.85,                 -- Scale multiplier for the UI
}

-- Prop configuration (for holding animation)
Config.Prop = {
    Model = "prop_cs_tablet",     -- The prop model to use
    Bone = 28422,                 -- Bone to attach prop to (right hand)
    Offset = vector3(0.0, 0.0, 0.0),
    Rotation = vector3(0.0, 0.0, 0.0),
}

-- Animation configuration
Config.Animation = {
    Dict = "amb@world_human_seat_wall_tablet@female@base",
    Anim = "base",
    Flag = 49,                    -- Animation flag (49 = upper body only, loop)
}

-- Key to close the tablet (default: ESC handled in JS, but backup)
Config.CloseKey = 177             -- BACKSPACE / ESC

-- Rep App Configuration
Config.RepAppEnabled = true       -- Enable/disable the rep app
Config.HideCriminalReps = true    -- Hide reps associated with criminal activities
Config.CriminalRepTypes = {       -- List of rep types considered criminal (hidden when HideCriminalReps is true)
    'crime',
    'boosting',
    'wash',
    'illegalfishing',
    'drugs',
    'heist',
    'robbery',
    'theft',
    'hacking',
    'smuggling',
    'carjacking',
    'burglary',
    'fraud',
    'cokeruns',
    'coke',
    'prison',
}
Config.RepNameOverrides = {       -- Override display names for rep types
    ['wash'] = 'Washing',
    ['boosting'] = 'Boosting',
    ['racing'] = 'Racing',
    ['hunting'] = 'Hunting',
    ['fishing'] = 'Fishing',
    ['magnetfishing'] = 'Magnet Fishing',
    ['flubbereats'] = 'Flubber Eats',
}

-- Darkweb/Crime Homepage Restrictions
-- Jobs that cannot access the hidden darkweb homepage
Config.DarkwebRestrictedJobs = {
    'police',
    'ambulance',
    'lspd',
    'bcso',
    'sasp',
    'doc',
    'ems',
    'hospital',
}

-- Apps configuration - apps available on the tablet
-- These can be extended to integrate with LB Phone apps later
Config.Apps = {
    {
        id = "home",
        name = "Home",
        icon = "home",
        enabled = true,
        isSystem = true,          -- System apps can't be hidden
    },
    {
        id = "settings",
        name = "Settings",
        icon = "settings",
        enabled = true,
        isSystem = true,
    },
    {
        id = "rep",
        name = "Rep",
        icon = "terminal",
        enabled = true,
        isSystem = false,
    },
    {
        id = "banking",
        name = "Banking",
        icon = "building-columns",
        enabled = true,
        isSystem = false,
    },
    {
        id = "crypto",
        name = "Crypto Mining",
        icon = "microchip",
        enabled = true,
        isSystem = false,
    },
    {
        id = "admins",
        name = "Admins",
        icon = "user-shield",
        enabled = true,
        isSystem = false,
        requiresPermission = "admin",    -- Only visible to players with admin+ permission
    },
    {
        id = "casino",
        name = "Casino Management",
        icon = "dice",
        enabled = true,
        isSystem = false,
        requiresJob = "casino",         -- Only visible to casino employees
        requiresGrade = 1,              -- Manager/Supervisor only (grade 0-1)
    },
    {
        id = "browser",
        name = "Browser",
        icon = "globe",
        enabled = true,
        isSystem = false,
    },
    {
        id = "notes",
        name = "Notes",
        icon = "sticky-note",
        enabled = true,
        isSystem = false,
    },
    {
        id = "calculator",
        name = "Calculator",
        icon = "calculator",
        enabled = true,
        isSystem = false,
    },
    {
        id = "weather",
        name = "Weather",
        icon = "cloud-sun",
        enabled = true,
        isSystem = false,
    },
    {
        id = "camera",
        name = "Camera",
        icon = "camera",
        enabled = true,
        isSystem = false,
    },
    {
        id = "gallery",
        name = "Gallery",
        icon = "images",
        enabled = true,
        isSystem = false,
    },
    {
        id = "events",
        name = "Events",
        icon = "crown",
        enabled = true,
        isSystem = false,
    },
    {
        id = "maps",
        name = "Maps",
        icon = "map-location-dot",
        enabled = true,
        isSystem = false,
    },
    {
        id = "mechanic",
        name = "Mechanic",
        icon = "wrench",
        enabled = true,
        isSystem = false,
        requiresJobs = {              -- Visible to any of these jobs (add more as needed)
            'fastcustoms',
            'lscustoms',
        },
    },
    {
        id = "bills",
        name = "Bills",
        icon = "file-invoice-dollar",
        enabled = true,
        isSystem = false,
    },
}

-- Wallpaper options
Config.Wallpapers = {
    "default",
    "gradient-blue",
    "gradient-purple",
    "gradient-dark",
    "nature-1",
    "abstract-1",
    "cyber-grid",
    "aurora",
    "nebula",
    "matrix",
    "sunset-city",
    "ocean-depths",
    "fire-ember",
    "hologram",
}

-- Default tablet settings
Config.DefaultSettings = {
    wallpaper = "default",
    customWallpaper = "",             -- Custom URL for wallpaper
    brightness = 100,
    volume = 50,
    notifications = true,
    darkMode = false,
    fontSize = "medium",              -- small, medium, large
}

-- Job restrictions - if empty, everyone can use the tablet
-- Example: Config.JobRestrictions = { "police", "ambulance" }
Config.JobRestrictions = {}

-- Camera Configuration (LB Phone style)
Config.Camera = {
    Enabled = true,                    -- Enable/disable the camera app
    AllowRunning = true,               -- Allow running while in camera mode
    
    -- FOV (Zoom) Settings
    DefaultFOV = 50.0,                 -- Default field of view
    MaxFOV = 80.0,                     -- Zoomed out (wide angle)
    MinFOV = 15.0,                     -- Zoomed in (telephoto)
    ZoomSpeed = 3.0,                   -- Speed of zoom when scrolling
    
    -- Camera Movement
    MaxLookUp = 89.0,                  -- Maximum look up angle
    MaxLookDown = -89.0,               -- Maximum look down angle
    
    -- Selfie Mode
    Selfie = {
        Enabled = true,
        Offset = vector3(0.0, -0.7, 0.6),        -- Camera offset (x=side, y=forward negative=in front, z=up)
        Rotation = vector3(-10.0, 0.0, 0.0),     -- Camera rotation (pitch down, roll, yaw)
        DefaultFOV = 70.0,
        MaxFOV = 90.0,
        MinFOV = 50.0,
    },
    
    -- Image Settings
    Image = {
        Quality = 0.92,                -- JPEG quality (0.0 - 1.0)
        Mime = "image/webp",           -- Image format (image/webp, image/jpeg, image/png)
    },
    
    -- Upload Settings (Fivemanage)
    Upload = {
        Service = "fivemanage",        -- fivemanage, fivemerr, or discord
        ApiKey = "KXPaSR9VDiZl9IAjZ3fJ0nsbTfEKnsNI",  -- Fivemanage API key (same as lb-phone)
        UseLBPhoneKey = false,         -- Disabled since export doesn't work in this version
    },
    
    -- Keybinds (displayed as hints)
    Keybinds = {
        TakePhoto = "ENTER",
        FlipCamera = "F",
        ZoomIn = "SCROLL UP",
        ZoomOut = "SCROLL DOWN",
        Exit = "BACKSPACE",
    },
    
    -- Sound Effects
    Sounds = {
        Shutter = true,                -- Play shutter sound on capture
    },
}

-- Gallery Configuration
Config.Gallery = {
    MaxPhotos = 50,                    -- Maximum photos stored per player
    SaveToDatabase = true,             -- Save photos to database
}

-- Locale strings
Config.Locale = {
    ["tablet_notification"] = "MI Tablet",
    ["tablet_opened"] = "Tablet opened",
    ["tablet_closed"] = "Tablet closed",
    ["no_tablet"] = "You don't have a tablet",
    ["job_restricted"] = "You cannot use this tablet",
    ["photo_saved"] = "Photo saved to gallery",
    ["photo_failed"] = "Failed to save photo",
    ["camera_opened"] = "Camera opened",
    ["camera_closed"] = "Camera closed",
}
