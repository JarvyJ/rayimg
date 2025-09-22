-- quick and a little dirty, but it gets the job done for what we need!
local function run_process(command: string): string, integer
    local file = io.popen(command .. '; echo $?')
    local output = file:read('*all')
    local rc_start, rc_end = output:find("(%d+)\n$")
    local return_code = output:sub(rc_start, rc_end)
    file:close()
    return output:sub(0, rc_start - 1), tonumber(return_code) as integer
end

local function get_screen_resolution(): integer, integer
    -- honestly not the best way to check if we're on a pi, 
    -- I would love if we could get back the build_platform from raylib
    local output, return_code = run_process("which fbset")
    if return_code ~= 0 then
        -- not on a pi, assuming development, using .5 of 1920x1080
        return 960, 540
    end

    output, return_code = run_process("fbset")

    if return_code ~= 0 then
        error("fbset return code: " .. return_code .. ". Unable to determine screen resolution")
    end

    local width, height = output:match("mode \"(%d+)x(%d+)")

    return tonumber(width) as integer, tonumber(height) as integer
end

return get_screen_resolution
