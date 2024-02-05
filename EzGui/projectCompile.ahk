#include <mustExec>
SetWorkingDir % A_InitialWorkingDir
debug.init({console: True})

for i, arg in A_Args {
	second_arg := A_Args[i+1]
	if (arg == "-web") {
		; folder path
		IsValid(second_arg)
		CompileWeb(second_arg)
	} else if (arg == "-includer") {
		IsValid(second_arg)
		Includer(second_arg)
	}
}
ExitApp 0

IsValid(second_arg) {
	if !second_arg {
		debug.print("Invalid parameter following " arg)
		ExitApp 1
	}
}

CompileWeb(webDirectory) {
	Debug.print("Compiling web folder " webDirectory)
	html := EzGuiHelper.inject(webDirectory)

	file := FileOpen(webDirectory "/minify/index.html", "w")
	file.Write(html)
	file.Close()
}

Includer(name) {
	Debug.print("Generating includer " name)
	gen_includer := new includer(name)
	gen_includer.generate_list()
	gen_includer.write()
}

#include <functionsahkshouldfuckinghave>
#include <debug>
#include <includer>
#include <EzGui>