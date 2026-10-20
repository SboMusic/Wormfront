param()
$ErrorActionPreference='Stop'
$taskRoot=Split-Path -Parent $PSScriptRoot
$taskName='Wormfront-0.20.0-Windows-x64'
$taskPortable=Join-Path $taskRoot "dist/$taskName"
if(-not (Test-Path -LiteralPath (Join-Path $taskPortable 'Wormfront.exe'))) {throw 'Esegui prima build_windows.ps1.'}
$taskHashes=foreach($taskFile in Get-ChildItem -LiteralPath $taskPortable -Recurse -File | Where-Object Name -ne 'SHA256SUMS.txt') {
 $taskRelative=$taskFile.FullName.Substring($taskPortable.Length).TrimStart([char[]]'\/').Replace('\','/')
 ((Get-FileHash -LiteralPath $taskFile.FullName -Algorithm SHA256).Hash.ToLowerInvariant())+'  '+$taskRelative
}
$taskHashes | Set-Content -LiteralPath (Join-Path $taskPortable 'SHA256SUMS.txt') -Encoding utf8
Compress-Archive -LiteralPath $taskPortable -DestinationPath (Join-Path $taskRoot "dist/$taskName.zip") -Force -CompressionLevel Optimal
$taskSetup=Join-Path $taskRoot 'dist/Wormfront-0.20.0-Windows-Setup'
New-Item -ItemType Directory $taskSetup -Force | Out-Null
foreach($taskFile in Get-ChildItem -LiteralPath $taskPortable -Recurse -File) {
 $taskRelative=$taskFile.FullName.Substring($taskPortable.Length).TrimStart([char[]]'\/')
 $taskDestination=Join-Path (Join-Path $taskSetup 'payload') $taskRelative
 New-Item -ItemType Directory (Split-Path -Parent $taskDestination) -Force | Out-Null
 Copy-Item -LiteralPath $taskFile.FullName -Destination $taskDestination -Force
}
foreach($taskFile in @('Install.ps1','Uninstall.ps1','Installa.cmd','Disinstalla.cmd','LEGGIMI.txt')) {Copy-Item -LiteralPath (Join-Path $taskRoot "installer/$taskFile") -Destination $taskSetup -Force}
Compress-Archive -LiteralPath $taskSetup -DestinationPath ($taskSetup+'.zip') -Force -CompressionLevel Optimal
foreach($taskZip in Get-ChildItem -LiteralPath (Join-Path $taskRoot 'dist') -Filter '*.zip' -File) {
 ((Get-FileHash -LiteralPath $taskZip.FullName -Algorithm SHA256).Hash.ToLowerInvariant())+'  '+$taskZip.Name | Set-Content -LiteralPath ($taskZip.FullName+'.sha256') -Encoding utf8
}
Write-Output 'ZIP portatile e ZIP di installazione pronti in dist.'

