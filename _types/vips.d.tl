local ffi = require("ffi")

local record vips
    cache_set_max: function(integer)
    cache_set_max_mem: function(integer)
    cache_set_max_files: function(integer)

    enum colorspace
        "srgb"
    end

    record Image
        new_from_file: function(file: string): VipsImage
        thumbnail: function(file: string, maxw: integer, options?: {string:any}): VipsImage
    end

    record VipsImage
        close: function(self)
        width: function(self): integer
        height: function(self): integer
        hasalpha: function(self): boolean
        autorot: function(self): VipsImage
        interpretation: function(self): colorspace
        resize: function(self, scale: number, options?: {string:string}): VipsImage
        colourspace: function(self, colorspace): VipsImage
        write_to_memory_ptr: function(self): ffi.CData, integer
    end
end

return vips
