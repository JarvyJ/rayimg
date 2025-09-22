
local function run_process(command)
   local file = io.popen(command .. '; echo $?')
   local output = file:read('*all')
   local rc_start, rc_end = output:find("(%d+)\n$")
   local return_code = output:sub(rc_start, rc_end)
   file:close()
   return output:sub(0, rc_start - 1), tonumber(return_code)
end

local function get_screen_resolution()


   local output, return_code = run_process("which fbset")
   if return_code ~= 0 then

      return 960, 540
   end

   output, return_code = run_process("fbset")

   if return_code ~= 0 then
      error("fbset return code: " .. return_code .. ". Unable to determine screen resolution")
   end

   local width, height = output:match("mode \"(%d+)x(%d+)")

   return tonumber(width), tonumber(height)
end

return get_screen_resolution
