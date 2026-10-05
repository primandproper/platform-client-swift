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
    guard let data = try item.load() else { return nil }
    do {
      return try IssuedToken(serializedBytes: data)
    } catch {
      throw KeychainCredentialStoreError.serialization(operation: .load, underlying: error)
    }
  }

  /// save replaces the held session in place, so a failure part way leaves the previous
  /// session, never none.
  public func save(_ token: IssuedToken) async throws {
    let data: Data
    do {
      data = try token.serializedData()
    } catch {
      throw KeychainCredentialStoreError.serialization(operation: .save, underlying: error)
    }
    try item.save(data)
  }

  public func clear() async throws {
    try item.clear()
  }

  private var item: KeychainItem {
    KeychainItem(service: service, account: account, accessGroup: accessGroup)
  }
}

/// KeychainCredentialStoreError names the operation that failed and why, for every Keychain
/// store here. A missing item on load is not one of these: it is nothing held.
public enum KeychainCredentialStoreError: Error, Sendable, CustomStringConvertible {
  public enum Operation: String, Sendable {
    case load, save, clear
  }

  /// keychain is a Security framework call that answered something other than success.
  case keychain(operation: Operation, status: OSStatus)
  /// serialization is a value that would not serialize on save, or an item whose bytes are not
  /// what the store holds on load.
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
        "keychain \(operation.rawValue) failed: the item did not (de)serialize: \(underlying)"
    case .serialization(let operation, nil):
      return "keychain \(operation.rawValue) failed: item held no data"
    }
  }
}
