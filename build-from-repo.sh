#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")" && pwd)"
for patch in "$ROOT"/patches/0[1-6]-*.patch; do cp "$patch" "$ROOT/rpm/"; done
exec bash "$ROOT/rpm/build-rc.sh" "$@"
