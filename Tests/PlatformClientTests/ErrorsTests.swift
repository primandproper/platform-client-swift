import GRPCCore
import GRPCProtobuf
import PlatformClient
import PlatformClientTesting
import Testing

private func rpcError(_ status: GoogleRPCStatus) -> RPCError { RPCError(status) }

@Suite struct PlatformErrorTests {
  @Test func readsASignInReasonFromTheErrorInfoDetail() {
    let error = PlatformError(
      rpcError(
        refusal(
          .unauthenticated, "a second-factor code is required",
          SignInReason.secondFactorRequired)))

    #expect(error.code == .unauthenticated)
    #expect(error.serverMessage == "a second-factor code is required")
    #expect(error.reason == .signIn(.secondFactorRequired))
    #expect(error.is(SignInReason.secondFactorRequired))
    #expect(!error.is(SignInReason.invalidCredentials))
  }

  @Test func findsTheErrorInfoAmongOtherDetails() {
    let status = GoogleRPCStatus(
      code: .permissionDenied, message: "suspended",
      details: [
        .debugInfo(stack: ["x"], detail: "y"),
        .errorInfo(reason: "USER_SUSPENDED", domain: SignInReason.domain),
      ])

    #expect(PlatformError(rpcError(status)).is(SignInReason.userSuspended))
  }

  @Test func keepsASignInReasonThisClientDoesNotKnowWithoutThrowing() {
    let error = PlatformError(
      rpcError(
        refusal(
          .failedPrecondition, "new", domain: SignInReason.domain, reason: "SOMETHING_NEW",
          metadata: ["k": "v"])))

    #expect(error.reason == .unknown(domain: SignInReason.domain, reason: "SOMETHING_NEW"))
    #expect(error.reasonMetadata == ["k": "v"])
  }

  @Test func doesNotTreatAKnownNameFromAnotherDomainAsASignInReason() {
    let error = PlatformError(
      rpcError(
        refusal(.unauthenticated, "x", domain: "example.com", reason: "INVALID_CREDENTIALS")))

    #expect(error.reason == .unknown(domain: "example.com", reason: "INVALID_CREDENTIALS"))
    #expect(!error.is(SignInReason.invalidCredentials))
  }

  @Test func hasNoReasonWhenTheStatusCarriedNoDetails() {
    let error = PlatformError(
      RPCError(code: .permissionDenied, message: "account status does not admit sign-in"))

    #expect(error.reason == nil)
    #expect(error.code == .permissionDenied)
  }

  @Test func hasNoReasonWhenTheDetailsDoNotDecode() {
    let error = PlatformError(
      RPCError(
        code: .unauthenticated, message: "x",
        metadata: ["grpc-status-details-bin": .binary([0xff, 0xff, 0xff])]))

    #expect(error.reason == nil)
    #expect(error.code == .unauthenticated)
  }

  @Test func saysInItsDescriptionWhatAnUnknownCodeProbablyMeans() {
    let error = PlatformError(RPCError(code: .unknown, message: "invalid credentials"))

    #expect(error.serverMessage == "invalid credentials")
    #expect(error.description.contains("errormappers.Register"))
  }

  @Test func namesTheCodeAndReasonInItsDescription() {
    let error = PlatformError(
      rpcError(refusal(.unauthenticated, "invalid credentials", SignInReason.invalidCredentials)))

    #expect(
      error.description
        == "UNAUTHENTICATED: invalid credentials [\(SignInReason.domain)/INVALID_CREDENTIALS]")
  }

  @Test func showsAPersonTheServersMessage() {
    let error = PlatformError(RPCError(code: .permissionDenied, message: "suspended until May"))

    #expect(error.localizedDescription == "suspended until May")
  }

  @Test func keepsTheRPCErrorItWasReadFrom() throws {
    struct SocketHangUp: Error {}
    let original = RPCError(
      code: .unavailable, message: "connection reset",
      metadata: ["x-request-id": "abc123"], cause: SocketHangUp())

    let kept = try #require(PlatformError(original).rpcError)

    #expect(kept.code == .unavailable)
    #expect(kept.message == "connection reset")
    #expect(kept.metadata[stringValues: "x-request-id"].map { $0 } == ["abc123"])
    #expect(kept.cause is SocketHangUp)
  }

  @Test func hasNoRPCErrorWhenBuiltFromItsParts() {
    let error = PlatformError(
      code: .unauthenticated, serverMessage: "x", reason: .signIn(.invalidCredentials))

    #expect(error.rpcError == nil)
  }

  @Test func arrivesWithItsReasonOverTheWire() async throws {
    typealias SignIn = Primandproper_Platform_Signin_V1_SignInService
    let server = FakeServer().handle(SignIn.Method.GetAuthStatus.descriptor) {
      (_: Primandproper_Platform_Signin_V1_GetAuthStatusRequest, _)
        -> Primandproper_Platform_Signin_V1_GetAuthStatusResponse in
      throw refusal(.failedPrecondition, "change it first", SignInReason.passwordChangeRequired)
    }

    let error = try await server.run { client in
      await #expect(throws: RPCError.self) {
        try await SignIn.Client(wrapping: client).getAuthStatus(.init())
      }
    }

    #expect(try PlatformError(#require(error)).is(SignInReason.passwordChangeRequired))
  }
}

