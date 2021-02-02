document.oncontextmenu =
document.ondragstart = function () { return false }

window.onload = function () {
	function injectcss(url) {
		let element = createElement("link")
		element.rel = "stylesheet"
		element.href = url
		element.type = "text/css"
		addElement(element)
	}
	function injectjs(url) {
		let element = createElement("script")
		element.src = url
		addElement(element)
	}

	function createElement(name) {
		let element = document.createElement(name)
		element.async = false
		element.onload = injectCheck.bind(1)
		element.onerror = function() {console.error("error in " + name)}
		return element
	}

	function addElement(element) {
		inject.countTo++
		document.body.appendChild(element)
	}

	if (typeof inject == "undefined") {
		inject = {}
		inject.path = "file:///C:/Users/TheGamerX/Documents/Autohotkey/Lib/EzGui/"
	}

	inject.count = 0
	inject.countTo = 0

	injectcss(inject.path + "libs/bootstrap-dark.min.css")
	injectcss(inject.path + "minify/default.css")
	injectjs(inject.path + "libs/polyfill.min.js")
	injectjs(inject.path + "minify/funcs.js")
	injectjs(inject.path + "libs/webcomponents.js")
	injectjs(inject.path + "minify/titlebar.js")
	injectjs(inject.path + "libs/bootstrap.min.js")
	console.log("INJECTED")
}


function injectCheck(inc) {
	if (inc) inject.count++
	if (inject.count >= inject.countTo) {
		console.log("All injected")
		if (!window.document.documentMode) {
			enableDebug()
		}
		inject.done = true
	}
}

function enableDebug() {
	isAHK = false
	activate(1)
	ready()
	debug()
}