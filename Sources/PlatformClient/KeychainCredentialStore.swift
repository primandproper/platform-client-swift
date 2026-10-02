import Foundation
import Security

/// KeychainCredentialStore holds the session as one generic-password item in the data
/// protection keychain, readable after first unlock so a background refresh can reach it,
/// and never written to a backup or restored onto another device.
///
/// It is opt-in: an app constructs one and hands it to its Session. It does not read what any
/// earlier store wrote; moving or discarding that item is the app's migration.
public struct KeychainCredentialStore: CredentialStore {
  public let service: String
  public let account: String
  /// accessGroup shares the item with an app extension in the same group. nil keeps it in the
  /// app's default group.
  public let accessGroup: String?

  public init(service: String, account: String, accessGroup: String? = nil) {
    self.service = service
    self.account = account
    self.accessGroup = accessGroup
  }

  public func load() async throws -> IssuedToken? {
    var query = itemQuery
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
    do {
      return try IssuedToken(serializedBytes: data)
    } catch {
      throw KeychainCredentialStoreError.serialization(operation: .load, underlying: error)
    }
  }

  /// save replaces the held session in place. Updating rather than deleting and re-adding
  /// means a failure part way leaves the previous session, never none. The accessibility is
  /// written on update too, so an item that predates it is brought in line.
  public func save(_ token: IssuedToken) async throws {
    let data: Data
    do {
      data = try token.serializedData()
    } catch {
      throw KeychainCredentialStoreError.serialization(operation: .save, underlying: error)
    }
    let attributes: [String: Any] = [
      kSecValueData as String: data,
      kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly,
    ]

    var status = SecItemUpdate(itemQuery as CFDictionary, attributes as CFDictionary)
    if status == errSecItemNotFound {
      status = SecItemAdd(itemQuery.merging(attributes) { $1 } as CFDictionary, nil)
    }
    guard status == errSecSuccess else {
      throw KeychainCredentialStoreError.keychain(operation: .save, status: status)
    }
  }

  public func clear() async throws {
    let status = SecItemDelete(itemQuery as CFDictionary)
    guard status == errSecSuccess || status == errSecItemNotFound else {
      throw KeychainCredentialStoreError.keychain(operation: .clear, status: status)
    }
  }

  /// itemQuery names the one item this store owns. The data protection keychain is the only
  /// one on macOS that honors a `ThisDeviceOnly` accessibility; on iOS it is the only keychain
  /// there is.
  private var itemQuery: [String: Any] {
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

/// KeychainCredentialStoreError names the operation that failed and why. A missing item on
/// load is not one of these: it is no session.
public enum KeychainCredentialStoreError: Error, Sendable, CustomStringConvertible {
  public enum Operation: String, Sendable {
    case load, save, clear
  }

  /// keychain is a Security framework call that answered something other than success.
  case keychain(operation: Operation, status: OSStatus)
  /// serialization is a session that would not serialize on save, or an item whose bytes are
  /// not a session on load.
  case serialization(operation: Operation, underlying: (any Error)?)

  public var operation: Operation {
    switch self {
    case .keychain(let operation, _), .serialization(let operation, _): operation
    }
  }

  public var description: String {
    switch self {
    case .keychain(let operation, let status):
      let message = SecCopyErrorMessageString(status, nil) as String? ?? "no message"
      return "keychain \(operation.rawValue) failed: OSStatus \(status) (\(message))"
    case .serialization(let operation, let underlying?):
      return
        "keychain \(operation.rawValue) failed: the session did not (de)serialize: \(underlying)"
    case .serialization(let operation, nil):
      return "keychain \(operation.rawValue) failed: item held no data"
    }
  }
}
