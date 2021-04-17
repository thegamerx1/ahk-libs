#include <functionsahkshouldfuckinghave>
class urlCode {
	decode(str) {
		while out := regex(str, "(?<=%)[\da-f]{1,2}", "i")
				str := StrReplace(str, "%" out.0, Chr("0x" out.0))
		return str
	}

	url(byref url) {
		regex := regex(url, "((?<proto>\w+):\/{2})?(?<base>[-a-zA-Z0-9@:%._\+~#=]+\.\w+)(?<path>[^?]*)(\/?\?(?<params>([-a-zA-Z0-9()@:%_\+.~#?&=]+)))?")
		return {proto: regex.proto, base: regex.base, path: regex.path, params: this.decodeParams(regex.params)}
	}

	encode(str) {
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
		return res
	}

	encodeParams(obj, dontadd := false) {
		out := ""
		for key, value in obj {
			out .= (out ? "&" : "") key "=" this.encode(value)
		}
		if !out
			return
		return (dontadd ? "" : "?") out
	}

	decodeParams(byref str) {
		out := {}
		split := StrSplit(str, "&")
		for _, value in split {
			spl := StrSplit(value, "=",, 2)
			out[spl[1]] := this.decode(spl[2])
		}
		return out
	}

	parseHeaders(byref str) {
		out := {}
		headers := SplitLine(str)
		for key, value in headers {
			if (key = "" || value = "")
				continue
			keys := StrSplit(value, ":", " ", 2)
			out[keys[1]] := keys[2]
		}
		return out
	}

	dumpHeaders(obj) {
		out := ""
		for key, value in obj {
			out .= (out ? "`n" : "") key ": " value
		}
		return out
	}

	parseCookies(byref str) {
		out := {}
		cookies := StrSplit(str, ";", " ")
		for key, value in cookies {
			if (key = "" || value = "")
				continue
			keys := StrSplit(value, "=",, 2)
			out[keys[1]] := keys[2]
		}
		return out
	}

	dumpCookies(obj) {
		out := ""
		for key, value in obj {
			out .= (out ? "; "  : "") key "=" this.encode(value)
		}
		return out
	}

	_parseFormHeaders(byref str) {
		out := {}
		headers := StrSplit(str, ";", " ")
		name := this.parseCookies(headers[2]).name
		return SubStr(name, 2, StrLen(name)-2)
	}

	parseForm(data, byref boundary) {
		debug.print(data)
		out := {}
		while match := regex(data, boundary "\R(.*?)\R" boundary, "s") {
			data := StrReplace(data, match.0, boundary)
			parse := StrSplit(match.1, ["`n`n", "`r`n`r`n"],, 2)
			name := urlCode._parseFormHeaders(parse[1])
			out[name] := parse[2]
		}
		return out
	}
}