import GRPCCore
import PlatformClient
import PlatformClientTesting
import Testing

private typealias SignIn = Primandproper_Platform_Signin_V1_SignInService
private let getAuthStatus = SignIn.Method.GetAuthStatus.descriptor

private func serverAnsweringAuthStatus() -> FakeServer {
  FakeServer().handle(getAuthStatus) {
    (_: Primandproper_Platform_Signin_V1_GetAuthStatusRequest, _) in
    Primandproper_Platform_Signin_V1_GetAuthStatusResponse()
  }
}

@Suite struct ConstantMetadataInterceptorTests {
  private let tenant = ConstantMetadataInterceptor(["x-tenant": "acme"])

  @Test func sendsTheEntriesOnACallThatCarriesNoMetadataOfItsOwn() async throws {
    let server = serverAnsweringAuthStatus()

    try await server.run(interceptors: [tenant]) { client in
      _ = try await SignIn.Client(wrapping: client).getAuthStatus(.init())
    }

    let sent = try #require(server.calls(to: getAuthStatus).first).metadata
    #expect(Array(sent[stringValues: "x-tenant"]) == ["acme"])
  }

  @Test func mergesTheEntriesWithACallThatCarriesItsOwn() async throws {
    let server = serverAnsweringAuthStatus()

    try await server.run(interceptors: [tenant]) { client in
      _ = try await SignIn.Client(wrapping: client).getAuthStatus(
        .init(), metadata: ["authorization": "Bearer abc"])
    }

    let sent = try #require(server.calls(to: getAuthStatus).first).metadata
    #expect(Array(sent[stringValues: "x-tenant"]) == ["acme"])
    #expect(Array(sent[stringValues: "authorization"]) == ["Bearer abc"])
  }

  @Test func isNotReplacedByAPerCallEntryOfTheSameName() async throws {
    let server = serverAnsweringAuthStatus()

    try await server.run(interceptors: [tenant]) { client in
      _ = try await SignIn.Client(wrapping: client).getAuthStatus(
        .init(), metadata: ["x-tenant": "globex"])
    }

    let sent = try #require(server.calls(to: getAuthStatus).first).metadata
    #expect(Array(sent[stringValues: "x-tenant"]) == ["acme"])
  }
}
