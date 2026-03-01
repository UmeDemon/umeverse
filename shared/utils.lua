-- ============================================================
--  UmeVerse Framework — Shared Utilities
--  Available on both client and server.
-- ============================================================

UmeUtils = {}

--- Deep-copy a table.
---@param orig table
---@return table
function UmeUtils.DeepCopy(orig)
    local orig_type = type(orig)
    local copy
    if orig_type == 'table' then
        copy = {}
        for k, v in pairs(orig) do
            copy[UmeUtils.DeepCopy(k)] = UmeUtils.DeepCopy(v)
        end
        setmetatable(copy, UmeUtils.DeepCopy(getmetatable(orig)))
    else
        copy = orig
    end
    return copy
end

--- Check whether a value is present in a sequential table.
---@param tbl   table
---@param value any
---@return boolean
function UmeUtils.TableContains(tbl, value)
    for _, v in ipairs(tbl) do
        if v == value then return true end
    end
    return false
end

--- Return the number of entries in a table (works for hash tables too).
---@param tbl table
---@return integer
function UmeUtils.TableLength(tbl)
    local count = 0
    for _ in pairs(tbl) do count = count + 1 end
    return count
end

--- Trim leading and trailing whitespace from a string.
---@param str string
---@return string
function UmeUtils.Trim(str)
    return str:match('^%s*(.-)%s*$')
end

--- Split a string on a separator, returning a sequential table.
--- Special pattern characters in `sep` are automatically escaped.
---@param str string
---@param sep string
---@return table
function UmeUtils.Split(str, sep)
    -- Escape any magic pattern characters in the separator.
    local escapedSep = sep:gsub('[%(%)%.%%%+%-%*%?%[%^%$%]]', '%%%1')
    local result = {}
    for part in str:gmatch('([^' .. escapedSep .. ']+)') do
        result[#result + 1] = part
    end
    return result
end

--- Round a number to the given decimal places (default 0).
---@param num    number
---@param places integer|nil
---@return number
function UmeUtils.Round(num, places)
    local mult = 10 ^ (places or 0)
    return math.floor(num * mult + 0.5) / mult
end

--- Format a number as a currency string, e.g. "$1,234.56".
---@param amount number
---@return string
function UmeUtils.FormatMoney(amount)
    local formatted = tostring(UmeUtils.Round(amount, 2))
    -- Ensure two decimal places.
    if not formatted:find('%.') then
        formatted = formatted .. '.00'
    else
        local decimals = formatted:match('%.(.+)$')
        if #decimals == 1 then
            formatted = formatted .. '0'
        end
    end
    -- Insert thousand separators.
    local int, dec = formatted:match('^(%-?%d+)(%.%d+)$')
    int = int:reverse():gsub('(%d%d%d)', '%1,'):reverse():gsub('^,', '')
    return '$' .. int .. dec
end

--- Print a debug message to the console (only when UmeConfig.Debug is true).
---@param ... any
function UmeUtils.Debug(...)
    if UmeConfig and UmeConfig.Debug then
        local parts = {}
        for _, v in ipairs({...}) do
            parts[#parts + 1] = tostring(v)
        end
        print('[UmeVerse][DEBUG] ' .. table.concat(parts, ' '))
    end
end
