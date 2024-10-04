//go:build rpi

package main

import (
	"errors"
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

func parsefbSet(fbsetOutput string) (int32, int32, error) {
	split := strings.SplitN(fbsetOutput, "\n", 4)

	for _, line := range split {
		if strings.HasPrefix(line, "mode") {
			resolutionLine := strings.Split(line, " ")[1]
			resolution := strings.Split(strings.Trim(resolutionLine, "\""), "x")
			width, err := strconv.Atoi(resolution[0])
			if err != nil {
				return 0, 0, err
			}
			if strings.Contains(resolution[1], "-") {
				resolution[1] = strings.Split(resolution[1], "-")[0]
			}
			height, err := strconv.Atoi(resolution[1])
			if err != nil {
				return 0, 0, err
			}
			return int32(width), int32(height), nil
		}
	}

	return 0, 0, errors.New("Unable to determine resolution from fbset output")
}

func getScreenResolution() (int32, int32, error) {
	path, err := getfbsetPath()
	if err != nil {
		return 0, 0, errors.New("Unable to find command fbset, can't determine resolution")
	}
	command := exec.Command(path, "-s")
	fullOuput, err := command.CombinedOutput()
	if err != nil {
		return 0, 0, errors.New("Unable to determine resolution from 'fbset -s'. Is there no mode line?")
	}
	width, height, err := parsefbSet(string(fullOuput))
	if err != nil {
		return 0, 0, err
	}
	return width, height, nil
}
