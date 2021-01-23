class BackgroundSender {
	__New() {
		WinGet hwnd, ID, A
		this.hwnd := hwnd
		;Debug.send("Background Sender attached to: " this.hwnd)
	}

	send(keys) {
		;Debug.send("Background Sender sending: " keys " to " this.hwnd)
		ControlSend,, %keys%, % "ahk_id " this.hwnd
	}

	click(button, options) {
		ControlClick,, % "ahk_id " this.hwnd,, %button%,, NA%options%
	}
}