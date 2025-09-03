local raylib_image = require("rayimg.imageloader.raylib_image")
local vips_image = require("rayimg.imageloader.vips_image")
local svg = require("rayimg.imageloader.svg")
-- local gif = require("rayimg.imageloader.gif")

local imageinterface = require("rayimg.imageinterface")
local rl = require("rayimg.raylib")
local path = require("rayimg.lua_libs.pl.path")
local dir = require("rayimg.lua_libs.pl.dir")

local image_loaders: {string:function(string, integer, integer): imageinterface.LoadedImage} = {
    [".avif"] = vips_image.load_image_and_downsize,
    [".bmp"] = raylib_image.load_image_and_downsize,
    -- [".gif"] = gif.load_image_and_downsize,
    [".heic"] = vips_image.load_image_and_downsize,
    [".heif"] = vips_image.load_image_and_downsize,
    [".jpeg"] = raylib_image.load_image_and_downsize,
    [".jpg"] = raylib_image.load_image_and_downsize,
    [".jxl"] = vips_image.load_image_and_downsize,
    [".png"] = raylib_image.load_image_and_downsize,
    [".qoi"] = raylib_image.load_image_and_downsize,
    [".svg"] = svg.load_image_and_downsize,
    [".tif"] = vips_image.load_image_and_downsize,
    [".tiff"] = vips_image.load_image_and_downsize,
    [".webp"] = vips_image.load_image_and_downsize,
}

local record LoadedTexture
    -- this reference only exists so Lua doesn't gc the original image data.
    -- some of the file loaders (gif notably) need the original image structures to produce additional frames
    -- ideally it shouldn't be accessed directly
    image: imageinterface.LoadedImage
    texture: rl.Texture2D
    position: rl.Vector2
    filename: string
    caption: string
    scale: number
end

local record ImageLoader
    LoadedTexture: LoadedTexture
    load_image: function(filepath: string, screen_width: integer, screen_height: integer, cache_directory: string): LoadedTexture
end

local function calculate_scale_and_position(screen_width: integer, screen_height: integer, texture: rl.Texture2D): number, rl.Vector2
    local scale = math.min(screen_width/texture.width, screen_height/texture.height)
    local position = rl.NewVector2( (screen_width/2) - (texture.width/2 * scale), (screen_height/2) - (texture.height/2 * scale))
    return scale, position
end

-- trim6 from https://lua-users.org/wiki/StringTrim
local function trim(s: string): string
    return s:match'^()%s*$' and '' or s:match'^%s*(.*%S)'
end

local function get_caption(filepath: string): string
    local caption_file = filepath .. ".txt"
    local caption: string = ""
    if path.isfile(caption_file) then
        caption = trim(io.open(caption_file, "r"):read("*all"))
    end
    return caption
end

ImageLoader.load_image = function(filepath: string, screen_width: integer, screen_height: integer, cache_directory: string): LoadedTexture
    local texture: rl.Texture2D
    local loaded_image: imageinterface.LoadedImage = {}
    
    if cache_directory ~= nil then
        local cache_location = path.abspath(cache_directory) .. filepath .. ".jpg"
        if path.isfile(cache_location) then
            texture = rl.LoadTexture(cache_location)
            loaded_image.kind = "cache"
        end
    end
    
    -- it was loaded from the cache
    if texture == nil then
        if path.isfile(filepath) == false then
            error("Can't load image since filepath does not exist: " .. filepath)
        end

        local file_extension = path.extension(filepath)
        local start = os.clock()
        loaded_image = image_loaders[file_extension](filepath, screen_width, screen_height)
        print("Time to load image", filepath, (os.clock() - start) * 1000)
        texture = rl.LoadTextureFromImage(loaded_image.image)
        
        if cache_directory ~= nil and loaded_image.should_cache then
            local cache_file = path.abspath(cache_directory) .. filepath .. ".jpg"
            local cache_file_dir = path.splitpath(cache_file)
            print(dir.makepath(cache_file_dir))
            rl.ExportImage(loaded_image.image, cache_file)
        end
    end

	rl.SetTextureFilter(texture, rl.FilterBilinear)

	local scale, position = calculate_scale_and_position(screen_width, screen_height, texture)    
    local filename = path.basename(filepath)
    local caption = get_caption(filepath)

    local texture_and_image: LoadedTexture = {
        image=loaded_image,
        filename=filename,
        position=position,
        caption=caption,
        texture=texture,
        scale=scale,
    }
    return texture_and_image
end

return ImageLoader
