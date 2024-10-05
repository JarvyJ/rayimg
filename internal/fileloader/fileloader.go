package fileloader

import (
	"errors"
	"fmt"
	"io/fs"
	"math/rand"
	"os"
	"path/filepath"
	"sort"
	"strings"

	"github.com/JarvyJ/rayimg/internal/arguments"
)

var validFileExtensions = []string{".jpg", ".png", ".jpeg", ".webp", ".avif", ".jxl", ".heif", ".heic", ".svg", ".bmp", ".tiff", ".tif", ".qoi"}
var validFileExtensionsSet = make(map[string]bool)

func validFileByExtension(path string) bool {
	extensionIndex := strings.LastIndex(path, ".")
	if extensionIndex > 0 {
		extension := strings.ToLower(path[extensionIndex:])
		return validFileExtensionsSet[extension]
	}
	return false
}

func getListOfFiles(unknownPath string, recursive bool) ([]string, error) {
	path, _ := filepath.Abs(unknownPath)
	var listOfFiles = []string{}

	fileInfo, err := os.Stat(path)
	if err != nil {
		return nil, errors.New("Unable to open path: " + path + "\n" + err.Error())
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
				return nil, errors.New("Can't read the directory: " + path + "\n" + err.Error())
			}
			for _, file := range files {
				if !file.IsDir() && validFileByExtension(file.Name()) {
					listOfFiles = append(listOfFiles, filepath.Join(path, file.Name()))
				}
			}
		}
	} else {
		if recursive {
			return nil, errors.New("Can only use --recursive when the path is a directory")
		}

		validFileExtension := validFileByExtension(path)
		if validFileExtension {
			listOfFiles = append(listOfFiles, path)
		}
	}

	return listOfFiles, nil
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
	}

}

func LoadFiles(arguments arguments.Arguments) ([]string, error) {
	for _, fileExtension := range validFileExtensions {
		validFileExtensionsSet[fileExtension] = true
	}

	listOfFiles := []string{}
	if len(arguments.Path) == 0 {
		workingDirectory, err := os.Getwd()
		if err != nil {
			return nil, errors.New("Unable to get the current working directory. You should specify a working directory at the end of your cli arguments. See rayimg -h for more info. Error: " + err.Error())
		}
		listOfFiles, err = getListOfFiles(workingDirectory, arguments.Recursive)
		if err != nil {
			return nil, errors.New(err.Error())
		}
	} else {
		for _, path := range arguments.Path {
			moreFiles, err := getListOfFiles(path, arguments.Recursive)
			if err != nil {
				return nil, errors.New(err.Error())
			}
			listOfFiles = append(listOfFiles, moreFiles...)
		}
	}

	if len(listOfFiles) == 0 {
		return nil, errors.New("Could not find any files with the following formats: " + strings.Join(validFileExtensions, ", "))
	}

	fmt.Println("Found pictures to display: ", len(listOfFiles))

	sortListOfFiles(arguments.Sort, listOfFiles)

	if arguments.ListFiles {
		for _, filepath := range listOfFiles {
			fmt.Println(filepath)
		}
	}

	return listOfFiles, nil
}
