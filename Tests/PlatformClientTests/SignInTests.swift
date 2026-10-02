import Foundation
import GRPCCore
import PlatformClient
import PlatformClientTesting
import Testing

private typealias Credentials = Primandproper_Platform_Signin_V1_Credentials
private typealias AdminLoginRequest = Primandproper_Platform_Signin_V1_AdminLoginForTokenRequest
private typealias AdminLoginResponse = Primandproper_Platform_Signin_V1_AdminLoginForTokenResponse
private typealias MagicLinkRequest = Primandproper_Platform_Signin_V1_RedeemMagicLinkRequest
private typealias MagicLinkResponse = Primandproper_Platform_Signin_V1_RedeemMagicLinkResponse

private let adminLoginMethod = SignInRPC.Method.AdminLoginForToken.descriptor
private let magicLinkMethod = SignInRPC.Method.RedeemMagicLink.descriptor

private func refuseWithoutASecondFactor() throws -> Never {
  throw refusal(
    .unauthenticated, "a second-factor code is required", SignInReason.secondFactorRequired)
}

@Suite struct SignInTests {
  @Test func signsInWithAUsernameAndAdoptsTheSession() async throws {
    let fixture = SessionFixture(held: false)
    fixture.server.handle(loginMethod) { (_: LoginRequest, _) in
      var response = LoginResponse()
      response.token = fakeIssuedToken(now: fixture.clock.now())
      return response
    }

    let (result, state) = try await fixture.run { session, _ in
      let result = try await session.signIn(
        PasswordSignIn(handle: .username("jeff"), password: "hunter2"))
      return (result, await session.state)
    }

    #expect(result.token?.token == "access-1")
    #expect(
      fixture.server.calls(to: loginMethod).first?.request(as: LoginRequest.self)?.credentials
        == credentials(username: "jeff", password: "hunter2"))
    #expect(try await fixture.store.load()?.token == "access-1")
    #expect(state == .authenticated)
  }

  @Test func sendsAnEmailHandleACodeAndAnAccountWhenItHasThem() async throws {
    let fixture = SessionFixture(held: false)
    fixture.server.handle(loginMethod) { (_: LoginRequest, _) in
      var response = LoginResponse()
      response.token = fakeIssuedToken(now: fixture.clock.now())
      return response
    }

    try await fixture.run { session, _ in
      _ = try await session.signIn(
        PasswordSignIn(
          handle: .emailAddress("j@example.com"), password: "hunter2", totpCode: "123456",
          activeAccountID: "account-2"))
    }

    #expect(
      fixture.server.calls(to: loginMethod).first?.request(as: LoginRequest.self)?.credentials
        == credentials(
          emailAddress: "j@example.com", password: "hunter2", totpCode: "123456",
          activeAccountID: "account-2"))
  }

  @Test func asksForASecondFactorAndResendsTheSameCredentialsWithIt() async throws {
    let fixture = SessionFixture(held: false)
    fixture.server.handle(loginMethod) { (request: LoginRequest, _) in
      guard !request.credentials.totpCode.isEmpty else { try refuseWithoutASecondFactor() }
      var response = LoginResponse()
      response.token = fakeIssuedToken(now: fixture.clock.now())
      return response
    }

    let (stateAsked, second, stateAfter) = try await fixture.run { session, _ in
      let first = try await session.signIn(
        PasswordSignIn(handle: .username("jeff"), password: "hunter2", activeAccountID: "a"))
      let stateAsked = await session.state
      let resend = try #require(first.resend)
      let second = try await resend("654321")
      return (stateAsked, second, await session.state)
    }

    #expect(stateAsked == .anonymous)
    #expect(second.token != nil)
    #expect(
      fixture.server.calls(to: loginMethod).dropFirst().first?.request(as: LoginRequest.self)?
        .credentials
        == credentials(
          username: "jeff", password: "hunter2", totpCode: "654321", activeAccountID: "a"))
    #expect(stateAfter == .authenticated)
  }

  @Test func asksAgainWhenTheResentCodeIsRefusedForTheSameReason() async throws {
    let fixture = SessionFixture(held: false)
    fixture.server.handle(loginMethod) { (_: LoginRequest, _) -> LoginResponse in
      try refuseWithoutASecondFactor()
    }

    let second = try await fixture.run { session, _ in
      let first = try await session.signIn(
        PasswordSignIn(handle: .username("jeff"), password: "hunter2"))
      let resend = try #require(first.resend)
      return try await resend("000000")
    }

    #expect(second.resend != nil)
  }

  @Test func throwsAnyOtherRefusalWithItsReasonToBranchOn() async throws {
    let fixture = SessionFixture(held: false)
    fixture.server.handle(loginMethod) { (_: LoginRequest, _) -> LoginResponse in
      throw refusal(
        .permissionDenied, "your account is suspended until Friday", SignInReason.userSuspended)
    }

    let (error, state) = try await fixture.run { session, _ in
      let error = await #expect(throws: PlatformError.self) {
        try await session.signIn(PasswordSignIn(handle: .username("jeff"), password: "x"))
      }
      return (error, await session.state)
    }

    #expect(error?.is(SignInReason.userSuspended) == true)
    #expect(error?.serverMessage == "your account is suspended until Friday")
    #expect(state == .anonymous)
  }

  @Test func throwsAnUnreasonedUnauthenticatedFromAnOlderServerRatherThanGuessingASecondFactor()
    async throws
  {
    let fixture = SessionFixture(held: false)
    fixture.server.handle(loginMethod) { (_: LoginRequest, _) -> LoginResponse in
      throw RPCError(code: .unauthenticated, message: "a second-factor code is required")
    }

    let error = try await fixture.run { session, _ in
      await #expect(throws: PlatformError.self) {
        try await session.signIn(PasswordSignIn(handle: .username("jeff"), password: "x"))
      }
    }

    #expect(error?.code == .unauthenticated)
    #expect(error?.reason == nil)
  }

  @Test func adminSignInGoesThroughTheAdministrativeDoor() async throws {
    let fixture = SessionFixture(held: false)
    fixture.server.handle(adminLoginMethod) { (_: AdminLoginRequest, _) in
      var response = AdminLoginResponse()
      response.token = fakeIssuedToken(now: fixture.clock.now()) { $0.administrative = true }
      return response
    }

    let result = try await fixture.run { session, _ in
      try await session.adminSignIn(PasswordSignIn(handle: .username("root"), password: "x"))
    }

    #expect(result.token?.administrative == true)
    #expect(fixture.server.calls(to: loginMethod).isEmpty)
  }

  @Test func adminSignInAsksForASecondFactorThroughTheSameDoor() async throws {
    let fixture = SessionFixture(held: false)
    fixture.server.handle(adminLoginMethod) { (request: AdminLoginRequest, _) in
      guard !request.credentials.totpCode.isEmpty else { try refuseWithoutASecondFactor() }
      var response = AdminLoginResponse()
      response.token = fakeIssuedToken(now: fixture.clock.now())
      return response
    }

    let second = try await fixture.run { session, _ in
      let first = try await session.adminSignIn(
        PasswordSignIn(handle: .username("root"), password: "x"))
      let resend = try #require(first.resend)
      return try await resend("1")
    }

    #expect(second.token != nil)
    #expect(fixture.server.calls(to: adminLoginMethod).count == 2)
    #expect(fixture.server.calls(to: loginMethod).isEmpty)
  }

  @Test func redeemMagicLinkSignsInWithTheLinkToken() async throws {
    let fixture = SessionFixture(held: false)
    fixture.server.handle(magicLinkMethod) { (_: MagicLinkRequest, _) in
      var response = MagicLinkResponse()
      response.token = fakeIssuedToken(now: fixture.clock.now())
      return response
    }

    let (result, stored) = try await fixture.run { session, _ in
      let result = try await session.redeemMagicLink(MagicLinkSignIn(token: "link"))
      return (result, try await fixture.store.load())
    }

    #expect(result.token != nil)
    #expect(stored?.token == "access-1")
    #expect(
      fixture.server.calls(to: magicLinkMethod).first?.request(as: MagicLinkRequest.self)
        == magicLink(token: "link"))
  }

  @Test func redeemMagicLinkResendsTheSameLinkTokenWithASecondFactor() async throws {
    let fixture = SessionFixture(held: false)
    fixture.server.handle(magicLinkMethod) { (request: MagicLinkRequest, _) in
      guard !request.totpCode.isEmpty else { try refuseWithoutASecondFactor() }
      var response = MagicLinkResponse()
      response.token = fakeIssuedToken(now: fixture.clock.now())
      return response
    }

    let second = try await fixture.run { session, _ in
      let first = try await session.redeemMagicLink(
        MagicLinkSignIn(token: "link", activeAccountID: "a"))
      let resend = try #require(first.resend)
      return try await resend("42")
    }

    #expect(second.token != nil)
    #expect(
      fixture.server.calls(to: magicLinkMethod).dropFirst().first?.request(
        as: MagicLinkRequest.self)
        == magicLink(token: "link", totpCode: "42", activeAccountID: "a"))
  }
}

private func credentials(
  username: String = "", emailAddress: String = "", password: String, totpCode: String = "",
  activeAccountID: String = ""
) -> Credentials {
  var credentials = Credentials()
  credentials.username = username
  credentials.emailAddress = emailAddress
  credentials.password = password
  credentials.totpCode = totpCode
  credentials.activeAccountID = activeAccountID
  return credentials
}

private func magicLink(token: String, totpCode: String = "", activeAccountID: String = "")
  -> MagicLinkRequest
{
  var request = MagicLinkRequest()
  request.token = token
  request.totpCode = totpCode
  request.activeAccountID = activeAccountID
  return request
}

extension SignInResult {
  fileprivate var token: IssuedToken? {
    guard case .signedIn(let token) = self else { return nil }
    return token
  }

  fileprivate var resend: (@Sendable (String) async throws -> SignInResult)? {
    guard case .secondFactorRequired(let resend) = self else { return nil }
    return resend
  }
}
