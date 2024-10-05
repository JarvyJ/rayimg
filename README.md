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
rayimg uses [raylib](https://www.raylib.com/) for rendering images on-screen, and support for some image formats. The more modern formats are supported via [libvips](https://www.libvips.org/).

## Building on a Pi
rayimg is written in golang, as as such needs a modern [Go install](https://go.dev/doc/install) (unfortunately, you can't just `apt get` it, the version in the apt repositories are usually out of date).

You also need the following pacakages to build against raylib and libvips:
```
sudo apt-get install libdrm-dev libegl1-mesa-dev libgles2-mesa-dev libgbm-dev libvips-dev
```

From there, on a Raspberry Pi you can cd to the cloned repository and just `go build -tags drm github.com/JarvyJ/rayimg/cmd/rayimg` and a `rayimg` binary will be created.

## Building on other platforms
rayimg needs the following to build:
- golang: Go is supported on various platforms and installation instructions can be found on [their site](https://go.dev/doc/install).
- raylib: raylib is also supported by [multiple platforms](https://www.raylib.com/#supported-platforms)
- libvips: libvips website includes how to find in on [various platforms](https://www.libvips.org/install.html)

From there, it can be built with go:
```
go build github.com/JarvyJ/rayimg/cmd/rayimg
```

I've done all of my testing on Linux and Raspberry Pis, so I can't quite speak to building it on other platforms.

## Why `vendor`?
Since this project is pulled into a buildroot build and some of the vendor files include `.c` files, we need to include all of them since they don't get pulled in correctly with `go mod vendor`. I'm currently using [vend](https://github.com/nomad-software/vend) for this. If there's a better way, please feel free to open an issue!
