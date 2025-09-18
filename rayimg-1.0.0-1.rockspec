package = "rayimg"
version = "1.0.0-1"

source = {
    url = "git://github.com/JarvyJ/rayimg.git",
    tag = "1.0.0"
}

description = {
    summary = "rayimg is a commandline Raspberry Pi image viewer",
    detailed = [[
   rayimg is a lightweight image viewer designed to run on Raspberry Pis.
   It has a slideshow mode and displays via the Direct Rendering Manager (DRM) on a Raspberry Pi, so X/Wayland are not needed - this makes it nice to run on a lightweight OS!
   It supports many image formats, including more modern ones: JPG, PNG, WEBP, AVIF, JXL, HEIF, HEIC, SVG, BMP, TIFF, and QOI.
  ]],
    homepage = "https://github.com/JarvyJ/rayimg",
    maintainer = "Jarvy Jarvison",
    license = "AGPL"
}

dependencies = {
    "lua >= 5.1",
    "lpath == 0.4.0"
}

build = {
    type = "builtin",
    modules = {
        ["rayimg.arguments"] = "build/rayimg/arguments.lua",
        ["rayimg.fileloader"] = "build/rayimg/fileloader.lua",
        ["rayimg.imageinterface"] = "build/rayimg/imageinterface.lua",
        ["rayimg.main"] = "build/rayimg/main.lua",
        ["rayimg.raylib"] = "build/rayimg/raylib.lua",
        ["rayimg.screen"] = "build/rayimg/screen.lua",

        -- image loader stuff
        ["rayimg.imageloader.gif"] = "build/rayimg/imageloader/gif.lua",
        ["rayimg.imageloader.imagehandler"] = "build/rayimg/imageloader/imagehandler.lua",
        ["rayimg.imageloader.imageloader"] = "build/rayimg/imageloader/imageloader.lua",
        ["rayimg.imageloader.raylib_image"] = "build/rayimg/imageloader/raylib_image.lua",
        ["rayimg.imageloader.svg"] = "build/rayimg/imageloader/svg.lua",
        ["rayimg.imageloader.vips_image"] = "build/rayimg/imageloader/vips_image.lua",

        -- teal libs!
        ["rayimg.libs.tinytoml"] = "build/rayimg/libs/tinytoml.lua",

        -- copy in the lua libs directly
        ["rayimg.lua_libs.argparse"] = "lua_libs/argparse.lua",
    },
    install = {
        -- yes, this is a bit of a hack, but it puts the files in the right spot!
        -- the buildroot luarocks eval uses the host luarocks, so "rayimg" which
        -- should be in install.bin ends up with references to file paths on the
        -- host system, which isn't super useful. This at least gets the bin on the system
        lua = {
            ['rayimg.font'] = 'static/NotoSans-Regular.ttf',
            ['rayimg'] = 'static/rayimg'
        }
    }
}
