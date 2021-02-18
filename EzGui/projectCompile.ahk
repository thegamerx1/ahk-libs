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
findScripts(html)
findCss(html)
clipboard := html
Debug.print("done")
ExitApp 0

findScripts(byref html) {
	static scripts := [A_MyDocuments "/Autohotkey/Lib/EzGui/libs/polyfill.min.js"
		,A_MyDocuments "/Autohotkey/Lib/EzGui/minify/funcs.js"
		,A_MyDocuments "/Autohotkey/Lib/EzGui/libs/webcomponents.js"
		,A_MyDocuments "/Autohotkey/Lib/EzGui/minify/titlebar.js"
		,A_MyDocuments "/Autohotkey/Lib/EzGui/libs/bootstrap.min.js"]
	static csss := [A_MyDocuments "/Autohotkey/Lib/EzGui/libs/bootstrap-dark.min.css", A_MyDocuments "/Autohotkey/Lib/EzGui/minify/default.css"]
	While match := regex(html, "\<script src=""(?<src>.+?)""\>\</script\>") {
		src := StrReplace(match.src, "file://")
		src := StrReplace(src, ".dev")
		if (src ~= "inject.js") {
			append := ""
			for _, value in scripts
				append .= "<script src=""" value """></script>"

			for _, value in csss
				append .= "<link rel=""stylesheet"" href=""" value """>"

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
}

findCss(byref html) {
	While match := regex(html, "\<link rel=""stylesheet"" href=""(?<src>.+?)\""\>") {
		src := StrReplace(match.src, "file://")
		Debug.print("replacing css " src)
		FileRead css, % src
		if !css {
			Debug.print("error")
			ExitApp 0
		}
		html := StrReplace(html, match.0, "<style>`n" css "</style>")
	}
}

#include <functionsahkshouldfuckinghave>
#include <debug>