This is a simple bot with discord.ahk with ping and pong commands.

```ahk
#Persistent
sleep 50 ;; To wait for the A_DebuggerName to get set if debugging
debug.init({console: !A_DebuggerName})

class Bot {
	init(token) {
		this.api := new Discord(this, token, 5633)
		;; https://ziad87.net/intents/
	}

	_event(event, data) {
		fn := ObjBindMethod(this, "E_" event)
		fn.call(data)

		debug.print(">Event " event)
	}

	E_READY(data) {
		debug.print("Ready!`nInvite me with https://discord.com/oauth2/authorize?&client_id=" this.api.self.id "&scope=bot&permissions=3072")
	}

	E_MESSAGE_CREATE(ctx, args*) {
		if (ctx.author.bot)
			return ;; Ignore bot messages including ourselves

		if (ctx.message == "!ping") {
			ctx.reply("Pong")
			return
		}
		if (ctx.message == "!pong") {
			ctx.reply("Ping")
			return
		}
	}
}
bot.init("your token here")
return

#Include <discord>
#Include <debug>
```
