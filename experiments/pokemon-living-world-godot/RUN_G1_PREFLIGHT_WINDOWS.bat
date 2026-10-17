@echo off
setlocal
cd /d "%~dp0"
echo PLW G1 PMD animation sheet + CopyOf preflight for 025/094/143
where py >nul 2>nul
if errorlevel 1 (
 echo Python not found.
 pause
 exit /b 1
)
py -3 tools\pmd_g1_preflight.py --out . --ids 25,94,143
set RESULT=%errorlevel%
echo G1 preflight exit code: %RESULT%
echo Report: reports\pmd_g1_preflight.json
pause
exit /b %RESULT%
