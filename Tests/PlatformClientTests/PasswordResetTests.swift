import Foundation
import GRPCCore
import PlatformClient
import PlatformClientTesting
import SwiftProtobuf
import Synchronization
import Testing

private typealias Reset = Primandproper_Platform_Passwordreset_V1_PasswordResetService
private typealias Request = Reset.Method.RequestPasswordReset
private typealias Verify = Reset.Method.VerifyPasswordResetToken
private typealias Complete = Reset.Method.CompletePasswordReset

private let tenant = ConstantMetadataInterceptor(["x-tenant": "acme"])

@Suite struct RequestPasswordResetTests {
  @Test func givesACallerTheSameOutcomeForAnAddressSomebodyHoldsAndOneNobodyDoes() async throws {
    let mailed = Mutex<[String]>([])
    let server = FakeServer().handle(Request.descriptor) {
      (request: Request.Input, _) -> Request.Output in
      if request.emailAddress == "held@example.com" {
        mailed.withLock { $0.append(request.emailAddress) }
      }
      return Request.Output()
    }

    let (forHeld, forNobody) = try await server.run(interceptors: [tenant]) { client in
      (
        try await requestPasswordReset(client, emailAddress: "held@example.com"),
        try await requestPasswordReset(client, emailAddress: "nobody@example.com")
      )
    }

    #expect(mailed.withLock { $0 } == ["held@example.com"])
    #expect(type(of: forHeld) == Void.self)
    #expect(type(of: forNobody) == Void.self)
  }

  @Test func isAnonymousAndCarriesTheTenant() async throws {
    let server = FakeServer().handle(Request.descriptor) { (_: Request.Input, _) in
      Request.Output()
    }

    try await server.run(interceptors: [tenant]) { client in
      try await requestPasswordReset(client, emailAddress: "a@example.com")
    }

    let sent = try #require(server.calls(to: Request.descriptor).first).metadata
    #expect(Array(sent[stringValues: "x-tenant"]) == ["acme"])
    #expect(Array(sent[stringValues: "authorization"]).isEmpty)
  }

  @Test func throwsAFailureToDeliverTheRequest() async throws {
    let server = FakeServer().handle(Request.descriptor) {
      (_: Request.Input, _) -> Request.Output in
      throw RPCError(code: .unavailable, message: "unavailable")
    }

    let error = try await server.run(interceptors: [tenant]) { client in
      await #expect(throws: PlatformError.self) {
        try await requestPasswordReset(client, emailAddress: "a@example.com")
      }
    }

    #expect(error?.code == .unavailable)
  }
}

@Suite struct VerifyPasswordResetTokenTests {
  @Test func answersALiveLinkWithWhenItExpires() async throws {
    let expiresAt = Date(timeIntervalSince1970: 1_767_226_800)
    let server = FakeServer().handle(Verify.descriptor) { (_: Verify.Input, _) in
      var response = Verify.Output()
      response.expiresAt = .init(date: expiresAt)
      return response
    }

    let result = try await server.run(interceptors: [tenant]) { client in
      try await verifyPasswordResetToken(client, token: "link")
    }

    #expect(result == .live(expiresAt: expiresAt))
    let sent = try #require(server.calls(to: Verify.descriptor).first)
    #expect(sent.request(as: Verify.Input.self)?.token == "link")
  }

  @Test(arguments: [
    "this link has expired", "this link has already been used", "this is not a reset link",
  ])
  func answersARefusedLinkAsADeadLinkCarryingTheMessage(_ message: String) async throws {
    let server = FakeServer().handle(Verify.descriptor) {
      (_: Verify.Input, _) -> Verify.Output in
      throw RPCError(code: .failedPrecondition, message: message)
    }

    let result = try await server.run(interceptors: [tenant]) { client in
      try await verifyPasswordResetToken(client, token: "link")
    }

    #expect(result == .deadLink(message: message))
  }

  @Test func throwsAnythingThatIsNotADeadLink() async throws {
    let server = FakeServer().handle(Verify.descriptor) {
      (_: Verify.Input, _) -> Verify.Output in
      throw RPCError(code: .unavailable, message: "unavailable")
    }

    let error = try await server.run(interceptors: [tenant]) { client in
      await #expect(throws: PlatformError.self) {
        try await verifyPasswordResetToken(client, token: "link")
      }
    }

    #expect(error?.code == .unavailable)
  }
}

@Suite struct CompletePasswordResetTests {
  @Test func setsThePasswordAndSignsNobodyIn() async throws {
    let server = FakeServer().handle(Complete.descriptor) { (_: Complete.Input, _) in
      Complete.Output()
    }

    let result = try await server.run(interceptors: [tenant]) { client in
      try await completePasswordReset(client, token: "link", newPassword: "correct horse")
    }

    #expect(result == .reset)
    let sent = try #require(server.calls(to: Complete.descriptor).first)
    #expect(sent.request(as: Complete.Input.self)?.token == "link")
    #expect(sent.request(as: Complete.Input.self)?.newPassword == "correct horse")
    #expect(server.calls.count == 1)
  }

  @Test func answersALinkSpentInTheMeantimeAsADeadLink() async throws {
    let server = FakeServer().handle(Complete.descriptor) {
      (_: Complete.Input, _) -> Complete.Output in
      throw RPCError(code: .failedPrecondition, message: "this link has already been used")
    }

    let result = try await server.run(interceptors: [tenant]) { client in
      try await completePasswordReset(client, token: "link", newPassword: "x")
    }

    #expect(result == .deadLink(message: "this link has already been used"))
  }

  @Test func throwsAnEmptyPasswordAsTheRefusalItIsNotADeadLink() async throws {
    let server = FakeServer().handle(Complete.descriptor) {
      (_: Complete.Input, _) -> Complete.Output in
      throw RPCError(code: .invalidArgument, message: "a password is required")
    }

    let error = try await server.run(interceptors: [tenant]) { client in
      await #expect(throws: PlatformError.self) {
        try await completePasswordReset(client, token: "link", newPassword: "")
      }
    }

    #expect(error?.code == .invalidArgument)
  }

  @Test func throwsAPasswordThePolicyRefusedWithItsReasonNotADeadLink() async throws {
    let server = FakeServer().handle(Complete.descriptor) {
      (_: Complete.Input, _) -> Complete.Output in
      throw refusal(
        .invalidArgument, "that password is too common",
        PasswordResetReason.replacementPasswordRefused)
    }

    let error = try await server.run(interceptors: [tenant]) { client in
      await #expect(throws: PlatformError.self) {
        try await completePasswordReset(client, token: "link", newPassword: "password")
      }
    }

    #expect(error?.is(PasswordResetReason.replacementPasswordRefused) == true)
  }
}
