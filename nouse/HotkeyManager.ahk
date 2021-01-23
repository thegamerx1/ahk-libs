class HotkeyManager {
	__New(parent) {
		this.parent := parent
		this.keylist := {}
	}

	add(keys, funcname, params := "", funcheck := "") {
		key := {}
		key.funcheck := funcheck
		func := ObjBindMethod(this.parent, funcname, params)
		this._createifwin(key)
		; func := ObjBindMethod(this, "cally", key)
		hotkey % keys, % func, On
		this._cleanifwin(key)
		this.keylist[keys] := key
	}

	; cally(key) {
	; 	this.currentkey := key
	; 	key.call(this)
	; }

	_createifwin(key) {
		fn := key.funcheck
		if (fn)
			hotkey if, % fn
	}

	_cleanifwin(key) {
		hotkey if
	}

	deletekey(keys) {
		keylist := this.keylist[keys]
		this._createifwin(keylist)
		f := func("DummyFunc")
		hotkey %keys%, %f%, Off
		this._cleanifwin(keylist)
		this.keylist.delete(keys)
	}

	delete() {
		for key, value in this.keylist {
			this.deletekey(key)
		}

		this.parentname := this.parent.base.__Class
		this.parent := ""
	}

	__delete() {
		this.delete()
	}
}