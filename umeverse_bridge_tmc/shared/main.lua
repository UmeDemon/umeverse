--[[
    Umeverse Bridge - TMC Shared
    Initializes the TMC global object used by both server and client
    Also sets up QBCore/QBShared/QBConfig aliases since TMC scripts use both
]]

TMC = {}
TMC.Players = {}
TMC.QueuedPlayers = {}
TMC.Config = {}
TMC.Shared = {}
TMC.Common = {}
TMC.Functions = {}
TMC.EnabledResources = {}
TMC.LoadingFinished = true
TMC.GameType = 'gta5'
TMC.IsGTA5 = true
TMC.IsRDR3 = false

-- Aliases TMC scripts expect
TMCConfig = {}
TMCShared = {}

-- TMC config mapping from Umeverse config
local coreConfig = rawget(_G, 'UmeConfig')

do
    TMCConfig.MaxPlayers = (coreConfig and coreConfig.MaxPlayers) or GetConvarInt('sv_maxclients', 64)
    TMCConfig.IdentifierType = (coreConfig and coreConfig.IdentifierType) or 'license'
    TMCConfig.DefaultSpawn = (coreConfig and coreConfig.DefaultSpawn) and { x = coreConfig.DefaultSpawn.x, y = coreConfig.DefaultSpawn.y, z = coreConfig.DefaultSpawn.z, w = coreConfig.DefaultSpawn.w } or { x = 0.0, y = 0.0, z = 0.0, w = 0.0 }
    TMCConfig.UseGlobalOoc = false
    TMCConfig.EnableJoinLeaveMessages = false
    TMCConfig.EnableDefaultChat = false

    TMCConfig.Currency = { Code = 'USD', Symbol = '$', HtmlSymbols = { ['$'] = '&dollar;', ['£'] = '&pound;', ['€'] = '&euro;' } }
    TMCConfig.Money = { MoneyTypes = { cash = 500 }, DontAllowMinus = { 'cash' } }
    TMCConfig.Player = { MaxWeight = 30000, MaxInvSlots = 50, DropOnMax = true }
    TMCConfig.Game = {}
    TMCConfig.Server = {
        closed = false,
        closedReason = '',
        uptime = 0,
        whitelist = false,
        discord = '',
        PermissionList = {},
        Timezone = 'US/Eastern',
        LatentBps = 75000,
        PermissionRanking = {
            [1] = 'user',
            [2] = 'helper',
            [3] = 'dev',
            [4] = 'mod',
            [5] = 'admin',
            [6] = 'senioradmin',
            [7] = 'god',
        },
        VoiceResource = 'pma-voice',
    }
end

TMC.Config = TMCConfig

-- TMCShared data mapping
TMCShared.Items = {}
TMCShared.Weapons = {}
TMCShared.Jobs = {}
TMCShared.RepJobs = {}
TMCShared.StarterItems = {}
TMC.Shared = TMCShared

-- ═══════════════════════════════════════
-- TMC.Common utilities (used by both sides)
-- ═══════════════════════════════════════

local StringCharset = {}
local NumberCharset = {}
for i = 48,  57 do table.insert(NumberCharset, string.char(i)) end
for i = 65,  90 do table.insert(StringCharset, string.char(i)) end
for i = 97, 122 do table.insert(StringCharset, string.char(i)) end

TMC.Common.GetTime = function(timestamp, format)
    return os.time()
end

TMC.Common.Decode = function(val)
    if type(val) == 'string' then return json.decode(val) end
    return val
end

TMC.Common.Clamp = function(amount, min, max)
    if amount == nil or type(amount) ~= 'number' then return nil end
    if max ~= nil then amount = math.min(amount, max) end
    if min ~= nil then amount = math.max(amount, min) end
    return amount
end

