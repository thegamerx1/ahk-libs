#include <functionsahkshouldfuckinghave>
#include <FileInstall>
#include <JSON>

class includer {
	init(pathToFolder) {
		if A_IsCompiled {
			this.list := JSON.Load(GetScriptResource("_includer.txt"))
			return
		}

		this.list := {}
		this.file := pathToFolder "/_includer.ahk"
		this.listFile := "_includer.txt"
		FileRead extensionlist, % this.file

		checklist := "FileInstall, " this.listFile ", ~`n"
		Loop Files, %pathToFolder%/*.ahk, FR
		{
			if (SubStr(A_LoopFileName, 1, 1) = "_" || SubStr(getLast(A_LoopFileDir), 1, 1) = "_") {
				continue
			}

			match := regex(A_LoopFileName, "^(?<name>\w+)\.ahk$")
			if !match.name {
				throw Exception("Error on command name: " A_LoopFileName, -1)
			}

			checklist .= "#include *i " A_LoopFilePath "`n"
			this.list[A_LoopFileName] := {name: match.name, folder: A_LoopFileDir, path: A_LoopFilePath}
		}
		if (extensionlist != checklist) {
			listFile := FileOpen(this.listFile, "w")
			listFile.Write(JSON.Dump(this.list))
			listFile.Close()
			file := FileOpen(this.file, "w")
			file.Write(checklist)
			file.Close()
			this.restart()
		}
	}

	restart() {
		;; Dont start outside of a debugger
		if !A_DebuggerName {
			Reload(Array2String(A_Args))
		}
		ExitApp 69
	}
}