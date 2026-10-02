import GRPCCore
import GRPCProtobuf
import PlatformClient

/// refusal is a status carrying `reason` in its details, as a server sends one. Thrown from a
/// FakeServer handler, it reaches the client as that status.
public func refusal(
  _ code: RPCError.Code,
  _ message: String,
  _ reason: some PlatformReason,
  metadata: [String: String] = [:]
) -> GoogleRPCStatus {
  refusal(
    code, message, domain: type(of: reason).domain, reason: reason.rawValue, metadata: metadata)
}

/// refusal is a status carrying a reason by its strings, for one this client has no name for.
public func refusal(
  _ code: RPCError.Code,
  _ message: String,
  domain: String,
  reason: String,
  metadata: [String: String] = [:]
) -> GoogleRPCStatus {
  GoogleRPCStatus(
    code: code, message: message,
    details: .errorInfo(reason: reason, domain: domain, metadata: metadata))
}
