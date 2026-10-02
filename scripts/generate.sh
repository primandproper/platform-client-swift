#!/usr/bin/env bash
# Generate the Swift client from the fetched .proto files.
#
# The generator is pinned, not just the schema. swift-protobuf's output changed after
# 1.33.3 — it began emitting `nonisolated extension` — so an unpinned `brew install`
# means a developer and CI generate different files from identical .proto sources. Each
# plugin is built from its own manifest under scripts/plugins/, which pins it exactly;
# they are two packages because they cannot share a swift-protobuf on SwiftPM 6.2.
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
EXPECTED_GRPC_PLUGIN="protoc-gen-grpc-swift-2 2.1.1"

[ -d "$INCLUDE" ] || { echo "::error::no .protos/include — run scripts/fetch-protos.sh first"; exit 1; }

echo "building pinned codegen plugins…"
for plugin in protoc-gen-swift protoc-gen-grpc-swift-2; do
  swift build --package-path "$PLUGINS/$plugin" --product "$plugin" >/dev/null
  PATH="$(swift build --package-path "$PLUGINS/$plugin" --show-bin-path):$PATH"
done
export PATH

# Fail on a version mismatch rather than on a four-thousand-line diff. A generator that
# is not the pinned one produces output that is not what is committed, and the useful
# error names the version, not every line it changed.
actual_protoc="$(protoc --version)"
[ "$actual_protoc" = "$EXPECTED_PROTOC" ] || {
  echo "::error::protoc is '$actual_protoc', expected '$EXPECTED_PROTOC'. Generated output is version-sensitive."
  exit 1
}
for expected in "$EXPECTED_SWIFT_PLUGIN" "$EXPECTED_GRPC_PLUGIN"; do
  plugin="${expected%% *}"
  actual="$("$plugin" --version)"
  [ "$actual" = "$expected" ] || {
    echo "::error::$plugin is '$actual', expected '$expected'. Is scripts/plugins/$plugin's build first on PATH?"
    exit 1
  }
done

rm -rf "$OUT"
mkdir -p "$OUT"

protos=()
while IFS= read -r p; do protos+=("$p"); done < <(find "$INCLUDE" -name '*.proto' | sort)

protoc \
  --swift_out="$OUT" \
  --swift_opt=Visibility=Public \
  --grpc-swift-2_out="$OUT" \
  --grpc-swift-2_opt=Client=true,Server=false,Visibility=Public \
  --proto_path "$INCLUDE" \
  "${protos[@]}"

cp "$ROOT/.protos/SOURCES.txt" "$OUT/SOURCES.txt"
echo "generated $(find "$OUT" -name '*.swift' | wc -l | tr -d ' ') files -> Sources/PlatformClient/Generated"
