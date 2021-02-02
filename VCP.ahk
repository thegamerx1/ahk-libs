class VCP {
	__New(monitornum := 0) {
		monitorhandle := DllCall("MonitorFromPoint", "int64", monitornum, "uint", 1)
		VarSetCapacity(Physical_Monitor, 8 + 256, 0)
		DllCall("dxva2\GetPhysicalMonitorsFromHMONITOR", "int", monitorhandle, "uint", 1, "int", &Physical_Monitor)
		this.handle := NumGet(Physical_Monitor)
	}

	send(code, number := 0) {
		DllCall("dxva2\SetVCPFeature", "int", this.handle, "char", code, "uint", number)
	}

	get(code) {
		DllCall("dxva2\GetVCPFeatureAndVCPFeatureReply", "int", this.handle, "char", code, "Ptr", 0, "uint*", currentValue, "uint*", maximumValue)
		return {current: currentValue, max: maximumValue}
	}

	delete() {
		DllCall("dxva2\DestroyPhysicalMonitor", "int", this.handle)
	}
	__Delete() {
		this.delete()
	}
}