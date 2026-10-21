# PHP 5.4 RHEL7 adapt6 RC1 — release gate

## What this is
Read-only verification and staging inventory scripts for the existing six-patch source kit. It is **not** a new source patch, a compiled RPM, a signed package, or a certification of CVE remediation.

## Verified here
- The original source kit's `SHA256SUMS` validates all six patches, php.spec, and build-rc.sh.
- `bash -n` passes on the original build script and the two scripts in this package.
- `php.spec` declares Patch200–205 and applies them in numeric order.
- No RPM binary has been built in this environment.

## Build host workflow
1. In an isolated authorized RHEL7-compatible build environment, install all build dependencies and `rpm-build`.
2. Place `php-5.4.16-48.el7.src.rpm` alongside the previously delivered `PHP54_RHEL48_adapt6_RPM_SOURCE_KIT.zip` extracted contents.
3. Run `bash build-rc.sh /absolute/path/php-5.4.16-48.el7.src.rpm 2>&1 | tee rc1-build.log` from the extracted source-kit directory.
4. Run `bash verify-build.sh 2>&1 | tee rc1-package-verification.log` from this release-gate directory.
5. Preserve `rc1-build.log`, the full package list, SHA-256 digests, source RPM, and binary RPMs. Review `rpm -K` results; unsigned packages must not be presented as signed.

## Staging gate
- On a non-production host with the same Apache MPM, modules, extensions and configuration as production, install the **full matching RPM set** in a reversible snapshot.
- Run `bash staging-checks.sh > rc1-staging-inventory.log 2>&1`.
- Confirm Apache uses actual mod_php rather than PHP-FPM before claiming mod_php coverage.
- Exercise multipart upload, duplicate/folded headers, large junk-header input, `max_multipart_body_parts` default/0/2, repeated requests on the same worker, and safe OOM cases. Use only authorized test fixtures; don't run adversarial inputs against production.
- Compare results with the prepatch reference; inspect error logs, process restarts and crashes.
- Obtain independent source review and documented rollback approval.

## Release decision
NO-GO until binary build, Apache mod_php tests, signature checks, staged rollback, and independent security sign-off are complete. Reported Claude tests cover CLI/CGI/FPM, not production Apache mod_php.

## Handoff
DONE: Source kit hash check; Bash syntax checks; verification and staging scripts created.
PARTIAL: Source patch testing is reported by Claude, not reproduced here.
OPEN: RPM build; mod_php runtime tests; signature verification; staged rollback; security sign-off.
NEXT: Build on authorized RHEL7-compatible host and attach build and staging logs.
ADD: verify-build.sh, staging-checks.sh, RELEASE_GATE.md.
REPLACE: None. DELETE: None. Keep frozen adapt6 patch sources unchanged.

## V2 correction: verify effective mod_php settings (mandatory)
`php -i` reports **CLI**, not Apache configuration. `staging-checks.sh` now **fails closed** if the Apache runtime probe is missing, inaccessible, or does not return `sapi=apache2handler` and all three required settings. The CLI values are printed only for comparison, not accepted as mod_php evidence.

On an **isolated staging host only**, manually place `modphp-runtime-probe.php` in an Apache-served directory and restrict access using Apache 2.4 configuration, for example:

```apache
<Files "modphp-runtime-probe.php">
    Require local
</Files>
```

Confirm that the endpoint is accessible only via loopback and that it is served by the intended Apache virtual host. If multiple virtual hosts exist, arrange a dedicated localhost-bound staging vhost; do not point this check at production. Then run, using the correct staging port and path:

```bash
MODPHP_PROBE_URL=http://127.0.0.1:80/modphp-runtime-probe.php bash staging-checks.sh \
  > rc1-staging-inventory.log 2>&1
```

The probe additionally rejects non-loopback `REMOTE_ADDR` in PHP. The script uses a **localhost HTTP GET** via `curl` (no external network access or server modifications). It verifies SAPI, version family, and the presence/type of the effective `memory_limit`, `max_multipart_body_parts`, and `session.upload_progress.enabled` values. The operator must check those values against approved settings and confirm the installed RPM release separately. A passing probe does **not** prove the security behavior under Apache or constitute release approval.

**Immediately remove the temporary PHP probe** from the web root after the check, verify it returns HTTP 404, and remove its dedicated Apache access rule. Do not leave a public `phpinfo()` page or this probe deployed.

### V2 manifest
- **REPLACE:** `staging-checks.sh`, `RELEASE_GATE.md`
- **ADD:** `modphp-runtime-probe.php`
- **UNCHANGED:** `verify-build.sh`; all six RC1 source patches, `php.spec`, and `build-rc.sh`
- **DELETE after staging:** deployed copy of `modphp-runtime-probe.php` and its temporary Apache rule
