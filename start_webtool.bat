@echo off
setlocal

REM Lance l'interface de flash sur http://localhost:8000

set SCRIPT_DIR=%~dp0
cd /d "%SCRIPT_DIR%"

powershell -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%SCRIPT_DIR%start_webtool.ps1" -Port 8000

endlocal

