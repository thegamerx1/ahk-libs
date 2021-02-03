;; ? Modified from https://github.com/G33kDude/Discord.ahk
#include <WebSocket>
#include <requests>

class Discord {
	static BaseURL := "https://discordapp.com/api/"
	reconnects := 0

	__New(parent, token, intent) {
		this.intent := intent
		this.token := token
		this.creator := parent
		this.connect()
	}

	setResume(sessionid, seq) {
		this.resumedata := {session: sessionid, seq: seq}
	}

	connect() {
		URL := this.CallAPI("GET", "gateway/bot").url
		this.ws := new WebSocket(this, URL "?v=8&encoding=json")
	}

	disconnect() {
		this.ws.disconnect()
		this.ws := ""
	}

	delete() {
		this.ws.disconnect()
		this.creator := False
	}

	CallAPI(method, endpoint, data := "") {
		http := new requests(method, this.BaseURL endpoint)

		; ? Try the request multiple times if necessary
		Loop 2 {
			http.headers["Authorization"] := "Bot " this.Token
			http.headers["Content-Type"] := "application/json"
			http.headers["User-Agent"] := "Discord.ahk"
			httpout := http.send(data ? JSON.dump(data) : "")
			httpjson := JSON.load(httpout.text)

			; * Handle rate limiting
			if (httpout.status = 429) {
				if !httpjson.retry_after
					break

				Sleep % httpjson.retry_after
				continue
			}

			break
		}

		; * Request was unsuccessful
		if (httpout.status != 200 && httpout.status != 204)
			throw Exception("Request failed: " httpout.status, -1, method " " endpoint "`n" httpout.text)

		return httpjson
	}

	; ? Sends data through the websocket
	Send(Data) {
		this.ws.send(JSON.dump(Data))
	}

	SetPresence(status, playing := "", type := 0) {
		activity := []
		if (playing)
			activity.push({name: playing, type: type})
		this.Send({
		(Join
			op: 3,
			d: {
				since: "null",
				activities: activity,
				status: status,
				afk: false
			}
		)})
	}

	SendMessage(channel_id, content) {
		msg := this.getMsg(content)
		return this.CallAPI("POST", "channels/" channel_id "/messages", msg)
	}

	getMsg(content) {
		if (content.__Class = "Discord.embed") {
			msg := content.get()
		} else {
			msg := {content: content}
		}
		return msg
	}

	EditMessage(channel_id, message_id, content) {
		msg := this.getMsg(content)
		return this.CallAPI("PATCH", "channels/" channel_id "/messages/" message_id, msg)
	}

	AddReaction(channel_id, message_id, emote) {
		return this.CallAPI("PUT", "channels/" channel_id "/messages/" message_id "/reactions/" urlEncode(emote) "/@me")
	}

	identify() {
		data := this.Send({
		(Join
			op: 2,
			d: {
				token: this.token,
				properties: {
					"$os": "windows",
					"$browser": "Discord.ahk",
					"$device": "Discord.ahk"
				},
				presence: {
					activity: [{
						name: "Starting..",
						type: 0
					}],
					status: "dnd",
					afk: false
				},
				intents: this.intent,
				compress: true,
				large_threshold: 250
			}
		)})
	}

	resume() {
		debug.print("Trying to resume with session")
		resumedata := this.resumedata
		this.Send({
		(Join
			op: 6,
			d: {
				token: this.token,
				session_id: resumedata.session,
				seq: resumedata.seq
			}
		)})
	}

	OnMessage(Event) {
		Data := JSON.load(Event.data)

		; * Save the most recent sequence number for heartbeats
		if Data.s
			this.Seq := Data.s

		if data.op != 0
			debug.print("OP: " Data.op ", " Data.t)
		this["OP" Data.op](Data)
	}

	OP10(Data) {
		this.HeartbeatACK := True
		Interval := Data.d.heartbeat_interval
		fn := ObjBindMethod(this, "SendHeartbeat")
		SetTimer %fn%, %Interval%
		; if (this.resumedata) {
			; this.resume()
		; } else {
			this.identify()
		; }
	}

	OP11(Data) { ; ? OP 11 Heartbeat ACK
		this.HeartbeatACK := True
	}

	OP9(Data) { ; ? Invalid session
		; throw Exception("Invalid session")
		if (this.reconnects > 2) {
			throw Exception("Tried to reconnect too many times", -1)
		}

		Debug.print("Attempting to reconnect to disco api")
		sleep % random(1000, 5000)
		sleep 1000
		this.identify()
	}

	OP0(Data) { ; ? OP 0 Dispatch
		fn := this.creator["E_" Data.t]
		if !fn
			Debug.print("Event not handled: " data.t)
		if (Data.t == "MESSAGE_CREATE")
			Data.d := new this.message(this, Data.d)
		if (Data.t == "READY")
			this.session_id := Data.d.session_id
		%fn%(this.creator, Data.d)
	}

	; * Called by the JS on WS error
	OnError(Event) {
		throw Exception("Unhandled Discord.ahk WebSocket Error", JSON.load(Event))
	}

	; * Called by the JS on WS close
	OnClose(reason, code := "") {
		throw Exception(reason, code)
	}
	; * Gets called periodically by a timer to send a heartbeat operation
	SendHeartbeat() {
		if !this.HeartbeatACK {
			throw Exception("Heartbeat did not respond")
			/*
				If a client does not receive a heartbeat ack between its
				attempts at sending heartbeats, it should immediately terminate
				the connection with a non 1000 close code, reconnect, and
				attempt to resume.
			*/
		}

		this.HeartbeatACK := False
		this.Send({op: 1, d: this.Seq})
	}

	class embed {
		__New(text := "") {
			this.content := text
			this.embed := {}
		}

		setEmbed(title, text, fields := "", color := "0x159af3") {
			obj := {title: title
				,description: text
				,color: format("{:u}", color)}
			if fields
				obj.fields := fields
			this.embed := obj
		}

		get() {
			return {content: this.content, embed: this.embed}
		}
	}

	class message {
		__New(api, data) {
			this.data := data
			this.api := api
			this.author := data.author
			this.guild := this.api.creator.cache.guild[data.guild_id]
		}

		react(reaction) {
			this.api.AddReaction(this.data.channel_id, this.data.id, reaction)
		}

		reply(data) {
			msg := this.api.SendMessage(this.data.channel_id, data)
			return new this.api.message(this.api, msg)
		}

		edit(data) {
			debug.print(this.data)
			this.api.EditMessage(this.data.channel_id, this.data.id, data)
		}
	}
}