@Suite struct ToPlatformErrorTests {
  @Test func convertsAnRPCError() {
    #expect(toPlatformError(RPCError(code: .notFound, message: "x")) is PlatformError)
  }

  @Test func returnsAFailureWithNoStatusAsItWas() {
    struct SocketHangUp: Error {}

    #expect(toPlatformError(SocketHangUp()) is SocketHangUp)
  }
}

@Suite struct IsAmbiguousTests {
  @Test(arguments: [
    (RPCError.Code.deadlineExceeded, true),
    (.unavailable, true),
    (.cancelled, true),
    (.internalError, true),
    (.unknown, true),
    (.unauthenticated, false),
    (.permissionDenied, false),
    (.invalidArgument, false),
    (.failedPrecondition, false),
  ])
  func classifiesByCode(code: RPCError.Code, ambiguous: Bool) {
    #expect(isAmbiguous(RPCError(code: code, message: "x")) == ambiguous)
    #expect(isAmbiguous(PlatformError(code: code, serverMessage: "x")) == ambiguous)
  }

  @Test func treatsAFailureWithNoStatusAsAmbiguous() {
    struct SocketHangUp: Error {}

    #expect(isAmbiguous(SocketHangUp()))
  }

  @Test func treatsAnExchangeThatWasNeverSentAsNotAmbiguous() {
    struct StoreUnreachable: Error {}

    #expect(!isAmbiguous(ExchangeNotSentError("store unreachable", cause: StoreUnreachable())))
  }
}

@Suite struct IsTransientTests {
  @Test(arguments: [
    (RPCError.Code.unavailable, true),
    (.deadlineExceeded, true),
    (.resourceExhausted, true),
    (.cancelled, false),
    (.unknown, false),
    (.invalidArgument, false),
    (.notFound, false),
    (.alreadyExists, false),
    (.permissionDenied, false),
    (.failedPrecondition, false),
    (.aborted, false),
    (.outOfRange, false),
    (.unimplemented, false),
    (.internalError, false),
    (.dataLoss, false),
    (.unauthenticated, false),
  ])
  func classifiesByCode(code: RPCError.Code, transient: Bool) {
    #expect(isTransient(RPCError(code: code, message: "x")) == transient)
    #expect(isTransient(PlatformError(code: code, serverMessage: "x")) == transient)
    #expect(isTransient(PlatformError(RPCError(code: code, message: "x"))) == transient)
  }

  @Test func treatsAFailureWithNoStatusAsTransient() {
    struct SocketHangUp: Error {}

    #expect(isTransient(SocketHangUp()))
  }

  @Test func treatsACancelledTaskAsNotTransient() {
    #expect(!isTransient(CancellationError()))
  }

  @Test func treatsAnExchangeThatWasNeverSentAsNotTransient() {
    struct StoreUnreachable: Error {}

    #expect(!isTransient(ExchangeNotSentError("store unreachable", cause: StoreUnreachable())))
  }
}

@Suite struct ReasonTablesTests {
  @Test func readAResetRefusalAsKnownInItsOwnDomain() {
    let error = PlatformError(
      rpcError(
        refusal(.invalidArgument, "too short", PasswordResetReason.replacementPasswordRefused)))

    #expect(error.reason == .passwordReset(.replacementPasswordRefused))
    #expect(error.is(PasswordResetReason.replacementPasswordRefused))
  }

  @Test func readAPasskeyRefusalAsKnownInItsOwnDomain() {
    let error = PlatformError(
      rpcError(refusal(.permissionDenied, "cloned", PasskeyReason.passkeySignCountRegressed)))

    #expect(error.reason == .passkey(.passkeySignCountRegressed))
    #expect(!error.is(SignInReason.invalidCredentials))
  }

  @Test func matchTheWireStringsTypeScriptKnows() {
    #expect(SignInReason.allCases.count == 20)
    #expect(PasskeyReason.allCases.count == 5)
    #expect(PasswordResetReason.allCases.count == 4)
  }
}
