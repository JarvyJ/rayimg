local function get_screen_resolution()
   local file = io.popen('fbset; echo $?')
   local output = file:read('*all')
   file:close()

   local return_code = output:sub(-2, -2)
   if return_code ~= "0" then

      return 960, 540
   end

   local width, height = output:match("mode \"(%d+)x(%d+)")

   return tonumber(width), tonumber(height)
end

return get_screen_resolution
