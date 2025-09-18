local imageinterface = require("rayimg.imageinterface")
local rl = require("rayimg.raylib")
local vips = require("vips")






local VipsImageLoader = {}



function VipsImageLoader.load_image_and_downsize(file, screen_width, screen_height)
   local vips_image = vips.Image.new_from_file(file)

   local should_cache = false

   if vips_image:width() > screen_width or vips_image:height() > screen_height then
      local scale = math.min(screen_width / vips_image:width(), screen_height / vips_image:height())
      vips_image = vips_image:resize(scale, { kernel = "lanczos3" })
      should_cache = true
   end

   if vips_image:interpretation() ~= "srgb" then
      vips_image = vips_image:colourspace("srgb")
   end



   vips_image = vips_image:autorot()

   local ptr, _ = vips_image:write_to_memory_ptr()
   local image
   if vips_image:hasalpha() then
      image = rl.NewImage(ptr, vips_image:width(), vips_image:height(), 1, rl.PixelFormat_U_R8G8B8A8)
   else
      image = rl.NewImage(ptr, vips_image:width(), vips_image:height(), 1, rl.PixelFormat_U_R8G8B8)
   end

   vips_image = nil

   local loaded_image = { image = image, kind = "static", should_cache = should_cache }

   return loaded_image
end

return VipsImageLoader
