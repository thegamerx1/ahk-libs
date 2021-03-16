#include <socket>
#include <urlCode>
#include <base64>
#include <EzConf>

class httpServer {
	static mimetypes := {"application/atom+xml":["atom"],"application/java-archive":["jar","war","ear"],"application/mac-binhex40":["hqx"],"application/msword":["doc"],"application/octet-stream":["bin","exe","dll","deb","dmg","eot","iso","img","msi","msp","msm"],"application/pdf":["pdf"],"application/postscript":["ps","eps","ai"],"application/rss+xml":["rss"],"application/rtf":["rtf"],"application/vnd.google-earth.kml+xml":["kml"],"application/vnd.google-earth.kmz":["kmz"],"application/vnd.ms-excel":["xls"],"application/vnd.ms-powerpoint":["ppt"],"application/vnd.wap.wmlc":["wmlc"],"application/x-7z-compressed":["7z"],"application/x-cocoa":["cco"],"application/x-java-archive-diff":["jardiff"],"application/x-java-jnlp-file":["jnlp"],"application/x-javascript":["js"],"application/x-makeself":["run"],"application/x-perl":["pl","pm"],"application/x-pilot":["prc","pdb"],"application/x-rar-compressed":["rar"],"application/x-redhat-package-manager":["rpm"],"application/x-sea":["sea"],"application/x-shockwave-flash":["swf"],"application/x-stuffit":["sit"],"application/x-tcl":["tcl","tk"],"application/x-x509-ca-cert":["der","pem","crt"],"application/x-xpinstall":["xpi"],"application/xhtml+xml":["xhtml"],"application/zip":["zip"],"audio/midi":["mid","midi","kar"],"audio/mpeg":["mp3"],"audio/ogg":["ogg"],"audio/x-m4a":["m4a"],"audio/x-realaudio":["ra"],"image/gif":["gif"],"image/jpeg":["jpeg","jpg"],"image/png":["png"],"image/svg+xml":["svg","svgz"],"image/tiff":["tif","tiff"],"image/vnd.wap.wbmp":["wbmp"],"image/webp":["webp"],"image/x-icon":["ico"],"image/x-jng":["jng"],"image/x-ms-bmp":["bmp"],"text/css":["css"],"text/html":["html","htm","shtml"],"text/mathml":["mml"],"text/plain":["txt"],"text/vnd.sun.j2me.app-descriptor":["jad"],"text/vnd.wap.wml":["wml"],"text/x-component":["htc"],"text/xml":["xml"],"video/3gpp":["3gpp","3gp"],"video/mp4":["mp4"],"video/mpeg":["mpeg","mpg"],"video/quicktime":["mov"],"video/webm":["webm"],"video/x-flv":["flv"],"video/x-m4v":["m4v"],"video/x-mng":["mng"],"video/x-ms-asf":["asx","asf"],"video/x-ms-wmv":["wmv"],"video/x-msvideo":["avi"]}
	static HTTP := {100:"Continue", 101:"Switching Protocols", 103:"Checkpoint", 200:"OK", 201:"Created", 202:"Accepted", 203:"Non-Authoritative Information", 204:"No Content", 205:"Reset Content", 206:"Partial Content", 300:"Multiple Choices", 301:"Moved Permanently", 302:"Found", 303:"See Other", 304:"Not Modified", 306:"Switch Proxy", 307:"Temporary Redirect", 308:"Resume Incomplete", 400:"Bad Request", 401:"Unauthorized", 402:"Payment Required", 403:"Forbidden", 404:"Not Found", 405:"Method Not Allowed", 406:"Not Acceptable", 407:"Proxy Authentication Required", 408:"Request Timeout", 409:"Conflict", 410:"Gone", 411:"Length Required", 412:"Precondition Failed", 413:"Request Entity Too Large", 414:"Request-URI Too Long", 415:"Unsupported Media Type", 416:"Requested Range Not Satisfiable", 417:"Expectation Failed", 418:"I'm a teapot", 421:"Misdirected Request", 422:"Unprocessable Entity", 423:"Locked", 424:"Failed Dependency", 426:"Upgrade Required", 428:"Precondition Required", 429:"Too Many Requests", 431:"Request Header Fields Too Large", 451:"Unavailable For Legal Reasons", 500:"Internal Server Error", 501:"Not Implemented", 502:"Bad Gateway", 503:"Service Unavailable", 504:"Gateway Timeout", 505:"HTTP Version Not Supported", 511:"Network Authentication Required"}

