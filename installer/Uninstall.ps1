param([switch]$ConfirmRemoval,[switch]$NoShortcuts)
$ErrorActionPreference='Stop'
$taskRoot=[IO.Path]::GetFullPath($PSScriptRoot)
$taskManifestPath=Join-Path $taskRoot 'sbomusic-install.json'
if(-not (Test-Path -LiteralPath $taskManifestPath)) {throw 'Manifest di installazione assente: nessun file eliminato.'}
$taskManifest=Get-Content -LiteralPath $taskManifestPath -Raw | ConvertFrom-Json
if($taskManifest.publisher -ne 'SboMusic' -or $taskManifest.product -ne 'Crateri') {throw 'Manifest non valido.'}
if(-not $ConfirmRemoval) {if((Read-Host 'Rimuovere Crateri? Scrivi SI per confermare') -ne 'SI') {exit 0}}
$taskPrefix=$taskRoot.TrimEnd([char[]]'\/')+[IO.Path]::DirectorySeparatorChar
$taskPaths=@()
foreach($taskFile in $taskManifest.files) {
 $taskPath=[IO.Path]::GetFullPath((Join-Path $taskRoot $taskFile))
 if(-not $taskPath.StartsWith($taskPrefix,[StringComparison]::OrdinalIgnoreCase)) {throw 'Percorso esterno nel manifest: rimozione annullata.'}
 $taskPaths+=$taskPath
}
foreach($taskPath in $taskPaths) {if(Test-Path -LiteralPath $taskPath -PathType Leaf) {Remove-Item -LiteralPath $taskPath -Force}}
Remove-Item -LiteralPath $taskManifestPath -Force
if(-not $NoShortcuts) {
 $taskLink=Join-Path ([Environment]::GetFolderPath('Programs')) 'SboMusic/Crateri.lnk'
 if(Test-Path -LiteralPath $taskLink) {Remove-Item -LiteralPath $taskLink -Force}
}
Write-Output 'File del gioco rimossi. Salvataggi personali conservati. Eventuali cartelle vuote possono essere eliminate.'
