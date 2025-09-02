local argparse = require("lua_libs.argparse")
local path = require("lua_libs.pl.path")
local tinytoml = require("libs.tinytoml")

local enum DisplayOptions
    "filename"
    "caption"
    "none"
end

local enum SortOptions
    "filename"
    "random"
    "natural"
 end

local record SlideSettings
    is argparse.Args
    recursive: boolean -- false
    sort: SortOptions -- natural
    display: DisplayOptions -- none
    duration: number -- 0
    transition_duration: number -- 0
    list: boolean -- false
    paths: {string} -- .
end

local record TomlSettings
    Recursive: boolean -- false
    Sort: SortOptions -- natural
    Display: DisplayOptions -- none
    Duration: number -- 0
    TransitionDuration: number -- 0
    List: boolean
end

local toml_keys: {string:string} = {
    ["Recursive"] = "boolean",
    ["Sort"] = "string",
    ["Display"] = "string",
    ["Duration"] = "number",
    ["TransitionDuration"] = "number",
    ["List"] = "boolean",
}

-- TODO: generate these instead
local sort_options: {string: boolean} = {
    ["filename"] = true,
    ["random"] = true,
    ["natural"] = true,
}

local display_options: {string: boolean} = {
    ["filename"] = true,
    ["caption"] = true,
    ["none"] = true,
}

local sort_options_list = {"filename", "random", "natural"}
local display_options_list = {"filename", "caption", "none"}

local defaults: SlideSettings = {
    recursive = false,
    sort = "natural",
    display = "none",
    duration = 0,
    transition_duration = 0,
    list = false,
    paths = {"."}
}

local record arguments
    display_options: SlideSettings
    get_settings: function(): SlideSettings
end

local function parse_arguments(): SlideSettings, argparse.Parser
    local parser = argparse("rayimg", "the commandline image viewer")

    -- i don't set defaults here so I can load slide_settings.ini and then overwrite with anything passed in from the cli
    parser:flag("-r --recursive")
        :description("recurse into subdirectories")
	
    parser:option("--sort")
        :description("sort mode for pictures (default: natural)")
        :choices({"filename", "random", "natural"})
	
    parser:option("--display")
        :description("text to overlay on image (default: none)")
        :choices({"filename", "caption", "none"})

    parser:option("--duration")
        :description("duration to display each image in a slideshow ('0' for always, must use arrow keys to navigate - default: 0)")
	
    parser:option("--transition-duration")
        :description("length of the transition in seconds during a slideshow (default: 0)")

    parser:flag("-l --list")
        :description("display filepaths on terminal that will be displayed")

    parser:argument("paths", "paths to files or directories to display\ndefaults to current directory\nuse arrow keys or 'duration' option to cycle through")
        :args("*")

    local args: SlideSettings = parser:parse()

    -- we need to do this later
    -- args.duration = convert_to_positive_number(parser, "--duration", args.duration)
    -- args.transition_duration = convert_to_positive_number(parser, "--transition-duration", args.transition_duration)

    -- defaults to current directory if not provided
    if args.paths[1] == nil then
        args.paths[1] = "."
    end

    return args, parser
end

local function parse_ini_file(paths: {string}): TomlSettings
    if #paths > 1 then
        for _, working_path in ipairs(paths) do
            local ini_location = path.join(working_path, "slide_settings.ini")
            if path.isfile(ini_location) then
                print("WARNING: Can't load slide_settings.ini when multiple directories passed in")
                return {}
            end
        end
    end

    local ini_location = path.join(paths[1], "slide_settings.ini")
    if path.isfile(ini_location) then
        local settings: TomlSettings = tinytoml.parse(ini_location) as TomlSettings
        for setting, value in pairs(settings as {string:any}) do
            assert(toml_keys[setting], "Unsupported setting: '" .. setting .. "'\n There may be a typo on the setting name")
            assert(
                toml_keys[setting] == type(value), 
                "Type is not correct for: " .. setting ..': "'.. tostring(value) ..'"\n Ensure true/false don\'t have quotes, but strings do'
            )
            if setting == "Sort" then
                assert(sort_options[value as string], "The only Sort options are " .. table.concat(sort_options_list, ", ") .. '.\n Sort is currently: "' .. tostring(value) .. '"')
            elseif setting == "Display" then
                assert(display_options[value as string], "The only Display options are " .. table.concat(display_options_list, ", ") .. '.\n Display is currently: "' .. tostring(value) .. '"')
            end            
        end
        return settings
    end
end

local function convert_to_positive_number(parser: argparse.Parser, name: string, input: any): number
    local output = tonumber(input)
    if output == nil then
        return nil
    elseif output < 0 then
        parser:error(name .. " must be a positive number, instead got '" .. tostring(input) .. "'")
    end
    return output
end

function arguments.get_settings(): SlideSettings
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
        paths = args.paths
    }

    return final_settings
end

return arguments