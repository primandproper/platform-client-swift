import Foundation
import GRPCCore
import PlatformClient
import PlatformClientTesting
import Synchronization
import Testing

@Suite struct SessionTests {
  @Test func adoptsAStoredSessionAndSendsItsTokenWithTheTenant() async throws {
    let fixture = SessionFixture()

    let state = try await fixture.run { session, caller in
      try await caller.call(session)
      return await session.state
    }

    #expect(state == .authenticated)
    let sent = try #require(fixture.server.calls(to: authStatusMethod).first).metadata
    #expect(sent.first("authorization") == "Bearer access-1")
    #expect(sent.first("x-tenant") == "acme")
  }

  @Test func refusesAnAuthenticatedCallWithNoSession() async throws {
    let fixture = SessionFixture(held: false)

    let state = try await fixture.run { session, caller in
      await #expect(throws: NotSignedInError.self) { try await caller.call(session) }
      return await session.state
    }

    #expect(fixture.server.calls.isEmpty)
    #expect(state == .anonymous)
  }

  @Test func doesNotRefreshOutsideTheSkew() async throws {
    let fixture = SessionFixture()

    try await fixture.run { session, caller in
      fixture.clock.advance(by: hour - 31)
      try await caller.call(session)
    }

    #expect(fixture.server.calls(to: exchangeMethod).isEmpty)
  }

  @Test func refreshesInsideTheSkewPersistingTheSuccessorBeforeUsingIt() async throws {
    // R6
    let fixture = SessionFixture()
    fixture.handleExchange { _ in fixture.successor(2) }
    let storedWhenUsed = Box<IssuedToken?>(nil)
    fixture.server.handle(authStatusMethod) { (_: AuthStatusRequest, _) in
      storedWhenUsed.value = try await fixture.store.load()
      return AuthStatusResponse()
    }

    let state = try await fixture.run { session, caller in
      fixture.clock.advance(by: hour - Session.refreshSkew)
      try await caller.call(session)
      return await session.state
    }

    let exchanged = fixture.server.calls(to: exchangeMethod)
    #expect(fixture.refreshTokensPresented(to: exchangeMethod) == ["refresh-1"])
    #expect(exchanged.first?.metadata.first("x-tenant") == "acme")
    #expect(exchanged.first?.metadata.first("authorization") == nil)
    #expect(fixture.tokensSent() == ["Bearer access-2"])
    #expect(storedWhenUsed.value?.refreshToken == "refresh-2")
    #expect(state == .authenticated)
  }

  @Test func r1_makesOneExchangeForManyConcurrentCallersInsideTheSkew() async throws {
    let fixture = SessionFixture()
    let gate = Gate()
    fixture.handleExchange { _ in
      await gate.wait()
      return fixture.successor(2)
    }

    let sawRefreshing = try await fixture.run { session, caller in
      fixture.clock.advance(by: hour - 10)
      return try await withThrowingTaskGroup(of: Void.self) { group in
        for _ in 0..<50 {
          group.addTask { try await caller.call(session) }
        }
        defer { gate.open() }
        try await eventually { !fixture.server.calls(to: exchangeMethod).isEmpty }
        let refreshing = await session.state == .refreshing
        // Let every caller reach the flight before it lands.
        try await Task.sleep(for: .milliseconds(50))
        gate.open()
        try await group.waitForAll()
        return refreshing
      }
    }

    #expect(sawRefreshing)
    #expect(fixture.server.calls(to: exchangeMethod).count == 1)
    #expect(fixture.tokensSent() == Array(repeating: "Bearer access-2", count: 50))
  }

  @Test func endsTheSessionWithoutARoundTripOnceTheRefreshTokenHasExpired() async throws {
    let fixture = SessionFixture()

    let state = try await fixture.run { session, caller in
      fixture.clock.advance(by: 24 * hour)
      await #expect(throws: NotSignedInError.self) { try await caller.call(session) }
      return await session.state
    }

    #expect(fixture.server.calls.isEmpty)
    #expect(try await fixture.store.load() == nil)
    #expect(state == .anonymous)
  }

