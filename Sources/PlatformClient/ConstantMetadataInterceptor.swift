import GRPCCore

/// ConstantMetadataInterceptor sends its entries on every call through the GRPCClient it is
/// installed on. This is R12's third shape: a tenant carried in metadata travels identically
/// on anonymous and authenticated calls alike, so it belongs on the client rather than on each
/// call, where one call site could forget it. A per-call entry of the same name does not
/// replace it.
///
/// Install it when building the client every service shares, platform's and the product's:
///
/// ```swift
/// let client = GRPCClient(
///   transport: transport,
///   interceptors: [ConstantMetadataInterceptor(["x-tenant": "acme"])]
/// )
/// ```
public struct ConstantMetadataInterceptor: ClientInterceptor {
  private let entries: [(key: String, value: String)]

  public init(_ entries: [String: String]) {
    self.entries = entries.sorted { $0.key < $1.key }.map { (key: $0.key, value: $0.value) }
  }

  public func intercept<Input: Sendable, Output: Sendable>(
    request: StreamingClientRequest<Input>,
    context: ClientContext,
    next: (
      _ request: StreamingClientRequest<Input>,
      _ context: ClientContext
    ) async throws -> StreamingClientResponse<Output>
  ) async throws -> StreamingClientResponse<Output> {
    var request = request
    for entry in entries {
      request.metadata.replaceOrAddString(entry.value, forKey: entry.key)
    }
    return try await next(request, context)
  }
}
