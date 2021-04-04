Between(byref num, byref min, byref max) {
	return (num > max || num < min)
}

Array2String(array, delimiter := " ", wrap := "") {
	out := ""
	for _, v in array
		out .= (out ? delimiter : "") wrap v wrap
	return out
}

IsFile(file) {
	exist := FileExist(file)
	return (exist && !InStr("D", exist))
}

IsFolder(folder) {
	exist := FileExist(folder)
	return (exist && InStr("D", exist))
}

SplitLine(byref str, max := -1) {
	return StrSplit(str, "`n", "`r", max)
}

StripNewline(byref str) {
	return Trim(str, "`n`r")
}

Truncate(byref str, byref limit, byref ending := "..") {
	lenEnd := StrLen(ending)
	lenStr := StrLen(str)
	if (lenStr > limit-lenEnd) {
		return SubStr(str, 1, limit-lenEnd) ending
	}
	return str
}

ifNull(var, default) {
	return var ? var : default
}

getLast(str) {
	return StrSplit(str, ["/", "\"]).pop()
}

title(str) {
	return Format("{:T}", str)
}

Clone(obj) {
	cloned := obj.clone()
	for i, key in obj {
		if IsObject(key) {
			cloned[i] := clone(key)
		}
	}
	return cloned
}

ObjectMerge(array1, array2c) {
	array2 := clone(array2c)
	for key, value in array1 {
		array2[key] := (IsObject(value) && !value.base.IsArray) ? ObjectMerge(value, array2[key]) : value
	}

	return array2
}

ObjectDeep(obj, limit := 100, loop := "") {
	if !loop
		loop := 0
	for _, value in obj {
		loop++
		if IsObject(value)
			loop := ObjectDeep(value, limit, loop)

		if (loop > limit)
			return limit
	}
	return loop
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
	return false
}

killPid(pid) {
	run % "taskkill.exe /FI ""PID eq " pid """ /f",, hide
}

getPath(pathwithFile) {
	return RegExReplace(pathwithFile, "m)\w+\.\w+$")
}

regex(byref string, byref regex, flags := "") {
	RegExMatch(string, "`a`nO" flags ")" regex, match)
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
			out .= (out ? " " : "") %value% SubStr(value, 1,1)
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

strDiffBest(byref to, byref array) {
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

ClipBoardPaste(byref text) {
	oldclipboard := clipboard
	clipboard := ""
	clipboard := text
	ClipWait 1
	send {Ctrl down}v{Ctrl up}
	sleep 50
	clipboard := oldclipboard
}

SetTimer(fn, time) {
	if (time == 0)
		time = off
	SetTimer %fn%, %time%
}

TimeOnce(fn, time := 1000) {
	SetTimer(fn, -time)
}

strGetLast(str, limit) {
	out := ""
	lines := StrSplit(str, "`n", "`r")
	length := Max(lines.length()-limit, 0)
	for _, value in lines {
		if (A_Index > length)
			out .= value "`n"
	}
	return out
}

Unix2Miss(time) {
    human := 19700101000000
    time -= ((A_NowUTC-A_Now)//10000)*3600
    human += %time%,Seconds
    return human
}

StartsWith(str, start) {
	return SubStr(str, 1, StrLen(start)) = start
}

Miss2Text(miss) {
	FormatTime time, % miss, yyyy MMMM dddd HH:mm
	return time
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
	types := []
	if IsObject(what)
		types.push("obj")
	if (bool(what) != "")
		types.push("bool")
	if regex(what, "^\d+$")
		types.push("int")
	if regex(what, "^[a-z_]+$", "i")
		types.push("strAscii")
	if regex(what, "^[a-z_0-9_]+$", "i")
		types.push("str")
	return types
}

reload(args := "") {
	run % """" A_AhkPath """ /restart """ A_ScriptFullPath """ " args
	ExitApp
}

Bool(bool) {
	static truthy := ["1", "on", "true"]
	static falsy := ["0", "off", "false"]
	for _, value in truthy {
		if (bool = value)
			return true
	}
	for _, value in falsy {
		if (bool = value)
			return false
	}
	return ""
}

eval(str, context := "") {
	if !(match := regex(str, "^(?<str>[\w\.]+)(?(?=\()(?<params>\(.*)\)|)$"))
		Throw Exception("Invalid query")

	func := StrSplit(match.str, ".")
	paramstr := match.params
	isCall := StartsWith(paramstr,  "(")
	paramstr := SubStr(paramstr, 2)
	params := []
	if (paramstr) {
		while match := regex(paramstr, "^((?="")\""(?<arg>[^,""]+)\""|(?<var>(?&arg)),?\s*)") {
			if match.arg {
				params.push(match.arg)
			} else {
				params.push(match.var)
			}
			paramstr := StrReplace(paramstr, match.0,, 1)
		}
	}

	; ? function call
	if (func.length() = 1 && isCall)
		return Func(func[1]).call(params*)

	obj := func[1]
	for _, value in context {
		if (obj = value.name) {
			obj := value.val
			func.RemoveAt(1)
			break
		}
	}

	; ? global class
	if !IsObject(obj) {
		try {
			obj := %obj%
		}
	}

	; ? query
	if !isCall
		return obj[func*]

	; ? method call
	funcn := func.pop()
	if (func.length() > 0) {
		args := func.clone()
		obj := obj[args*]
	}

	if !IsObject(obj)
		return "object not found"

	return ObjBindMethod(obj, funcn).call(params*)
}

FileRead(file) {
	FileRead out, %file%
	return out
}

;; https://autohotkey.com/board/topic/76062-ahk-l-how-to-get-callstack-solution/
CallStack(deepness := 5, printLines := 1) {
	stack := ""
	loop % deepness
	{
		lvl := -2 - deepness + A_Index
		oEx := Exception("", lvl)
		oExPrev := Exception("", lvl - 1)
		FileReadLine, line, % oEx.file, % oEx.line
		if(oEx.What = lvl)
			continue
		line := "	-> " Trim(line)
		stack .= "File """ oEx.file """, Line " oEx.line (oExPrev.What = lvl-1 ? "" : ", in " oExPrev.What "()") (printLines ? ":`n" line : "") "`n"
	}
	return stack
}