  @Test(arguments: [RPCError.Code.unauthenticated, .permissionDenied])
  func r7_signsOutWhenTheExchangeIsRefused(code: RPCError.Code) async throws {
    let fixture = SessionFixture()
    fixture.handleExchange { _ in throw RPCError(code: code, message: "refused") }

    let (error, state) = try await fixture.run { session, caller in
      fixture.clock.advance(by: hour)
      let error = await #expect(throws: PlatformError.self) { try await caller.call(session) }
      return (error, await session.state)
    }

    #expect(error?.code == code)
    #expect(try await fixture.store.load() == nil)
    #expect(state == .anonymous)
    #expect(fixture.server.calls(to: authStatusMethod).isEmpty)
  }

  @Test func r2_keepsTheSessionWhenTheExchangeFailsSomeOtherWay() async throws {
    let fixture = SessionFixture()
    fixture.handleExchange { _ in throw RPCError(code: .resourceExhausted, message: "slow down") }

    let state = try await fixture.run { session, caller in
      fixture.clock.advance(by: hour - 10)
      await #expect(throws: PlatformError.self) { try await caller.call(session) }
      return await session.state
    }

    #expect(state == .authenticated)
    #expect(try await fixture.store.load()?.refreshToken == "refresh-1")
  }

  @Test func r5_neverReSendsARefreshTokenAnAmbiguousExchangeMayHaveSpent() async throws {
    let fixture = SessionFixture()
    fixture.handleExchange { _ in throw RPCError(code: .unavailable, message: "connection reset") }

    try await fixture.run { session, caller in
      fixture.clock.advance(by: hour - 10)
      await #expect(throws: PlatformError.self) { try await caller.call(session) }
      #expect(await session.state == .authenticated)
      #expect(try await fixture.store.load()?.refreshToken == "")

      try await caller.call(session)
      #expect(fixture.server.calls(to: exchangeMethod).count == 1)
      #expect(fixture.tokensSent() == ["Bearer access-1"])

      fixture.clock.advance(by: 10)
      await #expect(throws: NotSignedInError.self) { try await caller.call(session) }
      #expect(fixture.server.calls(to: exchangeMethod).count == 1)
      #expect(await session.state == .anonymous)
    }
  }

  @Test func r3_refreshesOnceAndRetriesOnceWhenACallIsAnsweredUnauthenticated() async throws {
    let fixture = SessionFixture()
    fixture.handleExchange { _ in fixture.successor(2) }
    fixture.server.handle(authStatusMethod) { (_: AuthStatusRequest, metadata) in
      if metadata.first("authorization") == "Bearer access-1" {
        throw RPCError(code: .unauthenticated, message: "invalid credentials")
      }
      return AuthStatusResponse()
    }

    try await fixture.run { session, caller in try await caller.call(session) }

    #expect(fixture.server.calls(to: exchangeMethod).count == 1)
    #expect(fixture.tokensSent() == ["Bearer access-1", "Bearer access-2"])
  }

  @Test func r3_signsOutOnASecondUnauthenticatedRatherThanLooping() async throws {
    let fixture = SessionFixture()
    fixture.handleExchange { _ in fixture.successor(2) }
    fixture.server.handle(authStatusMethod) { (_: AuthStatusRequest, _) -> AuthStatusResponse in
      throw RPCError(code: .unauthenticated, message: "invalid credentials")
    }

    let (error, state) = try await fixture.run { session, caller in
      let error = await #expect(throws: PlatformError.self) { try await caller.call(session) }
      return (error, await session.state)
    }

    #expect(error?.code == .unauthenticated)
    #expect(fixture.server.calls(to: exchangeMethod).count == 1)
    #expect(fixture.server.calls(to: authStatusMethod).count == 2)
    #expect(try await fixture.store.load() == nil)
    #expect(state == .anonymous)
  }

