--[[
    Umeverse Framework - HUD Client
    Sends player status & vehicle data to NUI,
    native circular minimap with NUI compass overlay, /hudsettings command.
]]

local playerLoaded = false
local showMinimap  = true  -- player preference: show/hide minimap
local minimapSetup = false -- has the minimap been positioned yet?
local minimapScaleform = nil -- minimap scaleform handle

-- ═══════════════════════════════════════
-- Minimap Scaleform
-- ═══════════════════════════════════════

-- Request and store the minimap scaleform handle
local function InitMinimapScaleform()
    minimapScaleform = RequestScaleformMovie("minimap")
    -- Toggle bigmap briefly to force the scaleform to initialise
    SetRadarBigmapEnabled(true, false)
    Wait(0)
    SetRadarBigmapEnabled(false, false)
end

-- Hide the native health/armor arcs on the minimap
-- type 3 = no arcs (GTA Online style minimal)
local function HideMinimapHealthArmor()
    if not minimapScaleform then return end
    BeginScaleformMovieMethod(minimapScaleform, "SETUP_HEALTH_ARMOUR")
    ScaleformMovieMethodAddParamInt(3)
    EndScaleformMovieMethod()
end

-- Hide the native satnav overlay on the minimap
local function HideMinimapSatNav()
    if not minimapScaleform then return end
    BeginScaleformMovieMethod(minimapScaleform, "HIDE_SATNAV")
    EndScaleformMovieMethod()
end

-- Apply the circular minimap position (call once, or when position changes)
local function SetupMinimap(posX, posY, sizeW, sizeH)
    -- Make the minimap circular
    SetMinimapClipType(1)
    -- Map content
    SetMinimapComponentPosition('minimap', 'L', 'B', posX, posY, sizeW, sizeH)
    -- Mask defines the visible clipping area
    SetMinimapComponentPosition('minimap_mask', 'L', 'B', posX + 0.0, posY + 0.013, sizeW, sizeH)
    -- Blur background (slightly larger to avoid edge artifacts)
    SetMinimapComponentPosition('minimap_blur', 'L', 'B', posX - 0.005, posY - 0.005, sizeW + 0.01, sizeH + 0.01)
    minimapSetup = true
end

-- Radar management: per-frame lightweight calls only
CreateThread(function()
    -- Initialise the minimap scaleform on first run
    InitMinimapScaleform()

    while true do
        if playerLoaded and showMinimap then
            DisplayRadar(true)
            SetRadarAsExteriorThisFrame()
            SetRadarBigmapEnabled(false, false)
            -- Hide native overlays (border, area name, vehicle name, street name)
            HideHudComponentThisFrame(6)
            HideHudComponentThisFrame(7)
            HideHudComponentThisFrame(8)
            HideHudComponentThisFrame(9)
            -- Hide weapon wheel
            HideHudComponentThisFrame(19)
            DisableControlAction(0, 37, true) -- INPUT_SELECT_WEAPON (weapon wheel)
            -- Hide north blip
            local nb = GetNorthRadarBlip()
            if nb and nb ~= 0 then SetBlipAlpha(nb, 0) end
            -- Remove native health/armor arcs from minimap via scaleform
            HideMinimapHealthArmor()
            HideMinimapSatNav()
            -- Apply default minimap position if not yet set by NUI sync
            if not minimapSetup then
                SetupMinimap(0.015, 0.025, 0.090, 0.160)
            end
        else
            DisplayRadar(false)
        end
        Wait(0)
    end
end)

-- Wait for player to load before showing HUD
RegisterNetEvent('umeverse:client:playerLoaded', function()
    playerLoaded = true

    -- Restore saved layout / preferences from KVP
    local savedPositions = GetResourceKvpString('umeverse_hud_positions')
    local savedSettings  = GetResourceKvpString('umeverse_hud_settings')

    SendNUIMessage({
        action    = 'init',
        positions = savedPositions and json.decode(savedPositions) or nil,
        settings  = savedSettings  and json.decode(savedSettings)  or nil,
    })

    -- Restore minimap preference from saved settings
    if savedSettings then
        local s = json.decode(savedSettings)
        if s and s.showMinimap ~= nil then
            showMinimap = s.showMinimap
        end
    end
end)

-- ═══════════════════════════════════════
-- Seatbelt state helper
-- ═══════════════════════════════════════
local function IsSeatbeltOn()
    local ok, result = pcall(exports['umeverse_vehicles'].IsSeatbeltOn,
                             exports['umeverse_vehicles'])
    return ok and result or false
end

-- ═══════════════════════════════════════
-- Status update loop (1 s)
-- ═══════════════════════════════════════
CreateThread(function()
    while true do
        Wait(1000)
        if not playerLoaded then goto continue end

        local ped = PlayerPedId()

        if IsEntityDead(ped) then
            SendNUIMessage({ action = 'updateStatus', health = 0, armor = 0, hunger = 0, thirst = 0 })
            goto continue
        end

        local health    = GetEntityHealth(ped) - 100
        local maxHealth = GetEntityMaxHealth(ped) - 100
        if maxHealth <= 0 then maxHealth = 100 end
        local armor = GetPedArmour(ped)

        local hunger = 100.0
        local thirst = 100.0

        local ok, playerData = pcall(exports['umeverse_core'].GetPlayerData,
                                     exports['umeverse_core'])
        if ok and playerData and playerData.status then
            hunger = playerData.status.hunger or 100.0
            thirst = playerData.status.thirst or 100.0
        end

        SendNUIMessage({
            action = 'updateStatus',
            health = math.max(0, math.floor((health / maxHealth) * 100)),
            armor  = math.max(0, math.min(100, armor)),
            hunger = math.max(0, math.min(100, math.floor(hunger))),
            thirst = math.max(0, math.min(100, math.floor(thirst))),
        })
        ::continue::
    end
end)

