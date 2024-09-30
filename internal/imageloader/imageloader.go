package imageloader

import (
	"fmt"

	"os"
	"slices"
	"strings"
	"time"

	"github.com/davidbyttow/govips/v2/vips"
	rl "github.com/gen2brain/raylib-go/raylib"
)

type ImageLoader struct {
	listOfFiles    []string
	currentIndex   int
	screenHeight   int32
	screenWidth    int32
	cacheImages    bool
	cacheDirectory string
}

func New(listOfFiles []string, screenWidth int32, screenHeight int32) ImageLoader {
	imageLoader := ImageLoader{}
	imageLoader.listOfFiles = listOfFiles
	imageLoader.currentIndex = 0
	imageLoader.screenWidth = screenWidth
	imageLoader.screenHeight = screenHeight

	imageLoader.cacheDirectory, imageLoader.cacheImages = os.LookupEnv("CACHE_DIR")

	vips.LoggingSettings(nil, vips.LogLevelWarning)
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
