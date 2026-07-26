# install.ps1 — umaker plugin installer (Windows PowerShell)
#
# One-line install (CMD):
#   curl.exe -fsSL --ssl-no-revoke -o "%TEMP%\install.ps1" https://raw.githubusercontent.com/upleat-ax/umaker-plugin/main/install.ps1 && powershell -NoProfile -ExecutionPolicy Bypass -File "%TEMP%\install.ps1"
#
# Options (environment variables):
#   $env:UMAKER_VERSION = "4.0.0"   # specific version
#   $env:UMAKER_UNINSTALL = "1"     # uninstall mode

$ErrorActionPreference = "Stop"
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
[Net.ServicePointManager]::CheckCertificateRevocationList = $false

$repo = "upleat-ax/umaker-plugin"
$apiBase = "https://api.github.com/repos/$repo/releases"
$rawBase = "https://raw.githubusercontent.com/$repo/main"
$tmp = Join-Path $env:TEMP "umaker-install-$(Get-Random)"
$headers = @{ "User-Agent" = "umaker-installer/1.0"; "Accept" = "application/vnd.github+json" }
# Plugin names: new (umaker) + legacy pre-rename (u-maker). Cleanup targets both
# so upgrades from an old u-maker install leave nothing behind.
$pluginNames = @("u-maker", "umaker")

function Write-Step($msg) { Write-Host "  [..] $msg" -NoNewline }
function Write-OK($msg)   { Write-Host "`r  [OK] $msg                    " -ForegroundColor Green }
function Write-Err($msg)  { Write-Host "`r  [ERR] $msg" -ForegroundColor Red }

function Invoke-GHApi($uri) {
    # curl.exe first (handles SSL reliably on Windows)
    try {
        $curlOut = & curl.exe -fsSL --ssl-no-revoke -H "User-Agent: umaker-installer" -H "Accept: application/vnd.github+json" $uri 2>&1
        if ($LASTEXITCODE -eq 0 -and $curlOut) {
            return ($curlOut | ConvertFrom-Json)
        }
    } catch {}
    # Fallback: PowerShell
    try {
        $resp = Invoke-WebRequest -Uri $uri -Headers $headers -UseBasicParsing -ErrorAction Stop
        return ($resp.Content | ConvertFrom-Json)
    } catch {}
    throw "API call failed: $uri"
}

function Invoke-Download($uri, $outFile) {
    # curl.exe first
    try {
        & curl.exe -fsSL --ssl-no-revoke -o $outFile $uri 2>&1
        if ($LASTEXITCODE -eq 0 -and (Test-Path $outFile)) { return }
    } catch {}
    # Fallback: PowerShell
    try {
        Invoke-WebRequest -Uri $uri -OutFile $outFile -Headers @{"User-Agent"="umaker-installer"} -UseBasicParsing -ErrorAction Stop
        return
    } catch {}
    throw "Download failed: $uri"
}

