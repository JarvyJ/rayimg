local ffi = require("ffi")
ffi.cdef([[
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

]])
local rl = ffi.load("./libraylib.dylib")





































local raylib = {}

























































local _color = ffi.typeof("Color")
local _pixel_format = ffi.typeof("PixelFormat")
local _keyboard_key = ffi.typeof("KeyboardKey")
local _image = ffi.typeof("Image")
local _vector2 = ffi.typeof("Vector2")

raylib.BLACK = _color(0, 0, 0, 0)
raylib.WHITE = _color(255, 255, 255, 255)
raylib.RAYWHITE = _color(245, 245, 245, 255)
raylib.NewColor = _color

raylib.PixelFormat_U_R5G6B5 = _pixel_format("PIXELFORMAT_UNCOMPRESSED_R5G6B5")
raylib.PixelFormat_U_R8G8B8 = _pixel_format("PIXELFORMAT_UNCOMPRESSED_R8G8B8")
raylib.PixelFormat_U_R8G8B8A8 = _pixel_format("PIXELFORMAT_UNCOMPRESSED_R8G8B8A8")

raylib.KEY_NULL = _keyboard_key("KEY_NULL")
raylib.KEY_RIGHT = _keyboard_key("KEY_RIGHT")
raylib.KEY_LEFT = _keyboard_key("KEY_LEFT")
raylib.KEY_DOWN = _keyboard_key("KEY_DOWN")
raylib.KEY_UP = _keyboard_key("KEY_UP")

raylib.FilterBilinear = 1

raylib.NewImage = _image
raylib.NewVector2 = _vector2

function raylib.init_window(width, height, title)
   rl.SetConfigFlags(0x00000040)
   rl.SetTraceLogLevel(4)
   rl.InitWindow(width, height, title)
end

setmetatable(raylib, { __index = rl })

return raylib
