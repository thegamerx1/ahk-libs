;; ? Modified from https://github.com/G33kDude/WebSocket.ahk
class WebSocket {
	__New(creator, WS_URL) {
		static wb
		static html = "
		(
			<!DOCTYPE html>
			<meta http-equiv='X-UA-Compatible' content='IE=edge'>
			<script>
			function start(url, ahk_event) {
				ws = new WebSocket(url);
				ws.onopen = function(event){ ahk_event('Open', event) };
				ws.onclose = function(event){ ahk_event('Close', event.reason, event.code)};
				ws.onerror = function(event){ ahk_event('Error', event.reason, event.code)};
				ws.onmessage = function(event){ ahk_event('Message', event) };
			}
			</script>
		)"

		this.creator := creator
		; ? Create an IE instance
		Gui +hWndhOld
		Gui New, +hWndhWnd
		this.connected := hWnd
		Gui Add, ActiveX, vwb, % "about:" html
		while wb.readyState < 4
			sleep 50
		Gui %hOld%: Default

		this.doc := wb.document
		this.wnd := this.doc.parentWindow
		this.wnd.start(WS_URL, ObjBindMethod(this, "Event"))
	}

	; Called by the JS in response to WS events
	Event(EventName, Event*) {
		fn := this.creator["On" EventName]
		try {
			%fn%(this.creator, Event*)
		} catch e {
			debug.print(e)
			ExitApp 1
		}
	}

	; Sends data through the WebSocket
	Send(Data) {
		this.wnd.ws.send(Data)
	}

	; Closes the WebSocket connection
	Close(Code:=1000, Reason:="") {
		this.wnd.ws.close(Code, Reason)
	}

	; Closes and deletes the WebSocket, removing
	; references so the class can be garbage collected
	Disconnect() {
		if this.connected {
			this.Close()
			Gui % this.connected ": Destroy"
			this.connected := False
			this.creator := False
		}
	}
}