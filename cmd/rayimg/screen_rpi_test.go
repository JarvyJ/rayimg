//go:build rpi

package main

import "testing"

func TestParseFBset(t *testing.T) {
	fbsetOutput := `
mode "1921x1080-0"
	# D: 0.000 MHz, H: 0.000 kHz, V: 0.000 Hz
	geometry 1920 1080 1920 1080 16
	timings 0 0 0 0 0 0 0
	accel false
	rgba 5/11,6/5,5/0,0/0
endmode
`
	width, height, err := parsefbSet(fbsetOutput)
	expectedWidth := int32(1921)
	expectedHeight := int32(1080)

	if err != nil {
		t.Errorf("Not able to parse fbset: %s", err.Error())
	}

	if expectedWidth != width {
		t.Errorf("Expected width '%d', but got '%d'", expectedWidth, width)
	}

	if expectedHeight != height {
		t.Errorf("Expected height '%d', but got '%d'", expectedHeight, height)
	}
}
