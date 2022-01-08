document.oncontextmenu = document.ondragstart = function () {
	return false
}

window.onload

if (!window.document.documentMode) {
	isAHK = false
	activate(1)
	ready()
	debug()
}
