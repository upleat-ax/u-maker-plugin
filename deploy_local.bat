@echo off
setlocal EnableDelayedExpansion
chcp 65001 >nul 2>&1

:: ============================================================
:: deploy_local.bat — u-maker local plugin deployment (Windows)
::
:: Deploys the u-maker plugin to Claude Code, Codex CLI, and Gemini CLI.
::   Target: %USERPROFILE%\.claude\plugins\...
::
:: Usage:
::   deploy_local.bat          &  deploy (default)
::   deploy_local.bat --clean  &  remove deployed artifacts
::   deploy_local.bat --check  &  verify deployment status
:: ============================================================

:: ============================================================
:: 0. Prerequisites check & auto-install
:: ============================================================

call :check_prerequisites
if !errorlevel! neq 0 (
    echo.
    echo [ERR] Prerequisites check failed. Please resolve the issues above and retry.
    exit /b 1
)

:: ============================================================
:: 0b. Constants
:: ============================================================

set "SCRIPT_DIR=%~dp0"
:: Remove trailing backslash
if "%SCRIPT_DIR:~-1%"=="\" set "SCRIPT_DIR=%SCRIPT_DIR:~0,-1%"

set "PLUGIN_JSON=%SCRIPT_DIR%\.claude-plugin\plugin.json"

:: Parse plugin name and version from plugin.json via python
for /f "usebackq delims=" %%a in (`python -c "import json; print(json.load(open(r'%PLUGIN_JSON%'))['name'])" 2^>nul`) do set "PLUGIN_NAME=%%a"
for /f "usebackq delims=" %%a in (`python -c "import json; print(json.load(open(r'%PLUGIN_JSON%'))['version'])" 2^>nul`) do set "PLUGIN_VERSION=%%a"

if not defined PLUGIN_NAME (
    for /f "usebackq delims=" %%a in (`python3 -c "import json; print(json.load(open(r'%PLUGIN_JSON%'))['name'])"`) do set "PLUGIN_NAME=%%a"
    for /f "usebackq delims=" %%a in (`python3 -c "import json; print(json.load(open(r'%PLUGIN_JSON%'))['version'])"`) do set "PLUGIN_VERSION=%%a"
)

if not defined PLUGIN_NAME (
    echo [ERR] Cannot parse plugin.json. Ensure python or python3 is installed.
    exit /b 1
)

set "MARKETPLACE_NAME=%PLUGIN_NAME%-marketplace"

set "CLAUDE_HOME=%USERPROFILE%\.claude"
set "CODEX_HOME=%USERPROFILE%\.codex"
set "GEMINI_HOME=%USERPROFILE%\.gemini"

set "PLUGINS_DIR=%CLAUDE_HOME%\plugins"
set "MARKETPLACES_DIR=%PLUGINS_DIR%\marketplaces"
set "CACHE_DIR=%PLUGINS_DIR%\cache"
set "KNOWN_MP=%PLUGINS_DIR%\known_marketplaces.json"
set "INSTALLED_PL=%PLUGINS_DIR%\installed_plugins.json"

:: ============================================================
:: Main entry point
:: ============================================================

if "%~1"=="--clean" goto :clean
if "%~1"=="--check" goto :check
goto :deploy

:: ============================================================
:: Deploy
:: ============================================================
:deploy
echo.
echo ========================================
echo   u-maker Local Deploy (Windows)
echo ========================================
echo   Plugin:  %PLUGIN_NAME% v%PLUGIN_VERSION%
echo   Source:  %SCRIPT_DIR%
echo   Claude:  %CLAUDE_HOME%
echo   Codex:   %CODEX_HOME%
echo   Gemini:  %GEMINI_HOME%
echo ----------------------------------------
echo.

:: Ensure directories exist
if not exist "%MARKETPLACES_DIR%" mkdir "%MARKETPLACES_DIR%"
if not exist "%CACHE_DIR%" mkdir "%CACHE_DIR%"

:: Step 1: Marketplace junction
echo [u-maker] 1/10 Marketplace junction
call :make_junction "%MARKETPLACES_DIR%\%MARKETPLACE_NAME%" "%SCRIPT_DIR%"

:: Step 2: Cache sync
echo [u-maker] 2/10 Cache sync
call :sync_cache

