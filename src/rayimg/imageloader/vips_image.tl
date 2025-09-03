local imageinterface = require("rayimg.imageinterface")
local rl = require("rayimg.raylib")
local vips = require("vips")

local record VipsImage
    is imageinterface.LoadedImage
    where self.kind == "static"
end

local record VipsImageLoader
    is imageinterface.ImageLoader
end

function VipsImageLoader.load_image_and_downsize(file: string, screen_width: integer, screen_height: integer): imageinterface.LoadedImage
    local vips_image = vips.Image.new_from_file(file)

    local should_cache = false

    if vips_image:width() > screen_width or vips_image:height() > screen_height then
        local scale = math.min(screen_width/vips_image:width(), screen_height/vips_image:height())
		vips_image = vips_image:resize(scale, {kernel="lanczos3"})
        should_cache = true
    end

    if vips_image:interpretation() ~= "srgb" then
        vips_image = vips_image:colourspace("srgb")
    end

    -- would rather do this in hw, will see how slow it is on Pis...
    -- I think we need image:get_typeof('orientation'), because image:get_orientation() doesn't work...
    vips_image = vips_image:autorot()
    
    local ptr, _ = vips_image:write_to_memory_ptr()
    local image: rl.Image
    if vips_image:hasalpha() then
        image = rl.NewImage(ptr, vips_image:width(), vips_image:height(), 1, rl.PixelFormat_U_R8G8B8A8)
    else
        image = rl.NewImage(ptr, vips_image:width(), vips_image:height(), 1, rl.PixelFormat_U_R8G8B8)
    end

    vips_image = nil

    local loaded_image: VipsImage = {image=image, kind="static", should_cache=should_cache}

    return loaded_image
end

return VipsImageLoader
