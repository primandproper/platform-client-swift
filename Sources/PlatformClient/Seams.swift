import Foundation
import GRPCCore

/// IssuedToken is the whole of a session: the access token, the refresh token, and when each
/// lapses.
public typealias IssuedToken = Primandproper_Platform_Signin_V1_IssuedToken

/// CredentialStore holds the session a sign-in minted. The refresh token inside it is "the one
/// worth stealing", so an implementation belongs in the platform's most protected store, and
/// nowhere a log, a crash report or a backup can reach.
public protocol CredentialStore: Sendable {
  /// load answers the held session, or nil when there is none. A store that holds nothing is
  /// not an error.
  func load() async throws -> IssuedToken?
  func save(_ token: IssuedToken) async throws
  func clear() async throws
}

/// WallClock is a seam so that expiry skew and refresh timing can be tested without waiting
/// for real time. It is not the standard library's `Clock`, which measures instants for
/// sleeping; expiry is a wall-clock date the server stamped.
public protocol WallClock: Sendable {
  func now() -> Date
}

/// SystemClock is the WallClock every Session uses unless a test hands it another.
public struct SystemClock: WallClock {
  public init() {}

  public func now() -> Date { Date() }
}

/// Authorizer turns an access token into the metadata that carries it. Nothing in platform-go
/// fixes how a token reaches a server, since a service resolves its caller through a
/// PrincipalExtractor the consumer writes, so a deployment that chose something else supplies
/// its own.
public protocol Authorizer: Sendable {
  func credentials(_ token: String) -> Metadata
}

/// BearerAuthorizer is the contract's default: the `authorization` entry, valued
/// `Bearer <token>`.
public struct BearerAuthorizer: Authorizer {
  public init() {}

  public func credentials(_ token: String) -> Metadata {
    ["authorization": "Bearer \(token)"]
  }
}

extension Authorizer where Self == BearerAuthorizer {
  public static var bearer: BearerAuthorizer { BearerAuthorizer() }
}
