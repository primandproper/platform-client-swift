import Foundation
import GRPCCore
import GRPCProtobuf

/// PlatformReason is one of R11's tables: the refusals a service names, under the domain its
/// `google.rpc.ErrorInfo` details carry them in.
public protocol PlatformReason: RawRepresentable, CaseIterable, Hashable, Sendable
where RawValue == String {
  static var domain: String { get }
}

/// SignInReason is R11's table: every sign-in refusal a client may be told about, by its
/// stable identifier. A refusal absent from it carries no reason at all, which is how R7
/// survives: a reused, expired or revoked refresh token answers `INVALID_CREDENTIALS` exactly
/// as a wrong password does.
public enum SignInReason: String, PlatformReason {
  case invalidCredentials = "INVALID_CREDENTIALS"
  case secondFactorRequired = "SECOND_FACTOR_REQUIRED"
  case secondFactorNotEnrolled = "SECOND_FACTOR_NOT_ENROLLED"
  case multiFactorRequired = "MULTI_FACTOR_REQUIRED"
  case userUnverified = "USER_UNVERIFIED"
  case userSuspended = "USER_SUSPENDED"
  case userTerminated = "USER_TERMINATED"
  case notAnAdministrator = "NOT_AN_ADMINISTRATOR"
  case adminSignInUnavailable = "ADMIN_SIGNIN_UNAVAILABLE"
  case impersonationUnavailable = "IMPERSONATION_UNAVAILABLE"
  case noPasswordCredential = "NO_PASSWORD_CREDENTIAL"
  case passwordAlreadySet = "PASSWORD_ALREADY_SET"
  case emailAddressAlreadyVerified = "EMAIL_ADDRESS_ALREADY_VERIFIED"
  case noCredentialNamed = "NO_CREDENTIAL_NAMED"
  case passwordRefused = "PASSWORD_REFUSED"
  case registrationRefused = "REGISTRATION_REFUSED"
  case registrationClosed = "REGISTRATION_CLOSED"
  case passwordChangeRequired = "PASSWORD_CHANGE_REQUIRED"
  case signInNotIdentified = "SIGN_IN_NOT_IDENTIFIED"
  case reauthenticationRequired = "REAUTHENTICATION_REQUIRED"

  public static let domain = "signin.platform-go.primandproper.github.com"
}

/// PasskeyReason is the passkey service's table, in a domain of its own: the refusals a person
/// in front of a passkey prompt or a settings page acts on.
public enum PasskeyReason: String, PlatformReason {
  case passkeyLoginFailed = "PASSKEY_LOGIN_FAILED"
  case passkeySignCountRegressed = "PASSKEY_SIGN_COUNT_REGRESSED"
  case passkeyNotFound = "PASSKEY_NOT_FOUND"
  case passkeyAlreadyRegistered = "PASSKEY_ALREADY_REGISTERED"
  case lastPasskey = "LAST_PASSKEY"

  public static let domain = "passkeys.platform-go.primandproper.github.com"
}

/// PasswordResetReason is the reset service's table, in a domain of its own. The three about
/// the link all answer FAILED_PRECONDITION and read as a dead link; the one a caller branches
/// on is `replacementPasswordRefused`, which leaves the link live and asks for another
/// password.
public enum PasswordResetReason: String, PlatformReason {
  case resetTokenNotFound = "RESET_TOKEN_NOT_FOUND"
  case resetTokenExpired = "RESET_TOKEN_EXPIRED"
  case resetTokenRedeemed = "RESET_TOKEN_REDEEMED"
  case replacementPasswordRefused = "REPLACEMENT_PASSWORD_REFUSED"

  public static let domain = "passwordreset.platform-go.primandproper.github.com"
}

/// Reason is the structured refusal a status carried. `unknown` is a reason this client has
/// no name for, which a newer server may send, or one from a domain it does not know: it is
/// still readable, and reading it does not throw.
public enum Reason: Hashable, Sendable {
  case signIn(SignInReason)
  case passkey(PasskeyReason)
  case passwordReset(PasswordResetReason)
  case unknown(domain: String, reason: String)

  init(domain: String, reason: String) {
    switch domain {
    case SignInReason.domain:
      if let known = SignInReason(rawValue: reason) {
        self = .signIn(known)
        return
      }
    case PasskeyReason.domain:
      if let known = PasskeyReason(rawValue: reason) {
        self = .passkey(known)
        return
      }
    case PasswordResetReason.domain:
      if let known = PasswordResetReason(rawValue: reason) {
        self = .passwordReset(known)
        return
      }
    default:
      break
    }
    self = .unknown(domain: domain, reason: reason)
  }

  public var domain: String {
    switch self {
    case .signIn: SignInReason.domain
    case .passkey: PasskeyReason.domain
    case .passwordReset: PasswordResetReason.domain
    case .unknown(let domain, _): domain
    }
  }

  public var name: String {
    switch self {
    case .signIn(let reason): reason.rawValue
    case .passkey(let reason): reason.rawValue
    case .passwordReset(let reason): reason.rawValue
    case .unknown(_, let reason): reason
    }
  }
}

/// PlatformError is a refusal a caller can branch on: the code always, and the reason where
/// there is one (R13). Branch on the reason, never on `serverMessage` (R11).
///
/// `serverMessage` is the server's text as sent, and is what to show a person: it is this
/// error's `localizedDescription`. `description` is written for a log.
public struct PlatformError: Error, Sendable {
  public let code: RPCError.Code
  public let serverMessage: String
  public let reason: Reason?
  /// reasonMetadata is the ErrorInfo's metadata, empty when there is no reason.
  public let reasonMetadata: [String: String]
  /// rpcError is the status this error was read from, with its trailing metadata and cause.
  /// It is nil for one built from its parts, which no status stands behind.
  public let rpcError: RPCError?

