@echo off
REM ============================================================
REM  Play the game. Any scene:  tools\play.cmd res://path\to.tscn
REM
REM  This is a .cmd and not a .ps1 on purpose. Windows executes
REM  .cmd files natively from cmd.exe, PowerShell, the Run box and
REM  a double-click in Explorer, with no file association and no
REM  execution policy in the way. Running the .ps1 directly can
REM  hand the .tscn to whatever app the machine has associated
REM  with it (a text editor, a notes app) instead of running it.
REM ============================================================
setlocal

set "SCENE=%~1"
if "%SCENE%"=="" set "SCENE=res://src/world/slice.tscn"

powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0godot.ps1" "%SCENE%"
endlocal
