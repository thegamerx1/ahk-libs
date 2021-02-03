#include <functionsahkshouldfuckinghave>
urlDecode(str) {
	while out := regex(str, "(?<=%)[\da-f]{1,2}", "i")
			str := StrReplace(str, "%" out.0, Chr("0x" out.0))
	Return str
}

urlEncode(str) {
	VarSetCapacity(Var, StrPut(str, "UTF-8"), 0)
	StrPut(str, &Var, "UTF-8")
	f := A_FormatInteger
	SetFormat IntegerFast, H
	res := ""
	While Code := NumGet(Var, A_Index - 1, "UChar")
		If (Code >= 0x30 && Code <= 0x39 ; 0-9
			|| Code >= 0x41 && Code <= 0x5A ; A-Z
			|| Code >= 0x61 && Code <= 0x7A) ; a-z
			res .= Chr(Code)
		Else
			res .= "%" SubStr(Code + 0x100, -1)
	SetFormat IntegerFast, %f%
	Return res
}

msgbox % urlEncode("✅")