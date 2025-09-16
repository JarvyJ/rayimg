# Setting up a Pi for development
The following are required to run rayimg:
- LuaJIT and luarocks (I usually install with hererocks)
- raylib
- libvips (and the various image format libraries)

## LuaJIT + luarocks
Can be installed many different ways, I find hererocks the most convenient:
```
sudo apt-get install build-essential git
wget https://raw.githubusercontent.com/luarocks/hererocks/master/hererocks.py
python hererocks.py -r^ --luajit=@v2.1 lua
source lua/bin/activate
```

## raylib
raylib (as shipped in PiSlide OS) is installed as `PLATFORM_DRM` to not need a windowing environment:
```
sudo apt-get install libdrm-dev libegl1-mesa-dev libgles2-mesa-dev libgbm-dev
git clone --depth 1 https://github.com/raysan5/raylib.git raylib
cd raylib/src/
make PLATFORM=PLATFORM_DRM RAYLIB_LIBTYPE=SHARED
sudo make install RAYLIB_LIBTYPE=SHARED
```

See https://github.com/raysan5/raylib/wiki/Working-on-Raspberry-Pi and https://github.com/raysan5/raylib/wiki/Working-on-GNU-Linux for additional information.

## libvips
On Raspbian, you _should_ be able to just install via apt.
```
sudo apt-get install libvips-dev
```

## running rayimg

rayimg requires tl to run locally:
```
luarocks install tl
luarocks install cyan
luarocks install lpath
```

after you should be able to run:

```
tl run src/rayimg/main.tl image_directory
```
