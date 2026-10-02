#!/usr/bin/env bash
# Run the Keychain tests on an iOS Simulator, hosted by the stub app in Tests/KeychainHost.
# They cannot run under `swift test`: neither macOS's nor the simulator's xctest holds a
# keychain entitlement, and the data protection keychain refuses a process without one.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

if ! command -v xcodegen >/dev/null; then
  echo "xcodegen is required: brew install xcodegen" >&2
  exit 1
fi

# An iPhone on the newest installed iOS runtime, so the script follows whatever Xcode the
# machine has rather than naming a device that one version ships and the next drops.
device="$(xcrun simctl list devices available --json | jq -r '
  .devices
  | to_entries
  | map(select(.key | test("SimRuntime\\.iOS-")))
  | sort_by(.key | capture("iOS-(?<v>[0-9-]+)").v | split("-") | map(tonumber))
  | map(.value[] | select(.name | startswith("iPhone")))
  | last
  | .udid // empty')"

if [[ -z "$device" ]]; then
  echo "no available iPhone simulator; install an iOS runtime in Xcode" >&2
  exit 1
fi

xcodegen generate --quiet --spec Tests/KeychainHost/project.yml

xcodebuild test \
  -project Tests/KeychainHost/KeychainHost.xcodeproj \
  -scheme KeychainHost \
  -destination "platform=iOS Simulator,id=$device" \
  -derivedDataPath .build/keychain-host \
  -quiet