  public init(
    code: RPCError.Code,
    serverMessage: String,
    reason: Reason? = nil,
    reasonMetadata: [String: String] = [:]
  ) {
    self.code = code
    self.serverMessage = serverMessage
    self.reason = reason
    self.reasonMetadata = reasonMetadata
    self.rpcError = nil
  }

  /// init(_:) reads an RPCError's details. Details that do not decode are dropped, as the
  /// server drops a detail that does not marshal: the code is still right.
  public init(_ error: RPCError) {
    var reason: Reason?
    var metadata: [String: String] = [:]
    if let status = try? error.unpackGoogleRPCStatus(),
      let info = status.details.lazy.compactMap(\.errorInfo).first
    {
      reason = Reason(domain: info.domain, reason: info.reason)
      metadata = info.metadata
    }
    self.code = error.code
    self.serverMessage = error.message
    self.reason = reason
    self.reasonMetadata = metadata
    self.rpcError = error
  }

  /// is reports whether this refusal carries `reason`, in that reason's own domain.
  public func `is`(_ reason: some PlatformReason) -> Bool {
    self.reason?.domain == type(of: reason).domain && self.reason?.name == reason.rawValue
  }
}

extension PlatformError: CustomStringConvertible {
  public var description: String {
    let suffix = reason.map { " [\($0.domain)/\($0.name)]" } ?? ""
    if code == .unknown {
      return
        "UNKNOWN: \(serverMessage)\(suffix) (the server mapped this refusal to no code; a "
        + "deployment that has not called errormappers.Register answers its own refusals this way)"
    }
    return "\(code.wireName): \(serverMessage)\(suffix)"
  }
}

extension PlatformError: LocalizedError {
  public var errorDescription: String? { serverMessage }
}

/// toPlatformError converts what a call threw. An RPCError becomes a PlatformError; anything
/// else carried no status, and is returned as it was.
public func toPlatformError(_ error: any Error) -> any Error {
  (error as? RPCError).map(PlatformError.init) ?? error
}

/// ExchangeNotSentError is an exchange that failed before the refresh token left this device.
/// It is not ambiguous, since the server never saw the token, so the session keeps it and
/// tries again on the next call.
public struct ExchangeNotSentError: Error, Sendable {
  public let message: String
  public let cause: any Error

  public init(_ message: String, cause: any Error) {
    self.message = message
    self.cause = cause
  }
}

private let ambiguousCodes: Set<RPCError.Code> = [
  .deadlineExceeded, .unavailable, .cancelled, .internalError, .unknown,
]

/// isAmbiguous reports whether a failed call may have committed before it failed: R10's
/// table. A failure with no status at all is ambiguous, since nothing says the request did not
/// arrive, unless it is an ExchangeNotSentError, which does.
public func isAmbiguous(_ error: any Error) -> Bool {
  switch error {
  case let error as PlatformError: ambiguousCodes.contains(error.code)
  case let error as RPCError: ambiguousCodes.contains(error.code)
  case is ExchangeNotSentError: false
  default: true
  }
}

private let transientCodes: Set<RPCError.Code> = [
  .unavailable, .deadlineExceeded, .resourceExhausted,
]

/// isTransient reports whether a failed call failed because the server could not answer it
/// right now, so trying again later may succeed: what "try again later" and a breaker consult.
/// A failure with no status at all is transient, since the transport failed before anything
/// answered, except a CancellationError, which is `CANCELLED` by another name, and an
/// ExchangeNotSentError, which failed on this device.
///
/// `INTERNAL` and `UNKNOWN` are the server's fault but not transient: they are a bug, and a
/// breaker that trips on them hides it behind "try later". `CANCELLED` is the caller backing
/// out, never an outage. Unwrap any wrapper of your own first: this sees only what is in front
/// of it.
public func isTransient(_ error: any Error) -> Bool {
  switch error {
  case let error as PlatformError: transientCodes.contains(error.code)
  case let error as RPCError: transientCodes.contains(error.code)
  case is CancellationError, is ExchangeNotSentError: false
  default: true
  }
}

extension RPCError.Code {
  /// wireName is the code as gRPC names it everywhere else, in a log a reader can grep.
  fileprivate var wireName: String {
    switch self {
    case .cancelled: "CANCELLED"
    case .unknown: "UNKNOWN"
    case .invalidArgument: "INVALID_ARGUMENT"
    case .deadlineExceeded: "DEADLINE_EXCEEDED"
    case .notFound: "NOT_FOUND"
    case .alreadyExists: "ALREADY_EXISTS"
    case .permissionDenied: "PERMISSION_DENIED"
    case .resourceExhausted: "RESOURCE_EXHAUSTED"
    case .failedPrecondition: "FAILED_PRECONDITION"
    case .aborted: "ABORTED"
    case .outOfRange: "OUT_OF_RANGE"
    case .unimplemented: "UNIMPLEMENTED"
    case .internalError: "INTERNAL"
    case .unavailable: "UNAVAILABLE"
    case .dataLoss: "DATA_LOSS"
    case .unauthenticated: "UNAUTHENTICATED"
    default: "code \(rawValue)"
    }
  }
}
