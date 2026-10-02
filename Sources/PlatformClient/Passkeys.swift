import Foundation
import GRPCCore

/// PasskeysClient is the generated passkeys stub a passkey sign-in is made through.
public typealias PasskeysClient = Primandproper_Platform_Passkeys_V1_PasskeysService.ClientProtocol

/// PasskeySignIn is a finished passkey ceremony, ready to be exchanged for a session.
public struct PasskeySignIn: Sendable, Hashable {
  /// username is the one `beginPasskeySignIn` was sent, empty for a discoverable login.
  public var username: String
  /// response is the assertion's JSON, as a browser's `toJSON()` renders it:
  /// `PasskeyAssertion.json()`.
  public var response: Data
  /// totpCode is sent whenever there is one, as for a password sign-in.
  public var totpCode: String
  /// activeAccountID is which account the token is for; empty means the user's default.
  public var activeAccountID: String

  public init(
    username: String = "",
    response: Data,
    totpCode: String = "",
    activeAccountID: String = ""
  ) {
    self.username = username
    self.response = response
    self.totpCode = totpCode
    self.activeAccountID = activeAccountID
  }
}

/// PasskeySignInResult is a passkey sign-in that either minted a session or needs a
/// second-factor code first (R19). There is no `resend`, unlike a password sign-in: the
/// assertion's challenge is spent, so the code goes with a fresh one, from
/// `beginPasskeySignIn` and the key again.
public enum PasskeySignInResult: Sendable, Hashable {
  case signedIn(IssuedToken)
  case secondFactorRequired
}

extension Session {
  /// beginPasskeySignIn starts a passkey sign-in, answering the options JSON that
  /// `PasskeyAssertionOptions(json:)` reads. An empty `username` is the discoverable login. It
  /// answers the same for a username nobody holds as for one somebody does, so show the same
  /// prompt either way.
  public nonisolated func beginPasskeySignIn(
    _ passkeys: some PasskeysClient,
    username: String = ""
  ) async throws -> Data {
    var request = Primandproper_Platform_Passkeys_V1_BeginLoginRequest()
    request.username = username
    do {
      return try await passkeys.beginLogin(request).options
    } catch {
      throw toPlatformError(error)
    }
  }

  /// passkeySignIn finishes a passkey sign-in and adopts the session it mints. That session is
  /// the one a password sign-in mints, refresh token and all (R18), so it is held, refreshed
  /// and signed out of exactly as that one is.
  ///
  /// A key tapped with no user verification is one factor (R19): a person holding a proven
  /// second factor is answered `secondFactorRequired`. Every other refusal throws a
  /// PlatformError, `passkeyLoginFailed` for any login that proved nobody and
  /// `passkeySignCountRegressed` for a key that looks cloned, which is the end of it rather
  /// than a reason to try again.
  public nonisolated func passkeySignIn(
    _ passkeys: some PasskeysClient,
    _ request: PasskeySignIn
  ) async throws -> PasskeySignInResult {
    var message = Primandproper_Platform_Passkeys_V1_FinishLoginRequest()
    message.username = request.username
    message.response = request.response
    message.activeAccountID = request.activeAccountID
    message.totpCode = request.totpCode
    do {
      return .signedIn(try await signIn { [message] in try await passkeys.finishLogin(message) })
    } catch let error as PlatformError where error.is(SignInReason.secondFactorRequired) {
      return .secondFactorRequired
    }
  }
}
