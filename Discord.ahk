;; ? Modified from https://github.com/G33kDude/Discord.ahk
#include <WebSocket>
#include <Counter>
#include <requests>

class Discord {
	static baseapi := "https://discord.com/api/v8/"
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

	reconnects := identifies := 0

	__New(parent, token, intents, owner_guild := "", owner_id := "", isDebug := true) {
		;; ? owner guild is required for checking when the bot has loaded the owner's guild so it can use those emotes at start
		;; ? owner guild and owner id are used to add .isGuildOwner and .isBotOwner to the ctx
		this.log := debug.space("Discord", isDebug)
		this.utils.init(this)
		this.cache.init(this)
		this.intents := intents
		this.token := token
		this.owner := {guild: owner_guild, id: owner_id}
		this.creator := parent
		this.ratelimit := {}
		if this.connect()
			throw Exception("invalid token")
		OnError(ObjBindMethod(this, "handleError", -1))
	}

	handleError(e) {
		if (e.what = "DISCORDAHK_CALLAPI") {
			this.log("Request failed: " httpout.text, "WARNING")
			return 1
		}
	}

	setResume(sessionid, seq) {
		this.resumedata := {session: sessionid, seq: seq}
	}

	connect() {
		this.reconnecting := true
		try {
			data := this.CallAPI("GET", "gateway/bot")
			this.log("." data.session_start_limit.remaining "/" data.session_start_limit.total " identifies")
			this.ws := new WebSocket(this, data.url "?v=8&encoding=json")
		} catch {
			return 1
		}
		this.last_reconnect := new Counter(, true)
		this.reconnecting := false
	}

	disconnect() {
		this.connected := false
		this.ws.disconnect()
		this.ws := ""
	}

	reconnect(useResume := false) {
		if this.reconnecting
			return
		static TIMEOUT := 60*1000
		static reconnec := ".[Reconnect] Last reconnect: {} ago #{}"
		this.log(format(reconnec, niceDate(this.last_reconnect.get()), this.reconnects))

		if (useResume && this.session_id)
			this.setResume(this.session_id, this.seq)

		this.disconnect()
		while this.connect() {
			this.disconnect()
			this.log("[Reconnect] Trying to reconnect #" A_Index)
			DllCall("sleep", "int", 5*Min(A_Index, 120)*1000)
		}

		this.reconnects++
	}

	delete() {
		this.disconnect()
		this.creator := false
	}

	class cache {
		guild := {}
		user := {}
		dm := {}
		msg := {}

		init(byref parent) {
			this.api := parent
		}

		findChannelGuild(id) {
			for _, guild in this.guild {
				for _, channel in guild.channels {
					if (channel.id = id)
						return guild.id
				}
			}
		}

		userGet(id) {
			for _, guild in this.guild {
				if index := this.memberGet(guild.id, id)
					return guild.members[index].user
			}
			Throw Exception("No user found with id " id, -2)
		}

		dmGet(id) {
			return this.dm[id]
		}

		dmSet(id, data) {
			this.dm[id] := data
		}

		channelGet(guild, id) {
			for i, channel in this.guild[guild].channels {
				if (channel.id = id)
					return i
			}
		}

		channelUpdate(guild, id, data) {
			index := this.channelGet(guild, id)
			this.guild[guild].channels[index] := data
		}

		channelDelete(guild, id) {
			this.guild[guild].channels.RemoveAt(this.channelGet(guild, id))
		}

		channelSet(guild, data) {
			this.guild[guild].channels.InsertAt(1, data)
		}

		memberGet(guild, id) {
			for i, member in this.guild[guild].members
				if (member.user.id = id)
					return i

		}

		memberDelete(guild, id) {
			index := this.memberGet(guild, id)
			this.guild[guild].members.RemoveAt(index)
		}

		memberUpdate(guild, id, member) {
			index := this.memberGet(guild, id)
			newm := this.guild[guild].members[index] := member
			newm.roles.push(guild)
		}

		memberSet(guild, member) {
			if (index := this.memberGet(guild, member.user.id))
				return this.memberUpdate(guild, member.user.id, member)

			members := this.guild[guild].members
			members.InsertAt(1, member)
			members[1].roles.push(guild)
		}

