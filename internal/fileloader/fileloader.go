package fileloader

import (
	"fmt"
	"io/fs"
	"math/rand"
	"os"
	"path/filepath"
	"sort"
	"strings"

	"github.com/JarvyJ/rayimg/internal/arguments"
)

var validFileExtensions = []string{".jpg", ".png", ".jpeg", ".webp", ".gif", ".avif", ".jxl", ".heif", ".bmp", ".tiff", ".tif", ".qoi"}
var validFileExtensionsSet = make(map[string]bool)

func validFileByExtension(path string) bool {
	extension := strings.ToLower(path[strings.LastIndex(path, "."):])
	return validFileExtensionsSet[extension]
}

func getListOfFiles(path string, recursive bool) []string {
	var listOfFiles = []string{}

	fileInfo, err := os.Stat(path)
	if err != nil {
		panic(err)
	}

	customwalk := func(path string, d fs.DirEntry, err error) error {
		if !d.IsDir() && validFileByExtension(path) {
			listOfFiles = append(listOfFiles, path)
		}
		return nil
	}

	if fileInfo.IsDir() {
		if recursive {
			filepath.WalkDir(path, customwalk)
		} else {
			files, err := os.ReadDir(path)
			if err != nil {
				panic(err)
			}
			for _, file := range files {
				if !file.IsDir() && validFileByExtension(file.Name()) {
					listOfFiles = append(listOfFiles, filepath.Join(path, file.Name()))
				}
			}
		}
	} else {
		if recursive {
			panic("Can only use --recursive when the path is a directory")
		}

		validFileExtension := validFileByExtension(path)
		if validFileExtension {
			listOfFiles = append(listOfFiles, path)
		}
	}

	return listOfFiles
}

func sortListOfFiles(sortBy string, files []string) {
	switch sortBy {

	case "filename":
		sort.Slice(files, func(i, j int) bool {
			return files[i] < files[j]
		})

	case "natural":
		Sort(files)

	case "random":
		for i := range files {
			j := rand.Intn(i + 1)
			files[i], files[j] = files[j], files[i]
		}

	default:
		panic("The only --sort options are 'filename', 'natural', and 'random'")
	}
}

func LoadFiles(arguments arguments.Arguments) []string {
	for _, fileExtension := range validFileExtensions {
		validFileExtensionsSet[fileExtension] = true
	}

	listOfFiles := []string{}
	if len(arguments.Path) == 0 {
		workingDirectory, err := os.Getwd()
		if err != nil {
			panic("Unable to get the current working directory. You should specify a working directory at the end of your cli arguments. See rayimg -h for more info. Error: " + err.Error())
		}
		listOfFiles = getListOfFiles(workingDirectory, arguments.Recursive)
	} else {
		for _, path := range arguments.Path {
			listOfFiles = append(listOfFiles, getListOfFiles(path, arguments.Recursive)...)
		}
	}

	if len(listOfFiles) == 0 {
		panic("Could not find any files with the following formats: " + strings.Join(validFileExtensions, ", "))
	}

	fmt.Println("Found pictures to display: ", len(listOfFiles))

	sortListOfFiles(arguments.Sort, listOfFiles)

	if arguments.ListFiles {
		for _, filepath := range listOfFiles {
			fmt.Println(filepath)
		}
	}

	return listOfFiles
}
