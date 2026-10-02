import Foundation
import GRPCCore
import PlatformClient
import PlatformClientTesting
import Testing

extension SessionFixture {
  /// handleSwitch answers every switch with a successor in the account it names.
  func handleSwitch(_ n: Int, gate: Gate? = nil) {
    server.handle(switchMethod) { (request: SwitchRequest, _) in
      await gate?.wait()
      var response = SwitchResponse()
      response.token = successor(n, account: request.accountID)
      return response
    }
  }
}

@Suite struct SwitchAccountTests {
  @Test func spendsTheRefreshTokenForOneInTheNamedAccountAndSavesIt() async throws {
    let fixture = SessionFixture()
    fixture.handleSwitch(2)

    let (token, state) = try await fixture.run { session, _ in
      (try await session.switchAccount("account-2"), await session.state)
    }

    #expect(token.activeAccountID == "account-2")
    let request = try #require(
      fixture.server.calls(to: switchMethod).first?.request(as: SwitchRequest.self))
    #expect(request.refreshToken == "refresh-1")
    #expect(request.accountID == "account-2")
    #expect(fixture.tokensSent(to: switchMethod) == [nil])
    #expect(try await fixture.store.load()?.refreshToken == "refresh-2")
    #expect(state == .authenticated)
  }

  @Test func r20_holdsCallsMadeDuringTheSwitchAndServesThemItsSuccessor() async throws {
    let fixture = SessionFixture()
    let gate = Gate()
    fixture.handleSwitch(2, gate: gate)

    try await fixture.run { session, caller in
      async let switching = session.switchAccount("account-2")
      try await eventually { fixture.server.calls(to: switchMethod).count == 1 }
      async let call: Void = caller.call(session)
      try await Task.sleep(for: .milliseconds(20))
      gate.open()
      _ = try await (switching, call)
    }

    #expect(fixture.tokensSent() == ["Bearer access-2"])
  }

  @Test func r20_neverPresentsTheTokenTwiceWhenASwitchRacesAnExchange() async throws {
    let fixture = SessionFixture()
    fixture.handleExchange { _ in fixture.successor(2) }
    fixture.handleSwitch(3)

    let token = try await fixture.run { session, caller in
      fixture.clock.advance(by: hour)
      async let call: Void = caller.call(session)
      async let switched = session.switchAccount("account-2")
      _ = try await call
      return try await switched
    }

    // Whichever reached the actor first, each token was presented once, and the switch spent
    // whatever the session held when it ran.
    let presented =
      fixture.refreshTokensPresented(to: exchangeMethod)
      + fixture.refreshTokensPresented(to: switchMethod)
    #expect(Set(presented).count == presented.count)
    #expect(fixture.server.calls(to: switchMethod).count == 1)
    #expect(token.activeAccountID == "account-2")
    #expect(try await fixture.store.load()?.refreshToken == "refresh-3")
  }

  @Test func keepsTheLoginWhereItWasWhenTheAccountIsRefusedAndTheTokenStillExchanges()
    async throws
  {
    let fixture = SessionFixture()
    fixture.server.handle(switchMethod) { (_: SwitchRequest, _) -> SwitchResponse in
      throw refusal(.unauthenticated, "invalid credentials", SignInReason.invalidCredentials)
    }
    fixture.handleExchange { _ in fixture.successor(2) }

    let (error, state) = try await fixture.run { session, _ in
      let error = await #expect(throws: PlatformError.self) {
        try await session.switchAccount("not-mine")
      }
      return (error, await session.state)
    }

    #expect(error?.is(SignInReason.invalidCredentials) == true)
    #expect(fixture.refreshTokensPresented(to: exchangeMethod) == ["refresh-1"])
    #expect(try await fixture.store.load()?.refreshToken == "refresh-2")
    #expect(try await fixture.store.load()?.activeAccountID == "account-1")
    #expect(state == .authenticated)
  }

  @Test func servesCallsMadeDuringARefusedSwitchTheLoginItKept() async throws {
    let fixture = SessionFixture()
    let gate = Gate()
    fixture.server.handle(switchMethod) { (_: SwitchRequest, _) -> SwitchResponse in
      await gate.wait()
      throw refusal(.unauthenticated, "invalid credentials", SignInReason.invalidCredentials)
    }
    fixture.handleExchange { _ in fixture.successor(2) }

    let (error, state) = try await fixture.run { session, caller in
      let switching = Task { try await session.switchAccount("not-mine") }
      try await eventually { fixture.server.calls(to: switchMethod).count == 1 }
      async let call: Void = caller.call(session)
      try await Task.sleep(for: .milliseconds(20))
      gate.open()
      // The refusal is the switch's alone: the call still goes out on the kept login.
      try await call
      let error = await #expect(throws: PlatformError.self) { try await switching.value }
      return (error, await session.state)
    }

    #expect(error?.is(SignInReason.invalidCredentials) == true)
    #expect(fixture.tokensSent() == ["Bearer access-2"])
    #expect(state == .authenticated)
  }

  @Test func r7_endsTheLoginWhenTheRefusedTokenDoesNotExchangeEither() async throws {
    let fixture = SessionFixture()
    fixture.server.handle(switchMethod) { (_: SwitchRequest, _) -> SwitchResponse in
      throw refusal(.unauthenticated, "invalid credentials", SignInReason.invalidCredentials)
    }
    fixture.handleExchange { _ in
      throw refusal(.unauthenticated, "invalid credentials", SignInReason.invalidCredentials)
    }

    let state = try await fixture.run { session, _ in
      await #expect(throws: PlatformError.self) { try await session.switchAccount("account-2") }
      return await session.state
    }

    #expect(try await fixture.store.load() == nil)
    #expect(state == .anonymous)
  }

  @Test func r5_keepsTheAccessTokenAndDropsTheRefreshTokenWhenASwitchFailsAmbiguously()
    async throws
  {
    let fixture = SessionFixture()
    fixture.server.handle(switchMethod) { (_: SwitchRequest, _) -> SwitchResponse in
      throw RPCError(code: .unavailable, message: "connection reset")
    }

    let error = try await fixture.run { session, _ in
      await #expect(throws: PlatformError.self) { try await session.switchAccount("account-2") }
    }

    #expect(error?.code == .unavailable)
    #expect(fixture.server.calls(to: switchMethod).count == 1)
    #expect(fixture.server.calls(to: exchangeMethod).isEmpty)
    let stored = try await fixture.store.load()
    #expect(stored?.token == "access-1")
    #expect(stored?.refreshToken == "")
  }

  @Test func refusesToSwitchWithoutALogin() async throws {
    let fixture = SessionFixture(held: false)

    try await fixture.run { session, _ in
      await #expect(throws: NotSignedInError.self) { try await session.switchAccount("account-2") }
    }

    #expect(fixture.server.calls.isEmpty)
  }

  @Test func refusesAnEmptyAccountBeforeAnyCall() async throws {
    let fixture = SessionFixture()

    try await fixture.run { session, caller in
      await #expect(throws: NoAccountError.self) { try await session.switchAccount("") }
      // The login is untouched, and still makes calls.
      try await caller.call(session)
    }

    #expect(fixture.server.calls(to: switchMethod).isEmpty)
    #expect(fixture.server.calls(to: exchangeMethod).isEmpty)
    #expect(try await fixture.store.load()?.refreshToken == "refresh-1")
  }
}
