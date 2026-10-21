#!/usr/bin/env bash
set -euo pipefail
# Read-only validation of built packages. Run after build-rc.sh on the build host.
TOP="${RPM_TOPDIR:-$HOME/rpmbuild}"
command -v rpm >/dev/null
command -v rpmbuild >/dev/null
printf 'Build host: '; uname -a
printf 'RPM version: '; rpm --version
printf 'RPM build version: '; rpmbuild --version
find "$TOP/RPMS" "$TOP/SRPMS" -type f -name '*.rpm' -print | sort | tee package-files.txt
if [[ ! -s package-files.txt ]]; then echo 'ERROR: No RPM artifacts' >&2; exit 1; fi
while IFS= read -r f; do
  echo "=== $f ==="
  rpm -qp --qf 'NAME=%{NAME} VERSION=%{VERSION} RELEASE=%{RELEASE} ARCH=%{ARCH}\n' "$f"
  rpm -K "$f" || true
  sha256sum "$f"
done < package-files.txt | tee package-report.txt
if ! grep -q 'securityrc1' package-report.txt; then echo 'ERROR: Candidate release suffix not found' >&2; exit 1; fi
echo 'NOTE: rpm -K output is informational. Signature verification must be enforced separately.'
