import Foundation
import GRPCCore
import PlatformClient
import PlatformClientTesting
import Testing

private typealias SignOutRequest = Primandproper_Platform_Signin_V1_SignOutRequest
private typealias SignOutResponse = Primandproper_Platform_Signin_V1_SignOutResponse
private typealias EverywhereRequest = Primandproper_Platform_Signin_V1_SignOutEverywhereRequest
private typealias EverywhereResponse = Primandproper_Platform_Signin_V1_SignOutEverywhereResponse

private let signOutMethod = SignInRPC.Method.SignOut.descriptor
private let everywhereMethod = SignInRPC.Method.SignOutEverywhere.descriptor

@Suite struct SignOutTests {
  @Test func sendsTheRefreshTokenAndClearsOnlyAfter() async throws {
    let fixture = SessionFixture()
    let storedDuringCall = Box<IssuedToken?>(nil)
    fixture.server.handle(signOutMethod) { (_: SignOutRequest, _) in
      storedDuringCall.value = try await fixture.store.load()
      return SignOutResponse()
    }

    let state = try await fixture.run { session, _ in
      await session.signOut()
      return await session.state
    }

    let sent = try #require(fixture.server.calls(to: signOutMethod).first)
    #expect(sent.request(as: SignOutRequest.self)?.refreshToken == "refresh-1")
    #expect(sent.metadata.first("x-tenant") == "acme")
    #expect(sent.metadata.first("authorization") == nil)
    #expect(storedDuringCall.value?.refreshToken == "refresh-1")
    #expect(try await fixture.store.load() == nil)
    #expect(state == .anonymous)
  }

  @Test func worksOnASessionWhoseAccessTokenLapsedLongAgoWithoutRefreshingItFirst() async throws {
    let fixture = SessionFixture()
    fixture.server.handle(signOutMethod) { (_: SignOutRequest, _) in SignOutResponse() }

    try await fixture.run { session, _ in
      fixture.clock.advance(by: 12 * hour)
      await session.signOut()
    }

    #expect(fixture.server.calls(to: signOutMethod).count == 1)
    #expect(fixture.server.calls(to: exchangeMethod).isEmpty)
  }

  @Test func clearsWhenTheServerRefusesTheToken() async throws {
    let fixture = SessionFixture()
    fixture.server.handle(signOutMethod) { (_: SignOutRequest, _) -> SignOutResponse in
      throw RPCError(code: .unauthenticated, message: "invalid credentials")
    }

    try await fixture.run { session, _ in await session.signOut() }

    #expect(fixture.server.calls(to: signOutMethod).count == 1)
    #expect(try await fixture.store.load() == nil)
  }

  @Test func clearsWhenTheCallCannotBeDelivered() async throws {
    let fixture = SessionFixture()
    fixture.server.handle(signOutMethod) { (_: SignOutRequest, _) -> SignOutResponse in
      throw RPCError(code: .unavailable, message: "connection refused")
    }

    let state = try await fixture.run { session, _ in
      await session.signOut()
      return await session.state
    }

    #expect(fixture.server.calls(to: signOutMethod).count == 1)
    #expect(try await fixture.store.load() == nil)
    #expect(state == .anonymous)
  }

  @Test func makesNoCallWhenThereIsNothingToSignOut() async throws {
    let fixture = SessionFixture(held: false)

    try await fixture.run { session, _ in await session.signOut() }

    #expect(fixture.server.calls.isEmpty)
  }

  @Test func makesNoCallForASessionWithNoRefreshTokenAndStillClearsIt() async throws {
    let fixture = SessionFixture { now in
      MemoryCredentialStore(
        fakeIssuedToken(now: now) {
          $0.refreshToken = ""
          $0.clearRefreshTokenExpiresAt()
        })
    }

    try await fixture.run { session, _ in await session.signOut() }

    #expect(fixture.server.calls.isEmpty)
    #expect(try await fixture.store.load() == nil)
  }

  @Test func sendsTheSuccessorWhenARefreshWasInFlight() async throws {
    let fixture = SessionFixture()
    let gate = Gate()
    fixture.handleExchange { _ in
      await gate.wait()
      return fixture.successor(2)
    }
    fixture.server.handle(signOutMethod) { (_: SignOutRequest, _) in SignOutResponse() }

    try await fixture.run { session, caller in
      fixture.clock.advance(by: hour)
      async let calling: Void = caller.call(session)
      try await eventually { !fixture.server.calls(to: exchangeMethod).isEmpty }
      async let signingOut: Void = session.signOut()
      try await Task.sleep(for: .milliseconds(10))
      gate.open()
      try await calling
      await signingOut
    }

    #expect(
      fixture.server.calls(to: signOutMethod).first?.request(as: SignOutRequest.self)?
        .refreshToken == "refresh-2")
    #expect(try await fixture.store.load() == nil)
  }

  @Test func signOutEverywhereIsAnAuthenticatedCallAndClearsAfterIt() async throws {
    let fixture = SessionFixture()
    let storedDuringCall = Box<IssuedToken?>(nil)
    fixture.server.handle(everywhereMethod) { (_: EverywhereRequest, _) in
      storedDuringCall.value = try await fixture.store.load()
      return EverywhereResponse()
    }

    let state = try await fixture.run { session, _ in
      try await session.signOutEverywhere()
      return await session.state
    }

    let sent = try #require(fixture.server.calls(to: everywhereMethod).first).metadata
    #expect(sent.first("authorization") == "Bearer access-1")
    #expect(sent.first("x-tenant") == "acme")
    #expect(storedDuringCall.value != nil)
    #expect(try await fixture.store.load() == nil)
    #expect(state == .anonymous)
  }

  @Test func signOutEverywhereThrowsAndKeepsTheSessionWhenItFails() async throws {
    let fixture = SessionFixture()
    fixture.server.handle(everywhereMethod) { (_: EverywhereRequest, _) -> EverywhereResponse in
      throw RPCError(code: .unavailable, message: "unavailable")
    }

    let (error, state) = try await fixture.run { session, _ in
      let error = await #expect(throws: PlatformError.self) {
        try await session.signOutEverywhere()
      }
      return (error, await session.state)
    }

    #expect(error?.code == .unavailable)
    #expect(try await fixture.store.load()?.token == "access-1")
    #expect(state == .authenticated)
  }

  @Test func signOutEverywhereThrowsWhenThereIsNoSession() async throws {
    let fixture = SessionFixture(held: false)

    try await fixture.run { session, _ in
      await #expect(throws: NotSignedInError.self) { try await session.signOutEverywhere() }
    }

    #expect(fixture.server.calls.isEmpty)
  }
}