  @Test func doesNotTreatAnErrorThatIsNotUnauthenticatedAsAReasonToRefresh() async throws {
    let fixture = SessionFixture()
    fixture.server.handle(authStatusMethod) { (_: AuthStatusRequest, _) -> AuthStatusResponse in
      throw RPCError(code: .notFound, message: "no")
    }

    let error = try await fixture.run { session, caller in
      await #expect(throws: PlatformError.self) { try await caller.call(session) }
    }

    #expect(error?.code == .notFound)
    #expect(fixture.server.calls(to: exchangeMethod).isEmpty)
  }

  @Test func treatsASessionWithNoRefreshTokenAsValidUntilItsAccessTokenExpires() async throws {
    let fixture = SessionFixture { now in
      MemoryCredentialStore(
        fakeIssuedToken(now: now) {
          $0.refreshToken = ""
          $0.clearRefreshTokenExpiresAt()
        })
    }

    let state = try await fixture.run { session, caller in
      fixture.clock.advance(by: hour - 0.001)
      try await caller.call(session)
      fixture.clock.advance(by: 0.001)
      await #expect(throws: NotSignedInError.self) { try await caller.call(session) }
      return await session.state
    }

    #expect(fixture.server.calls(to: exchangeMethod).isEmpty)
    #expect(state == .anonymous)
  }

  @Test func adoptsAndSavesWhatASignInDoorAnswers() async throws {
    let fixture = SessionFixture(held: false)
    fixture.server.handle(loginMethod) { (_: LoginRequest, _) in
      var response = LoginResponse()
      response.token = fakeIssuedToken(now: fixture.clock.now())
      return response
    }

    let (token, states) = try await fixture.run { session, caller in
      let states = await session.states()
      let token = try await session.signIn(caller.login)
      return (token, await states.first(3))
    }

    #expect(token.token == "access-1")
    #expect(try await fixture.store.load()?.token == "access-1")
    #expect(states == [.anonymous, .authenticating, .authenticated])
    #expect(fixture.server.calls(to: loginMethod).first?.metadata.first("x-tenant") == "acme")
  }

  @Test func staysAnonymousWhenASignInIsRefusedAndSurfacesTheRefusal() async throws {
    let fixture = SessionFixture(held: false)
    fixture.server.handle(loginMethod) { (_: LoginRequest, _) -> LoginResponse in
      throw refusal(.unauthenticated, "invalid credentials", SignInReason.invalidCredentials)
    }

    let (error, states) = try await fixture.run { session, caller in
      let states = await session.states()
      let error = await #expect(throws: PlatformError.self) {
        try await session.signIn(caller.login)
      }
      return (error, await states.first(3))
    }

    #expect(error?.is(SignInReason.invalidCredentials) == true)
    #expect(try await fixture.store.load() == nil)
    #expect(states == [.anonymous, .authenticating, .anonymous])
  }

  @Test func servesACallThatWasWaitingOnASignIn() async throws {
    let fixture = SessionFixture(held: false)
    let gate = Gate()
    fixture.server.handle(loginMethod) { (_: LoginRequest, _) in
      await gate.wait()
      var response = LoginResponse()
      response.token = fakeIssuedToken(now: fixture.clock.now())
      return response
    }

    try await fixture.run { session, caller in
      async let signingIn = session.signIn(caller.login)
      try await eventually { await session.state == .authenticating }
      async let waiting: Void = caller.call(session)
      try await Task.sleep(for: .milliseconds(20))
      gate.open()
      _ = try await (signingIn, waiting)
    }

    #expect(fixture.tokensSent() == ["Bearer access-1"])
  }

  @Test func r6_stillUsesASuccessorItFailedToPersistAndSurfacesTheFailure() async throws {
    let fixture = SessionFixture { now in FailingSaveStore(fakeIssuedToken(now: now)) }
    fixture.handleExchange { _ in fixture.successor(2) }
    await (fixture.store as? FailingSaveStore)?.failSaves()

    try await fixture.run { session, caller in
      fixture.clock.advance(by: hour)
      await #expect(throws: (any Error).self) { try await caller.call(session) }
      try await caller.call(session)
    }

    #expect(fixture.tokensSent() == ["Bearer access-2"])
    #expect(fixture.server.calls(to: exchangeMethod).count == 1)
  }

  @Test func makesAnOptionallyAuthenticatedCallAnonymouslyWhenNothingIsHeld() async throws {
    let fixture = SessionFixture(held: false)

    try await fixture.run { session, caller in
      try await session.callOptionallyAuthenticated(caller.authStatus)
    }

    #expect(fixture.tokensSent() == [nil])
  }

  @Test func makesAnOptionallyAuthenticatedCallWithTheCredentialWhenOneIsHeld() async throws {
    let fixture = SessionFixture()

    try await fixture.run { session, caller in
      try await session.callOptionallyAuthenticated(caller.authStatus)
    }

    #expect(fixture.tokensSent() == ["Bearer access-1"])
  }

  @Test func clearsTheSessionHereAndInTheStore() async throws {
    let fixture = SessionFixture()

    let (held, state) = try await fixture.run { session, _ in
      _ = try await session.held()
      try await session.clear()
      return (try await session.held(), await session.state)
    }

    #expect(held == nil)
    #expect(state == .anonymous)
    #expect(try await fixture.store.load() == nil)
  }
}

