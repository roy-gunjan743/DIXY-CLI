$existingCli = Join-Path $InstallDir "dixy-cli.jar"
$existingAgent = Join-Path $InstallDir "dixy-agent.jar"
$existingBat = Join-Path $InstallDir "dixy.bat"

if (
    (Test-Path $existingCli) -and
    (Test-Path $existingAgent) -and
    (Test-Path $existingBat)
) {
    Write-Host ""
    Write-Host "[DIXY] Existing installation detected." -ForegroundColor Yellow
    Write-Host "[DIXY] Location: $InstallDir"
    Write-Host ""

    # Make sure PATH is still configured
    $userPath = [Environment]::GetEnvironmentVariable("Path", "User")

    if ($userPath -notlike "*$InstallDir*") {
        [Environment]::SetEnvironmentVariable(
            "Path",
            "$userPath;$InstallDir",
            "User"
        )

        Write-Host "[DIXY] PATH configuration restored."
    }

    Write-Host "[DIXY] DIXY is already installed."
    Write-Host ""

    exit 0
}
$ErrorActionPreference = "Stop"

# ============================================================
# DIXY Windows Installer
# ============================================================

$Repo = "roy-gunjan743/DIXY-CLI"

$InstallDir = if ($env:DIXY_INSTALL_DIR) {
    $env:DIXY_INSTALL_DIR
} else {
    Join-Path $env:USERPROFILE ".dixy"
}

$Version = if ($env:DIXY_VERSION) {
    $env:DIXY_VERSION
} else {
    "latest"
}

Write-Host ""
Write-Host "========================================"
Write-Host "          DIXY CLI INSTALLER"
Write-Host "========================================"
Write-Host ""

# ============================================================
# Check Java
# ============================================================

Write-Host "[DIXY] Checking Java..."

$javaCommand = Get-Command java.exe -ErrorAction SilentlyContinue

if (-not $javaCommand) {
    Write-Host ""
    Write-Host "[ERROR] Java was not found on PATH." -ForegroundColor Red
    Write-Host ""
    Write-Host "Please install Java 21+ and restart PowerShell."
    Write-Host ""
    exit 1
}

Write-Host "[DIXY] Java found: $($javaCommand.Source)"

# Do NOT parse java -version.
# Simply verify that Java can actually start.

$javaProcess = Start-Process `
    -FilePath $javaCommand.Source `
    -ArgumentList "-version" `
    -NoNewWindow `
    -Wait `
    -PassThru

if ($javaProcess.ExitCode -ne 0) {
    Write-Host ""
    Write-Host "[ERROR] Java was found but could not be executed." -ForegroundColor Red
    Write-Host ""
    exit 1
}

Write-Host "[DIXY] Java is working."

# ============================================================
# Create installation directory
# ============================================================

Write-Host "[DIXY] Installation directory: $InstallDir"

New-Item `
    -ItemType Directory `
    -Force `
    -Path $InstallDir | Out-Null

# ============================================================
# Release URL
# ============================================================

if ($Version -eq "latest") {
    $BaseUrl = "https://github.com/$Repo/releases/latest/download"
} else {
    $BaseUrl = "https://github.com/$Repo/releases/download/$Version"
}

# ============================================================
# Download function
# ============================================================

function Download-Asset([string]$Name) {

    $url = "$BaseUrl/$Name"
    $destination = Join-Path $InstallDir $Name

    Write-Host ""
    Write-Host "[DIXY] Downloading $Name..."

    try {

        Invoke-WebRequest `
            -Uri $url `
            -OutFile $destination `
            -UseBasicParsing

    }
    catch {

        Write-Host ""
        Write-Host "[ERROR] Failed to download $Name" -ForegroundColor Red
        Write-Host "[ERROR] URL: $url" -ForegroundColor Red
        Write-Host ""
        Write-Host $_.Exception.Message

        throw
    }

    if (-not (Test-Path $destination)) {
        throw "[ERROR] Download completed but $Name was not found."
    }

    Write-Host "[DIXY] Downloaded: $Name"
}

# ============================================================
# Download DIXY
# ============================================================

Write-Host ""
Write-Host "[DIXY] Installing DIXY $Version..."

Download-Asset "dixy-agent.jar"
Download-Asset "dixy-cli.jar"
Download-Asset "dixy.bat"

# ============================================================
# Configure PATH
# ============================================================

Write-Host ""
Write-Host "[DIXY] Configuring PATH..."

$userPath = [Environment]::GetEnvironmentVariable(
    "Path",
    "User"
)

$pathEntries = @()

if ($userPath) {

    $pathEntries = $userPath `
        -split ';' `
        | Where-Object {
            $_ -and $_.Trim()
        }
}

$alreadyPresent = $pathEntries | Where-Object {

    [string]::Equals(
        $_.TrimEnd('\'),
        $InstallDir.TrimEnd('\'),
        [System.StringComparison]::OrdinalIgnoreCase
    )
}

if (-not $alreadyPresent) {

    $newUserPath = (
        ($pathEntries + $InstallDir) -join ';'
    )

    [Environment]::SetEnvironmentVariable(
        "Path",
        $newUserPath,
        "User"
    )

    Write-Host "[DIXY] Added $InstallDir to user PATH."

}
else {

    Write-Host "[DIXY] DIXY is already in PATH."

}

# ============================================================
# Refresh current PowerShell PATH
# ============================================================

$machinePath = [Environment]::GetEnvironmentVariable(
    "Path",
    "Machine"
)

$currentUserPath = [Environment]::GetEnvironmentVariable(
    "Path",
    "User"
)

$env:Path = "$currentUserPath;$machinePath"

# ============================================================
# Verify installation
# ============================================================

Write-Host ""
Write-Host "[DIXY] Verifying installation..."

$requiredFiles = @(
    "dixy-agent.jar",
    "dixy-cli.jar",
    "dixy.bat"
)

foreach ($file in $requiredFiles) {

    $filePath = Join-Path $InstallDir $file

    if (-not (Test-Path $filePath)) {

        throw "[ERROR] Installation verification failed: $file"

    }

    Write-Host "[DIXY] OK: $file"
}

# ============================================================
# Success
# ============================================================

Write-Host ""
Write-Host "========================================"
Write-Host "       DIXY INSTALLED SUCCESSFULLY"
Write-Host "========================================"
Write-Host ""

Write-Host "Location:"
Write-Host "  $InstallDir"

Write-Host ""
Write-Host "You can now run:"
Write-Host ""

Write-Host "  dixy"

Write-Host ""

Write-Host "Or:"
Write-Host ""

Write-Host "  dixy path\to\your-application.jar"

Write-Host ""