:: Step 3: known_marketplaces.json
echo [u-maker] 3/10 known_marketplaces.json
call :update_known_marketplaces

:: Step 4: installed_plugins.json
echo [u-maker] 4/10 installed_plugins.json
call :update_installed_plugins

:: Step 5: Clean stale skill symlinks
echo [u-maker] 5/10 Clean stale skill junctions
call :clean_stale_skills

:: Step 6: Clean stale agent symlinks
echo [u-maker] 6/10 Clean stale agent junctions
call :clean_stale_agents

:: Step 7: Skill junctions
echo [u-maker] 7/10 Skill junctions
call :register_skills

:: Step 8: Agent junctions
echo [u-maker] 8/10 Agent junctions
call :register_agents

:: Step 9: Codex integration
echo [u-maker] 9/10 Codex integration
call :setup_codex

:: Step 10: Gemini integration
echo [u-maker] 10/10 Gemini integration
call :setup_gemini

echo.
echo ========================================
echo   Deploy complete!
echo ========================================
echo.
echo   Restart Claude Code / Codex / Gemini CLI to pick up changes.
echo.
goto :eof

:: ============================================================
:: Clean (--clean)
:: ============================================================
:clean
echo.
echo [u-maker] Cleaning u-maker deployment...

:: Remove marketplace junction
if exist "%MARKETPLACES_DIR%\%MARKETPLACE_NAME%" (
    rmdir "%MARKETPLACES_DIR%\%MARKETPLACE_NAME%" 2>nul
    if not exist "%MARKETPLACES_DIR%\%MARKETPLACE_NAME%" (
        echo   [OK] Marketplace junction removed
    ) else (
        rd /s /q "%MARKETPLACES_DIR%\%MARKETPLACE_NAME%" 2>nul
        echo   [OK] Marketplace directory removed
    )
)

:: Remove cache
if exist "%CACHE_DIR%\%PLUGIN_NAME%" (
    rd /s /q "%CACHE_DIR%\%PLUGIN_NAME%"
    echo   [OK] Cache removed
)

:: Remove from known_marketplaces.json
if exist "%KNOWN_MP%" (
    call :py_exec "import json; f='%KNOWN_MP:\=\\%'; d=json.load(open(f)); d.pop('%PLUGIN_NAME%',None); json.dump(d,open(f,'w'),indent=2)"
    echo   [OK] known_marketplaces.json cleaned
)

:: Remove from installed_plugins.json
if exist "%INSTALLED_PL%" (
    call :py_exec "import json; f='%INSTALLED_PL:\=\\%'; d=json.load(open(f)); d.get('plugins',{}).pop('%PLUGIN_NAME%@%PLUGIN_NAME%',None); json.dump(d,open(f,'w'),indent=2)"
    echo   [OK] installed_plugins.json cleaned
)

:: Remove skill junctions
set "SKILLS_ROOT=%CLAUDE_HOME%\skills"
if exist "%SKILLS_ROOT%" (
    set "SCOUNT=0"
    for /d %%d in ("%SKILLS_ROOT%\%PLUGIN_NAME%__*") do (
        rmdir "%%d" 2>nul
        if not exist "%%d" set /a SCOUNT+=1
    )
    if !SCOUNT! GTR 0 echo   [OK] Removed !SCOUNT! skill junctions
)

:: Remove agent junctions/links
set "AGENTS_ROOT=%CLAUDE_HOME%\agents"
if exist "%AGENTS_ROOT%" (
    set "ACOUNT=0"
    for %%f in ("%AGENTS_ROOT%\%PLUGIN_NAME%__*.md") do (
        del "%%f" 2>nul
        set /a ACOUNT+=1
    )
    if !ACOUNT! GTR 0 echo   [OK] Removed !ACOUNT! agent links
)

:: Remove Gemini junctions
if exist "%GEMINI_HOME%" (
    for %%l in (plugins agents skills) do (
        if exist "%GEMINI_HOME%\%%l" (
            rmdir "%GEMINI_HOME%\%%l" 2>nul
            echo   [OK] Gemini %%l junction removed
        )
    )
)

echo.
echo   [OK] Clean complete. Restart Claude Code / Codex / Gemini CLI.
echo.
goto :eof

:: ============================================================
:: Check (--check)
:: ============================================================
:check
echo.
echo ========================================
echo   u-maker Deployment Status
echo ========================================
echo.

