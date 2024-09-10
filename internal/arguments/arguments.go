package arguments

type Arguments struct {
	Path               []string
	Duration           float64
	Recursive          bool
	Sort               string
	Help               bool
	Display            string
	TransitionDuration float64
	ListFiles          bool
}
