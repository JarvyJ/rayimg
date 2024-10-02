//go:build !rpi

package main

import (
	"fmt"
	"os"
)

func getScreenResolution() (int32, int32, error) {
	return 1920, 1080, nil
}

func displayError(errorMessage string) {
	fmt.Println(errorMessage)
	os.Exit(1)
}
