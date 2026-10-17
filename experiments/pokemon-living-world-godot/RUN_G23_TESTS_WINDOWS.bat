@echo off
setlocal
cd /d "%~dp0"
echo PLW G2.3 Species Cadence - Python offline regression (Godot F6 not implied)
where py >nul 2>nul
if errorlevel 1 (echo Python 3 not found.& pause& exit /b 1)
py -3 -m unittest discover -s tests -v
set RC=%errorlevel%
echo Python offline test exit: %RC%
pause
exit /b %RC%
