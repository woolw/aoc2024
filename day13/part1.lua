local utils = require('utils')
local table_math = require('table_math')

--------------------------------------------------------------------

---@param game table
---@param a_button table
---@param b_button table
---@return integer
local function solve_game(game, a_button, b_button)
    local res = { { {}, 0 } }
    table.insert(res, { game, 0 })
    --print(table.concat(game), table.concat(a_button), table.concat(b_button))

    for _ = 1, 100, 1 do
        local b_res = {}
        for _, op in pairs(res) do
            local a_game = { { tonumber(op[1][1]) - tonumber(a_button[1]), tonumber(op[1][2]) - tonumber(a_button[2]) },
                tonumber(op[2]) + 3 }
            if a_game[1][1] == 0 and a_game[1][2] == 0 then return a_game[2] end
            table.insert(b_res, a_game)

            local b_game = { { op[1][1] - b_button[1], op[1][2] - b_button[2] }, op[2] + 1 }
            if b_game[1][1] == 0 and b_game[1][2] == 0 then return b_game[2] end
            table.insert(b_res, b_game)
        end
        res = b_res
    end

    for _, check in pairs(res) do
        if check[1][1] == 0 and check[1][2] == 0 then return check[2] end
    end
    return 0
end

--------------------------------------------------------------------

local x = os.clock()
local file = 'input'
local lines = utils.lines_from(file)

local a_button = { 0, 0 }
local b_button = { 0, 0 }
local game = { 0, 0 }

local result = 0
for i, v in pairs(lines) do
    if #v <= 1 then goto continue end

    if i % 3 == 0 then
        string.gsub(v, 'X%=(%d+), Y%=(%d+)', function(c1, c2)
            game = { c1, c2 }
        end)
        result = result + solve_game(game, a_button, b_button)
    elseif i % 3 == 1 then
        string.gsub(v, 'X%+(%d+), Y%+(%d+)', function(c1, c2)
            a_button = { c1, c2 }
        end)
    elseif i % 3 == 2 then
        string.gsub(v, 'X%+(%d+), Y%+(%d+)', function(c1, c2)
            b_button = { c1, c2 }
        end)
    end

    ::continue::
end
print('Part One : ', result)
print(string.format('elapsed time: %.2f s\n', os.clock() - x))
