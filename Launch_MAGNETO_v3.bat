@echo off
title MAGNETO v3 - Advanced APT Campaign Simulator
color 0A
cls

echo ===============================================
echo     MAGNETO v3 - APT CAMPAIGN SIMULATOR
echo ===============================================
echo.
echo  Advanced Threat Simulation Platform
echo  Version 3 - October 2025
echo.
echo  KEY FEATURES:
echo  [+] 38 MITRE Attack Techniques
echo  [+] 7 APT Campaign Simulations
echo  [+] MITRE Attack Tactics Visualization
echo  [+] Enhanced Threat Intelligence
echo  [+] Real-World APT Attribution
echo  [+] HTML Attack Reports
echo.

REM Check for admin rights
net session >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo [!] WARNING: Not running as Administrator
    echo.
    echo Some techniques require Administrator privileges.
    choice /C YN /T 10 /D N /M "Would you like to restart as Administrator?"
    if %ERRORLEVEL% EQU 1 (
        echo.
        echo Restarting as Administrator...
        powershell -Command "Start-Process '%~f0' -Verb RunAs"
        exit
    ) else (
        echo.
        echo Continuing without Administrator privileges...
        echo Some techniques may not be available.
        echo.
    )
) else (
    echo [+] Running with Administrator privileges
    echo.
)

REM Check PowerShell version
echo Checking PowerShell version...
for /f "tokens=*" %%i in ('powershell -Command "$PSVersionTable.PSVersion.Major"') do set PS_VER=%%i
if %PS_VER% GEQ 5 (
    echo [+] PowerShell %PS_VER%.x detected - OK
) else (
    echo [!] PowerShell version %PS_VER% detected
    echo     PowerShell 5.0 or higher required
    pause
    exit /b 1
)
echo.

REM Check for required files
echo Checking required files...
set FILES_OK=1

if exist "%~dp0MAGNETO_GUI_v3.ps1" (
    echo [+] MAGNETO_GUI_v3.ps1 found
    set GUI_FILE=MAGNETO_GUI_v3.ps1
) else (
    echo [!] MAGNETO GUI script NOT FOUND
    set FILES_OK=0
)

if exist "%~dp0MAGNETO_v3.ps1" (
    echo [+] MAGNETO_v3.ps1 found
) else (
    echo [!] MAGNETO_v3.ps1 NOT FOUND
    set FILES_OK=0
)
echo.

if %FILES_OK% EQU 0 (
    echo ===============================================
    echo ERROR: Required files missing!
    echo ===============================================
    echo.
    echo Please ensure the following files are present:
    echo   - MAGNETO_v3.ps1
    echo   - MAGNETO_GUI_v3.ps1
    echo.
    pause
    exit /b 1
)

REM Create logs directory if it doesn't exist
if not exist "%~dp0MAGNETO_GUI_Logs" (
    echo Creating logs directory...
    mkdir "%~dp0MAGNETO_GUI_Logs"
    echo [+] Logs directory created
    echo.
)

if not exist "%~dp0MAGNETO_Logs" (
    echo Creating MAGNETO logs directory...
    mkdir "%~dp0MAGNETO_Logs"
    echo [+] MAGNETO logs directory created
    echo.
)

echo ===============================================
echo          LAUNCHING MAGNETO v3 GUI
echo ===============================================
echo.

echo Starting GUI application...

REM Launch the GUI
powershell.exe -WindowStyle Normal -NoProfile -File "%~dp0%GUI_FILE%"

set EXIT_CODE=%ERRORLEVEL%

if %EXIT_CODE% EQU 0 (
    echo.
    echo [+] MAGNETO GUI closed successfully
) else (
    echo.
    echo [!] GUI exited with error code: %EXIT_CODE%
    echo.
    echo Troubleshooting:
    echo   1. Check logs in MAGNETO_GUI_Logs folder
    echo   2. Ensure .NET Framework 4.5+ is installed
    echo   3. Try running PowerShell as Administrator
    echo   4. Verify Windows Defender isn't blocking execution
    echo.
    pause
)
