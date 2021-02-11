#include <functionsahkshouldfuckinghave>
class includer {
	init(pathToFolder) {
		this.list := {}
		this.file := pathToFolder "/_includer.ahk"
		FileRead extensionlist, % this.file

		checklist := ""
		Loop Files, %pathToFolder%/*.ahk, F
		{
			if (SubStr(A_LoopFileName, 1, 1) = "_")
				continue

			match := regex(A_LoopFileName, "^(?<name>\w+)\.ahk$")
			if !match.name
				throw Exception("Error on command name: " A_LoopFileName, -1)

			name := match.name
			checklist .= "#include *i " pathToFolder "/" A_LoopFIleName "`n"
			this.list[A_LoopFileName] := name
		}
		if (extensionlist != checklist) {
			file := FileOpen(this.file, "w")
			file.write(checklist)
			file.close()
			this.restart()
		}
	}

	restart() {
		Run % A_AhkPath " /restart """ A_ScriptFullPath """" Array2String(A_Args)
		ExitApp 69
	}
}