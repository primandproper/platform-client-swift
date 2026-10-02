import Foundation
import GRPCCore
import PlatformClient
import PlatformClientTesting
import Testing

private typealias PasskeysRPC = Primandproper_Platform_Passkeys_V1_PasskeysService
private typealias BeginLogin = PasskeysRPC.Method.BeginLogin
private typealias FinishLogin = PasskeysRPC.Method.FinishLogin

private let assertion = Data(#"{"id":"credential"}"#.utf8)

/// PasskeysFixture is a Session over a FakeServer that answers both halves of a passkey
/// sign-in, UNIMPLEMENTED until a test says otherwise.
private struct PasskeysFixture {
  let clock = FakeClock()
  let server = FakeServer()
  let store = MemoryCredentialStore()

  init() {
    server
      .handle(BeginLogin.descriptor) { (_: BeginLogin.Input, _) -> BeginLogin.Output in
        throw RPCError(code: .unimplemented, message: "begin")
      }
      .handle(FinishLogin.descriptor) { (_: FinishLogin.Input, _) -> FinishLogin.Output in
        throw RPCError(code: .unimplemented, message: "finish")
      }
  }

  func run<Result: Sendable>(
    _ body: @Sendable (_ session: Session, _ passkeys: any PasskeysClient) async throws -> Result
  ) async throws -> Result {
    let store = self.store
    let clock = self.clock
    return try await server.run { client in
      try await body(
        Session(client: client, store: store, clock: clock), PasskeysRPC.Client(wrapping: client))
    }
  }

  func refuseFinish(_ refusal: some Error) {
    server.handle(FinishLogin.descriptor) { (_: FinishLogin.Input, _) -> FinishLogin.Output in
      throw refusal
    }
  }
}

@Suite struct PasskeysTests {
  @Test func beginAnswersTheOptionsDiscoverableWhenNoUsernameIsGiven() async throws {
    let fixture = PasskeysFixture()
    let options = Data(#"{"publicKey":{"challenge":"Yw"}}"#.utf8)
    fixture.server.handle(BeginLogin.descriptor) { (_: BeginLogin.Input, _) in
      var response = BeginLogin.Output()
      response.options = options
      return response
    }

    let answered = try await fixture.run { session, passkeys in
      try await session.beginPasskeySignIn(passkeys)
    }

    #expect(answered == options)
    let sent = try #require(fixture.server.calls(to: BeginLogin.descriptor).first)
    #expect(sent.request(as: BeginLogin.Input.self)?.username == "")
  }

  @Test func r18_adoptsTheSessionAPasskeyMintsRefreshTokenAndAll() async throws {
    let fixture = PasskeysFixture()
    let token = fakeIssuedToken(now: fixture.clock.now())
    fixture.server.handle(FinishLogin.descriptor) { (_: FinishLogin.Input, _) in
      var response = FinishLogin.Output()
      response.token = token
      return response
    }

    let (result, state) = try await fixture.run { session, passkeys in
      let result = try await session.passkeySignIn(
        passkeys, PasskeySignIn(username: "jeff", response: assertion))
      return (result, await session.state)
    }

    #expect(result == .signedIn(token))
    var expected = FinishLogin.Input()
    expected.username = "jeff"
    expected.response = assertion
    let sent = try #require(fixture.server.calls(to: FinishLogin.descriptor).first)
    #expect(sent.request(as: FinishLogin.Input.self) == expected)
    #expect(await fixture.store.load()?.refreshToken == "refresh-1")
    #expect(state == .authenticated)
  }

  @Test func r19_asksForASecondFactorOnAKeyTapAlone() async throws {
    let fixture = PasskeysFixture()
    fixture.refuseFinish(
      refusal(
        .unauthenticated, "a second-factor code is required", SignInReason.secondFactorRequired))

    let (result, state) = try await fixture.run { session, passkeys in
      let result = try await session.passkeySignIn(passkeys, PasskeySignIn(response: assertion))
      return (result, await session.state)
    }

    #expect(result == .secondFactorRequired)
    #expect(state == .anonymous)
    #expect(await fixture.store.load() == nil)
  }

  @Test func surfacesAClonedLookingKeyByItsPasskeyReason() async throws {
    let fixture = PasskeysFixture()
    fixture.refuseFinish(
      refusal(.permissionDenied, "sign count regressed", PasskeyReason.passkeySignCountRegressed))

    let error = try await fixture.run { session, passkeys in
      await #expect(throws: PlatformError.self) {
        try await session.passkeySignIn(passkeys, PasskeySignIn(response: assertion))
      }
    }

    #expect(error?.code == .permissionDenied)
    #expect(error?.reason == .passkey(.passkeySignCountRegressed))
    #expect(error?.is(PasskeyReason.passkeySignCountRegressed) == true)
  }

  @Test func beginRethrowsARefusalAsAPlatformError() async throws {
    let fixture = PasskeysFixture()

    let error = try await fixture.run { session, passkeys in
      await #expect(throws: PlatformError.self) {
        try await session.beginPasskeySignIn(passkeys, username: "jeff")
      }
    }

    #expect(error?.code == .unimplemented)
  }
}
