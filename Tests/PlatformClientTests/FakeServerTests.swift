import GRPCCore
import GRPCProtobuf
import PlatformClient
import PlatformClientTesting
import Testing

private typealias SignIn = Primandproper_Platform_Signin_V1_SignInService
private typealias Request = Primandproper_Platform_Signin_V1_GetAuthStatusRequest
private typealias Response = Primandproper_Platform_Signin_V1_GetAuthStatusResponse
private let getAuthStatus = SignIn.Method.GetAuthStatus.descriptor

@Suite struct FakeServerTests {
  @Test func answersAMethodWithNoHandlerUnimplemented() async throws {
    let server = FakeServer()

    let error = try await server.run { client in
      await #expect(throws: RPCError.self) {
        try await SignIn.Client(wrapping: client).getAuthStatus(.init())
      }
    }

    #expect(error?.code == .unimplemented)
  }

  @Test func deliversAThrownStatusWithItsDetails() async throws {
    let server = FakeServer().handle(getAuthStatus) { (_: Request, _) -> Response in
      throw GoogleRPCStatus(
        code: .unauthenticated,
        message: "wrong password",
        details: .errorInfo(reason: "INVALID_CREDENTIALS", domain: "example.com"))
    }

    let error = try await server.run { client in
      await #expect(throws: RPCError.self) {
        try await SignIn.Client(wrapping: client).getAuthStatus(.init())
      }
    }

    let status = try #require(try error?.unpackGoogleRPCStatus())
    #expect(status.code == .unauthenticated)
    #expect(status.details.first?.errorInfo?.reason == "INVALID_CREDENTIALS")
  }

  @Test func answersWithTheHandlerItHasNow() async throws {
    let server = FakeServer().handle(getAuthStatus) { (_: Request, _) -> Response in
      var response = Response()
      response.authenticated = false
      return response
    }

    let answers = try await server.run { client in
      let signIn = SignIn.Client(wrapping: client)
      let first = try await signIn.getAuthStatus(.init())
      server.handle(getAuthStatus) { (_: Request, _) -> Response in
        var response = Response()
        response.authenticated = true
        return response
      }
      let second = try await signIn.getAuthStatus(.init())
      return [first.authenticated, second.authenticated]
    }

    #expect(answers == [false, true])
    #expect(server.calls(to: getAuthStatus).count == 2)
  }
}