-- ═══════════════════════════════════════
-- Vehicle data loop (50 ms in vehicle, 500 ms on foot)
-- ═══════════════════════════════════════
CreateThread(function()
    while true do
        if not playerLoaded then Wait(1000) goto continue end

        local ped       = PlayerPedId()
        local inVehicle = IsPedInAnyVehicle(ped, false)

        if inVehicle then
            local veh          = GetVehiclePedIsIn(ped, false)
            local speed        = GetEntitySpeed(veh)              -- m/s
            local rpm          = GetVehicleCurrentRpm(veh)        -- 0.0-1.0
            local gear         = GetVehicleCurrentGear(veh)       -- 0=R, 1-7
            local fuel         = GetVehicleFuelLevel(veh)         -- 0-100
            local engineHealth = GetVehicleEngineHealth(veh)      -- -4000 .. 1000

            SendNUIMessage({
                action       = 'updateVehicle',
                show         = true,
                speed        = speed,
                rpm          = rpm,
                gear         = gear,
                fuel         = math.max(0, math.min(100, fuel)),
                engineHealth = engineHealth,
                seatbelt     = IsSeatbeltOn(),
            })

            Wait(50)
        else
            SendNUIMessage({ action = 'updateVehicle', show = false })
            Wait(500)
        end
        ::continue::
    end
end)

-- ═══════════════════════════════════════
-- Custom minimap data loop (200 ms)
-- Sends heading, street name, zone to NUI
-- ═══════════════════════════════════════
CreateThread(function()
    while true do
        Wait(200)
        if not playerLoaded then goto continue end
        if not showMinimap then goto continue end

        local ped = PlayerPedId()
        local coords  = GetEntityCoords(ped)
        local heading = GetEntityHeading(ped)

        -- Street name
        local streetHash, crossHash = GetStreetNameAtCoord(coords.x, coords.y, coords.z)
        local street = GetStreetNameFromHashKey(streetHash) or ''
        local cross  = ''
        if crossHash and crossHash ~= 0 then
            cross = GetStreetNameFromHashKey(crossHash) or ''
        end

        -- Zone / area
        local zoneHash = GetNameOfZone(coords.x, coords.y, coords.z)
        local zone = GetLabelText(zoneHash)
        if zone == 'NULL' then zone = zoneHash end

        SendNUIMessage({
            action  = 'updateMinimap',
            heading = heading,
            street  = street,
            cross   = cross,
            zone    = zone,
            x       = coords.x,
            y       = coords.y,
        })
        ::continue::
    end
end)

-- ═══════════════════════════════════════
-- /hudsettings command (rebindable)
-- ═══════════════════════════════════════
RegisterCommand('hudsettings', function()
    if not playerLoaded then return end
    SetNuiFocus(true, true)
    SendNUIMessage({ action = 'openSettings' })
end, false)

RegisterKeyMapping('hudsettings', 'Open HUD Settings', 'keyboard', '')

-- ═══════════════════════════════════════
-- NUI Callbacks
-- ═══════════════════════════════════════
RegisterNUICallback('closeSettings', function(_, cb)
    SetNuiFocus(false, false)
    cb('ok')
end)

RegisterNUICallback('savePositions', function(data, cb)
    if data.positions then
        SetResourceKvp('umeverse_hud_positions', json.encode(data.positions))
    end
    cb('ok')
end)

RegisterNUICallback('saveSettings', function(data, cb)
    if data.settings then
        SetResourceKvp('umeverse_hud_settings', json.encode(data.settings))
        if data.settings.showMinimap ~= nil then
            showMinimap = data.settings.showMinimap
        end
    end
    cb('ok')
end)

RegisterNUICallback('setMinimap', function(data, cb)
    if data.show ~= nil then
        showMinimap = data.show
        if not data.show then
            SendNUIMessage({ action = 'updateMinimap', hidden = true })
        end
    end
    cb('ok')
end)

RegisterNUICallback('syncMinimapPosition', function(data, cb)
    if data.left and data.bottom and data.size then
        local sw = data.screenW or 1920
        local sh = data.screenH or 1080
        -- Inset 20% on each side so native map fits inside compass ring (60% of compass size)
        local inset   = data.size * 0.20
        local mapSize = data.size * 0.60

        local posX  = (data.left + inset) / sw
        local posY  = (data.bottom + inset) / sh
        local sizeW = mapSize / sw
        local sizeH = mapSize / sh

        SetupMinimap(posX, posY, sizeW, sizeH)
    end
    cb('ok')
end)

-- ═══════════════════════════════════════
-- External toggle (other resources can hide HUD)
-- ═══════════════════════════════════════
RegisterNetEvent('umeverse:client:toggleHud', function(visible)
    SendNUIMessage({ action = 'toggleHud', visible = visible })
end)
