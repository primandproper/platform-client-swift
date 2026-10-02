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

# The Keychain tests, on an iOS Simulator under a host app: `swift test` cannot reach the
# data protection keychain.
.PHONY: test-keychain
test-keychain:
	./scripts/test-keychain.sh
