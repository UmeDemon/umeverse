AddEventHandler('av_weather:timeUpdated', function(hour,minutes)
    if LocalPlayer.state.inLaptop and Config.UseGameClock then
        SendNUIMessage({
            action = "clock",
            data = {
                enabled = true,
                hour = hour,
                minutes = minutes
            }
        })
    end
end)