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