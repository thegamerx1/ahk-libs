random(min:=0, max:=1) {
	Random result, Min, Max
	Return result
}

randomSeed(seed := "") {
	if !seed
		seed := random(0, 2147483647)
	random,, %seed%
}
; bigrandom(Min:=0, Max:=1) {
; 	return ("", VarSetCapacity(CSPHandle, 8, 0), VarSetCapacity(RandomBuffer, 8, 0), DllCall("advapi32.dll\CryptAcquireContextA", "Ptr", &CSPHandle, "UInt", 0, "UInt", 0, "UInt", PROV_RSA_AES := 0x00000018,"UInt", CRYPT_VERIFYCONTEXT := 0xF0000000), DllCall("advapi32.dll\CryptGenRandom", "Ptr", NumGet(&CSPHandle, 0, "UInt64"), "UInt", 8, "Ptr", &RandomBuffer), DllCall("advapi32.dll\CryptReleaseContext", "Ptr", NumGet(&CSPHandle, 0, "UInt64"), "UInt", 0)) (Abs(NumGet(&RandomBuffer, 0, "UInt64") / 2 ** 64) * (Max - Min)) + Min
; }

; random_keyboard(length) {
; 	randomkeys := "asda9sdaowasd asdbawodonnwbdbnoa8wsdnoawodnianoida9dnaodnoianioda9dndfnrut4537t4ntksdgnosdngosaoifgwnoetfgb9uwegfubieifsdobufgieuoiyr6uu4r6yh6h57ni7im5758im64un546ybw35tybq3y4qv5t345tvq34tv4tv34tv3w4t234tvq34vtq3y45y546u 56u 5b uji57i6b kjb 56b4yvwrgegh4y5ui67i67 ik567ui5uy4b5t 3e4r t43e 4tv3 4tv3 345tvq5yb4w45uu4w6 46uniw56e 4mi56e im4 5un5 yy53SASFSEuyiFSEBg uSE OUJnbgJKS EG IS IIYBE TBOIiojadniaindinoad9adnoianiodnoiadasnd iwaods9dwndia nsidan9w0dnawndansndpowaod0 sdniwaidniosdniownoiad 90n90iandianioniodniosdoniawnoidnoiafoniion4tnioeniofionsoinedfieoigwoieofih40rihjjhdfowebifhb320fuiebfsoefbb4uwht09uth4bg90ubdsejth304t89rfjnsdfhwepr843thidfhnspoeiru3849thdsiofnsidofjpsf8efuy3894fhjesduifhsdifsjef9038hf8hsdifhjeio23ho23809fsruwieth98th98hrouighhoifdiitbsawnd5yb3eseropasodjwjrojosjopafjoerj043t0hefj0nnmvvnt904836829anvbvbbuirebuitebuibuifabfu3b7984t8yb9yb89tyb08t40yb8t408yb1t0yb8tyb80t34bvsvbñabpqoeroeybxncbvasdwqdadd9uhudfhawhoupifhuifhupoawhuporhupp48hep9h4t3ebyp4beh89pb4ah89a4tbhbaunotbanwoñbtnño4btañba4p4a9opbawb12952497gta7g234bth4buirbi3252352689389497987527341v985vg18934o6iug456bh345076384n634789b630m46ny06324y4542434948476nb3406mb34b634,v5vnm3b4n0y65n4723109710y9541yy74y9765yn9bn4y3906ny09b45ny90b63n4y09756ny70945y7n0936y07n9y97021790udhuoasdhuawoudahoiudohuiahuoidahuowhudohuoawuh0r0jtntdhf24r908hdsufshdf"
; 	return SubStr(randomkeys, random(1, StrLen(randomkeys)), length)
; }