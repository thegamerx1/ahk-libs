;; ? Modified from https://github.com/G33kDude/Discord.ahk
#include <WebSocket>
#include <requests>

class Discord {
	static OPCode := {0: "Dispatch"
					,1: "Heartbeat"
					,2: "Identify"
					,3: "PresenceUpdate"
					,4: "VoiceStateUpdate"
					,5: ""
					,6: "Resume"
					,7: "Reconnect"
					,8: "RequestGuildMembers"
					,9: "InvalidSession"
					,10: "Hello"
					,11: "HeartbeatACK"}
	static BaseURL := "https://discord.com/api/"
	reconnects := 0

	__New(parent, token, intent, owner_guild := "") {
		this.intent := intent
		this.token := token
		this.owner_guild := owner_guild
		this.creator := parent
		this.emojis := []
		this.connect()
		this.cache := {guild:{}, user:{}, dm:{}, msg:{}}
	}

	setMirror(func) {
		this.mirror := func
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
			httpjson := httpout.json()

			; * Handle rate limiting
			if (httpout.status = 429) {
				if !httpjson.retry_after
					break

				sleep % httpjson.retry_after
				continue
			}

			break
		}

		; * Request was unsuccessful
		if (httpout.status != 200 && httpout.status != 204) {
			throw Exception(httpout.status, "request " method " " endpoint, httpout.text)
		}

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
		this.Send({op: 3, d: {since: "null", activities: activity, status: status, afk: false}})
	}

	SendMessage(channel_id, content) {
		msg := this.getMsg(content)
		if (StrLen(msg.content) > 2000)
			Throw Exception("Message too long", -1)
		return this.CallAPI("POST", "channels/" channel_id "/messages", msg)
	}

	getMsg(content) {
		if (content.__Class = "Discord.embed") {
			msg := content.get()
		} else {
			if StrLen(content) > 2000
				Throw Exception("Message too long", -2)
			msg := {content: content}
		}
		return msg
	}

	ISODATE(str) {
		match := regex(str, "(?<YYYY>\d{4})-?(?<MM>\d{2})-?(?<DD>\d{2})T?(?<HH>\d{2}):?(?<MI>\d{2}):?(?<SS>\d{2}(?<SD>.\d+)?)\+?(?<TZ>\d{2}:\d{2})?")
		return match.YYYY match.MM  match.DD  match.HH  match.MI  match.SS ;  match.SD
	}

	GetMessage(channel, message) {
		if !this.cache.msg[channel][message] {
			if !this.cache.msg[channel]
				this.cache.msg[channel] := {}
			this.cache.msg[channel][message] := this.callAPI("GET", "channels/" channel "/messages/" message)
		}
		return new this.message(this, this.cache.msg[channel][message])
	}

	EditMessage(channel_id, message_id, content) {
		msg := this.getMsg(content)
		return this.CallAPI("PATCH", "channels/" channel_id "/messages/" message_id, msg)
	}

	AddReaction(channel, id, emote) {
		if RegExMatch(emote, "^[\w#@$\?\[\]\x80-\xFF]+$")
			emote .= ":" this.emojis[emote]
		return this.CallAPI("PUT", "channels/" channel "/messages/" id "/reactions/" urlEncode(emote) "/@me")
	}

	RemoveReaction(channel, id, emote) {
		if RegExMatch(emote, "^[\w#@$\?\[\]\x80-\xFF]+$")
			emote .= ":" this.emojis[emote]
		return this.CallAPI("DELETE", "channels/" channel "/messages/" id "/reactions/" urlEncode(emote) "/@me")
	}

	TypingIndicator(channel) {
		return this.CallAPI("POST", "channels/" channel "/typing")
	}

	BulkDelete(channel, messages) {
		return this.CallAPI("POST" , "channels/" channel "/messages/bulk-delete", messages)
	}

	getRole(guild, id) {
		for i, role in this.cache.guild[guild].roles {
			if (role.id = id) {
				return this.cache.guild[data.d.guild_id].roles[i]
			}
		}
	}

	DeleteMessage(channel, message) {
		return this.CallAPI("DELETE" , "channels/" channel "/messages/" message)
	}

	CreateDM(usrid) {
		if !this.cache.dm[usrid]
			this.cache.dm[usrid] := this.CallAPI("POST", "users/@me/channels", {recipient_id: usrid})
		return this.cache.dm[usrid]
	}

	changeSelfNick(guild, nick) {
		this.CallAPI("PATCH", "guilds/" guild "/members/@me/nick", {nick: nick})
	}

	getUser(usrid) {
		if !this.cache.user[usrid]
			this.cache.user[usrid] := this.CallAPI("GET", "users/" usrid)
		return this.cache.user[usrid]
	}

	SendHeartbeat() {
		if !this.HeartbeatACK
			throw Exception("Heartbeat did not respond")

		this.HeartbeatACK := False
		this.Send({op: 1, d: this.Seq})
		; debug.print("Heartbeat sent")
	}

	GetMoji(name) {
		return "<:" name ":" this.emojis[name] ">"
	}

	getMember(guild, id) {
		if !this.cache.guild[guild].members[id] {
			data := this.getGuildMember(guild, id)
			this.cache.guild[guild].members[id] := data
		}
		return this.cache.guild[guild].members[id]
	}

	getGuildMember(guild, id) {
		return this.CallAPI("GET", "guilds/" guild "/members/" id)
	}

	updateMember(guild, id, member) {
		this.cache.guild[guild].members[id] := member
	}

	sanitize(str) {
		return StrReplace(str, "``", chr(8203) "``")
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
		this.Send({op: 6, d: {token: this.token, session_id: resumedata.session, seq: resumedata.seq}})
		this.resumedata := ""
	}

	/*
		? OP HANDLING
	*/

	OP_HELLO(Data) {
		this.HeartbeatACK := True
		Interval := Data.d.heartbeat_interval
		fn := ObjBindMethod(this, "SendHeartbeat")
		SetTimer %fn%, % Interval
		Debug.print("Heartbeating every " Interval "ms")
		if (this.resumedata) {
			this.resume()
		} else {
			this.identify()
		}
	}

	OP_HEARTBEATACK(Data) {
		this.HeartbeatACK := True
	}

	OP_INVALIDSESSION(Data) {
		Debug.print("Attempting to reidentify to disco api")
		sleep % random(1000, 5000)
		this.identify()
	}

	OP_Dispatch(Data) {
		switch data.t {
			case "MESSAGE_CREATE":
				Data.d := new this.message(this, Data.d)
			case "READY":
				this.session_id := Data.d.session_id
				this.user_id := Data.d.user.id
				this.user_name := Data.d.user.username
				return
			case "MESSAGE_REACTION_ADD":
				if data.d.user_id == this.user_id
					return
				data.d := new this.reaction(this, data.d)
			case "GUILD_CREATE":
				this.cache.guild[data.d.id] := data.d
				if (data.d.id = this.owner_guild) {
					for key, value in this.cache.guild[data.d.id].emojis
						this.emojis[value.name] := value.id
					fn := ObjBindMethod(this, "dispatch", "READY", data.d)
					SetTimer %fn%, -50
				}
			case "GUILD_ROLE_UPDATE":
				role := this.getRole(data.d.guild_id, role.id)
				role := data.d.role
			case "GUILD_ROLE_CREATE":
				this.cache.guild[data.d.guild_id].roles.push(data.d.role)
			case "GUILD_UPDATE":
				this.cache.guild[data.d.guild_id] := data.d
			case "GUILD_ROLE_DELETE":
				for i, role in this.cache.guild[data.d.guild_id].roles {
					if (role.id = data.d.role_id) {
						this.cache.guild[data.d.guild_id].roles.removeAt(i)
						break
					}
				}
		}

		this.dispatch(data.t, data.d)
	}

	dispatch(event, data) {
		debug.print(Event)
		fn := ObjBindMethod(this.creator, "E_" event)
		fn.call(data)
		if !fn
			Debug.print("Event not handled: " event)
		if this.mirror
			this.mirror.call(event, Data)
	}

	/*
		? Websocket
	*/

	OnMessage(Event) {
		Data := JSON.load(Event.data)

		; * Save the most recent sequence number for heartbeats
		if Data.s
			this.Seq := Data.s

		opname := this.OPCode[data.op]
		if data.op != 0
			debug.print(opname)

		this["OP_" opname](Data)
	}

	OnError(reason := "", code := "") {
		debug.print(format("Errpr, {},: {}", code, reason))
		throw Exception(reason, code)
	}


	OnClose(reason := "", code := "") {
		debug.print(format("Closed, {},: {}", code, reason))
		if (code = 1001 || code = 1000) {
			this.disconnect()
			this.setResume(this.session_id, this.seq)
			this.connect()
			return
		}
		throw Exception(reason, code)
	}


	/*
		? Constructors
	*/

	class paginator {
		__New(content, limit := 1950) {
			content := discord.sanitize(content)
			this.pages := []
			lines := StrSplit(content, "`n", "`r")
			temp := ""
			for _, value in lines {
				if StrLen(temp value) > limit {
					this.pages.push(temp)
					temp := ""
				}
				temp .= value "`n"
			}
			this.pages.push(temp)
		}
	}

	class embed {
		__New(title := "", content := "", color := "0x159af3") {
			if StrLen(title) > 256
				Throw Exception("Embed title too long", -1)
			if StrLen(content) > 2048
				Throw Exception("Embed description too long", -1)

			this.embed := {title: title
				,description: content
				,color: format("{:u}", color)
				,fields: []}
		}

		setContent(byref str) {
			if StrLen(str) > 1990
				Throw Exception("Content too long", -1)
			if StrLen(Str) == 0
				return
			this.content := str
		}

		setUrl(url) {
			this.embed.url := url
		}

		setAuthor(name, icon_url := "") {
			if StrLen(name) > 256
				Throw Exception("Author name too long", -1)
			this.embed.author := {name: name, icon_url: icon_url}
		}

		setFooter(text, icon_url := "") {
			if StrLen(text) > 2048
				Throw Exception("Footer text too long", -1)
			this.embed.footer := {text: text, icon_url: icon_url}
		}

		setTimestamp(time) {
			this.embed.timestamp := time
		}

		setImage(img) {
			this.embed.image := {url: img}
		}

		setThumbnail(img) {
			this.embed.image := {url: img}
		}

		addField(title, content, inline := false) {
			if StrLen(title) > 256
				Throw Exception("Field title too long", -1)
			if StrLen(content) > 1024
				Throw Exception("Field content too long", -1)

			if (StrLen(content) == 0 || StrLen(title) == 0)
				return

			this.embed.fields.push({name: title, value: content, inline: inline})
		}

		get(webhook := false) {
			if (webhook)
				return {content: this.content, embeds: [this.embed]}
			return {content: this.content, embed: this.embed}
		}
	}

	class author {
		static permissionlist := {ADD_REACTIONS: 0x00000040, ADMINISTRATOR: 0x00000008, ATTACH_FILES: 0x00008000, BAN_MEMBERS: 0x00000004, CHANGE_NICKNAME: 0x04000000, CONNECT: 0x00100000, CREATE_INSTANT_INVITE: 0x00000001, DEAFEN_MEMBERS: 0x00800000, EMBED_LINKS: 0x00004000, KICK_MEMBERS: 0x00000002, MANAGE_CHANNELS: 0x00000010, MANAGE_EMOJIS: 0x40000000, MANAGE_GUILD: 0x00000020, MANAGE_MESSAGES: 0x00002000, MANAGE_NICKNAMES: 0x08000000, MANAGE_ROLES: 0x10000000, MANAGE_WEBHOOKS: 0x20000000, MENTION_EVERYONE: 0x00020000, MOVE_MEMBERS: 0x01000000, MUTE_MEMBERS: 0x00400000, PRIORITY_SPEAKER: 0x00000100, READ_MESSAGE_HISTORY: 0x00010000, SEND_MESSAGES: 0x00000800, SEND_TTS_MESSAGES: 0x00001000, SPEAK: 0x00200000, STREAM: 0x00000200, USE_EXTERNAL_EMOJIS: 0x00040000, USE_VAD: 0x02000000, VIEW_AUDIT_LOG: 0x00000080, VIEW_CHANNEL: 0x00000400, VIEW_GUILD_INSIGHTS: 0x00080000}

		__New(api, data, guild, member := "") {
			this.api := api
			this.data := data
			this.id := data.id
			this.bot := data.bot
			this.name := data.username
			this.guild := guild
			this.discriminator := data.discriminator
			this.mention := "<@" data.id ">"
			this.avatar := "https://cdn.discordapp.com/avatars/" this.id "/" data.avatar ".png"
			if guild {
				if !member {
					member := api.getMember(guild.id, this.id)
				}
				this.member := member
				api.updateMember(guild.id, this.id, member)
				this.roles := member.roles
				this.roles.push(guild.id)
				this.permissions := []
				for _, value in this.roles {
					for key, flag in this.permissionlist {
						if this.hasPermission(flag)
							this.permissions.push(key)
					}
				}
			}
		}

		sendDM(content) {
			channel := this.api.createDM(this.id)
			this.api.SendMessage(channel.id, content)
		}

		get(userid) {
			return new discord.author(this.api, this.api.getUser(userid), this.guild)
		}

		notMention() {
			return this.name "@" this.discriminator
		}

		hasPermission(name) {
			return (this.author.permissions & this.permissionslist[name]) == this.permissionslist[name]
		}
	}

	class guild {
		__New(api, id) {
			this.api := api
			this.data := this.api.cache.guild[id]
			this.name := this.data.name
			this.id := this.data.id
			this.owner := this.data.owner_id
			this.region := this.data.region
		}
	}

	class reaction {
		__New(api, data) {
			this.api := api
			this.data := data
			this.guild := new discord.guild(api, data.guild_id)
			this.author := new discord.author(api, data.member.user, this.guild)
			this.message := data.message_id
			this.channel := data.channel_id
			this.emoji := data.emoji.name
		}
	}

	class message {
		__New(api, data) {
			this.data := data
			this.id := data.id
			this.api := api
			this.message := data.content
			this.channel := {id: data.channel_id}
			if data.guild_id {
				this.guild := new discord.guild(api, data.guild_id)
			}
			this.author := new discord.author(api, data.author, this.guild, data.member)
			if data.referenced_message {
				data.referenced_message.guild_id := data.guild_id
				this.referenced_msg := new api.message(api, data.referenced_message)
			}
		}

		typing() {
			this.api.TypingIndicator(this.channel.id)
		}

		react(reaction) {
			this.api.AddReaction(this.data.channel_id, this.id, reaction)
		}

		reply(data) {
			msg := this.api.SendMessage(this.data.channel_id, data)
			return new this.api.message(this.api, msg)
		}

		edit(data) {
			this.api.EditMessage(this.data.channel_id, this.data.id, data)
		}

		delete() {
			this.api.DeleteMessage(this.data.channel_id, this.data.id)
		}

		getEmoji(name) {
			return this.api.getMoji(name)
		}
	}
}
