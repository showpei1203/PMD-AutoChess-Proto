@echo off
setlocal
cd /d "%~dp0"
where py >nul 2>nul
if errorlevel 1 (
 echo Python 3 not found.
 pause
 exit /b 1
)
py -3 tools\g2_collect_logs.py --root .
set RC=%errorlevel%
echo.
echo Upload this file in ChatGPT after stopping the F6 test:
echo %CD%\reports\PLW_G2_DIAGNOSTICS_TO_SHARE.zip
echo Exit code: %RC%
pause
exit /b %RC%

