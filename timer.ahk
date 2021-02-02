class timer {
	__New(func, interval := 1000, start := true) {
		if !(IsFunc(func) || IsObject(func))
			Throw "Invalid func object sent!"

		this.func := func
		this._interval := interval
		if (start) {
			try {
				SetTimer % func, % interval
			} catch e {
				Throw Exception("Error creating timer: " e.message, -1)
			}
		}
	}

	__delete() {
		try {
			this.delete()
		}
	}

	delete() {
		func := this.func
		SetTimer % func, Delete
	}

	interval {
		get {
			return this._interval
		}

		set {
			this._interval := value
			func := this.func
			SetTimer % func, % this._interval
		}
	}

	enabled {
		get {
			return this._enabled
		}

		set {
			func := this.func
			if (value) {
				SetTimer % func, On
			} else {
				SetTimer % func, Off
			}
			this._enabled := value
		}
	}

}