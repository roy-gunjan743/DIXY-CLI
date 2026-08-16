@echo off
setlocal enabledelayedexpansion
rem ─────────────────────────────────────────────────────────────────
rem  DIXY installer (Windows) — fetches only the prebuilt release
rem  artifacts (dixy-agent.jar, dixy-cli.jar, dixy.bat) from a
rem  GitHub Release. Never clones the repo, never touches source.
rem
rem  Usage (PowerShell):
rem    irm https://raw.githubusercontent.com/roy-gunjan743/DIXY/main/install.bat -OutFile install.bat; .\install.bat
rem
rem  Or download install.bat manually and double-click it.
rem
rem  Optional env vars:
rem    set DIXY_INSTALL_DIR=C:\tools\dixy
rem    set DIXY_VERSION=v1.2.0
rem ─────────────────────────────────────────────────────────────────

set "REPO=roy-gunjan743/DIXY"
if "%DIXY_INSTALL_DIR%"=="" (set "INSTALL_DIR=%USERPROFILE%\.dixy") else (set "INSTALL_DIR=%DIXY_INSTALL_DIR%")
if "%DIXY_VERSION%"=="" (set "VERSION=latest") else (set "VERSION=%DIXY_VERSION%")

where curl >nul 2>&1
if errorlevel 1 (
    echo [ERROR] curl is required. Windows 10+ ships it by default - update Windows if missing.
    exit /b 1
)
where java >nul 2>&1
if errorlevel 1 (
    echo [ERROR] java is required and was not found on PATH.
    exit /b 1
)

echo [dixy-install] Target directory: %INSTALL_DIR%
if not exist "%INSTALL_DIR%" mkdir "%INSTALL_DIR%"

if /i "%VERSION%"=="latest" (
    set "RELEASE_URL=https://api.github.com/repos/%REPO%/releases/latest"
) else (
    set "RELEASE_URL=https://api.github.com/repos/%REPO%/releases/tags/%VERSION%"
)

echo [dixy-install] Resolving release (%VERSION%)...
curl -fsSL "%RELEASE_URL%" -o "%TEMP%\dixy_release.json"
if errorlevel 1 (
    echo [ERROR] Could not reach %RELEASE_URL% - check the version/tag or your network.
    exit /b 1
)

rem ---- extract each asset's download URL and fetch it ----------------
rem Assets fetched: dixy-agent.jar, dixy-cli.jar, dixy.bat
rem (No "Source code (zip)" asset is ever requested here.)

for %%A in (dixy-agent.jar dixy-cli.jar dixy.bat) do (
    call :download_asset %%A
    if errorlevel 1 exit /b 1
)

echo.
echo [dixy-install] Done. Installed to: %INSTALL_DIR%
echo [dixy-install] Add this folder to your PATH, or run it directly:
echo     %INSTALL_DIR%\dixy.bat
goto :eof

:download_asset
set "ASSET_NAME=%~1"
set "ASSET_URL="
for /f "usebackq tokens=* delims=" %%L in (`findstr /c:"browser_download_url" "%TEMP%\dixy_release.json" ^| findstr /i "%ASSET_NAME%"`) do (
    set "LINE=%%L"
)
if not defined LINE (
    echo [ERROR] Release has no asset named "%ASSET_NAME%".
    exit /b 1
)
rem crude JSON value extraction: grab text between quotes after the colon
for /f "tokens=2 delims=:" %%U in ("!LINE!") do set "RAW=%%U"
set "RAW=!RAW:"=!"
set "ASSET_URL=https!RAW:~1!"
set "ASSET_URL=!ASSET_URL: =!"

echo [dixy-install] Downloading %ASSET_NAME%...
curl -fsSL "!ASSET_URL!" -o "%INSTALL_DIR%\%ASSET_NAME%"
exit /b 0