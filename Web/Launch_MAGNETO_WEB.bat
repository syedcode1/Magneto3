@echo off
:: MAGNETO v3 - Web Interface Launcher
:: Optional - you can also run MAGNETO_WEB_SERVER.ps1 directly

echo.
echo ========================================
echo    MAGNETO v3 - WEB INTERFACE
echo    Advanced APT Simulator
echo ========================================
echo.

:: Launch PowerShell Web Server
powershell.exe -ExecutionPolicy Bypass -NoProfile -File "%~dp0MAGNETO_WEB_SERVER.ps1"

pause
