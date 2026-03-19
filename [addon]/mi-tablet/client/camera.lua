-- MI Tablet Camera System
-- LB Phone-style camera with screenshot capture

local TMC = exports['umeverse_core']:GetCoreObject()

-- Camera State
local CameraState = {
    isActive = false,
    isSelfie = false,
    camera = nil,
    currentFOV = Config.Camera.DefaultFOV,
    rotation = vector3(0.0, 0.0, 0.0),
    originalCoords = nil,
    cameraCoords = nil, -- Track camera position for player look-at
    selfieHeading = 0.0, -- Store initial heading for selfie camera
    headLookPos = nil, -- Store head position for camera to look at
    selfieAdjust = { x = 0.0, y = 0.0, z = 0.0 }, -- Fine-tune offset adjustments
    headingAdjust = 0.0, -- Rotation around the player (orbit)
}

-- Debug print helper
local function debugPrint(...)
    if Config.Debug then
        print("[MI Tablet Camera]", ...)
    end
end

-- Get camera API key
local function getCameraApiKey()
    -- First try to use LB Phone's key if enabled
    if Config.Camera.Upload.UseLBPhoneKey then
        local success, key = pcall(function()
            return exports['lb-phone']:GetImageApiKey()
        end)
        if success and key and key ~= "" then
            debugPrint("Using LB Phone API key:", string.sub(key, 1, 10) .. "...")
            return key
        else
            debugPrint("LB Phone API key not available, success:", success, "key:", key)
        end
    end
    
    -- Fall back to configured key
    local configKey = Config.Camera.Upload.ApiKey
    debugPrint("Using config API key:", configKey and string.len(configKey) > 0 and (string.sub(configKey, 1, 10) .. "...") or "EMPTY")
    return configKey
end

-- Disable controls during camera mode
local function disableCameraControls()
    -- Disable attack controls
    DisableControlAction(0, 24, true)   -- Attack
    DisableControlAction(0, 25, true)   -- Aim
    DisableControlAction(0, 47, true)   -- Weapon
    DisableControlAction(0, 58, true)   -- Weapon
    DisableControlAction(0, 263, true)  -- Melee
    DisableControlAction(0, 264, true)  -- Melee
    DisableControlAction(0, 257, true)  -- Melee
    DisableControlAction(0, 140, true)  -- Melee
    DisableControlAction(0, 141, true)  -- Melee
    DisableControlAction(0, 142, true)  -- Melee
    DisableControlAction(0, 143, true)  -- Melee
    
    -- Disable phone/tablet
    DisableControlAction(0, 27, true)   -- Phone
    DisableControlAction(0, 199, true)  -- Pause Menu
    
    -- Disable arrow keys default actions (for selfie adjustment)
    DisableControlAction(0, 172, true)  -- Up Arrow
    DisableControlAction(0, 173, true)  -- Down Arrow
    DisableControlAction(0, 174, true)  -- Left Arrow
    DisableControlAction(0, 175, true)  -- Right Arrow
    
    -- Disable sprint (Shift is used for rotation modifier)
    DisableControlAction(0, 21, true)   -- Sprint
end

