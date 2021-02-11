class HtmlFile {
	__New(data) {
		html := ComObjCreate("HTMLfile")
		html.write(data)
		this.html := html
	}

	qs(sel) {
		return this.html.querySelector(sel)
	}

	qsa(sel) {
		return this.html.querySelectorAll(sel)
	}

	Each(collection) {
		return new this.Enumerable(collection)
	}

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