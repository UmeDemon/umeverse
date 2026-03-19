--[[
    Umeverse Framework - Shared Core Object
    This is the main framework object accessible on both server and client
]]

UME = {}
UME.Players = {}
UME.Functions = {}
UME.ServerCallbacks = {}
UME.ClientCallbacks = {}

-- Shared utility functions

--- Prints a formatted debug message
---@param msg string
function UME.Debug(msg)
    if UmeConfig.EnableLogging then
        print('^3[Umeverse]^0 ' .. tostring(msg))
    end
end

--- Prints an error message
---@param msg string
function UME.Error(msg)
    print('^1[Umeverse ERROR]^0 ' .. tostring(msg))
end

--- Prints a success message
---@param msg string
function UME.Success(msg)
    print('^2[Umeverse]^0 ' .. tostring(msg))
end

--- Deep copy a table
---@param orig table
---@return table
function UME.DeepCopy(orig)
    local copy = {}
    for k, v in pairs(orig) do
        if type(v) == 'table' then
            copy[k] = UME.DeepCopy(v)
        else
            copy[k] = v
        end
    end
    return copy
end

--- Round a number to n decimal places
---@param num number
---@param decimals number
---@return number
function UME.Round(num, decimals)
    local mult = 10 ^ (decimals or 0)
    return math.floor(num * mult + 0.5) / mult
end

--- String trim
---@param s string
---@return string
function UME.Trim(s)
    return s:match('^%s*(.-)%s*$')
end

--- String split
---@param str string
---@param sep string
---@return table
function UME.Split(str, sep)
    local result = {}
    for part in str:gmatch('([^' .. sep .. ']+)') do
        result[#result + 1] = part
    end
    return result
end

-- Seed the PRNG once on load so IDs aren't predictable across restarts
-- os.time() is unavailable on client-side FiveM Lua, fall back to GetGameTimer()
local _seed = (os and os.time and os.time() or GetGameTimer()) + (tonumber(tostring({}):sub(8)) or 0)
math.randomseed(_seed)
for _ = 1, 20 do math.random() end -- burn initial values for better entropy

--- Generate a unique ID (UUID v4 format)
---@return string
function UME.GenerateId()
    local template = 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'
    return string.gsub(template, '[xy]', function(c)
        local v = (c == 'x') and math.random(0, 0xf) or math.random(8, 0xb)
        return string.format('%x', v)
    end)
end

--- Check if a value exists in a table
---@param tbl table
---@param value any
---@return boolean
function UME.TableContains(tbl, value)
    for _, v in pairs(tbl) do
        if v == value then return true end
    end
    return false
end

--- Get table length (works for non-sequential tables)
---@param tbl table
---@return number
function UME.TableLength(tbl)
    local count = 0
    for _ in pairs(tbl) do count = count + 1 end
    return count
end

UME.Success('Umeverse Framework loaded | Version 1.0.0')
