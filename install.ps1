$ErrorActionPreference = "Stop"

# DIXY public distribution installer
# Source repository:  roy-gunjan743/DIXY
# Public releases:   roy-gunjan743/DIXY-CLI

$Repo = "roy-gunjan743/DIXY-CLI"
$InstallDir = if ($env:DIXY_INSTALL_DIR) {
    $env:DIXY_INSTALL_DIR
} else {
    Join-Path $env:USERPROFILE ".dixy"
}
$Version = if ($env:DIXY_VERSION) { $env:DIXY_VERSION } else { "latest" }

function Assert-Command([string]$Name) {
    if (-not (Get-Command $Name -ErrorAction SilentlyContinue)) {
        throw "[ERROR] '$Name' is required but was not found on PATH."
    }
}

Assert-Command "java"
Assert-Command "curl"

$javaVersion = (& cmd.exe /c "java -version 2>&1" | Select-String 'version' | Select-Object -First 1).ToString()
Write-Host "[dixy-install] Java detected: $javaVersion"

New-Item -ItemType Directory -Force -Path $InstallDir | Out-Null

if ($Version -eq "latest") {
    $BaseUrl = "https://github.com/$Repo/releases/latest/download"
} else {
    $BaseUrl = "https://github.com/$Repo/releases/download/$Version"
}

function Download-Asset([string]$Name) {
    $url = "$BaseUrl/$Name"
    $destination = Join-Path $InstallDir $Name

    Write-Host "[dixy-install] Downloading $Name..."
    & curl.exe -fL --retry 3 --retry-delay 2 $url -o $destination

    if ($LASTEXITCODE -ne 0) {
        throw "[ERROR] Failed to download $Name from $url"
    }
}

Write-Host "[dixy-install] Installing DIXY $Version..."
Write-Host "[dixy-install] Target directory: $InstallDir"

Download-Asset "dixy-agent.jar"
Download-Asset "dixy-cli.jar"
Download-Asset "dixy.bat"

# Add the DIXY directory to the current user's PATH.
$userPath = [Environment]::GetEnvironmentVariable("Path", "User")
$pathEntries = @()
if ($userPath) {
    $pathEntries = $userPath -split ';' | Where-Object { $_ -and $_.Trim() }
}

$alreadyPresent = $pathEntries | Where-Object {
    [string]::Equals($_.TrimEnd('\'), $InstallDir.TrimEnd('\'), [System.StringComparison]::OrdinalIgnoreCase)
}

if (-not $alreadyPresent) {
    $newUserPath = (($pathEntries + $InstallDir) -join ';')
    [Environment]::SetEnvironmentVariable("Path", $newUserPath, "User")
    Write-Host "[dixy-install] Added $InstallDir to your user PATH."
    Write-Host "[dixy-install] Open a NEW PowerShell/Command Prompt window before using 'dixy'."
}

Write-Host ""
Write-Host "[dixy-install] DIXY installed successfully."
Write-Host "[dixy-install] Location: $InstallDir"
Write-Host ""
Write-Host "[dixy-install] Usage:"
Write-Host "    dixy.bat path\to\your-application.jar"
Write-Host ""
Write-Host "[dixy-install] To install a specific release:"
Write-Host "    `$env:DIXY_VERSION='v6.8.0'; irm https://raw.githubusercontent.com/roy-gunjan743/DIXY-CLI/main/install.ps1 | iex"

