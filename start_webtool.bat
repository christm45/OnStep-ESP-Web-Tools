@echo off
setlocal
cd /d "%~dp0"

echo Starting Web Tool... (this window will remain open)
echo Script: "%~dp0start_webtool.ps1"
echo.

REM Start local web server and open browser; keep PowerShell session open to show logs
powershell -NoLogo -NoProfile -ExecutionPolicy Bypass -NoExit -File "%~dp0start_webtool.ps1"

echo.
pause
endlocal