@Suite struct SessionRefreshTests {
  @Test func r10_sendsNoKeyAndNeverRetriesAnExchangeWhenOff() async throws {
    let fixture = SessionFixture()
    fixture.handleExchange { _ in throw RPCError(code: .deadlineExceeded, message: "deadline") }

    try await fixture.run { session, caller in
      fixture.clock.advance(by: hour - 10)
      await #expect(throws: PlatformError.self) { try await caller.call(session) }
    }

    #expect(fixture.keysSent() == [nil])
  }

  @Test func putsAThirtySecondDeadlineOnAnExchangeByDefault() {
    #expect(Session.defaultExchangeDeadline == .seconds(30))
  }

  @Test func honoursAConfiguredExchangeDeadline() async throws {
    let fixture = SessionFixture()
    fixture.handleExchange { _ in
      try await Task.sleep(for: .seconds(2))
      return fixture.successor(2)
    }

    let (error, took) = try await fixture.run(exchangeDeadline: .milliseconds(100)) {
      session, caller in
      fixture.clock.advance(by: hour - 10)
      let started = ContinuousClock.now
      let error = await #expect(throws: PlatformError.self) { try await caller.call(session) }
      return (error, ContinuousClock.now - started)
    }

    #expect(error?.code == .deadlineExceeded)
    #expect(took < .seconds(1))
    // A deadline is an ambiguous failure, so the refresh token is gone and the login kept.
    #expect(try await fixture.store.load()?.refreshToken == "")
  }

  @Test func r4_sendsAKeyOnTheFirstAttemptNotJustTheOnesItExpectsToLose() async throws {
    let fixture = SessionFixture()
    fixture.handleExchange { _ in fixture.successor(2) }

    try await fixture.run(idempotentRefresh: true) { session, caller in
      fixture.clock.advance(by: hour)
      try await caller.call(session)
    }

    let key = try #require(fixture.keysSent().first ?? nil)
    #expect(key.wholeMatch(of: /[\x21-\x7e]{1,255}/) != nil)
    #expect(fixture.server.calls(to: exchangeMethod).first?.metadata.first("x-tenant") == "acme")
  }

  @Test func r10_retriesAnAmbiguousExchangeOnceWithTheSameTokenAndTheSameKey() async throws {
    let fixture = SessionFixture()
    fixture.handleExchange { attempt in
      if attempt == 1 { throw RPCError(code: .unavailable, message: "connection reset") }
      return fixture.successor(2)
    }

    try await fixture.run(idempotentRefresh: true) { session, caller in
      fixture.clock.advance(by: hour)
      try await caller.call(session)
    }

    #expect(fixture.refreshTokensPresented(to: exchangeMethod) == ["refresh-1", "refresh-1"])
    let keys = fixture.keysSent()
    #expect(keys.count == 2)
    #expect(keys[0] != nil && keys[0] == keys[1])
    #expect(try await fixture.store.load()?.refreshToken == "refresh-2")
    #expect(fixture.tokensSent() == ["Bearer access-2"])
  }

