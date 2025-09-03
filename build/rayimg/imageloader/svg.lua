local imageinterface = require("rayimg.imageinterface")
local rl = require("rayimg.raylib")
local vips = require("vips")






local SvgImageLoader = {}



function SvgImageLoader.load_image_and_downsize(file, screen_width, screen_height)
   local vips_image = vips.Image.thumbnail(file, screen_width, { height = screen_height })

   if vips_image:interpretation() ~= "srgb" then
      vips_image = vips_image:colourspace("srgb")
   end

   local ptr, _ = vips_image:write_to_memory_ptr()
   local image
   if vips_image:hasalpha() then
      image = rl.NewImage(ptr, vips_image:width(), vips_image:height(), 1, rl.PixelFormat_U_R8G8B8A8)
   else
      image = rl.NewImage(ptr, vips_image:width(), vips_image:height(), 1, rl.PixelFormat_U_R8G8B8)
   end

   vips_image = nil

   local loaded_image = { image = image, kind = "static", should_cache = false }

   return loaded_image
end

return SvgImageLoader
