@echo off
setlocal
cd /d "%~dp0"
if not exist "reports\PLW_G2_RUNTIME_LAST.log" (
 echo No G2 runtime log yet at:
 echo %CD%\reports\PLW_G2_RUNTIME_LAST.log
 echo In Godot: Open scenes\ecology_lab.tscn and press F6.
 echo You should see G2.0.2 LOGGER ACTIVE in the running scene.
 pause
 exit /b 2
)
start "" notepad.exe "reports\PLW_G2_RUNTIME_LAST.log"
echo G2 log: %CD%\reports\PLW_G2_RUNTIME_LAST.log
pause

