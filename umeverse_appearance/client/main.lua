--[[
    Umeverse Appearance - Client
    Handles clothing store & barber interactions, appearance camera, NUI communication
]]

local UME = exports['umeverse_core']:GetCoreObject()
local isMenuOpen   = false
local menuType     = 'clothing' -- 'clothing' or 'barber'
local cam          = nil
local originalAppearance = nil

-- ═══════════════════════════════════════
-- Blip Setup
-- ═══════════════════════════════════════

CreateThread(function()
    for _, coords in ipairs(AppearConfig.ClothingStores) do
        local blip = AddBlipForCoord(coords.x, coords.y, coords.z)
        SetBlipSprite(blip, AppearConfig.Blips.clothing.sprite)
        SetBlipDisplay(blip, 4)
        SetBlipScale(blip, AppearConfig.Blips.clothing.scale)
        SetBlipColour(blip, AppearConfig.Blips.clothing.color)
        SetBlipAsShortRange(blip, true)
        BeginTextCommandSetBlipName('STRING')
        AddTextComponentString('Clothing Store')
        EndTextCommandSetBlipName(blip)
    end

    for _, coords in ipairs(AppearConfig.BarberShops) do
        local blip = AddBlipForCoord(coords.x, coords.y, coords.z)
        SetBlipSprite(blip, AppearConfig.Blips.barber.sprite)
        SetBlipDisplay(blip, 4)
        SetBlipScale(blip, AppearConfig.Blips.barber.scale)
        SetBlipColour(blip, AppearConfig.Blips.barber.color)
        SetBlipAsShortRange(blip, true)
        BeginTextCommandSetBlipName('STRING')
        AddTextComponentString('Barber Shop')
        EndTextCommandSetBlipName(blip)
    end
end)

-- ═══════════════════════════════════════
-- Interaction Loop
-- ═══════════════════════════════════════

CreateThread(function()
    while true do
        local sleep = 1000
        if UME.IsLoggedIn() and not UME.IsDead() and not isMenuOpen then
            local myCoords = GetEntityCoords(PlayerPedId())

            -- Clothing stores
            for _, storeCoords in ipairs(AppearConfig.ClothingStores) do
                local dist = #(myCoords - storeCoords)
                if dist < 20.0 then
                    sleep = 0
                    DrawMarker(36, storeCoords.x, storeCoords.y, storeCoords.z - 0.9, 0,0,0, 0,0,0, 0.8,0.8,0.3, 59,130,246,150, false,false, 2, false, nil, nil, false)

                    if dist < AppearConfig.InteractDistance then
                        UME.ShowHelpText('Press ~INPUT_CONTEXT~ to open clothing store')
                        if IsControlJustPressed(0, 38) then
                            OpenAppearanceMenu('clothing')
                        end
                    end
                end
            end

            -- Barber shops
            for _, barberCoords in ipairs(AppearConfig.BarberShops) do
                local dist = #(myCoords - barberCoords)
                if dist < 20.0 then
                    sleep = 0
                    DrawMarker(36, barberCoords.x, barberCoords.y, barberCoords.z - 0.9, 0,0,0, 0,0,0, 0.8,0.8,0.3, 200,100,255,150, false,false, 2, false, nil, nil, false)

                    if dist < AppearConfig.InteractDistance then
                        UME.ShowHelpText('Press ~INPUT_CONTEXT~ to open barber shop')
                        if IsControlJustPressed(0, 38) then
                            OpenAppearanceMenu('barber')
                        end
                    end
                end
            end
        end
        Wait(sleep)
    end
end)

-- ═══════════════════════════════════════
-- Appearance Menu
-- ═══════════════════════════════════════

function OpenAppearanceMenu(type)
    if isMenuOpen then return end
    isMenuOpen = true
    menuType = type

    local ped = PlayerPedId()
    originalAppearance = GetPedAppearance(ped)

    -- Get max drawable/texture counts for NUI sliders
    local maxValues = GetMaxAppearanceValues(ped)

    -- Create camera
    local pedCoords = GetEntityCoords(ped)
    local heading = GetEntityHeading(ped)
    local fwd = GetEntityForwardVector(ped)

    local camCoords = pedCoords + fwd * 1.5 + vector3(0.0, 0.0, 0.3)
    cam = CreateCam('DEFAULT_SCRIPTED_CAMERA', true)
    SetCamCoord(cam, camCoords.x, camCoords.y, camCoords.z)
    PointCamAtCoord(cam, pedCoords.x, pedCoords.y, pedCoords.z + 0.3)
    SetCamFov(cam, AppearConfig.CamFov)
    SetCamActive(cam, true)
    RenderScriptCams(true, true, 500, true, false)

    -- Freeze ped
    FreezeEntityPosition(ped, true)

    SendNUIMessage({
        action     = 'openMenu',
        type       = type,
        appearance = originalAppearance,
        maxValues  = maxValues,
    })
    SetNuiFocus(true, true)
