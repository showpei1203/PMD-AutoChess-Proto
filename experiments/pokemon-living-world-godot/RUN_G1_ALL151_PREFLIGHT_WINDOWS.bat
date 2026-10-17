@echo off
setlocal
cd /d "%~dp0"
echo PLW G1 catalogue preflight: check 151 PMD sprite XML/Idle/Walk/Attack sheets locally.
where py >nul 2>nul
if errorlevel 1 (
 echo Python not found.
 pause
 exit /b 1
)
py -3 tools\pmd_g1_preflight.py --out . --all151
set RESULT=%errorlevel%
echo Preflight exit code: %RESULT%
echo Report: reports\pmd_g1_preflight.json
pause
exit /b %RESULT%
