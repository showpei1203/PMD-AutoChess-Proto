@echo off
setlocal
cd /d "%~dp0"
echo PLW G2.2 offline regression (not Godot runtime acceptance)
where py >nul 2>nul
if errorlevel 1 (echo Python missing.& pause& exit /b 1)
py -3 -m unittest discover -s tests -v
set RC=%errorlevel%
echo Test exit code: %RC%
pause
exit /b %RC%
