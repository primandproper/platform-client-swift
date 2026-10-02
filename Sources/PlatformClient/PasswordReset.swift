import Foundation
import GRPCCore

private typealias PasswordResetService =
  Primandproper_Platform_Passwordreset_V1_PasswordResetService

/// PasswordResetTokenVerification is what a reset link's page load learned about the link.
public enum PasswordResetTokenVerification: Sendable, Hashable {
  /// live is a link that could be spent now. It says when the link expires and nothing else,
  /// deliberately not whose it is, so there is no address to prefill.
  case live(expiresAt: Date?)
  /// deadLink is a link that cannot be spent: expired, already used, or never a link. The three
  /// are told apart only by `message`, which is written to be shown, and they share one remedy,
  /// so there is nothing to branch on: show the message and offer to send a new link.
  case deadLink(message: String)
}

/// PasswordResetCompletion is what spending a reset link came to.
public enum PasswordResetCompletion: Sendable, Hashable {
  case reset
  /// deadLink is the link found dead, as `PasswordResetTokenVerification.deadLink` is: perhaps
  /// spent by somebody else since the page loaded.
  case deadLink(message: String)
}

/// requestPasswordReset mails a reset link to `emailAddress` if somebody holds it. It returns
/// the same way whether they do or not, and a caller must show the same screen either way
/// (R15): "check your inbox" on one and "no account with that address" on the other rebuilds
/// the account enumerator the server's silence and timing floor exist to prevent.
///
/// It is anonymous. The tenant rides the ConstantMetadataInterceptor on `client` (R12).
public func requestPasswordReset(
  _ client: GRPCClient<some ClientTransport>,
  emailAddress: String,
  options: CallOptions = .defaults
) async throws {
  var request = Primandproper_Platform_Passwordreset_V1_RequestPasswordResetRequest()
  request.emailAddress = emailAddress
  do {
    _ = try await PasswordResetService.Client(wrapping: client).requestPasswordReset(
      request, options: options)
  } catch {
    throw toPlatformError(error)
  }
}

/// verifyPasswordResetToken is the page load behind a reset link, made before rendering the
/// form so that somebody who followed a dead link is told now rather than after choosing a
/// password (R16). It holds nothing open: the answer that decides anything is
/// `completePasswordReset`'s.
public func verifyPasswordResetToken(
  _ client: GRPCClient<some ClientTransport>,
  token: String,
  options: CallOptions = .defaults
) async throws -> PasswordResetTokenVerification {
  var request = Primandproper_Platform_Passwordreset_V1_VerifyPasswordResetTokenRequest()
  request.token = token
  do {
    let response = try await PasswordResetService.Client(wrapping: client)
      .verifyPasswordResetToken(request, options: options)
    return .live(expiresAt: response.hasExpiresAt ? response.expiresAt.date : nil)
  } catch {
    return .deadLink(message: try deadResetLinkOrThrow(error))
  }
}

/// completePasswordReset spends the link and sets the new password. It signs nobody in and does
/// not end the account's other sessions: the next call is a sign-in with the password just
/// chosen. Somebody resetting because they think another person is in their account should
/// sign in and then sign out everywhere, which is the one sequence that ends the other sessions.
///
/// Password policy is the consumer's, applied before this call. A password the service refuses
/// is thrown, not answered as a dead link, because the link is still live: an empty one as
/// INVALID_ARGUMENT, and one the deployment's policy refuses as INVALID_ARGUMENT carrying
/// `PasswordResetReason.replacementPasswordRefused`.
public func completePasswordReset(
  _ client: GRPCClient<some ClientTransport>,
  token: String,
  newPassword: String,
  options: CallOptions = .defaults
) async throws -> PasswordResetCompletion {
  var request = Primandproper_Platform_Passwordreset_V1_CompletePasswordResetRequest()
  request.token = token
  request.newPassword = newPassword
  do {
    _ = try await PasswordResetService.Client(wrapping: client).completePasswordReset(
      request, options: options)
    return .reset
  } catch {
    return .deadLink(message: try deadResetLinkOrThrow(error))
  }
}

/// deadResetLinkOrThrow answers the message of a refusal that means the link is dead, and
/// throws anything else as a PlatformError. Every dead reset link is FAILED_PRECONDITION.
private func deadResetLinkOrThrow(_ error: any Error) throws -> String {
  let error = toPlatformError(error)
  guard let refusal = error as? PlatformError, refusal.code == .failedPrecondition else {
    throw error
  }
  return refusal.serverMessage
}
