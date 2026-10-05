import Foundation

/// DeviceID names a device registration, and is what RevokeDevice names one by. It survives a
/// re-registration of the same token.
public typealias DeviceID = String

/// DevicePlatform is which provider a device token is addressed through.
public typealias DevicePlatform = Primandproper_Platform_Notifications_V1_DevicePlatform

extension DevicePlatform: Codable {}

/// DeviceRegistration is what this install registered, under which login. The login is the
/// session's `familyID`, so a registration made for one person is never mistaken for another's.
public struct DeviceRegistration: Sendable, Hashable, Codable {
  public var id: DeviceID
  /// token is the device token as it was sent: lowercase hex, no separators.
  public var token: String
  public var platform: DevicePlatform
  public var login: String

  public init(id: DeviceID, token: String, platform: DevicePlatform, login: String) {
    self.id = id
    self.token = token
    self.platform = platform
    self.login = login
  }
}

/// DeviceRegistrationStore holds this install's device registration, so a relaunch does not
/// register again and a sign-out knows what to revoke. It is per install: a registration
/// restored onto another device names a token that device does not hold.
public protocol DeviceRegistrationStore: Sendable {
  /// load answers the held registration, or nil when there is none.
  func load() async throws -> DeviceRegistration?
  func save(_ registration: DeviceRegistration) async throws
  func clear() async throws
}

/// KeychainDeviceRegistrationStore holds the registration as one generic-password item in the
/// data protection keychain, on this device only, exactly as `KeychainCredentialStore` holds
/// the session.
public struct KeychainDeviceRegistrationStore: DeviceRegistrationStore {
  public static let defaultService = "com.github.primandproper.platform-client"
  public static let defaultAccount = "notifications.device"

  public let service: String
  public let account: String
  /// accessGroup shares the item with an app extension in the same group. nil keeps it in the
  /// app's default group.
  public let accessGroup: String?

  public init(
    service: String = Self.defaultService,
    account: String = Self.defaultAccount,
    accessGroup: String? = nil
  ) {
    self.service = service
    self.account = account
    self.accessGroup = accessGroup
  }

  public func load() async throws -> DeviceRegistration? {
    guard let data = try item.load() else { return nil }
    do {
      return try JSONDecoder().decode(DeviceRegistration.self, from: data)
    } catch {
      throw KeychainCredentialStoreError.serialization(operation: .load, underlying: error)
    }
  }

  public func save(_ registration: DeviceRegistration) async throws {
    let data: Data
    do {
      data = try JSONEncoder().encode(registration)
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
