param([string]$InstallDir=(Join-Path $env:LOCALAPPDATA 'SboMusic/Wormfront'),[switch]$NoShortcuts)
$ErrorActionPreference='Stop'
$taskSource=Join-Path $PSScriptRoot 'payload'
if(-not (Test-Path -LiteralPath (Join-Path $taskSource 'Wormfront.exe')) -or -not (Test-Path -LiteralPath (Join-Path $taskSource 'Wormfront.pck'))) {
 Write-Host ''
 if(Test-Path -LiteralPath (Join-Path (Split-Path -Parent $PSScriptRoot) 'project.godot')) {
  Write-Host 'Questa e la cartella dei SORGENTI, non il pacchetto di installazione.'
 } else {
  Write-Host 'Il pacchetto di installazione e incompleto: mancano i file del gioco nella cartella payload.'
 }
 Write-Host 'Per giocare scarica Wormfront-0.20.0-Windows-Setup.zip da:'
 Write-Host 'https://github.com/SboMusic/Wormfront/releases/tag/v0.20.0'
 Write-Host 'Estrai tutto lo ZIP Setup e avvia Installa.cmd dalla cartella estratta.'
 Write-Host 'Il pulsante verde Code > Download ZIP scarica invece i sorgenti.'
 exit 1
}
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
$taskManifest=@{publisher='SboMusic';product='Wormfront';version='0.20.0';files=$taskFiles}
$taskManifest | ConvertTo-Json -Depth 4 | Set-Content -LiteralPath (Join-Path $taskTarget 'sbomusic-install.json') -Encoding utf8
if(-not $NoShortcuts) {
 $taskShell=New-Object -ComObject WScript.Shell
 $taskMenu=Join-Path ([Environment]::GetFolderPath('Programs')) 'SboMusic'
 New-Item -ItemType Directory $taskMenu -Force | Out-Null
 $taskLink=$taskShell.CreateShortcut((Join-Path $taskMenu 'Wormfront.lnk'))
 $taskLink.TargetPath=Join-Path $taskTarget 'Wormfront.exe'
 $taskLink.WorkingDirectory=$taskTarget
 $taskLink.Description='Wormfront - SboMusic'
 $taskLink.IconLocation=(Join-Path $taskTarget 'Wormfront.exe')+',0'
 $taskLink.Save()
}
Write-Output 'Wormfront di SboMusic installato. Avvialo dal menu Start o dalla cartella scelta.'


