@echo off
setlocal
cd /d "%~dp0"
if "%GODOT_EXE%"=="" (
  echo Imposta GODOT_EXE sul percorso di Godot 4.5.1 oppure importa project.godot nell'editor.
  pause
  exit /b 1
)
"%GODOT_EXE%" --path "%~dp0."
