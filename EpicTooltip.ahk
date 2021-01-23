#include <ezConf>
#include <timer>

class EpicTooltip {
	__New(text, options := "") {
		Gui New, +AlwaysOnTop +Hwndhwnd -Caption +Border +Lastfound
		this.hwnd := hwnd
		options := ezConf(options, "followmouse=1 time=0 x=0 y=0 rows=1 center=1")
		Gui Margin, 3, 3
		Gui Color, 1d1f21, 282a2e
		Gui Font, ce3e3e3
		rows := options.rows
		center := (options.center) ? "0x200 Center" : "" ;0x200 : center text vertically
		Gui Add, Text, +HwndTextHwnd %center% h18 R%rows%, % text
		this.texthwnd := TextHwnd
		this._text := text

		if (options.followmouse)
			this.followtimer := new timer(this.followmouse.bind(this), 14)

		if !(options.time = 0)
			this.stoptimer := new timer(this.stop.bind(this), options.time)

		Gui %hwnd%:Show, NoActivate, x%x% y%y%
	}

	text {
		get {
			return this._text
		}

		set {
			this._text := value
			GuiControl,, % this.texthwnd, %value%
		}
	}

	__Delete() {
		Gui % this.hwnd ":Destroy"
	}

	delete() {
		this.followtimer.delete()
		this.followtimer := ""
		this.stoptimer.delete()
		this.stoptimer := ""
		Gui % this.hwnd ":Show", Hide
	}

	followmouse() {
		CoordMode Mouse, Screen
		MouseGetPos x, y
		if (this.oldposx = x && this.oldposy = y)
			return

		x += 10
		Gui % this.hwnd ":Show", NoActivate x%x% y%y%
		this.oldposx := x
		this.oldposy := y
	}
}