set "ALL_OK=1"

:: Marketplace junction
if exist "%MARKETPLACES_DIR%\%MARKETPLACE_NAME%" (
    echo   [OK] Marketplace junction exists
) else (
    echo   [ERR] Marketplace junction missing
    set "ALL_OK=0"
)

:: Cache
set "CACHE_PATH=%CACHE_DIR%\%PLUGIN_NAME%\%PLUGIN_NAME%\%PLUGIN_VERSION%"
if exist "%CACHE_PATH%" (
    echo   [OK] Cache exists at %CACHE_PATH%
) else (
    echo   [ERR] Cache missing at %CACHE_PATH%
    set "ALL_OK=0"
)

:: known_marketplaces.json
if exist "%KNOWN_MP%" (
    for /f "usebackq delims=" %%r in (`call :py_out "import json; print('yes' if '%PLUGIN_NAME%' in json.load(open(r'%KNOWN_MP%')) else 'no')"`) do set "HAS_KM=%%r"
    if "!HAS_KM!"=="yes" (
        echo   [OK] known_marketplaces.json has entry
    ) else (
        echo   [ERR] known_marketplaces.json missing entry
        set "ALL_OK=0"
    )
) else (
    echo   [ERR] known_marketplaces.json not found
    set "ALL_OK=0"
)

:: installed_plugins.json
if exist "%INSTALLED_PL%" (
    for /f "usebackq delims=" %%r in (`call :py_out "import json; print('yes' if '%PLUGIN_NAME%@%PLUGIN_NAME%' in json.load(open(r'%INSTALLED_PL%')).get('plugins',{}) else 'no')"`) do set "HAS_IP=%%r"
    if "!HAS_IP!"=="yes" (
        echo   [OK] installed_plugins.json has entry
    ) else (
        echo   [ERR] installed_plugins.json missing entry
        set "ALL_OK=0"
    )
) else (
    echo   [ERR] installed_plugins.json not found
    set "ALL_OK=0"
)

:: Skill junctions count
set "SK_COUNT=0"
if exist "%CLAUDE_HOME%\skills" (
    for /d %%d in ("%CLAUDE_HOME%\skills\%PLUGIN_NAME%__*") do set /a SK_COUNT+=1
)
echo   [OK] %SK_COUNT% skill junctions registered

:: Agent links count
set "AG_COUNT=0"
if exist "%CLAUDE_HOME%\agents" (
    for %%f in ("%CLAUDE_HOME%\agents\%PLUGIN_NAME%__*.md") do set /a AG_COUNT+=1
)
echo   [OK] %AG_COUNT% agent links registered

:: Codex
if exist "%CODEX_HOME%" (
    if exist "%CODEX_HOME%\plugins" (
        echo   [OK] Codex plugins junction exists
    ) else (
        echo   [WARN] Codex plugins junction missing
    )
) else (
    echo   [WARN] Codex not installed ^(skipped^)
)

:: Gemini
if exist "%GEMINI_HOME%" (
    if exist "%GEMINI_HOME%\plugins" (
        echo   [OK] Gemini plugins junction exists
    ) else (
        echo   [WARN] Gemini plugins junction missing
    )
) else (
    echo   [WARN] Gemini not installed ^(skipped^)
)

echo.
if "%ALL_OK%"=="1" (
    echo   All checks passed.
) else (
    echo   Issues found. Run deploy_local.bat to fix.
)
echo.
goto :eof

:: ============================================================
:: Subroutines
:: ============================================================

:: --- make_junction <link_path> <target> ---
:make_junction
set "LINK_PATH=%~1"
set "TARGET=%~2"

if exist "%LINK_PATH%" (
    :: Check if it's a junction (directory reparse point)
    fsutil reparsepoint query "%LINK_PATH%" >nul 2>&1
    if !errorlevel! equ 0 (
        rmdir "%LINK_PATH%" 2>nul
    ) else (
        rd /s /q "%LINK_PATH%" 2>nul
    )
)

mklink /J "%LINK_PATH%" "%TARGET%" >nul 2>&1
if !errorlevel! equ 0 (
    echo   [OK] Junction created: %LINK_PATH%
) else (
    echo   [ERR] Failed to create junction: %LINK_PATH%
    echo        Try running as Administrator.
)
goto :eof

