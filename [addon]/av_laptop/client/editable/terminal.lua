RegisterNUICallback("external", function(data,cb)
    local command = data and data['command']
    local args = data and data['args']
    dbug("externalMinigame(command, args?)", command, args and json.encode(args) or "none")
    local result = false
    if command == "atm-crack" then
        -- EXAMPLE with av_alphabet:
        -- result = exports['av_alphabet']:start("left", 7, 6)
    end
    cb(result)
end)

-- Handshake success: Minigame/Process resolved correctly
RegisterNUICallback('success', function(data,cb)
    local command = data and data['command']
    local args = data and data['args']
    dbug("Command triggered successfully (command,args)", command, args and json.encode(args) or "none")
    local isAllowed = lib.callback.await('av_laptop:verifyPlayerCommand', false, command, args)
    dbug("Was player allowed to run this command?", isAllowed and "yes" or "no")
    if isAllowed then
        -- if player isAllowed and you didn't triggered anything server side, you can still trigger something client side here:
        if command == "atm-crack" then
            
        end
    end
    cb("ok")
end)

-- Handshake failure: Minigame was failed or user cancelled the process
RegisterNUICallback("failed", function(data,cb)
    local command = data and data['command']
    local args = data and data['args']
    dbug("Command failed to complete (command, args)", command, args and json.encode(args) or "none")
    SendNUIMessage({
        action = "terminal",
        data = {
            type = "error",
            message = "DECRYPT_FAIL: System lockdown triggered."
        }
    })
    cb("ok")
end)