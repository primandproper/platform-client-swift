import GRPCCore

private typealias SignInService = Primandproper_Platform_Signin_V1_SignInService

// Register has no helper: it is one anonymous call that mints no session, so a sign-up screen
// calls `SignInService.Client.register` through `TokenCaller.callAnonymous`, and branches on
// `registrationRefused` and `registrationClosed`. What follows it, and is anonymous, is here.

/// EmailVerification is what answering a mailed verification link came to.
public enum EmailVerification: Sendable, Hashable {
  case verified
  /// deadLink is a link that cannot be answered. Expired, already answered and never issued are
  /// one answer, and there is no verification token in any response to read one back from: it
  /// only ever travels to the person it is about.
  case deadLink(message: String)
}

/// PasswordAttachment is what answering a mailed attach-a-password link came to.
public enum PasswordAttachment: Sendable, Hashable {
  case attached
  /// deadLink is a link that cannot be answered, as `EmailVerification.deadLink` is.
  case deadLink(message: String)
  /// passwordAlreadySet is an attach refused because the account already has a password. The
  /// remedy is the password reset flow, not this one: attaching exists for somebody who
  /// registered without a password.
  case passwordAlreadySet(message: String)
}

/// verifyEmailAddress answers a mailed verification link: it proves the address and finishes
/// the registration. The link's token is the whole of its authority.
public func verifyEmailAddress(
  _ client: GRPCClient<some ClientTransport>,
  token: String,
  options: CallOptions = .defaults
) async throws -> EmailVerification {
  var request = Primandproper_Platform_Signin_V1_VerifyEmailAddressRequest()
  request.token = token
  do {
    _ = try await SignInService.Client(wrapping: client).verifyEmailAddress(
      request, options: options)
    return .verified
  } catch {
    return .deadLink(message: try deadMailedLinkOrThrow(error))
  }
}

/// attachPassword gives a password to somebody who registered without one, answering the link
/// that was mailed to them. It is not a password reset and must not be offered as one: for an
/// account that already holds a password it is refused, which comes back as
/// `passwordAlreadySet`.
public func attachPassword(
  _ client: GRPCClient<some ClientTransport>,
  token: String,
  newPassword: String,
  options: CallOptions = .defaults
) async throws -> PasswordAttachment {
  var request = Primandproper_Platform_Signin_V1_AttachPasswordRequest()
  request.token = token
  request.newPassword = newPassword
  do {
    _ = try await SignInService.Client(wrapping: client).attachPassword(
      request, options: options)
    return .attached
  } catch {
    if let refusal = toPlatformError(error) as? PlatformError,
      refusal.is(SignInReason.passwordAlreadySet)
    {
      return .passwordAlreadySet(message: refusal.serverMessage)
    }
    return .deadLink(message: try deadMailedLinkOrThrow(error))
  }
}

/// requestMagicLink mails a sign-in link to `emailAddress` if somebody holds it. It returns the
/// same way whether they do or not, and a caller must show the same screen either way (R15):
/// "we sent it" on one and "no such account" on the other rebuilds the enumerator the server's
/// padded timing exists to prevent. The link is answered with `RedeemMagicLink`.
public func requestMagicLink(
  _ client: GRPCClient<some ClientTransport>,
  emailAddress: String,
  options: CallOptions = .defaults
) async throws {
  var request = Primandproper_Platform_Signin_V1_RequestMagicLinkRequest()
  request.emailAddress = emailAddress
  do {
    _ = try await SignInService.Client(wrapping: client).requestMagicLink(
      request, options: options)
  } catch {
    throw toPlatformError(error)
  }
}

/// deadMailedLinkOrThrow answers the message of a refusal that means the link is dead, and
/// throws anything else as a PlatformError. A verification token that is expired, spent or
/// wrong answers exactly as a wrong password does.
private func deadMailedLinkOrThrow(_ error: any Error) throws -> String {
  let error = toPlatformError(error)
  guard let refusal = error as? PlatformError, refusal.code == .unauthenticated else {
    throw error
  }
  return refusal.serverMessage
}
