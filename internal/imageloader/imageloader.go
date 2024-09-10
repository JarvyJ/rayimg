package imageloader

import (
	"errors"
	"fmt"
	"image"
	"image/color"
	"image/draw"
	"image/gif"
	"unsafe"

	"os"
	"slices"
	"strings"
	"time"

	"github.com/davidbyttow/govips/v2/vips"
	rl "github.com/gen2brain/raylib-go/raylib"
)

type ImageLoader struct {
	listOfFiles  []string
	currentIndex int
}

func New(listOfFiles []string) ImageLoader {
	imageLoader := ImageLoader{}
	imageLoader.listOfFiles = listOfFiles
	imageLoader.currentIndex = 0

	// vips.LoggingSettings(nil, vips.LogLevelWarning)
	vips.Startup(nil)
	// replace with finalizer: defer vips.Shutdown()

	return imageLoader
}

// a little hacky, but it should work for now.
// if I ever support more than just animated gifs, might need to do something different
type RayImgImage struct {
	ImageData   *rl.Texture2D
	ImageFormat string
	GifData     *GifData
}

type GifData struct {
	ImagesData [][]color.RGBA
	Delay      []int
	rawFrames  []*image.Paletted
	imgBounds  image.Rectangle
}

const m = 1<<16 - 1

func getImage(imageLoader *ImageLoader, index int) *RayImgImage {
	// unlikely, but could happen if there are a lot of corrupt images...
	if index >= len(imageLoader.listOfFiles) {
		index = 0
	}
	imageData := &RayImgImage{}

	currentFile := imageLoader.listOfFiles[index]
	if _, err := os.Stat(currentFile); errors.Is(err, os.ErrNotExist) {
		fmt.Println("WARNING: File does not exist", currentFile, ". Skipping for now - error: ", err.Error())
		deleteImageAtIndex(imageLoader, index)
		return getImage(imageLoader, index)
	}

	extension := strings.ToLower(currentFile[strings.LastIndex(currentFile, ".")+1:])
	imageData.ImageFormat = extension
	switch strings.ToLower(extension) {
	case "jpg":
		fallthrough
	case "jpeg":
		fallthrough
	case "png":
		fallthrough
	case "bmp":
		fallthrough
	case "qoi":
		imageData.ImageData = loadRaylib(currentFile)
	case "gif":
		start := time.Now()
		r, err := os.Open(currentFile)
		if err != nil {
			fmt.Println("WARNING: Unable to open file", currentFile, ". Skipping for now - error: ", err.Error())
			deleteImageAtIndex(imageLoader, index)
			return getImage(imageLoader, index)
		}
		defer r.Close()
		fmt.Println("open file", time.Now().Sub(start))

		start = time.Now()
		rawimg, _, err := image.Decode(r)
		if err != nil {
			fmt.Println("WARNING: Unable to decode image", currentFile, ". Skipping for now - error: ", err.Error())
			deleteImageAtIndex(imageLoader, index)
			return GetCurrentImage(imageLoader)
		}
		fmt.Println("decode image", time.Now().Sub(start))

		start = time.Now()
		// convert color model to RGBA
		imgBounds := rawimg.Bounds()
		img := image.NewRGBA(image.Rect(0, 0, imgBounds.Dx(), imgBounds.Dy()))
		draw.Draw(img, img.Bounds(), rawimg, imgBounds.Min, draw.Src)

		rlImage := rl.NewImageFromImage(img)
		texture := rl.LoadTextureFromImage(rlImage)
		rl.UnloadImage(rlImage)
		imageData.ImageData = &texture
		fmt.Println("convert first frame", time.Now().Sub(start))

		imageData.GifData = new(r, currentFile, img)

	default:
		texture, err := loadVips(currentFile)
		if err != nil {
			fmt.Println("WARNING: Unable to open image", currentFile, ". Skipping for now - error: ", err.Error())
			deleteImageAtIndex(imageLoader, index)
			return getImage(imageLoader, index)
		}
		imageData.ImageData = texture
	}

	return imageData
}

func loadVips(filename string) (*rl.Texture2D, error) {
	imageRef, err := vips.NewImageFromFile(filename)
	if err != nil {
		return nil, err
	}

	if imageRef.ColorSpace() != vips.InterpretationSRGB {
		err = imageRef.ToColorSpace(vips.InterpretationSRGB)
		if err != nil {
			return nil, err
		}
	}

	imageBytes, err := imageRef.ToBytes()
	if err != nil {
		return nil, err
	}

	if imageRef.HasAlpha() {
		image := rl.NewImage(imageBytes, int32(imageRef.Width()), int32(imageRef.Height()), 1, rl.UncompressedR8g8b8a8)
		texture := rl.LoadTextureFromImage(image)
		return &texture, nil
	}
	image := rl.NewImage(imageBytes, int32(imageRef.Width()), int32(imageRef.Height()), 1, rl.UncompressedR8g8b8)
	texture := rl.LoadTextureFromImage(image)
	// rl.UnloadImage(image) // yeah, we don't need to do this, otherwise we end up trying to free the pointer twice and the app crashes.
	return &texture, nil
}

func loadRaylib(filename string) *rl.Texture2D {
	texture := rl.LoadTexture(filename)
	return &texture
}

