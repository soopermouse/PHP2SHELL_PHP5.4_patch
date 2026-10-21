#!/bin/bash
set -euo pipefail
# Run on an authorized, isolated RHEL7-compatible RPM build host with rpmbuild installed.
# Supply the original php-5.4.16-48.el7.src.rpm as the first argument.
SRPM="${1:?Usage: ./build-rc.sh /path/to/php-5.4.16-48.el7.src.rpm}"
HERE="$(cd "$(dirname "$0")" && pwd)"
command -v rpmbuild >/dev/null || { echo 'rpmbuild missing'; exit 1; }
command -v rpm >/dev/null || { echo 'rpm missing'; exit 1; }
TOP="${RPM_TOPDIR:-$HOME/rpmbuild}"
mkdir -p "$TOP"/{SPECS,SOURCES,BUILD,BUILDROOT,RPMS,SRPMS}
rpm -ivh --define "_topdir $TOP" "$SRPM"
cp "$HERE/php.spec" "$TOP/SPECS/php.spec"
for patch in "$HERE"/*.patch; do cp "$patch" "$TOP/SOURCES/"; done
rpmbuild -bp --define "_topdir $TOP" "$TOP/SPECS/php.spec"
rpmbuild -bs --define "_topdir $TOP" "$TOP/SPECS/php.spec"
rpmbuild -ba --define "_topdir $TOP" "$TOP/SPECS/php.spec"
echo "Build artifacts: $TOP/SRPMS and $TOP/RPMS"
