class GuiClass {
	SetColor(color, hwnd) {
		GuiControl +c%color% +Redraw, %hwnd%
	}

	SetIcon(icon, hwnd) {
		hIcon := DllCall("LoadImage", UInt,0, Str, icon, UInt, 1, UInt, 0, UInt, 0, UInt, 0x10)
		SendMessage 0x80, 0, hIcon,, % "ahk_id" hwnd
		SendMessage 0x80, 1, hIcon,, % "ahk_id" hwnd
	}

	ButtonIcon(Handle, File, Index := 1, Options := "") {
		RegExMatch(Options, "i)w\K\d+", W), (W="") ? W := 16 :
		RegExMatch(Options, "i)h\K\d+", H), (H="") ? H := 16 :
		RegExMatch(Options, "i)s\K\d+", S), S ? W := H := S :
		RegExMatch(Options, "i)l\K\d+", L), (L="") ? L := 0 :
		RegExMatch(Options, "i)t\K\d+", T), (T="") ? T := 0 :
		RegExMatch(Options, "i)r\K\d+", R), (R="") ? R := 0 :
		RegExMatch(Options, "i)b\K\d+", B), (B="") ? B := 0 :
		RegExMatch(Options, "i)a\K\d+", A), (A="") ? A := 4 :
		Psz := A_PtrSize = "" ? 4 : A_PtrSize, DW := "UInt", Ptr := A_PtrSize = "" ? DW : "Ptr"
		VarSetCapacity( button_il, 20 + Psz, 0 )
		NumPut( normal_il := DllCall( "ImageList_Create", DW, W, DW, H, DW, 0x21, DW, 1, DW, 1 ), button_il, 0, Ptr )	; Width & Height
		NumPut( L, button_il, 0 + Psz, DW )		; Left Margin
		NumPut( T, button_il, 4 + Psz, DW )		; Top Margin
		NumPut( R, button_il, 8 + Psz, DW )		; Right Margin
		NumPut( B, button_il, 12 + Psz, DW )	; Bottom Margin
		NumPut( A, button_il, 16 + Psz, DW )	; Alignment
		SendMessage BCM_SETIMAGELIST := 5634, 0, &button_il,, AHK_ID %Handle%
		return IL_Add( normal_il, File, Index )
	}
}