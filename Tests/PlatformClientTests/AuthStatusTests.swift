import Foundation
import GRPCCore
import PlatformClient
import PlatformClientTesting
import Testing

@Suite struct AuthStatusTests {
  @Test func asksAnonymouslyWhenNoSessionIsHeldAndIsAnsweredNo() async throws {
    let fixture = answering(SessionFixture(held: false))

    let result = try await fixture.run { session, _ in try await session.getAuthStatus() }

    #expect(result == .anonymous)
    let sent = try #require(fixture.server.calls(to: authStatusMethod).first).metadata
    #expect(sent.first("authorization") == nil)
    #expect(sent.first("x-tenant") == "acme")
  }

  @Test func carriesTheCredentialWhenASessionIsHeld() async throws {
    let fixture = answering(SessionFixture())

    let result = try await fixture.run { session, _ in try await session.getAuthStatus() }

    #expect(result == .authenticated(SignedInStatus(status: status())))
    #expect(fixture.tokensSent() == ["Bearer access-1"])
  }

  @Test func refreshesAHeldSessionInsideTheSkewBeforeAsking() async throws {
    let fixture = answering(SessionFixture())
    fixture.handleExchange { _ in fixture.successor(2) }

    try await fixture.run { session, _ in
      fixture.clock.advance(by: hour)
      _ = try await session.getAuthStatus()
    }

    #expect(fixture.server.calls(to: exchangeMethod).count == 1)
    #expect(fixture.tokensSent() == ["Bearer access-2"])
  }

  @Test func asksAnonymouslyWhenTheHeldSessionTurnsOutToHaveEnded() async throws {
    let fixture = answering(SessionFixture())

    let (result, state) = try await fixture.run { session, _ in
      fixture.clock.advance(by: 24 * hour)
      return (try await session.getAuthStatus(), await session.state)
    }

    #expect(result == .anonymous)
    let sent = try #require(fixture.server.calls(to: authStatusMethod).first).metadata
    #expect(sent.first("authorization") == nil)
    #expect(sent.first("x-tenant") == "acme")
    #expect(state == .anonymous)
  }

  @Test(
    arguments: [
      (false, true, []),
      (true, true, [.changePassword]),
      (false, false, [.verifyEmail]),
      (true, false, [.changePassword, .verifyEmail]),
    ] as [(Bool, Bool, [RequiredAction])])
  func routesOnWhatTheAnswerObliges(
    requiresPasswordChange: Bool, emailAddressVerified: Bool, expected: [RequiredAction]
  ) async throws {
    let fixture = answering(
      SessionFixture(),
      status {
        $0.requiresPasswordChange = requiresPasswordChange
        $0.emailAddressVerified = emailAddressVerified
      })

    let result = try await fixture.run { session, _ in try await session.getAuthStatus() }

    #expect(signedIn(result)?.requiredActions == expected)
  }

  @Test func doesNotOfferAPasswordChangeToSomebodyWhoHasNoPassword() async throws {
    let fixture = answering(SessionFixture(), status { $0.hasPassword_p = false })

    let result = try await fixture.run { session, _ in try await session.getAuthStatus() }

    #expect(signedIn(result)?.canChangePassword == false)
  }

  @Test func asksTheServerEveryTimeRatherThanCachingTheAnswer() async throws {
    let fixture = answering(SessionFixture())

    try await fixture.run { session, _ in
      _ = try await session.getAuthStatus()
      _ = try await session.getAuthStatus()
    }

    #expect(fixture.server.calls(to: authStatusMethod).count == 2)
  }
}

private func status(_ configure: (inout AuthStatus) -> Void = { _ in }) -> AuthStatus {
  var status = AuthStatus()
  status.activeAccountID = "account-1"
  status.accountIds = ["account-1", "account-2"]
  status.hasPassword_p = true
  status.twoFactorEnrolled = false
  status.requiresPasswordChange = false
  status.emailAddressVerified = true
  configure(&status)
  return status
}

/// answering makes the fixture's server answer GetAuthStatus as the real one does: `answer` to
/// a caller carrying a credential, and not signed in to one carrying none.
private func answering(_ fixture: SessionFixture, _ answer: AuthStatus = status())
  -> SessionFixture
{
  fixture.server.handle(authStatusMethod) { (_: AuthStatusRequest, metadata) in
    var response = AuthStatusResponse()
    if metadata.first("authorization") != nil {
      response.authenticated = true
      response.status = answer
    }
    return response
  }
  return fixture
}

private func signedIn(_ result: AuthStatusResult) -> SignedInStatus? {
  guard case .authenticated(let signedIn) = result else { return nil }
  return signedIn
}
