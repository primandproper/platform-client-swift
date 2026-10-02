import GRPCCore

extension Session {
  /// signOutDeadline bounds the one SignOut attempt. It is short because nothing waits on the
  /// answer: the session here is cleared either way.
  public static let signOutDeadline: Duration = .seconds(5)

  /// signOut ends this login on the server and then here, in that order: the refresh token is
  /// the only thing that can end the login, and clearing first would throw it away (R17).
  /// `SignOut` needs no caller, so it works on a session whose access token lapsed a week ago,
  /// which is exactly when somebody presses the button.
  ///
  /// It never throws. Every refusal a presented token can draw means the login is already over,
  /// and a SignOut that could not be delivered cannot be made more true by telling the person.
  /// What neither stops is an access token already issued, which lapses within one access-token
  /// lifetime.
  public func signOut() async {
    let held: IssuedToken?
    do {
      held = try await self.held()
    } catch {
      logger.error(
        "the session could not be loaded to sign it out: \(String(describing: error), privacy: .public)"
      )
      held = nil
    }

    if let held, !held.refreshToken.isEmpty {
      var request = Primandproper_Platform_Signin_V1_SignOutRequest()
      request.refreshToken = held.refreshToken
      var options = CallOptions.defaults
      options.timeout = Self.signOutDeadline
      do {
        _ = try await signInClient.signOut(request, options: options)
      } catch {
        // Unknown, spent, revoked and expired all answer success on the server; anything else
        // is a failure to deliver it, and the session here is cleared regardless.
        logger.notice(
          "SignOut was not delivered; clearing the session anyway: \(String(describing: toPlatformError(error)), privacy: .public)"
        )
      }
    }

    do {
      try await clear()
    } catch {
      logger.error(
        "the session could not be cleared from the store: \(String(describing: error), privacy: .public)"
      )
    }
  }

  /// signOutEverywhere ends every login this person holds on every device, this one included,
  /// and then clears the session here. It is the door for a password its owner thinks somebody
  /// else has seen, so unlike `signOut` a failure throws and leaves the session in place:
  /// reporting "signed out everywhere" when it was not would be the lie R17 is about, and
  /// keeping the session lets the person press it again.
  public func signOutEverywhere() async throws {
    let client = signInClient
    try await call { metadata in
      _ = try await client.signOutEverywhere(.init(), metadata: metadata)
    }
    try await clear()
  }
}
