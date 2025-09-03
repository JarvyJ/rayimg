local dir = require("rayimg.lua_libs.pl.dir")
local path = require("rayimg.lua_libs.pl.path")

local display_options = require("rayimg.arguments").display_options

local validFileExtensions: {string:boolean} = {
    [".avif"] = true,
    [".bmp"] = true,
    [".gif"] = true,
    [".heic"] = true,
    [".heif"] = true,
    [".jpeg"] = true,
    [".jpg"] = true,
    [".jxl"] = true,
    [".png"] = true,
    [".qoi"] = true,
    [".svg"] = true,
    [".tif"] = true,
    [".tiff"] = true,
    [".webp"] = true,
}

-- from https://notebook.kulchenko.com/algorithms/alphanumeric-natural-sorting-for-humans-in-lua,
-- absolutely amazing writeup on this!
local function alphanumsort(o: {string}): {string}
    local function padnum(d: string): string
        local dec, n = string.match(d, "(%.?)0*(.+)")
        return #dec > 0 and ("%.12f" as string):format(d) or ("%s%03d%s"):format(dec, #n, n)
    end
    table.sort(o, function(a: string, b:string): boolean
      return tostring(a):gsub("%.?%d+",padnum)..("%3d"):format(#b)
           < tostring(b):gsub("%.?%d+",padnum)..("%3d"):format(#a) 
    end)
    return o
  end

local function get_list_of_files(args: display_options): {string}
    local list_of_files: {string} = {}
    local extension: string

    if args.sort == "random" then
        math.randomseed()
    end

    for _, filepath in ipairs(args.paths) do

        if path.isfile(filepath) then
            extension = path.extension(filepath)
            if validFileExtensions[extension] then
                table.insert(list_of_files, path.abspath(filepath))
            end

        elseif path.isdir(filepath) then

            if args.recursive then
                for _, file in ipairs(dir.getallfiles(filepath)) do
                    extension = path.extension(file)
                    if validFileExtensions[extension] then
                        table.insert(list_of_files, path.abspath(file))
                    end
                end 
            else
                for _, file in ipairs(dir.getfiles(filepath)) do
                    extension = path.extension(file)
                    if validFileExtensions[extension] then
                        table.insert(list_of_files, path.abspath(file))
                    end
                end        
            end

        else
            error("Could not determine if path was a file or a directory: " .. filepath)
        end
    end
    
    if #list_of_files == 0 then
        local file_formats = {}
        for k, _ in pairs(validFileExtensions) do
            table.insert(file_formats, k)
        end
        -- i should probably sort them, but the output is more fun this way
        error("Could not find any files with the following formats: " .. table.concat(file_formats, ", "))
    end
    
    if args.sort == "random" then
        for i = #list_of_files, 2, -1 do
            local j = math.random(i)
            list_of_files[i], list_of_files[j] = list_of_files[j], list_of_files[i]
        end
    elseif args.sort == "natural" then
        alphanumsort(list_of_files)
    elseif args.sort == "filename" then
        table.sort(list_of_files)
    end
    
    if args.list then
        for _, file in ipairs(list_of_files) do
            print(file)
        end
    end

    print("Found pictures to display: ", #list_of_files)

    return list_of_files

end

return get_list_of_files