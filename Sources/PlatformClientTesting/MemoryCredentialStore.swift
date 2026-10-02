import PlatformClient

/// MemoryCredentialStore holds a session in memory. It is for tests: a store that forgets on
/// restart loses the successor R6 says to persist before anything else, so it is not a
/// production default.
public actor MemoryCredentialStore: CredentialStore {
  private var token: IssuedToken?

  public init(_ token: IssuedToken? = nil) {
    self.token = token
  }

  public func load() -> IssuedToken? { token }

  public func save(_ token: IssuedToken) { self.token = token }

  public func clear() { token = nil }
}
