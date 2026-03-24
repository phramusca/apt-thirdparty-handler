#!/usr/bin/env bash
# Builds the apt-thirdparty-handler .deb package from repository root.
set -euo pipefail

VERSION="${1:-1.0}"
SCRIPT_DIR="$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)"
PACKAGE_DIR="${SCRIPT_DIR}/aptrepo-handler"

chmod 755 "${PACKAGE_DIR}/usr/bin/apt-thirdparty-handler"
chmod 644 "${PACKAGE_DIR}/usr/share/applications/apt-thirdparty-handler.desktop"
chmod 755 "${PACKAGE_DIR}/DEBIAN/postinst"
chmod 755 "${PACKAGE_DIR}/DEBIAN/prerm"

command -v fakeroot >/dev/null 2>&1 || {
  echo "Error: fakeroot is required (sudo apt install fakeroot)." >&2
  exit 1
}

sed -i "s/^Version:.*/Version: ${VERSION}/" "${PACKAGE_DIR}/DEBIAN/control"

package_name="$(awk -F': ' '/^Package:/ { print $2 }' "${PACKAGE_DIR}/DEBIAN/control")"
package_version="$(awk -F': ' '/^Version:/ { print $2 }' "${PACKAGE_DIR}/DEBIAN/control")"
output_file="${SCRIPT_DIR}/${package_name}_${package_version}_all.deb"

fakeroot dpkg-deb --root-owner-group --build "${PACKAGE_DIR}" "$output_file"
echo "Package built: $output_file"
