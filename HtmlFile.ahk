class HtmlFile {
	__New(byref data) {
		static compatibility := "<meta http-equiv=""X-UA-Compatible"" content=""IE=9"">"
		html := ComObjCreate("HTMLfile")
		html.write(compatibility data)
		this.html := html
	}

	qs(byref sel) {
		return this.html.querySelector(sel)
	}

	qsa(byref sel) {
		return this.html.querySelectorAll(sel)
	}

	Each(collection) {
		return new this.Enumerable(collection)
	}

	; ? Stolen from https://github.com/G33kDude/Neutron.ahk
	class Enumerable {
		i := 0
		__New(collection) {
			this.collection := collection
		}

		_NewEnum() {
			return this
		}

		Next(ByRef i, ByRef elem) {
			if (this.i >= this.collection.length)
				return False
			i := this.i
			elem := this.collection.item(this.i++)
			return True
		}
	}
}