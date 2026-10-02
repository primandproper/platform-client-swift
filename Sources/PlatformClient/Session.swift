import Foundation
import GRPCCore
import os

private typealias SignInService = Primandproper_Platform_Signin_V1_SignInService

/// SessionState is where a Session is in the contract's state machine.
public enum SessionState: Sendable, Hashable {
  case anonymous
  case authenticating
  case authenticated
  case refreshing
}

/// NotSignedInError is what an authenticated call throws when there is no session to make it
/// with.
public struct NotSignedInError: Error, Sendable, CustomStringConvertible {
  public init() {}

  public var description: String { "not signed in" }
}

/// MissingTokenError is a door or an exchange that answered OK with no token. It carries no
/// status, so it is ambiguous: an exchange that answers it abandons the refresh token.
public struct MissingTokenError: Error, Sendable, CustomStringConvertible {
  public let method: MethodDescriptor

  public var description: String { "\(method) answered OK with no token" }
}

/// NoAccountError is a `switchAccount` that named no account to switch to.
public struct NoAccountError: Error, Sendable, CustomStringConvertible {
  public var description: String { "switchAccount needs an account to switch to" }
}

/// TokenResponse is a response from one of the doors that mint a session.
public protocol TokenResponse: Sendable {
  var token: IssuedToken { get }
  var hasToken: Bool { get }
}

extension Primandproper_Platform_Signin_V1_LoginForTokenResponse: TokenResponse {}
extension Primandproper_Platform_Signin_V1_AdminLoginForTokenResponse: TokenResponse {}
extension Primandproper_Platform_Signin_V1_RedeemMagicLinkResponse: TokenResponse {}
extension Primandproper_Platform_Passkeys_V1_FinishLoginResponse: TokenResponse {}

