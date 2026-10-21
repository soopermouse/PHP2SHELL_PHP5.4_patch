# Release gate

The scripts here check a build of the backport before it's allowed near
production. They don't change anything they inspect — they read package
metadata and the running Apache/PHP configuration and fail if something is
missing. Building the RPMs and testing under mod_php is still on you; these
just stop a half-checked build from being called ready.

## On the build host

1. Build the RPMs on an isolated RHEL 7 box (see the repo README), keeping the
   build log:

   ```bash
   bash build-rc.sh /absolute/path/php-5.4.16-48.el7.src.rpm 2>&1 | tee rc1-build.log
   ```

2. From this directory, check the output packages:

   ```bash
   bash verify-build.sh 2>&1 | tee rc1-package-verification.log
   ```

3. Keep the build log, the package list, the SHA-256 digests, and the RPMs.
   Look at the `rpm -K` output — an unsigned package is unsigned, don't let it
   be presented otherwise.

## On staging

Use a non-production host set up like production — same Apache MPM, modules,
extensions and config — and install the full matching RPM set as a reversible
snapshot so you can roll back.

Inventory the host and verify the effective mod_php settings:

```bash
MODPHP_PROBE_URL=http://127.0.0.1:80/modphp-runtime-probe.php bash staging-checks.sh \
  > rc1-staging-inventory.log 2>&1
```

Reading the effective settings matters, because `php -i` shows the **CLI**
configuration, not what Apache actually runs with. `staging-checks.sh` fails
closed: if the Apache probe is missing or unreachable, or doesn't report
`sapi=apache2handler` with all three directives present, it stops. The CLI
values are printed only for comparison.

To use the probe, put `modphp-runtime-probe.php` in an Apache-served directory
on the staging host and lock it to loopback in the vhost config:

```apache
<Files "modphp-runtime-probe.php">
    Require local
</Files>
```

The probe also refuses any request whose `REMOTE_ADDR` isn't loopback, and the
script only does a localhost `curl` GET — no external calls, no server changes.
If there are several vhosts, give it a dedicated localhost-only staging vhost;
never point it at production. A passing probe confirms the settings are in
place under mod_php — it does **not** prove the security behaviour or approve
the release.

**Remove the probe as soon as you're done**, confirm the URL returns 404, and
take out its Apache rule. Don't leave it (or any `phpinfo()` page) deployed.

Then exercise the actual behaviour under Apache: multipart uploads,
duplicate/folded headers, a part with a large number of junk headers,
`max_multipart_body_parts` at the default, 0 and 2, repeated requests on the
same worker, and controlled OOM cases. Use only test fixtures you control;
don't run adversarial input at production. Compare against the pre-patch build
and watch the error log for worker restarts or crashes.

## Decision

No-go until the RPMs are built, mod_php is tested on staging, signatures are
checked, rollback is verified, and someone other than the author has reviewed
the source and signed off. The source-side testing done so far is on a
CLI/CGI/FPM build, which is not the same as production Apache mod_php.
