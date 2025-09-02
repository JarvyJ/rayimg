package = "rayimg"
version = "1.0.0-1"

source = {
    url = "git://github.com/JarvyJ/rayimg.git",
    tag = "teal-conversion"
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
}

build = {
    type = "builtin",
    modules = {
        ["rayimg.arguments"] = "build/arguments.lua",
        ["rayimg.fileloader"] = "build/fileloader.lua",
        ["rayimg.imageinterface"] = "build/imageinterface.lua",
        ["rayimg.main"] = "build/main.lua",
        ["rayimg.raylib"] = "build/raylib.lua",

        -- image loader stuff
        ["rayimg.imageloader.gif"] = "build/imageloader/gif.lua",
        ["rayimg.imageloader.imagehandler"] = "build/imageloader/imagehandler.lua",
        ["rayimg.imageloader.imageloader"] = "build/imageloader/imageloader.lua",
        ["rayimg.imageloader.raylib_image"] = "build/imageloader/raylib_image.lua",
        ["rayimg.imageloader.svg"] = "build/imageloader/svg.lua",
        ["rayimg.imageloader.vips_image"] = "build/imageloader/vips_image.lua",

        -- teal libs!
        ["rayimg.libs.tinytoml"] = "build/libs/tinytoml.lua",

        -- copy in the lua libs directly
        ["rayimg.lua_libs.argparse"] = "lua_libs/argparse.lua",
        ["rayimg.lua_libs.pl.compat"] = "lua_libs/pl/compat.lua",
        ["rayimg.lua_libs.pl.path"] = "lua_libs/pl/path.lua",
        ["rayimg.lua_libs.pl.utils"] = "lua_libs/pl/utils.lua",
   },
   install = {
        bin = {
            ['rayimg'] = 'build/main.lua'
        }
    }
}

