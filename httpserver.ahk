#include <socket>
#include <urlCode>
#include <base64>
class httpServer {
	static mimetypes := {"application/atom+xml":["atom"],"application/java-archive":["jar","war","ear"],"application/mac-binhex40":["hqx"],"application/msword":["doc"],"application/octet-stream":["bin","exe","dll","deb","dmg","eot","iso","img","msi","msp","msm"],"application/pdf":["pdf"],"application/postscript":["ps","eps","ai"],"application/rss+xml":["rss"],"application/rtf":["rtf"],"application/vnd.google-earth.kml+xml":["kml"],"application/vnd.google-earth.kmz":["kmz"],"application/vnd.ms-excel":["xls"],"application/vnd.ms-powerpoint":["ppt"],"application/vnd.wap.wmlc":["wmlc"],"application/x-7z-compressed":["7z"],"application/x-cocoa":["cco"],"application/x-java-archive-diff":["jardiff"],"application/x-java-jnlp-file":["jnlp"],"application/x-javascript":["js"],"application/x-makeself":["run"],"application/x-perl":["pl","pm"],"application/x-pilot":["prc","pdb"],"application/x-rar-compressed":["rar"],"application/x-redhat-package-manager":["rpm"],"application/x-sea":["sea"],"application/x-shockwave-flash":["swf"],"application/x-stuffit":["sit"],"application/x-tcl":["tcl","tk"],"application/x-x509-ca-cert":["der","pem","crt"],"application/x-xpinstall":["xpi"],"application/xhtml+xml":["xhtml"],"application/zip":["zip"],"audio/midi":["mid","midi","kar"],"audio/mpeg":["mp3"],"audio/ogg":["ogg"],"audio/x-m4a":["m4a"],"audio/x-realaudio":["ra"],"image/gif":["gif"],"image/jpeg":["jpeg","jpg"],"image/png":["png"],"image/svg+xml":["svg","svgz"],"image/tiff":["tif","tiff"],"image/vnd.wap.wbmp":["wbmp"],"image/webp":["webp"],"image/x-icon":["ico"],"image/x-jng":["jng"],"image/x-ms-bmp":["bmp"],"text/css":["css"],"text/html":["html","htm","shtml"],"text/mathml":["mml"],"text/plain":["txt"],"text/vnd.sun.j2me.app-descriptor":["jad"],"text/vnd.wap.wml":["wml"],"text/x-component":["htc"],"text/xml":["xml"],"video/3gpp":["3gpp","3gp"],"video/mp4":["mp4"],"video/mpeg":["mpeg","mpg"],"video/quicktime":["mov"],"video/webm":["webm"],"video/x-flv":["flv"],"video/x-m4v":["m4v"],"video/x-mng":["mng"],"video/x-ms-asf":["asx","asf"],"video/x-ms-wmv":["wmv"],"video/x-msvideo":["avi"]}

	__New(parent, paths, public := "", sessions := false) {
		this.parent := parent
		this.paths := paths
		this.public := public
		this.publicFull := GetFullPathName(public)
		this.log := debug.space("HTTP_SERV", true)
		if sessions
			this.sessions := {}
	}

	serve(port := 80, ip := "localhost") {
		if ip = "localhost"
			ip := "0.0.0.0"
		tcp := new SocketTCP()
		tcp.OnAccept := ObjBindMethod(this, "OnAcceptW")
		tcp.Bind([ip, port])
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
		Sock := Server.Accept()
		request := new httpserver.request(this, Sock.RecvText())
		response := new httpserver.response(request)

		for _, path in this.paths {
			if (request.path = path.path && path.method = request.method) {
				if path.redirect {
					response.redirect(path.redirect)
				} else {
					ObjBindMethod(this.parent, path.func).call(response, request)
				}
				this.reply(sock, response, request)
			}
		}

		if (request.method != "get") {
			response.status := 501
			this.reply(sock, response, request)
		} else if (FileExist(path := GetFullPathName(this.public request.path)) && StartsWith(path, this.publicFull)) {
			if FileExist(this.public request.path "/index.html")
				path := GetFullPathName(this.public request.path (request.path = "/" ? "" : "/") "index.html")

			try {
				response.setRes(FileRead(path))
				response.setMime(path)
			} catch e {
				response.status := 404
				this.reply(sock, response, request)
			}
			this.reply(sock, response, request)
		}

		response.status := 404
		this.reply(sock, response, request)
	}

	reply(sock, response, request) {
		this.log(response.protocol " " response.status " " request.path " " response.mime)
		sock.SendText(response.toString())
		sock.Disconnect()
		throw Exception("", "sent")
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
					httpserv.sessions[this.cookies["session"]] := {}
				}
			}
			; httpserv.log(".set to" this.cookies["session"])
			this.session := httpserv.sessions[this.cookies["session"]]
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
		__New(request) {
			this.headers := {}
			this.status := 0
			this.protocol := "HTTP/1.1"
			this.mime := "text/plain"
			this.cookies := request.cookies
			this.setRes("")
		}

		redirect(to, code := 301) {
			this.status := code
			this.headers["Location"] := to
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

			out := this.protocol " " this.status "`n"
			out .= urlCode.dumpHeaders(this.headers) "`n"
			if this.body
				out .= "`n" this.body "`n"
			return out
		}

		setRes(text, status := 200) {
			this.body := text
			this.status := status
		}
	}
}