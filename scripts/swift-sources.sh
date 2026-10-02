#!/usr/bin/env bash
# Print the Swift files format and lint own: everything but the generated client, which
# is protoc's output and is checked by regenerating it, not by reformatting it.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

echo Package.swift
find Sources Tests scripts -name '*.swift' -not -path '*/Generated/*' -not -path '*/.build/*' | sort
