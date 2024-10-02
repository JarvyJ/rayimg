//go:build rpi

package main

import (
	"errors"
	"os"
	"os/exec"
	"strconv"
	"strings"
)

func getfbsetPath() (string, error) {
	path, err := exec.LookPath("fbset")
	if err != nil {
		return "", errors.New("Not able to find fbset")
	}
	return path, nil
}

func parsefbSet(fbsetOutput string) (int32, int32) {
	split := strings.SplitN(fbsetOutput, "\n", 4)

	for _, line := range split {
		if strings.HasPrefix(line, "mode") {
			resolutionLine := strings.Split(line, " ")[1]
			resolution := strings.Split(strings.Trim(resolutionLine, "\""), "x")
			width, _ := strconv.Atoi(resolution[0])
			height, _ := strconv.Atoi(resolution[1])
			return int32(width), int32(height)
		}
	}

	return 1920, 1080
}

func getScreenResolution() (int32, int32, error) {
	path, err := getfbsetPath()
	if err != nil {
		return _, _, errors.New("Unable to find command fbset, can't determine resolution")
	}
	command := exec.Command(path, "-s")
	fullOuput, err := command.CombinedOutput()
	if err != nil {
		return _, _, errors.New("Unable to determine resolution from 'fbset -s'. Is there no mode line?")
	}
	return parsefbSet(string(fullOuput)), nil
}

func displayError(errorMessage string) {
	if !rl.IsWindowReady() {
		rl.InitWindow(1920, 1080, "rayimg - error")
	}
	font := rl.LoadFontEx("NotoSansDisplay-VariableFont_wdth,wght.ttf", int32(64), nil)
	fontPosition := rl.NewVector2(10, 10)
	for !rl.WindowShouldClose() {
		rl.BeginDrawing()
		rl.ClearBackground(rl.Black)
		rl.DrawTextEx(font, errorMessage, fontPosition, float32(font.BaseSize), 0, rl.RayWhite)
		rl.EndDrawing()
	}
	os.Exit(1)
}
