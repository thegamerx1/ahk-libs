#Include <ezConf>
#Include <JSON>
class Debug {
	init(options := "") {
		static defaultconf := {stamp: false, stampformat: "[{:02}:{:02}:{:02}] "}
		this.initiated := true
		this.config := ezConf(options, defaultconf)

		if this.config.console {
			if !DllCall("AttachConsole", "Uint", -1)
				DllCall("AllocConsole")

			OnExit(ObjBindMethod(this, "clean"))
		}

		this.log := ""
		OnError(ObjBindMethod(this, "error"))
	}

	space(name, debug := false) {
		return ObjBindMethod(this, "spacecall", {label: name, debug: debug})
	}

	spacecall(opt, _, text, sev := "", options := "") {
		opt := ObjectMerge(opt, options ? options : {})
		opt.sev := sev
		this.print(text, opt)
	}

	error(e) {
		this.print("Unhandled error: ")
		this.print(e)
	}

	clean(reason, code) {
		if code != 0
			sleep 5000
		DllCall("FreeConsole")
	}

	attachRedirect {
		get {
			return this._attachRedirect
		}

		set {
			if this.attachRedirect
				Throw % "Already Attached to """ this.attachRedirect.func.name """!"

			this._attachRedirect := value
			value.call(this.log)
		}
	}

	attachEdit {
		get {
			return this._attachEdit
		}

		set {
			if this.attachEdit
				Throw % "Already Attached to """ this.attachEdit.func.name """!"

			this._attachEdit := value
			GuiControl,, % value, % this.log
		}
	}

	attachFile {
		get {
			return this._attachFile
		}

		set {
			if this.attachFile
				Throw % "Already saving to """ this.attachFile """!"

			this._attachFile := value
			FileAppend % this.log, %value%
		}
	}

	print(message := "", options := "") {
		static defaultconf := {label: "", end: "`n", pretty: false, debug: false}
		static actions := [">", "|", "."]

		config := ezConf(options, defaultconf)
		isAction := false
		start := SubStr(message, 1,1)
		out := ""

		if contains(start, actions) {
			isAction := true
			message := SubStr(message, 2)
		}

		switch start {
			case ".":
				if !config.debug
					return
				config.sev := "DEBUG"
		}

		if IsObject(message)
			message := JSON.dump(message, 1, config.pretty)


		if this.config.stamp
			out .= Format(this.config.stampformat, A_Hour, A_Min, A_Sec)
		if config.label
			out .= "[" config.label "] "
		if config.sev
			out .= config.sev " "


		if (message = "") {
			out := config.end
		} else {
			out .= message config.end
		}

		switch start {
			case "|":
				this.debug(out)
			case ">":
				this.std(out)
			case ".":
				this.debug(out)
		}

		this.log .= out

		if isAction
			return


		if (this.attachRedirect)
			this.attachRedirect.call(out)

		if (this.attachFile)
			FileAppend %out%, % this.attachFile

		if (this.attachEdit) {
			GuiControlGet textbefore,, % this.attachEdit
			GuiControl,, % this.attachEdit, % textbefore out
			SendMessage 0x115, 7, 0,, % "ahk_id " this.attachEdit
		}

		this.std(out)
	}

	debug(byref str) {
		if A_DebuggerName {
			OutputDebug % str
		} else {
			this.std(str)
		}
	}

	std(byref str) {
		if !this.errorStdOut {
			try {
				FileAppend %str%, *
			} catch e {
				this.errorStdOut := true
			}
		}
	}
}