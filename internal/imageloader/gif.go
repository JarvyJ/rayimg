package imageloader

import (
	"fmt"
	"image"
	"image/color"
	"image/draw"
	"image/gif"
	"os"
	"unsafe"

	rl "github.com/gen2brain/raylib-go/raylib"
)

const m = 1<<16 - 1

type GifData struct {
	ImagesData [][]color.RGBA
	Delay      []int
	rawFrames  []*image.Paletted
	imgBounds  image.Rectangle
}

func newGifData(r *os.File, currentFile string, img *image.RGBA) *GifData {
	gifData := GifData{}

	r.Seek(0, 0)
	gif, err := gif.DecodeAll(r)
	if err != nil {
		fmt.Println("WARNING: Unable to decode gif", currentFile, ". Skipping for now - error: ", err.Error())
	}
	gifData.ImagesData = make([][]color.RGBA, len(gif.Image))
	gifData.rawFrames = gif.Image
	gifData.imgBounds = img.Bounds()

	// wild this saves like 4ms
	gifData.ImagesData[0] = *(*[]color.RGBA)(unsafe.Pointer(&img.Pix))
	// alternatively it would've been this:
	// for i := 0; i < len(img.Pix); i += 4 {
	// 	color := color.RGBA{img.Pix[i], img.Pix[i+1], img.Pix[i+2], img.Pix[i+3]}
	// 	gifData.ImagesData[0] = append(gifData.ImagesData[0], color)
	// }

	gifData.Delay = gif.Delay
	return &gifData
}

func loadGif(r *os.File, currentFile string, imageData *RayImgImage) error {
	rawimg, _, err := image.Decode(r)
	if err != nil {
		return err
	}

	imgBounds := rawimg.Bounds()
	img := image.NewRGBA(image.Rect(0, 0, imgBounds.Dx(), imgBounds.Dy()))
	draw.Draw(img, img.Bounds(), rawimg, imgBounds.Min, draw.Src)

	rlImage := rl.NewImageFromImage(img)
	texture := rl.LoadTextureFromImage(rlImage)
	rl.UnloadImage(rlImage)
	imageData.ImageData = &texture

	imageData.GifData = newGifData(r, currentFile, img)
	return nil
}

// use previous frame's value if outside rect and continue
// if the new pixels are transparent, use the previous frame's value
func (gifData *GifData) GetGifFrame(currentFrame int) []color.RGBA {
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
