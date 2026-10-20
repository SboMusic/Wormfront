param([string]$GodotExe=$env:GODOT_EXE,[string[]]$Suites=@('verify_rebrand.gd','verify.gd','verify_new_weapons.gd','verify_arsenal_all.gd','verify_upgrade.gd','verify_expansion.gd','verify_random_audio.gd','verify_tall_camera.gd','verify_restyle.gd'))
$ErrorActionPreference='Stop'
$taskRoot=Split-Path -Parent $PSScriptRoot
if(-not $GodotExe) {$taskCommand=Get-Command godot,godot4 -ErrorAction SilentlyContinue | Select-Object -First 1; if($taskCommand) {$GodotExe=$taskCommand.Source}}
if(-not $GodotExe -or -not (Test-Path -LiteralPath $GodotExe)) {throw 'Indica Godot 4.5.1 con -GodotExe o GODOT_EXE.'}
$taskOldAppData=$env:APPDATA
$taskOldXdg=$env:XDG_DATA_HOME
try {
 foreach($taskSuite in $Suites) {
  if($taskSuite -notmatch '^verify[a-z0-9_]*\.gd$') {throw 'Nome della suite non valido.'}
  $taskLog=Join-Path $taskRoot ".local/test-results/$taskSuite.log"
  $env:APPDATA=Join-Path $taskRoot ".local/test-userdata/$taskSuite"
  $env:XDG_DATA_HOME=$env:APPDATA
  New-Item -ItemType Directory (Split-Path -Parent $taskLog),$env:APPDATA -Force | Out-Null
  & $GodotExe --headless --path $taskRoot --script "tests/$taskSuite" --quit-after 2400 *> $taskLog
  $taskStatus=$LASTEXITCODE
  $taskText=Get-Content -LiteralPath $taskLog -Raw
  if($taskStatus -ne 0 -or $taskText -match 'SCRIPT ERROR:|(?m)^ERROR:|(?m)^FAIL\b' -or $taskText -notmatch 'PASS') {throw "Test non riuscito: $taskSuite. Consulta .local/test-results."}
  Write-Output "PASS $taskSuite"
 }
} finally {$env:APPDATA=$taskOldAppData; $env:XDG_DATA_HOME=$taskOldXdg}

