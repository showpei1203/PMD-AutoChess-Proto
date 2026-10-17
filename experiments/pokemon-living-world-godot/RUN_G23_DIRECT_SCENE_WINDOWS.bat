@echo off
setlocal
cd /d "%~dp0"
echo PLW G2.3 DIRECT LAUNCH: ecology_ambient_lab.tscn
 echo Godot scene starts directly. Close the GAME window after 45-60 seconds.
where py >nul 2>nul
if errorlevel 1 (echo Python 3 required.& pause& exit /b 1)
py -3 tools\g23_direct_launch.py --root .
set RC=%errorlevel%
echo.
echo Upload: %CD%\reports\PLW_G23_DIRECT_DIAGNOSTICS_TO_SHARE.zip
echo Exit code: %RC%
pause
exit /b %RC%
