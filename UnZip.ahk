UnZip(zipFile, fileInside, saveTo) {
	static script = "
	(
		param($zipFile, $fileInside, $saveTo)
		Add-Type -Assembly System.IO.Compression.FileSystem
		$zip = [IO.Compression.ZipFile]::OpenRead($zipFile)
		$zip.Entries | where {$_.Name -eq $fileInside} | foreach {[System.IO.Compression.ZipFileExtensions]::ExtractToFile($_, $saveTo)}
		$zip.Dispose()
	)"

	RunWait PowerShell.exe -Command &{%script%} "%zipFile%" "%fileInside%" "%saveTo%",, hide
}