#Include <functionsahkshouldfuckinghave>
EzConf(conf := "", default := "") {
	if !IsObject(conf)
		conf := {}

	return IsObject(default) ? ObjectMerge(conf, default) : conf
}