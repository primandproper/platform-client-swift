import Foundation
import GRPCCore
import PlatformClient
import PlatformClientTesting
import Synchronization
import Testing

private typealias NotificationsRPC = Primandproper_Platform_Notifications_V1_NotificationsService
private typealias RegisterRequest = Primandproper_Platform_Notifications_V1_RegisterDeviceRequest
private typealias RegisterResponse = Primandproper_Platform_Notifications_V1_RegisterDeviceResponse
private typealias RevokeRequest = Primandproper_Platform_Notifications_V1_RevokeDeviceRequest
private typealias RevokeResponse = Primandproper_Platform_Notifications_V1_RevokeDeviceResponse
private typealias SignOutRequest = Primandproper_Platform_Signin_V1_SignOutRequest
private typealias SignOutResponse = Primandproper_Platform_Signin_V1_SignOutResponse

private let registerMethod = NotificationsRPC.Method.RegisterDevice.descriptor
private let revokeMethod = NotificationsRPC.Method.RevokeDevice.descriptor
private let signOutMethod = SignInRPC.Method.SignOut.descriptor

private let firstToken = Data([0x0A, 0xBC, 0xFF, 0x00, 0x7E])
private let secondToken = Data([0xDE, 0xAD, 0xBE, 0xEF])

@Suite struct DevicesTests {
  @Test func registersTheTokenAsLowercaseHexWithoutSeparators() async throws {
    let fixture = DevicesFixture()

    let id = try await fixture.run { app in
      try await app.devices.register(apnsToken: firstToken, platform: .ios)
    }

    #expect(id == "device-0abcff007e")
    let sent = try #require(fixture.registrations().first)
    #expect(sent.input.token == "0abcff007e")
    #expect(sent.input.platform == .ios)
    #expect(
      fixture.server.calls(to: registerMethod).first?.metadata.first("authorization")
        == "Bearer access-1")
    #expect(
      try await fixture.registrationStore.load()
        == DeviceRegistration(
          id: "device-0abcff007e", token: "0abcff007e", platform: .ios, login: "family-1"))
  }

  @Test func registeringTheSameTokenAgainMakesNoCall() async throws {
    let fixture = DevicesFixture()

    let ids = try await fixture.run { app in
      [
        try await app.devices.register(apnsToken: firstToken, platform: .ios),
        try await app.devices.register(apnsToken: firstToken, platform: .ios),
      ]
    }

    #expect(ids == ["device-0abcff007e", "device-0abcff007e"])
    #expect(fixture.registrations().count == 1)
  }

  @Test func aRelaunchWithTheSameTokenAndLoginMakesNoCall() async throws {
    let fixture = DevicesFixture()
    try await fixture.run { app in
      _ = try await app.devices.register(apnsToken: firstToken, platform: .ios)
    }

    let id = try await fixture.run { app in
      try await app.devices.register(apnsToken: firstToken, platform: .ios)
    }

    #expect(id == "device-0abcff007e")
    #expect(fixture.registrations().count == 1)
  }

  @Test func aTokenThatArrivesBeforeSignInIsRegisteredOnceSignedIn() async throws {
    let fixture = DevicesFixture(held: false)
    fixture.server.handle(loginMethod) { (_: LoginRequest, _) in
      var response = LoginResponse()
      response.token = fakeIssuedToken(now: fixture.clock.now())
      return response
    }

    try await fixture.run { app in
      await #expect(throws: NotSignedInError.self) {
        try await app.devices.register(apnsToken: firstToken, platform: .ios)
      }
      #expect(fixture.registrations().isEmpty)

      try await app.signIn()

      try await eventually { fixture.registrations().count == 1 }
      try await eventually { (try? await fixture.registrationStore.load()) != nil }
    }

    #expect(fixture.registrations().map(\.input.token) == ["0abcff007e"])
    #expect(try await fixture.registrationStore.load()?.id == "device-0abcff007e")
  }

  @Test func aRotatedTokenRegistersAndThenRevokesTheOldRegistration() async throws {
    let fixture = DevicesFixture()

    let id = try await fixture.run { app in
      _ = try await app.devices.register(apnsToken: firstToken, platform: .ios)
      return try await app.devices.register(apnsToken: secondToken, platform: .ios)
    }

    #expect(id == "device-deadbeef")
    #expect(fixture.registrations().map(\.input.token) == ["0abcff007e", "deadbeef"])
    #expect(fixture.revocations() == ["device-0abcff007e"])
    #expect(
      fixture.server.calls.map(\.method).filter { $0 == registerMethod || $0 == revokeMethod }
        == [registerMethod, registerMethod, revokeMethod])
    #expect(try await fixture.registrationStore.load()?.token == "deadbeef")
  }

  @Test func aRotationTheServerAnswersWithTheSameIDRevokesNothing() async throws {
    let fixture = DevicesFixture()
    fixture.server.handle(registerMethod) { (_: RegisterRequest, _) in
      var response = RegisterResponse()
      response.result.id = "device-1"
      return response
    }

    try await fixture.run { app in
      _ = try await app.devices.register(apnsToken: firstToken, platform: .ios)
      _ = try await app.devices.register(apnsToken: secondToken, platform: .ios)
    }

    #expect(fixture.registrations().count == 2)
    #expect(fixture.revocations().isEmpty)
  }

  @Test func aFailedRevocationOfTheOldRegistrationStillAnswersTheNewOne() async throws {
    let fixture = DevicesFixture()
    fixture.server.handle(revokeMethod) { (_: RevokeRequest, _) -> RevokeResponse in
      throw RPCError(code: .unavailable, message: "down")
    }

    let id = try await fixture.run { app in
      _ = try await app.devices.register(apnsToken: firstToken, platform: .ios)
      return try await app.devices.register(apnsToken: secondToken, platform: .ios)
    }

    #expect(id == "device-deadbeef")
    #expect(try await fixture.registrationStore.load()?.id == "device-deadbeef")
  }

  @Test func revokingBeforeSignOutRevokesTheRegistrationAndForgetsIt() async throws {
    let fixture = DevicesFixture()
    fixture.server.handle(signOutMethod) { (_: SignOutRequest, _) in SignOutResponse() }

    try await fixture.run { app in
      _ = try await app.devices.register(apnsToken: firstToken, platform: .ios)

      try await app.devices.revoke()
      await app.session.signOut()
    }

    #expect(fixture.revocations() == ["device-0abcff007e"])
    #expect(
      fixture.server.calls(to: revokeMethod).first?.metadata.first("authorization")
        == "Bearer access-1")
    #expect(
      fixture.server.calls.map(\.method).filter { $0 == revokeMethod || $0 == signOutMethod }
        == [revokeMethod, signOutMethod])
    #expect(try await fixture.registrationStore.load() == nil)
  }

  @Test func aRefreshBetweenRevokeAndSignOutDoesNotRegisterAgain() async throws {
    let fixture = DevicesFixture()
    fixture.handleExchange { fixture.successor($0 + 1) }

    try await fixture.run { app in
      _ = try await app.devices.register(apnsToken: firstToken, platform: .ios)
      try await app.devices.revoke()

      fixture.clock.advance(by: hour)
      _ = try await app.session.call { _ in }
      try await Task.sleep(for: .milliseconds(50))
    }

    #expect(fixture.server.calls(to: exchangeMethod).count == 1)
    #expect(fixture.registrations().count == 1)
  }

  @Test func revokingWithNothingRegisteredMakesNoCall() async throws {
    let fixture = DevicesFixture()

    try await fixture.run { app in
      try await app.devices.revoke()
    }

    #expect(fixture.revocations().isEmpty)
  }

  @Test func aRegistrationTheServerNoLongerHasCountsAsRevoked() async throws {
    let fixture = DevicesFixture()
    fixture.server.handle(revokeMethod) { (_: RevokeRequest, _) -> RevokeResponse in
      throw RPCError(code: .notFound, message: "no such device")
    }

    try await fixture.run { app in
      _ = try await app.devices.register(apnsToken: firstToken, platform: .ios)
      try await app.devices.revoke()
    }

    #expect(try await fixture.registrationStore.load() == nil)
  }

  @Test func aRevocationThatFailsKeepsTheRegistration() async throws {
    let fixture = DevicesFixture()
    fixture.server.handle(revokeMethod) { (_: RevokeRequest, _) -> RevokeResponse in
      throw RPCError(code: .unavailable, message: "down")
    }

    try await fixture.run { app in
      _ = try await app.devices.register(apnsToken: firstToken, platform: .ios)
      await #expect(throws: PlatformError.self) { try await app.devices.revoke() }
    }

    #expect(try await fixture.registrationStore.load()?.id == "device-0abcff007e")
  }

  @Test func theNextLoginOnTheDeviceRegistersTheHeldTokenAgain() async throws {
    let fixture = DevicesFixture()
    fixture.server.handle(signOutMethod) { (_: SignOutRequest, _) in SignOutResponse() }
    fixture.server.handle(loginMethod) { (_: LoginRequest, _) in
      var response = LoginResponse()
      response.token = fakeIssuedToken(now: fixture.clock.now()) {
        $0.token = "access-2"
        $0.familyID = "family-2"
      }
      return response
    }

    try await fixture.run { app in
      _ = try await app.devices.register(apnsToken: firstToken, platform: .ios)
      try await app.devices.revoke()
      await app.session.signOut()

      try await app.signIn()

      try await eventually { fixture.registrations().count == 2 }
      try await eventually { (try? await fixture.registrationStore.load())??.login == "family-2" }
    }

    #expect(
      fixture.server.calls(to: registerMethod).last?.metadata.first("authorization")
        == "Bearer access-2")
  }

  @Test func aLoginThatEndedWithoutARevocationIsRegisteredOverWithoutRevokingIt() async throws {
    let fixture = DevicesFixture()
    fixture.server.handle(loginMethod) { (_: LoginRequest, _) in
      var response = LoginResponse()
      response.token = fakeIssuedToken(now: fixture.clock.now()) { $0.familyID = "family-2" }
      return response
    }

    try await fixture.run { app in
      _ = try await app.devices.register(apnsToken: firstToken, platform: .ios)
      try await app.session.clear()
      try await app.signIn()

      let id = try await app.devices.register(apnsToken: firstToken, platform: .ios)
      #expect(id == "device-0abcff007e")
    }

    #expect(fixture.registrations().count == 2)
    #expect(fixture.revocations().isEmpty)
    #expect(try await fixture.registrationStore.load()?.login == "family-2")
  }
}

