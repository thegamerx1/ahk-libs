class requests {
	__New(type, url, params := "", async := false) {
		this.url := url
		this.type := type
		this.headers := {"User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/88.0.4324.96 Safari/537.36"}
		this.cookies := {}
		this.allowredirect := false
		out := ""
		for key, value in params {
			out .= (out ? "&" : "?") key "=" value
		}
		this.url .= out
		this.async := async
 	}

	send(data := "") {
		this.com := ComObjCreate(this.async ? "Msxml2.XMLHTTP" : "WinHttp.WinHttpRequest.5.1")
		this.com.open(this.type, this.url, this.async)

		if !this.async
			this.com.Option(6) := this.allowredirect

		for name, value in this.headers
			this.com.SetRequestHeader(name, value)


		if this.async
			this.com.OnReadyStateChange := ObjBindMethod(this, "readyState")

		this.com.send(data)

		if !this.async
			return new requests_response(this)
	}

	readyState(asd := "") {
		if (this.com.readyState != 4)
			return
		this.onFinished.call(new requests_response(this))
	}

	encode(obj) {
		out := ""
		for key, value in obj {
			out .= (out ? "&" : "") key "=" value
		}
		return out
	}
}

class requests_response {
	__New(http) {
		com := http.com
		this.status := com.status
		this.statusText := com.statusText
		this.text := com.responseText
		this.headers := {}
		headers := StrSplit(com.GetAllResponseHeaders(), "`n", "`r")
		for key, value in headers {
			keys := StrSplit(value, ":", " ", 2)
			this.headers[keys[1]] := keys[2]
		}
	}

	json() {
		try {
			return JSON.load(this.text)
		} catch e {
			Throw Exception("Not json output", -1)
		}
	}
}