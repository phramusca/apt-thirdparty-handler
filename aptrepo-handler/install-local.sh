#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)"
LOCAL_BIN_DIR="${HOME}/.local/bin"
LOCAL_APPS_DIR="${HOME}/.local/share/applications"
SYSTEM_CONFIG_DIR="/etc/aptrepo-handler/apps.d"

echo "Installing aptrepo-handler locally..."

mkdir -p "$LOCAL_BIN_DIR" "$LOCAL_APPS_DIR"

install -m 0755 "${SCRIPT_DIR}/usr/bin/aptrepo-handler" "${LOCAL_BIN_DIR}/aptrepo-handler"

cp "${SCRIPT_DIR}/usr/share/applications/aptrepo-handler.desktop" "${LOCAL_APPS_DIR}/aptrepo-handler.desktop"

if command -v sed >/dev/null 2>&1; then
  sed -i "s|^Exec=.*|Exec=${LOCAL_BIN_DIR}/aptrepo-handler %u|" "${LOCAL_APPS_DIR}/aptrepo-handler.desktop"
fi

echo "Copying system configs (sudo required)..."
sudo mkdir -p "$SYSTEM_CONFIG_DIR"
sudo install -m 0644 "${SCRIPT_DIR}/etc/aptrepo-handler/apps.d/"*.conf "$SYSTEM_CONFIG_DIR/"

xdg-mime default aptrepo-handler.desktop x-scheme-handler/aptrepo
update-desktop-database "${LOCAL_APPS_DIR}" >/dev/null 2>&1 || true

echo
echo "Done. Handler registered."
echo "Test with: xdg-open 'aptrepo://bruno'"

