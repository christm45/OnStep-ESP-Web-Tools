@echo off
setlocal
cd /d "%~dp0"

echo Running sync_firmware.ps1...
echo.
powershell -NoLogo -NoProfile -ExecutionPolicy Bypass -NoExit -File "%~dp0sync_firmware.ps1"
echo.
pause
endlocal

