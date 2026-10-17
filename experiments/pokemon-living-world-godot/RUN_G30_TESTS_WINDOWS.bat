@echo off
setlocal
cd /d "%~dp0"
echo G3.0 offline regression (NOT Godot Surface acceptance)
where py >nul 2>nul
if errorlevel 1 (echo Python 3 required.& pause& exit /b 1)
py -3 -m unittest discover -s tests -v > reports\G30_OFFLINE_TESTS_LAST.log 2>&1
set RC=%errorlevel%
type reports\G30_OFFLINE_TESTS_LAST.log
echo Offline tests exit code: %RC%
pause
exit /b %RC%