		guildSet(guild, data) {
			this.guild[guild] := data
			for _, value in this.guild[guild].members {
				index := this.memberGet(guild, value.user.id)
				member := this.guild[guild].members[index]
				for _, role in member.roles {
					if role = guild
						return
				}
				member.roles.push(guild)
			}
		}

		guildUpdate(guild, data) {
			this.guild[guild] := ObjectMerge(data, this.guild[guild])
		}

		guildDelete(id) {
			this.guild.Delete(id)
		}

		roleUpdate(guild, id, data) {
			index := this.roleGet(guild, id)
			this.guild[guild].roles[index] := data
		}

		roleDelete(guild, id) {
			for _, role in this.guild[guild].roles {
				if (role.id = id) {
					this.guild[guild].roles.RemoveAt(A_Index)
					break
				}
			}
		}

		roleCreate(guild, role) {
			this.guild[guild].roles.push(role)
		}

		roleGet(guild, id) {
			for i, role in this.guild[guild].roles
				if (role.id = id)
					return i
		}

		messageSet(channel, data) {
			if !this.msg[channel]
				this.msg[channel] := {}

			if !data.guild_id
				data.guild_id := this.findChannelGuild(channel)
			data.edits := []
			this.msg[channel][data.id] := data
		}

		messageGet(channel, id) {
			return this.msg[channel][id]
		}

		emojiGet(guild, name) {
			for _, value in this.guild[guild].emojis
				if (value.name = name)
					return value
			Throw Exception("Couldn't find emoji", -2, name)
		}

		emojiUpdate(guild, emojis) {
			this.guild[guild].emojis := emojis
		}
	}

	class utils {
		init(byref parent) {
			this.api := parent
		}

		snowflakeTime(flake) {
			static DISCORD_EPOCH := 1420070400000
			return Unix2Miss(((flake >> 22) + DISCORD_EPOCH) / 1000)
		}

		convertEmoji(emote) {
			if RegExMatch(emote, "^[\w#@$\?\[\]\x80-\xFF]+$")
				emote := this.getEmoji(emote, false)
			return emote
		}

		webhook(content, webhook) {
			http := new requests("POST", webhook,, true)
			http.headers["Content-Type"] := "application/json"
			http.onFinished := ObjBindMethod(this, "webhookRes")
			http.send(JSON.dump(this.getMsg(content, true)))
		}

		webhookRes(http) {
			if (http.status != 204 && http.status != 200)
				this.log("[Webhook] Error " http.status ": " http.text, "ERROR")
		}

		getId(str) {
			regex := regex(str, "(?<id>\d{9,})")
			return regex.id
		}

		getMsg(content, webhook := false) {
			if IsObject(content) {
				msg := content.get(webhook)
			} else {
				if StrLen(content) > 2000
					Throw Exception("Message too long", -2)
				msg := {content: content}
			}
			return msg
		}

		ISODATE(str, noms := false) {
			match := regex(str, "(?<YYYY>\d{4})-?(?<MM>\d{2})-?(?<DD>\d{2})T?(?<HH>\d{2}):?(?<MI>\d{2}):?(?<SS>\d{2})\.(?<SD>\d+)\+\d{2}:\d{2}")
			return match.YYYY match.MM  match.DD  match.HH  match.MI  match.SS (noms ? "" : "."  match.SD)
		}

		TOISO(date) {
			FormatTime out, %date%, yyyy-MM-ddTHH:ss:00+00:00
			return out
		}

		getEmoji(name, wrap := true) {
			if !RegExMatch(name, "^[\w#@$\?\[\]\x80-\xFF]+$")
				return name
			emoji := this.api.getEmoji(name)
			wraps := (wrap ? ["<" (emoji.animated ? "a" : "") ":", ">"] : [])
			return wraps[1] name ":" emoji.id wraps[2]
		}

		sanitize(str, delims := "``") {
			return StrReplace(str, "``", chr(8203) "``")
		}

		getCodeBlock(code) {
			static regex := "^(``{1,2}(?!``)(?<code>.*?))``{1,2}|``{3}(?(?=\w+\n)(?<lang>\w+)\n)(?<code>.*?)``{3}$"
			out := {}
			if !(match := regex(code, regex, "Js")) {
				out.code := code
			} else {
				out.code := match.code
				out.lang := match.lang
			}
			return out
		}