	__New(parent, paths, public := "", sessions := false, isDebug := true) {
		this.parent := parent
		this.paths := paths
		this.public := public
		this.publicFull := GetFullPathName(public)
		this.log := debug.space("HTTP_SERV", isDebug)
		this.debug := isDebug
		this.cache := {}
		if sessions
			this.sessions := {}
	}

	serve(port := 80, ip := "localhost") {
		tcp := new SocketTCP()
		tcp.OnAccept := ObjBindMethod(this, "OnAcceptW")
		tcp.Bind([ip = "localhost" ? "0.0.0.0" : ip, port])
		tcp.Listen()
		this.server := tcp
		this.log("Listening on http://" ip ":" port)
	}

	OnAcceptW(serv) {
		try {
			this.OnAccept(serv)
		} catch e {
			if e.what = "sent"
				return
			throw e
		}
	}

	OnAccept(Server) {
		static defaultpath := {method: "GET"}
		Sock := Server.Accept()
		request := new httpserver.request(this, Sock.RecvText())
		response := new httpserver.response(this, sock, request)

		for _, path in this.paths {
			path := EzConf(path, defaultpath)
			if (request.path = path.path && path.method = request.method) {
				if path.redirect {
					response.redirect(path.redirect)
					return
				} else {
					ObjBindMethod(this.parent, path.func).call(response, request)
					return
				}
			}
		}

		if (request.method != "get") {
			response.error(501)
		} else if (this.public && FileExist(path := GetFullPathName(this.public request.path)) && StartsWith(path, this.publicFull)) {
			if FileExist(this.public request.path "/index.html")
				path := GetFullPathName(this.public request.path (request.path = "/" ? "" : "/") "index.html")
			try {
				if (!this.cache[path] || this.debug) {
					this.cache[path] := FileRead(path)
				}
				response.setMime(path)
				response.setRes(this.cache[path])
				return
			} catch e {
				response.error(404)
				return
			}
		}

		response.error(404)
	}

	class request {
		__New(httpserv, byref data) {
			data := StrSplit(data, "`n`n")
			headers := SplitLine(data[1], 2)
			this.body := data[2]

			this.GetPathInfo(headers[1])
			this.query := urlCode.decodeParams(this.query)
			this.headers := urlCode.parseHeaders(headers[2])
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
			this.body := code " " httpServer.http[code]
			this._reply()
		}

		_reply() {
			if this.replied
				throw Exception("Already sent!", -2)
			this.replied := true
			this.serv.log(this.protocol " " this.request.headers["host"] " " this.status " " this.request.path " " (this.redirectto ? "-> " this.redirectto : ""))
			this.sock.SendText(this.toString())
			this.sock.Disconnect()
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

		toString() {
			if !this.headers["Date"] {
				FormatTime date,, ddd, d MMM yyyy HH:mm:ss
				this.headers["Date"] := date
			}
			this.headers["Set-Cookie"] := urlCode.dumpCookies(this.cookies)

			out := this.protocol " " this.status " " httpServer.http[this.status] "`n"
			out .= urlCode.dumpHeaders(this.headers) "`n"
			if this.body
				out .= "`n" this.body chr(0)
			return out
		}

		setRes(text, status := 200) {
			this.body := text
			this.status := status
			this._reply()
		}
	}
}