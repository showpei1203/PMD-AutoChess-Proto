@echo off
setlocal
cd /d "%~dp0"
echo PLW G1 offline unit tests (all current Python tests)
where py >nul 2>nul
if errorlevel 1 (
 echo Python not found.
 pause
 exit /b 1
)
py -3 -m unittest discover -s tests -v
set RESULT=%errorlevel%
echo G1 unit test exit code: %RESULT%
pause
exit /b %RESULT%
