;; ? Modified from some stackoverflow question

#include <requests>
#include <timer>

class fileDownloader {
	__New(url, saveTo, progressFunc, rate := 250) {
		this.url := url
		if (saveTo == "") {
			saveTo := StrSplit(url, ["/", "\"]).pop()
			if (saveTo == "")
				throw Exception("Invalid name", -1)
		}
		this.saveTo := saveTo
		this.progressFunc := progressFunc
		http := new requests("HEAD", url)
		response := http.send()
		this.FinalSize := response.headers["Content-Length"]

		this.LastSizeTick := 0
		this.LastSize := 0
		progressFunc.call(-1, Floor(this.FinalSize/1024/1024) "MB")
		this.timer := new timer(ObjBindMethod(this, "check"), rate)
		UrlDownloadToFile %url%, %saveTo%
		progressFunc.call(100, "Done")
		this.timer.delete()
	}

	check() {
        this.CurrentSize := FileOpen(this.saveTo, "r").Length
        this.CurrentSizeTick := A_TickCount
        Speed := Round((this.CurrentSize/1024-this.LastSize/1024)/((this.CurrentSizeTick-this.LastSizeTick)/1000))
        SpeedUnit := "KB/s"

        if (Speed > 1024) {
            SpeedUnit := "MB/s"
            Speed := Round(Speed/1024, 2)
        }
		if !speed {
			speed = Unkown
		}


        if this.FinalSize {
            PercentDone := Round(this.CurrentSize/this.FinalSize*100)
        } else {
            PercentDone := 10
        }

        this.LastSizeTick := this.CurrentSizeTick
        this.LastSize := FileOpen(this.saveTo, "r").Length
        this.progressFunc.call(PercentDone, Speed SpeedUnit)
	}
}