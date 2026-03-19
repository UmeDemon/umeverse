-- Notification
RegisterNetEvent('av_laptop:notification', function(title, description, type, position, time)
    if Config.UseLationUI then
        return exports.lation_ui:notify({
            title = title,
            message = description,
            type = type,
            position = position,
            duration = time,
        })
    end
    lib.notify({
        title = title,
        description = description,
        type = type,
        position = position,
        duration = time
    })
end)