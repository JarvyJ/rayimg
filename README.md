# rayimg

rayimg is a lightweight image viewer designed to run on Raspberry Pis. It has a slideshow mode and displays via the Direct Rendering Manager (DRM) on a Raspberry Pi, so X/Wayland are not needed - this makes it nice to run on a lightweight OS! Check out my other project [PiSlide OS](https://github.com/JarvyJ/pislide-os) if interested. It supports many image formats, including more modern ones: JPG, PNG, GIF (animated!), WEBP, AVIF, JXL, HEIF, BMP, TIFF, and QOI.

It has been built and tested on a Pi 0W, Pi 3, and Pi 4.

## Installation
rayimg is _not currently available_ as a binary. It's mostly created to be used in PiSlide OS. I might explore looking into how best to distribute it, for those that want a simpler option. You can always build it from source on the Pi of your choosing!

## Features
- Modern and common image formats!
- Load images from the commandline: `rayimg some-folder/image.jxl`
- Load an entire folder of images and navigate with arrow keys: `rayimg some-folder`
  - or recurse into sub folders `rayimg --recursive some-folder`
- Sorting files in a folder `rayimg --sort random some-folder`
- Support for automatically transitioning between images `rayimg --duration 3 some-folder`
  - with a cool cross-dissolve effect: `rayimg --duration 3 --transition-duration 2 some-folder`

all flags and their options can be found with `rayimg --help`.

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
go build -tags drm github.com/JarvyJ/rayimg/cmd/rayimg
```

I've done all of my testing on Linux and Raspberry Pis, so I can't quite speak to building it on other platforms.
