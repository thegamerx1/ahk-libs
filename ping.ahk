;https://gist.github.com/Uberi/5987142
Ping(Address, Timeout := 800) {
	data := length := 0
	if DllCall("LoadLibrary","Str","ws2_32","UPtr") = 0
		throw Exception("Could not load WinSock 2 library")
	if DllCall("LoadLibrary","Str","icmp","UPtr") = 0
		throw Exception("Could not load ICMP library")

	NumericAddress := DllCall("ws2_32\inet_addr","AStr", Address, "UInt")
	if NumericAddress = 0xFFFFFFFF ;INADDR_NONE
		throw Exception("Invalid IP")

	hPort := DllCall("icmp\IcmpCreateFile","UPtr") ;open port
	if hPort = -1 ;INVALID_HANDLE_VALUE
		throw Exception("Could not open port")

	StructLength := 270 + (A_PtrSize * 2) ;ICMP_ECHO_REPLY structure
	VarSetCapacity(Reply,StructLength)
	Count := DllCall("icmp\IcmpSendEcho"
		,"UPtr",hPort ;ICMP handle
		,"UInt",NumericAddress ;IP address
		,"UPtr",&Data ;request data
		,"UShort",Length ;length of request data
		,"UPtr",0 ;pointer to IP options structure
		,"UPtr",&Reply ;reply buffer
		,"UInt",StructLength ;length of reply buffer
		,"UInt",Timeout) ;ping timeout
	;IP_BUF_TOO_SMALL
	if NumGet(Reply,4,"UInt") = 11001 {
		StructLength *= Count
		VarSetCapacity(Reply,StructLength)
		DllCall("icmp\IcmpSendEcho"
			,"UPtr",hPort ;ICMP handle
			,"UInt",NumericAddress ;IP address
			,"UPtr",&Data ;request data
			,"UShort",Length ;length of request data
			,"UPtr",0 ;pointer to IP options structure
			,"UPtr",&Reply ;reply buffer
			,"UInt",StructLength ;length of reply buffer
			,"UInt",Timeout) ;ping timeout
	}

	if !DllCall("icmp\IcmpCloseHandle","UInt", hPort) ;close port
		throw Exception("Could not close port")

	if contains(Status, [11002,11003,11004,11005,11010]) {
		Return -1
	}

	if NumGet(Reply,4,"UInt") != 0 ;IP_SUCCESS
		throw Exception("Could not send echo")

	Return NumGet(Reply, 8, "UInt")
}