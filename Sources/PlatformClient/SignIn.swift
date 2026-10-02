import GRPCCore

/// Handle names who is signing in: a username or an email address, never both and never
/// neither.
public enum Handle: Sendable, Hashable {
  case username(String)
  case emailAddress(String)
}

/// PasswordSignIn is a sign-in through one of the password doors.
public struct PasswordSignIn: Sendable, Hashable {
  public var handle: Handle
  public var password: String
  /// totpCode is sent whenever there is one. It is required from a user with a proven second
  /// factor and ignored for everybody else, so sending it when the user typed one is always
  /// correct.
  public var totpCode: String?
  /// activeAccountID is which account the token is for; nil means the user's default. Moving a
  /// signed-in user to another account is `Session.switchAccount`, which keeps the login.
  public var activeAccountID: String?

  public init(
    handle: Handle, password: String, totpCode: String? = nil, activeAccountID: String? = nil
  ) {
    self.handle = handle
    self.password = password
    self.totpCode = totpCode
    self.activeAccountID = activeAccountID
  }
}

/// MagicLinkSignIn is a sign-in with the token a mailed link carried.
public struct MagicLinkSignIn: Sendable, Hashable {
  public var token: String
  public var totpCode: String?
  public var activeAccountID: String?

  public init(token: String, totpCode: String? = nil, activeAccountID: String? = nil) {
    self.token = token
    self.totpCode = totpCode
    self.activeAccountID = activeAccountID
  }
}

/// SignInResult is a sign-in that either minted a session or needs a second-factor code first.
/// `resend` repeats the same sign-in with the code, so the app never asks the person to retype
/// a password.
///
/// Every other refusal is thrown as a PlatformError to branch on by reason or code (R11, R13).
/// Against a server older than v14.1.0 a refusal carries no reason, so a second-factor prompt is
/// indistinguishable from a wrong password and is thrown as a plain UNAUTHENTICATED; a sign-in
/// form with an optional code field, sent whenever filled, needs no branch at all.
public enum SignInResult: Sendable {
  case signedIn(IssuedToken)
  case secondFactorRequired(resend: @Sendable (_ totpCode: String) async throws -> SignInResult)
}

extension Session {
  /// signIn signs in with a password through `LoginForToken`.
  public func signIn(_ request: PasswordSignIn) async throws -> SignInResult {
    let client = signInClient
    var message = Primandproper_Platform_Signin_V1_LoginForTokenRequest()
    message.credentials = credentials(request)
    return try await attempt(
      { [message] in try await client.loginForToken(message) },
      resend: { totpCode in
        var request = request
        request.totpCode = totpCode
        return try await self.signIn(request)
      })
  }

  /// adminSignIn signs in through the administrative door, `AdminLoginForToken`.
  public func adminSignIn(_ request: PasswordSignIn) async throws -> SignInResult {
    let client = signInClient
    var message = Primandproper_Platform_Signin_V1_AdminLoginForTokenRequest()
    message.credentials = credentials(request)
    return try await attempt(
      { [message] in try await client.adminLoginForToken(message) },
      resend: { totpCode in
        var request = request
        request.totpCode = totpCode
        return try await self.adminSignIn(request)
      })
  }

  /// redeemMagicLink signs in with the token a mailed link carried.
  public func redeemMagicLink(_ request: MagicLinkSignIn) async throws -> SignInResult {
    let client = signInClient
    var message = Primandproper_Platform_Signin_V1_RedeemMagicLinkRequest()
    message.token = request.token
    message.totpCode = request.totpCode ?? ""
    message.activeAccountID = request.activeAccountID ?? ""
    return try await attempt(
      { [message] in try await client.redeemMagicLink(message) },
      resend: { totpCode in
        var request = request
        request.totpCode = totpCode
        return try await self.redeemMagicLink(request)
      })
  }

  private func attempt<Response: TokenResponse>(
    _ door: @escaping @Sendable () async throws -> Response,
    resend: @escaping @Sendable (_ totpCode: String) async throws -> SignInResult
  ) async throws -> SignInResult {
    guard let token = try await signInUnlessSecondFactor(door) else {
      return .secondFactorRequired(resend: resend)
    }
    return .signedIn(token)
  }

  /// signInUnlessSecondFactor is `signIn(_ door:)`, answering nil rather than throwing when the
  /// door refused for a second factor. Every door that can ask for one branches on it the same
  /// way, by reason and never by code.
  func signInUnlessSecondFactor<Response: TokenResponse>(
    _ door: @escaping @Sendable () async throws -> Response
  ) async throws -> IssuedToken? {
    do {
      return try await signIn(door)
    } catch let error as PlatformError where error.is(SignInReason.secondFactorRequired) {
      logger.info("a sign-in needs a second factor")
      return nil
    }
  }
}

private func credentials(_ request: PasswordSignIn) -> Primandproper_Platform_Signin_V1_Credentials
{
  var credentials = Primandproper_Platform_Signin_V1_Credentials()
  switch request.handle {
  case .username(let username): credentials.username = username
  case .emailAddress(let emailAddress): credentials.emailAddress = emailAddress
  }
  credentials.password = request.password
  credentials.totpCode = request.totpCode ?? ""
  credentials.activeAccountID = request.activeAccountID ?? ""
  return credentials
}
