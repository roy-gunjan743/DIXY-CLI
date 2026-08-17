@echo off
setlocal EnableExtensions EnableDelayedExpansion

rem DIXY public distribution installer
rem Source repository:  roy-gunjan743/DIXY
rem Public releases:   roy-gunjan743/DIXY-CLI

set "REPO=roy-gunjan743/DIXY-CLI"

if "%DIXY_INSTALL_DIR%"=="" (
    set "INSTALL_DIR=%USERPROFILE%\.dixy"
) else (
    set "INSTALL_DIR=%DIXY_INSTALL_DIR%"
)

if "%DIXY_VERSION%"=="" (
    set "VERSION=latest"
) else (
    set "VERSION=%DIXY_VERSION%"
)

where curl.exe >nul 2>&1
if errorlevel 1 (
    echo [ERROR] curl.exe is required. Windows 10/11 normally includes it.
    exit /b 1
)

where java.exe >nul 2>&1
if errorlevel 1 (
    echo [ERROR] Java is required and was not found on PATH.
    echo [ERROR] Install Java 21 or newer, then run this installer again.
    exit /b 1
)

if /I "%VERSION%"=="latest" (
    set "BASE_URL=https://github.com/%REPO%/releases/latest/download"
) else (
    set "BASE_URL=https://github.com/%REPO%/releases/download/%VERSION%"
)

echo [dixy-install] Installing DIXY %VERSION%...
echo [dixy-install] Target directory: %INSTALL_DIR%

if not exist "%INSTALL_DIR%" mkdir "%INSTALL_DIR%"
if errorlevel 1 (
    echo [ERROR] Could not create %INSTALL_DIR%
    exit /b 1
)

call :download "dixy-agent.jar"
if errorlevel 1 exit /b 1

call :download "dixy-cli.jar"
if errorlevel 1 exit /b 1

call :download "dixy.bat"
if errorlevel 1 exit /b 1

rem Add install directory to the current user's PATH if it is not already there.
powershell.exe -NoProfile -ExecutionPolicy Bypass -Command ^
  "$dir=[IO.Path]::GetFullPath('%INSTALL_DIR%');" ^
  "$p=[Environment]::GetEnvironmentVariable('Path','User');" ^
  "$items=@(); if($p){$items=$p -split ';' | ? {$_ -and $_.Trim()}};" ^
  "$exists=$items | ? {[string]::Equals($_.TrimEnd('\'),$dir.TrimEnd('\'),[StringComparison]::OrdinalIgnoreCase)};" ^
  "if(-not $exists){[Environment]::SetEnvironmentVariable('Path', (($items+$dir)-join ';'),'User'); Write-Host '[dixy-install] Added DIXY to user PATH.'} else {Write-Host '[dixy-install] DIXY is already in user PATH.'}"

echo.
echo [dixy-install] DIXY installed successfully.
echo [dixy-install] Location: %INSTALL_DIR%
echo.
echo [dixy-install] IMPORTANT: Open a NEW terminal before using "dixy".
echo [dixy-install] Usage:
echo     dixy.bat path\to\your-application.jar
goto :eof

:download
set "NAME=%~1"
echo [dixy-install] Downloading %NAME%...
curl.exe -fL --retry 3 --retry-delay 2 "%BASE_URL%/%NAME%" -o "%INSTALL_DIR%\%NAME%"
if errorlevel 1 (
    echo [ERROR] Failed to download %NAME%.
    exit /b 1
)
exit /b 0
