#!/usr/bin/env bash
# Lint every hand-written Swift file with the toolchain's swift-format, and every script
# with shellcheck. --strict makes a swift-format finding fail the run rather than print a
# warning nobody reads.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

files=()
while IFS= read -r f; do files+=("$f"); done < <("$ROOT/scripts/swift-sources.sh")
swift format lint --strict --parallel "${files[@]}"

shellcheck scripts/*.sh
