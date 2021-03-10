#Include <ezConf>
#Include <functionsahkshouldfuckinghave>
#Include <FileInstall>

class EzGui {
	__New(creator, config := "") {
		defaultconf := {resize: false
			,caption: true
			,w: 400
			,h: 300
			,margin: 10
			,dark: true
			,fixsize: false
			,vsync: false
			,title: "EzGui"
			,autosize: false
			,browser: false
			,bordersize: 5
			,debug: false}

		this.config := ezConf(config, defaultconf)
		this.log := debug.space("EzGui", config.debug)
		this.creator := creator
		this.parentname := creator.__Class
		try {
			this.initGui()
		} catch e {
			this.fatalError(JSON.dump(e,0,1))
		}
		this.resetFont()
	}

	initGui() {
		this.controls := {}
		conf := this.config
		if conf.handleExit
			OnExit(ObjBindMethod(this, "handleExit"), -1)
		Gui new, % "+LastFound +hwndhGui -DPIScale +OwnDialogs " conf.options, % conf.title
		this.controls.gui := hGui
		if conf.owner && !conf.browser
			this.options("+Owner" conf.owner)
		if conf.resize
			this.options("+resize")
		if conf.vsync
			this.options("+E0x02000000 +E0x00080000")
		if conf.dark
			Gui Color, 1d1f21, 282a2e
		if conf.browser {
			static wb
			w := conf.w
			h := conf.h
			m := conf.margin

			; yoinked code from neutron.ahk by geekdude
			EXE_NAME := A_IsCompiled ? A_ScriptName : StrSplit(A_AhkPath, "\").Pop()
			KEY_FBE := "HKEY_CURRENT_USER\Software\Microsoft\Internet Explorer\MAIN\FeatureControl\FEATURE_BROWSER_EMULATION"
			RegWrite REG_DWORD, % KEY_FBE, % EXE_NAME, 11001

			Gui Add, ActiveX, vwb x0 y0 w%w% h%h% hwndhwb, shell.explorer
			this.wb := wb
			this.controls.wb := hwb

			ComObjConnect(wb, new BrowserEvent)
			if A_IsCompiled {
				wb.Navigate("about:blank")
				while (wb.readyState != 4) {
					if (A_Index-1 > 50*100) { ; 5s
						this.fatalError("Waiting timed out (readyState) A_IsCompiled")
					}
					Sleep 50
				}
				this.doc.write(GetScriptResource(conf.browserhtml "minify/index.html"))
				this.doc.close()
			} else {
				wb.Navigate(A_WorkingDir "\" conf.browserhtml "index.html")
			}

			VarSetCapacity(margins, 16, 0)
			NumPut(1, &margins, 0, "Int")
			DllCall("Dwmapi\DwmExtendFrameIntoClientArea"
			, "UPtr", hGui      ; HWND hWnd
			, "UPtr", &margins) ; MARGINS *pMarInset
			VarSetCapacity(wcad, A_PtrSize+A_PtrSize+4, 0)
			NumPut(19, &wcad, 0, "Int")
			VarSetCapacity(accent, 16, 0)
			NumPut(3, &accent, 0, "Int")
			NumPut(&accent, &wcad, A_PtrSize, "Ptr")
			NumPut(16, &wcad, A_PtrSize+A_PtrSize, "Int")
			DllCall("SetWindowCompositionAttribute", "UPtr", this.controls.gui, "UPtr", &wcad)
			this.wb.RegisterAsDropTarget := false
			; end yoinked code

			while (wb.readyState != 4) {
				if (A_Index-1 > 50*100) { ; 5s
					this.fatalError("Waiting timed out (readyState)")
				}
				Sleep 50
			}
			this.log(".browser ready")

			ControlGet, IES, hwnd,, Internet Explorer_Server1, % "ahk_id" this.controls.gui
			this.controls.IES := IES
			DllCall("ole32\RevokeDragDrop", "UPtr", IES)

			if !A_IsCompiled {
				Loop {
					try
						if this.wnd.inject.done
							break
					if (A_Index-1 > 50*100)
						this.fatalError("Waiting timed out (inject)")

					Sleep 50
				}
				this.log(".injected")
			}
			this.wnd.ahk := this.creator
			this.wnd.gui := this
			this.wnd.console := this.console
			this.wnd.ready()
		}
		Gui Margin, % conf.margin, % conf.margin
	}

	fatalError(what) {
		Msgbox 16, Fatal error, EzGui encountered a fatal error and will exit`n%what%
		ExitApp 1
	}

	wnd {
		get {
			return this.wb.Document.parentWindow
		}
	}

	doc {
		get {
			return this.wb.Document
		}
	}

	class console {
		log(a) {
			debug.print(a, {label: "JsConsole"})
		}

		error(a) {
			Msgbox % a
		}
	}

	handleExit(Reason, Code) {
		if (contains(Reason, ["Shutdown"]) || Code = -1)
			return

		if IsObject(this.creator.shouldExit) {
			if !this.creator.shouldExit() {
				return 1
			}
		}
		return
	}

	exit() {
		ExitApp 0
	}

	close() {
		if IsObject(this.creator.close) {
			return this.creator.close()
		} else {
			ExitApp 0
		}
	}

	minimize() {
		Gui % this.controls.gui ":minimize"
	}

	maximize() {
		Gui % this.controls.gui ":maximize"
	}

	AddControl(byref name, options := "", value := "") {
		if (RegExMatch(options, "O)v(?<id>\w+)", match)) {
			id := match.id
			options := StrReplace(options, match.0, "+hwndhwnd")
		}

		Gui % this.controls.gui ":add", %name%, %options%, %value%
		if (id)
			this.controls[id] := hwnd
	}

	ControlGet(byref name) {
		control := this.controls[name]
		if !control
			Throw Exception("No control found: " name, -1)
		return control
	}

	setControl(byref name, byref value) {
		control := this.ControlGet(name)
		GuiControl,, %control%, %value%
	}

	getControl(byref name) {
		control := this.ControlGet(name)
		GuiControlGet value,, %control%
		return value
	}

	optionControl(byref name, byref option) {
		control := this.ControlGet(name)
		GuiControl %option% +Redraw, %control%
	}

	resetFont() {
		Gui Font
		Gui Font, cababab
	}

	focus() {
		Gui % this.controls.gui ":Default"
	}

	toggle() {
		this.visible := !this.visible
	}

	CaptionMove() {
		PostMessage 0xA1, 2,,, % "ahk_id " this.controls.gui
	}

	Options(options) {
		Gui % this.controls.gui ":" options
	}

	visible {
		get {
			return this._visible
		}

		set {
			this.focus()
			conf := this.config
			this._visible := value
			if (value) {
				w := conf.w
				h := conf.h
				if conf.fixsize {
					VarSetCapacity(rect, 16, 0)
					DllCall("AdjustWindowRectEx"
					, "Ptr", &rect ;  LPRECT lpRect
					, "UInt", 0x80CE0000 ;  DWORD  dwStyle
					, "UInt", 0 ;  BOOL   bMenu
					, "UInt", 0 ;  DWORD  dwExStyle
					, "UInt") ; BOOL
					w += NumGet(&rect, 0, "Int")-NumGet(&rect, 8, "Int")
					h += NumGet(&rect, 4, "Int")-NumGet(&rect, 12, "Int")
					if !conf.resize {
						w += 10
						h += 10
					}
				}
				Gui Show, % (conf.autosize ? "AutoSize" : "w" w " h" h) " " conf.showoptions
			} else {
				Gui hide
			}
		}
	}


	Delete() {
		this.messages.Delete()
		this.messages := ""

		this.events.Delete()
		this.events := ""

		Gui % this.controls.gui ":Destroy"
		this.creator := ""
	}

	__Delete() {
		this.log(".Deleted EzGui of " this.parentname)
	}

	initHooks() {
		if !this.config.browser {
			this.creator.buildGui(this)

			this.events := new EventManager(this)
			this.creator.events(this.events)
		}

		this.messages := new MessageManager(this)
		this.initMessages()
		this.creator.messages(this.messages)
	}

	initMessages() {
		conf := this.config
		if (conf.dark && !conf.browser) {
			this.messages.add(0x0135, "WM_CTLCOLORBTN", true)
		}

		this.messages.add(0x112, "WM_SYSCOMMAND", true)

		if !conf.caption {
			this.messages.add(0x84, "WM_NCHITTEST", true)
			this.messages.add(0x83, "WM_NCCALCSIZE", true)
			this.messages.add(0x86, "WM_NCACTIVATE", true)
		}

		if conf.browser {
			this.messages.add(0x06, "WM_ACTIVATE", true)
			this.messages.add(0x100, "WM_KEYDOWN", true)
		}

		if conf.resize {
			this.messages.add(0x5, "WM_SIZE", true)
		}
	}

	WM_CTLCOLORBTN(wParam, lParam) {
		GuiColor = 1d1f21
		B := SubStr(GuiColor, 5, 2)
		G := SubStr(GuiColor, 3, 2)
		R := SubStr(GuiColor, 1, 2)
		return DllCall("Gdi32.dll\CreateSolidBrush", "UInt", "0x" B G R)
	}

	WM_KEYDOWN(wParam, lParam, Msg) {
		if (Chr(wParam) ~= "[A-Z]" || wParam = 0x74)
			return

		pipa := ComObjQuery(this.wb, "{00000117-0000-0000-C000-000000000046}")
		VarSetCapacity(kMsg, 48), NumPut(A_GuiY, NumPut(A_GuiX
		, NumPut(A_EventInfo, NumPut(lParam, NumPut(wParam
		, NumPut(Msg, NumPut(this.controls.IES, kMsg)))), "uint"), "int"), "int")
		Loop 2
			r := DllCall(NumGet(NumGet(1*pipa)+5*A_PtrSize), "ptr", pipa, "ptr", &kMsg)
		until wParam != 9 || this.wb.Document.activeElement != ""
			ObjRelease(pipa)
		if r = 0
			return 0
	}

	WM_ACTIVATE(wParam, lParam, args*) {
		if (A_Gui != this.controls.gui)
			return

		this.wnd.activate(wParam)
	}

	WM_SYSCOMMAND(wParam, lParam, args*) {
		if (A_Gui != this.controls.gui)
			return

		switch wParam {
			Case "0xF020":
				return this.minimize()
			Case "0xF060":
				return this.close()
		}
	}

	WM_NCCALCSIZE(wParam, lParam) {
		if (A_Gui != this.controls.gui)
			return
		return 0
	}

	WM_NCACTIVATE(args*) {
		if (A_Gui != this.controls.gui)
			return
		return 1
	}


	WM_NCHITTEST(wParam, lParam, args*) {
		static HT_VALUES := [[13, 12, 14], [10, 1, 11], [16, 15, 17]]
		if (A_Gui != this.controls.gui)
			return
		border := this.config.bordersize
		x := lParam<<48>>48
		y := lParam<<32>>48
		WinGetPos wX, wY, wW, wH, % "ahk_id" this.controls.gui

		row := (x < wX + border) ? 1 : (x >= wX + wW - border) ? 3 : 2
		col := (y < wY + border) ? 1 : (y >= wY + wH - border) ? 3 : 2

		return HT_VALUES[col, row]
	}


	WM_SIZE(wParam, lParam, args*) {
		if (A_Gui != this.controls.gui)
			Return

		if this.config.browser {
			w := lParam<<48>>48
			h := lParam<<32>>48
			DllCall("MoveWindow", "UPtr", this.controls.wb, "Int", 0, "Int", 0, "Int", w, "Int", h, "UInt", 0)
		}
		return 1
	}
}

class MessageManager {
	__New(_this) {
		this._this := _this
		this.messages := {}
	}

	Add(num, bind, isEventHook := false) {
		bindie := (isEventHook) ? this._this : this._this.creator
		this.messages[num] := {num: num, obj: ObjBindMethod(bindie, bind)}
		OnMessage(num, this.messages[num].obj)
	}

	Remove(name) {
		if !IsObject(this.messages[name]) {
			Throw "Message " name " not found!"
		}

		data := this.messages[name]
		OnMessage(data.num, data.obj, 0)
		this.messages.delete(name)
	}

	Delete() {
		for key, value in this.messages {
			this.Remove(key)
		}

		this.parentname := this._this.parentname
		this._this := ""
	}
}

class EventManager {
	__New(_this) {
		this._this := _this
		this.list := {}
	}

	Add(id, functionname) {
		hwnd := this._this.controls[id]
		if !hwnd
			Throw "Id not found!"
		this.list[hwnd] := {}
		handler := this.list[hwnd].handler := ObjBindMethod(this._this.creator, functionname)
		GuiControl +g, %hwnd%, %handler%
	}

	Delete() {
		for key, value in this.list {
			GuiControl -g, %key%
		}
		this.parentname := this._this.parentname
		this._this := ""
	}
}

class BrowserEvent {
	DocumentComplete(wb) {
		this.doc := wb.Document
		ComObjConnect(this.doc, new BrowserEvent)
	}

	OnKeyPress(doc) {
		static inputs := ["input", "textarea", "code"]
		static keys := {1: {name: "selectall"}, 3:{name: "copy", allow: true}, 22:{name: "paste"}, 24:{name: "cut"}}
		keyCode := doc.parentWindow.event.keyCode
		if keys.HasKey(keyCode) {
			allow := false
			key := keys[keyCode]
			if key.allow {
				allow := true
			} else {
				for _, input in inputs {
					if (doc.activeElement.tagName = input) {
						allow := true
						break
					}
				}
			}
			if allow {
				doc.ExecCommand(key.name)
			}
		}
	}
}