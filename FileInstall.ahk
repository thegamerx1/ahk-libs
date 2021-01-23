getScriptResource(name, type = 10) {
	local
    lib := DllCall("GetModuleHandle", "ptr", 0, "ptr")
    res := DllCall("FindResource", "ptr", lib, "str", name, "ptr", type, "ptr")
    dataSize := DllCall("SizeofResource", "ptr", lib, "ptr", res, "uint")
    hresdata := DllCall("LoadResource", "ptr", lib, "ptr", res, "ptr")
    data := DllCall("LockResource", "ptr", hresdata, "ptr")
	if data {
		return StrGet(data, dataSize, "UTF-8")
	} else {
		msgbox % "Failed to get script resource " name
		ExitApp -1
	}
}

getCompiledFile(path) {
	if A_IsCompiled {
		data := getScriptResource(path)
	} else {
		FileRead data, %path%
	}
	return data
}