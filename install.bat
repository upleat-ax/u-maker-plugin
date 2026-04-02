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
if "%~1"=="--repo" (
    set "REPO=%~2"
    set "API_URL=https://api.github.com/repos/%~2/releases"
    shift
    shift
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

:: TLS 1.2 enforcement (required for GitHub API on older Windows)
set "PS_TLS=[Net.ServicePointManager]::SecurityProtocol=[Net.SecurityProtocolType]::Tls12;"

:: Check PowerShell availability
where powershell >nul 2>&1
if !errorlevel! neq 0 (
    echo   [ERR] PowerShell is required but not found.
    echo        Please install PowerShell or use Windows 10+.
    exit /b 1
)

:: Determine version
if defined TARGET_VERSION (
    set "VERSION=%TARGET_VERSION%"
    if not "!VERSION:~0,1!"=="v" set "VERSION=v!VERSION!"
) else (
    echo   [..] Fetching latest release...
    for /f "usebackq delims=" %%v in (`powershell -NoProfile -Command "%PS_TLS% (Invoke-RestMethod -Uri '%API_URL%/latest').tag_name" 2^>^&1`) do set "VERSION=%%v"
    if not defined VERSION (
        echo   [ERR] Failed to fetch latest release from %REPO%
        echo        Check: https://github.com/%REPO%/releases
        echo        If repo is private, use: install.bat --repo owner/repo
        exit /b 1
    )
    :: Check if response is an error message instead of version
    echo !VERSION! | findstr /i "error exception" >nul 2>&1
    if !errorlevel! equ 0 (
        echo   [ERR] GitHub API error: !VERSION!
        echo        Possible causes:
        echo          - Repository %REPO% does not exist or is private
        echo          - Network/firewall is blocking api.github.com
        echo          - GitHub API rate limit exceeded
        echo        Try: install.bat --repo your-org/u-maker-plugin
        exit /b 1
    )
)
echo   [OK] Version: %VERSION%

:: Get download URL
echo   [..] Finding download URL...
for /f "usebackq delims=" %%u in (`powershell -NoProfile -Command "%PS_TLS% $r = Invoke-RestMethod -Uri '%API_URL%/tags/%VERSION%'; ($r.assets | Where-Object { $_.name -like '*.zip' } | Select-Object -First 1).browser_download_url"`) do set "DOWNLOAD_URL=%%u"

if not defined DOWNLOAD_URL (
    echo   [ERR] No zip asset found for %VERSION%
    echo        Check: https://github.com/%REPO%/releases/tag/%VERSION%
    exit /b 1
)
echo   [OK] URL: %DOWNLOAD_URL%

:: Create temp directory
set "TMP_DIR=%TEMP%\u-maker-install-%RANDOM%"
mkdir "%TMP_DIR%" 2>nul
set "ZIP_FILE=%TMP_DIR%\u-maker-plugin.zip"

:: Download
echo   [..] Downloading...
powershell -NoProfile -Command "%PS_TLS% Invoke-WebRequest -Uri '%DOWNLOAD_URL%' -OutFile '%ZIP_FILE%'" 2>nul
if !errorlevel! neq 0 (
    echo   [ERR] Download failed. Trying curl fallback...
    curl -fsSL --ssl-no-revoke "%DOWNLOAD_URL%" -o "%ZIP_FILE%" 2>nul
    if !errorlevel! neq 0 (
        echo   [ERR] Download failed with both PowerShell and curl
        echo        Check your network connection and try again.
        rd /s /q "%TMP_DIR%" 2>nul
        exit /b 1
    )
)
echo   [OK] Downloaded

:: Extract
echo   [..] Extracting...
powershell -NoProfile -Command "Expand-Archive -Path '%ZIP_FILE%' -DestinationPath '%TMP_DIR%\plugin' -Force" 2>nul
if !errorlevel! neq 0 (
    echo   [ERR] Extraction failed. Trying tar fallback...
    tar -xf "%ZIP_FILE%" -C "%TMP_DIR%\plugin" 2>nul
    if !errorlevel! neq 0 (
        echo   [ERR] Extraction failed
        rd /s /q "%TMP_DIR%" 2>nul
        exit /b 1
    )
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

:: Leave upgrade marker for existing .u-maker/ projects
echo   [..] Checking for existing projects...
if exist "%CD%\.u-maker\u-maker.config.json" (
    powershell -NoProfile -Command "%PS_TLS% $c=Get-Content '%CD%\.u-maker\u-maker.config.json' | ConvertFrom-Json; if($c.ssotVersion -eq '3.0'){@{from='3.0';to='3.1';timestamp=(Get-Date -Format 'yyyy-MM-ddTHH:mm:ssZ');action='folder-restructure'}|ConvertTo-Json|Set-Content '%CD%\.u-maker\.upgrade-pending'; Write-Host '  [OK] Upgrade marker set for %CD%\.u-maker'}" 2>nul
)

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
echo   install.bat                          Install latest version
echo   install.bat --version 1.0.7          Install specific version
echo   install.bat --repo owner/repo        Use custom GitHub repo
echo   install.bat --uninstall              Remove plugin
echo   install.bat --help                   Show this help
echo.
echo Quick install (PowerShell):
echo   irm https://raw.githubusercontent.com/upleat-ax/u-maker-plugin/main/install.ps1 ^| iex
goto :eof
