#!/bin/bash
# Builds the aptrepo-handler .deb package
set -e

VERSION="${1:-1.0}"

chmod 755 usr/bin/aptrepo-handler
chmod 644 usr/share/applications/aptrepo-handler.desktop
chmod 755 DEBIAN/postinst
chmod 755 DEBIAN/prerm

command -v fakeroot >/dev/null 2>&1 || { echo "Error: fakeroot is required (sudo apt install fakeroot)." >&2; exit 1; }

sed -i "s/^Version:.*/Version: ${VERSION}/" DEBIAN/control

package_name="$(awk -F': ' '/^Package:/ { print $2 }' DEBIAN/control)"
package_version="$(awk -F': ' '/^Version:/ { print $2 }' DEBIAN/control)"
output_file="./${package_name}_${package_version}_all.deb"

fakeroot dpkg-deb --root-owner-group --build . "$output_file"
echo "Package built: $output_file"
