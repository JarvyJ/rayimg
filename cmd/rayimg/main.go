package main

import (
	"flag"
	"fmt"
	"image/color"
	"math"
	"os"

	"github.com/JarvyJ/rayimg/internal/arguments"
	"github.com/JarvyJ/rayimg/internal/fileloader"
	"github.com/JarvyJ/rayimg/internal/imageloader"

	rl "github.com/gen2brain/raylib-go/raylib"
)

var args arguments.Arguments

func init() {
	flag.BoolVar(&args.Recursive, "recursive", false, "recurse into subdirectories (default false)")
	flag.StringVar(&args.Sort, "sort", "filename", "sort mode for pictures (`'filename'`, 'random', 'natural' - default 'filename')")
	flag.StringVar(&args.Display, "display", "none", "text to overlay on image (`'filename'`, 'caption', 'none' - default 'none')")
	flag.BoolVar(&args.Help, "help", false, "show all arguments")
	flag.Float64Var(&args.Duration, "duration", 0, "duration to display each image for a slideshow (`0` for always - default 0)")
	flag.Float64Var(&args.TransitionDuration, "transition-duration", 0, "length of the transition in seconds during a slideshow")
	flag.BoolVar(&args.ListFiles, "list", false, "display filepaths on terminal that will be displayed (mostly for debugging)")
}

func createTextureFromImage(texture *rl.Texture2D) (rl.Vector2, float32) {
	// Create rl.Image from Go image.Image and create texture
	rl.SetTextureFilter(*texture, rl.FilterBilinear)

	scale := float32(math.Min(float64(rl.GetScreenWidth())/float64(texture.Width), float64(rl.GetScreenHeight())/float64(texture.Height)))

	position := rl.Vector2{}
	position.X = float32(rl.GetScreenWidth()/2) - (float32(texture.Width/2) * scale)
	position.Y = float32(rl.GetScreenHeight()/2) - (float32(texture.Height/2) * scale)

	return position, scale
}

