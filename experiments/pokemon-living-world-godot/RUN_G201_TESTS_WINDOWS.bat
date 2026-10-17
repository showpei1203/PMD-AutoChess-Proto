@echo off
setlocal
cd /d "%~dp0"
echo PLW G2.0.1 ecology diagnosis - all offline Python tests
where py >nul 2>nul
if errorlevel 1 (
 echo Python 3 launcher missing. Install Python 3.
 pause
 exit /b 1
)
py -3 -m unittest discover -s tests -v
set RC=%errorlevel%
echo Offline test exit code: %RC% ^(does not mean Godot runtime PASS^)
echo Open scenes\ecology_lab.tscn in Godot and press F6.
echo D = debug ON/OFF, M = forced move, N = new seed, R = replay, Space = pause.
pause
exit /b %RC%
