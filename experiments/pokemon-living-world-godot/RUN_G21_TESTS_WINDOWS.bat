@echo off
setlocal
cd /d "%~dp0"
py -3 -m unittest discover -s tests -v > "reports\G21_OFFLINE_TESTS_LAST.log" 2>&1
set RC=%errorlevel%
type "reports\G21_OFFLINE_TESTS_LAST.log"
echo G2.1 offline exit code: %RC%
pause
exit /b %RC%
