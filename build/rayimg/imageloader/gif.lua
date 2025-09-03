local ffi = require("ffi")

local rl = require("rayimg.raylib")
local imageinterface = require("rayimg.imageinterface")

ffi.cdef([[
typedef struct gif_file_tag
{
  int32_t iPos; // current file position
  int32_t iSize; // file size
  uint8_t *pData; // memory file pointer
  void * fHandle; // class pointer to File/SdFat or whatever you want
} GIFFILE;

typedef struct gif_info_tag
{
  int32_t iFrameCount; // total frames in file
  int32_t iDuration; // duration of animation in milliseconds
  int32_t iMaxDelay; // maximum frame delay
  int32_t iMinDelay; // minimum frame delay
} GIFINFO;

typedef struct gif_draw_tag
{
    int iX, iY; // Corner offset of this frame on the canvas
    int y; // current line being drawn (0 = top line of image)
    int iWidth, iHeight; // size of this frame
    int iCanvasWidth; // need this to know where to place output in a fully cooked bitmap
    void *pUser; // user supplied pointer
    uint8_t *pPixels; // 8-bit source pixels for this line
    uint16_t *pPalette; // little or big-endian RGB565 palette entries (default)
    uint8_t *pPalette24; // RGB888 palette (optional)
    uint8_t ucTransparent; // transparent color
    uint8_t ucHasTransparency; // flag indicating the transparent color is in use
    uint8_t ucDisposalMethod; // frame disposal method
    uint8_t ucBackground; // background color
    uint8_t ucPaletteType; // type of palette entries
    uint8_t ucIsGlobalPalette; // Flag to indicate that a global palette, rather than a local palette is being used
} GIFDRAW;

// Callback function prototypes
typedef int32_t (GIF_READ_CALLBACK)(GIFFILE *pFile, uint8_t *pBuf, int32_t iLen);
typedef int32_t (GIF_SEEK_CALLBACK)(GIFFILE *pFile, int32_t iPosition);
typedef void (GIF_DRAW_CALLBACK)(GIFDRAW *pDraw);
typedef void * (GIF_OPEN_CALLBACK)(const char *szFilename, int32_t *pFileSize);
typedef void (GIF_CLOSE_CALLBACK)(void *pHandle);
typedef void * (GIF_ALLOC_CALLBACK)(uint32_t iSize);
typedef void (GIF_FREE_CALLBACK)(void *buffer);

typedef struct gif_image_tag
{
    uint16_t iWidth, iHeight, iCanvasWidth, iCanvasHeight;
    uint16_t iX, iY; // GIF corner offset
    uint16_t iBpp;
    int16_t iError; // last error
    uint16_t iFrameDelay; // delay in milliseconds for this frame
    int16_t iRepeatCount; // NETSCAPE animation repeat count. 0=forever
    uint16_t iXCount, iYCount; // decoding position in image (countdown values)
    int iLZWOff; // current LZW data offset
    int iLZWSize; // current quantity of data in the LZW buffer
    int iCommentPos; // file offset of start of comment data
    short sCommentLen; // length of comment
    unsigned char bEndOfFrame;
    unsigned char ucGIFBits, ucBackground, ucTransparent, ucCodeStart, ucMap, bUseLocalPalette;
    unsigned char ucPaletteType; // RGB565 or RGB888
    unsigned char ucDrawType; // RAW or COOKED
    GIF_READ_CALLBACK *pfnRead;
    GIF_SEEK_CALLBACK *pfnSeek;
    GIF_DRAW_CALLBACK *pfnDraw;
    GIF_OPEN_CALLBACK *pfnOpen;
    GIF_CLOSE_CALLBACK *pfnClose;
    GIFFILE GIFFile;
    void *pUser;
    unsigned char *pFrameBuffer;
    unsigned char *pTurboBuffer;
    unsigned char *pPixels, *pOldPixels;
    unsigned char ucFileBuf[4096]; // holds temp data and pixel stack
    unsigned short pPalette[(256 * 3)/2]; // can hold RGB565 or RGB888 - set in begin()
    unsigned short pLocalPalette[(256 * 3)/2]; // color palettes for GIF images
    unsigned char ucLZW[1530]; // holds de-chunked LZW data
    // These next 3 are used in Turbo mode to have a larger ucLZW buffer
    unsigned short usGIFTable[4096];
    unsigned char ucGIFPixels[(4096*2)];
    unsigned char ucLineBuf[2048]; // current line
} GIFIMAGE;

typedef enum {
   GIF_PALETTE_RGB565_LE = 0, // little endian (default)
   GIF_PALETTE_RGB565_BE,     // big endian
   GIF_PALETTE_RGB888,        // original 24-bpp entries
   GIF_PALETTE_RGB8888,       // 32-bit (alpha = 0xff)
   GIF_PALETTE_1BPP,          // 1-bit per pixel (horizontal, MSB on left)
   GIF_PALETTE_1BPP_OLED      // 1-bit per pixel (vertical, LSB on top)
} PixelType;

void GIF_begin(GIFIMAGE *pGIF, unsigned char ucPaletteType);
int GIF_openFile(GIFIMAGE *pGIF, const char *szFilename, GIF_DRAW_CALLBACK *pfnDraw);
int GIF_playFrame(GIFIMAGE *pGIF, int *delayMilliseconds, void *pUser);
int GIF_getInfo(GIFIMAGE *pGIF, GIFINFO *pInfo);
void GIF_reset(GIFIMAGE *pGIF);

void *malloc( size_t size );
void free( void *ptr );
void* memcpy( void* dest, const void* src, size_t count );
]])
local animated = ffi.load("./libs/libanimatedgif.so")











local gif = {}





local GifImageLoader = {}









function gif.new(filename)
   local image = ffi.new("GIFIMAGE")
   animated.GIF_begin(image, ffi.new("PixelType", "GIF_PALETTE_RGB888"))
   local success = animated.GIF_openFile(image, filename, nil)


   if success == 1 then
      local w, h = image.iCanvasWidth, image.iCanvasHeight
      local self = setmetatable({}, { __index = gif })

      image.pFrameBuffer = ffi.C.malloc(w * h * 4)
      image.ucDrawType = 1


      self.gif_data = image
      self.width = w
      self.height = h

      return self
   end
end

function gif:advanceFrame()
   local response = animated.GIF_playFrame(self.gif_data, nil, nil)
   if response == 0 then
      animated.GIF_reset(self.gif_data)
      animated.GIF_playFrame(self.gif_data, nil, nil)
   end
   return self.gif_data.iFrameDelay
end

function gif:getFramePixels()


   return ((self.gif_data.pFrameBuffer) + (self.width * self.height))
end

function gif:__gc()
   print("Gif gc called")
   ffi.C.free(self.gif_data.pFrameBuffer)

end

function GifImageLoader.load_image_and_downsize(filename, screen_width, screen_height)

   local this_gif = gif.new(filename)

   if this_gif.width > screen_width or this_gif.height > screen_height then
      local error_message = "Your gif file is larger than your screen size and it will unfortunately not work.\nTry scaling it down to %dx%d.\nFile: %s"
      error(string.format(error_message, screen_width, screen_height, filename))
   end

   this_gif:advanceFrame()
   local image = rl.NewImage(this_gif:getFramePixels(), this_gif.width, this_gif.height, 1, rl.PixelFormat_U_R8G8B8)

   local gif_image = {
      gif = this_gif,
      image = image,
      should_cache = false,
      kind = "animation",

      get_frame_pixels = function() return this_gif:getFramePixels() end,
      advance_frame = function() return this_gif:advanceFrame() end,
   }

   return gif_image
end

return GifImageLoader