:: --- sync_cache ---
:sync_cache
set "DEST=%CACHE_DIR%\%PLUGIN_NAME%\%PLUGIN_NAME%\%PLUGIN_VERSION%"

if exist "%DEST%" rd /s /q "%DEST%"
mkdir "%DEST%" 2>nul

:: Use robocopy for efficient sync (exit codes 0-7 are success)
robocopy "%SCRIPT_DIR%" "%DEST%" /E /XD .git node_modules /XF .DS_Store .orphaned_at /NFL /NDL /NJH /NJS /NC /NS /NP >nul 2>&1
if !errorlevel! LEQ 7 (
    echo   [OK] Cache synced: cache\%PLUGIN_NAME%\%PLUGIN_NAME%\%PLUGIN_VERSION%
) else (
    echo   [WARN] Robocopy returned code !errorlevel!, trying xcopy fallback...
    xcopy "%SCRIPT_DIR%\*" "%DEST%\" /E /I /Y /Q >nul 2>&1
    :: Remove excluded items
    if exist "%DEST%\.git" rd /s /q "%DEST%\.git"
    if exist "%DEST%\node_modules" rd /s /q "%DEST%\node_modules"
    echo   [OK] Cache synced via xcopy fallback
)
goto :eof

:: --- update_known_marketplaces ---
:update_known_marketplaces
if not exist "%KNOWN_MP%" echo {} > "%KNOWN_MP%"

call :py_exec "import json; from datetime import datetime, timezone; f=r'%KNOWN_MP%'; d=json.load(open(f)); d['%PLUGIN_NAME%']={'source':{'source':'directory','path':r'%SCRIPT_DIR%'},'installLocation':r'%SCRIPT_DIR%','lastUpdated':datetime.now(timezone.utc).strftime('%%Y-%%m-%%dT%%H:%%M:%%S.000Z')}; json.dump(d,open(f,'w'),indent=2)"
echo   [OK] known_marketplaces.json updated
goto :eof

:: --- update_installed_plugins ---
:update_installed_plugins
if not exist "%INSTALLED_PL%" echo {"plugins":{}} > "%INSTALLED_PL%"

call :py_exec "import json; from datetime import datetime, timezone; f=r'%INSTALLED_PL%'; d=json.load(open(f)); d.setdefault('plugins',{}); now=datetime.now(timezone.utc).strftime('%%Y-%%m-%%dT%%H:%%M:%%S.000Z'); d['plugins']['%PLUGIN_NAME%@%PLUGIN_NAME%']=[{'scope':'user','installPath':r'%SCRIPT_DIR%','version':'%PLUGIN_VERSION%','installedAt':now,'lastUpdated':now}]; json.dump(d,open(f,'w'),indent=2)"
echo   [OK] installed_plugins.json updated
goto :eof

:: --- register_skills ---
:register_skills
set "SKILLS_ROOT=%CLAUDE_HOME%\skills"
set "CACHE_SKILLS=%CACHE_DIR%\%PLUGIN_NAME%\%PLUGIN_NAME%\%PLUGIN_VERSION%\skills"

if not exist "%SKILLS_ROOT%" mkdir "%SKILLS_ROOT%"
if not exist "%CACHE_SKILLS%" (
    echo   [WARN] No skills directory in cache, skipping
    goto :eof
)

set "COUNT=0"
for /d %%d in ("%CACHE_SKILLS%\*") do (
    set "SKILL_NAME=%%~nxd"
    set "LINK_NAME=%PLUGIN_NAME%__!SKILL_NAME!"
    set "LINK_PATH=%SKILLS_ROOT%\!LINK_NAME!"

    if exist "!LINK_PATH!" (
        rmdir "!LINK_PATH!" 2>nul
    )
    mklink /J "!LINK_PATH!" "%%d" >nul 2>&1
    set /a COUNT+=1
)

if !COUNT! GTR 0 (
    echo   [OK] Registered !COUNT! skill junctions
) else (
    echo   [OK] No skills to register
)
goto :eof

:: --- register_agents ---
:register_agents
set "AGENTS_ROOT=%CLAUDE_HOME%\agents"
set "CACHE_AGENTS=%CACHE_DIR%\%PLUGIN_NAME%\%PLUGIN_NAME%\%PLUGIN_VERSION%\agents"

