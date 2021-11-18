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

GetPixelColor(pos) {
	PixelGetColor color, pos["x"], pos["y"], Fast RGB
	return color
}

ImageSearch(image, variation := 0, x0 := 0, y0 := 0, x1 := -1, y1 := -1) {
	if (x1 == -1 && y1 == -1) {
		x1 := A_ScreenWidth
		y1 := A_ScreenHeight
	}
	ImageSearch x, y, % x0, % y0, % x1, % y1, % "*" variation " " image
	Switch (ErrorLevel) {
		case 0:
			Return {x: x, y: y}
		case 1:
			return
		case 2:
			throw Exception("Error conducting imagesearch`n" image "`n" x0 "x" y0 " to " x1 "x" y1, -1)
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

MouseMove(x,y, speed := 0) {
	if IsObject(x) {
		speed := y
		y := x.y
		x := x.x
	}
	MouseMove %x%, %y%, %speed%
}