--[[
    Umeverse Framework - Locale System
    Centralized strings for localization
]]

UME.Locale = {}

local Translations = {
    ['en'] = {
        -- General
        ['framework_loaded']         = 'Umeverse Framework has loaded successfully.',
        ['player_loaded']            = 'Welcome to %s!',
        ['player_logout']            = 'You have logged out.',

        -- Money
        ['money_received']           = 'You received $%s.',
        ['money_removed']            = '$%s has been removed.',
        ['money_insufficient']       = 'You don\'t have enough money.',
        ['bank_deposit']             = 'Deposited $%s into your bank account.',
        ['bank_withdraw']            = 'Withdrew $%s from your bank account.',
        ['bank_transfer']            = 'Transferred $%s to %s.',
        ['bank_transfer_received']   = 'You received $%s from %s.',

        -- Jobs
        ['job_joined']               = 'You are now a %s (%s).',
        ['job_duty_on']              = 'You are now on duty.',
        ['job_duty_off']             = 'You are now off duty.',
        ['paycheck_received']        = 'You received your paycheck: $%s.',

        -- Inventory
        ['inventory_full']           = 'Your inventory is full.',
        ['item_received']            = 'Received %sx %s.',
        ['item_removed']             = 'Removed %sx %s.',
        ['item_used']                = 'Used %s.',
        ['item_cannot_carry']        = 'You cannot carry any more of this item.',

        -- Vehicle
        ['vehicle_spawned']          = 'Vehicle spawned.',
        ['vehicle_stored']           = 'Vehicle stored in garage.',
        ['vehicle_not_owned']        = 'You don\'t own this vehicle.',
        ['vehicle_impounded']        = 'Your vehicle has been impounded.',
        ['garage_empty']             = 'You have no vehicles in this garage.',

        -- Death
        ['death_respawn']            = 'You will respawn in %s seconds.',
        ['death_respawned']          = 'You have been taken to the hospital.',
        ['death_bleedout']           = 'You have bled out.',

        -- Admin
        ['admin_no_permission']      = 'You do not have permission to do this.',
        ['admin_player_kicked']      = 'Player %s has been kicked: %s',
        ['admin_player_banned']      = 'Player %s has been banned: %s',
        ['admin_teleported']         = 'Teleported to waypoint.',
        ['admin_noclip_on']          = 'Noclip enabled.',
        ['admin_noclip_off']         = 'Noclip disabled.',
        ['admin_godmode_on']         = 'God mode enabled.',
        ['admin_godmode_off']        = 'God mode disabled.',

        -- Status
        ['status_hungry']            = 'You are getting hungry.',
        ['status_thirsty']           = 'You are getting thirsty.',
        ['status_starving']          = 'You are starving!',
        ['status_dehydrated']        = 'You are dehydrated!',

        -- Multicharacter
        ['char_select']              = 'Select a character or create a new one.',
        ['char_created']             = 'Character created successfully.',
        ['char_deleted']             = 'Character deleted.',
        ['char_slots_full']          = 'You have reached the maximum number of characters.',
    },
}

local currentLocale = 'en'

--- Set the current locale
---@param locale string
function UME.SetLocale(locale)
    if Translations[locale] then
        currentLocale = locale
    else
        UME.Error('Locale "' .. locale .. '" not found, defaulting to "en".')
    end
end

--- Get a translated string with optional format args
---@param key string
---@vararg any
---@return string
function UME.Translate(key, ...)
    local str = Translations[currentLocale] and Translations[currentLocale][key]
    if not str then
        UME.Error('Missing translation key: ' .. key)
        return key
    end
    if ... then
        return string.format(str, ...)
    end
    return str
end

-- Shorthand
_T = UME.Translate
