import Foundation
import GRPCCore
import PlatformClient
import PlatformClientTesting
import Synchronization

typealias SignInRPC = Primandproper_Platform_Signin_V1_SignInService
typealias AuthStatusRequest = Primandproper_Platform_Signin_V1_GetAuthStatusRequest
typealias AuthStatusResponse = Primandproper_Platform_Signin_V1_GetAuthStatusResponse
typealias ExchangeRequest = Primandproper_Platform_Signin_V1_ExchangeRefreshTokenRequest
typealias ExchangeResponse = Primandproper_Platform_Signin_V1_ExchangeRefreshTokenResponse
typealias SwitchRequest = Primandproper_Platform_Signin_V1_SwitchAccountRequest
typealias SwitchResponse = Primandproper_Platform_Signin_V1_SwitchAccountResponse
typealias LoginRequest = Primandproper_Platform_Signin_V1_LoginForTokenRequest
typealias LoginResponse = Primandproper_Platform_Signin_V1_LoginForTokenResponse

let authStatusMethod = SignInRPC.Method.GetAuthStatus.descriptor
let exchangeMethod = SignInRPC.Method.ExchangeRefreshToken.descriptor
let switchMethod = SignInRPC.Method.SwitchAccount.descriptor
let loginMethod = SignInRPC.Method.LoginForToken.descriptor

let hour: TimeInterval = 60 * 60

/// SessionFixture is a Session over a FakeServer that answers every sign-in method this suite
/// calls: GetAuthStatus with OK, and the rest UNIMPLEMENTED until a test says otherwise.
struct SessionFixture {
  let clock = FakeClock()
  let server = FakeServer()
  let store: any CredentialStore

  init(held: Bool = true, store: ((Date) -> any CredentialStore)? = nil) {
    let clock = self.clock
    self.store =
      store?(clock.now()) ?? MemoryCredentialStore(held ? fakeIssuedToken(now: clock.now()) : nil)
    server
      .handle(authStatusMethod) { (_: AuthStatusRequest, _) in AuthStatusResponse() }
      .handle(exchangeMethod) { (_: ExchangeRequest, _) -> ExchangeResponse in
        throw RPCError(code: .unimplemented, message: "exchange")
      }
      .handle(switchMethod) { (_: SwitchRequest, _) -> SwitchResponse in
        throw RPCError(code: .unimplemented, message: "switch")
      }
      .handle(loginMethod) { (_: LoginRequest, _) -> LoginResponse in
        throw RPCError(code: .unimplemented, message: "login")
      }
  }

  /// run hands `body` a Session built over the server, and a way to make an authenticated call
  /// through it. The client sends the tenant on every call, as an app's would.
  @discardableResult
  func run<Result: Sendable>(
    idempotentRefresh: Bool = false,
    exchangeDeadline: Duration = Session.defaultExchangeDeadline,
    _ body: @Sendable (_ session: Session, _ client: Caller) async throws -> Result
  ) async throws -> Result {
    let store = self.store
    let clock = self.clock
    return try await server.run(interceptors: [ConstantMetadataInterceptor(["x-tenant": "acme"])]) {
      client in
      let session = Session(
        client: client, store: store, clock: clock, idempotentRefresh: idempotentRefresh,
        exchangeDeadline: exchangeDeadline)
      return try await body(
        session,
        Caller(
          authStatus: { metadata in
            _ = try await SignInRPC.Client(wrapping: client).getAuthStatus(
              .init(), metadata: metadata)
          },
          login: {
            try await SignInRPC.Client(wrapping: client).loginForToken(.init())
          },
          getAuthStatus: { session in
            try await PlatformClient.getAuthStatus(session, client: client)
          }))
    }
  }

  /// handleExchange answers every exchange with what `answer` returns, counting attempts from 1.
  func handleExchange(_ answer: @escaping @Sendable (Int) async throws -> IssuedToken) {
    let attempts = Mutex(0)
    server.handle(exchangeMethod) { (_: ExchangeRequest, _) -> ExchangeResponse in
      let attempt = attempts.withLock {
        $0 += 1
        return $0
      }
      var response = ExchangeResponse()
      response.token = try await answer(attempt)
      return response
    }
  }

  func successor(_ n: Int, account: String = "account-1") -> IssuedToken {
    fakeIssuedToken(now: clock.now()) {
      $0.token = "access-\(n)"
      $0.refreshToken = "refresh-\(n)"
      $0.tokenID = "jti-\(n)"
      $0.activeAccountID = account
    }
  }

  func tokensSent(to method: MethodDescriptor = authStatusMethod) -> [String?] {
    server.calls(to: method).map { $0.metadata.first("authorization") }
  }

  func keysSent() -> [String?] {
    server.calls(to: exchangeMethod).map { $0.metadata.first("idempotency-key") }
  }

  func refreshTokensPresented(to method: MethodDescriptor) -> [String] {
    server.calls(to: method).compactMap {
      $0.request(as: ExchangeRequest.self)?.refreshToken
        ?? $0.request(as: SwitchRequest.self)?.refreshToken
    }
  }
}

/// Caller makes the calls a test makes through a Session.
struct Caller: Sendable {
  let authStatus: @Sendable (Metadata) async throws -> Void
  let login: @Sendable () async throws -> LoginResponse
  let getAuthStatus: @Sendable (Session) async throws -> AuthStatusResult

  func call(_ session: Session) async throws {
    try await session.call(authStatus)
  }
}

/// Gate holds whoever waits on it until it is opened.
final class Gate: Sendable {
  private let state = Mutex<(open: Bool, waiters: [CheckedContinuation<Void, Never>])>(
    (false, []))

  func wait() async {
    await withCheckedContinuation { continuation in
      let open = state.withLock { state in
        if !state.open { state.waiters.append(continuation) }
        return state.open
      }
      if open { continuation.resume() }
    }
  }

  func open() {
    let waiters = state.withLock { state in
      state.open = true
      defer { state.waiters = [] }
      return state.waiters
    }
    for waiter in waiters { waiter.resume() }
  }
}

/// eventually waits for `condition` to hold, for up to two seconds.
func eventually(_ condition: @Sendable () async -> Bool) async throws {
  for _ in 0..<2000 {
    if await condition() { return }
    try await Task.sleep(for: .milliseconds(1))
  }
  struct TimedOut: Error {}
  throw TimedOut()
}

/// FailingSaveStore is a store whose saves fail while `failing` is set.
actor FailingSaveStore: CredentialStore {
  private var token: IssuedToken?
  private var failing = false

  init(_ token: IssuedToken?) { self.token = token }

  func failSaves() { failing = true }

  func load() -> IssuedToken? { token }

  func save(_ token: IssuedToken) throws {
    struct DiskFull: Error {}
    if failing { throw DiskFull() }
    self.token = token
  }

  func clear() { token = nil }
}

extension Metadata {
  func first(_ key: String) -> String? {
    self[stringValues: key].first(where: { _ in true })
  }
}

extension AsyncStream {
  /// first answers the stream's first `count` elements.
  func first(_ count: Int) async -> [Element] {
    var iterator = makeAsyncIterator()
    var elements: [Element] = []
    while elements.count < count, let next = await iterator.next() {
      elements.append(next)
    }
    return elements
  }
}
