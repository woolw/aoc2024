local utils = {}

--- checks if a file can be opened at a given location
--- @param file string
--- @return boolean
function utils.file_exists(file)
    local f = io.open(file, 'rb')
    if f then f:close() end
    return f ~= nil
end

---returns iterable table of lines in given file, if found
---@param file string
---@return table
function utils.lines_from(file)
    if not utils.file_exists(file) then
        print('file not found')
        return {}
    end
    local lines = {}
    for line in io.lines(file) do
        lines[#lines + 1] = line
    end
    return lines
end

---returns table with the split results over a given character
---@param inputstr string
---@param sep string
---@return table
function utils.split_on_char(inputstr, sep)
    if sep == nil then
        sep = '%s'
    end
    local t = {}
    for str in string.gmatch(inputstr, '([^' .. sep .. ']+)') do
        table.insert(t, str)
    end
    return t
end

return utils
