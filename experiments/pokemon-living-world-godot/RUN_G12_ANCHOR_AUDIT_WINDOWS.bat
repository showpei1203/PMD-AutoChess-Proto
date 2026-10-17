@echo off
setlocal
cd /d "%~dp0"
echo PLW G1.2.1: Actual PMD 151-species Sprite/Shadow anchor audit (no dependencies).
echo Compares original Frame bottom with real visible pixels and native shadow center.
where py >nul 2>nul
if errorlevel 1 (
 echo Python 3 not found. Please install Python.
 pause
 exit /b 1
)
py -3 tools\pmd_anchor_audit.py --root .
set RESULT=%errorlevel%
echo Exit code: %RESULT% (2 = PNG/XML file errors; REVIEW = needs visual acceptance)
echo Reports: reports\pmd_anchor_audit.csv / reports\pmd_anchor_audit.json
pause
exit /b %RESULT%
