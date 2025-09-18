# rayimg

rayimg is a lightweight image viewer designed to run on Raspberry Pis. It has a slideshow mode and displays via the Direct Rendering Manager (DRM) on a Raspberry Pi, so X/Wayland are not needed - this makes it nice to run on a lightweight OS! Check out my other project [PiSlide OS](https://github.com/JarvyJ/pislide-os) if interested. It supports many image formats, including more modern ones: JPG, PNG, WEBP, AVIF, JXL, HEIF, HEIC, SVG, BMP, TIFF, and QOI.

It has been built and tested on a Pi 0W, Pi 3, and Pi 4.

## Installation
rayimg is _not currently available_ as a binary. It's mostly created to be used in PiSlide OS. I might explore looking into how best to distribute it. You can always build it from source on the Pi of your choosing!

## Features
- Modern and common image formats!
- Arrow Key Navigation
- Load images from the commandline: `rayimg some-folder/image.jxl`
- Load an entire folder of images and navigate with arrow keys: `rayimg some-folder`
  - or recurse into sub folders `rayimg --recursive some-folder`
- Sorting files in a folder `rayimg --sort random some-folder`
- Support for automatically transitioning between images `rayimg --duration 3 some-folder`
  - with a cool cross-dissolve effect: `rayimg --duration 3 --transition-duration 2 some-folder`
- Support for displaying filenames or captions on screen `rayimg --display filename`
  - A captions for `example.jpg` would be next to it as  `example.jpg.txt` and can be displayed with `rayimg --display caption`

all flags and their options can be found with `rayimg --help`.

## Loading via ini files
When passing in a single folder, rayimg can load settings via a `slide_settings.ini` file that lives in that folder:
Example `slide_settings.ini`:
```ini
# duration to show each slide in seconds
Duration = 7

# how long the crossfade should happen
# can set to 0 to disable fade
TransitionDuration = 3

# set to true (without quotes) if there are sub-folders in this directory that have images to display
Recursive = false

# can be "none", "filename", or "caption" to display various text over the images
# a "caption" is simply the exact filename (including extension) with .txt on the end
# ex: The caption for bird.jpg would be in bird.jpg.txt
Display = "none"

# can be "filename", "natural", or "random"
# "natural" sorts mostly alphabetically, but tries to handle numbers correctly.
# Ex "filename": f-1.jpg, f-10.jpg, f-2.jpg
# Ex "natural": f-1.jpg, f-2.jpg, f-10.jpg
Sort = "natural"
```

## How it works
rayimg uses [raylib](https://www.raylib.com/) for rendering images on-screen, and support for some image formats. The more modern formats are supported via [libvips](https://www.libvips.org/). It's written in Teal and uses LuaJIT's FFI to interact with the shared libraries.