end

function CloseAppearanceMenu(save)
    if not isMenuOpen then return end
    isMenuOpen = false

    -- Destroy camera
    if cam then
        RenderScriptCams(false, true, 500, true, false)
        DestroyCam(cam, false)
        cam = nil
    end

    -- Unfreeze ped
    FreezeEntityPosition(PlayerPedId(), false)

    if not save and originalAppearance then
        SetPedAppearance(PlayerPedId(), originalAppearance)
    end

    SendNUIMessage({ action = 'closeMenu' })
    SetNuiFocus(false, false)
end

-- ═══════════════════════════════════════
-- Get/Set Ped Appearance
-- ═══════════════════════════════════════

function GetPedAppearance(ped)
    local appearance = {
        -- Components (0-11)
        components = {},
        -- Props (0-2, 6-7)
        props = {},
        -- Hair color
        hairColor        = GetPedHairColor(ped),
        hairHighlight    = GetPedHairHighlightColor(ped),
        -- Head overlays (0-12)
        overlays = {},
    }

    -- Drawable components: 0=Head, 1=Mask, 2=Hair, 3=Torso, 4=Legs, 5=Bag, 6=Shoes, 7=Accessory, 8=Undershirt, 9=Kevlar, 10=Badge, 11=Torso2
    for i = 0, 11 do
        appearance.components[i] = {
            drawable = GetPedDrawableVariation(ped, i),
            texture  = GetPedTextureVariation(ped, i),
        }
    end

    -- Props: 0=Hat, 1=Glasses, 2=Ears, 6=Watch, 7=Bracelet
    for _, propId in ipairs({0, 1, 2, 6, 7}) do
        appearance.props[propId] = {
            drawable = GetPedPropIndex(ped, propId),
            texture  = GetPedPropTextureIndex(ped, propId),
        }
    end

    -- Head overlays: 0=Blemishes, 1=Beard, 2=Eyebrows, 3=Ageing, 4=Makeup, 5=Blush, 6=Complexion, 7=SunDamage, 8=Lipstick, 9=MolesFreckles, 10=ChestHair, 11=BodyBlemishes, 12=AddBodyBlemishes
    for i = 0, 12 do
        local success, overlayValue, colourType, firstColor, secondColor, overlayOpacity = GetPedHeadOverlayData(ped, i)
        appearance.overlays[i] = {
            value   = overlayValue,
            opacity = overlayOpacity and overlayOpacity + 0.0 or 1.0,
            color   = firstColor or 0,
        }
    end

    return appearance
end

function SetPedAppearance(ped, appearance)
    if not appearance then return end

    -- Components
    if appearance.components then
        for i = 0, 11 do
            local comp = appearance.components[i]
            if comp then
                SetPedComponentVariation(ped, i, comp.drawable or 0, comp.texture or 0, 0)
            end
        end
    end

    -- Props
    if appearance.props then
        for _, propId in ipairs({0, 1, 2, 6, 7}) do
            local prop = appearance.props[propId]
            if prop then
                if prop.drawable == -1 then
                    ClearPedProp(ped, propId)
                else
                    SetPedPropIndex(ped, propId, prop.drawable or 0, prop.texture or 0, true)
                end
            end
        end
    end

    -- Hair color
    if appearance.hairColor then
        SetPedHairColor(ped, appearance.hairColor, appearance.hairHighlight or 0)
    end

    -- Overlays
    if appearance.overlays then
        for i = 0, 12 do
            local overlay = appearance.overlays[i]
            if overlay then
                SetPedHeadOverlay(ped, i, overlay.value or 0, overlay.opacity or 1.0)
                -- Color for certain overlays
                if i == 1 or i == 2 or i == 10 then
                    -- Hair-colored overlays (beard, eyebrows, chest hair)
                    SetPedHeadOverlayColor(ped, i, 1, overlay.color or 0, 0)
                elseif i == 4 or i == 5 or i == 8 then
                    -- Makeup/blush/lipstick
                    SetPedHeadOverlayColor(ped, i, 2, overlay.color or 0, 0)
                end
            end
        end
    end
