import GRPCCore

/// AuthStatus is where a signed-in caller stands: who they are, which accounts they are in, and
/// what they owe.
public typealias AuthStatus = Primandproper_Platform_Signin_V1_AuthStatus

/// RequiredAction is something the signed-in user has to be sent to do. The service signs such
/// users in anyway, since the alternative is a user who cannot reach the form, so routing them
/// there is the client's job.
public enum RequiredAction: String, Sendable, Hashable {
  /// changePassword is a password change an operator forced. From v14.2.0 the server holds it
  /// too, refusing every other call with PASSWORD_CHANGE_REQUIRED, so this is what an app
  /// routes on before it meets that refusal.
  case changePassword = "change_password"
  /// verifyEmail is an unproven address, so an unfinished registration. The remedy is the
  /// mailed link.
  case verifyEmail = "verify_email"
}

/// AuthStatusResult is what `getAuthStatus` answers.
public enum AuthStatusResult: Sendable, Hashable {
  case anonymous
  case authenticated(SignedInStatus)
}

/// SignedInStatus is a signed-in caller's AuthStatus, and what it obliges the app to do.
public struct SignedInStatus: Sendable, Hashable {
  public let status: AuthStatus
  /// requiredActions is what the user must be routed to before anything else, in that order.
  /// Empty for most.
  public let requiredActions: [RequiredAction]
  /// canChangePassword is false for a passwordless user (a passkey, or federated). A
  /// change-password form offered to them cannot work.
  public let canChangePassword: Bool

  public init(status: AuthStatus) {
    var requiredActions: [RequiredAction] = []
    if status.requiresPasswordChange {
      requiredActions.append(.changePassword)
    }
    if !status.emailAddressVerified {
      requiredActions.append(.verifyEmail)
    }
    self.status = status
    self.requiredActions = requiredActions
    self.canChangePassword = status.hasPassword_p
  }
}

/// getAuthStatus asks whether `session` is signed in, and if so who it is and what it owes. It
/// is the one RPC that answers an anonymous caller instead of refusing one, so it is safe to
/// call before knowing whether the credentials are good, and it carries the credential whenever
/// one is held.
///
/// It is read fresh every time and deliberately not cached: the token carries no user and no
/// permissions so that a revoked role takes effect now rather than at the token's expiry, and
/// caching this answer indefinitely would rebuild the frozen permission set that design avoids.
///
/// `twoFactorEnrolled` is readable only here, by a signed-in caller, which is why a sign-in
/// refused for a second factor cannot be resolved from this.
public func getAuthStatus<Transport: ClientTransport>(
  _ session: Session,
  client: GRPCClient<Transport>,
  options: CallOptions = .defaults
) async throws -> AuthStatusResult {
  let signIn = Primandproper_Platform_Signin_V1_SignInService.Client(wrapping: client)
  let response = try await session.callOptionallyAuthenticated { metadata in
    try await signIn.getAuthStatus(.init(), metadata: metadata, options: options)
  }
  guard response.authenticated, response.hasStatus else { return .anonymous }
  return .authenticated(SignedInStatus(status: response.status))
}