TMC.Common.RandomStr = function(length)
    if length > 0 then
        return TMC.Common.RandomStr(length - 1) .. StringCharset[math.random(1, #StringCharset)]
    else
        return ''
    end
end

TMC.Common.RandomInt = function(length)
    if length > 0 then
        return TMC.Common.RandomInt(length - 1) .. NumberCharset[math.random(1, #NumberCharset)]
    else
        return ''
    end
end

TMC.Common.SplitStr = function(str, delimiter)
    local result = {}
    local from = 1
    local delim_from, delim_to = string.find(str, delimiter, from)
    while delim_from do
        table.insert(result, string.sub(str, from, delim_from - 1))
        from = delim_to + 1
        delim_from, delim_to = string.find(str, delimiter, from)
    end
    table.insert(result, string.sub(str, from))
    return result
end

TMC.Common.MathRound = function(value, numDecimalPlaces)
    return tonumber(string.format('%.' .. (numDecimalPlaces or 0) .. 'f', value))
end

TMC.Common.MathGroupDigits = function(value)
    local left, num, right = string.match(value, '^([^%d]*%d)(%d*)(.-)$')
    return left .. (num:reverse():gsub('(%d%d%d)', '%1,'):reverse()) .. right
end

TMC.Common.MathTrim = function(value)
    if value then return (string.gsub(value, '^%s*(.-)%s*$', '%1')) end
    return nil
end

TMC.Common.MathAverage = function(data)
    local sum = 0
    for _, v in pairs(data) do sum = sum + v end
    return sum / #data
end

TMC.Common.TrueRandom = function(x, y)
    if x ~= nil and y ~= nil then
        return math.random(x, y)
    else
        return math.random(0, 100)
    end
end

TMC.Common.RandomChance = function(min, max, chance)
    local rand = math.random(min, max)
    return rand <= chance
end

TMC.Common.Dump = function(o, p)
    if type(o) == 'table' then
        local s = '{ '
        for k, v in pairs(o) do
            if type(k) ~= 'number' then k = '"' .. k .. '"' end
            s = s .. '[' .. k .. '] = ' .. TMC.Common.Dump(v, true) .. ','
        end
        if not p then print(s .. '} ') end
        return s .. '} '
    else
        return tostring(o)
    end
end

TMC.Common.TablePrint = function(data, toPush, noTab)
    if not noTab then print('Table:') end
    local tabsCache = string.rep('\t', (toPush or 1))
    if type(data) == 'table' then
        for k, v in pairs(data) do
            if type(v) == 'table' then
                print(tabsCache .. k .. ':')
                TMC.Common.TablePrint(v, (toPush or 1) + 1, true)
            else
                print(tabsCache .. k .. ' = ' .. tostring(v))
            end
        end
    else
        print(tabsCache .. tostring(data))
    end
end

TMC.Common.GetJob = function(job)
    job = tostring(job):lower()
    if TMC.Shared.Jobs and TMC.Shared.Jobs[job] then
        return TMC.Shared.Jobs[job]
    end
    return nil
end

TMC.Common.GetJobGrade = function(job, grade)
    job = tostring(job):lower()
    local jobData = TMC.Common.GetJob(job)
    if jobData and jobData.grades and jobData.grades[grade] then
        return jobData.grades[grade]
    end
    return nil
end

TMC.Common.JobLabel = function(job)
    local _job = TMC.Common.GetJob(job)
    if _job then return _job.label end
    return job
end

TMC.Common.GenerateInventory = function(slots)
    local newInv = {}
    for i = 1, slots, 1 do table.insert(newInv, {}) end
    return newInv
end

TMC.Common.GenerateVIN = function(isLocal)
    return tostring((isLocal and '2' or '1') .. TMC.Common.RandomStr(2) .. TMC.Common.RandomInt(4) .. TMC.Common.RandomStr(4) .. TMC.Common.RandomInt(6))
end

TMC.Common.GenerateBankAccount = function()
    return 'BNK0' .. math.random(1, 9) .. 'TMC' .. math.random(1111, 9999) .. math.random(1111, 9999) .. math.random(11, 99)
end

TMC.Common.Shuffle = function(tab)
    for i = #tab, 2, -1 do
        local j = math.random(i)
        tab[i], tab[j] = tab[j], tab[i]
    end
    return tab
end

TMC.Common.Merge = function(t1, t2)
    for k, v in pairs(t2) do
        if type(v) == 'table' and type(t1[k] or false) == 'table' then
            TMC.Common.Merge(t1[k], t2[k])
        else
            t1[k] = v
        end
    end
    return t1
end

TMC.Common.Combine = function(t1, t2)
    local newT = {}
    for _, v in ipairs(t1) do table.insert(newT, v) end
    for _, v in ipairs(t2) do table.insert(newT, v) end
    return newT
end

TMC.Common.CopyTable = function(data)
    local retTab = {}
    if type(data) == 'table' then
        TMC.Common.Merge(retTab, data)
    else
        retTab = data
    end
    return retTab
end

TMC.Common.TableHas = function(tab, value)
    if tab == nil or value == nil then return false end
    for _, v in ipairs(tab) do
        if v == value then return true end
    end
    return false
end

TMC.Common.GetPermissionRank = function(permission)
    for k, v in pairs(TMC.Config.Server.PermissionRanking) do
        if permission == v then return k end
    end
    return 1
end

TMC.Common.DoesRankHavePerm = function(curPerm, reqPerm)
    local curRank = TMC.Common.GetPermissionRank(curPerm)
    local reqRank = TMC.Common.GetPermissionRank(reqPerm)
    return curRank >= reqRank
end

TMC.Common.TrimPlate = function(plate)
    return plate:gsub('^%s*(.-)%s*$', '%1')
end

TMC.Common.IsDepRunning = function(resName)
    if TMC.EnabledResources[resName] then return true end
    return GetResourceState(resName) == 'started'
end

TMC.Common.TableSortAlphabetical = function(data)
    local keys = {}
    for k in pairs(data) do keys[#keys + 1] = k end
    table.sort(keys)
    local i = 0
    return function()
        i = i + 1
        if keys[i] then return keys[i], data[keys[i]] end
    end
end

-- ── Additional utility functions ──

TMC.Common.Levenshtein = function(str1, str2)
    local len1, len2 = #str1, #str2
    local matrix = {}
    for i = 0, len1 do matrix[i] = {[0] = i} end
    for j = 0, len2 do matrix[0][j] = j end
    for i = 1, len1 do
        for j = 1, len2 do
            local cost = str1:sub(i, i) == str2:sub(j, j) and 0 or 1
            matrix[i][j] = math.min(
                matrix[i-1][j] + 1,
                matrix[i][j-1] + 1,
                matrix[i-1][j-1] + cost
            )
        end
    end
    return matrix[len1][len2]
end

TMC.Common.StringStartsWith = function(str, start)
    return str:sub(1, #start) == start
end

TMC.Common.StringEndsWith = function(str, ending)
    return ending == "" or str:sub(-#ending) == ending
end

TMC.Common.StringSplit = function(str, delimiter)
    return TMC.Common.SplitStr(str, delimiter)
end

TMC.Common.TableCount = function(tab)
    local count = 0
    for _ in pairs(tab) do count = count + 1 end
    return count
end

TMC.Common.TableKeys = function(tab)
    local keys = {}
    for k in pairs(tab) do table.insert(keys, k) end
    return keys
end

TMC.Common.TableValues = function(tab)
    local values = {}
    for _, v in pairs(tab) do table.insert(values, v) end
    return values
end

TMC.Common.TableReverse = function(tab)
    local reversed = {}
    for i = #tab, 1, -1 do
        table.insert(reversed, tab[i])
    end
    return reversed
end

TMC.Common.TableIntersect = function(t1, t2)
    local result = {}
    for _, v in pairs(t1) do
        for _, v2 in pairs(t2) do
            if v == v2 then table.insert(result, v) break end
        end
    end
    return result
end

TMC.Common.FindInTable = function(tab, value, useValue)
    for k, v in pairs(tab) do
        if useValue then
            if v == value then return k end
        else
            if k == value then return v end
        end
    end
    return nil
end

TMC.Common.IsJSON = function(str)
    local success = pcall(function() json.decode(str) end)
    return success
end

TMC.Common.Distance = function(coords1, coords2)
    return #(coords1 - coords2)
end

TMC.Common.IsNumberInRange = function(num, min, max)
    return num >= min and num <= max
end

TMC.Common.GetRandomWeightedIndex = function(weights)
    local totalWeight = 0
    for _, w in pairs(weights) do totalWeight = totalWeight + w end
    
    local random = math.random(0, totalWeight * 1000) / 1000
    local currentWeight = 0
    
    for i, w in pairs(weights) do
        currentWeight = currentWeight + w
        if random <= currentWeight then return i end
    end
    
    return #weights
end

TMC.Common.IsNotEmpty = function(val)
    if val == nil then return false end
    if type(val) == 'string' and val == '' then return false end
    if type(val) == 'table' and TMC.Common.TableCount(val) == 0 then return false end
    return true
end

-- TMC.Shared aliases used by scripts (Trim, Round)
TMC.Shared.Trim = function(str)
    if not str then return '' end
    return str:gsub('^%s*(.-)%s*$', '%1')
end

TMC.Shared.Round = function(value, numDecimalPlaces)
    return TMC.Common.MathRound(value, numDecimalPlaces)
end

TMC.Shared.Upper = function(str)
    return str:upper()
end

TMC.Shared.Lower = function(str)
    return str:lower()
end

TMC.Shared.CapitalizeFirst = function(str)
    return str:sub(1, 1):upper() .. str:sub(2)
end

TMC.Shared.Split = function(str, delimiter)
    return TMC.Common.SplitStr(str, delimiter)
end

TMC.Shared.TrimmedSplit = function(str, delimiter)
    local result = {}
    for _, part in pairs(TMC.Common.SplitStr(str, delimiter)) do
        table.insert(result, TMC.Shared.Trim(part))
    end
    return result
end

TMC.Shared.ToString = function(val)
    return tostring(val)
end

TMC.Shared.ToNumber = function(val)
    return tonumber(val)
end

TMC.Shared.IsEmpty = function(val)
    return not TMC.Common.IsNotEmpty(val)
end

-- QBCore aliases (TMC scripts reference both TMC and QBCore globals)
QBCore = TMC
QBConfig = TMC.Config
QBShared = TMC.Shared

-- Global aliases
_G.TMC = TMC
_G.QBCore = TMC
_G.QBConfig = TMC.Config
_G.QBShared = TMC.Shared
_G.TMCConfig = TMCConfig
_G.TMCShared = TMCShared
