@echo off
setlocal
cd /d "%~dp0"
echo PLW G1.2 Calibration - offline tests. Original sprites remain private.
where py >nul 2>nul
if errorlevel 1 (
 echo Python 3 not found.
 pause
 exit /b 1
)
py -3 -m unittest discover -s tests -v
set CODE=%errorlevel%
echo Exit code: %CODE%
pause
exit /b %CODE%
