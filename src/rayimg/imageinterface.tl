local rl = require("rayimg.raylib")
local ffi = require("ffi")

local type ms = integer

local enum ImageTypes
    "cache"
    "static"
    "animation"
end

local record ImageInterface

    interface LoadedImage
        image: rl.Image
        should_cache: boolean
        kind: ImageTypes
    end

    interface ImageLoader
        load_image_and_downsize: function(file: string, screen_width: integer, screen_height: integer): LoadedImage
    end

    interface Animation
        advance_frame: function(): ms
        get_frame_pixels: function(): ffi.CData
    end

end

return ImageInterface