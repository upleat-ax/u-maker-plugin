@echo off
setlocal EnableDelayedExpansion
chcp 65001 >nul 2>&1

:: ============================================================
:: install.bat — u-maker plugin installer (Windows)
::
:: Downloads the latest release from GitHub, extracts, installs,
:: and cleans up temporary files.
::
:: Usage:
::   install.bat                  & install latest version
::   install.bat --version 1.0.7  & install specific version
::   install.bat --uninstall      & remove plugin
:: ============================================================

set "REPO=upleat-ax/u-maker-plugin"
set "API_URL=https://api.github.com/repos/%REPO%/releases"
set "PLUGIN_NAME=u-maker"

if "%~1"=="--uninstall" goto :uninstall
if "%~1"=="--clean" goto :uninstall
if "%~1"=="--help" goto :help
if "%~1"=="-h" goto :help
if "%~1"=="--version" (
    set "TARGET_VERSION=%~2"
    goto :install
)
goto :install

:: ============================================================
:: Install
:: ============================================================
:install
echo.
echo ========================================
echo   u-maker Plugin Installer (Windows)
echo ========================================
echo.

:: Check prerequisites
where python >nul 2>&1
if !errorlevel! neq 0 (
    where python3 >nul 2>&1
    if !errorlevel! neq 0 (
        echo   [ERR] Python is required. Install from https://python.org
        exit /b 1
    )
    set "PY=python3"
) else (
    set "PY=python"
)

:: Determine version
if defined TARGET_VERSION (
    set "VERSION=%TARGET_VERSION%"
    if not "!VERSION:~0,1!"=="v" set "VERSION=v!VERSION!"
) else (
    echo   [..] Fetching latest release...
    for /f "usebackq delims=" %%v in (`powershell -NoProfile -Command "(Invoke-RestMethod -Uri '%API_URL%/latest').tag_name"`) do set "VERSION=%%v"
    if not defined VERSION (
        echo   [ERR] Failed to fetch latest release
        exit /b 1
    )
)
echo   [OK] Version: %VERSION%

:: Get download URL
echo   [..] Finding download URL...
for /f "usebackq delims=" %%u in (`powershell -NoProfile -Command "$r = Invoke-RestMethod -Uri '%API_URL%/tags/%VERSION%'; ($r.assets | Where-Object { $_.name -like '*.zip' } | Select-Object -First 1).browser_download_url"`) do set "DOWNLOAD_URL=%%u"

if not defined DOWNLOAD_URL (
    echo   [ERR] No zip asset found for %VERSION%
    exit /b 1
)
echo   [OK] URL: %DOWNLOAD_URL%

:: Create temp directory
set "TMP_DIR=%TEMP%\u-maker-install-%RANDOM%"
mkdir "%TMP_DIR%" 2>nul
set "ZIP_FILE=%TMP_DIR%\u-maker-plugin.zip"

:: Download
echo   [..] Downloading...
powershell -NoProfile -Command "Invoke-WebRequest -Uri '%DOWNLOAD_URL%' -OutFile '%ZIP_FILE%'" 2>nul
if !errorlevel! neq 0 (
    echo   [ERR] Download failed
    rd /s /q "%TMP_DIR%" 2>nul
    exit /b 1
)
echo   [OK] Downloaded

:: Extract
echo   [..] Extracting...
powershell -NoProfile -Command "Expand-Archive -Path '%ZIP_FILE%' -DestinationPath '%TMP_DIR%\plugin' -Force" 2>nul
if !errorlevel! neq 0 (
    echo   [ERR] Extraction failed
    rd /s /q "%TMP_DIR%" 2>nul
    exit /b 1
)
echo   [OK] Extracted

:: Find and run deploy_local.bat
set "DEPLOY_SCRIPT="
for /r "%TMP_DIR%\plugin" %%f in (deploy_local.bat) do (
    if exist "%%f" set "DEPLOY_SCRIPT=%%f"
)

if not defined DEPLOY_SCRIPT (
    echo   [ERR] deploy_local.bat not found in archive
    rd /s /q "%TMP_DIR%" 2>nul
    exit /b 1
)

:: Install
echo   [..] Installing...
call "%DEPLOY_SCRIPT%"
if !errorlevel! neq 0 (
    echo   [ERR] Installation failed
    rd /s /q "%TMP_DIR%" 2>nul
    exit /b 1
)

:: Clean up
echo   [..] Cleaning up temporary files...
rd /s /q "%TMP_DIR%" 2>nul
echo   [OK] Temporary files removed

echo.
echo ========================================
echo   u-maker %VERSION% installed!
echo ========================================
echo.
echo   Restart Claude Code to start using u-maker.
echo   Then run: /u-skill-help
echo.
goto :eof

:: ============================================================
:: Uninstall
:: ============================================================
:uninstall
echo.
echo   [..] Uninstalling u-maker...

set "CLAUDE_HOME=%USERPROFILE%\.claude"
set "CACHE_DIR=%CLAUDE_HOME%\plugins\cache\%PLUGIN_NAME%"

:: Find deploy_local.bat in cache
set "DEPLOY_SCRIPT="
if exist "%CACHE_DIR%" (
    for /r "%CACHE_DIR%" %%f in (deploy_local.bat) do (
        if exist "%%f" set "DEPLOY_SCRIPT=%%f"
    )
)

if defined DEPLOY_SCRIPT (
    call "%DEPLOY_SCRIPT%" --clean
) else (
    echo   [WARN] Cache not found. Manual cleanup may be needed.
    echo   [WARN] Check %CLAUDE_HOME%\plugins\ and %CLAUDE_HOME%\skills\
)

echo   [OK] Uninstall complete. Restart Claude Code.
echo.
goto :eof

:: ============================================================
:: Help
:: ============================================================
:help
echo Usage:
echo   install.bat                  Install latest version
echo   install.bat --version 1.0.7  Install specific version
echo   install.bat --uninstall      Remove plugin
echo   install.bat --help           Show this help
goto :eof
