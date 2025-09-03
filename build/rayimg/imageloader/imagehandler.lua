local ImageLoader = require("rayimg.imageloader.imageloader")

local ImageHandler = {}







function ImageHandler.new(list_of_files, screen_width, screen_height)
   local self = setmetatable({}, { __index = ImageHandler })

   self.list_of_files = list_of_files
   self.current_index = 1
   self.screen_width = screen_width
   self.screen_height = screen_height
   self.cache_directory = os.getenv("CACHE_DIR")

   return self
end

function ImageHandler:get_current_image()
   if #self.list_of_files == 0 then
      error("Could not open any of the found files. See above in log for details.\nImages potentially corrupt or incompatible formats")
   end

   local current_file = self.list_of_files[self.current_index]
   local success, texture_and_image = pcall(ImageLoader.load_image, current_file, self.screen_width, self.screen_height, self.cache_directory)
   if success == false then
      local warning = "WARNING: unable to load file '%s' \n Error: %s"
      print(string.format(warning, current_file, texture_and_image))
      table.remove(self.list_of_files, self.current_index)
      return self:get_current_image()
   end

   return texture_and_image
end


function ImageHandler:peek_next_image()
   local next_image_index = self.current_index + 1
   if next_image_index > #self.list_of_files then
      next_image_index = 1
   end

   local next_file = self.list_of_files[next_image_index]

   local success, texture_and_image = pcall(ImageLoader.load_image, next_file, self.screen_width, self.screen_height, self.cache_directory)
   if success == false then
      local warning = "WARNING: unable to load file '%s' \n Error: %s"
      print(string.format(warning, next_file, texture_and_image))
      table.remove(self.list_of_files, next_image_index)
      return self:peek_next_image()
   end
   return texture_and_image
end

function ImageHandler:increase_index()
   if self.current_index >= #self.list_of_files then
      self.current_index = 1
   else
      self.current_index = self.current_index + 1
   end
end

function ImageHandler:decrease_index()
   if self.current_index <= 1 then
      self.current_index = #self.list_of_files
   else
      self.current_index = self.current_index - 1
   end
end

return ImageHandler
