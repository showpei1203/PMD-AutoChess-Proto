@echo off
setlocal
cd /d "%~dp0"
echo ==========================================================
echo  PLW G2.2 DIRECT LAUNCH: forced ecology_animation_lab.tscn
 echo  Does NOT use Godot editor F5 or F6.
echo  Godot window opens: play ~30 seconds then CLOSE game window.
echo  Diagnostic ZIP is created even if scene startup FAILS.
echo ==========================================================
where py >nul 2>nul
if errorlevel 1 (echo Python 3 is required.& pause& exit /b 1)
py -3 tools\g22_direct_launch.py --root .
set RC=%errorlevel%
echo.
echo Upload: %CD%\reports\PLW_G22_DIRECT_DIAGNOSTICS_TO_SHARE.zip
echo Exit code: %RC%
pause
exit /b %RC%