-- Create the camera
local function createCamera()
    local ped = PlayerPedId()
    
    if CameraState.isSelfie then
        -- Selfie camera - in front of player facing them (LB Phone style)
        CameraState.camera = CreateCam("DEFAULT_SCRIPTED_CAMERA", true)
        local offset = Config.Camera.Selfie.Offset
        local rotation = Config.Camera.Selfie.Rotation
        local pedHeading = GetEntityHeading(ped)
        
        -- Turn player 180 degrees to face the camera
        local newHeading = (pedHeading + 180.0) % 360.0
        SetEntityHeading(ped, newHeading)
        
        -- Use GTA native to get proper world coords relative to player's NEW facing direction
        local camPos = GetOffsetFromEntityInWorldCoords(ped, offset.x, offset.y, offset.z)
        
        -- Store initial heading (the new heading after turning) so camera angle stays fixed as player moves
        CameraState.selfieHeading = newHeading
        CameraState.cameraCoords = camPos
        
        -- Set camera position and rotation
        SetCamCoord(CameraState.camera, camPos.x, camPos.y, camPos.z)
        -- Rotation: pitch (look down at face), roll, yaw (same direction as player is now facing)
        SetCamRot(CameraState.camera, rotation.x, rotation.y, newHeading + rotation.z, 2)
        SetCamFov(CameraState.camera, Config.Camera.Selfie.DefaultFOV)
        CameraState.currentFOV = Config.Camera.Selfie.DefaultFOV
        
        -- Make player look directly at the camera
        ClearPedTasks(ped)
        TaskLookAtCoord(ped, camPos.x, camPos.y, camPos.z, -1, 2048, 2)
    else
        -- Normal camera - first person POV (camera comes out of player's eyes)
        CameraState.camera = CreateCam("DEFAULT_SCRIPTED_CAMERA", true)
        local pedCoords = GetEntityCoords(ped)
        local pedHeading = GetEntityHeading(ped)
        
        -- Get forward vector to position camera in front of head
        local headBone = GetPedBoneIndex(ped, 31086) -- SKEL_Head
        local headPos = GetPedBoneCoords(ped, headBone, 0.0, 0.0, 0.0)
        local rad = math.rad(pedHeading)
        
        -- Position camera slightly forward from head position
        local camX = headPos.x + (0.3 * math.sin(rad))
        local camY = headPos.y + (0.3 * math.cos(rad))
        local camZ = headPos.z + 0.1
        
        SetCamCoord(CameraState.camera, camX, camY, camZ)
        SetCamRot(CameraState.camera, 0.0, 0.0, pedHeading, 2)
        SetCamFov(CameraState.camera, Config.Camera.DefaultFOV)
        CameraState.currentFOV = Config.Camera.DefaultFOV
        CameraState.rotation = vector3(0.0, 0.0, pedHeading)
    end
    
    -- Hide player in first person mode to avoid head clipping
    if not CameraState.isSelfie then
        SetEntityAlpha(ped, 0, false)
        SetEntityVisible(ped, false, false)
    else
        SetEntityAlpha(ped, 255, false)
        SetEntityVisible(ped, true, false)
    end
    
    RenderScriptCams(true, true, 500, true, true)
    debugPrint("Camera created, selfie:", CameraState.isSelfie)
end

-- Destroy the camera
local function destroyCamera()
    if CameraState.camera then
        RenderScriptCams(false, true, 500, true, true)
        DestroyCam(CameraState.camera, false)
        CameraState.camera = nil
    end
    
    -- Restore player visibility and clear look-at task
    local ped = PlayerPedId()
    SetEntityAlpha(ped, 255, false)
    SetEntityVisible(ped, true, false)
    ClearPedTasks(ped) -- Clear the look-at task
    CameraState.cameraCoords = nil
    
    debugPrint("Camera destroyed")
end

-- Toggle selfie mode
local function toggleSelfieMode()
    CameraState.isSelfie = not CameraState.isSelfie
    destroyCamera()
    createCamera()
    
    -- Notify NUI
    SendNUIMessage({
        type = "cameraUpdate",
        isSelfie = CameraState.isSelfie
    })
    
    debugPrint("Selfie mode toggled:", CameraState.isSelfie)
end

-- Handle camera rotation input
local function handleCameraRotation()
    if not CameraState.camera or CameraState.isSelfie then return end
    
    local rightAxisX = GetDisabledControlNormal(0, 220) -- Mouse X
    local rightAxisY = GetDisabledControlNormal(0, 221) -- Mouse Y
    
    local sensitivity = 5.0
    
    CameraState.rotation = vector3(
        math.max(Config.Camera.MaxLookDown, math.min(Config.Camera.MaxLookUp, CameraState.rotation.x - (rightAxisY * sensitivity))),
        0.0,
        CameraState.rotation.z - (rightAxisX * sensitivity)
    )
    
    SetCamRot(CameraState.camera, CameraState.rotation.x, CameraState.rotation.y, CameraState.rotation.z, 2)
end

-- Handle zoom input
local function handleZoom()
    if not CameraState.camera then return end
    
    local minFOV, maxFOV
    if CameraState.isSelfie then
        minFOV = Config.Camera.Selfie.MinFOV
        maxFOV = Config.Camera.Selfie.MaxFOV
    else
        minFOV = Config.Camera.MinFOV
        maxFOV = Config.Camera.MaxFOV
    end
    
    -- Scroll wheel zoom
    if IsDisabledControlPressed(0, 241) then -- Scroll Up
        CameraState.currentFOV = math.max(minFOV, CameraState.currentFOV - Config.Camera.ZoomSpeed)
    elseif IsDisabledControlPressed(0, 242) then -- Scroll Down
        CameraState.currentFOV = math.min(maxFOV, CameraState.currentFOV + Config.Camera.ZoomSpeed)
    end
    
    SetCamFov(CameraState.camera, CameraState.currentFOV)
end

-- Handle player movement in camera mode
local function handleMovement()
    local ped = PlayerPedId()
    
    -- Allow limited movement
    if Config.Camera.AllowRunning then
        -- Let player move normally
    else
        -- Slow walk only
        SetPedMoveRateOverride(ped, 0.5)
    end
end

-- Handle selfie camera fine-tuning with arrow keys
local function handleSelfieAdjustment()
    if not CameraState.isSelfie or not CameraState.camera then return end
    
    local adjustSpeed = 0.01 -- How fast to adjust position per frame
    local rotateSpeed = 0.5  -- How fast to rotate around player (degrees per frame)
    local isShiftHeld = IsDisabledControlPressed(0, 21) -- Left Shift
    
    if isShiftHeld then
        -- Shift + Left/Right = Rotate camera around the player
        if IsDisabledControlPressed(0, 174) then -- Left Arrow
            CameraState.headingAdjust = CameraState.headingAdjust + rotateSpeed
        end
        
        if IsDisabledControlPressed(0, 175) then -- Right Arrow
            CameraState.headingAdjust = CameraState.headingAdjust - rotateSpeed
        end
    else
        -- Normal arrow keys = Move camera position
        -- Up Arrow - move camera up
        if IsDisabledControlPressed(0, 172) then
            CameraState.selfieAdjust.z = CameraState.selfieAdjust.z + adjustSpeed
        end
        
        -- Down Arrow - move camera down
        if IsDisabledControlPressed(0, 173) then
            CameraState.selfieAdjust.z = CameraState.selfieAdjust.z - adjustSpeed
        end
        
        -- Left Arrow - move camera left
        if IsDisabledControlPressed(0, 174) then
            CameraState.selfieAdjust.x = CameraState.selfieAdjust.x - adjustSpeed
        end
        
        -- Right Arrow - move camera right
        if IsDisabledControlPressed(0, 175) then
            CameraState.selfieAdjust.x = CameraState.selfieAdjust.x + adjustSpeed
        end
    end
end

-- Update selfie camera - keep camera at fixed distance from player, facing them
local function updateSelfieCamera()
    if not CameraState.isSelfie or not CameraState.camera then return end
    
    local ped = PlayerPedId()
    local offset = Config.Camera.Selfie.Offset
    local rotation = Config.Camera.Selfie.Rotation
    local adjust = CameraState.selfieAdjust
    
    -- Apply fine-tune adjustments to offset
    local adjustedOffset = vector3(
        offset.x + adjust.x,
        offset.y + adjust.y,
        offset.z + adjust.z
    )
    
    -- Get current player position
    local pedCoords = GetEntityCoords(ped)
    
    -- Calculate the heading difference to rotate the offset correctly
    -- Include the manual heading adjustment for orbiting
    local currentHeading = GetEntityHeading(ped)
    local effectiveHeading = CameraState.selfieHeading + CameraState.headingAdjust
    local headingDiff = effectiveHeading - currentHeading
    local rad = math.rad(headingDiff)
    
    -- Get base offset from current player position/heading (with adjustments)
    local baseOffset = GetOffsetFromEntityInWorldCoords(ped, adjustedOffset.x, adjustedOffset.y, adjustedOffset.z)
    
    -- Now rotate this offset around the player by the heading difference
    -- to keep camera at the original angle relative to world (plus orbit adjustment)
    local dx = baseOffset.x - pedCoords.x
    local dy = baseOffset.y - pedCoords.y
    
    local rotatedX = pedCoords.x + (dx * math.cos(rad)) - (dy * math.sin(rad))
    local rotatedY = pedCoords.y + (dx * math.sin(rad)) + (dy * math.cos(rad))
    
    local camPos = vector3(rotatedX, rotatedY, baseOffset.z)
    
    -- Update camera position to follow player at fixed distance and angle
    SetCamCoord(CameraState.camera, camPos.x, camPos.y, camPos.z)
    -- Keep rotation fixed based on initial heading (plus orbit adjustment)
    SetCamRot(CameraState.camera, rotation.x, rotation.y, effectiveHeading + rotation.z, 2)
    
    -- Update stored coords for player look-at
    CameraState.cameraCoords = camPos
    
    -- Keep player looking directly at camera
    TaskLookAtCoord(ped, camPos.x, camPos.y, camPos.z, 50, 2048, 2)
end

-- Enter camera mode
function EnterCameraMode(selfie)
    if CameraState.isActive then return end
    
    local ped = PlayerPedId()
    CameraState.isActive = true
    CameraState.isSelfie = selfie or false
    CameraState.originalCoords = GetEntityCoords(ped)
    CameraState.selfieAdjust = { x = 0.0, y = 0.0, z = 0.0 } -- Reset position adjustments
    CameraState.headingAdjust = 0.0 -- Reset rotation adjustment
    
    -- Hide HUD
    DisplayRadar(false)
    
    -- Create camera
    createCamera()
    
    -- Send to NUI to show camera overlay
    SendNUIMessage({
        type = "enterCameraMode",
        isSelfie = CameraState.isSelfie,
        keybinds = Config.Camera.Keybinds,
    })
    
    -- Don't set NUI focus - we want game controls to work
    -- SetNuiFocus is not needed since we're using game input
    
    debugPrint("Entered camera mode")
    
    -- Main camera loop
    CreateThread(function()
        while CameraState.isActive do
            Wait(0)
            
            disableCameraControls()
            handleCameraRotation()
            handleZoom()
            handleMovement()
            handleSelfieAdjustment()
            updateSelfieCamera()
            
            -- Hide HUD components
            HideHudAndRadarThisFrame()
            
            -- Handle inputs - use regular control checks (not disabled)
            -- Take photo - ENTER
            if IsControlJustPressed(0, 191) or IsDisabledControlJustPressed(0, 191) then
                TakePhoto()
            end
            
            -- Flip camera - F
            if IsControlJustPressed(0, 23) or IsDisabledControlJustPressed(0, 23) then
                toggleSelfieMode()
            end
            
            -- Exit camera - BACKSPACE or ESC
            if IsControlJustPressed(0, 177) or IsDisabledControlJustPressed(0, 177) or IsControlJustPressed(0, 200) then
                ExitCameraMode()
            end
        end
    end)
end

-- Exit camera mode
function ExitCameraMode()
    if not CameraState.isActive then return end
    
    CameraState.isActive = false
    
    -- Destroy camera
    destroyCamera()
    
    -- Restore HUD
    DisplayRadar(true)
    
    -- Reset movement
    local ped = PlayerPedId()
    SetPedMoveRateOverride(ped, 1.0)
    
    -- Tell NUI to exit camera mode
    SendNUIMessage({
        type = "exitCameraMode"
    })
    
    debugPrint("Exited camera mode")
    
    -- Small delay then reopen tablet
    Wait(300)
    TriggerEvent('mi-tablet:client:openTablet')
end

-- Take a photo
function TakePhoto()
    if not CameraState.isActive then return end
    
    debugPrint("Taking photo...")
    
    -- Play shutter sound
    if Config.Camera.Sounds.Shutter then
        PlaySoundFrontend(-1, "Camera_Shoot", "Phone_Soundset_Michael", false)
    end
    
    -- Flash effect
    SendNUIMessage({
        type = "cameraFlash"
    })
    
    -- Request NUI to capture screenshot
    SendNUIMessage({
        type = "capturePhoto",
        quality = Config.Camera.Image.Quality,
        mime = Config.Camera.Image.Mime,
    })
end

-- NUI Callback: Receive captured photo
RegisterNUICallback('photoCaptured', function(data, cb)
    local imageData = data.imageData
    
    if imageData then
        debugPrint("Photo captured, uploading...")
        
        -- Send to server for upload
        TriggerServerEvent('mi-tablet:server:uploadPhoto', imageData)
    else
        debugPrint("Failed to capture photo")
    end
    
    cb('ok')
end)

-- NUI Callback: Open camera from app
RegisterNUICallback('openCameraMode', function(data, cb)
    local selfie = data.selfie or false
    
    -- Respond immediately to prevent NUI timeout
    cb('ok')
    
    -- Close tablet UI first
    SetNuiFocus(false, false)
    SendNUIMessage({ type = "close" })
    
    Wait(100)
    
    -- Enter camera mode
    EnterCameraMode(selfie)
end)

-- NUI Callback: Close camera mode
RegisterNUICallback('closeCameraMode', function(data, cb)
    ExitCameraMode()
    cb('ok')
end)

-- Cached camera config from server
local CachedCameraConfig = nil

-- Function to fetch camera config from server
local function fetchCameraConfig()
    TMC.Functions.TriggerServerCallback('mi-tablet:server:getCameraConfig', function(config)
        if config then
            CachedCameraConfig = config
            debugPrint("Camera config cached from server, API key length:", config.apiKey and string.len(config.apiKey) or 0)
        end
    end)
end

-- Fetch config on resource start
CreateThread(function()
    Wait(1000) -- Wait for server to be ready
    fetchCameraConfig()
end)

-- NUI Callback: Get camera config for uploads (returns cached config immediately)
RegisterNUICallback('getCameraConfig', function(data, cb)
    -- If we don't have cached config, trigger a fetch for next time
    if not CachedCameraConfig then
        fetchCameraConfig()
        -- Return default config with empty key for now
        cb({
            apiKey = "",
            service = Config.Camera.Upload.Service,
            quality = Config.Camera.Image.Quality,
            mime = Config.Camera.Image.Mime
        })
    else
        cb(CachedCameraConfig)
    end
end)

-- NUI Callback: Photo uploaded to external service
RegisterNUICallback('photoUploaded', function(data, cb)
    local photoUrl = data.url
    
    if photoUrl then
        debugPrint("Photo uploaded to service:", photoUrl)
        -- Tell server to save the URL
        TriggerServerEvent('mi-tablet:server:savePhotoUrl', photoUrl)
    end
    
    cb('ok')
end)

-- Event: Photo uploaded successfully
RegisterNetEvent('mi-tablet:client:photoUploaded', function(photoUrl)
    debugPrint("Photo uploaded:", photoUrl)
    
    -- Add to gallery
    SendNUIMessage({
        type = "photoAdded",
        url = photoUrl
    })
    
    -- Show notification
    TMC.Functions.Notify({ message = Config.Locale["photo_saved"] or "Photo saved!", notifType = "success" })
end)

-- Event: Photo upload failed
RegisterNetEvent('mi-tablet:client:photoFailed', function(error)
    debugPrint("Photo upload failed:", error)
    TMC.Functions.Notify({ message = Config.Locale["photo_failed"] or "Failed to save photo", notifType = "error" })
end)

-- Fetch player's gallery photos
RegisterNUICallback('fetchGalleryPhotos', function(data, cb)
    TMC.Functions.TriggerServerCallback('mi-tablet:server:getGalleryPhotos', function(photos)
        cb({ photos = photos or {} })
    end)
end)

-- Delete a photo from gallery
RegisterNUICallback('deleteGalleryPhoto', function(data, cb)
    local photoId = data.photoId
    
    TMC.Functions.TriggerServerCallback('mi-tablet:server:deletePhoto', function(success)
        cb({ success = success })
    end, photoId)
end)

debugPrint("Camera module loaded")
