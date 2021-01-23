#include <mustExec>
debug.init()
if (A_Args[1]) {
	file := A_Args[1]
} else {
	FileSelectFile, file, 1, ::{20d04fe0-3aea-1069-a2d8-08002b30309d},, main html (*.html)
}
if !file
	ExitApp 1
SetWorkingDir % getPath(file)
Debug.print("Reading: " file)
FileRead html, %file%
html := findScripts(html)
html := findCss(html)
clipboard := html
Debug.print("done")
ExitApp 0

findScripts(html) {
	static scripts := [A_MyDocuments "/Autohotkey/Lib/EzGui/libs/polyfill.min.js"
		,A_MyDocuments "/Autohotkey/Lib/EzGui/minify/funcs.js"
		,A_MyDocuments "/Autohotkey/Lib/EzGui/libs/webcomponents.js"
		,A_MyDocuments "/Autohotkey/Lib/EzGui/minify/titlebar.js"
		,A_MyDocuments "/Autohotkey/Lib/EzGui/libs/bootstrap.min.js"]
	static csss := [A_MyDocuments "/Autohotkey/Lib/EzGui/libs/bootstrap-dark.min.css", A_MyDocuments "/Autohotkey/Lib/EzGui/minify/default.css"]
	While RegExMatch(html, "O`a)\<script src=""(?<src>.+?)""\>\</script\>", match) {
		src := StrReplace(match.src, "file://")
		src := StrReplace(src, ".dev")
		if (src ~= "inject.js") {
			append := ""
			for _, value in scripts {
				append .= "<link rel=""stylesheet"" href=""" value """>"
			}
			for _, value in csss {
				append .= append .= "<script src=""" value """></script>"
			}
			html := StrReplace(html, match.0, append)
			continue
		}
		Debug.print("replacing js: " src)
		FileRead js, % src
		if !js {
			Debug.print("error")
			ExitApp 0
		}
		html := StrReplace(html, match.0, "<script>`n" js "</script>")
	}
	return html
}

findCss(html) {
	While RegExMatch(html, "O`a)\<link rel=""stylesheet"" href=""(?<src>.+?)\""\>", match) {
		src := StrReplace(match.src, "file://")
		Debug.print("replacing css " src)
		FileRead css, % src
		if !css {
			Debug.print("error")
			ExitApp 0
		}
		html := StrReplace(html, match.0, "<style>`n" css "</style>")
	}
	return html
}

escapeIt(what, array) {
	for key, value in array {
		what := StrReplace(what, value, "``" value)
	}
	return what
}

#include <functionsahkshouldfuckinghave>
#include <debug>