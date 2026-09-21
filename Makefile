.PHONY: codegen build test format check

# Fetch the pinned .proto sources and regenerate. The output is committed; this is how it
# gets refreshed, not something a consumer runs.
codegen:
	./scripts/fetch-protos.sh
	./scripts/generate.sh

build:
	swift build

test:
	swift test

format:
	swift-format format --in-place --recursive Sources/ || true

check: build test
