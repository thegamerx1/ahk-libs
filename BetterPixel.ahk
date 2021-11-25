ColorDiff(c1, c2) {
	c1 := ToRGB(c1)
	c2 := ToRGB(c2)
	return abs(c1.red - c2.red) + abs(c1.green - c2.green) + abs(c1.blue - c2.blue)
}

ToRGB(color) {
	RegExMatch(color, "O)(0x)?(?<red>\w{2})(?<green>\w{2})(?<blue>\w{2})", match)
	return {red: ToDecimal("0x" match.red), green: ToDecimal("0x" match.green), blue: ToDecimal("0x" match.blue)}
}

ToDecimal(Hex) {
	Return Format("{:u}", hex)
}

GetMousePos() {
	MouseGetPos x, y
	return {x: x, y: y}
}

PixelSearch(color, variation := 0, x0 := 0, y0 := 0, x1 := 0, y1 := 0) {
	if (x1 == 0 && y1 == 0) {
		mon := GetMonitor(1)
		x0 := mon.x
		y0 := mon.y
		x1 := mon.width
		y1 := mon.height
	}
	PixelSearch x, y, % x0, % y0, % x1, % y1, % color, % variation, Fast RGB
	Switch (ErrorLevel) {
		case 0:
			Return {x: x, y: y}
		case 1:
			return
		case 2:
			throw Exception("Error conducting PixelSearch`n" color "`n" x0 "x" y0 " to " x1 "x" y1, -1)
	}
}

WaitPixelSearch(color, timeout := 200, variation := 0, x0 := 0, y0 := 0, x1 := 0, y1 := 0, timer := 50) {
	start := A_TickCount
	loop {
		pos := PixelSearch(color, variation, x0, y0, x1, y1)
		if IsObject(pos) {
			break
		}
		if (timeout != 0) {
			if (A_TickCount - start > timeout) {
				break
			}
		}
		if (timer != 0) {
			sleep % timer
		}
	}
	return pos
}

PixelColor(pos) {
	PixelGetColor color, % pos.x, % pos.y, Fast RGB
	return color
}

WaitPixel(pos, color, timeout := 100, not := false, timer := 50) {
	start := A_TickCount
	loop {
		pixel := PixelColor(pos)
		if (not && pixel != color) {
			break
		}
		if (!not && ColorDiff(pixel, color) <= 10) {
			break
		}

		if (timeout != 0) {
			if (A_TickCount - start > timeout) {
				break
			}
		}
		sleep % timer
	}
	return {color: pixel, pos: pos}
}

ImageSearch(image, variation := 0, x0 := 0, y0 := 0, x1 := -1, y1 := -1) {
	if !IsObject(image) {
		image := [image]
	}
	if (x1 == -1 && y1 == -1) {
		x1 := A_ScreenWidth
		y1 := A_ScreenHeight
	}
	for index, image in image {
		try {
			ImageSearch x, y, % x0, % y0, % x1, % y1, % "*" variation " " image
		} catch e {
			throw Exception("Error conducting imagesearch`n" image "`n" x0 "x" y0 " to " x1 "x" y1, -1)
		}
		Switch (ErrorLevel) {
			case 0:
				Return {x: x, y: y, index: index}
			case 1:
				continue
			case 2:
				throw Exception("Error conducting imagesearch`n" image "`n" x0 "x" y0 " to " x1 "x" y1, -1)
		}
		return
	}
}

WaitImage(image, variation := 0, timeout := 0, x0 := 0, y0 := 0, x1 := -1, y1 := -1) {
	start := A_TickCount
	loop {
		pos := ImageSearch(image, variation, x0, y0, x1, y1)
		if IsObject(pos) {
			break
		}
		if (timeout != 0) {
			if (A_TickCount - start > timeout) {
				break
			}
		}
		sleep 50
	}
	return pos
}

Click(x, y := 0, sleep := 0) {
	if IsObject(x) {
		sleep := y
		y := x.y
		x := x.x
	}
	Click %x%, %y%
	if (sleep != 0) {
		sleep % sleep
	}
}

MouseMove(x,y := 0, speed := 0) {
	if IsObject(x) {
		speed := y
		y := x.y
		x := x.x
	}
	MouseMove %x%, %y%, %speed%
}

GetAllMonitors() {
	SysGet count, MonitorCount
	array := []
	loop %count%
	{
		array.push(GetMonitor(A_Index))
	}
	return array
}

GetMonitor(num) {
	SysGet mon, Monitor, %num%
	SysGet name, MonitorName, %num%
	return {x: monLeft
		,y: monTop
		,width: monRight - monLeft
		,height: monBottom - monTop
		,name: name}
}

GetFullWorkarea() {
	monitors := GetAllMonitors()
	x0 := x1 := y0 := y1 := 0
	for _, value in monitors {
		if (value.x < x0) {
			x0 := value.x
		}
		if (value.y < y0) {
			y0 := value.y
		}
		if (value.x + value.width > x1) {
			x1 := value.x + value.width
		}
		if (value.y + value.height > y1) {
			y1 := value.y + value.height
		}
	}
	return {x0: x0, y0: y0, x1: x1 - x0, y1: y1 - y0}
}