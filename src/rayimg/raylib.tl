local ffi = require("ffi")
ffi.cdef[[
void InitWindow(int width, int height, const char *title);
void CloseWindow(void);
bool WindowShouldClose(void);
void SetTargetFPS(int fps);
void BeginDrawing(void);
void EndDrawing(void);
double GetTime(void);
float GetFrameTime(void);

void SetTraceLogLevel(int logLevel);
void SetConfigFlags(unsigned int flags);

// Vector2, 2 components
typedef struct Vector2 {
    float x;                // Vector x component
    float y;                // Vector y component
} Vector2;

typedef struct Color {
    unsigned char r;        // Color red value
    unsigned char g;        // Color green value
    unsigned char b;        // Color blue value
    unsigned char a;        // Color alpha value
} Color;

// images
// Image, pixel data stored in CPU memory (RAM)
typedef struct Image {
    void *data;             // Image raw data
    int width;              // Image base width
    int height;             // Image base height
    int mipmaps;            // Mipmap levels, 1 by default
    int format;             // Data format (PixelFormat type)
} Image;

// textures
// Texture, tex data stored in GPU memory (VRAM)
typedef struct Texture {
    unsigned int id;        // OpenGL texture id
    int width;              // Texture base width
    int height;             // Texture base height
    int mipmaps;            // Mipmap levels, 1 by default
    int format;             // Data format (PixelFormat type)
} Texture;

// Texture2D, same as Texture
typedef Texture Texture2D;

// Rectangle, 4 components
typedef struct Rectangle {
    float x;                // Rectangle top-left corner position x
    float y;                // Rectangle top-left corner position y
    float width;            // Rectangle width
    float height;           // Rectangle height
} Rectangle;

// GlyphInfo, font characters glyphs info
typedef struct GlyphInfo {
    int value;              // Character value (Unicode)
    int offsetX;            // Character offset X when drawing
    int offsetY;            // Character offset Y when drawing
    int advanceX;           // Character advance position X
    Image image;            // Character image data
} GlyphInfo;

// Font, font texture and GlyphInfo array data
typedef struct Font {
    int baseSize;           // Base size (default chars height)
    int glyphCount;         // Number of glyph characters
    int glyphPadding;       // Padding around the glyph characters
    Texture2D texture;      // Texture atlas containing the glyphs
    Rectangle *recs;        // Rectangles in texture for the glyphs
    GlyphInfo *glyphs;      // Glyphs info data
} Font;

// methods we need
Image LoadImage(const char *fileName);
void ImageResize(Image *image, int newWidth, int newHeight);
void UnloadImage(Image image);
bool ExportImage(Image image, const char *fileName);

// Load font from file into GPU memory (VRAM)
Font LoadFont(const char *fileName);
// Load font from file with extended parameters, use NULL for codepoints and 0 for codepointCount to load the default character set, font size is provided in pixels height
Font LoadFontEx(const char *fileName, int fontSize, int *codepoints, int codepointCount);
void UnloadFont(Font font);
void DrawTextEx(Font font, const char *text, Vector2 position, float fontSize, float spacing, Color tint);
void DrawRectangleGradientV(int posX, int posY, int width, int height, Color top, Color bottom);

Texture2D LoadTexture(const char *fileName);
Texture2D LoadTextureFromImage(Image image);
void UpdateTexture(Texture2D texture, const void *pixels);
void UnloadTexture(Texture2D texture);
void DrawTexture(Texture2D texture, int posX, int posY, Color tint);
void DrawTextureEx(Texture2D texture, Vector2 position, float rotation, float scale, Color tint);
void SetTextureFilter(Texture2D texture, int filter);

void ClearBackground(Color color);
bool IsKeyPressed(int key);

typedef enum {
    KEY_NULL            = 0,        // Key: NULL, used for no key pressed
    KEY_RIGHT           = 262,      // Key: Cursor right
    KEY_LEFT            = 263,      // Key: Cursor left
    KEY_DOWN            = 264,      // Key: Cursor down
    KEY_UP              = 265      // Key: Cursor up
} KeyboardKey;

typedef enum {
    PIXELFORMAT_UNCOMPRESSED_GRAYSCALE = 1, // 8 bit per pixel (no alpha)
    PIXELFORMAT_UNCOMPRESSED_GRAY_ALPHA,    // 8*2 bpp (2 channels)
    PIXELFORMAT_UNCOMPRESSED_R5G6B5,        // 16 bpp
    PIXELFORMAT_UNCOMPRESSED_R8G8B8,        // 24 bpp
    PIXELFORMAT_UNCOMPRESSED_R5G5B5A1,      // 16 bpp (1 bit alpha)
    PIXELFORMAT_UNCOMPRESSED_R4G4B4A4,      // 16 bpp (4 bit alpha)
    PIXELFORMAT_UNCOMPRESSED_R8G8B8A8      // 32 bpp
} PixelFormat;

]]
local rl = ffi.load("raylib")

