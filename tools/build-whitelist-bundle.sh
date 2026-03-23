#!/usr/bin/env bash
set -euo pipefail

if [ $# -lt 2 ] || [ $# -gt 3 ]; then
  echo "Usage: $0 <apps.d-dir> <gpg-key-id-or-email> [output-dir]" >&2
  exit 1
fi

APPS_DIR="$1"
SIGNING_KEY="$2"
OUT_DIR="${3:-.}"

[ -d "$APPS_DIR" ] || {
  echo "Error: apps directory not found: $APPS_DIR" >&2
  exit 1
}

mkdir -p "$OUT_DIR"
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

mkdir -p "$TMP_DIR/apps.d"
cp "$APPS_DIR"/*.conf "$TMP_DIR/apps.d"/

ARCHIVE="$OUT_DIR/apps.tar"
SIG="$OUT_DIR/apps.tar.asc"

tar -cf "$ARCHIVE" -C "$TMP_DIR" apps.d
gpg --armor --detach-sign --local-user "$SIGNING_KEY" --output "$SIG" "$ARCHIVE"

echo "Created:"
echo "  $ARCHIVE"
echo "  $SIG"
