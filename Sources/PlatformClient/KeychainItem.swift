import Foundation
import Security

/// KeychainItem is one generic-password item in the data protection keychain, readable after
/// first unlock so a background task can reach it, and never written to a backup or restored
/// onto another device. The Keychain stores build on it, so each holds what it holds the same
/// way.
struct KeychainItem: Sendable {
  let service: String
  let account: String
  let accessGroup: String?

  /// load answers the item's bytes, or nil when there is no item.
  func load() throws -> Data? {
    var query = query
    query[kSecReturnData as String] = true
    query[kSecMatchLimit as String] = kSecMatchLimitOne

    var result: CFTypeRef?
    let status = SecItemCopyMatching(query as CFDictionary, &result)
    if status == errSecItemNotFound {
      return nil
    }
    guard status == errSecSuccess else {
      throw KeychainCredentialStoreError.keychain(operation: .load, status: status)
    }
    guard let data = result as? Data else {
      throw KeychainCredentialStoreError.serialization(operation: .load, underlying: nil)
    }
    return data
  }

  /// save replaces the item in place. Updating rather than deleting and re-adding means a
  /// failure part way leaves the previous item, never none. The accessibility is written on
  /// update too, so an item that predates it is brought in line.
  func save(_ data: Data) throws {
    let attributes: [String: Any] = [
      kSecValueData as String: data,
      kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly,
    ]

    var status = SecItemUpdate(query as CFDictionary, attributes as CFDictionary)
    if status == errSecItemNotFound {
      status = SecItemAdd(query.merging(attributes) { $1 } as CFDictionary, nil)
    }
    guard status == errSecSuccess else {
      throw KeychainCredentialStoreError.keychain(operation: .save, status: status)
    }
  }

  func clear() throws {
    let status = SecItemDelete(query as CFDictionary)
    guard status == errSecSuccess || status == errSecItemNotFound else {
      throw KeychainCredentialStoreError.keychain(operation: .clear, status: status)
    }
  }

  /// query names the one item. The data protection keychain is the only one on macOS that
  /// honors a `ThisDeviceOnly` accessibility; on iOS it is the only keychain there is.
  private var query: [String: Any] {
    var query: [String: Any] = [
      kSecClass as String: kSecClassGenericPassword,
      kSecAttrService as String: service,
      kSecAttrAccount as String: account,
      kSecUseDataProtectionKeychain as String: true,
    ]
    if let accessGroup {
      query[kSecAttrAccessGroup as String] = accessGroup
    }
    return query
  }
}
