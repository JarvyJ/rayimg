local imageinterface = require("rayimg.imageinterface")
local rl = require("rayimg.raylib")

local record RaylibImage
    is imageinterface.LoadedImage
    where self.kind == "static"
    metamethod __gc: function(RaylibImage)
end

local record RaylibImageLoader
    is imageinterface.ImageLoader
end

function RaylibImageLoader.load_image_and_downsize(file: string, screen_width: integer, screen_height: integer): imageinterface.LoadedImage
    local image = rl.LoadImage(file)
    local should_cache = false
    if image.width > screen_width or image.height > screen_height then
        local scale = math.min(screen_width/image.width, screen_height/image.height)
		local newWidth = math.min(screen_width, scale*image.width)
		local newHeight = math.min(screen_height, scale*image.height)
        rl.ImageResize(image, math.floor(newWidth), math.floor(newHeight))
        should_cache = true
    end

    local mt = {__gc=function(self: RaylibImage) print("raylib gc called") rl.UnloadImage(self.image) end}
    local loaded_image: RaylibImage = {image=image, kind="static", should_cache=should_cache}
    setmetatable(loaded_image, mt)
    return loaded_image
end

return RaylibImageLoader