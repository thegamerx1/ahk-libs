#include <socket>
#include <urlCode>
#include <base64>
#include <EzConf>

class httpServer {
	static mimetypes := {"application/atom+xml":["atom"],"application/java-archive":["jar","war","ear"],"application/mac-binhex40":["hqx"],"application/msword":["doc"],"application/octet-stream":["bin","exe","dll","deb","dmg","eot","iso","img","msi","msp","msm"],"application/pdf":["pdf"],"application/postscript":["ps","eps","ai"],"application/rss+xml":["rss"],"application/rtf":["rtf"],"application/vnd.google-earth.kml+xml":["kml"],"application/vnd.google-earth.kmz":["kmz"],"application/vnd.ms-excel":["xls"],"application/vnd.ms-powerpoint":["ppt"],"application/vnd.wap.wmlc":["wmlc"],"application/x-7z-compressed":["7z"],"application/x-cocoa":["cco"],"application/x-java-archive-diff":["jardiff"],"application/x-java-jnlp-file":["jnlp"],"application/x-javascript":["js"],"application/x-makeself":["run"],"application/x-perl":["pl","pm"],"application/x-pilot":["prc","pdb"],"application/x-rar-compressed":["rar"],"application/x-redhat-package-manager":["rpm"],"application/x-sea":["sea"],"application/x-shockwave-flash":["swf"],"application/x-stuffit":["sit"],"application/x-tcl":["tcl","tk"],"application/x-x509-ca-cert":["der","pem","crt"],"application/x-xpinstall":["xpi"],"application/xhtml+xml":["xhtml"],"application/zip":["zip"],"audio/midi":["mid","midi","kar"],"audio/mpeg":["mp3"],"audio/ogg":["ogg"],"audio/x-m4a":["m4a"],"audio/x-realaudio":["ra"],"image/gif":["gif"],"image/jpeg":["jpeg","jpg"],"image/png":["png"],"image/svg+xml":["svg","svgz"],"image/tiff":["tif","tiff"],"image/vnd.wap.wbmp":["wbmp"],"image/webp":["webp"],"image/x-icon":["ico"],"image/x-jng":["jng"],"image/x-ms-bmp":["bmp"],"text/css":["css"],"text/html":["html","htm","shtml"],"text/mathml":["mml"],"text/plain":["txt"],"text/vnd.sun.j2me.app-descriptor":["jad"],"text/vnd.wap.wml":["wml"],"text/x-component":["htc"],"text/xml":["xml"],"video/3gpp":["3gpp","3gp"],"video/mp4":["mp4"],"video/mpeg":["mpeg","mpg"],"video/quicktime":["mov"],"video/webm":["webm"],"video/x-flv":["flv"],"video/x-m4v":["m4v"],"video/x-mng":["mng"],"video/x-ms-asf":["asx","asf"],"video/x-ms-wmv":["wmv"],"video/x-msvideo":["avi"]}
	static HTTP := {100:"Continue", 101:"Switching Protocols", 103:"Checkpoint", 200:"OK", 201:"Created", 202:"Accepted", 203:"Non-Authoritative Information", 204:"No Content", 205:"Reset Content", 206:"Partial Content", 300:"Multiple Choices", 301:"Moved Permanently", 302:"Found", 303:"See Other", 304:"Not Modified", 306:"Switch Proxy", 307:"Temporary Redirect", 308:"Resume Incomplete", 400:"Bad Request", 401:"Unauthorized", 402:"Payment Required", 403:"Forbidden", 404:"Not Found", 405:"Method Not Allowed", 406:"Not Acceptable", 407:"Proxy Authentication Required", 408:"Request Timeout", 409:"Conflict", 410:"Gone", 411:"Length Required", 412:"Precondition Failed", 413:"Request Entity Too Large", 414:"Request-URI Too Long", 415:"Unsupported Media Type", 416:"Requested Range Not Satisfiable", 417:"Expectation Failed", 418:"I'm a teapot", 421:"Misdirected Request", 422:"Unprocessable Entity", 423:"Locked", 424:"Failed Dependency", 426:"Upgrade Required", 428:"Precondition Required", 429:"Too Many Requests", 431:"Request Header Fields Too Large", 451:"Unavailable For Legal Reasons", 500:"Internal Server Error", 501:"Not Implemented", 502:"Bad Gateway", 503:"Service Unavailable", 504:"Gateway Timeout", 505:"HTTP Version Not Supported", 511:"Network Authentication Required"}

	__New(parent, paths, public := false, sessions := false, isDebug := true) {
		this.parent := parent
		this.paths := []
		for _, path in paths {
			if !path.method
				path.method := "get"
			path.path := StrSplit(path.path, "/")
			if path.func
				path.func := ObjBindMethod(parent, path.func)
			this.paths.push(path)
		}

		if public {
			if !IsFolder(public)
				throw Exception("Not a valid folder", -2, public)
			this.public := public
			this.publicFull := GetFullPathName(public)
		}
		if sessions
			this.sessions := {}
		this.debug := isDebug
		this.log := debug.space("HTTP_SERV", isDebug)
	}

	serve(port := 80, ip := "localhost") {
		tcp := new SocketTCP()
		tcp.OnAccept := ObjBindMethod(this, "OnAcceptW")
		tcp.Bind([ip = "*" ? "0.0.0.0" : ip, port])
		tcp.Listen()
		this.server := tcp
		this.log("Listening on http://" ip ":" port)
	}

	setRender(folder, 2way := "") {
		static modes := ["format", "2way"]
		if !IsFolder(folder)
			throw Exception("Not a valid folder", -2, folder)
		this.render := {folder: folder, 2way: 2way}
	}

