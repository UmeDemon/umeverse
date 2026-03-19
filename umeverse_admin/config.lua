--[[
    Umeverse Admin - Configuration
]]

AdminConfig = {}

AdminConfig.OpenKey = 'F7'     -- Key to open admin panel
AdminConfig.OpenControl = 168  -- FiveM control for F7

-- Permission levels
AdminConfig.Permissions = {
    ['moderator'] = { level = 1, label = 'Moderator' },
    ['admin']     = { level = 2, label = 'Admin' },
    ['superadmin'] = { level = 3, label = 'Super Admin' },
    ['owner']     = { level = 4, label = 'Owner' },
}

-- Minimum permission level for each action
AdminConfig.ActionPermissions = {
    ['view_players']   = 1,
    ['kick']           = 1,
    ['teleport']       = 1,
    ['noclip']         = 1,
    ['revive']         = 1,
    ['godmode']        = 2,
    ['give_money']     = 2,
    ['remove_money']   = 2,
    ['set_job']        = 2,
    ['give_item']      = 2,
    ['ban']            = 2,
    ['heal']           = 1,
    ['spawn_vehicle']  = 2,
    ['despawn_vehicle'] = 2,
    ['invisible']      = 2,
    ['teleport_coords'] = 2,
    ['clear_inventory'] = 3,
    ['announce']       = 2,
    ['set_weather']    = 2,
    ['set_time']       = 2,
    ['unban']          = 3,
}
