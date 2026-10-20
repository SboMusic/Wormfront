param([string]$GodotExe=$env:GODOT_EXE,[string]$TemplateDir,[switch]$DebugBuild)
$ErrorActionPreference='Stop'
$taskRoot=Split-Path -Parent $PSScriptRoot
if(-not $GodotExe) { $taskCommand=Get-Command godot,godot4 -ErrorAction SilentlyContinue | Select-Object -First 1; if($taskCommand) {$GodotExe=$taskCommand.Source} }
if(-not $GodotExe -or -not (Test-Path -LiteralPath $GodotExe)) {throw 'Indica Godot 4.5.1 con -GodotExe oppure GODOT_EXE.'}
$taskVersion=& $GodotExe --version
if($taskVersion -notmatch '^4\.5\.1') {throw 'Il progetto e verificato con Godot 4.5.1.'}
if(-not $TemplateDir) {$TemplateDir=Join-Path $env:APPDATA 'Godot/export_templates/4.5.1.stable'}
$taskTemplates=Join-Path $taskRoot '.local/export-templates'
New-Item -ItemType Directory $taskTemplates -Force | Out-Null
foreach($taskFile in @('windows_release_x86_64.exe','windows_debug_x86_64.exe')) {
 $taskFrom=Join-Path $TemplateDir $taskFile
 $taskTo=Join-Path $taskTemplates $taskFile
 if(Test-Path -LiteralPath $taskFrom) {if([IO.Path]::GetFullPath($taskFrom) -ne [IO.Path]::GetFullPath($taskTo)) {Copy-Item -LiteralPath $taskFrom -Destination $taskTo -Force}}
 if(-not (Test-Path -LiteralPath $taskTo)) {throw "Installa i template ufficiali 4.5.1 o passa -TemplateDir: $taskFile"}
}
$taskDist=Join-Path $taskRoot 'dist/Crateri-0.19.1-Windows-x64'
New-Item -ItemType Directory $taskDist -Force | Out-Null
$taskOldAppData=$env:APPDATA
try {
 $env:APPDATA=Join-Path $taskRoot '.local/build-userdata'
 New-Item -ItemType Directory $env:APPDATA -Force | Out-Null
 & $GodotExe --headless --path $taskRoot --editor --import --quit
 if($LASTEXITCODE -ne 0) {throw 'Importazione non riuscita.'}
 $taskMode=if($DebugBuild) {'--export-debug'} else {'--export-release'}
 & $GodotExe --headless --path $taskRoot $taskMode 'Windows Desktop' (Join-Path $taskDist 'Crateri.exe')
 if($LASTEXITCODE -ne 0) {throw 'Esportazione non riuscita.'}
 Copy-Item -LiteralPath (Join-Path $taskRoot 'licenses') -Destination $taskDist -Recurse -Force
 foreach($taskFile in @('LICENSE','AUTHORS.md')) {Copy-Item -LiteralPath (Join-Path $taskRoot $taskFile) -Destination $taskDist -Force}
 Copy-Item -LiteralPath (Join-Path $taskRoot 'installer/LEGGIMI.txt') -Destination $taskDist -Force
 Copy-Item -LiteralPath (Join-Path $taskRoot 'docs/GUIDA_UTENTE.md') -Destination $taskDist -Force
 Write-Output 'Build Windows creata nella cartella dist.'
} finally {$env:APPDATA=$taskOldAppData}
