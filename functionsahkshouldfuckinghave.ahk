numDiff(a, b) {
	return round((min(a,b) / max(a,b)) * 100)
}

isNull(var) {
	if (var = "" || !IsObject(var))
		return true
}

Array2String(array) {
	result := ""
	for index, value in array
		result .= value " "
	return result
}

ObjectMerge(array1, array2) {
	for key, value in array1
		array2[key] := value

	return array2
}

GetFullPathName(path) {
	cc := DllCall("GetFullPathName", "str", path, "uint", 0, "ptr", 0, "ptr", 0, "uint")
	VarSetCapacity(buf, cc*(A_IsUnicode?2:1))
	DllCall("GetFullPathName", "str", path, "uint", cc, "str", buf, "ptr", 0, "uint")
	return buf
}

InRegion(x, y ,x1, y1, x2, y2) {
	return (x >= x1) && (x <= x2) && (y >= y1) && (y <= y2)
}

ListBoxGetRow(value, column := 1) {
	Loop % LV_GetCount()
	{
		LV_GetText(text, A_Index, column)
		if (text = name)
			break
	}
	return A_Index
}

contains(object, string, reverse := false) {
	for key, value in object {
		data := (reverse) ? key : value
		if (data = string)
			return A_Index
	}
	return 0
}

ifIn(var,matchlist){
    if var in %matchlist%
        return 1
}

killPid(pid) {
	run % "taskkill.exe /FI ""PID eq " pid """ /f",, hide
}

getPath(pathwithFile) {
	return RegExReplace(pathwithFile, "m)\w+\.\w+$")
}