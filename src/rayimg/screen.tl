local function get_screen_resolution(): integer, integer
    local file = io.popen('fbset; echo $?')
    local output = file:read('*all')
    file:close()

    local return_code = output:sub(-2, -2)
    if return_code ~= "0" then
        -- used for development
        return 960, 540
    end

    local width, height = output:match("mode \"(%d+)x(%d+)")

    return tonumber(width) as integer, tonumber(height) as integer
end

return get_screen_resolution
