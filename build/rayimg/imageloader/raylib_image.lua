local imageinterface = require("rayimg.imageinterface")
local rl = require("rayimg.raylib")







local RaylibImageLoader = {}



function RaylibImageLoader.load_image_and_downsize(file, screen_width, screen_height)
   local image = rl.LoadImage(file)
   local should_cache = false
   if image.width > screen_width or image.height > screen_height then
      local scale = math.min(screen_width / image.width, screen_height / image.height)
      local newWidth = math.min(screen_width, scale * image.width)
      local newHeight = math.min(screen_height, scale * image.height)
      rl.ImageResize(image, math.floor(newWidth), math.floor(newHeight))
      should_cache = true
   end

   local mt = { __gc = function(self) print("raylib gc called"); rl.UnloadImage(self.image) end }
   local loaded_image = { image = image, kind = "static", should_cache = should_cache }
   setmetatable(loaded_image, mt)
   return loaded_image
end

return RaylibImageLoader
