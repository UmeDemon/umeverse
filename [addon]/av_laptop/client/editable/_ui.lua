-- Just in case u want to change the ox_lib text ui to a different one
function showTextUI(text, data) -- I personally don't use the options from ox_lib
    if Config.UIlib == "lation_ui" then
        local keybind, msg = parseInputText(text)
        return exports.lation_ui:showText({
            title = data and data['title'] or nil,
            description = msg,
            keybind = data and data['keybind'] or keybind,
            icon = data and data['icon'] or nil,
            options = data and data['options'] or nil
        })
    end
    lib.showTextUI(text, data)
end

function hideTextUI()
    if Config.UIlib == "lation_ui" then
        exports.lation_ui:hideText()
    else
        lib.hideTextUI()
    end
end

function isTextUIOpen()
    if Config.UIlib == "lation_ui" then
        return exports.lation_ui:isOpen()
    end
    return lib.isTextUIOpen()
end

function alertDialog(data)
    if Config.UIlib == "lation_ui" then
        return exports.lation_ui:alert(data)
    end
    return lib.alertDialog(data)
end

function inputDialog(label, options, extra)
    if Config.UIlib == "lation_ui" then
        return exports.lation_ui:input({
            title = label,
            subtitle = extra and extra['subtitle'] or nil,
            submitText = extra and extra['submitText'] or nil,
            options = options
        })
    end
    return lib.inputDialog(label, options)
end

function progressBar(data)
    return exports[Config.UIlib]:progressBar({
        label = data.label,
        description = data.description,
        duration = data.duration,
        icon = data.icon,
        canCancel = data.canCancel ,
        iconColor = data.iconColor,
        color = data.color,
        useWhileDead = data.useWhileDead,
        disable = data.disable or {},
        anim = data.anim or {},
        prop = data.prop or {},
        steps = data.steps or nil
    })
end

function progressCircle(data)
    if Config.UIlib == "lation_ui" then
        return progressBar(data)
    else
        return lib.progressCircle({
            label = data.label,
            description = data.description,
            duration = data.duration,
            icon = data.icon,
            canCancel = data.canCancel ,
            iconColor = data.iconColor,
            color = data.color,
            useWhileDead = data.useWhileDead,
            disable = data.disable or {},
            anim = data.anim or {},
            prop = data.prop or {},
            steps = data.steps or nil,
            position = data.position or "bottom"
        })
    end
end

function registerContext(data)
    if Config.UIlib == "lation_ui" then
        return exports.lation_ui:registerMenu(data)
    end
    lib.registerContext(data)
end

function showContext(name)
    if Config.UIlib == "lation_ui" then
        return exports.lation_ui:showMenu(name)
    end
    lib.showContext(name)
end

function hideContext()
    if Config.UIlib == "lation_ui" then
        return exports.lation_ui:hideMenu()
    end
    lib.hideContext()
end

exports("showTextUI", showTextUI)
exports("hideTextUI", hideTextUI)
exports("isTextUIOpen", isTextUIOpen)
exports("alertDialog", alertDialog)
exports("inputDialog", inputDialog)
exports("progressBar", progressBar)
exports("registerContext", registerContext)
exports("showContext", showContext)
exports("hideContext", hideContext)
exports("progressCircle", progressCircle)
exports('getUI', function()
    return Config.UIlib or "ox_lib"
end)