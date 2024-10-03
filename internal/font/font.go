package font

/*
#include "../../vendor/github.com/gen2brain/raylib-go/raylib/raylib.h"
#include "NotoSansDisplay.h"
#include <stdlib.h>
*/
import "C"

import (
	"unsafe"

	rl "github.com/gen2brain/raylib-go/raylib"
)

// newFontFromPointer - Returns new Font from pointer
func newFontFromPointer(ptr unsafe.Pointer) rl.Font {
	return *(*rl.Font)(ptr)
}

// LoadFont - Load a Font image into GPU memory (VRAM)
func LoadFont() rl.Font {
	ret := C.LoadFont_NotoSansDisplay()
	v := newFontFromPointer(unsafe.Pointer(&ret))
	return v
}
