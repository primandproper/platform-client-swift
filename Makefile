# Fetch the pinned .proto sources and regenerate. The output is committed; this is how it
# gets refreshed, not something a consumer runs.
.PHONY: codegen
codegen:
	./scripts/fetch-protos.sh
	./scripts/generate.sh

.PHONY: build
build:
	swift build

.PHONY: format
format:
	./scripts/format.sh

.PHONY: lint
lint:
	./scripts/lint.sh

.PHONY: test
test:
	swift test

.PHONY: check
check: build test

# Every dependency at exactly its declared floor rather than the newest match.
.PHONY: test-floors
test-floors:
	./scripts/test-floors.sh

# The Keychain tests, on an iOS Simulator under a host app: `swift test` cannot reach the
# data protection keychain.
.PHONY: test-keychain
test-keychain:
	./scripts/test-keychain.sh