/// Session is the sign-in state machine, and the one thing in a process that holds and
/// refreshes an access token. Every service a process calls, platform's and its own alike, goes
/// through one Session, because two refreshers would present the same refresh token twice,
/// which is reuse, which revokes the login (R1).
///
/// It is an actor, and that is the whole of R1: one refresh at a time, with every concurrent
/// caller awaiting the same exchange. TypeScript's `ExchangeCoordinator` has no counterpart
/// here. It exists because a backend-for-frontend builds a Session per request, so many
/// Sessions hold one refresh token; an app has one process and one Session.
///
/// An exchange runs in a task of its own rather than in the caller that started it, so a
/// caller that is cancelled leaves the exchange to finish for everyone else. Cancelling one
/// partway would turn it into an ambiguous failure and cost the refresh token.
public actor Session {
  /// refreshSkew is how long before an access token's expiry a call refreshes it instead. The
  /// contract fixes it at thirty seconds so that two clients do not differ over a value neither
  /// can derive, so it is not configurable.
  public static let refreshSkew: TimeInterval = 30

  /// defaultExchangeDeadline is generous on purpose. A short deadline on the exchange turns a
  /// slow success into an ambiguous failure, which costs a keyed retry with R10 on and the
  /// refresh token with it off.
  public static let defaultExchangeDeadline: Duration = .seconds(30)

  /// remintWindow is how long after an exchange the server will honour a keyed retry of it. It
  /// is not configurable there.
  static let remintWindow: TimeInterval = 10 * 60

  static let idempotencyKeyHeader = "idempotency-key"

  private typealias Exchange =
    @Sendable (_ refreshToken: String, _ metadata: Metadata, _ options: CallOptions) async throws
    -> IssuedToken?
  private typealias Switch =
    @Sendable (_ refreshToken: String, _ accountID: String) async throws -> IssuedToken?

  private let store: any CredentialStore
  private let clock: any WallClock
  private let authorizer: any Authorizer
  private let idempotentRefresh: Bool
  private let exchangeDeadline: Duration
  private let exchangeCall: Exchange
  private let switchCall: Switch
  private let logger = Logger(
    subsystem: "com.github.primandproper.platform-client", category: "session")

  private var current: IssuedToken?
  /// state is where the session is now. `states()` follows it.
  public private(set) var state: SessionState = .anonymous
  private var loading: Task<Void, any Error>?
  private var signingIn: Task<IssuedToken, any Error>?
  private var refreshing: (id: Int, task: Task<IssuedToken, any Error>)?
  private var flights = 0
  private var observers: [UUID: AsyncStream<SessionState>.Continuation] = [:]

  /// init builds a Session over `client`, which carries its exchanges and switches. Build
  /// `client` with whatever interceptors every call needs, the tenant's among them (R12): the
  /// Session's own calls go through it as well.
  ///
  /// - Parameters:
  ///   - idempotentRefresh: turns on R10. An exchange that fails ambiguously is retried once,
  ///     under the idempotency key the first attempt carried, and the server answers with a
  ///     fresh successor instead of treating it as reuse. It is off unless the deployment says
  ///     its server supports it, because a client cannot tell from the wire. It needs a server
  ///     built from platform-go v14.1.0 or later AND a refresh-token store that implements the
  ///     behaviour (the ones platform-go ships do; a consumer's own may not). Against one that
  ///     does not, a keyed retry is a bare retry: reuse, and the login revoked. Off, an
  ///     ambiguous failure keeps the session until its access token expires and never re-sends
  ///     the refresh token (R5).
  ///   - exchangeDeadline: bounds each exchange attempt. `defaultExchangeDeadline` unless set.
  public init<Transport: ClientTransport>(
    client: GRPCClient<Transport>,
    store: any CredentialStore,
    clock: any WallClock = SystemClock(),
    authorizer: any Authorizer = BearerAuthorizer(),
    idempotentRefresh: Bool = false,
    exchangeDeadline: Duration = Session.defaultExchangeDeadline
  ) {
    self.store = store
    self.clock = clock
    self.authorizer = authorizer
    self.idempotentRefresh = idempotentRefresh
    self.exchangeDeadline = exchangeDeadline
    self.exchangeCall = { refreshToken, metadata, options in
      var request = Primandproper_Platform_Signin_V1_ExchangeRefreshTokenRequest()
      request.refreshToken = refreshToken
      let response = try await SignInService.Client(wrapping: client).exchangeRefreshToken(
        request, metadata: metadata, options: options)
      return response.hasToken ? response.token : nil
    }
    self.switchCall = { refreshToken, accountID in
      var request = Primandproper_Platform_Signin_V1_SwitchAccountRequest()
      request.refreshToken = refreshToken
      request.accountID = accountID
      let response = try await SignInService.Client(wrapping: client).switchAccount(request)
      return response.hasToken ? response.token : nil
    }
  }

  /// states follows the session's state: the one it is in now, then every transition. It is
  /// what a SwiftUI view model observes. Each call answers a stream of its own, which stops
  /// being fed when it is dropped.
  public func states() -> AsyncStream<SessionState> {
    let (stream, continuation) = AsyncStream.makeStream(of: SessionState.self)
    let id = UUID()
    observers[id] = continuation
    continuation.onTermination = { [weak self] _ in
      Task { await self?.stopObserving(id) }
    }
    continuation.yield(state)
    return stream
  }

  /// held answers the session as it stands once any sign-in or refresh in flight has settled,
  /// or nil when there is none. It never refreshes.
  public func held() async throws -> IssuedToken? {
    try await ensureLoaded()
    _ = try? await signingIn?.value
    _ = try? await refreshing?.task.value
    return current
  }

  /// clear forgets the session here and in the store. On its own it ends nothing on the
  /// server: the refresh token stays exchangeable for the rest of its window (R17).
  public func clear() async throws {
    try await end()
  }

  /// call makes an authenticated call, refreshing first if the token is inside the skew.
  /// `body` makes the call with the metadata it is handed, which carries the credential:
  ///
  /// ```swift
  /// let me = try await session.call { metadata in
  ///   try await identity.getSelf(.init(), metadata: metadata)
  /// }
  /// ```
  ///
  /// A call answered UNAUTHENTICATED refreshes once and retries once, and a second
  /// UNAUTHENTICATED ends the session (R3). A status `body` throws is rethrown as a
  /// PlatformError.
  public func call<Result: Sendable>(
    _ body: @Sendable (_ metadata: Metadata) async throws -> Result
  ) async throws -> Result {
    let token = try await accessToken()
    do {
      return try await body(authorizer.credentials(token.token))
    } catch {
      let error = toPlatformError(error)
      guard isUnauthenticated(error) else { throw error }
    }

    let retryWith = try await refreshAfterRefusal(token)
    do {
      return try await body(authorizer.credentials(retryWith.token))
    } catch {
      let error = toPlatformError(error)
      if isUnauthenticated(error) {
        logger.notice("a call was refused again after a refresh; signing out")
        try await end()
      }
      throw error
    }
  }

  /// callOptionallyAuthenticated makes a call that carries the credential whenever a session is
  /// held and none otherwise, for an RPC that answers an anonymous caller rather than refusing
  /// one. A held session is refreshed as `call` would; one that turns out to have ended makes
  /// the call anonymously instead, with empty metadata.
  public func callOptionallyAuthenticated<Result: Sendable>(
    _ body: @Sendable (_ metadata: Metadata) async throws -> Result
  ) async throws -> Result {
    if try await held() != nil {
      do {
        return try await call(body)
      } catch is NotSignedInError {}
    }
    do {
      return try await body([:])
    } catch {
      throw toPlatformError(error)
    }
  }

  /// signIn makes a call to one of the doors that mint a session and adopts what it answers. A
  /// refusal leaves the session as it was, and is thrown as a PlatformError for the caller to
  /// branch on.
  ///
  /// ```swift
  /// try await session.signIn { try await signIn.loginForToken(request) }
  /// ```
  public func signIn<Response: TokenResponse>(
    _ door: @escaping @Sendable () async throws -> Response
  ) async throws -> IssuedToken {
    try await ensureLoaded()
    let attempt = Task { try await self.adopt(from: door) }
    signingIn = attempt
    defer {
      if signingIn == attempt { signingIn = nil }
    }
    return try await attempt.value
  }

  /// switchAccount moves this login to another of the person's accounts, with no password: the
  /// same login, an access token for `accountID`, and every exchange after it staying there.
  /// The accounts a person may name are `getAuthStatus`'s `accountIds`.
  ///
  /// A switch spends the refresh token, so it is a refresh as far as R1 is concerned (R20): it
  /// waits out any exchange in flight and then runs as one, and calls made meanwhile get its
  /// successor.
  ///
  /// An account the person is not in is refused exactly as a dead refresh token is, and unlike
  /// one it leaves the token unspent. So a refused switch exchanges the token before it decides
  /// anything: if the exchange succeeds the login is kept, in the account it was in, and the
  /// refusal is thrown; if the exchange is refused too, the login was over, and the session is
  /// cleared as any refused exchange clears it.
  public func switchAccount(_ accountID: String) async throws -> IssuedToken {
    guard !accountID.isEmpty else { throw NoAccountError() }
    try await ensureLoaded()
    _ = try? await signingIn?.value
    while let flight = refreshing {
      _ = try? await flight.task.value
    }
    return try await fly { try await $0.switchTo(accountID) }
  }

  // MARK: - Tokens

  private func accessToken() async throws -> IssuedToken {
    try await ensureLoaded()
    if let signingIn {
      _ = try? await signingIn.value
    }
    if let refreshing {
      return try await refreshing.task.value
    }

    guard let held = current else { throw NotSignedInError() }
    let now = clock.now()

    if held.refreshToken.isEmpty {
      // A service that stores no refresh tokens: the access token is the whole login, and it
      // ends when it expires.
      if held.hasExpiresAt && now >= held.expiresAt.date {
        try await end()
        throw NotSignedInError()
      }
      return held
    }
    if held.hasRefreshTokenExpiresAt && now >= held.refreshTokenExpiresAt.date {
      logger.info("the refresh token has expired; signing out without a round trip")
      try await end()
      throw NotSignedInError()
    }
    if held.hasExpiresAt && now >= held.expiresAt.date.addingTimeInterval(-Self.refreshSkew) {
      return try await refresh()
    }
    return held
  }

  private func refreshAfterRefusal(_ refused: IssuedToken) async throws -> IssuedToken {
    if let refreshing {
      return try await refreshing.task.value
    }
    if let current, current.token != refused.token {
      // Somebody else refreshed while this call was in flight; retry with what they got.
      return current
    }
    guard let current, !current.refreshToken.isEmpty else {
      try await end()
      throw NotSignedInError()
    }
    return try await refresh()
  }

  private func refresh() async throws -> IssuedToken {
    if let refreshing {
      return try await refreshing.task.value
    }
    return try await fly { try await $0.exchange() }
  }

  /// fly runs `work` as the one flight that spends the refresh token, which every caller
  /// finding it in flight awaits (R1). The flight takes itself down when it lands, so a caller
  /// arriving afterwards never sees a finished one.
  private func fly(
    _ work: @escaping @Sendable (isolated Session) async throws -> IssuedToken
  ) async throws -> IssuedToken {
    flights += 1
    let id = flights
    let task = Task {
      defer { self.land(id) }
      return try await work(self)
    }
    refreshing = (id, task)
    return try await task.value
  }

  private func land(_ id: Int) {
    if refreshing?.id == id { refreshing = nil }
  }

  private func exchange() async throws -> IssuedToken {
    guard let held = current, !held.refreshToken.isEmpty else { throw NotSignedInError() }
    setState(.refreshing)

    let successor: IssuedToken
    do {
      successor = try await exchange(held.refreshToken)
    } catch {
      try await settleFailedExchange(held, error)
      throw error
    }
    try await adopt(successor)
    return successor
  }

  private func switchTo(_ accountID: String) async throws -> IssuedToken {
    guard let held = current, !held.refreshToken.isEmpty else { throw NotSignedInError() }
    setState(.refreshing)

    var refused: PlatformError?
    let successor: IssuedToken
    do {
      do {
        successor = try await switchOnce(held.refreshToken, accountID)
      } catch let error as PlatformError where error.code == .unauthenticated {
        // The account was refused, or the token is dead, and nothing says which. An exchange
        // tells them apart, and the token is still unspent either way.
        refused = error
        successor = try await exchange(held.refreshToken)
      }
    } catch {
      try await settleFailedExchange(held, error)
      throw error
    }

    try await adopt(successor)
    if let refused { throw refused }
    return successor
  }

  private func switchOnce(_ refreshToken: String, _ accountID: String) async throws
    -> IssuedToken
  {
    let token: IssuedToken?
    do {
      token = try await switchCall(refreshToken, accountID)
    } catch {
      throw toPlatformError(error)
    }
    guard let token else {
      throw MissingTokenError(method: SignInService.Method.SwitchAccount.descriptor)
    }
    return token
  }

  /// exchange is one logical exchange of `refreshToken`: an attempt, and with R10 on, one keyed
  /// retry of it.
  private func exchange(_ refreshToken: String) async throws -> IssuedToken {
    // R4: the key is minted once per logical exchange, outside the retry, and sent on the first
    // attempt. A key that was not on the original request cannot be recognised on the retry.
    let key = idempotentRefresh ? UUID().uuidString : nil
    let startedAt = clock.now()

    let token: IssuedToken?
    do {
      token = try await exchangeOnce(refreshToken, key: key)
    } catch {
      // One retry per key: honouring it clears the key, so another would be reuse.
      guard let key, isAmbiguous(error),
        clock.now().timeIntervalSince(startedAt) < Self.remintWindow
      else { throw error }
      logger.info("an exchange failed ambiguously; retrying it once under its key")
      token = try await exchangeOnce(refreshToken, key: key)
    }

    // It carries no status, so it is ambiguous, and the refresh token is abandoned.
    guard let token else {
      throw MissingTokenError(method: SignInService.Method.ExchangeRefreshToken.descriptor)
    }
    return token
  }

  private func exchangeOnce(_ refreshToken: String, key: String?) async throws -> IssuedToken? {
    var options = CallOptions.defaults
    options.timeout = exchangeDeadline
    let metadata: Metadata = key.map { [Self.idempotencyKeyHeader: .string($0)] } ?? [:]
    do {
      return try await exchangeCall(refreshToken, metadata, options)
    } catch {
      throw toPlatformError(error)
    }
  }

  private func settleFailedExchange(_ held: IssuedToken, _ error: any Error) async throws {
    if let error = error as? PlatformError,
      error.code == .unauthenticated || error.code == .permissionDenied
    {
      // R7: signed out, and there is no learning why. PERMISSION_DENIED is the directory
      // refusing them: stop asking.
      logger.notice("the exchange was refused; signing out")
      try await end()
    } else if isAmbiguous(error) {
      try await abandonRefreshToken(held)
    } else {
      // R2: a timeout is not a revocation.
      logger.info("the exchange failed and was not refused; keeping the session")
      setState(.authenticated)
    }
  }

  /// abandonRefreshToken is what an exchange that may have spent the refresh token leaves
  /// behind. Re-sending it bare would be R5's one forbidden act, and not signing out is R2's,
  /// so the session keeps its access token and drops the refresh token, in the store as well so
  /// that a restart cannot re-send it either. That is the valid shape of a service that stores
  /// no refresh tokens: the login lasts until the access token expires.
  private func abandonRefreshToken(_ held: IssuedToken) async throws {
    logger.notice(
      "the exchange may have spent the refresh token; keeping the access token until it expires")
    var remaining = held
    remaining.refreshToken = ""
    remaining.clearRefreshTokenExpiresAt()
    current = remaining
    setState(.authenticated)
    try await store.save(remaining)
  }

  // MARK: - State

  private func adopt<Response: TokenResponse>(
    from door: @Sendable () async throws -> Response
  ) async throws -> IssuedToken {
    setState(.authenticating)
    let response: Response
    do {
      response = try await door()
    } catch {
      setState(current == nil ? .anonymous : .authenticated)
      throw toPlatformError(error)
    }
    guard response.hasToken else {
      setState(current == nil ? .anonymous : .authenticated)
      throw MissingTokenError(method: SignInService.Method.LoginForToken.descriptor)
    }
    try await adopt(response.token)
    return response.token
  }

  /// adopt makes `token` the session. It is saved before anything else happens with it (R6): a
  /// successor that was exchanged and not persisted is a login that ends at the next restart.
  /// If saving fails the token is still used, since it is the only live one, and the failure
  /// is thrown.
  private func adopt(_ token: IssuedToken) async throws {
    do {
      try await store.save(token)
    } catch {
      logger.error("the session could not be saved; using it anyway")
      current = token
      setState(.authenticated)
      throw error
    }
    current = token
    setState(.authenticated)
  }

  private func end() async throws {
    current = nil
    setState(.anonymous)
    try await store.clear()
  }

  private func ensureLoaded() async throws {
    let loading =
      self.loading
      ?? Task {
        let token = try await self.store.load()
        if let token, self.current == nil {
          self.current = token
          self.setState(.authenticated)
        }
      }
    self.loading = loading
    do {
      try await loading.value
    } catch {
      if self.loading == loading { self.loading = nil }
      throw error
    }
  }

  private func setState(_ next: SessionState) {
    guard next != state else { return }
    logger.debug(
      "session: \(String(describing: self.state), privacy: .public) -> \(String(describing: next), privacy: .public)"
    )
    state = next
    for observer in observers.values {
      observer.yield(next)
    }
  }

  private func stopObserving(_ id: UUID) {
    observers[id] = nil
  }
}

private func isUnauthenticated(_ error: any Error) -> Bool {
  (error as? PlatformError)?.code == .unauthenticated
}
