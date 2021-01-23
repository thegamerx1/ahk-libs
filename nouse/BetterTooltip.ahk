#Include <timer>
class BetterTooltip {
	__New(text := "", time := 0, follow := false, show := true, x := 0, y := 0) {
		this.timers := {}
		this.timers.stop := new timer(this.stop.bind(this), -this.time, true)
		this.timers.follow := new timer(this.followroutine.bind(this), 14, true)
		this.time := time*1000
		this._text := text
		this._follow := follow
		this.pos := {x: x, y: y}

		if (time) {
			this.timers.stop.enabled := true
		}
		if (show)
			this.RefreshTooltip()
	}

	__Delete() {
		this.timers := ""
		Tooltip
	}

	text {
		get {
			return this._text
		}

		set {
			this._text := value
			this.RefreshTooltip()
		}
	}

	follow {
		get {
			return this._follow
		}

		set {
			this.timers.follow.enabled := value
			this._follow := value
		}
	}

	RefreshTooltip() {
		Tooltip % this._text, % this.pos.x, % this.pos.y
	}

	followroutine() {
		MouseGetPos x, y
		if ((x != this.oldx) || (y != this.oldy)) {
			this.pos.x := x
			this.pos.y := y + 8
			this.RefreshTooltip()
		}
		this.oldx := x
		this.oldy := y
	}

	stop() {
		if (this.follow)
			this.timers.follow.enabled := false

		this.timers.stop.enabled := false
		Tooltip
	}
}