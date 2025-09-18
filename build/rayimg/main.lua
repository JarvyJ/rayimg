local arguments = require("rayimg.arguments")
local get_list_files = require("rayimg.fileloader")
local rl = require("rayimg.raylib")
local vips = require("vips")
local ImageHandler = require("rayimg.imageloader.imagehandler")
local ImageLoader = require("rayimg.imageloader.imageloader")
local imageinterface = require("rayimg.imageinterface")
local get_screen_resolution = require("rayimg.screen")

local path = require("path")
local rayimg_location = package.searchpath("rayimg.main", package.path)
local rayimg_dir = path.parent(rayimg_location)
local font_location = path.abs(rayimg_dir, "NotoSans-Regular.ttf")


vips.cache_set_max(0)
vips.cache_set_max_mem(0)
vips.cache_set_max_files(0)


local screen_width, screen_height = get_screen_resolution()

local function load_app()
   local args = arguments.get_settings()
   local files = get_list_files(args)
   local image_handler = ImageHandler.new(files, screen_width, screen_height)

   return args, image_handler
end

local function display_error(error_message)
   rl.init_window(screen_width, screen_height, "rayimg - ERROR")
   local font = rl.LoadFont(font_location)
   local font_position = rl.NewVector2(10, 10)
   local short_error = error_message:match(":%d+%: (.-)\n")
   while not rl.WindowShouldClose() do
      rl.BeginDrawing()
      rl.ClearBackground(rl.BLACK)
      rl.DrawTextEx(font, short_error, font_position, font.baseSize, 0, rl.RAYWHITE)
      rl.EndDrawing()
   end
end

local ok, args, image_handler = xpcall(load_app, (debug.traceback))
if not ok then
   local full_error = args
   print(full_error)
   if os.getenv("DISPLAY_ERROR_ON_SCREEN") then
      display_error(full_error)
   end
   os.exit(1)
end


rl.init_window(screen_width, screen_height, "rayimg")

local font = rl.LoadFont(font_location)
local fontSize = 48
local fontPosition = rl.NewVector2(20, screen_height - fontSize - 10)

local loaded_texture = image_handler:get_current_image()
local next_texture


if args.transition_duration > 0 then
   next_texture = image_handler:peek_next_image()
end

local timer_duration = 0
local transitioning = false
local transition_time = 0
local transition_opacity = 255

local function reset_timers()
   timer_duration = 0
   transitioning = false
   transition_time = 0
end

local function drawText()
   if args.display == "none" then
      return
   elseif args.display == "filename" then
      rl.DrawRectangleGradientV(0, (fontPosition.y) - fontSize, screen_width, fontSize * 2 + 20, rl.NewColor(0, 0, 0, 0), rl.NewColor(0, 0, 0, 192))
      rl.DrawTextEx(font, loaded_texture.filename, fontPosition, fontSize, 0, rl.RAYWHITE)
   elseif args.display == "caption" then
      local caption = loaded_texture.caption
      if #caption > 0 then
         rl.DrawRectangleGradientV(0, (fontPosition.y) - fontSize, screen_width, fontSize * 2 + 20, rl.NewColor(0, 0, 0, 0), rl.NewColor(0, 0, 0, 192))
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
      rl.SetTargetFPS(math.floor(1000 / (loaded_texture.image).advance_frame()))
      rl.UpdateTexture(loaded_texture.texture, (loaded_texture.image).get_frame_pixels())
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
