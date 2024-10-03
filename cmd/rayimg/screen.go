//go:build !rpi

package main

func getScreenResolution() (int32, int32, error) {
	return 1920, 1080, nil
}
