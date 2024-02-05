#include <functionsahkshouldfuckinghave>
#include <FileInstall>
#include <JSON>

class includer {
	__New(folder) {
		this.folder := folder
		this.listFile := folder "/_includer.txt"
		this.includeFile := this.folder "/_includer.ahk"
	}

	generate_list() {
		local list := {}
		local checklist := "FileInstall, " this.listFile ", ~`n"

		local folder := this.folder
		Loop Files, %folder%/*.ahk, FR
		{
			if (SubStr(A_LoopFileName, 1, 1) = "_" || SubStr(getLast(A_LoopFileDir), 1, 1) = "_") {
				continue
			}

			match := regex(A_LoopFileName, "^(?<name>\w+)\.ahk$")
			if !match.name {
				throw Exception("Error on command name: " A_LoopFileName, -1)
			}

			checklist .= "#include *i " A_LoopFilePath "`n"
			list[A_LoopFileName] := {name: match.name, folder: A_LoopFileDir, path: A_LoopFilePath}
		}
		this.list := list
		this.checklist := checklist
	}

	init() {
		if A_IsCompiled {
			this.list := JSON.Load(GetScriptResource(this.folder "/_includer.txt"))
			return
		}

		this.generate_list()
		FileRead extensionlist, % this.includeFile

		if (extensionlist != this.checklist) {
			this.write()
			this.restart()
		}
	}

	write() {
		local listFile := FileOpen(this.listFile, "w")
		listFile.Write(JSON.Dump(this.list))
		listFile.Close()
		local includerFile := FileOpen(this.includeFile, "w")
		includerFile.Write(this.checklist)
		includerFile.Close()
	}

	restart() {
		;; Dont start outside of a debugger
		if !A_DebuggerName {
			Reload(Array2String(A_Args))
		}
		ExitApp 69
	}
}