@echo off
setlocal
cd /d "%~dp0"
echo PLW G1.1 local PMDCollab 151-species roster preflight.
echo This inspects ignored local assets; DO NOT commit original PNG to GitHub.
where py >nul 2>nul
if errorlevel 1 (
 echo Python 3 not found. Install it before continuing.
 pause
 exit /b 1
)
py -3 tools\pmd_roster_report.py --root .
set RESULT=%errorlevel%
echo G1.1 report exit code: %RESULT% ^(0 means no hard failures^)
echo Check reports\pmd_roster_report.json and reports\pmd_roster_report.csv
pause
exit /b %RESULT%
