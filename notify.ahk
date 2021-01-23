class notification {
	__New(title, text, icon := 0) {
		this.title := title
		this.text := text
		this.icon := icon
	}

	queue() {
		notify.queue(this)
	}
}

class notify {
	init() {
		OnMessage(0x404, objbindmethod(this, "message"))
		this.inprogress := false
		this.waitlist := []
		this.initiated := true
	}

	message(wParam, lParam, msg, hwnd) {
		if (hwnd != A_ScriptHwnd)
			return

		obj := this.inobj
		switch (lParam) {
			case 1026:
				this.inprogress := true
			case 1029:
				obj.onclick()
			case 1028:
				obj.onclose()
		}
		if (lParam = "1029" || lParam = "1028") {
			this.inprogress := false
			this.inobj := ""
			if (this.waitlist.length() > 0) {
				this.queue(this.waitlist.pop())
			}
		}
	}

	queue(obj) {
		if !this.initiated
			this.init()
		if this.inprogress {
			this.waitlist.push(obj)
			return
		}

		this.inprogress := true
		this.inobj := obj
		TrayTip % obj.title, % obj.text,, % obj.icon
	}
}