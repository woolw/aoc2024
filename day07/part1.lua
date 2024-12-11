local utils = require('utils')
local table_math = require('table_math')

--------------------------------------------------------------------

---@param t_res number
---@param parts table
---@return boolean
local function iter_mixed_sum_pro(t_res, parts)
    local res = {}
    table.insert(res, parts[1])

    for q, part in pairs(parts) do
        if q == 1 then goto continue end
        local b_res = {}
        for _, op in pairs(res) do
            table.insert(b_res, op * part)
            table.insert(b_res, op + part)
        end
        res = b_res
        ::continue::
    end

    for _, check in pairs(res) do
        if check == t_res then return true end
    end
    return false
end

--------------------------------------------------------------------

local x = os.clock()
local file = 'input'
local lines = utils.lines_from(file)

local result = 0
for _, v in pairs(lines) do
    if #v <= 1 then goto continue end

    local t = utils.split_on_char(v, ':')
    local t_res = tonumber(t[1])
    if type(t_res) ~= 'number' then
        print('ERROR: could not parse to number :' .. t[1])
        return
    end
    local vals = utils.split_on_char(t[2], ' ')

    local sum = table_math.sum(vals)
    local pro = table_math.product(vals)
    if t_res ~= sum and t_res ~= pro and iter_mixed_sum_pro(t_res, vals) == false then
        --print('INVALID: ', 'res[' .. t_res .. ']', 'sum[' .. sum .. ']', 'pro[' .. pro .. ']')
        goto continue
    end

    result = result + t_res
    --print('VALID: ', 'res[' .. t_res .. ']', 'parts[' .. table.concat(vals, ',') .. ']')
    ::continue::
end
print('Part One : ', result)
print(string.format('elapsed time: %.2f s\n', os.clock() - x))
