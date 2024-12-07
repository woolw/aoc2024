local utils = {}

--- checks if a file can be opened at a given location
--- @param file string
--- @return boolean
function utils.file_exists(file)
    local f = io.open(file, 'rb')
    if f then f:close() end
    return f ~= nil
end

---returns all file contents if found, else ''
---@param file string
---@return string
function utils.read_all(file)
    if not utils.file_exists(file) then
        print('file not found')
        return ''
    end
    local f = assert(io.open(file, "rb"))
    local content = f:read("*all")
    f:close()
    return content
end

---returns table with the split results over a given string
---@param inputstr string
---@param sep string
---@return table
function utils.split_on_string(inputstr, sep)
    if sep == nil then
        sep = '%s'
    end
    local t = {}
    for str in string.gmatch(inputstr, "(.-)(" .. sep .. ")") do
        table.insert(t, str)
    end
    return t
end

return utils
