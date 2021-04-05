class counter {
	__New(count := 2, legacy := false) {
		if legacy {
			this.legacy := true
			this.starttime := A_TickCount
		} else {
			this.count := count
			DllCall("QueryPerformanceFrequency", "Int64*", freq := 0)
			this.freq := freq
			DllCall("QueryPerformanceCounter", "Int64*", before := 0)
			this.before := before
		}
	}

	Reset() {
		out := this.get()
		this.__New(this.count, this.legacy)
		return out
	}

	Get() {
		if this.starttime {
			time := A_TickCount - this.starttime
			return time ? time : 1
		} else {
			DllCall("QueryPerformanceCounter", "Int64*", after := 0)
			Return Round((after - this.before) / this.freq * 1000, this.count)
		}
	}
}