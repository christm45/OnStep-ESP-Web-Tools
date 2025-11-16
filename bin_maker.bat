@echo off
setlocal
cd /d "%~dp0"

echo Running bin_maker.ps1...
echo.
powershell -NoLogo -NoProfile -ExecutionPolicy Bypass -NoExit -File "%~dp0bin_maker.ps1"
echo.
pause
endlocal

