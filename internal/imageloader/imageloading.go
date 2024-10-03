package imageloader

import (
	"errors"
	"fmt"
	"math"
	"os"
	"path/filepath"
	"strings"

	"github.com/davidbyttow/govips/v2/vips"
	rl "github.com/gen2brain/raylib-go/raylib"
)

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

	// GIFs are a little hacked in, but currently modify the imageData fields `ImageData` and `GifData` directly
	if extension == "gif" {
		r, err := os.Open(currentFile)
		if err != nil {
			fmt.Println("WARNING: Unable to open file", currentFile, ". Skipping for now - error: ", err.Error())
			deleteImageAtIndex(imageLoader, index)
			return getImage(imageLoader, index)
		}
		defer r.Close()

		err = loadGif(r, currentFile, imageData)
		if err != nil {
			fmt.Println("WARNING: Unable to decode image", currentFile, ". Skipping for now - error: ", err.Error())
			deleteImageAtIndex(imageLoader, index)
			return getImage(imageLoader, index)
		}
	} else {
		texture, err := loadImageByType(imageLoader, currentFile, extension)
		if err != nil {
			fmt.Println(err)
			deleteImageAtIndex(imageLoader, index)
			return getImage(imageLoader, index)
		}
		imageData.ImageData = texture
	}

	return imageData
}

func loadImageByType(imageLoader *ImageLoader, currentFile string, extension string) (*rl.Texture2D, error) {

	if imageLoader.cacheImages {
		_, cacheFile := getCacheFileLocation(imageLoader.cacheDirectory, currentFile)
		cachedImage := loadCachedImage(cacheFile)
		if cachedImage != nil {
			return cachedImage, nil
		}
	}

	var image *rl.Image
	var shouldCache bool
	var err error

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
		image, shouldCache = loadRaylib(currentFile, imageLoader)
		// TODO: get raylib error?

	default:
		image, shouldCache, err = loadVips(currentFile, imageLoader)
		if err != nil {
			errorString := "WARNING: Unable to open image " + currentFile + ". Skipping for now - error: " + err.Error()
			return nil, errors.New(errorString)
		}
	}

	texture := rl.LoadTextureFromImage(image)
	if imageLoader.cacheImages && shouldCache {
		cacheDirectory, cacheFile := getCacheFileLocation(imageLoader.cacheDirectory, currentFile)
		cacheImage(image, cacheDirectory, cacheFile)
	}
	return &texture, nil
}

func loadRaylib(filename string, imageLoader *ImageLoader) (*rl.Image, bool) {
	image := rl.LoadImage(filename)
	width := image.Width
	height := image.Height
	maxWidth := imageLoader.screenWidth
	maxHeight := imageLoader.screenHeight
	if width > maxWidth || height > maxHeight {
		scale := math.Min(float64(maxWidth)/float64(width), float64(maxHeight)/float64(height))
		newWidth := math.Min(float64(maxWidth), scale*float64(width))
		newHeight := math.Min(float64(maxHeight), scale*float64(height))
		rl.ImageResize(image, int32(newWidth), int32(newHeight))
		return image, true
	}

	return image, false
}

func loadVips(filename string, imageLoader *ImageLoader) (*rl.Image, bool, error) {
	imageRef, err := vips.NewImageFromFile(filename)
	if err != nil {
		return nil, false, err
	}

	// needed for rpi < 4 mostly. Not sure what image size an RPI 4 can technically support
	width := imageRef.Width()
	height := imageRef.Height()
	maxWidth := imageLoader.screenWidth
	maxHeight := imageLoader.screenHeight
	saveCachedImage := false

	if width > int(maxWidth) || height > int(maxHeight) {
		scale := math.Min(float64(maxWidth)/float64(width), float64(maxHeight)/float64(height))
		fmt.Println("Downsizing by ", scale)
		imageRef.Resize(scale, vips.KernelLanczos3)
		saveCachedImage = true
	}

	if imageRef.ColorSpace() != vips.InterpretationSRGB {
		err = imageRef.ToColorSpace(vips.InterpretationSRGB)
		if err != nil {
			return nil, false, err
		}
	}

	imageBytes, err := imageRef.ToBytes()
	if err != nil {
		return nil, false, err
	}

	var image *rl.Image

	if imageRef.HasAlpha() {
		image = rl.NewImage(imageBytes, int32(imageRef.Width()), int32(imageRef.Height()), 1, rl.UncompressedR8g8b8a8)
	}
	image = rl.NewImage(imageBytes, int32(imageRef.Width()), int32(imageRef.Height()), 1, rl.UncompressedR8g8b8)
	return image, saveCachedImage, nil
}

func getCacheFileLocation(cacheDirectory string, filename string) (string, string) {
	originalDirectory := filepath.Dir(filename)
	cachedDirectory := filepath.Join(cacheDirectory, originalDirectory)
	cachedFile := filepath.Join(cachedDirectory, filepath.Base(filename)+".jpg")
	return cachedDirectory, cachedFile
}

func loadCachedImage(cachedFilename string) *rl.Texture2D {
	if _, err := os.Stat(cachedFilename); err == nil {
		texture := rl.LoadTexture(cachedFilename)
		return &texture
	}
	return nil
}

func cacheImage(image *rl.Image, cacheDirectory string, cacheFilename string) {
	os.MkdirAll(cacheDirectory, 0755)
	rl.ExportImage(*image, cacheFilename)
}
