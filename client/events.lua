-- ============================================================
--  UmeVerse Framework — Client Event Handlers
-- ============================================================

-- ── Player loaded ─────────────────────────────────────────

RegisterNetEvent('umeverse:client:playerLoaded', function(data)
    -- Overwrite the local cache exposed via Ume.Functions.GetPlayerData().
    local pd = Ume.Functions.GetPlayerData()
    -- Clear and re-populate in-place so existing references remain valid.
    for k in pairs(pd) do pd[k] = nil end
    for k, v in pairs(data) do  pd[k] = v  end

    -- Mark the player as loaded via the proper setter exposed in main.lua.
    Ume.Functions.SetPlayerLoaded(true)

    TriggerEvent('umeverse:client:ready', pd)
    UmeUtils.Debug('Player data received:', pd.name)
end)

-- ── Money updates ─────────────────────────────────────────

RegisterNetEvent('umeverse:client:moneyUpdate', function(account, amount)
    local pd = Ume.Functions.GetPlayerData()
    pd[account] = amount
    TriggerEvent('umeverse:client:moneyUpdated', account, amount)
    UmeUtils.Debug('Money update —', account, '=', amount)
end)

-- ── Inventory updates ──────────────────────────────────────

RegisterNetEvent('umeverse:client:inventoryUpdate', function(inventory)
    local pd = Ume.Functions.GetPlayerData()
    pd.inventory = inventory
    TriggerEvent('umeverse:client:inventoryUpdated', inventory)
end)

-- ── Job updates ───────────────────────────────────────────

RegisterNetEvent('umeverse:client:jobUpdate', function(job)
    local pd = Ume.Functions.GetPlayerData()
    pd.job = job
    TriggerEvent('umeverse:client:jobUpdated', job)
    UmeUtils.Debug('Job update —', job.name, 'grade', job.grade)
end)

-- ── Metadata updates ──────────────────────────────────────

RegisterNetEvent('umeverse:client:metadataUpdate', function(key, value)
    local pd = Ume.Functions.GetPlayerData()
    if not pd.metadata then pd.metadata = {} end
    pd.metadata[key] = value
    TriggerEvent('umeverse:client:metadataUpdated', key, value)
end)

-- ── Notifications ─────────────────────────────────────────

RegisterNetEvent('umeverse:client:notify', function(msg, notifType)
    Ume.Functions.Notify(msg, notifType)
end)
