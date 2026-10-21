#!/usr/bin/env bash
set -euo pipefail
# Inventory plus explicit Apache-served PHP runtime verification.
# No configuration changes; the operator must manually deploy/remove the temporary probe.
echo '== Host =='; uname -a
printf '\n== Installed PHP packages ==\n'; rpm -qa | grep -E '^php([^-]|-)' | sort || true
printf '\n== PHP CLI (NOT Apache) ==\n'; php -v || true
printf '\n== Apache build and modules ==\n'; httpd -V || true
httpd -M 2>&1 | grep -E '(mpm_|php|proxy_fcgi)' || true
printf '\n== Apache configuration syntax ==\n'; httpd -t || true
printf '\n== Service status ==\n'; systemctl status httpd --no-pager -l || true
printf '\n== CLI modules ==\n'; php -m || true
printf '\n== CLI settings (NOT Apache) ==\n'; php -i | grep -E '^(Server API|memory_limit|session.upload_progress.enabled|max_multipart_body_parts)' || true

# Do not accept CLI configuration as evidence of mod_php settings.
# Operator-provided URL must target loopback. Probe must be deployed under Apache,
# protected with Require local, and removed immediately after verification.
if [[ -z "${MODPHP_PROBE_URL:-}" ]]; then
  echo 'NO-GO: MODPHP_PROBE_URL not set; Apache PHP runtime not verified.' >&2
  echo 'Set MODPHP_PROBE_URL=http://127.0.0.1:PORT/path/modphp-runtime-probe.php (or localhost).' >&2
  exit 2
fi
if [[ ! "$MODPHP_PROBE_URL" =~ ^http://(127\.0\.0\.1|localhost|\[::1\])(:[0-9]{1,5})?/[A-Za-z0-9_./-]+\.php$ ]]; then
  echo 'NO-GO: probe URL must be plain HTTP, loopback-only, with a .php path and no query string.' >&2
  exit 2
fi
command -v curl >/dev/null || { echo 'NO-GO: curl not installed' >&2; exit 2; }
probe=$(curl --fail --silent --show-error --noproxy '*' --max-time 8 "$MODPHP_PROBE_URL") || {
  echo 'NO-GO: Apache probe request failed.' >&2; exit 2;
}
printf '\n== Apache-served PHP runtime (verified endpoint) ==\n%s\n' "$probe"
get_value() { printf '%s\n' "$probe" | sed -n "s/^$1=//p" | head -n 1; }
sapi=$(get_value sapi)
version=$(get_value php_version)
mem=$(get_value memory_limit)
parts=$(get_value max_multipart_body_parts)
progress=$(get_value 'session\.upload_progress\.enabled')
if [[ "$sapi" != 'apache2handler' ]]; then
  echo "NO-GO: Apache endpoint reports SAPI '$sapi', expected apache2handler." >&2; exit 2
fi
if [[ "$version" != 5.4.16* ]]; then
  echo "NO-GO: unexpected PHP version '$version' (expected 5.4.16-based RHEL package)." >&2; exit 2
fi
if [[ -z "$mem" || -z "$parts" || -z "$progress" ]]; then
  echo 'NO-GO: Apache endpoint did not expose all required directive values.' >&2; exit 2
fi
if ! [[ "$parts" =~ ^-?[0-9]+$ ]]; then
  echo 'NO-GO: max_multipart_body_parts is not an integer.' >&2; exit 2
fi
echo 'PASS: Apache request reports apache2handler and required runtime directives.'
echo 'REVIEW REQUIRED: confirm directive values against approved staging configuration and installed RPM NEVRA.'
echo 'REMOVE THE TEMPORARY PHP PROBE FROM THE APACHE DOCUMENT ROOT NOW.'
