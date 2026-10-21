# PHP 5.4.16-48.el7 security backport — RC1

**Uncertified source-level candidate for CVE-2026-109618 and CVE-2026-109619.** Not an official Red Hat update. Not a binary RPM. **Do not deploy to production without building, Apache/mod_php testing, rollback verification, and security approval.**

## What is in this repository?

- `patches/01-...` through `06-...`: the six tested source increments, in RPM application order.
- `patches/*COMBINED.patch`: equivalent single patch **for an already Red Hat-patched** PHP 5.4.16-48.el7 source tree. **Do not apply this alongside the six individual patches.**
- `rpm/php.spec`: original `-48` spec with Patch200–205 integration and `.securityrc1` release suffix.
- `rpm/build-rc.sh`: build script for an isolated RHEL 7-compatible host.
- `rpm/SPEC_INTEGRATION.diff`: changes to the vendor spec.
- `tests/release-gate/`: build and Apache staging checks, including a **temporary, localhost-only** mod_php probe.
- `docs/`: installation and release status.

## Build RPMs on an isolated RHEL 7-compatible VM

1. Obtain the original `php-5.4.16-48.el7.src.rpm` from an authorized source. **The original source RPM is deliberately not redistributed in this Git repository.**
2. Install `rpm-build` and the required RHEL 7 build dependencies and make sure repositories/subscriptions are configured.
3. Clone this repository and run:

```bash
cd php54-rhel7-security-backport
sha256sum -c SHA256SUMS
bash build-from-repo.sh /absolute/path/to/php-5.4.16-48.el7.src.rpm
```

The repository wrapper copies the six individual patches next to the unchanged RPM build script. It does **not** copy the combined patch. `build-rc.sh` invokes `rpmbuild -bp`, `-bs`, and `-ba` and requires a working RHEL 7 build environment. It has **not** been run in this ChatGPT environment.

**Important:** the commands above copy patches into `rpm/`; `.gitignore` excludes those temporary copies to keep the repository clean.

## Verify Apache staging

See `tests/release-gate/RELEASE_GATE.md`. The probe must be protected at the Apache layer (`Require local`), accessed only through loopback, and removed immediately after testing. CLI `php -i` is not proof of Apache mod_php configuration.

## Evidence and remaining work

External testing reported: all 101 patches apply in spec order; patched source matches the tested adapt6 tree; CLI/CGI/FPM compile; 7,853 passing regression tests with 113 accounted-for failures; targeted OOM, multipart, and request-state tests pass. These results were **reported by the external tester**, not reproduced by this repository's CI.

**DONE:** Source patch series, combined patch, RPM spec integration, release-gate scripts.  
**OPEN:** Actual RPM binary build, Apache mod_php security tests, RPM signing, rollback test, independent security audit and approval.  
**NEXT:** Build on a matching isolated RHEL 7 host, validate staging, then make a GO/NO-GO decision.

## Safety

Do not publish a claim that both CVEs are fully remediated or that the update is vendor-certified. This repository is a candidate backport for legacy PHP; Red Hat Enterprise Linux 7 is beyond ordinary maintenance. Prefer migration to a supported PHP/platform where feasible.
