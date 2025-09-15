local argparse = require("rayimg.lua_libs.argparse")
local path = require("path")
local tinytoml = require("rayimg.libs.tinytoml")






















local toml_keys = {
   ["Recursive"] = "boolean",
   ["Sort"] = "string",
   ["Display"] = "string",
   ["Duration"] = "number",
   ["TransitionDuration"] = "number",
   ["List"] = "boolean",
}


local sort_options = {
   ["filename"] = true,
   ["random"] = true,
   ["natural"] = true,
}

local display_options = {
   ["filename"] = true,
   ["caption"] = true,
   ["none"] = true,
}

local sort_options_list = { "filename", "random", "natural" }
local display_options_list = { "filename", "caption", "none" }

local arguments = { SlideSettings = {} }















local defaults = {
   recursive = false,
   sort = "natural",
   display = "none",
   duration = 0,
   transition_duration = 0,
   list = false,
   paths = { "." },
}



local function parse_arguments()
   local parser = argparse("rayimg", "the commandline image viewer")


   parser:flag("-r --recursive"):
   description("recurse into subdirectories")

   parser:option("--sort"):
   description("sort mode for pictures (default: natural)"):
   choices({ "filename", "random", "natural" })

   parser:option("--display"):
   description("text to overlay on image (default: none)"):
   choices({ "filename", "caption", "none" })

   parser:option("--duration"):
   description("duration to display each image in a slideshow ('0' for always, must use arrow keys to navigate - default: 0)")

   parser:option("--transition-duration"):
   description("length of the transition in seconds during a slideshow (default: 0)")

   parser:flag("-l --list"):
   description("display filepaths on terminal that will be displayed")

   parser:argument("paths", "paths to files or directories to display\ndefaults to current directory\nuse arrow keys or 'duration' option to cycle through"):
   args("*")

   local args = parser:parse()






   if args.paths[1] == nil then
      args.paths[1] = "."
   end

   return args, parser
end

local function parse_ini_file(paths)
   if #paths > 1 then
      for _, working_path in ipairs(paths) do
         if path.isfile(working_path, "slide_settings.ini") then
            print("WARNING: Can't load slide_settings.ini when multiple directories passed in")
            return {}
         end
      end
   end

   local ini_location = path.abs(paths[1], "slide_settings.ini")
   if path.isfile(ini_location) then
      local settings = tinytoml.parse(ini_location)
      for setting, value in pairs(settings) do
         assert(toml_keys[setting], "Unsupported setting: '" .. setting .. "'\n There may be a typo on the setting name")
         assert(
         toml_keys[setting] == type(value),
         "Type is not correct for: " .. setting .. ': "' .. tostring(value) .. '"\n Ensure true/false don\'t have quotes, but strings do')

         if setting == "Sort" then
            assert(sort_options[value], "The only Sort options are " .. table.concat(sort_options_list, ", ") .. '.\n Sort is currently: "' .. tostring(value) .. '"')
         elseif setting == "Display" then
            assert(display_options[value], "The only Display options are " .. table.concat(display_options_list, ", ") .. '.\n Display is currently: "' .. tostring(value) .. '"')
         end
      end
      return settings
   else
      return {}
   end
end

local function convert_to_positive_number(parser, name, input)
   local output = tonumber(input)
   if output == nil then
      return nil
   elseif output < 0 then
      parser:error(name .. " must be a positive number, instead got '" .. tostring(input) .. "'")
   end
   return output
end

function arguments.get_settings()
   local args, parser = parse_arguments()
   args.duration = convert_to_positive_number(parser, "--duration", args.duration)
   args.transition_duration = convert_to_positive_number(parser, "--transition_duration", args.transition_duration)

   local toml_settings = parse_ini_file(args.paths)
   toml_settings.Duration = convert_to_positive_number(parser, "Duration", toml_settings.Duration)
   toml_settings.TransitionDuration = convert_to_positive_number(parser, "TransitionDuration", toml_settings.TransitionDuration)

   local final_settings = {
      recursive = args.recursive or toml_settings.Recursive or defaults.recursive,
      sort = args.sort or toml_settings.Sort or defaults.sort,
      display = args.display or toml_settings.Display or defaults.display,
      duration = args.duration or toml_settings.Duration or defaults.duration,
      transition_duration = args.transition_duration or toml_settings.TransitionDuration or defaults.transition_duration,
      list = args.list or toml_settings.List or defaults.list,
      paths = args.paths,
   }

   return final_settings
end

return arguments