if not exist "%AGENTS_ROOT%" mkdir "%AGENTS_ROOT%"
if not exist "%CACHE_AGENTS%" (
    echo   [WARN] No agents directory in cache, skipping
    goto :eof
)

set "COUNT=0"
for %%f in ("%CACHE_AGENTS%\*.md") do (
    set "AGENT_NAME=%%~nxf"
    set "LINK_NAME=%PLUGIN_NAME%__!AGENT_NAME!"
    set "LINK_PATH=%AGENTS_ROOT%\!LINK_NAME!"

    if exist "!LINK_PATH!" del "!LINK_PATH!" 2>nul
    :: For agent files, create a hard link (file, not directory)
    mklink /H "!LINK_PATH!" "%%f" >nul 2>&1
    if !errorlevel! neq 0 (
        :: Fallback: copy the file
        copy "%%f" "!LINK_PATH!" >nul 2>&1
    )
    set /a COUNT+=1
)

if !COUNT! GTR 0 (
    echo   [OK] Registered !COUNT! agent links
) else (
    echo   [OK] No agents to register
)
goto :eof

:: --- clean_stale_skills ---
:clean_stale_skills
set "SKILLS_ROOT=%CLAUDE_HOME%\skills"
set "CACHE_SKILLS=%CACHE_DIR%\%PLUGIN_NAME%\%PLUGIN_NAME%\%PLUGIN_VERSION%\skills"
set "COUNT=0"

if not exist "%SKILLS_ROOT%" goto :eof

for /d %%d in ("%SKILLS_ROOT%\%PLUGIN_NAME%__*") do (
    set "LINK_NAME=%%~nxd"
    set "SKILL_NAME=!LINK_NAME:%PLUGIN_NAME%__=!"
    if not exist "%CACHE_SKILLS%\!SKILL_NAME!" (
        rmdir "%%d" 2>nul
        set /a COUNT+=1
    )
)

if !COUNT! GTR 0 (
    echo   [OK] Removed !COUNT! stale skill junctions
) else (
    echo   [OK] No stale skill junctions
)
goto :eof

:: --- clean_stale_agents ---
:clean_stale_agents
set "AGENTS_ROOT=%CLAUDE_HOME%\agents"
set "CACHE_AGENTS=%CACHE_DIR%\%PLUGIN_NAME%\%PLUGIN_NAME%\%PLUGIN_VERSION%\agents"
set "COUNT=0"

if not exist "%AGENTS_ROOT%" goto :eof

for %%f in ("%AGENTS_ROOT%\%PLUGIN_NAME%__*.md") do (
    set "LINK_NAME=%%~nxf"
    set "AGENT_NAME=!LINK_NAME:%PLUGIN_NAME%__=!"
    if not exist "%CACHE_AGENTS%\!AGENT_NAME!" (
        del "%%f" 2>nul
        set /a COUNT+=1
    )
)

if !COUNT! GTR 0 (
    echo   [OK] Removed !COUNT! stale agent links
) else (
    echo   [OK] No stale agent links
)
goto :eof

:: --- setup_codex ---
:setup_codex
if not exist "%CODEX_HOME%" (
    echo   [WARN] Codex home not found, skipping
    goto :eof
)

call :make_junction "%CODEX_HOME%\plugins" "%PLUGINS_DIR%"

if exist "%CLAUDE_HOME%\agents" (
    call :make_junction "%CODEX_HOME%\agents" "%CLAUDE_HOME%\agents"
)
if exist "%CLAUDE_HOME%\skills" (
    call :make_junction "%CODEX_HOME%\skills" "%CLAUDE_HOME%\skills"
)
echo   [OK] Codex shares Claude plugin directories
goto :eof

:: --- setup_gemini ---
:setup_gemini
if not exist "%GEMINI_HOME%" (
    echo   [WARN] Gemini home not found, skipping
    goto :eof
)

call :make_junction "%GEMINI_HOME%\plugins" "%PLUGINS_DIR%"

if exist "%CLAUDE_HOME%\agents" (
    call :make_junction "%GEMINI_HOME%\agents" "%CLAUDE_HOME%\agents"
)
if exist "%CLAUDE_HOME%\skills" (
    call :make_junction "%GEMINI_HOME%\skills" "%CLAUDE_HOME%\skills"
)
echo   [OK] Gemini shares Claude plugin directories
goto :eof

