Between(byref num, byref min, byref max) {
	return (num > max || num < min)
}
Array2String(array, delimiter := " ") {
	out := ""
	for _, v in array
		out .= v delimiter
	return out
}

ObjectMerge(array1, array2) {
	array2 := array2.clone()
	for key, value in array1 {
		array2[key] := IsObject(value) ? ObjectMerge(value, array2[key]) : value
	}

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

contains(byref string, byref object, isObject := false) {
	for key, value in object {
		data := isObject ? key : value
		if (data = string)
			return A_Index
	}
	return 0
}

killPid(pid) {
	run % "taskkill.exe /FI ""PID eq " pid """ /f",, hide
}

getPath(pathwithFile) {
	return RegExReplace(pathwithFile, "m)\w+\.\w+$")
}

regex(string, regex, flags := "") {
	RegExMatch(string, "`aO" flags ")" regex, match)
	return match
}

niceDate(ms) {
	static values := ["days", "hours", "minutes", "seconds"]
	total_seconds := floor(ms / 1000)
	total_minutes := floor(total_seconds / 60)
	total_hours := floor(total_minutes / 60)
	days := floor(total_hours / 24)
	seconds := Mod(total_seconds, 60)
	minutes := Mod(total_minutes, 60)
	hours := Mod(total_hours, 24)
	out := ""
	for _, value in values {
		if (%value% > 0)
			out .= %value% SubStr(value, 1,1) " "
	}
	return out
}

random(min:=0, max:=1) {
	if IsObject(min) {
		return min[random(1,min.length())]
	}
	Random result, Min, Max
	Return result
}

randomSeed(seed := "") {
	if !seed
		seed := random(0, 2147483647)
	random,, %seed%
}

strDiff(str,str2) {
	; ? TAKEN FROM: https://github.com/Chunjee/string-similarity.ahk
	; * Sørensen-Dice coefficient
	static oArray := {base:{__Get:Func("Abs").Bind(0)}}

	vCount := 0
	Loop % vCount1 := StrLen(str) - 1
		oArray["z" SubStr(str, A_Index, 2)]++
	Loop % vCount2 := StrLen(str2) - 1
		if (oArray["z" SubStr(str2, A_Index, 2)] > 0) {
			oArray["z" SubStr(str2, A_Index, 2)]--
			vCount++
		}

	vSDC := (2 * vCount) / (vCount1 + vCount2)

	return vSDC
}

strDiffBest(array, to) {
	best := ""
	for _, value in array {
		percent := strDiff(value, to)
		if (percent > best.percent) {
			best := {str: value, percent: percent}
		}
	}
	return best
}

strMultiply(byref str, times) {
	out := ""
	Loop % times
		out .= str
	return out
}

ClipBoardPaste(text) {
	oldclipboard := clipboard
	clipboard := ""
	clipboard := text
	ClipWait 1
	send {Ctrl down}v{Ctrl up}
	sleep 50
	clipboard := oldclipboard
}

TimeOnce(fn, time := 1000) {
	SetTimer %fn%, -%time%
}

strGetLast(str, limit) {
	out := ""
	lines := StrSplit(str, "`n", "`r")
	length := Max(lines.length()-limit, 1)
	for _, value in lines {
		if (A_Index > length)
			out .= value "`n"
	}
	return out
}

Unix2Miss(time) {
    human=19700101000000
    time-=((A_NowUTC-A_Now)//10000)*3600
    human+=%time%,Seconds
    return human
}

StartsWith(str, start) {
	return SubStr(str, 1, StrLen(start)) == start
}

;https://autohotkey.com/board/topic/80587-how-to-find-internet-connection-status/
ConnectedToInternet(flag=0x40) {
	Return DllCall("Wininet.dll\InternetGetConnectedState", "Str", flag, "Int", 0)
}

RandomString(length := 16) {
	out := ""
	loop % length
		out .= Chr(random() ? random(0x61, 0x7A) : random(0x30, 0x39))
	return out
}

TypeOf(what) {
	if IsObject(what)
		return "obj"
	if (what = false || what = true)
		return "bool"
	if regex(what, "^\d+$")
		return "int"
	if regex(what, "^\w+$")
		return "str"
	return "?"
}

reload(args) {
	run % A_AhkPath "/restart " A_ScriptDir	" " args
	ExitApp 0
}