local record Vector2
    is ffi.CData
    x: number
    y: number
end

local record Color
    is ffi.CData
    r: integer
    g: integer
    b: integer
    a: integer
end

local record Image
    is ffi.CData
    data: ffi.CData
    width: integer
    height: integer
    mipmaps: integer
    format: integer
end

local record Texture2D
   is ffi.CData
    id: integer
    width: integer
    height: integer
    mipmaps: integer
    format: integer
end

local type PixelFormat = integer
local type KeyboardKey = integer
local type TextureFilter = integer

local record raylib
    Image: Image
    Texture2D: Texture2D
    Vector2: Vector2

    BLACK: Color
    WHITE: Color
    RAYWHITE: Color

    PixelFormat_U_R5G6B5: PixelFormat
    PixelFormat_U_R8G8B8: PixelFormat
    PixelFormat_U_R8G8B8A8: PixelFormat

    KEY_NULL: KeyboardKey
    KEY_RIGHT: KeyboardKey
    KEY_LEFT: KeyboardKey
    KEY_DOWN: KeyboardKey
    KEY_UP: KeyboardKey

    FilterBilinear: TextureFilter

    -- helpful raylib initializers
    NewColor: function(r: integer, g: integer, b: integer, a: integer): Color
    NewImage: function(data: ffi.CData, width: integer , height: integer, mipmaps: integer, format: PixelFormat): Image
    NewVector2: function(x: number, y: number): Vector2

    -- direct from raylib
    CloseWindow: function()
    WindowShouldClose: function()
    SetTargetFPS: function(integer)
    BeginDrawing: function()
    EndDrawing: function()
    GetTime: function(): number
    GetFrameTime: function(): number

    ClearBackground: function(ffi.CData)
    IsKeyPressed: function(KeyboardKey): boolean

    LoadImage: function(fileName: string): Image
    ImageResize: function(image: Image, newWidth: integer, newHeight: integer)
    UnloadImage: function(image: Image)
    ExportImage: function(image: Image, fileName: string): boolean

    LoadFont: function(fileName: string): ffi.CData
    LoadFontEx: function(fileName: string, fontSize: integer, codepoints?: integer, codepointCount: integer): ffi.CData
    UnloadFont: function(ffi.CData)
    DrawTextEx: function(font: ffi.CData, text: string, position:Vector2, fontSize: number, spacing: number, tine: Color)
    DrawRectangleGradientV: function(posX: integer, posY: integer, width: integer, height: integer, top: Color, bottom: Color)

    LoadTexture: function(fileName: string): Texture2D
    LoadTextureFromImage: function(image: Image): Texture2D
    UpdateTexture: function(texture: Texture2D, pixels: ffi.CData)
    UnloadTexture: function(Texture2D)
    DrawTexture: function(texture: Texture2D, posX: integer, posY: integer, tint: Color)
    DrawTextureEx: function(texture: Texture2D, position: Vector2,rotation: number, scale: number, tine: Color)
    SetTextureFilter: function(texture: Texture2D, filter: TextureFilter)
end

local _color: ffi.CFunction<Color> = ffi.typeof("Color")
local _pixel_format: ffi.CFunction<PixelFormat> = ffi.typeof("PixelFormat")
local _keyboard_key: ffi.CFunction<KeyboardKey> = ffi.typeof("KeyboardKey")
local _image: ffi.CFunction<Image> = ffi.typeof("Image")
local _vector2: ffi.CFunction<Vector2> = ffi.typeof("Vector2")

raylib.BLACK = _color(0, 0, 0, 0)
raylib.WHITE = _color(255, 255, 255, 255)
raylib.RAYWHITE = _color(245, 245, 245, 255)
raylib.NewColor = _color

raylib.PixelFormat_U_R5G6B5 = _pixel_format("PIXELFORMAT_UNCOMPRESSED_R5G6B5")
raylib.PixelFormat_U_R8G8B8 = _pixel_format("PIXELFORMAT_UNCOMPRESSED_R8G8B8")
raylib.PixelFormat_U_R8G8B8A8 = _pixel_format("PIXELFORMAT_UNCOMPRESSED_R8G8B8A8")

raylib.KEY_NULL  = _keyboard_key("KEY_NULL")
raylib.KEY_RIGHT = _keyboard_key("KEY_RIGHT")
raylib.KEY_LEFT  = _keyboard_key("KEY_LEFT")
raylib.KEY_DOWN  = _keyboard_key("KEY_DOWN")
raylib.KEY_UP    = _keyboard_key("KEY_UP")

raylib.FilterBilinear = 1

raylib.NewImage = _image
raylib.NewVector2 = _vector2

function raylib.init_window(width: integer, height: integer, title: string)
    rl.SetConfigFlags(0x00000040)
    rl.SetTraceLogLevel(4)
    rl.InitWindow(width, height, title)
end

setmetatable(raylib, {__index = rl})

return raylib

