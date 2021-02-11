#Include <json>
#Include <functionsahkshouldfuckinghave>
class configloader {
	__New(file, default := "") {
		this.file := file
		this.default := IsObject(default) ? default : {}
		if !(FileExist(this.file))
			this.fixfile()

		this.loadfile()
		if !(isObject(this.data)) {
			this.fixfile()
		}
	}

	fixfile() {
		debug.print("Fixing", {label: this.file})

		file := FileOpen(this.file, "w")
		file.Write(JSON.dump(this.default))
		file.close()
		this.loadfile()
	}

	loadfile() {
		this.data := ObjectMerge(JSON.Load(fileopen(this.file, "r").read()), this.default)
	}

	save() {
		debug.print("Saving", {label: this.file})

		file := FileOpen(this.file, "w")
		file.write(JSON.Dump(this.data))
		file.close()
	}
}