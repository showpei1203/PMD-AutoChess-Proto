@echo off
setlocal
cd /d "%~dp0"
if "%~1"=="" (
  echo Usage: Drag-and-drop full PMD archive.zip on this script.
  echo Or run: RUN_AUDIT_WINDOWS.bat "C:\path\to\PMD_source.zip"
  pause
  exit /b 1
)
py -3 tools\pmd_asset_audit.py --source "%~1" --out "%~dp0reports-new" --require-complete
set CODE=%errorlevel%
if "%CODE%"=="0" (
 echo PASS: Source reference and PNG structural coverage complete.
) else (
 echo G0 PENDING or ERROR. Review reports-new\audit_summary.json and asset_matrix.csv.
 echo Incomplete sources are expected until the original PNG files are supplied.
)
pause
exit /b %CODE%

