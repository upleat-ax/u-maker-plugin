# install.ps1 — u-maker plugin installer (Windows PowerShell)
#
# Usage:
#   irm https://raw.githubusercontent.com/upleat-ax/u-maker-plugin/main/install.ps1 | iex
#
# Options (environment variables):
#   $env:UMAKER_VERSION = "3.0.37"   # specific version
#   $env:UMAKER_UNINSTALL = "1"      # uninstall mode

$ErrorActionPreference = "Stop"
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
# Skip certificate revocation check (common issue on corporate networks)
[Net.ServicePointManager]::CheckCertificateRevocationList = $false

$repo = "upleat-ax/u-maker-plugin"
$base = "https://raw.githubusercontent.com/$repo/main"
$tmp  = Join-Path $env:TEMP "u-maker-install-$(Get-Random)"

try {
    New-Item -ItemType Directory -Path $tmp -Force | Out-Null

    Write-Host ""
    Write-Host "  u-maker Plugin Installer" -ForegroundColor Cyan
    Write-Host "  ========================" -ForegroundColor Cyan
    Write-Host ""

    # Download install.bat
    Write-Host "  [..] Downloading installer..." -NoNewline
    $bat = Join-Path $tmp "install.bat"
    Invoke-WebRequest -Uri "$base/install.bat" -OutFile $bat -UseBasicParsing
    Write-Host "`r  [OK] Downloaded            " -ForegroundColor Green

    # Build arguments
    $args_ = @()
    if ($env:UMAKER_VERSION)   { $args_ += "--version", $env:UMAKER_VERSION }
    if ($env:UMAKER_UNINSTALL) { $args_ += "--uninstall" }

    # Run
    & cmd /c "`"$bat`" $($args_ -join ' ')"

} finally {
    # Cleanup
    if (Test-Path $tmp) { Remove-Item -Recurse -Force $tmp -ErrorAction SilentlyContinue }
    Remove-Item Env:UMAKER_VERSION   -ErrorAction SilentlyContinue
    Remove-Item Env:UMAKER_UNINSTALL -ErrorAction SilentlyContinue
}
