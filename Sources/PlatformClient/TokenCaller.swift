import GRPCCore

/// TokenCaller makes calls with a token the caller already holds. It is for an app whose login
/// lives somewhere else (its own sign-in, say, while it moves onto platform's) and that wants
/// the stubs before it wants a Session.
///
/// It holds no state, so R1 through R7 do not apply to it: it never refreshes, never retries,
/// and never ends anything. A call answered UNAUTHENTICATED throws that PlatformError, and
/// signing the person in again is the caller's to do.
///
/// The tenant is not its to carry. R12's entries ride the ConstantMetadataInterceptor on the
/// GRPCClient the stubs wrap, so they reach a call made through this and one made around it
/// alike:
///
/// ```swift
/// let caller = TokenCaller()
/// let signIn = Primandproper_Platform_Signin_V1_SignInService.Client(wrapping: client)
/// let me = try await caller.call(token) { metadata in
///   try await signIn.getSelf(.init(), metadata: metadata)
/// }
/// ```
public struct TokenCaller: Sendable {
  private let authorizer: any Authorizer

  public init(authorizer: some Authorizer = .bearer) {
    self.authorizer = authorizer
  }

  /// callAnonymous makes a call that carries no credential.
  public func callAnonymous<Result>(
    _ body: () async throws -> Result
  ) async throws -> Result {
    do {
      return try await body()
    } catch {
      throw toPlatformError(error)
    }
  }

  /// call hands `body` the metadata to make its call with: `metadata`, and `token` in whatever
  /// entries the Authorizer puts it, which replace any of `metadata`'s by the same name.
  public func call<Result>(
    _ token: String,
    metadata: Metadata = [:],
    _ body: (Metadata) async throws -> Result
  ) async throws -> Result {
    let credentials = authorizer.credentials(token)
    var metadata = metadata
    for key in Set(credentials.map(\.key)) {
      metadata.removeAllValues(forKey: key)
    }
    metadata.add(contentsOf: credentials)
    return try await callAnonymous { try await body(metadata) }
  }
}
