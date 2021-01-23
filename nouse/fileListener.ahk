#include <timer>
class fileListener {
	__new(file, func, interval := 1000) {
		if !(FileExist(file))
			Throw "The file " file " doesnt exist!"

		this.file := file
		this.interval := interval
		this.func := func

		FileGetTime time, % this.file
		this.start := time
		this.loop := new timer(ObjBindMethod(this, "check"), interval)
	}

	__Delete() {
		this.loop.__Delete()
	}

	check() {
		FileGetTime time, % this.file
		if !(this.start = time) {
			this.func.call()
			this.start := time
		}
	}
}