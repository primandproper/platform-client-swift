import Foundation
import GRPCCore
import os

private typealias NotificationsService =
  Primandproper_Platform_Notifications_V1_NotificationsService

/// MissingDeviceError is a RegisterDevice that answered OK with no device.
public struct MissingDeviceError: Error, Sendable, CustomStringConvertible {
  public var description: String { "RegisterDevice answered OK with no device" }
}

/// Devices registers this install's push token with the notifications service, and revokes it
/// on sign-out. The app hands it the token from
/// `application(_:didRegisterForRemoteNotificationsWithDeviceToken:)` and calls `revoke` before
/// `Session.signOut`; everything between is here.
///
/// A token that arrives before sign-in is held, and registered as soon as the session is
/// authenticated: one dropped would mean no push until the next launch. The registration is
/// persisted with the login it was made under, so a relaunch with the same token and the same
/// login makes no call, and a different login registers again, which moves the server's row to
/// the person now holding the device.
///
/// It is an actor, and its registrations and revocations run one at a time in the order they
/// were asked for, so the token handed over at launch and the sign-in that follows it cannot
/// both register.
public actor Devices {
  private let session: Session
  private let client: any NotificationsService.ClientProtocol
  private let store: any DeviceRegistrationStore
  private let logger = Logger(
    subsystem: "com.github.primandproper.platform-client", category: "devices")

  /// held is the newest token the app handed over, kept so that a sign-in after it registers it.
  private var held: (token: String, platform: DevicePlatform)?
  /// revokedLogin is the login `revoke` was last called under. A token held for it is not
  /// registered again on its own, since the next thing that login does is sign out.
  private var revokedLogin: String?
  private var observing: Task<Void, Never>?
  private var tail: Task<Void, Never>?

  /// init builds Devices over `session`, which makes its calls, and `client`, the same
  /// GRPCClient the session was built over.
  public init<Transport: ClientTransport>(
    session: Session,
    client: GRPCClient<Transport>,
    store: any DeviceRegistrationStore = KeychainDeviceRegistrationStore()
  ) {
    self.session = session
    self.client = NotificationsService.Client(wrapping: client)
    self.store = store
  }

  deinit {
    observing?.cancel()
  }

  /// register registers `apnsToken` for the signed-in person and answers the device's ID. A
  /// token already registered under this login answers its ID without a call. A token that
  /// replaces a registered one is registered first, and the old registration revoked after, so
  /// there is never a moment with none.
  ///
  /// With no session, the token is held, registered once one is authenticated, and this throws
  /// NotSignedInError. The app need not hand it over again.
  public func register(apnsToken: Data, platform: DevicePlatform) async throws -> DeviceID {
    let token = hexEncoded(apnsToken)
    held = (token, platform)
    observeSession()
    return try await serially { try await $0.converge(token, platform) }
  }

  /// revoke revokes this install's registration and forgets it, so the next person to sign in
  /// on the device does not get the last one's notifications. It is an authenticated call, so
  /// it goes before `Session.signOut`, not after. A registration the server no longer has
  /// counts as revoked. A held token stays held, for whoever signs in next.
  public func revoke() async throws {
    try await serially { try await $0.revokeRegistration() }
  }

  // MARK: - Registration

  private func converge(_ token: String, _ platform: DevicePlatform) async throws -> DeviceID {
    guard let login = try await session.held()?.familyID else { throw NotSignedInError() }
    let previous = try await store.load()
    if let previous, previous.token == token, previous.platform == platform,
      previous.login == login
    {
      return previous.id
    }

    var request = Primandproper_Platform_Notifications_V1_RegisterDeviceRequest()
    request.input.token = token
    request.input.platform = platform
    let client = self.client
    let response = try await session.call { [request] metadata in
      try await client.registerDevice(request, metadata: metadata)
    }
    guard response.hasResult, !response.result.id.isEmpty else { throw MissingDeviceError() }

    let registration = DeviceRegistration(
      id: response.result.id, token: token, platform: platform, login: login)
    revokedLogin = nil
    do {
      try await store.save(registration)
    } catch {
      logger.error(
        "the device registration could not be saved: \(String(describing: error), privacy: .public)"
      )
      throw error
    }
    logger.info("registered device \(registration.id, privacy: .public)")

    // A registration from another login is that person's row, or has just become this one's
    // under the same ID; neither is this login's to revoke.
    if let previous, previous.login == login, previous.id != registration.id {
      do {
        try await revokeDevice(previous.id)
      } catch {
        logger.notice(
          "the replaced device \(previous.id, privacy: .public) was not revoked: \(String(describing: error), privacy: .public)"
        )
      }
    }
    return registration.id
  }

  private func revokeRegistration() async throws {
    revokedLogin = try await session.held()?.familyID
    guard let registration = try await store.load() else { return }
    try await revokeDevice(registration.id)
    try await store.clear()
    logger.info("revoked device \(registration.id, privacy: .public)")
  }

  private func revokeDevice(_ id: DeviceID) async throws {
    var request = Primandproper_Platform_Notifications_V1_RevokeDeviceRequest()
    request.deviceID = id
    let client = self.client
    do {
      _ = try await session.call { [request] metadata in
        try await client.revokeDevice(request, metadata: metadata)
      }
    } catch let error as PlatformError where error.code == .notFound {
      logger.info("device \(id, privacy: .public) was already gone")
    }
  }

  // MARK: - Sign-in

  /// observeSession registers the held token whenever the session becomes authenticated, which
  /// is how a token handed over before sign-in reaches the server.
  private func observeSession() {
    guard observing == nil else { return }
    let session = self.session
    observing = Task { [weak self] in
      for await state in await session.states() where state == .authenticated {
        await self?.sessionAuthenticated()
      }
    }
  }

  private func sessionAuthenticated() async {
    guard let held else { return }
    do {
      try await serially { devices in
        guard let login = try await devices.session.held()?.familyID,
          login != devices.revokedLogin
        else { return }
        _ = try await devices.converge(held.token, held.platform)
      }
    } catch {
      logger.notice(
        "the held device token was not registered: \(String(describing: error), privacy: .public)"
      )
    }
  }

  /// serially runs `work` once everything asked for before it has finished.
  private func serially<Result: Sendable>(
    _ work: @escaping @Sendable (isolated Devices) async throws -> Result
  ) async throws -> Result {
    let previous = tail
    let task = Task {
      await previous?.value
      return try await work(self)
    }
    tail = Task { _ = try? await task.value }
    return try await task.value
  }
}

/// hexEncoded is an APNs token as the server stores it: lowercase hex, no separators.
func hexEncoded(_ token: Data) -> String {
  token.map { String(format: "%02x", $0) }.joined()
}
