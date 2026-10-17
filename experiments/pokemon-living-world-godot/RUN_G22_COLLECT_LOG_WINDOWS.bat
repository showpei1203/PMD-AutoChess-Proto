@echo off
setlocal
cd /d "%~dp0"
where py >nul 2>nul
if errorlevel 1 (echo Python 3 not found.& pause& exit /b 1)
py -3 tools\g22_collect_logs.py --root .
set RC=%errorlevel%
echo.
echo Share: %CD%\reports\PLW_G22_DIAGNOSTICS_TO_SHARE.zip
echo Exit code: %RC%
pause
exit /b %RC%
