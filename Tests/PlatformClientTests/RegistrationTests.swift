import GRPCCore
import PlatformClient
import PlatformClientTesting
import Synchronization
import Testing

private typealias SignIn = Primandproper_Platform_Signin_V1_SignInService
private typealias VerifyEmail = SignIn.Method.VerifyEmailAddress
private typealias Attach = SignIn.Method.AttachPassword
private typealias MagicLink = SignIn.Method.RequestMagicLink

private let tenant = ConstantMetadataInterceptor(["x-tenant": "acme"])

@Suite struct VerifyEmailAddressTests {
  @Test func verifiesWithTheLinkTokenAloneAnonymously() async throws {
    let server = FakeServer().handle(VerifyEmail.descriptor) { (_: VerifyEmail.Input, _) in
      VerifyEmail.Output()
    }

    let result = try await server.run(interceptors: [tenant]) { client in
      try await verifyEmailAddress(client, token: "link")
    }

    #expect(result == .verified)
    let sent = try #require(server.calls(to: VerifyEmail.descriptor).first)
    #expect(sent.request(as: VerifyEmail.Input.self)?.token == "link")
    #expect(Array(sent.metadata[stringValues: "x-tenant"]) == ["acme"])
    #expect(Array(sent.metadata[stringValues: "authorization"]).isEmpty)
  }

  @Test func answersADeadLinkAsOneWhateverMadeItDead() async throws {
    let server = FakeServer().handle(VerifyEmail.descriptor) {
      (_: VerifyEmail.Input, _) -> VerifyEmail.Output in
      throw refusal(.unauthenticated, "invalid credentials", SignInReason.invalidCredentials)
    }

    let result = try await server.run(interceptors: [tenant]) { client in
      try await verifyEmailAddress(client, token: "link")
    }

    #expect(result == .deadLink(message: "invalid credentials"))
  }

  @Test func throwsAnythingThatIsNotADeadLink() async throws {
    let server = FakeServer().handle(VerifyEmail.descriptor) {
      (_: VerifyEmail.Input, _) -> VerifyEmail.Output in
      throw RPCError(code: .unavailable, message: "unavailable")
    }

    let error = try await server.run(interceptors: [tenant]) { client in
      await #expect(throws: PlatformError.self) {
        try await verifyEmailAddress(client, token: "link")
      }
    }

    #expect(error?.code == .unavailable)
  }
}

@Suite struct AttachPasswordTests {
  @Test func attachesAPasswordWithTheLinkToken() async throws {
    let server = FakeServer().handle(Attach.descriptor) { (_: Attach.Input, _) in
      Attach.Output()
    }

    let result = try await server.run(interceptors: [tenant]) { client in
      try await attachPassword(client, token: "link", newPassword: "correct horse")
    }

    #expect(result == .attached)
    let sent = try #require(server.calls(to: Attach.descriptor).first)
    #expect(sent.request(as: Attach.Input.self)?.token == "link")
    #expect(sent.request(as: Attach.Input.self)?.newPassword == "correct horse")
    #expect(server.calls.count == 1)
  }

  @Test func answersAnAccountThatAlreadyHasAPasswordWithTheReasonNotAsADeadLink() async throws {
    let server = FakeServer().handle(Attach.descriptor) {
      (_: Attach.Input, _) -> Attach.Output in
      throw refusal(
        .failedPrecondition, "a password is already set", SignInReason.passwordAlreadySet)
    }

    let result = try await server.run(interceptors: [tenant]) { client in
      try await attachPassword(client, token: "link", newPassword: "x")
    }

    #expect(result == .passwordAlreadySet(message: "a password is already set"))
  }

  @Test func answersADeadLinkAsOne() async throws {
    let server = FakeServer().handle(Attach.descriptor) {
      (_: Attach.Input, _) -> Attach.Output in
      throw RPCError(code: .unauthenticated, message: "invalid credentials")
    }

    let result = try await server.run(interceptors: [tenant]) { client in
      try await attachPassword(client, token: "link", newPassword: "x")
    }

    #expect(result == .deadLink(message: "invalid credentials"))
  }

  @Test func throwsAFailedPreconditionThatCarriesNoReasonRatherThanGuessingFromItsMessage()
    async throws
  {
    let server = FakeServer().handle(Attach.descriptor) {
      (_: Attach.Input, _) -> Attach.Output in
      throw RPCError(code: .failedPrecondition, message: "a password is already set")
    }

    let error = try await server.run(interceptors: [tenant]) { client in
      await #expect(throws: PlatformError.self) {
        try await attachPassword(client, token: "link", newPassword: "x")
      }
    }

    #expect(error?.code == .failedPrecondition)
  }
}

@Suite struct RequestMagicLinkTests {
  @Test func givesACallerTheSameOutcomeForAnAddressSomebodyHoldsAndOneNobodyDoes() async throws {
    let mailed = Mutex<[String]>([])
    let server = FakeServer().handle(MagicLink.descriptor) {
      (request: MagicLink.Input, _) -> MagicLink.Output in
      if request.emailAddress == "held@example.com" {
        mailed.withLock { $0.append(request.emailAddress) }
      }
      return MagicLink.Output()
    }

    let (forHeld, forNobody) = try await server.run(interceptors: [tenant]) { client in
      (
        try await requestMagicLink(client, emailAddress: "held@example.com"),
        try await requestMagicLink(client, emailAddress: "nobody@example.com")
      )
    }

    #expect(mailed.withLock { $0 } == ["held@example.com"])
    #expect(type(of: forHeld) == Void.self)
    #expect(type(of: forNobody) == Void.self)
    let sent = try #require(server.calls(to: MagicLink.descriptor).first).metadata
    #expect(Array(sent[stringValues: "x-tenant"]) == ["acme"])
  }
}
