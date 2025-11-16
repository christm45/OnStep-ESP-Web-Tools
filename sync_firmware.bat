@echo off
setlocal

REM Synchronise les .bin -> manifests -> manifest_list.js

set SCRIPT_DIR=%~dp0
cd /d "%SCRIPT_DIR%"

powershell -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%SCRIPT_DIR%sync_firmware.ps1"

endlocal