try {
    New-Item -ItemType Directory -Path $tmp -Force | Out-Null

    Write-Host ""
    Write-Host "  ========================================" -ForegroundColor Cyan
    Write-Host "    umaker Plugin Installer (Windows)" -ForegroundColor Cyan
    Write-Host "  ========================================" -ForegroundColor Cyan
    Write-Host ""

    # --- Uninstall mode ---
    if ($env:UMAKER_UNINSTALL -eq "1") {
        Write-Host "  Uninstalling umaker (incl. legacy u-maker artifacts)..." -ForegroundColor Yellow
        $claudeHome = Join-Path $env:USERPROFILE ".claude"
        $pluginsDir = Join-Path $claudeHome "plugins"
        $skillsDir  = Join-Path $claudeHome "skills"
        $agentsDir  = Join-Path $claudeHome "agents"

        foreach ($name in $pluginNames) {
            # Remove skill junctions
            if (Test-Path $skillsDir) {
                Get-ChildItem "$skillsDir\${name}__*" -Directory -ErrorAction SilentlyContinue | ForEach-Object {
                    cmd /c "rmdir `"$($_.FullName)`"" 2>$null
                    if (!(Test-Path $_.FullName)) { Remove-Item $_.FullName -Recurse -Force -ErrorAction SilentlyContinue }
                }
                Write-OK "Skill junctions removed (${name}__*)"
            }
            # Remove agent links
            if (Test-Path $agentsDir) {
                Get-ChildItem "$agentsDir\${name}__*" -File -ErrorAction SilentlyContinue | Remove-Item -Force -ErrorAction SilentlyContinue
                Write-OK "Agent links removed (${name}__*)"
            }
            # Remove marketplace junction
            $mpDir = Join-Path $pluginsDir "marketplaces\${name}-marketplace"
            if (Test-Path $mpDir) { cmd /c "rmdir `"$mpDir`"" 2>$null; Write-OK "Marketplace junction removed (${name})" }
            # Remove cache
            $cacheDir = Join-Path $pluginsDir "cache\${name}"
            if (Test-Path $cacheDir) { Remove-Item $cacheDir -Recurse -Force; Write-OK "Cache removed (${name})" }
            # Clean JSON registries
            $knownMp = Join-Path $pluginsDir "known_marketplaces.json"
            if (Test-Path $knownMp) {
                $d = Get-Content $knownMp | ConvertFrom-Json
                $d.PSObject.Properties.Remove($name)
                $d | ConvertTo-Json -Depth 10 | Set-Content $knownMp
                Write-OK "known_marketplaces.json cleaned (${name})"
            }
            $instPl = Join-Path $pluginsDir "installed_plugins.json"
            if (Test-Path $instPl) {
                $d = Get-Content $instPl | ConvertFrom-Json
                if ($d.plugins.PSObject.Properties["${name}@${name}"]) {
                    $d.plugins.PSObject.Properties.Remove("${name}@${name}")
                    $d | ConvertTo-Json -Depth 10 | Set-Content $instPl
                }
                Write-OK "installed_plugins.json cleaned (${name}@${name})"
            }
            # Remove enabledPlugins toggle from settings.json
            $settingsFile = Join-Path $claudeHome "settings.json"
            if (Test-Path $settingsFile) {
                $d = Get-Content $settingsFile | ConvertFrom-Json
                if ($d.enabledPlugins -and $d.enabledPlugins.PSObject.Properties["${name}@${name}"]) {
                    $d.enabledPlugins.PSObject.Properties.Remove("${name}@${name}")
                    $d | ConvertTo-Json -Depth 10 | Set-Content $settingsFile
                }
                Write-OK "settings.json enabledPlugins cleaned (${name}@${name})"
            }
        }
        Write-Host ""
        Write-Host "  Uninstall complete. Restart Claude Code." -ForegroundColor Green
        Write-Host ""
        return
    }

    # --- Determine version ---
    if ($env:UMAKER_VERSION) {
        $version = $env:UMAKER_VERSION
        if ($version[0] -ne "v") { $version = "v$version" }
    } else {
        Write-Step "Fetching latest release..."
        try {
            $release = Invoke-GHApi "$apiBase/latest"
            $version = $release.tag_name
            if (-not $version) { throw "tag_name is empty in API response" }
        } catch {
            Write-Err "Failed to fetch latest release: $_"
            Write-Host "         Check: https://github.com/$repo/releases" -ForegroundColor Yellow
            throw
        }
    }
    Write-OK "Version: $version"

    # --- Find zip download URL ---
    Write-Step "Finding download URL..."
    try {
        $release = Invoke-GHApi "$apiBase/tags/$version"
        $zipAsset = $release.assets | Where-Object { $_.name -like "*.zip" } | Select-Object -First 1
        if (-not $zipAsset) { throw "No zip asset found in release $version" }
        $downloadUrl = $zipAsset.browser_download_url
        if (-not $downloadUrl) { throw "browser_download_url is empty" }
    } catch {
        Write-Err "No zip asset for $version : $_"
        Write-Host "         Check: https://github.com/$repo/releases/tag/$version" -ForegroundColor Yellow
        throw
    }
    Write-OK "URL: $downloadUrl"

    # --- Clean previous installation (new umaker + legacy u-maker artifacts) ---
    Write-Step "Cleaning previous installation..."
    $claudeHome = Join-Path $env:USERPROFILE ".claude"
    $skillsDir  = Join-Path $claudeHome "skills"
    $agentsDir  = Join-Path $claudeHome "agents"
    foreach ($name in $pluginNames) {
        if (Test-Path $skillsDir) {
            Get-ChildItem "$skillsDir\${name}__*" -Directory -ErrorAction SilentlyContinue | ForEach-Object {
                cmd /c "rmdir `"$($_.FullName)`"" 2>$null
                if (Test-Path $_.FullName) { Remove-Item $_.FullName -Recurse -Force -ErrorAction SilentlyContinue }
            }
        }
        if (Test-Path $agentsDir) {
            Get-ChildItem "$agentsDir\${name}__*" -File -ErrorAction SilentlyContinue | Remove-Item -Force -ErrorAction SilentlyContinue
        }
        $mpDir = Join-Path $claudeHome "plugins\marketplaces\${name}-marketplace"
        if (Test-Path $mpDir) { cmd /c "rmdir `"$mpDir`"" 2>$null }
        $cacheDir = Join-Path $claudeHome "plugins\cache\${name}"
        if (Test-Path $cacheDir) { Remove-Item $cacheDir -Recurse -Force -ErrorAction SilentlyContinue }
        # Clean JSON registries so no dangling entries remain
        # (deploy_local.bat re-adds the new-name keys right after)
        $knownMp = Join-Path $claudeHome "plugins\known_marketplaces.json"
        if (Test-Path $knownMp) {
            $d = Get-Content $knownMp | ConvertFrom-Json
            if ($d.PSObject.Properties[$name]) {
                $d.PSObject.Properties.Remove($name)
                $d | ConvertTo-Json -Depth 10 | Set-Content $knownMp
            }
        }
        $instPl = Join-Path $claudeHome "plugins\installed_plugins.json"
        if (Test-Path $instPl) {
            $d = Get-Content $instPl | ConvertFrom-Json
            if ($d.plugins -and $d.plugins.PSObject.Properties["${name}@${name}"]) {
                $d.plugins.PSObject.Properties.Remove("${name}@${name}")
                $d | ConvertTo-Json -Depth 10 | Set-Content $instPl
            }
        }
        # Remove enabledPlugins toggle from settings.json
        $settingsFile = Join-Path $claudeHome "settings.json"
        if (Test-Path $settingsFile) {
            $d = Get-Content $settingsFile | ConvertFrom-Json
            if ($d.enabledPlugins -and $d.enabledPlugins.PSObject.Properties["${name}@${name}"]) {
                $d.enabledPlugins.PSObject.Properties.Remove("${name}@${name}")
                $d | ConvertTo-Json -Depth 10 | Set-Content $settingsFile
            }
        }
    }
    Write-OK "Previous installation cleaned"

    # --- Download ---
    Write-Step "Downloading..."
    $zipFile = Join-Path $tmp "umaker-plugin.zip"
    Invoke-Download $downloadUrl $zipFile
    Write-OK "Downloaded"

    # --- Extract ---
    Write-Step "Extracting..."
    $extractDir = Join-Path $tmp "plugin"
    Expand-Archive -Path $zipFile -DestinationPath $extractDir -Force
    Write-OK "Extracted"

    # --- Fix line endings (GitHub may deliver LF instead of CRLF) ---
    Write-Step "Fixing line endings..."
    Get-ChildItem $extractDir -Filter "*.bat" -Recurse | ForEach-Object {
        $raw = [System.IO.File]::ReadAllText($_.FullName)
        $fixed = $raw -replace "`r`n", "`n"
        $fixed = $fixed -replace "`n", "`r`n"
        [System.IO.File]::WriteAllText($_.FullName, $fixed)
    }
    Write-OK "Line endings fixed (CRLF)"

    # --- Find deploy_local.bat and run ---
    $deployBat = Get-ChildItem $extractDir -Filter "deploy_local.bat" -Recurse | Select-Object -First 1
    if (-not $deployBat) {
        Write-Err "deploy_local.bat not found in archive"
        throw "deploy_local.bat not found"
    }

    Write-Step "Installing..."
    Write-Host ""
    & cmd /c "cd /d `"$($deployBat.DirectoryName)`" && `"$($deployBat.FullName)`""
    if ($LASTEXITCODE -ne 0) {
        Write-Err "Installation failed"
        throw "deploy_local.bat failed"
    }

    # --- Warn about existing .u-maker/ projects ---
    $umakerDir = Join-Path (Get-Location) ".u-maker"
    if (Test-Path $umakerDir) {
        Write-Host ""
        Write-Host "  [WARN] Existing .u-maker/ folder detected. If upgrading from an older version, re-initialize with /um-plan." -ForegroundColor Yellow
        Write-Host ""
    }

    Write-Host ""
    Write-Host "  ========================================" -ForegroundColor Green
    Write-Host "    umaker $version installed!" -ForegroundColor Green
    Write-Host "  ========================================" -ForegroundColor Green
    Write-Host ""
    Write-Host "    Restart Claude Code, then run:" -ForegroundColor White
    Write-Host "      /um-plan" -ForegroundColor Cyan
    Write-Host "    Note: um-* skill bodies are served by the u-maker terminal app - keep it running." -ForegroundColor White
    Write-Host ""

} catch {
    Write-Host ""
    Write-Host "  Installation failed: $_" -ForegroundColor Red
    Write-Host "  Try manual install:" -ForegroundColor Yellow
    Write-Host "    1. Download: https://github.com/$repo/releases" -ForegroundColor Yellow
    Write-Host "    2. Extract zip -> run deploy_local.bat" -ForegroundColor Yellow
    Write-Host ""
} finally {
    if (Test-Path $tmp) { Remove-Item -Recurse -Force $tmp -ErrorAction SilentlyContinue }
    Remove-Item Env:UMAKER_VERSION   -ErrorAction SilentlyContinue
    Remove-Item Env:UMAKER_UNINSTALL -ErrorAction SilentlyContinue
}
