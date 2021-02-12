#include <OrderArray>
class textrower {
	__New(spacing, columns) {
		this.spacing := spacing
		this.columns := columns
		this.data := {}
		for _, value in this.columns {
			this.data[value.name] := []
		}
	}

	addRow(column, data) {
		this.data[column].push(data)
	}

	get() {
		lines := this.prepareLines()
		columns := {}
		for _, v in this.columns {
			; ? get length
			big := StrLen(v.name)
			for _, row in this.data[v.name] {
				now := StrLen(row)
				if (now > big)
					big := now
			}
			columns[A_Index] := big+this.spacing

			for _, row in this.data[v.name] {
				length := columns[A_Index]-StrLen(row)
				switch v.align {
					case "left":
						data := row strMultiply(" ", length)
					case "right":
						data := strMultiply(" ", length) row
				}
				lines[A_Index].data .= data
			}
		}

		out := ""
		lines.InsertAt(1, {})
		for _, v in this.columns {
			out .= v.name strMultiply(" ",  columns[A_Index]-StrLen(v.name)+this.spacing)
			lines[1].data .= strMultiply("-", columns[A_Index]) strMultiply(" ", this.spacing)
		}
		out .= "`n"
		for _, line in lines {
			out .= line.data "`n"
		}
		return out
	}

	prepareLines() {
		lines := {}
		for key, value in this.columns {
			for key, value in value {
				lines[A_Index] := {}
			}
		}
		return lines
	}
}
#include <mustExec>
debug.init()
test := new textrower(4, [{align: "left", name: "Item"}
							,{align: "left", name: "Quantify"}
							,{align: "left", name: "Available"}])


test.addRow("Item", "tomato")
test.addRow("Quantify", "500")
test.addRow("Available", "100%")

test.addRow("Item", "potatoo")
test.addRow("Quantify", "1000")
test.addRow("Available", "50%")
debug.print(test.get())
ExitApp

#include <functionsahkshouldfuckinghave>
#include <debug>