		codeBlock(lang, code, sanitize := true, emptymsg := "No output") {
			if (code = "" || code = "`n")
				return emptymsg
			return "``````" lang "`n" (sanitize ? this.sanitize(code) : code) "``````"
		}
	}

	CallAPI(method, endpoint, data := "", async := false) {
		static loggyFormat := "[{}:{}] [{}ms] {}"
		http := new requests(method, Discord.baseapi endpoint,, async)
		count := new Counter(, true)
		; ? Try the request multiple times if necessary
		Loop 2 {
			http.headers["Authorization"] := "Bot " this.token

			if IsObject(data) {
				http.headers["Content-Type"] := "application/json"
				data := JSON.dump(data)
			}

			http.headers["User-Agent"] := "Discord.ahk"
			httpout := http.send(data)
			this.log("." format(loggyFormat, method, httpout.status, count.get(), endpoint))
			httpjson := httpout.json()
			; TODO: ratelimit
			; this.ratelimit.bucket := httpout.headers["x-ratelimit-bucket"]
			; this.ratelimit.limit := httpout.headers["x-ratelimit-limit"]
			; this.ratelimit.remaining := httpout.headers["x-ratelimit-remaining"]
			; this.ratelimit.reset := httpout.headers["x-ratelimit-reset"]
			; this.ratelimit["reset-after"] := httpout.headers["x-ratelimit-reset-after"]
			; debug.print(this.ratelimit)

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
		if !StartsWith(httpout.status, 20)
			throw Exception(httpjson.message, "DISCORDAHK_CALLAPI", httpjson.code)

		return httpjson
	}

	; ? Sends data through the websocket
	Send(Data) {
		if (this.reconnecting || !this.connected) {
			this.log("Couldnt send " this.reconnecting " " this.connected, "ERROR")
			this.log(data)
		}
		this.ws.send(JSON.dump(Data))
	}

	SetPresence(status, playing := "", type := 0) {
		activity := []
		if playing
			activity.push({name: playing, details: playing, type: type})
		this.Send({op: 3, d: {since: "null", activities: activity, status: status, afk: false}})
	}

	SendMessage(channel, content) {
		msg := this.utils.getMsg(content)
		if (StrLen(msg.content) > 2000)
			Throw Exception("Message too long", -1)
		return this.CallAPI("POST", "channels/" channel "/messages", msg)
	}

	getGuild(id) {
		return new discord.guild(this, id)
	}

	getUser(id) {
		; if !this.cache.userGet(id)
			; this.cache.userSet(id, this.CallAPI("GET", "users/" id))
			; Throw Exception("No user found with id " id, -2)
		return this.cache.userGet(id)
	}

	changeSelfNick(guild, nick) {
		this.CallAPI("PATCH", "guilds/" guild "/members/@me/nick", {nick: nick})
	}

	createDM(id) {
		if !this.cache.dmGet(id)
			this.cache.dmSet(id, this.CallAPI("POST", "users/@me/channels", {recipient_id: id}))
		return this.cache.dmGet(id)
	}

	getEmoji(name, guild := "") {
		if !guild
			guild := this.owner.guild
		return this.cache.emojiGet(guild, name)
	}

	SendHeartbeat() {
		if !this.connected
			return
		if !this.HeartbeatACK {
			this.reconnect(true)
			return
		}

		this.HeartbeatACK := False
		this.Send({op: 1, d: this.Seq})
		this.HeartbeatACKms := new counter()
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
				intents: this.intents,
				compress: true,
				large_threshold: 250
			}
		)})
		this.identifies++
	}

	resume() {
		this.log(".[Reconnect] Trying to resume with session")
		res := this.resumedata
		this.Send({op: 6, d: {token: this.token, session_id: res.session, seq: res.seq}})
		this.resumedata := ""
	}

	/*
		? OP HANDLING
	*/

	OP_HELLO(Data) {
		this.HeartbeatACK := True
		Interval := Data.d.heartbeat_interval
		SetTimer(ObjBindMethod(this, "SendHeartbeat"), Interval)
		TimeOnce(ObjBindMethod(this, this.resumedata ? "resume" : "identify"), 50)
		this.connected := true
	}

	OP_HEARTBEATACK(Data) {
		this.HeartbeatACK := True
		this.ws.ping := this.HeartbeatACKms.get()
	}

	OP_INVALIDSESSION(Data) {
		this.log(".[SESSION] Attempting to identify to discord api")
		TimeOnce(ObjBindMethod(this, "identify"), random(1000, 4000))
	}

	OP_Dispatch(Data) {
		output := false
		switch data.t {
			case "MESSAGE_UPDATE":
				if !data.d.author
					return
				msg := this.cache.messageGet(data.d.channel_id, data.d.id)
				edits := clone(msg.edits)
				edits.InsertAt(1, msg)
				this.cache.messageSet(data.d.channel_id, data.d)
				msg := this.cache.messageGet(data.d.channel_id, data.d.id)
				msg.edits := edits
				output := new discord.message(this, Data.d)
			case "MESSAGE_CREATE":
				this.cache.messageSet(data.d.channel_id, data.d)
				if data.d.author.id = this.self.id
					return ;; ? Ignore own messages

				output := new discord.message(this, Data.d)
			case "MESSAGE_DELETE_BULK":
				output := new discord.messageDeleteBulk(this, data.d)
			case "MESSAGE_DELETE":
				msg := this.cache.messageGet(data.d.channel_id, data.d.id)
				msg.deleted := true
				output := new discord.message(this, msg)

			case "MESSAGE_REACTION_ADD":
				if data.d.user_id == this.self.user_id
					return
				output := new this.reaction(this, data.d)


			case "READY":
				this.session_id := Data.d.session_id
				this.self := data.d.user
				this.self.application := data.d.application
				if (this.owner.guild)
					return

			case "RESUMED":
				this.log(".Succesfully resumed")

			case "GUILD_CREATE":
				this.cache.guildSet(data.d.id, data.d)
				if (data.d.id = this.owner.guild) {
					TimeOnce(ObjBindMethod(this, "dispatch", "READY", {}), 1)
					this.log(".READY")
				}
			case "GUILD_UPDATE":
				this.cache.guildUpdate(data.d.guild_id, data.d)
			case "GUILD_DELETE":
				if !data.d.unavailable
					this.cache.guildDelete(data.d.id)
			case "GUILD_EMOJIS_UPDATE": ;;UNCHECKED
				this.cache.emojiUpdate(data.d.guild_id, data.d.emojis)

			case "INTERACTION_CREATE":
				output := new this.interaction(this, data.d)

			case "GUILD_ROLE_CREATE":
				this.cache.roleCreate(data.d.guild_id, data.d.role)
			case "GUILD_ROLE_UPDATE":
				this.cache.roleUpdate(data.d.guild_id, data.d.role.id, data.d.role)
			case "GUILD_ROLE_DELETE":
				this.cache.roleDelete(data.d.guild_id, data.d.role_id)

			case "GUILD_MEMBER_UPDATE":
				this.cache.memberUpdate(data.d.guild_id, data.d.user.id, data.d)
				data.d := new discord.memberAction(this, data.d)
			case "GUILD_MEMBER_REMOVE":
				data.d := new discord.memberAction(this, data.d)
				this.cache.memberDelete(data.d.guild_id, data.d.user.id)
			case "GUILD_MEMBER_ADD":
				this.cache.memberSet(data.d.guild_id, data.d)
				data.d := new discord.memberAction(this, data.d)

			case "CHANNEL_UPDATE":
				this.cache.channelUpdate(data.d.guild_id, data.d.id, data.d)
			case "CHANNEL_CREATE":
				this.cache.channelSet(data.d.guild_id, data.d)
			case "CHANNEL_DELETE":
				this.cache.channelDelete(data.d.guild_id, data.d.id)
		}

		this.dispatch(data.t, output ? output : data.d)
	}

	dispatch(event, data) {
		fn := this.creator["_event"]
		%fn%(this.creator, event, data)
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

		if (opname != "dispatch")
			this.log("." opname)
		this["OP_" opname](Data)
	}

	OnError(reason := "", code := "", message := "") {
		this.log(format("Error, {},: {} {}", code, reason, message), "ERROR")
		this.reconnect(true)
	}


	OnClose(reason := "", code := "") {
		static allowed := [1000, 1001, 4000, 4005, 4007, 4009]
		this.log(format("Closed, {}: {}", code, reason), "INFO")
		if !contains(code, allowed)
			Throw Exception("Discord closed with an error")
		this.reconnect(true)
	}


	/*
		? Constructors
	*/

	class paginator {
		__New(content, limit := 1950) {
			content := discord.utils.sanitize(content)
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

		get() {
			return this.pages
		}
	}

	class embed {
		__New(title := "", content := "", color := "blue") {
			static colors := [{name: "error", value: 0xAC3939}, {name: "success", value: 0x65C85B}, {name: "blue", value: 0x159af3}]
			for _, val in colors {
				if val.name = color
					color := val.value
			}

			if StrLen(title) > 256
				Throw Exception("Embed title too long", -1)
			if StrLen(content) > 2048
				Throw Exception("Embed description too long", -1)

			this.embed := {title: title
				,description: content
				,color: format("{:u}", color)
				,fields: []}
		}

		setDescription(str) {
			if StrLen(str) > 2048
				Throw Exception("Embed description too long", -1)
			this.embed.description := str
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
			this.embed.thumbnail := {url: img}
		}

		addField(title, content, inline := false, empty := false) {
			if StrLen(title) > 256
				Throw Exception("Field title too long", -1)
			if StrLen(content) > 1024
				Throw Exception("Field content too long", -1)

			if empty
				content := title := chr(8203)

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

	calcPermissions(guild, channel, member) {
		static permissionlist := {ADD_REACTIONS: 0x00000040, ADMINISTRATOR: 0x00000008, ATTACH_FILES: 0x00008000, BAN_MEMBERS: 0x00000004, CHANGE_NICKNAME: 0x04000000, CONNECT: 0x00100000, CREATE_INSTANT_INVITE: 0x00000001, DEAFEN_MEMBERS: 0x00800000, EMBED_LINKS: 0x00004000, KICK_MEMBERS: 0x00000002, MANAGE_CHANNELS: 0x00000010, MANAGE_EMOJIS: 0x40000000, MANAGE_GUILD: 0x00000020, MANAGE_MESSAGES: 0x00002000, MANAGE_NICKNAMES: 0x08000000, MANAGE_ROLES: 0x10000000, MANAGE_WEBHOOKS: 0x20000000, MENTION_EVERYONE: 0x00020000, MOVE_MEMBERS: 0x01000000, MUTE_MEMBERS: 0x00400000, PRIORITY_SPEAKER: 0x00000100, READ_MESSAGE_HISTORY: 0x00010000, SEND_MESSAGES: 0x00000800, SEND_TTS_MESSAGES: 0x00001000, SPEAK: 0x00200000, STREAM: 0x00000200, USE_EXTERNAL_EMOJIS: 0x00040000, USE_VAD: 0x02000000, VIEW_AUDIT_LOG: 0x00000080, VIEW_CHANNEL: 0x00000400, VIEW_GUILD_INSIGHTS: 0x00080000}
		perms := allow := deny := 0, done := false
		permissions := []

		for _, value in member.roles {
			role := guild.getRole(value)
			perms |= role.permissions
		}

		if (discord.checkFlag(perms, permissionlist["ADMINISTRATOR"]) || (member.user.id = guild.owner_id)) {
			for key, _ in permissionlist {
				permissions.push(key)
			}
			done := true
		}

		if !done {
			for _, value in member.roles {
				overwrite := channel.getOverwrite(value)
				if overwrite {
					allow |= overwrite.allow
					deny |= overwrite.deny
				}
			}
			perms &= ~deny
			perms |= allow
			for key, flag in permissionlist
				if discord.checkFlag(perms, flag)
					permissions.push(key)
		}

		return permissions
	}

	checkFlag(perms, flag) {
		return (perms & flag) == flag
	}

	class author {
		__New(api, data, guild := "", channel := "") {
			static avatar := "https://cdn.discordapp.com/avatars/{}/{}.webp?size=1024"
			static noavatar := "https://cdn.discordapp.com/embed/avatars/{}.png"
			this.api := api
			for key, value in data {
				this[key] := value
			}

			this.guild := guild
			this.channel := channel
			this.mention := "<@" data.id ">"
			this.notMention := this.username "#" this.discriminator
			this.avatar := this.avatar ? format(avatar, this.id, this.avatar) : format(noavatar, mod(this.discriminator, 5))
			this.isGuildOwner := (this.id = guild.owner_id)
			this.isBotOwner := (this.id = api.owner.id)

			if !guild
				this.api.log("`n" callstack(3) "did not provide a guild", "WARNING")

			if guild {
				member := guild.getMember(this.id)
				this.roles := member.roles
				if channel {
					this.permissions := discord.calcPermissions(guild, channel, member)
				}
			}

		}

		sendDM(content) {
			channel := this.api.createDM(this.id)
			this.api.SendMessage(channel.id, content)
		}

		get(userid) {
			return new discord.author(this.api, this.api.getUser(userid), this.guild, this.channel)
		}

		modify(json) {
			; ? JSON https://discord.com/developers/docs/resources/guild#modify-guild-member

			this.api.CallAPI("PATCH", "guilds/" this.guild.id "/members/" this.id)
		}

		addRole(role) {
			this.guild.role(this.id, role)
		}

		removeRole(role) {
			this.guild.role(this.id, role, 0)
		}

		kick() {
			this.guild.kick(this.id)
		}
	}

	class messageDeleteBulk {
		__New(api, data) {
			this.api := api
			for key, value in data {
				this[key] := value
			}
			this.count := data.ids.length()
			this.guild := new discord.guild(api, data.guild_id)
			this.channel := new discord.channel(api, data.channel_id, this.guild)
		}
	}

	class guild {
		__New(api, id) {
			this.api := api
			guild := api.cache.guild[id]
			if !guild
				return

			for key, value in guild {
				this[key] := value
			}
			this.created_at := discord.utils.ToISO(discord.utils.snowflakeTime(this.id))
		}

		kick(user) {
			this.api.CallAPI("DELETE", "guilds/" this.id "/members/" user)
		}

		ban(id, reason, delete) {
			return this.api.CallAPI("PUT", "guilds/" this.id "/bans/" id, {reason: reason, delete_message_days: delete})
		}

		getBans() {
			return this.api.CallAPI("GET", "guilds/" this.id "/bans")
		}

		unBan(id) {
			return this.api.CallAPI("DELETE", "guilds/" this.id "/bans/" id)
		}

		leave() {
			return this.api.CallAPI("DELETE", "users/@me/guilds/" this.id)
		}

		getChannel(id) {
			return new discord.channel(this.api, id, this)
		}

		getMember(id) {
			; if !this.api.cache.memberGet(this.id, id) {
			; 	if dontRequest
			; 		return
			; 	this.api.cache.memberSet(this.id, this.api.CallAPI("GET", "guilds/" this.id "/members/" id))
			; }
			return this.members[this.api.cache.memberGet(this.id, id)]
		}

		getRole(id) {
			return this.roles[this.api.cache.roleGet(this.id, id)]
		}

		modify(json) {
			; ? JSON https://discord.com/developers/docs/resources/guild#modify-guild
			return this.api.CallAPI("PATCH", "guilds/" this.id, json)
		}

		delete() {
			this.api.CallAPI("DELETE" , "guilds/" this.id)
		}

		createChannel(json) {
			; ? JSON https://discord.com/developers/docs/resources/guild#modify-guild
			return this.api.CallAPI("POST", "guilds/" this.id "/channels", json)
		}

		channelPositions(array) {
			return this.api.CallAPI("PATCH", "guilds/" this.id "/channels", array)
		}

		rolePositions(array) {
			return this.api.CallAPI("PATCH", "guilds/" this.id "/roles", array)
		}

		role(user, id, addremove := 1) {
			return this.api.CallAPI(addremove ? "PUT" : "DELETE", "guilds/" this.id "/members/" user "/roles/" id)
		}

		findChannel(name) {
			for i, channel in this.channels {
				if (channel.id = name || channel.name = name || strDiff(channel.name, name) > 0.7) {
					return channel.id
				}
			}
		}
	}

	class reaction {
		__New(api, data) {
			this.api := api
			this.guild := new discord.guild(api, data.guild_id)
			this.channel := new discord.channel(api, data.channel_id, this.guild)
			this.author := new discord.author(api, data.member.user, this.guild, this.channel)
			this.emoji := data.emoji.name
			this.message_id := data.message_id
		}

		message {
			get {
				if !this._message
					this._message := this.channel.getMessage(this.message_id)
				return this._message
			}
		}
	}

	class memberAction {
		__New(api, data) {
			this.api := api
			this.guild := new discord.guild(api, data.guild_id)
			if !this.guild
				return
			for key, value in data {
				this[key] := value
			}
			this.user := new discord.author(api, data.user, this.guild)
		}
	}

	class channel {
		; TODO: Edit Channel perms,
		__New(api, id, guild := "") {
			if !guild
				guild := new discord.guild(api, api.cache.findChannelGuild(id))
			if !guild
				return
			this.api := api
			index := api.cache.channelGet(guild.id, id)
			channel := guild.channels[index]
			if !channel
				return
			for key, value in channel {
				this[key] := value
			}
			this.mention := "<#" this.id ">"
			this.guild := guild
			this.permissions := discord.calcPermissions(this.guild, this, guild.getMember(api.self.id))
		}

		modify(json) {
			; ? JSON from https://discord.com/developers/docs/resources/channel#modify-channel
			return this.api.CallAPI("PATCH", "channels/" this.id, json)
		}

		delete() {
			return this.api.CallAPI("DELETE", "channels/" this.id)
		}

		canI(perms := "") {
			for _, perm in perms {
				if !contains(perm, this.permissions)
					return 0
			}
			return 1
		}

		getOverwrite(id) {
			if !this.guild
				Throw Exception("No guild provided on channel", -1)

			for _, value in this.permission_overwrites {
				if (value.id = id)
					return value
			}
		}

		TypingIndicator() {
			this.api.CallAPI("POST", "channels/" this.id "/typing")
		}

		deleteMessage(message) {
			if IsObject(message)
				if (message.length() > 1) {
					return this.api.CallAPI("POST", "channels/" this.id "/messages/bulk-delete", {messages: message})
				} else {
					message := message[1]
				}
			return this.api.CallAPI("DELETE", "channels/" this.id "/messages/" message)
		}

		getMessage(id) {
			if !this.api.cache.messageGet(this.id, id)
				this.api.cache.messageSet(this.id, this.api.CallAPI("GET", "channels/" this.id "/messages/" id))

			return new discord.message(this.api, this.api.cache.messageGet(this.id, id))
		}

		getMessages(opt) {
			return this.api.CallAPI("GET", "channels/" this.id "/messages?" urlCode.encodeParams(opt))
		}

		send(content) {
			msg := this.api.SendMessage(this.id, content)
			msg.guild_id := this.guild.id
			return msg
		}

		editMessage(id, data) {
			msg := this.api.utils.getMsg(data)
			return this.api.CallAPI("PATCH", "channels/" this.id "/messages/" id, msg)
		}

		reaction(id, emoji, addremove := 1) {
			emoji := this.api.utils.convertEmoji(emoji)
			return this.api.CallAPI(addremove ? "PUT" : "DELETE", "channels/" this.id "/messages/" id "/reactions/" urlCode.encode(emoji) "/@me")
		}

		getReactions(id, emoji, opt) {
			emoji := this.api.utils.convertEmoji(emoji)
			this.api.CallAPI("GET", "channels/" this.id "/messages/" id "/reactions/" emoji "?" rurlCode.encodeParams(opt))
		}

		deleteAllReactions(id) {
			this.api.CallAPI("DELETE", "channels/" this.id "/messages/" id "/reactions/")
		}

		deleteEmojiReactions(id, emoji) {
			emoji := this.api.utils.convertEmoji(emoji)
			this.api.CallAPI("DELETE", "channels/" this.id "/messages/" id "/reactions/" emoji)
		}

		getInvites() {
			return this.api.CallAPI("GET", "channels/" this.id "/invites")
		}

		createInvite(json) {
			; ? JSON https://discord.com/developers/docs/resources/channel#create-channel-invite
			return new discord.invite(this.guild, this.api.CallAPI("POST", "channels/" this.id "/invites", json))
		}

		getPins() {
			msgs := []
			pins := this.api.CallAPI("GET", "channels/" this.id "/pins")
			for _, pin in pins {
				msgs.push(new discord.message(this.api, pin))
			}
			return msgs
		}

		pin(id, addremove := 1) {
			this.api.CallAPI(addremove ? "PUT" : "DELETE", "channels/" this.id "/pins/" id)
		}
	}

	;; TODO: EMOJI OBJECT

	class invite {
		__New(guild, data) {
			this.api := guild.api
			this.guild := guild
			this.code := data.code
			this.channel := guild.getChannel(data.channel.id)
			this.inviter := guild.getMember(data.inviter.id)
			this.presence_count := data.approximate_presence_count
			this.member_count := data.approximate_member_count
		}

		delete() {
			this.api.CallAPI("DELETE",  "invites/" this.code)
		}
	}

	; class interaction {
	; 	__New(api, data) {
	; 		this.api := api
	; 		this.guild := new discord.guild(api, data.guild_id)
	; 		this.channel := new discord.channel(api, data.channel_id, data.guild)
	; 		api.cache.memberSet(data.guild_id, data.member)
	; 		this.author := new discord.author(api, data.member.user, this.guild, this.channel)
	; 		this.token := data.token
	; 		this.id := data.id
	; 		this.data := data.data
	; 		this.isInteraction := true
	; 	}

	; 	reply(type, message := "") {
	; 		if (!message && StrLen(type) != 1) {
	; 			response := {type: 4, data: discord.utils.getMsg(type)}
	; 		} else {
	; 			response := {type: type}
	; 			if message
	; 				response.data := discord.utils.getMsg(message)
	; 		}
	; 		data := this.api.callAPI("POST", "interactions/"  this.id "/" this.token "/callback", response)
	; 	}
	; }

	class message {
		__New(api, data) {
			static messageLink := "https://discord.com/channels/{}/{}/{}"
			this.id := data.id
			this.api := api
			for key, value in data {
				this[key] := value
			}

			this.link := format(messageLink, data.guild_id, data.channel_id, data.id)

			if data.guild_id {
				this.guild := new discord.guild(api, data.guild_id)
			}
			this.channel := new discord.channel(api, data.channel_id, this.guild)
			this.timestamp := discord.utils.ISODATE(data.timestamp)
			if !data.webhook_id {
				this.author := new discord.author(api, data.author, this.guild, this.channel)
				if data.referenced_message {
					data.referenced_message.guild_id := data.guild_id
					msg := api.cache.messageGet(data.channel_id, data.referenced_message.id)
					this.reply_msg := new discord.message(api, msg ? msg : data.referenced_message)
				}
			}
		}

		typing() {
			this.channel.TypingIndicator()
		}

		react(emote) {
			this.channel.reaction(this.id, emote, 1)
		}

		unReact(emote) {
			this.channel.reaction(this.id, emote, 0)
		}

		reply(data) {
			return new this.api.message(this.api, this.channel.send(data))
		}

		edit(data) {
			this.channel.editMessage(this.id, data)
		}

		delete() {
			msg := this.api.cache.messageGet(this.channel.id, this.id)
			if msg.deleted
				return
			try {
				this.channel.deleteMessage(this.id)
			} catch e {
				if (e.Extra != 10008)
					throw e
			}
		}

		getEmoji(name) {
			return this.api.utils.getEmoji(name)
		}

		pin() {
			this.channel.pin(this.id)
		}

		unPin() {
			this.channel.pin(this.id, 0)
		}
	}
}


class DiscordOauth {
	__New(clientid, secret, redirect, scopes) {
		this.id := clientid
		this.secret := secret
		this.redirect := redirect
		this.scopes := scopes
	}

	getCode(code) {
		http := this.tokenRequest({grant_type: "authorization_code", code: code})

		if http.status != 200
			throw Exception("Auth failed code: " http.status, "Invalid code", http.text)
		return new this.AccessToken(this, http.text)
	}

	tokenRequest(obj) {
		http := new requests("POST", Discord.baseapi "oauth2/token")
		data := {client_id: this.id
		,client_secret: this.secret
		,redirect_uri: this.redirect
		,scope: this.scopes}

		data := ObjectMerge(obj, data)
		http.headers["Content-type"] := "application/x-www-form-urlencoded"
		return http.send(urlCode.encodeParams(data, true))
	}

	apiRequest(endpoint, token) {
		http := new requests("GET", Discord.baseapi endpoint)
		http.headers["Authorization"] := "Bearer " token.token
		return http.send()
	}
	class AccessToken {
		__New(oauth, raw) {
			data := JSON.load(raw)
			this.token := data.access_token
			this.type := data.token_type
			this.expires_in := data.expires_in
			this.refresh_token := data.refresh_token
			this.oauth := oauth
		}

		refresh() {
			http := new requests("POST", Discord.baseapi "oauth2/token")
		}
	}
}