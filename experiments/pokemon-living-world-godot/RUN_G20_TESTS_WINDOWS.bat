@echo off
setlocal
cd /d "%~dp0"
echo PLW G2.0 ecology local tests (no copyrighted art included).
where py >nul 2>nul
if errorlevel 1 (
 echo Python 3 not found.
 pause
 exit /b 1
)
py -3 -m unittest discover -s tests -v
set RC=%errorlevel%
echo G2.0 offline test exit code: %RC%
pause
exit /b %RC%
