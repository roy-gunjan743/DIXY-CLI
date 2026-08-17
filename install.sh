#!/usr/bin/env bash
set -euo pipefail

# DIXY public distribution installer
# Source repository:  roy-gunjan743/DIXY
# Public releases:   roy-gunjan743/DIXY-CLI

REPO="roy-gunjan743/DIXY-CLI"
INSTALL_DIR="${DIXY_INSTALL_DIR:-$HOME/.dixy}"
VERSION="${DIXY_VERSION:-latest}"

need() {
    command -v "$1" >/dev/null 2>&1 || {
        echo "[ERROR] '$1' is required but was not found on PATH."
        exit 1
    }
}

need curl
need java

JAVA_VERSION="$(java -version 2>&1 | awk -F '"' '/version/ {print $2; exit}')"
echo "[dixy-install] Java detected: ${JAVA_VERSION:-unknown}"

mkdir -p "$INSTALL_DIR"

if [ "$VERSION" = "latest" ]; then
    BASE_URL="https://github.com/$REPO/releases/latest/download"
else
    BASE_URL="https://github.com/$REPO/releases/download/$VERSION"
fi

download() {
    local name="$1"
    echo "[dixy-install] Downloading $name..."
    curl -fL --retry 3 --retry-delay 2 \
        "$BASE_URL/$name" \
        -o "$INSTALL_DIR/$name"
}

echo "[dixy-install] Installing DIXY ${VERSION}..."
echo "[dixy-install] Target directory: $INSTALL_DIR"

download "dixy-agent.jar"
download "dixy-cli.jar"
download "dixy.sh"

chmod +x "$INSTALL_DIR/dixy.sh"

# Expose a global `dixy` command for Unix-like systems.
BIN_DIR="$HOME/.local/bin"
mkdir -p "$BIN_DIR"
ln -sf "$INSTALL_DIR/dixy.sh" "$BIN_DIR/dixy"

echo
echo "[dixy-install] DIXY installed successfully."
echo "[dixy-install] Location: $INSTALL_DIR"

case ":${PATH}:" in
    *":$BIN_DIR:"*)
        echo "[dixy-install] Command available: dixy"
        ;;
    *)
        echo "[dixy-install] Add this directory to PATH:"
        echo "    export PATH=\"\$HOME/.local/bin:\$PATH\""
        echo
        echo "[dixy-install] Then open a new terminal."
        ;;
esac

echo
echo "[dixy-install] Usage:"
echo "    dixy path/to/your-application.jar"
echo
echo "[dixy-install] To install a specific release:"
echo "    DIXY_VERSION=v6.8.0 curl -fsSL https://raw.githubusercontent.com/roy-gunjan743/DIXY-CLI/main/install.sh | bash"