end

function GetMaxAppearanceValues(ped)
    local maxValues = {
        components = {},
        props = {},
    }

    for i = 0, 11 do
        maxValues.components[i] = {
            maxDrawable = GetNumberOfPedDrawableVariations(ped, i) - 1,
            maxTexture  = GetNumberOfPedTextureVariations(ped, i, GetPedDrawableVariation(ped, i)) - 1,
        }
    end

    for _, propId in ipairs({0, 1, 2, 6, 7}) do
        maxValues.props[propId] = {
            maxDrawable = GetNumberOfPedPropDrawableVariations(ped, propId) - 1,
            maxTexture  = GetNumberOfPedPropTextureVariations(ped, propId, GetPedPropIndex(ped, propId)) - 1,
        }
    end

    return maxValues
end

-- ═══════════════════════════════════════
-- NUI Callbacks
-- ═══════════════════════════════════════

RegisterNUICallback('updateComponent', function(data, cb)
    local ped = PlayerPedId()
    local componentId = tonumber(data.componentId)
    local drawable    = tonumber(data.drawable) or 0
    local texture     = tonumber(data.texture) or 0

    SetPedComponentVariation(ped, componentId, drawable, texture, 0)

    -- Return new max texture for this drawable
    local maxTexture = GetNumberOfPedTextureVariations(ped, componentId, drawable) - 1
    cb({ maxTexture = maxTexture })
end)

RegisterNUICallback('updateProp', function(data, cb)
    local ped = PlayerPedId()
    local propId   = tonumber(data.propId)
    local drawable = tonumber(data.drawable) or -1
    local texture  = tonumber(data.texture) or 0

    if drawable < 0 then
        ClearPedProp(ped, propId)
    else
        SetPedPropIndex(ped, propId, drawable, texture, true)
    end

    local maxTexture = GetNumberOfPedPropTextureVariations(ped, propId, math.max(0, drawable)) - 1
    cb({ maxTexture = maxTexture })
end)

RegisterNUICallback('updateOverlay', function(data, cb)
    local ped = PlayerPedId()
    local overlayId = tonumber(data.overlayId)
    local value     = tonumber(data.value) or 0
    local opacity   = tonumber(data.opacity) or 1.0
    local color     = tonumber(data.color) or 0

    SetPedHeadOverlay(ped, overlayId, value, opacity)

    if overlayId == 1 or overlayId == 2 or overlayId == 10 then
        SetPedHeadOverlayColor(ped, overlayId, 1, color, 0)
    elseif overlayId == 4 or overlayId == 5 or overlayId == 8 then
        SetPedHeadOverlayColor(ped, overlayId, 2, color, 0)
    end

    cb('ok')
end)

RegisterNUICallback('updateHairColor', function(data, cb)
    local ped = PlayerPedId()
    SetPedHairColor(ped, tonumber(data.color) or 0, tonumber(data.highlight) or 0)
    cb('ok')
end)

RegisterNUICallback('rotatePed', function(data, cb)
    local ped = PlayerPedId()
    local heading = GetEntityHeading(ped) + (tonumber(data.angle) or 0)
    SetEntityHeading(ped, heading)
    cb('ok')
end)

RegisterNUICallback('saveAppearance', function(_, cb)
    local ped = PlayerPedId()
    local appearance = GetPedAppearance(ped)

    TriggerServerEvent('umeverse_appearance:server:saveAppearance', appearance)
    CloseAppearanceMenu(true)
    cb('ok')
end)

RegisterNUICallback('cancelAppearance', function(_, cb)
    CloseAppearanceMenu(false)
    cb('ok')
end)

-- ═══════════════════════════════════════
-- Apply saved appearance on spawn
-- ═══════════════════════════════════════

RegisterNetEvent('umeverse:client:playerLoaded:done', function()
    Wait(1000)
    UME.TriggerServerCallback('umeverse_appearance:getAppearance', function(appearance)
        if appearance and next(appearance) then
            SetPedAppearance(PlayerPedId(), appearance)
        end
    end)
end)