  @Test func r4_mintsANewKeyForEachLogicalExchange() async throws {
    let fixture = SessionFixture()
    fixture.handleExchange { attempt in fixture.successor(attempt + 1) }

    try await fixture.run(idempotentRefresh: true) { session, caller in
      fixture.clock.advance(by: hour)
      try await caller.call(session)
      fixture.clock.advance(by: hour)
      try await caller.call(session)
    }

    let keys = fixture.keysSent()
    #expect(keys.count == 2)
    #expect(keys[0] != nil && keys[0] != keys[1])
  }

  @Test func r10_retriesOnlyOnceThenKeepsTheAccessTokenAndDropsTheRefreshToken() async throws {
    let fixture = SessionFixture()
    fixture.handleExchange { _ in throw RPCError(code: .deadlineExceeded, message: "deadline") }

    let state = try await fixture.run(idempotentRefresh: true) { session, caller in
      fixture.clock.advance(by: hour - 10)
      await #expect(throws: PlatformError.self) { try await caller.call(session) }
      return await session.state
    }

    #expect(fixture.server.calls(to: exchangeMethod).count == 2)
    #expect(state == .authenticated)
    #expect(try await fixture.store.load()?.refreshToken == "")
  }

  @Test(arguments: [
    RPCError.Code.unauthenticated, .permissionDenied, .invalidArgument, .failedPrecondition,
  ])
  func r10_doesNotRetryARefusedExchange(code: RPCError.Code) async throws {
    let fixture = SessionFixture()
    fixture.handleExchange { _ in throw RPCError(code: code, message: "refused") }

    let error = try await fixture.run(idempotentRefresh: true) { session, caller in
      fixture.clock.advance(by: hour - 10)
      return await #expect(throws: PlatformError.self) { try await caller.call(session) }
    }

    #expect(error?.code == code)
    #expect(fixture.server.calls(to: exchangeMethod).count == 1)
  }

  @Test func r7_signsOutWhenTheKeyedRetryIsRefused() async throws {
    let fixture = SessionFixture()
    fixture.handleExchange { attempt in
      throw RPCError(code: attempt == 1 ? .unavailable : .unauthenticated, message: "x")
    }

    let (error, state) = try await fixture.run(idempotentRefresh: true) { session, caller in
      fixture.clock.advance(by: hour)
      let error = await #expect(throws: PlatformError.self) { try await caller.call(session) }
      return (error, await session.state)
    }

    #expect(error?.code == .unauthenticated)
    #expect(try await fixture.store.load() == nil)
    #expect(state == .anonymous)
  }

  @Test func r10_doesNotRetryOnceTheTenMinuteWindowHasClosed() async throws {
    let fixture = SessionFixture()
    fixture.handleExchange { _ in
      // The process was suspended mid-exchange for longer than the server will honour the key.
      fixture.clock.advance(by: 10 * 60)
      throw RPCError(code: .unavailable, message: "connection reset")
    }

    try await fixture.run(idempotentRefresh: true) { session, caller in
      fixture.clock.advance(by: hour - 20)
      await #expect(throws: PlatformError.self) { try await caller.call(session) }
    }

    #expect(fixture.server.calls(to: exchangeMethod).count == 1)
    #expect(try await fixture.store.load()?.refreshToken == "")
  }
}

/// Box is a value a server handler records for a test to read afterwards.
final class Box<Value: Sendable>: Sendable {
  private let stored: Mutex<Value>

  init(_ value: Value) { stored = Mutex(value) }

  var value: Value {
    get { stored.withLock { $0 } }
    set { stored.withLock { $0 = newValue } }
  }
}
