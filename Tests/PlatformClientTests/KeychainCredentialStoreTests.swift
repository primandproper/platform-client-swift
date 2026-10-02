import Foundation
import PlatformClient
import PlatformClientTesting
import Security
import Testing

// `swift test` runs these inside xctest, which holds no keychain entitlement, so the data
// protection keychain refuses it with errSecMissingEntitlement; macOS's legacy keychain would
// accept it but ignores accessibility altogether. They run on a simulator instead, under the
// host app in Tests/KeychainHost that links the entitlement in: `make test-keychain`.
#if os(macOS)
  private let dataProtectionKeychainReachable = false
#else
  private let dataProtectionKeychainReachable = true
#endif

@Suite(
  .enabled(
    if: dataProtectionKeychainReachable,
    "the data protection keychain needs an entitlement on macOS; run make test-keychain"))
struct KeychainCredentialStoreTests {
  @Test func loadsNothingBeforeAnythingIsSaved() async throws {
    try await withStore { store in
      let loaded = try await store.load()
      #expect(loaded == nil)
    }
  }

  @Test func loadsWhatItSaved() async throws {
    try await withStore { store in
      let token = fakeIssuedToken(now: Date())

      try await store.save(token)

      #expect(try await store.load() == token)
    }
  }

  @Test func savingAgainReplacesTheHeldSession() async throws {
    try await withStore { store in
      let first = fakeIssuedToken(now: Date())
      let second = fakeIssuedToken(now: Date()) { $0.refreshToken = "refresh-2" }

      try await store.save(first)
      try await store.save(second)

      #expect(try await store.load() == second)
      #expect(try matchingItems(store).count == 1)
    }
  }

  @Test func clearingLeavesNoSession() async throws {
    try await withStore { store in
      try await store.save(fakeIssuedToken(now: Date()))

      try await store.clear()

      #expect(try await store.load() == nil)
      #expect(try matchingItems(store).isEmpty)
    }
  }

  @Test func clearingWithNothingHeldIsNotAnError() async throws {
    try await withStore { store in
      try await store.clear()
    }
  }

  @Test func storesTheItemReadableAfterFirstUnlockOnThisDeviceOnly() async throws {
    try await withStore { store in
      try await store.save(fakeIssuedToken(now: Date()))

      let accessible = try #require(try matchingItems(store).first?[kSecAttrAccessible as String])
      #expect(
        accessible as? String == kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly as String)
    }
  }

  @Test func savingOverAnItemThatPredatesItBringsItsAccessibilityInLine() async throws {
    try await withStore { store in
      let added = SecItemAdd(
        [
          kSecClass as String: kSecClassGenericPassword,
          kSecAttrService as String: store.service,
          kSecAttrAccount as String: store.account,
          kSecUseDataProtectionKeychain as String: true,
          kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock,
          kSecValueData as String: Data("stale".utf8),
        ] as CFDictionary, nil)
      try #require(added == errSecSuccess)

      try await store.save(fakeIssuedToken(now: Date()))

      let accessible = try #require(try matchingItems(store).first?[kSecAttrAccessible as String])
      #expect(
        accessible as? String == kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly as String)
    }
  }

  @Test func anItemThatIsNotASessionThrowsOnLoad() async throws {
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
    _ body: (KeychainCredentialStore) async throws -> Void
  ) async throws {
    let store = KeychainCredentialStore(
      service: "platform-client-swift.tests.\(UUID().uuidString)", account: "session")
    do {
      try await body(store)
    } catch {
      try? await store.clear()
      throw error
    }
    try await store.clear()
  }

  /// matchingItems reads the store's items' attributes straight from the Keychain, around the
  /// store, so a test sees what was actually written.
  private func matchingItems(_ store: KeychainCredentialStore) throws -> [[String: Any]] {
    var result: CFTypeRef?
    let status = SecItemCopyMatching(
      [
        kSecClass as String: kSecClassGenericPassword,
        kSecAttrService as String: store.service,
        kSecAttrAccount as String: store.account,
        kSecUseDataProtectionKeychain as String: true,
        kSecReturnAttributes as String: true,
        kSecMatchLimit as String: kSecMatchLimitAll,
      ] as CFDictionary, &result)
    if status == errSecItemNotFound {
      return []
    }
    try #require(status == errSecSuccess)
    return try #require(result as? [[String: Any]])
  }
}

@Suite struct KeychainCredentialStoreErrorTests {
  @Test func namesTheOperationAndTheStatus() {
    let error = KeychainCredentialStoreError.keychain(
      operation: .save, status: errSecMissingEntitlement)

    #expect(error.operation == .save)
    #expect(error.description.contains("keychain save failed"))
    #expect(error.description.contains("OSStatus \(errSecMissingEntitlement)"))
  }
}
