local utils = require('utils')

local x = os.clock()
local file = 'input'
local content = utils.read_all(file)

local result = 0

string.gsub(content, 'mul%((%d),(%d)%)', function(c1, c2)
    result = result + (c1 * c2)
end)
string.gsub(content, 'mul%((%d),(%d%d)%)', function(c1, c2)
    result = result + (c1 * c2)
end)
string.gsub(content, 'mul%((%d),(%d%d%d)%)', function(c1, c2)
    result = result + (c1 * c2)
end)

string.gsub(content, 'mul%((%d%d),(%d)%)', function(c1, c2)
    result = result + (c1 * c2)
end)
string.gsub(content, 'mul%((%d%d),(%d%d)%)', function(c1, c2)
    result = result + (c1 * c2)
end)
string.gsub(content, 'mul%((%d%d),(%d%d%d)%)', function(c1, c2)
    result = result + (c1 * c2)
end)

string.gsub(content, 'mul%((%d%d%d),(%d)%)', function(c1, c2)
    result = result + (c1 * c2)
end)
string.gsub(content, 'mul%((%d%d%d),(%d%d)%)', function(c1, c2)
    result = result + (c1 * c2)
end)
string.gsub(content, 'mul%((%d%d%d),(%d%d%d)%)', function(c1, c2)
    result = result + (c1 * c2)
end)

print('Part One : ', result)
print(string.format('elapsed time: %.2f s\n', os.clock() - x))