:: --- py_exec <python_code> ---
:: Execute python code (tries python then python3)
:py_exec
python -c "%~1" 2>nul
if !errorlevel! neq 0 python3 -c "%~1" 2>nul
goto :eof

:: --- py_out <python_code> ---
:: Execute python code and capture output
:py_out
python -c "%~1" 2>nul
if !errorlevel! neq 0 python3 -c "%~1" 2>nul
goto :eof

:: ============================================================
:: Prerequisites: check & auto-install
:: ============================================================

:check_prerequisites
echo.
echo ========================================
echo   Checking prerequisites...
echo ========================================
echo.

set "PREREQ_FAIL=0"

:: --- winget ---
call :check_winget

:: --- Node.js ---
call :check_tool "node" "--version" "Node.js"
if !errorlevel! neq 0 (
    call :install_with_winget "OpenJS.NodeJS.LTS" "Node.js LTS"
    if !errorlevel! neq 0 set "PREREQ_FAIL=1"
)

:: --- Python ---
call :check_python
if !errorlevel! neq 0 (
    call :install_with_winget "Python.Python.3.12" "Python 3.12"
    if !errorlevel! neq 0 set "PREREQ_FAIL=1"
)

:: --- bun ---
call :check_tool "bun" "--version" "bun"
if !errorlevel! neq 0 (
    call :install_bun
    if !errorlevel! neq 0 set "PREREQ_FAIL=1"
)

:: --- Claude Code (npm package) ---
call :check_tool "claude" "--version" "Claude Code"
if !errorlevel! neq 0 (
    echo   [WARN] Claude Code CLI not found. Install it manually:
    echo          npm install -g @anthropic-ai/claude-code
    echo.
)

:: Refresh PATH after installs
call :refresh_path

:: Final verification
echo.
echo ----------------------------------------
echo   Final verification
echo ----------------------------------------
set "FINAL_FAIL=0"

call :verify_tool "node" "Node.js"
if !errorlevel! neq 0 set "FINAL_FAIL=1"

call :verify_python
if !errorlevel! neq 0 set "FINAL_FAIL=1"

call :verify_tool "bun" "bun"
if !errorlevel! neq 0 set "FINAL_FAIL=1"

if "!FINAL_FAIL!"=="1" (
    echo.
    echo   [WARN] Some tools may require a new terminal window to be detected.
    echo          Close this window, open a new cmd, and run deploy_local.bat again.
    echo.
    exit /b 1
)

echo.
echo   [OK] All prerequisites satisfied.
echo.
exit /b 0

:: --- check_winget ---
:check_winget
where winget >nul 2>&1
if !errorlevel! neq 0 (
    echo   [WARN] winget not found. Auto-install will use fallback methods.
    set "HAS_WINGET=0"
) else (
    set "HAS_WINGET=1"
    echo   [OK] winget available
)
goto :eof

:: --- check_tool <command> <version_flag> <display_name> ---
:check_tool
set "CMD_NAME=%~1"
set "VER_FLAG=%~2"
set "DISP_NAME=%~3"

where %CMD_NAME% >nul 2>&1
if !errorlevel! neq 0 (
    echo   [--] %DISP_NAME% not found
    exit /b 1
)

for /f "usebackq delims=" %%v in (`%CMD_NAME% %VER_FLAG% 2^>^&1`) do set "TOOL_VER=%%v"
echo   [OK] %DISP_NAME% found: !TOOL_VER!
exit /b 0

:: --- check_python ---
:check_python
:: Try python first, then python3
where python >nul 2>&1
if !errorlevel! equ 0 (
    :: Verify it's real Python (not Windows Store alias)
    python --version >nul 2>&1
    if !errorlevel! equ 0 (
        for /f "usebackq delims=" %%v in (`python --version 2^>^&1`) do set "PY_VER=%%v"
        echo   [OK] Python found: !PY_VER!
        exit /b 0
    )
)
where python3 >nul 2>&1
if !errorlevel! equ 0 (
    for /f "usebackq delims=" %%v in (`python3 --version 2^>^&1`) do set "PY_VER=%%v"
    echo   [OK] Python found: !PY_VER!
    exit /b 0
)
echo   [--] Python not found
exit /b 1

