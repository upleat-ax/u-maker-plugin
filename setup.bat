@echo off
setlocal EnableDelayedExpansion
chcp 65001 >/dev/null 2>&1

:: ============================================================
:: setup.bat - u-maker plugin one-click installer (Windows)
::
:: Usage:
::   1. Download and extract the zip file
::   2. Double-click setup.bat (or run from CMD)
::   3. Restart Claude Code
::
::   setup.bat              Install plugin
::   setup.bat --uninstall  Remove plugin
::   setup.bat --check      Verify installation
:: ============================================================

echo.
echo  ======================================
echo    U-MAKER Plugin Setup (Windows)
echo  ======================================
echo.

:: Check if deploy_local.bat exists
set "SCRIPT_DIR=%~dp0"
if "%SCRIPT_DIR:~-1%"=="\" set "SCRIPT_DIR=%SCRIPT_DIR:~0,-1%"

if not exist "%SCRIPT_DIR%\deploy_local.bat" (
    echo  [ERR] deploy_local.bat not found.
    echo        Make sure you extracted the zip file completely.
    echo.
    pause
    exit /b 1
)

:: Pass arguments to deploy_local.bat
if "%~1"=="--uninstall" (
    call "%SCRIPT_DIR%\deploy_local.bat" --clean
) else if "%~1"=="--check" (
    call "%SCRIPT_DIR%\deploy_local.bat" --check
) else (
    call "%SCRIPT_DIR%\deploy_local.bat"
)

if !errorlevel! equ 0 (
    echo.
    echo  ======================================
    echo    Setup complete!
    echo  ======================================
    echo.
    echo    Please restart Claude Code to start
    echo    using U-MAKER.
    echo.
    echo    Quick start:
    echo      /u-init my-project
    echo      /u-plan [app]
    echo.
) else (
    echo.
    echo  [ERR] Setup failed. Check the errors above.
    echo.
)

pause
