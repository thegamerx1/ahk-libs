numDiff(a, b) {
	return round((min(a,b) / max(a,b)) * 100)
}

isNull(var) {
	if (var = "" || !IsObject(var))
		return true
}

Array2String(array, delimiter := " ") {
	out := ""
	for _, v in array
		out .= v delimiter
	return out
}

ObjectMerge(array1, array2) {
	array2 := array2.clone()
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

;https://gist.github.com/Uberi/5987142
Ping(Address, Timeout := 800) {
	data := length := 0
	if DllCall("LoadLibrary","Str","ws2_32","UPtr") = 0
		throw Exception("Could not load WinSock 2 library")
	if DllCall("LoadLibrary","Str","icmp","UPtr") = 0
		throw Exception("Could not load ICMP library")

	NumericAddress := DllCall("ws2_32\inet_addr","AStr", Address, "UInt")
	if NumericAddress = 0xFFFFFFFF ;INADDR_NONE
		throw Exception("Invalid IP")

	hPort := DllCall("icmp\IcmpCreateFile","UPtr") ;open port
	if hPort = -1 ;INVALID_HANDLE_VALUE
		throw Exception("Could not open port")

	StructLength := 270 + (A_PtrSize * 2) ;ICMP_ECHO_REPLY structure
	VarSetCapacity(Reply,StructLength)
	Count := DllCall("icmp\IcmpSendEcho"
		,"UPtr",hPort ;ICMP handle
		,"UInt",NumericAddress ;IP address
		,"UPtr",&Data ;request data
		,"UShort",Length ;length of request data
		,"UPtr",0 ;pointer to IP options structure
		,"UPtr",&Reply ;reply buffer
		,"UInt",StructLength ;length of reply buffer
		,"UInt",Timeout) ;ping timeout
	;IP_BUF_TOO_SMALL
	if NumGet(Reply,4,"UInt") = 11001 {
		StructLength *= Count
		VarSetCapacity(Reply,StructLength)
		DllCall("icmp\IcmpSendEcho"
			,"UPtr",hPort ;ICMP handle
			,"UInt",NumericAddress ;IP address
			,"UPtr",&Data ;request data
			,"UShort",Length ;length of request data
			,"UPtr",0 ;pointer to IP options structure
			,"UPtr",&Reply ;reply buffer
			,"UInt",StructLength ;length of reply buffer
			,"UInt",Timeout) ;ping timeout
	}

	if !DllCall("icmp\IcmpCloseHandle","UInt", hPort) ;close port
		throw Exception("Could not close port")

	if contains(Status, [11002,11003,11004,11005,11010]) {
		Return -1
	}

	if NumGet(Reply,4,"UInt") != 0 ;IP_SUCCESS
		throw Exception("Could not send echo")

	Return NumGet(Reply, 8, "UInt")
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
	if regex(what, "\d+")
		return "int"
	if regex(what, "\w+")
		return "str"
	return "?"
}