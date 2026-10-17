@echo off
setlocal
cd /d "%~dp0"
echo PLW PMDCollab / 151 species source sprites download.
echo For noncommercial research only. Attribution required. This can take time.
where py >nul 2>nul
if errorlevel 1 (
  echo Python 3 not found. Install from https://www.python.org/downloads/windows/
  pause
  exit /b 1
)
py -3 tools\pmdcollab_fetch.py --all151 --out .
echo Exit code: %errorlevel% ^(0 means every source ZIP verified^)
pause