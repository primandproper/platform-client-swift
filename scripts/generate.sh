#!/usr/bin/env bash
# Generate the Swift client from the fetched .proto files.
#
# The generator is pinned, not just the schema. swift-protobuf's output changed after
# 1.33.3 — it began emitting `nonisolated extension` — so an unpinned `brew install`
# means a developer and CI generate different files from identical .proto sources. The
# plugins are built from scripts/plugins/Package.swift, which pins them exactly.
#
# 1.33.3 and 2.1.1 are what dinnerdonebetter's committed output was generated with.
# Matching them is what keeps this package a drop-in for that app.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OUT="$ROOT/Sources/PlatformClient/Generated"
INCLUDE="$ROOT/.protos/include"
PLUGINS="$ROOT/scripts/plugins"

EXPECTED_PROTOC="libprotoc 33.1"
EXPECTED_SWIFT_PLUGIN="protoc-gen-swift 1.33.3"

[ -d "$INCLUDE" ] || { echo "::error::no .protos/include — run scripts/fetch-protos.sh first"; exit 1; }

echo "building pinned codegen plugins…"
swift build --package-path "$PLUGINS" --product protoc-gen-swift >/dev/null
swift build --package-path "$PLUGINS" --product protoc-gen-grpc-swift-2 >/dev/null
bin="$(swift build --package-path "$PLUGINS" --show-bin-path)"
export PATH="$bin:$PATH"

# Fail on a version mismatch rather than on a four-thousand-line diff. A generator that
# is not the pinned one produces output that is not what is committed, and the useful
# error names the version, not every line it changed.
actual_protoc="$(protoc --version)"
[ "$actual_protoc" = "$EXPECTED_PROTOC" ] || {
  echo "::error::protoc is '$actual_protoc', expected '$EXPECTED_PROTOC'. Generated output is version-sensitive."
  exit 1
}
actual_plugin="$(protoc-gen-swift --version)"
[ "$actual_plugin" = "$EXPECTED_SWIFT_PLUGIN" ] || {
  echo "::error::protoc-gen-swift is '$actual_plugin', expected '$EXPECTED_SWIFT_PLUGIN'. Is $bin first on PATH?"
  exit 1
}

rm -rf "$OUT"
mkdir -p "$OUT"

protoc \
  --swift_out="$OUT" \
  --swift_opt=Visibility=Public \
  --grpc-swift-2_out="$OUT" \
  --grpc-swift-2_opt=Client=true,Server=false \
  --proto_path "$INCLUDE" \
  $(find "$INCLUDE" -name '*.proto' | sort)

cp "$ROOT/.protos/SOURCES.txt" "$OUT/SOURCES.txt"
echo "generated $(find "$OUT" -name '*.swift' | wc -l | tr -d ' ') files -> Sources/PlatformClient/Generated"
