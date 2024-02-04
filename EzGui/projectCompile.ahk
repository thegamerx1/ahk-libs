#include <mustExec>
#include <EzGui>
debug.init({console: True})

if (A_Args[1]) {
	file := A_Args[1]
} else {
	FileSelectFile, file, 1, ::{20d04fe0-3aea-1069-a2d8-08002b30309d},, main html (*.html)
}

if !file
	ExitApp 1

WebDirectory := getPath(file)
SetWorkingDir % WebDirectory

html := EzGuiHelper.inject(WebDirectory)

file := FileOpen("minify/index.html", "w")
file.Write(html)
file.Close()
Debug.print("done")
ExitApp 0

#include <functionsahkshouldfuckinghave>
#include <debug>