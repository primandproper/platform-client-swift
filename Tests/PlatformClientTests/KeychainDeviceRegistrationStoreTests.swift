import Foundation
import PlatformClient
import Security
import Testing

// These need the data protection keychain, so like KeychainCredentialStoreTests they run on a
// simulator under the host app in Tests/KeychainHost: `make test-keychain`.
#if os(macOS)
  private let dataProtectionKeychainReachable = false
#else
  private let dataProtectionKeychainReachable = true
#endif

@Suite(
  .enabled(
    if: dataProtectionKeychainReachable,
    "the data protection keychain needs an entitlement on macOS; run make test-keychain"))
struct KeychainDeviceRegistrationStoreTests {
  private let registration = DeviceRegistration(
    id: "device-1", token: "0abcff007e", platform: .ios, login: "family-1")

  @Test func loadsNothingBeforeAnythingIsSaved() async throws {
    try await withStore { store in
      let loaded = try await store.load()
      #expect(loaded == nil)
    }
  }

  @Test func loadsWhatItSaved() async throws {
    try await withStore { store in
      try await store.save(registration)

      #expect(try await store.load() == registration)
    }
  }

  @Test func savingAgainReplacesTheHeldRegistration() async throws {
    try await withStore { store in
      var rotated = registration
      rotated.id = "device-2"
      rotated.token = "deadbeef"

      try await store.save(registration)
      try await store.save(rotated)

      #expect(try await store.load() == rotated)
    }
  }

  @Test func clearingLeavesNoRegistration() async throws {
    try await withStore { store in
      try await store.save(registration)

      try await store.clear()

      #expect(try await store.load() == nil)
    }
  }

  @Test func anItemThatIsNotARegistrationThrowsOnLoad() async throws {
    try await withStore { store in
      let added = SecItemAdd(
        [
          kSecClass as String: kSecClassGenericPassword,
          kSecAttrService as String: store.service,
          kSecAttrAccount as String: store.account,
          kSecUseDataProtectionKeychain as String: true,
          kSecValueData as String: Data([0xFF, 0xFF, 0xFF]),
        ] as CFDictionary, nil)
      try #require(added == errSecSuccess)

      let error = await #expect(throws: KeychainCredentialStoreError.self) {
        try await store.load()
      }
      #expect(error?.operation == .load)
    }
  }

  /// withStore hands the body a store under a service no other test shares, and clears it
  /// afterwards whether the body passed or not.
  private func withStore(
    _ body: (KeychainDeviceRegistrationStore) async throws -> Void
  ) async throws {
    let store = KeychainDeviceRegistrationStore(
      service: "platform-client-swift.tests.\(UUID().uuidString)")
    do {
      try await body(store)
    } catch {
      try? await store.clear()
      throw error
    }
    try await store.clear()
  }
}
