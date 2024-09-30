package arguments

import (
	"flag"
	"fmt"
	"os"
	"path/filepath"
	"strings"

	"github.com/BurntSushi/toml"
)

type Arguments struct {
	Path      []string
	Help      bool
	ListFiles bool
	IniSettings
}

const slideSettingsFile = "slide_settings.ini"

type IniSettings struct {
	Duration           float64
	Recursive          bool
	Sort               string
	Display            string
	TransitionDuration float64
}

func LoadIniFile(args *Arguments) {
	if len(args.Path) > 1 {
		for _, path := range args.Path {
			fileInfo, err := os.Stat(path)
			if err != nil {
				panic(err)
			}
			if fileInfo.IsDir() {
				iniLocation := filepath.Join(path, slideSettingsFile)
				if _, err := os.Stat(iniLocation); err == nil {
					fmt.Println("WARNING: Can't load slide_settings.ini if multiple directories passed in")
					return
				}
			}
		}
	}

	// defaults to current dir if args.Path not specified
	directoryToLoad, err := os.Getwd()
	if err != nil {
		fmt.Println("WARNING: Cannot get current directory. Unable to check for and load slide_settings.ini: " + err.Error())
		return
	}
	if len(args.Path) == 1 {
		directoryToLoad = args.Path[0]
	}

	iniLocation := filepath.Join(directoryToLoad, slideSettingsFile)
	if _, err := os.Stat(iniLocation); err == nil {
		iniSettings := &IniSettings{}
		// using toml to decode ini, probably not the best look.
		// but an ini file will just open on Windows/Linux for easy editing
		// also, there's only 5 settings here. I think we'll be fine (for now)
		toml.DecodeFile(iniLocation, &iniSettings)
		fmt.Println("Loading settings from ini file: ", iniLocation)

		flagset := make(map[string]bool)
		flag.Visit(func(f *flag.Flag) { flagset[strings.ToLower(f.Name)] = true })

		// set values from ini if they aren't provided via the commandline
		if !flagset["duration"] {
			args.Duration = iniSettings.Duration
		}

		if !flagset["recursive"] {
			args.Recursive = iniSettings.Recursive
		}

		if !flagset["sort"] && iniSettings.Sort != "" {
			args.Sort = iniSettings.Sort
		}

		if !flagset["display"] && iniSettings.Display != "" {
			args.Display = iniSettings.Display
		}

		if !flagset["transition-duration"] {
			args.TransitionDuration = iniSettings.TransitionDuration
		}
	}
}
