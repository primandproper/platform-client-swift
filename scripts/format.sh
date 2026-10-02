#!/usr/bin/env bash
# Format every hand-written Swift file in place with the toolchain's swift-format.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

files=()
while IFS= read -r f; do files+=("$f"); done < <("$ROOT/scripts/swift-sources.sh")
swift format format --in-place --parallel "${files[@]}"