	OnAcceptW(serv) {
		try {
			this.OnAccept(serv)
		} catch e {
			this.log(e, "ERROR")
		}
	}

	getFile(file) {
		static tries := ["index.html", ".html", ".hbs"]
		temp := file
		Loop % tries.length() + 1 {
			try
				return FileRead(temp)
			temp := file tries[A_Index]
		}
		this.log("Error getting """ file """")
		return false
	}

	OnAccept(Server) {
		Sock := Server.Accept()
		request := new httpserver.request(this, Sock.RecvText())
		response := new httpserver.response(this, sock, request)

		rPath := StrSplit(request.path, "/")
		for _, path in this.paths {
			equal := true
			for i, value in path.path {
				if (rPath[i] != value) {
					if (match := regex(value, "^\{(.*)\}$")) {
						if (rPath[i] = "")
							equal := false
						else
							request.params[match.1] := rPath[i]
					} else {
						equal := false
					}
				}
			}
			if (equal && path.method = request.method) {
				if path.redirect {
					response.redirect(path.redirect)
					return
				} else {
					path.func.call(response, request)
					return
				}
			}
		}


		if (request.method != "get") {
			response.error(501)
		} else if (this.public && StartsWith(path := GetFullPathName(this.public request.path), this.publicFull)) {
			if !IsFile(this.public request.path)
				path := GetFullPathName(this.public request.path "/index.html")
			if !IsFile(path)
				return response.error(404)
			try {
				response.file(path)
			} catch e {
				debug.print(e)
			}
			return
		}

		response.error(403)
	}

	class request {
		__New(httpserv, byref data) {
			data := StrSplit(data, ["`n`n", "`r`n`r`n"],, 2)
			headers := SplitLine(data[1], 2)

			this.GetPathInfo(headers[1])
			this.get := urlCode.decodeParams(this.query)
			this.params := {}
			this.headers := urlCode.parseHeaders(headers[2])
			if InStr(this.headers["Content-Type"], "form-data") {
				boundary := "--" urlCode.parseCookies(this.headers["Content-Type"]).boundary
				this.form := urlCode.parseForm(data[2], boundary)
			} else if (inStr(this.headers["Content-Type"], "x-www-form-urlencoded")) {
				this.form := urlCode.decodeParams(data[2])
			}
			this.cookies := urlCode.parseCookies(this.headers["Cookie"])
			; httpserv.log(".received " this.cookies["session"])
			if httpserv.sessions {
				if !this.cookies["session"] {
					this.cookies["session"] := randomString(64)
				}
				if !httpserv.sessions[this.cookies["session"]]
					httpserv.sessions[this.cookies["session"]] := {}
			}
			; httpserv.log(".set " this.cookies["session"])
			this.session := httpserv.sessions[this.cookies["session"]]
			; httpserv.log(this.session)
		}

		GetPathInfo(byref top) {
			results := StrSplit(top, " ")
			path := StrSplit(urlCode.decode(results[2]), "?")

			this.method := results[1]
			this.path := path[1]
			this.query := path[2]
			this.protocol := results[3]
		}
	}

	class response {
		__New(serv, sock, request) {
			this.serv := serv
			this.sock := sock
			this.headers := {}
			this.status := 0
			this.protocol := "HTTP/1.1"
			this.mime := "text/plain"
			this.cookies := request.cookies
			this.request := request
			this.counter := new counter(, true)
		}

		redirect(to, code := 303) {
			this.redirectto := to
			this.status := code
			this.headers["Location"] := to
			this.body := to
			this._reply()
		}

		error(code) {
			this.status := code
			this._reply()
		}

		_reply() {
			if this.replied
				throw Exception("Already sent!", -2)
			this.replied := true
			this.sock.SendText(this._generate())
			this.sock.Disconnect()
			this.serv.log(this.protocol " " this.counter.get() "ms " this.request.headers["host"] " " this.status " " this.request.path " " (this.redirectto ? "-> " Truncate(this.redirectto, 80) : ""))
		}

		setMime(file) {
			SplitPath, file,,, ext
			for mime, filetype in httpServer.mimetypes {
				if contains(ext, filetype) {
					this.mime := mime
					return
				}
			}
		}

		_generate() {
			FormatTime date, %A_NowUTC%, ddd, d MMM yyyy HH:mm:ss GMT
			this.headers["Date"] := date
			this.headers["Cache-Control"] := "no-store"
			this.headers["Set-Cookie"] := urlCode.dumpCookies(this.cookies)
			this.headers["Content-Type"] := this.mime

			out := this.protocol " " this.status " " httpServer.http[this.status] "`n"
			out .= urlCode.dumpHeaders(this.headers) "`n"
			if this.body
				out .= "`n" this.body chr(0)
			return out
		}

		file(file, static := true) {
			this.headers["Cache-Control"] := "max-age=300"
			this.setMime(file)
			this.body := FileRead(file)
			this.status := 200
			this._reply()
		}

		send(text, status := 200) {
			this.body := text
			this.status := status
			this._reply()
		}

		render(name, data := "") {
			if !(render := this.serv.render)
				throw Exception("Render not set!", -2)

			file := GetFullPathName(render.folder "/" name)
			out := this.serv.getFile(file)
			this.mime := "text/html"
			if render.2way {
				2way := GetFullPathName(render.folder "/" render.2way)
				out := format(this.serv.getFile(2way), out)
			}
			this.send(format(out, JSON.dump(data)))
		}
	}
}