UnZip(zipFile, fileInside, saveTo) {
	local
	script =
	(
		param($zipFile, $fileInside, $saveTo)
		Add-Type -Assembly System.IO.Compression.FileSystem
		$zip = [IO.Compression.ZipFile]::OpenRead($zipFile)
		$zip.Entries | where {$_.Name -eq $fileInside} | foreach {[System.IO.Compression.ZipFileExtensions]::ExtractToFile($_, $saveTo)}
		$zip.Dispose()
	)

	Run PowerShell.exe -Command &{%script%} "%zipFile%" "%fileInside%" "%saveTo%",, hide
}
