#include <urlCode>
class requests {
	__New(type, url, params := "", async := false) {
		this.url := url
		this.type := type
		this.headers := {"User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/88.0.4324.96 Safari/537.36"}
		this.cookies := {}
		this.allowredirect := false
		this.url .= urlCode.encodeParams(params)
		this.async := async
		this.timeout := 2
 	}

	send(data := "") {
		this.com := ComObjCreate(this.async ? "Msxml2.ServerXMLHTTP.6.0" : "WinHttp.WinHttpRequest.5.1")
		try {
			this.com.open(this.type, this.url, this.async)
		} catch e {
			throw Exception("Couldn't open url", -1)
		}

		if !this.async
			this.com.Option(6) := this.allowredirect

		if (data.base.__class == "requests.FormData") {
			this.headers["Content-Type"] := "multipart/form-data; boundary=" data.boundary
			data := data.generate()
		}

		for name, value in this.headers
			this.com.SetRequestHeader(name, value)

		if this.async {
			timeout := this.timeout*1000
			this.com.setTimeouts(timeout,timeout,timeout,timeout)
			if IsObject(this.onFinished) {
				this.com.OnReadyStateChange := ObjBindMethod(this, "readyState")
			}
		}


		this.com.send(data)

		if !this.async {
			return new requests.response(this)
		}
	}

	readyState() {
		if (this.com.readyState != 4 || this.called)
			return
		this.called := true
		try {
			this.onFinished.call(new requests.response(this))
		} catch e {
			debug.print("[REQUEST] Error on a async thread")
			debug.print(e)
		}
	}
	class response {
		__New(request) {
			this.request := request
			com := request.com
			this.status := com.status
			this.statusText := com.statusText
			this.text := com.responseText
			this.headers := urlCode.parseHeaders(com.GetAllResponseHeaders())
			this.url := request.async ? com.getOption(-1) : com.Option(1)
			if request.async
				com.abort()
		}

		json() {
			try {
				return JSON.load(this.text)
			} catch e {
				Throw Exception("Not json output", -1)
			}
		}
	}

	class FormData {
		__New() {
			this.boundary := StrMultiply("-", 2) "AhkFormBoundary" RandomString(16)
			this.data := {}
		}

		set(key, value, filename := "", mime := "", disp := "") {
			obj := {name: key, val: value, mime: mime != "" ? mime : "text/plain", disp: disp != "" ? disp : "form-data"}
			if (filename != "")
				obj.file := filename
			this.data[key] := obj
		}

		get(key) {
			return this.data[key].val
		}

		generate() {
			out := ""
			for _, form in this.data {
				out .= "--" this.boundary "`nContent-Disposition: " form.disp "; name=""" form.name """"
				if form.file
					out .= "; filename=""" form.file """"
				out .= "`nContent-Type: " form.mime "`n`n" form.val "`n"
			}
			out .= "--" this.boundary "--"
			return out
		}
	}
}