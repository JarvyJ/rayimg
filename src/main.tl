local arguments = require("arguments")
local get_list_files = require("fileloader")
local rl = require("raylib")
local vips = require("vips")
local ImageHandler = require("imageloader.imagehandler")
local ImageLoader = require("imageloader.imageloader")
local imageinterface = require("imageinterface")

-- use as little app memory as possible
vips.cache_set_max(0)
vips.cache_set_max_mem(0)
vips.cache_set_max_files(0)

local args = arguments.get_settings()
local files = get_list_files(args)

local screen_width = (1920/2) as integer
local screen_height = (1080/2) as integer

local image_handler = ImageHandler.new(files, screen_width, screen_height)

rl.init_window(screen_width, screen_height, "rayimg - lua test")

local font = rl.LoadFont("NotoSans-Regular.ttf")
local fontSize = 48
local fontPosition = rl.NewVector2(20, screen_height-fontSize-10)

local loaded_texture = image_handler:get_current_image()
local next_texture: ImageLoader.LoadedTexture

-- will need both images loaded to do a smooth transition
if args.transition_duration > 0 then
    next_texture = image_handler:peek_next_image()
end

local timer_duration: number = 0
local transitioning = false
local transition_time: number = 0
local transition_opacity: integer = 255

local function reset_timers()
    timer_duration = 0
    transitioning = false
    transition_time = 0
end

local function drawText()
    if args.display == "none" then
        return
    elseif args.display == "filename" then
        rl.DrawRectangleGradientV(0, (fontPosition.y as integer)-fontSize, screen_width, fontSize*2+20, rl.NewColor(0, 0, 0, 0), rl.NewColor(0, 0, 0, 192))
        rl.DrawTextEx(font, loaded_texture.filename, fontPosition, fontSize, 0, rl.RAYWHITE)
    elseif args.display == "caption" then
        local caption = loaded_texture.caption
        if #caption > 0 then
            rl.DrawRectangleGradientV(0, (fontPosition.y as integer)-fontSize, screen_width, fontSize*2+20, rl.NewColor(0, 0, 0, 0), rl.NewColor(0, 0, 0, 192))
            rl.DrawTextEx(font, caption, fontPosition, fontSize, 0, rl.RAYWHITE)
        end
    end
end

local function drawSingleImage()
    rl.BeginDrawing()
    rl.ClearBackground(rl.BLACK)
    rl.DrawTextureEx(loaded_texture.texture, loaded_texture.position, 0, loaded_texture.scale, rl.WHITE)
    drawText()
    rl.EndDrawing()
end

while not rl.WindowShouldClose() do
    if rl.IsKeyPressed(rl.KEY_RIGHT) then
        rl.UnloadTexture(loaded_texture.texture)
        image_handler:increase_index()
        loaded_texture = image_handler:get_current_image()
        reset_timers()
    end

    if rl.IsKeyPressed(rl.KEY_LEFT) then
        rl.UnloadTexture(loaded_texture.texture)
        image_handler:decrease_index()
        loaded_texture = image_handler:get_current_image()
        reset_timers()
    end

    if args.duration > 0 then
        if timer_duration >= args.duration then
            transitioning = true
            rl.SetTargetFPS(20)
        end
        timer_duration = timer_duration + rl.GetFrameTime()
    end

    if transitioning and args.transition_duration > 0 then
        rl.SetTargetFPS(60)
        transition_time = transition_time + rl.GetFrameTime()
        transition_opacity = math.min(math.floor(255 * (transition_time / args.transition_duration)), 255)

        rl.BeginDrawing()
        rl.ClearBackground(rl.BLACK)
        rl.DrawTextureEx(loaded_texture.texture, loaded_texture.position, 0, loaded_texture.scale, rl.NewColor(255, 255, 255, 255 - transition_opacity))
        rl.DrawTextureEx(next_texture.texture, next_texture.position, 0, next_texture.scale, rl.NewColor(255, 255, 255, transition_opacity))
        drawText()
        rl.EndDrawing()

        if transition_time > args.transition_duration then
            rl.UnloadTexture(loaded_texture.texture)

            -- since the next image is already loaded, we just need to increase the index and move on
            image_handler:increase_index()
            loaded_texture = next_texture
            
            next_texture = image_handler:peek_next_image()
            reset_timers()
        end
    elseif transitioning then
        rl.UnloadTexture(loaded_texture.texture)
        image_handler:increase_index()
        loaded_texture = image_handler:get_current_image()
        reset_timers()
        drawSingleImage()
    elseif loaded_texture.image.kind == "animation" then
        rl.SetTargetFPS(math.floor(1000/(loaded_texture.image as imageinterface.Animation).advance_frame()))
        rl.UpdateTexture(loaded_texture.texture, (loaded_texture.image as imageinterface.Animation).get_frame_pixels())
        drawSingleImage()
    else
        drawSingleImage()
    end
end
rl.UnloadTexture(loaded_texture.texture)
if next_texture ~= nil then
    rl.UnloadTexture(next_texture.texture)
end
rl.UnloadFont(font)
rl.CloseWindow()
