#!/usr/bin/env bash
# Generate the Swift client from the fetched .proto files.
#
# Flags match what dinnerdonebetter already generates with — grpc-swift 2, client only,
# public visibility — because the output has to drop into that app in place of the copies
# it maintains by hand.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OUT="$ROOT/Sources/PlatformClient/Generated"
INCLUDE="$ROOT/.protos/include"

[ -d "$INCLUDE" ] || { echo "::error::no .protos/include — run scripts/fetch-protos.sh first"; exit 1; }

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
