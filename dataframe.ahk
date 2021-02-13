#include <OrderArray>
class dataframe {
	__New(data, spacing = 2) {
		this.spacing := spacing
		this.columns := []
		for _, col in data {
			this.columns.push(new dataframe.column(col.content, col.name))
		}
	}

	convertToData(obj) {
		out := []
		for key, value in obj {
			out.push({name: key, content: value})
		}
		return out
	}

	fromObj(obj, names) {
		temp := new OrderArray()
		indexes := []
		for key, value in obj {
			name := names[A_Index]
			if !name
				break

			temp[name] := []
			indexes[A_Index] := name
		}
		for key, value in obj {
			temp[indexes[1]].push(key)
			temp[indexes[2]].push(value)
		}
		return this.convertToData(temp)
	}

	class column {
		__New(content, name) {
			big := StrLen(name)
			for _, value in content {
				length := StrLen(value)
				big := length > big ? length : big
			}
			this.width := big
			this.rows := content
			this.length := content.length()
			this.name := name
		}
	}

	get() {
		lines := this.prepareLines()
		for _, col in this.columns {
			lines[1] .= col.name strMultiply(" ", col.width-StrLen(col.name)+this.spacing)
			lines[2] .= strMultiply("-", col.width+this.spacing/2) strMultiply(" ", this.spacing/2)
			for _, row in col.rows {
				lines[A_Index+2] .= row strMultiply(" ", col.width-StrLen(row)+this.spacing)
			}
		}

		out := ""
		for _, line in lines {
			out .= line "`n"
		}
		return out
	}

	prepareLines() {
		lines := {}
		total := 0
		for _, value in this.columns {
			if value.length > total
				total := value.length
		}
		total += 2
		Loop % total
			lines[A_Index] := ""
		return lines
	}
}