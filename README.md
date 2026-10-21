# PHP 5.4.16-48.el7 security backport (RC1)



Uncertified source-level candidate for CVE-2026-109618 and CVE-2026-109619. 

Not an official Red Hat update.

&#x20;Not a binary RPM. 

Do not deploy to production without building, Apache/mod\_php testing, rollback verification, and security approval.



This was made by reverse engineering the PHP 7.4 backport for PHP 5.4. 



The problem:



* **CVE-2026-109618** — out-of-memory handling can leave request data half
initialised, and request shutdown then runs over it.
* **CVE-2026-109619** — request-owned state (freed request strings, error and
exception handlers, session upload-progress) can survive into the next
request on the same worker.

The changes are ported from PHP's own 7.4 emergency backport and adapted to the
Zend Engine 2 / 5.4 tree. This is a candidate, not a finished vendor update:
it has not been built into an RPM here, not tested under Apache mod\_php, and
not security-reviewed by anyone but me. 



USE AT YOUR OWN RISK

---



## Layout

* `patches/01…06-\*.patch` — the six changes, in the order the spec applies them.
* `patches/\*COMBINED.patch` — the same six changes as one diff, for applying
directly to an already Red Hat-patched 5.4.16-48 tree. Use either this or the
six split patches, never both.
* `rpm/php.spec` — the stock `-48` spec with the six patches added as
Patch200–205 and a `.securityrc1` release suffix.
* `rpm/SPEC\_INTEGRATION.diff` — exactly what changed in the spec.
* `rpm/build-rc.sh` — builds the RPMs on a RHEL 7 host.
* `tests/release-gate/` — build and Apache-staging checks, plus a temporary
loopback-only probe for reading the effective mod\_php settings.
* `docs/` — install notes and current status.

## Building

Try on an isolated RHEL 7 (or compatible) VM, not on anything that matters.

1. Get the original `php-5.4.16-48.el7.src.rpm` from your RHEL subscription. It
is deliberately not committed here — it's Red Hat's to distribute, not mine.
2. Install `rpm-build` and the 5.4 build dependencies, with your repos set up.
3. From the repo root:

```bash
   sha256sum -c SHA256SUMS
   bash build-from-repo.sh /absolute/path/to/php-5.4.16-48.el7.src.rpm
   ```

The wrapper copies the six split patches next to the spec and hands off to
`rpm/build-rc.sh`, which runs `rpmbuild -bp`, `-bs` and `-ba`. It does not copy
the combined patch, so there's no way to apply both by accident. None of this
has been run here — it needs a real RHEL 7 build environment.

## Test it! Test it! Test it!!!!!

See `tests/release-gate/RELEASE\_GATE.md`. The short version: build the RPMs,
install them on a staging host that matches production, and confirm the new
behaviour under **Apache mod\_php** — that's the SAPI the advisory calls the
highest risk, and it's the one I could not test here. Read the effective ini
values from mod\_php itself with the included probe, not from `php -i`, which
only shows the CLI. Remove the probe the moment you're done.

## Tested

I tested the patched source on a local CLI/CGI/FPM build of the 5.4.16-48 tree:
all 101 patches (Red Hat's 95 plus these 6) apply in spec order with no
rejects, it compiles and links, the regression suite passes (7,853 pass, 113
pre-existing/expected failures — the session upload-progress tests, which the
patch disables, and a few OOM tests whose message now goes to stderr), and the
targeted cases behave correctly: OOM fails closed without running shutdown, the
allocator overflow path is rerouted, the multipart part cap works, a part
stuffed with 300k junk headers that OOMs the stock build is handled cleanly
here, freed request strings are nulled, and executor error/exception state is
reset between requests.



TO DO:

---

The actual RPM build, Apache mod\_php testing, package signing, a
rollback test, and an independent security review. All of those have to happen
before this goes anywhere near production.



## Scope

This is NOT a complete fix or as vendor-certified — it's a legacy
backport, and RHEL 7 itself is past normal support. Where you can, the real
answer is moving off PHP 5.4 and RHEL 7 onto something still maintained. 


