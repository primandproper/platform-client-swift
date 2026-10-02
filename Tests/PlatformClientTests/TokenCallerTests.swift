import GRPCCore
import PlatformClient
import PlatformClientTesting
import Testing

private typealias SignIn = Primandproper_Platform_Signin_V1_SignInService
private typealias GetSelf = SignIn.Method.GetSelf
private typealias Exchange = SignIn.Method.ExchangeRefreshToken

private let tenant = ConstantMetadataInterceptor(["x-tenant": "acme"])

/// server answers GetSelf, and answers an exchange too, so that a caller attempting one would
/// be seen doing it rather than refused as unimplemented.
private func server() -> FakeServer {
  FakeServer()
    .handle(GetSelf.descriptor) { (_: GetSelf.Input, _) in GetSelf.Output() }
    .handle(Exchange.descriptor) { (_: Exchange.Input, _) in Exchange.Output() }
}

private struct APITokenAuthorizer: Authorizer {
  func credentials(_ token: String) -> Metadata { ["x-api-token": "\(token)"] }
}

private struct ConnectionReset: Error {}

@Suite struct TokenCallerTests {
  @Test func sendsTheTokenItIsGivenWithTheTenantEntries() async throws {
    let server = server()
    let caller = TokenCaller()

    try await server.run(interceptors: [tenant]) { client in
      _ = try await caller.call("access-1") { metadata in
        try await SignIn.Client(wrapping: client).getSelf(.init(), metadata: metadata)
      }
    }

    let sent = try #require(server.calls(to: GetSelf.descriptor).first).metadata
    #expect(Array(sent[stringValues: "authorization"]) == ["Bearer access-1"])
    #expect(Array(sent[stringValues: "x-tenant"]) == ["acme"])
  }

  @Test func sendsTheTenantEntriesOnAnAnonymousCallTooAndNoCredential() async throws {
    let server = server()
    let caller = TokenCaller()

    try await server.run(interceptors: [tenant]) { client in
      _ = try await caller.callAnonymous {
        try await SignIn.Client(wrapping: client).getSelf(.init())
      }
    }

    let sent = try #require(server.calls(to: GetSelf.descriptor).first).metadata
    #expect(Array(sent[stringValues: "x-tenant"]) == ["acme"])
    #expect(Array(sent[stringValues: "authorization"]).isEmpty)
  }

  @Test func carriesTheTokenHoweverItsAuthorizerSaysTo() async throws {
    let server = server()
    let caller = TokenCaller(authorizer: APITokenAuthorizer())

    try await server.run { client in
      _ = try await caller.call("access-1", metadata: ["idempotency-key": "key-1"]) {
        metadata in
        try await SignIn.Client(wrapping: client).getSelf(.init(), metadata: metadata)
      }
    }

    let sent = try #require(server.calls(to: GetSelf.descriptor).first).metadata
    #expect(Array(sent[stringValues: "x-api-token"]) == ["access-1"])
    #expect(Array(sent[stringValues: "idempotency-key"]) == ["key-1"])
    #expect(Array(sent[stringValues: "authorization"]).isEmpty)
  }

  @Test func replacesAPerCallEntryNamedLikeTheCredential() async throws {
    let server = server()
    let caller = TokenCaller()

    try await server.run { client in
      _ = try await caller.call("access-1", metadata: ["authorization": "Bearer stale"]) {
        metadata in
        try await SignIn.Client(wrapping: client).getSelf(.init(), metadata: metadata)
      }
    }

    let sent = try #require(server.calls(to: GetSelf.descriptor).first).metadata
    #expect(Array(sent[stringValues: "authorization"]) == ["Bearer access-1"])
  }

  @Test func surfacesUnauthenticatedWithoutAnExchangeOrARetry() async throws {
    let server = server().handle(GetSelf.descriptor) {
      (_: GetSelf.Input, _) -> GetSelf.Output in
      throw RPCError(code: .unauthenticated, message: "token expired")
    }
    let caller = TokenCaller()

    let error = try await server.run(interceptors: [tenant]) { client in
      await #expect(throws: PlatformError.self) {
        try await caller.call("access-1") { metadata in
          try await SignIn.Client(wrapping: client).getSelf(.init(), metadata: metadata)
        }
      }
    }

    #expect(error?.code == .unauthenticated)
    #expect(error?.serverMessage == "token expired")
    #expect(server.calls(to: Exchange.descriptor).isEmpty)
    #expect(server.calls.count == 1)
  }

  @Test func passesAFailureThatCarriedNoStatusThroughAsItWas() async {
    let caller = TokenCaller()

    await #expect(throws: ConnectionReset.self) {
      try await caller.call("access-1") { _ in throw ConnectionReset() }
    }
  }
}