func main() {
	flag.Usage = func() {
		fmt.Fprintf(flag.CommandLine.Output(), "Usage: %s [flags] [directory or image files to display]\n", os.Args[0])

		flag.PrintDefaults()
	}

	flag.Parse()
	if args.Help {
		// gross that they don't care about order here...
		flag.Usage()
		os.Exit(0)
	}

	args.Path = flag.Args()

	switch args.Display {
	case "none":
	case "filename":
	case "caption":
	default:
		panic("The only --text-display options are 'none', 'filename', or 'caption'")
	}

	if args.TransitionDuration > float64(0) && args.Duration <= 0 {
		panic("--transition-duration can only be used when --duration is also set for slideshow purposes")
	}

	if args.TransitionDuration < float64(0) {
		panic("--transition-duration must be positive")
	}

	if args.Duration < float64(0) {
		panic("--duration must be positive")
	}

	listOfFiles := fileloader.LoadFiles(args)
	imageLoader := imageloader.New(listOfFiles)

	screenWidth := int32(1920)
	screenHeight := int32(1080)
	fontSize := 72

	rl.SetTraceLogLevel(rl.LogWarning)
	rl.SetConfigFlags(rl.FlagVsyncHint)
	rl.InitWindow(screenWidth, screenHeight, "rayimg - Image Viewer")

	screenWidth = int32(rl.GetScreenWidth())
	screenHeight = int32(rl.GetScreenHeight())

	font := rl.LoadFontEx("NotoSansDisplay-VariableFont_wdth,wght.ttf", int32(fontSize), nil)
	fontPosition := rl.NewVector2(20, float32(screenHeight)-float32(fontSize)-10)
	rl.SetTextureFilter(font.Texture, rl.FilterBilinear)

	img := imageloader.GetCurrentImage(&imageLoader)
	position, scale := createTextureFromImage(img.ImageData)

	var nextImg *imageloader.RayImgImage
	nextPosition, nextScale := rl.Vector2{}, float32(0)

	if args.TransitionDuration > 0 {
		nextImg = imageloader.PeekNextImage(&imageLoader)
		nextPosition, nextScale = createTextureFromImage(nextImg.ImageData)
	}

	timerDuration := float32(0)
	animationCurrentFrame := 0
	transitioning := false
	transitionTime := 0.0

	// helps so we only update the buffer when an image changes instead of every tick
	var drawImage = func() {
		rl.ClearBackground(rl.Black)
		rl.DrawTextureEx(*img.ImageData, position, 0, scale, rl.White)
	}

	var drawText = func() {
		if args.Display == "none" {
			return
		}
		switch args.Display {
		case "filename":
			rl.DrawRectangleGradientV(0, int32(fontPosition.Y)-int32(fontSize), screenWidth, int32(fontSize)*2+20, color.RGBA{0, 0, 0, 0}, color.RGBA{0, 0, 0, 192})
			rl.DrawTextEx(font, imageloader.GetCurrentFilename(&imageLoader), fontPosition, float32(font.BaseSize), 0, rl.RayWhite)

		case "caption":
			caption := imageloader.GetCurrentCaption(&imageLoader)
			if len(caption) > 0 {
				rl.DrawRectangleGradientV(0, int32(fontPosition.Y)-int32(fontSize), screenWidth, int32(fontSize)*2+20, color.RGBA{0, 0, 0, 0}, color.RGBA{0, 0, 0, 192})
				rl.DrawTextEx(font, imageloader.GetCurrentCaption(&imageLoader), fontPosition, float32(font.BaseSize), 0, rl.RayWhite)
			}
		}
	}

	var drawScene = func() {
		rl.BeginDrawing()
		drawImage()
		drawText()
		rl.EndDrawing()
	}

	var unloadSingleTextureAndDrawNewImage = func() {
		rl.UnloadTexture(*img.ImageData)

		img = imageloader.GetCurrentImage(&imageLoader)
		position, scale = createTextureFromImage(img.ImageData)

		transitionTime = 0
		timerDuration = 0
		transitioning = false

		drawScene()

		if img.ImageFormat == "gif" {
			animationCurrentFrame = 0
		} else {
			rl.SetTargetFPS(40)
		}
	}

	var unloadCurrentTextureAndDrawNewImage = func() {
		rl.UnloadTexture(*img.ImageData)

		imageloader.IncreaseCurrentIndex(&imageLoader)
		img = nextImg
		position, scale = nextPosition, nextScale

		nextImg = imageloader.PeekNextImage(&imageLoader)
		nextPosition, nextScale = createTextureFromImage(nextImg.ImageData)

		transitioning = false

		drawScene()

		transitionTime = 0
		timerDuration = 0

		if img.ImageFormat == "gif" {
			animationCurrentFrame = 0
		} else {
			rl.SetTargetFPS(40)
		}
	}

	for !rl.WindowShouldClose() {

		if rl.IsKeyPressed(rl.KeyRight) {
			imageloader.IncreaseCurrentIndex(&imageLoader)
			unloadSingleTextureAndDrawNewImage()
		}

		if rl.IsKeyPressed(rl.KeyLeft) {
			imageloader.DecreaseCurrentIndex(&imageLoader)
			unloadSingleTextureAndDrawNewImage()
		}

		if args.Duration > 0 {
			if timerDuration >= float32(args.Duration) {
				transitioning = true
			}
			timerDuration = timerDuration + rl.GetFrameTime()
		}

		if transitioning {
			transitionTime = transitionTime + float64(rl.GetFrameTime())
			if args.TransitionDuration == 0 {
				imageloader.IncreaseCurrentIndex(&imageLoader)
				unloadSingleTextureAndDrawNewImage()
			} else {
				opacity := 255.0 * (transitionTime / args.TransitionDuration)
				opacityint := uint8(min(opacity, 255))
				rl.BeginDrawing()
				rl.ClearBackground(rl.Black)
				rl.DrawTextureEx(*img.ImageData, position, 0, scale, color.RGBA{255, 255, 255, 255 - opacityint})
				rl.DrawTextureEx(*nextImg.ImageData, nextPosition, 0, nextScale, color.RGBA{255, 255, 255, opacityint})
				drawText()
				rl.EndDrawing()
				if transitionTime >= args.TransitionDuration {
					unloadCurrentTextureAndDrawNewImage()
				}
			}
		} else if img.ImageFormat == "gif" {

			// wildest/best/dumbest hack ever
			// basically make raylib wait the right time each frame in the gif
			rl.SetTargetFPS(int32(100 / img.GifData.Delay[animationCurrentFrame]))
			rl.UpdateTexture(*img.ImageData, imageloader.GetGifFrame(img.GifData, animationCurrentFrame))

			animationCurrentFrame = animationCurrentFrame + 1
			if animationCurrentFrame >= len(img.GifData.Delay) {
				animationCurrentFrame = 0
			}

			drawScene()

		} else {
			// need to redraw every frame otherwise the pi goes haywire (i think it's a multiple buffer thing)
			drawScene()
		}
	}

	rl.UnloadTexture(*img.ImageData)
	if nextImg != nil {
		rl.UnloadTexture(*nextImg.ImageData)
	}

	rl.CloseWindow()
}
