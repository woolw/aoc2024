local utils = require('utils')

------------------------------------------------------------------

---@param s string
---@return number
local function valid_mul(s)
    local r = 0
    string.gsub(s, 'mul%((%d),(%d)%)', function(c1, c2)
        r = r + (c1 * c2)
    end)
    string.gsub(s, 'mul%((%d),(%d%d)%)', function(c1, c2)
        r = r + (c1 * c2)
    end)
    string.gsub(s, 'mul%((%d),(%d%d%d)%)', function(c1, c2)
        r = r + (c1 * c2)
    end)

    string.gsub(s, 'mul%((%d%d),(%d)%)', function(c1, c2)
        r = r + (c1 * c2)
    end)
    string.gsub(s, 'mul%((%d%d),(%d%d)%)', function(c1, c2)
        r = r + (c1 * c2)
    end)
    string.gsub(s, 'mul%((%d%d),(%d%d%d)%)', function(c1, c2)
        r = r + (c1 * c2)
    end)

    string.gsub(s, 'mul%((%d%d%d),(%d)%)', function(c1, c2)
        r = r + (c1 * c2)
    end)
    string.gsub(s, 'mul%((%d%d%d),(%d%d)%)', function(c1, c2)
        r = r + (c1 * c2)
    end)
    string.gsub(s, 'mul%((%d%d%d),(%d%d%d)%)', function(c1, c2)
        r = r + (c1 * c2)
    end)

    return r
end

------------------------------------------------------------------

local x = os.clock()
local file = 'input'
local content = utils.read_all(file)

local result = 0

local dont_splits = utils.split_on_string(content .. "don't()", "don't%(%)")
for i, str in pairs(dont_splits) do
    if i == 1 then
        result = valid_mul(str)
    end
    local i_do = string.find(str, 'do%(%)')
    if i_do == nil then goto continue end

    local valid_str = string.sub(str, i_do)
    result = result + valid_mul(valid_str)
    ::continue::
end

print('Part Two : ', result)
print(string.format('elapsed time: %.2f s\n', os.clock() - x))
