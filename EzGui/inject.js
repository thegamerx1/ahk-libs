document.oncontextmenu =
document.ondragstart = function () { return false }

window.onload = function () {
	function injectcss(url) {
		let element = document.createElement("link")
		element.rel = "stylesheet"
		element.href = url
		element.type = "text/css"
		element.async = false
		element.onload = function () {inject.count++;injectCheck()}
		document.body.appendChild(element)
		inject.countTo++
	}
	function injectjs(url) {
		let element = document.createElement("script")
		element.src = url
		element.async = false
		element.onload = function () {inject.count++;injectCheck()}
		document.body.appendChild(element)
		inject.countTo++
	}

	if (typeof inject == "undefined") {
		inject = {}
		inject.path = "file:///C:/Users/TheGamerX05/Documents/Autohotkey/Lib/EzGui/"
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
	console.log("INJECTED HGARD")
}


function injectCheck() {
	if (inject.count >= inject.countTo) {
		if (!window.document.documentMode) {
			enableDebug()
		}
	}
}

function enableDebug() {
	isAHK = false
	activate(1)
	ready()
	debug()
}