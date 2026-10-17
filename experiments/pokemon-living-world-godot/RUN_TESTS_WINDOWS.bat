@echo off
setlocal
cd /d "%~dp0"
where py >nul 2>nul
if errorlevel 1 (
  echo Python launcher not found. Install Python 3.10+ and select Add python to PATH.
  pause
  exit /b 1
)
py -3 -m unittest discover -s tests -v
if errorlevel 1 (
  echo FAIL: Some tests failed.
  pause
  exit /b 1
)
echo PASS: Synthetic source audit tests passed. Actual 151 art verification is still pending.
pause

