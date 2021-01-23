#include <functionsahkshouldfuckinghave>
class requests {
	__New(url, type, data := "") {
		this.url := url
		this.type := type
		this.headers := {}
		this.data := {}
		if (data)
			this.data := data
 	}

	send() {
		; isfirst := false
		; data := ""
		; for key, value in this._data {
		; 	data .= (isfirst++ > 0) ? "&" : ""
		; 	data .= key "=" value
		; }
		this.url := (this.type = "get") ? this.url "?" data : this.url
		comobj := ComObjCreate("WinHTTP.WinHTTPRequest.5.1")
		comobj.open(this.type, this.url, false)

		for name, value in this.headers {
			comobj.SetRequestHeader(name, value)
		}

		comobj.send(this.data)
		return {status: comobj.status, statusText: comobj.statusText, text: comobj.responseText, http: comobj}
	}
}