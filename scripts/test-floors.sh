#!/usr/bin/env bash
# Build and test against every dependency resolved to exactly its declared floor. SwiftPM
# always resolves the newest version a requirement admits, so without this a floor that has
# fallen below what the code calls compiles everywhere except in a consumer that happens to
# resolve it.
#
# It works on a copy of the package whose manifest has each `from:` rewritten to `exact:`,
# so the real Package.swift and Package.resolved are never touched, and an interrupted run
# leaves nothing behind but build products under .build/.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

staging="$(mktemp -d)"
trap 'rm -rf "$staging"' EXIT

cp -R Sources Tests "$staging/"
sed -E 's/(\.package\(url: "[^"]+",) from: ("[^"]+")\)/\1 exact: \2)/' Package.swift >"$staging/Package.swift"

# A requirement the rewrite did not recognize would quietly float to the newest version and
# make this a second copy of the regular build.
floating="$(grep -E '\.package\(' "$staging/Package.swift" | grep -vE 'exact: "[^"]+"\)' || true)"
if [[ -n "$floating" ]]; then
  echo "not declared as \`.package(url:, from:)\` on one line, so not pinned to its floor:" >&2
  echo "$floating" >&2
  exit 1
fi

scratch="$ROOT/.build/floors"

swift package --package-path "$staging" --scratch-path "$scratch" resolve
echo "--- resolved at the floors ---"
swift package --package-path "$staging" --scratch-path "$scratch" show-dependencies

swift test --package-path "$staging" --scratch-path "$scratch"
