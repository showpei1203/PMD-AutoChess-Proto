@echo off
setlocal
cd /d "%~dp0"
echo PLW G3.2 DIRECT LAUNCH: res://scenes/g32_combat_lab.tscn
 echo Standalone 1v1 Utility AI. Close GAME window after result / ~60 seconds.
where py >nul 2>nul
if errorlevel 1 (echo Python 3 required.& pause& exit /b 1)
py -3 tools\g32_direct_launch.py --root .
set RC=%errorlevel%
echo.
echo Share: %CD%\reports\PLW_G32_DIRECT_DIAGNOSTICS_TO_SHARE.zip
 echo Exit code: %RC%
pause
exit /b %RC%
