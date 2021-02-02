#include <functionsahkshouldfuckinghave>
class requests {
	__New(type, url) {
		this.url := url
		this.type := type
		this.headers := {"User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/88.0.4324.96 Safari/537.36"}
		this.cookies := {}
 	}

	send(data) {
		; isFirstCookie := true
		comobj := ComObjCreate("WinHTTP.WinHTTPRequest.5.1")
		comobj.open(this.type, this.url, false)
		comobj.Option(6) := false ;;Redirect

		for name, value in this.headers {
			comobj.SetRequestHeader(name, value)
		}
		; ;; TODO FIX
		; cookie := ""
		; ; for _, value in this.cookies {
		; 	; cookie .= key ""
		; 	; splitted := ()
		; 	; isFirstCookie := false
		; ; }

		comobj.send(data)
		return {status: comobj.status, statusText: comobj.statusText, text: comobj.responseText, http: comobj}
	}
}