local table_math = {}

---returns the sum of all numbers in a table
---@param vals {}
---@return number
function table_math.sum(vals)
    local sum = 0
    for _, val in pairs(vals) do
        if tonumber(val) ~= nil then
            sum = sum + val
        end
    end
    --print(sum)
    return sum
end

---returns the product of all numbers in a table
---@param vals {}
---@return number
function table_math.product(vals)
    local pro = 1
    for _, val in pairs(vals) do
        if tonumber(val) ~= nil then
            pro = pro * val
        end
    end
    --print(pro)
    return pro
end

return table_math