:: --- verify_tool <command> <display_name> ---
:verify_tool
where %~1 >nul 2>&1
if !errorlevel! neq 0 (
    echo   [ERR] %~2 still not found after install
    exit /b 1
)
for /f "usebackq delims=" %%v in (`%~1 --version 2^>^&1`) do set "V_VER=%%v"
echo   [OK] %~2: !V_VER!
exit /b 0

:: --- verify_python ---
:verify_python
where python >nul 2>&1
if !errorlevel! equ 0 (
    python --version >nul 2>&1
    if !errorlevel! equ 0 (
        for /f "usebackq delims=" %%v in (`python --version 2^>^&1`) do echo   [OK] Python: %%v
        exit /b 0
    )
)
where python3 >nul 2>&1
if !errorlevel! equ 0 (
    for /f "usebackq delims=" %%v in (`python3 --version 2^>^&1`) do echo   [OK] Python: %%v
    exit /b 0
)
echo   [ERR] Python still not found after install
exit /b 1

:: --- install_with_winget <package_id> <display_name> ---
:install_with_winget
set "PKG_ID=%~1"
set "PKG_NAME=%~2"

if "!HAS_WINGET!"=="0" (
    echo   [ERR] Cannot auto-install %PKG_NAME%: winget not available.
    echo        Please install %PKG_NAME% manually and retry.
    exit /b 1
)

echo.
echo   [..] Installing %PKG_NAME% via winget...
echo        Package: %PKG_ID%
echo.

winget install --id %PKG_ID% --accept-source-agreements --accept-package-agreements --silent
if !errorlevel! neq 0 (
    :: winget may return non-zero if already installed
    winget list --id %PKG_ID% >nul 2>&1
    if !errorlevel! equ 0 (
        echo   [OK] %PKG_NAME% is already installed
        exit /b 0
    )
    echo   [ERR] Failed to install %PKG_NAME% via winget.
    echo        Please install manually and retry.
    exit /b 1
)
echo   [OK] %PKG_NAME% installed successfully
exit /b 0

:: --- install_bun ---
:install_bun
:: Try winget first
if "!HAS_WINGET!"=="1" (
    echo.
    echo   [..] Installing bun via winget...
    winget install --id Oven-sh.Bun --accept-source-agreements --accept-package-agreements --silent
    if !errorlevel! equ 0 (
        echo   [OK] bun installed via winget
        exit /b 0
    )
    :: winget may return non-zero if already installed
    winget list --id Oven-sh.Bun >nul 2>&1
    if !errorlevel! equ 0 (
        echo   [OK] bun is already installed
        exit /b 0
    )
)

:: Fallback: use PowerShell install script
echo   [..] Installing bun via PowerShell...
powershell -Command "irm bun.sh/install.ps1 | iex" 2>nul
if !errorlevel! equ 0 (
    echo   [OK] bun installed via PowerShell
    exit /b 0
)

:: Fallback: npm global install
where npm >nul 2>&1
if !errorlevel! equ 0 (
    echo   [..] Installing bun via npm...
    npm install -g bun 2>nul
    if !errorlevel! equ 0 (
        echo   [OK] bun installed via npm
        exit /b 0
    )
)

echo   [ERR] Failed to install bun. Please install manually:
echo        https://bun.sh/docs/installation
exit /b 1

:: --- refresh_path ---
:: Reload PATH from registry to pick up newly installed tools
:refresh_path
for /f "usebackq tokens=2,*" %%a in (`reg query "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Environment" /v Path 2^>nul`) do set "SYS_PATH=%%b"
for /f "usebackq tokens=2,*" %%a in (`reg query "HKCU\Environment" /v Path 2^>nul`) do set "USR_PATH=%%b"
if defined SYS_PATH if defined USR_PATH set "PATH=!SYS_PATH!;!USR_PATH!"

:: Also add common install locations that may not be in PATH yet
if exist "%USERPROFILE%\.bun\bin" set "PATH=!PATH!;%USERPROFILE%\.bun\bin"
if exist "%LOCALAPPDATA%\Programs\Python" (
    for /d %%p in ("%LOCALAPPDATA%\Programs\Python\Python*") do (
        set "PATH=!PATH!;%%p;%%p\Scripts"
    )
)
if exist "%ProgramFiles%\nodejs" set "PATH=!PATH!;%ProgramFiles%\nodejs"
goto :eof
