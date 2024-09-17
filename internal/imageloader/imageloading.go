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
		imageData.ImageData = loadRaylib(currentFile, imageLoader.screenWidth, imageLoader.screenHeight)
	case "gif":
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
			return GetCurrentImage(imageLoader)
		}

	default:
		texture, err := loadVips(currentFile, imageLoader.screenWidth, imageLoader.screenHeight)
		if err != nil {
			fmt.Println("WARNING: Unable to open image", currentFile, ". Skipping for now - error: ", err.Error())
			deleteImageAtIndex(imageLoader, index)
			return getImage(imageLoader, index)
		}
		imageData.ImageData = texture
	}

	return imageData
}

func loadRaylib(filename string, maxWidth int32, maxHeight int32) *rl.Texture2D {
	cachedDirectory, cachedFile, cachedImage := loadCachedImage(filename)
	if cachedImage != nil {
		return cachedImage
	}

	image := rl.LoadImage(filename)
	width := image.Width
	height := image.Height
	if width > maxWidth || height > maxHeight {
		scale := math.Min(float64(maxWidth)/float64(width), float64(maxHeight)/float64(height))
		newWidth := math.Min(float64(maxWidth), scale*float64(width))
		newHeight := math.Min(float64(maxHeight), scale*float64(height))
		rl.ImageResize(image, int32(newWidth), int32(newHeight))

		cacheImage(cachedDirectory, image, cachedFile)
	}
	texture := rl.LoadTextureFromImage(image)
	rl.UnloadImage(image)
	return &texture
}

func loadVips(filename string, maxWidth int32, maxHeight int32) (*rl.Texture2D, error) {
	cachedDirectory, cachedFile, cachedImage := loadCachedImage(filename)
	if cachedImage != nil {
		return cachedImage, nil
	}

	imageRef, err := vips.NewImageFromFile(filename)
	if err != nil {
		return nil, err
	}

	// needed for rpi < 4 mostly. Not sure what image size an RPI 4 can technically support
	width := imageRef.Width()
	height := imageRef.Height()
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
			return nil, err
		}
	}

	imageBytes, err := imageRef.ToBytes()
	if err != nil {
		return nil, err
	}

	var image *rl.Image

	if imageRef.HasAlpha() {
		image = rl.NewImage(imageBytes, int32(imageRef.Width()), int32(imageRef.Height()), 1, rl.UncompressedR8g8b8a8)
	}
	image = rl.NewImage(imageBytes, int32(imageRef.Width()), int32(imageRef.Height()), 1, rl.UncompressedR8g8b8)
	if saveCachedImage {
		cacheImage(cachedDirectory, image, cachedFile)
	}
	texture := rl.LoadTextureFromImage(image)
	// rl.UnloadImage(image) // yeah, we don't need to do this, otherwise we end up trying to free the pointer twice and the app crashes.
	return &texture, nil
}

func loadCachedImage(filename string) (string, string, *rl.Texture2D) {
	originalDirectory := filepath.Dir(filename)
	cachedDirectory := filepath.Join(".", "test", "resized", originalDirectory)
	cachedFile := filepath.Join(cachedDirectory, filepath.Base(filename)+".jpg")
	if _, err := os.Stat(cachedFile); err == nil {
		texture := rl.LoadTexture(cachedFile)
		return cachedDirectory, cachedFile, &texture
	}
	return cachedDirectory, cachedFile, nil
}

func cacheImage(cachedDirectory string, image *rl.Image, cachedFile string) {
	os.MkdirAll(cachedDirectory, 0755)
	rl.ExportImage(*image, cachedFile)
}
