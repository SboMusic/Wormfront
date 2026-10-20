param([string]$InstallDir=(Join-Path $env:LOCALAPPDATA 'SboMusic/Crateri'),[switch]$NoShortcuts)
$ErrorActionPreference='Stop'
$taskSource=Join-Path $PSScriptRoot 'payload'
if(-not (Test-Path -LiteralPath (Join-Path $taskSource 'Crateri.exe')) -or -not (Test-Path -LiteralPath (Join-Path $taskSource 'Crateri.pck'))) {throw 'Estrai l''intero ZIP prima di installare.'}
$taskTarget=[IO.Path]::GetFullPath($InstallDir)
$taskSourceFull=[IO.Path]::GetFullPath($taskSource)
if($taskTarget.StartsWith($taskSourceFull,[StringComparison]::OrdinalIgnoreCase)) {throw 'Scegli una cartella esterna ai file di installazione.'}
New-Item -ItemType Directory $taskTarget -Force | Out-Null
$taskFiles=@()
foreach($taskFile in Get-ChildItem -LiteralPath $taskSource -Recurse -File) {
 $taskRelative=$taskFile.FullName.Substring($taskSourceFull.Length).TrimStart([char[]]'\/')
 $taskDestination=Join-Path $taskTarget $taskRelative
 New-Item -ItemType Directory (Split-Path -Parent $taskDestination) -Force | Out-Null
 Copy-Item -LiteralPath $taskFile.FullName -Destination $taskDestination -Force
 $taskFiles+=$taskRelative
}
foreach($taskFile in @('Uninstall.ps1','Disinstalla.cmd')) {
 Copy-Item -LiteralPath (Join-Path $PSScriptRoot $taskFile) -Destination $taskTarget -Force
 $taskFiles+=$taskFile
}
$taskManifest=@{publisher='SboMusic';product='Crateri';version='0.19.1';files=$taskFiles}
$taskManifest | ConvertTo-Json -Depth 4 | Set-Content -LiteralPath (Join-Path $taskTarget 'sbomusic-install.json') -Encoding utf8
if(-not $NoShortcuts) {
 $taskShell=New-Object -ComObject WScript.Shell
 $taskMenu=Join-Path ([Environment]::GetFolderPath('Programs')) 'SboMusic'
 New-Item -ItemType Directory $taskMenu -Force | Out-Null
 $taskLink=$taskShell.CreateShortcut((Join-Path $taskMenu 'Crateri.lnk'))
 $taskLink.TargetPath=Join-Path $taskTarget 'Crateri.exe'
 $taskLink.WorkingDirectory=$taskTarget
 $taskLink.Description='Crateri - SboMusic'
 $taskLink.Save()
}
Write-Output 'Crateri di SboMusic installato. Avvialo dal menu Start o dalla cartella scelta.'
