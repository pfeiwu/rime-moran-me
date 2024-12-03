local utf8 = require("utf8")
local Module = {}
-- @param string utf8
-- @param i start_pos
-- @param j end_pos
function Module.utf8_sub(s,i,j)
   i = i or 1
   j = j or -1
   local n = utf8.len(s)
   if not n then return nil end
   if i > n or -j > n then return "" end
   if i<1 or j<1 then
      if i<0 then i = n+1+i end
      if j<0 then j = n+1+j end
      if i<0 then i = 1 elseif i>n then i = n end
      if j<0 then j = 1 elseif j>n then j = n end
   end
   if j<i then return "" end
   i = utf8.offset(s,i)
   j = utf8.offset(s,j+1)
   if i and j then return s:sub(i,j-1)
      elseif i then return s:sub(i)
      else return ""
   end
end

-- get the common prefix of two strings
-- @param s1 string
-- @param s2 string
-- @return string common prefix,string remaining s1,string remaining s2
function Module.utf8_common_prefix(s1, s2)
    local len = math.min(utf8.len(s1), utf8.len(s2))
    if len == 0 then
        return "", s1, s2
    end

    for i = 1, len do
        local c1 = Module.utf8_sub(s1, i, i)
        local c2 = Module.utf8_sub(s2, i, i)
        if c1 ~= c2 then
            return Module.utf8_sub(s1, 1, i - 1), Module.utf8_sub(s1, i), Module.utf8_sub(s2, i)
        end
    end
    return Module.utf8_sub(s1, 1, len), Module.utf8_sub(s1, len + 1), Module.utf8_sub(s2, len + 1)
end

function Module.utf8_char_iter(s)
    local i = 0
    local len = utf8.len(s)
    return function()
        i = i + 1
        if i <= len then
            return Module.utf8_sub(s, i, i)
        end
    end
end

function Module.append_trailing_space(str)
    return str:gsub("%s*$", " ")
end

function Module.trim_trailing_space(str)
    return str:gsub("%s+$", "")
end

local full_to_half = {
    [0x30A1] = 0xFF67,
    [0x30A2] = 0xFF71,
    [0x30A3] = 0xFF68,
    [0x30A4] = 0xFF72,
    [0x30A5] = 0xFF69,
    [0x30A6] = 0xFF73,
    [0x30A7] = 0xFF6A,
    [0x30A8] = 0xFF74,
    [0x30A9] = 0xFF6B,
    [0x30AA] = 0xFF75,
    [0x30AB] = 0xFF76,
    [0x30AC] = 0xFF76,
    [0x30AD] = 0xFF77,
    [0x30AE] = 0xFF77,
    [0x30AF] = 0xFF78,
    [0x30B0] = 0xFF78,
    [0x30B1] = 0xFF79,
    [0x30B2] = 0xFF79,
    [0x30B3] = 0xFF7A,
    [0x30B4] = 0xFF7A,
    [0x30B5] = 0xFF7B,
    [0x30B6] = 0xFF7B,
    [0x30B7] = 0xFF7C,
    [0x30B8] = 0xFF7C,
    [0x30B9] = 0xFF7D,
    [0x30BA] = 0xFF7D,
    [0x30BB] = 0xFF7E,
    [0x30BC] = 0xFF7E,
    [0x30BD] = 0xFF7F,
    [0x30BE] = 0xFF7F,
    [0x30BF] = 0xFF80,
    [0x30C0] = 0xFF80,
    [0x30C1] = 0xFF81,
    [0x30C2] = 0xFF81,
    [0x30C3] = 0xFF6F,
    [0x30C4] = 0xFF82,
    [0x30C5] = 0xFF82,
    [0x30C6] = 0xFF83,
    [0x30C7] = 0xFF83,
    [0x30C8] = 0xFF84,
    [0x30C9] = 0xFF84,
    [0x30CA] = 0xFF85,
    [0x30CB] = 0xFF86,
    [0x30CC] = 0xFF87,
    [0x30CD] = 0xFF88,
    [0x30CE] = 0xFF89,
    [0x30CF] = 0xFF8A,
    [0x30D0] = 0xFF8A,
    [0x30D1] = 0xFF8A,
    [0x30D2] = 0xFF8B,
    [0x30D3] = 0xFF8B,
    [0x30D4] = 0xFF8B,
    [0x30D5] = 0xFF8C,
    [0x30D6] = 0xFF8C,
    [0x30D7] = 0xFF8C,
    [0x30D8] = 0xFF8D,
    [0x30D9] = 0xFF8D,
    [0x30DA] = 0xFF8D,
    [0x30DB] = 0xFF8E,
    [0x30DC] = 0xFF8E,
    [0x30DD] = 0xFF8E,
    [0x30DE] = 0xFF8F,
    [0x30DF] = 0xFF90,
    [0x30E0] = 0xFF91,
    [0x30E1] = 0xFF92,
    [0x30E2] = 0xFF93,
    [0x30E3] = 0xFF6C,
    [0x30E4] = 0xFF94,
    [0x30E5] = 0xFF6D,
    [0x30E6] = 0xFF95,
    [0x30E7] = 0xFF6E,
    [0x30E8] = 0xFF96,
    [0x30E9] = 0xFF97,
    [0x30EA] = 0xFF98,
    [0x30EB] = 0xFF99,
    [0x30EC] = 0xFF9A,
    [0x30ED] = 0xFF9B,
    [0x30EE] = 0xFF9C,
    [0x30EF] = 0xFF9D,
    [0x30F0] = 0xFF9D,
    [0x30F2] = 0xff66
}

function Module.hira2kata(hira, is_half_width)
    local is_half_width = is_half_width or false
    local kata = ""

    for i = 1, utf8.len(hira) do
        local u = Module.utf8_sub(hira, i, i)
        local code = utf8.codepoint(u)

        if code >= 0x3041 and code <= 0x3096 then
            -- hiragana to katakana
            code = code + 0x60
        end

        if is_half_width and full_to_half[code] then
            -- katakana to half-width katakana
            kata = kata .. utf8.char(full_to_half[code])
        else
            kata = kata .. utf8.char(code)
        end
    end
    return kata
end

function Module.insert_sorted(list, new_element, compare)
    if #list == 0 then
        table.insert(list, new_element)
        return
    end
    local low, high = 1, #list
    while low <= high do
        local mid = math.floor((low + high) / 2)
        if compare(new_element, list[mid]) then
            high = mid - 1
        else
            low = mid + 1
        end
    end
    table.insert(list, low, new_element)
end

return Module
