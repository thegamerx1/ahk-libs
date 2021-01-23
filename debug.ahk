#Include <ezConf>
#Include <json>
class Debug {
	init(options := "") {
		this.initiated := true
		defaultconf := {stamp: false, stampformat:"[{:02}:{:02}:{:02}.{:03u}] "}
		this.config := ezConf(options, defaultconf)

		if (this.config.console) {
			DllCall("AttachConsole", int, -1)
			OnExit(ObjBindMethod(this, "clean"))
		}

		this._attachRedirect := {}
		this._attachEdit := {}
		this.firstmessage := 0
		this.log := ""
	}

	clean() {
		DllCall("FreeConsole")
	}

	attachRedirect(obj) {
		if !(this.initiated)
			Throw "Not initiated yet!"
		if (this._attachRedirect.enabled)
			Throw % "Already Attached to " this._attachRedirect.func.name "!"

		this._attachRedirect.func := obj
		this._attachRedirect.enabled := true

		obj.call(this.log)
	}

	attachEdit(control) {
		if !(this.initiated)
			Throw "Not initiated yet!"
		if (this._attachEdit.enabled)
			Throw "Already Attached to " this._attachEdit.hwnd "!"

		this._attachEdit.hwnd := control
		this._attachEdit.enabled := true

		GuiControl,, % this._attachEdit.hwnd, % this.log
	}

	print(message := "", label := "", options := "") {
		if !(this.initiated)
			Throw "Not initiated yet!"

		if IsObject(message)
			message := Json.dump(message)

		config := ezConf(options, {onlyStdOut: false, newline: "`n"})

		prefix := ""
		out := ""
		if (this.config.stamp)
			prefix .= Format(this.config.stampformat, A_Hour, A_Min, A_Sec, A_MSec)

		if (label)
			prefix .= "[" label "] "

		if (message = "") {
			out := config.newline
		} else {
			out .= prefix message config.newline
		}

		if (this._attachRedirect.enabled && !config.onlyStdOut) {
			this._attachRedirect.func.call(out)
		}

		if (this._attachEdit.enabled && !config.onlyStdOut) {
			GuiControlGet textbefore,, % this._attachEdit.hwnd
			GuiControl,, % this._attachEdit.hwnd, % textbefore out
			; SendMessage 0x115, 7, 0,, % "ahk_id " this._attachEdit.hwnd
		}


		if (!this.errorStdOut) {
			try {
				FileAppend, %out%, *
			} catch e {
				this.errorStdOut := true
			}
		}
		this.log .= out
	}
}