/// App is what an app holds: one Session, one Devices over it, and a way to sign in.
private struct App: Sendable {
  let session: Session
  let devices: Devices
  let signIn: @Sendable () async throws -> Void
}

/// DevicesFixture is a SessionFixture whose server also answers RegisterDevice, with an ID
/// derived from the token, and RevokeDevice.
private struct DevicesFixture {
  let base: SessionFixture
  let registrationStore = MemoryDeviceRegistrationStore()

  var server: FakeServer { base.server }
  var clock: FakeClock { base.clock }

  init(held: Bool = true) {
    base = SessionFixture(held: held)
    base.server
      .handle(registerMethod) { (request: RegisterRequest, _) in
        var response = RegisterResponse()
        response.result.id = "device-\(request.input.token)"
        response.result.platform = request.input.platform
        return response
      }
      .handle(revokeMethod) { (_: RevokeRequest, _) in RevokeResponse() }
  }

  /// run hands `body` an App: a Session and a Devices over it, both built afresh, as a launch
  /// would build them.
  @discardableResult
  func run<Result: Sendable>(
    _ body: @Sendable (_ app: App) async throws -> Result
  ) async throws -> Result {
    let store = base.store
    let clock = base.clock
    let registrationStore = self.registrationStore
    return try await server.run { client in
      let session = Session(client: client, store: store, clock: clock)
      return try await body(
        App(
          session: session,
          devices: Devices(session: session, client: client, store: registrationStore),
          signIn: {
            _ = try await session.signIn {
              try await SignInRPC.Client(wrapping: client).loginForToken(.init())
            }
          }))
    }
  }

  func handleExchange(_ answer: @escaping @Sendable (Int) async throws -> IssuedToken) {
    base.handleExchange(answer)
  }

  func successor(_ n: Int) -> IssuedToken { base.successor(n) }

  func registrations() -> [RegisterRequest] {
    server.calls(to: registerMethod).compactMap { $0.request(as: RegisterRequest.self) }
  }

  func revocations() -> [String] {
    server.calls(to: revokeMethod).compactMap { $0.request(as: RevokeRequest.self)?.deviceID }
  }
}