func new(r *os.File, currentFile string, img *image.RGBA) *GifData {
	gifData := &GifData{}

	start := time.Now()
	r.Seek(0, 0)
	gif, err := gif.DecodeAll(r)
	if err != nil {
		fmt.Println("WARNING: Unable to decode gif", currentFile, ". Skipping for now - error: ", err.Error())
	}
	gifData.ImagesData = make([][]color.RGBA, len(gif.Image))
	gifData.rawFrames = gif.Image
	gifData.imgBounds = img.Bounds()
	fmt.Println("decode frame and setup", time.Now().Sub(start))

	start = time.Now()

	// wild this saves like 4ms
	gifData.ImagesData[0] = *(*[]color.RGBA)(unsafe.Pointer(&img.Pix))

	// for i := 0; i < len(img.Pix); i += 4 {
	// 	color := color.RGBA{img.Pix[i], img.Pix[i+1], img.Pix[i+2], img.Pix[i+3]}
	// 	gifData.ImagesData[0] = append(gifData.ImagesData[0], color)
	// }

	fmt.Println("convert first frame", time.Now().Sub(start))

	gifData.Delay = gif.Delay
	return gifData
}

// use previous frame's value if outside rect and continue
// if the new pixels are transparent, use the previous frame's value
func GetGifFrame(gifData *GifData, currentFrame int) []color.RGBA {
	if len(gifData.ImagesData[currentFrame]) == 0 {
		gifData.ImagesData[currentFrame] = make([]color.RGBA, len(gifData.ImagesData[currentFrame-1]))
		copy(gifData.ImagesData[currentFrame], gifData.ImagesData[currentFrame-1])
		rawFrame := gifData.rawFrames[currentFrame]
		pixelCount := 0
		for y := 0; y < gifData.imgBounds.Dy(); y++ {
			for x := 0; x < gifData.imgBounds.Dx(); x++ {

				if !(image.Point{x, y}.In(rawFrame.Rect)) {
					pixelCount++
					continue
				}
				pixIndex := rawFrame.PixOffset(x, y)
				pixColor := rawFrame.Palette[rawFrame.Pix[pixIndex]]

				r32, g32, b32, a32 := pixColor.RGBA()
				r, g, b, a := uint8(r32), uint8(g32), uint8(b32), uint8(a32)

				if a == 0 {
					pixelCount++
					continue
				}

				sr := uint32(r) * 0x101
				sg := uint32(g) * 0x101
				sb := uint32(b) * 0x101
				sa := uint32(a) * 0x101

				prgba := gifData.ImagesData[currentFrame-1][(y*gifData.imgBounds.Dx() + x)]
				dr := prgba.R
				dg := prgba.G
				db := prgba.B
				da := prgba.A

				alpha := (m - sa) * 0x101
				nr := uint8((uint32(dr)*alpha/m + sr) >> 8)
				ng := uint8((uint32(dg)*alpha/m + sg) >> 8)
				nb := uint8((uint32(db)*alpha/m + sb) >> 8)
				na := uint8((uint32(da)*alpha/m + sa) >> 8)
				color := color.RGBA{nr, ng, nb, na}
				gifData.ImagesData[currentFrame][pixelCount] = color

				pixelCount++
			}
		}
	}
	return gifData.ImagesData[currentFrame]
}

func deleteImageAtIndex(imageLoader *ImageLoader, index int) {
	imageLoader.listOfFiles = slices.Delete(imageLoader.listOfFiles, index, index+1)
	numberOfFiles := len(imageLoader.listOfFiles)
	if numberOfFiles == 0 {
		panic("Could not open any of the found files. See above in log for details. Images potentially corrupt or incompatible formats")
	}
	imageLoader.currentIndex = imageLoader.currentIndex - 1
	IncreaseCurrentIndex(imageLoader)
}

func GetCurrentImage(imageLoader *ImageLoader) *RayImgImage {
	start := time.Now()
	rayimage := getImage(imageLoader, imageLoader.currentIndex)
	fmt.Println("Time to decode: ", time.Now().Sub(start), imageLoader.listOfFiles[imageLoader.currentIndex])
	return rayimage
}

func GetCurrentFilename(imageLoader *ImageLoader) string {
	filePath := imageLoader.listOfFiles[imageLoader.currentIndex]
	splitPath := strings.Split(filePath, "/")
	return splitPath[len(splitPath)-1]
}

func GetCurrentCaption(imageLoader *ImageLoader) string {
	filePath := imageLoader.listOfFiles[imageLoader.currentIndex]
	captionPath := filePath + ".txt"
	captionData, err := os.ReadFile(captionPath)
	if err != nil {
		return ""
	}
	return strings.TrimSpace(string(captionData))
}

func IncreaseCurrentIndex(imageLoader *ImageLoader) {
	numberOfFiles := len(imageLoader.listOfFiles)
	if imageLoader.currentIndex+1 >= numberOfFiles {
		imageLoader.currentIndex = 0
	} else {
		imageLoader.currentIndex = imageLoader.currentIndex + 1
	}
}

func DecreaseCurrentIndex(imageLoader *ImageLoader) {
	if imageLoader.currentIndex <= 0 {
		imageLoader.currentIndex = len(imageLoader.listOfFiles) - 1
	} else {
		imageLoader.currentIndex = imageLoader.currentIndex - 1
	}
}

func PeekNextImage(imageLoader *ImageLoader) *RayImgImage {
	nextImageIndex := imageLoader.currentIndex + 1
	numberOfFiles := len(imageLoader.listOfFiles)
	if nextImageIndex >= numberOfFiles {
		nextImageIndex = 0
	}
	start := time.Now()
	img := getImage(imageLoader, nextImageIndex)
	fmt.Println("Time to decode: ", time.Now().Sub(start), imageLoader.listOfFiles[imageLoader.currentIndex])
	return img
}

func PeekPreviousImage(imageLoader *ImageLoader) *RayImgImage {
	previousImageIndex := imageLoader.currentIndex - 1
	if previousImageIndex <= 0 {
		previousImageIndex = len(imageLoader.listOfFiles) - 1
	}
	return getImage(imageLoader, previousImageIndex)
}
