--[[
    Umeverse Bridge - ESX Shared
    Initializes the ESX global object used by both server and client
]]

ESX = {}
ESX.PlayerData = {}
ESX.PlayerLoaded = false

-- Shared config values ESX scripts might check
ESX.Locale = function(str, ...)
    if str then return str:format(...) end
    return ''
end

-- Enable new-style ESX usage
ESX.SecureHashAlgorithm = 'sha512'
ESX.DefaultLocale = 'en'
