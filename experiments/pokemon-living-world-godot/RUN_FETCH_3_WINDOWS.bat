@echo off
setlocal
cd /d "%~dp0"
echo PLW PMDCollab / Three-species proof of concept (025, 094, 143)
echo Assets only downloaded into data\raw\pmdcollab. DO NOT commit art into public GitHub.
where py >nul 2>nul
if errorlevel 1 (
  echo Python 3 not found. Install from https://www.python.org/downloads/windows/
  pause
  exit /b 1
)
py -3 tools\pmdcollab_fetch.py --ids 25,94,143 --out .
echo Exit code: %errorlevel% ^(0 means source ZIPs verified^)
pause