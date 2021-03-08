class VCP {
	__New(cords) {
		VarSetCapacity(coord, 8)
		NumPut(cords.x, coord, 0, "Int")
		NumPut(cords.y, coord, 4, "Int")
		monitorhandle := DllCall("MonitorFromPoint", "Int64", NumGet(coord, 0, "ptr"), "UInt", 1)
		VarSetCapacity(Physical_Monitor, 8 + 256, 0)
		this.module := DllCall("LoadLibrary", "Str", "dxva2.dll", "Ptr")
		DllCall("dxva2\GetPhysicalMonitorsFromHMONITOR", "int", monitorhandle, "uint", 1, "int", &Physical_Monitor)
		this.handle := NumGet(Physical_Monitor)
	}

	send(code, number := 0) {
		DllCall("dxva2\SetVCPFeature", "int", this.handle, "char", code, "uint", number)
	}

	get(code) {
		currentValue := maximumValue := 0
		DllCall("dxva2\GetVCPFeatureAndVCPFeatureReply", "int", this.handle, "char", code, "Ptr", 0, "uint*", currentValue, "uint*", maximumValue)
		return {current: currentValue, max: maximumValue}
	}

	close() {
		if this.module {
			DllCall("dxva2\DestroyPhysicalMonitor", "int", this.handle)
			DllCall("FreeLibrary", "Ptr", this.module)
		}
	}
	__Delete() {
		this.close()
	}
}