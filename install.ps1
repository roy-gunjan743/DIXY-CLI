# ─────────────────────────────────────────────────────────────────────
#  DIXY installer (PowerShell) — fetches only the prebuilt release
#  artifacts (dixy-agent.jar, dixy-cli.jar, dixy.bat) from a GitHub
#  Release. Never clones the repo, never touches source.
#
#  Usage:
#    irm https://raw.githubusercontent.com/roy-gunjan743/DIXY/main/install.ps1 | iex
#
#  Optional (set before running):
#    $env:DIXY_INSTALL_DIR = "C:\tools\dixy"
#    $env:DIXY_VERSION     = "v1.2.0"
# ─────────────────────────────────────────────────────────────────────

$ErrorActionPreference = "Stop"

$Repo       = "roy-gunjan743/DIXY"
$InstallDir = if ($env:DIXY_INSTALL_DIR) { $env:DIXY_INSTALL_DIR } else { "$env:USERPROFILE\.dixy" }
$Version    = if ($env:DIXY_VERSION) { $env:DIXY_VERSION } else { "latest" }

function Assert-Command($name) {
    if (-not (Get-Command $name -ErrorAction SilentlyContinue)) {
        Write-Error "[ERROR] '$name' is required but was not found on PATH."
        exit 1
    }
}
Assert-Command java

Write-Host "[dixy-install] Target directory: $InstallDir"
New-Item -ItemType Directory -Force -Path $InstallDir | Out-Null

$releaseUrl = if ($Version -eq "latest") {
    "https://api.github.com/repos/$Repo/releases/latest"
} else {
    "https://api.github.com/repos/$Repo/releases/tags/$Version"
}

Write-Host "[dixy-install] Resolving release ($Version)..."
try {
    $release = Invoke-RestMethod -Uri $releaseUrl -Headers @{ "User-Agent" = "dixy-installer" }
} catch {
    Write-Error "[ERROR] Could not reach $releaseUrl - check the version/tag or your network."
    exit 1
}

Write-Host "[dixy-install] Installing release: $($release.tag_name)"

# Only these three assets are ever requested — GitHub's auto-generated
# "Source code (zip)" link is never touched.
$assetsWanted = @("dixy-agent.jar", "dixy-cli.jar", "dixy.bat")

foreach ($name in $assetsWanted) {
    $asset = $release.assets | Where-Object { $_.name -eq $name }
    if (-not $asset) {
        Write-Error "[ERROR] Release $($release.tag_name) has no asset named '$name'."
        exit 1
    }
    Write-Host "[dixy-install] Downloading $name..."
    Invoke-WebRequest -Uri $asset.browser_download_url -OutFile (Join-Path $InstallDir $name)
}

Write-Host ""
Write-Host "[dixy-install] Done. Installed to: $InstallDir"

# Offer to add to PATH for this user
$userPath = [Environment]::GetEnvironmentVariable("Path", "User")
if ($userPath -notlike "*$InstallDir*") {
    Write-Host "[dixy-install] Add $InstallDir to your PATH to run 'dixy' from anywhere:"
    Write-Host "    [Environment]::SetEnvironmentVariable('Path', `"`$env:Path;$InstallDir`", 'User')"
}
Write-Host "[dixy-install] Run it with: $InstallDir\dixy.bat"