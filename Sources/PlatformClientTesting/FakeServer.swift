import GRPCCore
import GRPCInProcessTransport
import GRPCProtobuf
import SwiftProtobuf
import Synchronization

/// RecordedCall is one request a FakeServer received, as the server saw it: after every client
/// interceptor ran and the message crossed the wire.
public struct RecordedCall: Sendable {
  public let method: MethodDescriptor
  public let request: any SwiftProtobuf.Message
  public let metadata: Metadata

  /// request(as:) answers the request as the message type its method takes.
  public func request<Request: SwiftProtobuf.Message>(as _: Request.Type) -> Request? {
    request as? Request
  }
}

/// FakeServer answers each method with a handler a test registers, and records every call it
/// was asked to make. A method with no handler answers UNIMPLEMENTED, as a server would.
///
/// It is a real gRPC server over grpc-swift's in-process transport, so a call through it
/// crosses serialization, metadata and status trailers exactly as one over the network does:
/// a handler that throws an `RPCError` or a `GoogleRPCStatus` reaches the client as that
/// status, details included.
///
/// A method must be handled before `run` starts the server, because the server's routes are
/// fixed when it starts. A handler may be replaced at any time, which is how a test changes
/// what a method answers partway through.
public final class FakeServer: Sendable {
  private typealias Answer =
    @Sendable (any SwiftProtobuf.Message, Metadata) async throws -> any SwiftProtobuf.Message
  private typealias Registration = @Sendable (inout RPCRouter<InProcessTransport.Server>) -> Void

  private struct State {
    var answers: [MethodDescriptor: Answer] = [:]
    var registrations: [MethodDescriptor: Registration] = [:]
    var calls: [RecordedCall] = []
    var running = false
  }

  private let state = Mutex(State())

  public init() {}

  /// calls is every request received, in the order it arrived.
  public var calls: [RecordedCall] { state.withLock { $0.calls } }

  public func calls(to method: MethodDescriptor) -> [RecordedCall] {
    calls.filter { $0.method == method }
  }

  /// handle answers `method` with `handler` from now on. Input and Output are the method's
  /// request and response messages, which a test names in the closure's signature.
  @discardableResult
  public func handle<Input: SwiftProtobuf.Message, Output: SwiftProtobuf.Message>(
    _ method: MethodDescriptor,
    _ handler: @escaping @Sendable (Input, Metadata) async throws -> Output
  ) -> Self {
    let answer: Answer = { request, metadata in
      guard let request = request as? Input else {
        preconditionFailure(
          "\(method) was first handled with another request type than \(Input.self)")
      }
      return try await handler(request, metadata)
    }
    let registration: Registration = { router in
      router.registerHandler(
        forMethod: method,
        deserializer: ProtobufDeserializer<Input>(),
        serializer: ProtobufSerializer<Output>()
      ) { request, _ in
        let single = try await ServerRequest(stream: request)
        let response = try await self.answer(method, single.message, single.metadata)
        guard let response = response as? Output else {
          preconditionFailure(
            "\(method) was first handled with another response type than \(Output.self)")
        }
        return StreamingServerResponse(single: ServerResponse(message: response))
      }
    }
    state.withLock { state in
      if state.registrations[method] == nil {
        precondition(!state.running, "\(method) has to be handled before the FakeServer runs")
        state.registrations[method] = registration
      }
      state.answers[method] = answer
    }
    return self
  }

  /// run serves the handled methods for as long as `body` runs, handing it a client connected
  /// to them through `interceptors`.
  public func run<Result: Sendable>(
    interceptors: [any ClientInterceptor] = [],
    _ body: @Sendable (GRPCClient<InProcessTransport.Client>) async throws -> Result
  ) async throws -> Result {
    let router = state.withLock { state in
      state.running = true
      var router = RPCRouter<InProcessTransport.Server>()
      for register in state.registrations.values {
        register(&router)
      }
      return router
    }
    defer { state.withLock { $0.running = false } }

    let transport = InProcessTransport()
    let server = GRPCServer(transport: transport.server, router: router)
    return try await withThrowingTaskGroup(of: Void.self) { group in
      group.addTask { try await server.serve() }
      defer { server.beginGracefulShutdown() }
      return try await withGRPCClient(transport: transport.client, interceptors: interceptors) {
        try await body($0)
      }
    }
  }

  private func answer(
    _ method: MethodDescriptor,
    _ request: any SwiftProtobuf.Message,
    _ metadata: Metadata
  ) async throws -> any SwiftProtobuf.Message {
    let answer = state.withLock { state in
      state.calls.append(RecordedCall(method: method, request: request, metadata: metadata))
      return state.answers[method]
    }
    guard let answer else {
      throw RPCError(code: .unimplemented, message: "\(method) has no handler")
    }
    return try await answer(request, metadata)
  }
}
