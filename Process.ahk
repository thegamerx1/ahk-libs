GetProcessMemoryUsage(ProcessID) {
	static PMC_EX, size := NumPut(VarSetCapacity(PMC_EX, 8 + A_PtrSize * 9, 0), PMC_EX, "uint")

	if (hProcess := DllCall("OpenProcess", "uint", 0x1000, "int", 0, "uint", ProcessID)) {
		if !(DllCall("psapi\GetProcessMemoryInfo", "ptr", hProcess, "ptr", &PMC_EX, "uint", size))
			return (ErrorLevel := 2) & 0, DllCall("CloseHandle", "ptr", hProcess)
		DllCall("CloseHandle", "ptr", hProcess)
		return Round(NumGet(PMC_EX, 8 + A_PtrSize * 8, "uptr") / 1024**2, 2)
	}
	return (ErrorLevel := 1) & 0
}