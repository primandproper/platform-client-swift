import AuthenticationServices
import Foundation
import PlatformClient
import Testing

// The fixtures' binary fields are chosen to need base64url's own alphabet: 0xfb 0xff 0x01 is
// "+/8B" in base64 and "-_8B" in base64url, so reading or writing base64 instead fails them.
private let challenge = Data([0xfb, 0xff, 0x01])
private let credentialID = Data([0xfa, 0xfe])
private let userHandle = Data([0x01, 0x02, 0x03, 0x04])

/// requestOptions is BeginLogin's options as go-webauthn renders a CredentialAssertion.
private let requestOptions = Data(
  #"""
  {"publicKey":{"challenge":"-_8B","timeout":300000,"rpId":"example.com",
  "allowCredentials":[{"type":"public-key","id":"-v4","transports":["internal"]}],
  "userVerification":"preferred"}}
  """#.utf8)

/// creationOptions is BeginRegistration's options as go-webauthn renders a CredentialCreation.
private let creationOptions = Data(
  #"""
  {"publicKey":{"rp":{"name":"Example","id":"example.com"},
  "user":{"name":"jeff","displayName":"Jeff","id":"AQIDBA"},
  "challenge":"-_8B","pubKeyCredParams":[{"type":"public-key","alg":-7}],"timeout":300000,
  "excludeCredentials":[{"type":"public-key","id":"-v4"}],
  "authenticatorSelection":{"residentKey":"required","requireResidentKey":true,
  "userVerification":"preferred"},"attestation":"none"}}
  """#.utf8)

@Suite struct PasskeyBridgeTests {
  @Test func readsRequestOptionsAsTheServerSendsThem() throws {
    let options = try PasskeyAssertionOptions(json: requestOptions)

    #expect(options.challenge == challenge)
    #expect(options.relyingPartyID == "example.com")
    #expect(options.allowedCredentialIDs == [credentialID])
    #expect(options.userVerification == "preferred")
  }

  @Test func readsBareRequestOptionsForADiscoverableLogin() throws {
    let options = try PasskeyAssertionOptions(
      json: Data(#"{"challenge":"-_8B","rpId":"example.com"}"#.utf8))

    #expect(options.challenge == challenge)
    #expect(options.allowedCredentialIDs.isEmpty)
    #expect(options.userVerification == "")
  }

  @Test func readsPaddedBase64URL() throws {
    let options = try PasskeyAssertionOptions(
      json: Data(#"{"challenge":"-v4=","rpId":"example.com"}"#.utf8))

    #expect(options.challenge == credentialID)
  }

  @Test func refusesBase64ThatIsNotBase64URL() {
    #expect(throws: DecodingError.self) {
      try PasskeyAssertionOptions(json: Data(#"{"challenge":"+/8B","rpId":"example.com"}"#.utf8))
    }
  }

  @Test func refusesRequestOptionsThatNameNoRelyingParty() {
    #expect(throws: PasskeyBridgeError.self) {
      try PasskeyAssertionOptions(json: Data(#"{"publicKey":{"challenge":"-_8B"}}"#.utf8))
    }
  }

  @Test func reportsAMalformedEnvelopeRatherThanReadingPastIt() {
    #expect(throws: DecodingError.self) {
      try PasskeyAssertionOptions(json: Data(#"{"publicKey":{"rpId":"example.com"}}"#.utf8))
    }
  }

  @Test func readsCreationOptionsAsTheServerSendsThem() throws {
    let options = try PasskeyRegistrationOptions(json: creationOptions)

    #expect(options.challenge == challenge)
    #expect(options.relyingPartyID == "example.com")
    #expect(options.userID == userHandle)
    #expect(options.userName == "jeff")
    #expect(options.excludedCredentialIDs == [credentialID])
    #expect(options.userVerification == "preferred")
    #expect(options.attestation == "none")
  }

  @Test func buildsAnAssertionRequestRequiringUserVerificationWhateverTheServerAsked() throws {
    let request = try PasskeyAssertionOptions(json: requestOptions).request()

    #expect(request.challenge == challenge)
    #expect(request.relyingPartyIdentifier == "example.com")
    #expect(request.allowedCredentials.map(\.credentialID) == [credentialID])
    #expect(request.userVerificationPreference == .required)
  }

  @Test func buildsAnAssertionRequestWithTheVerificationItIsGiven() throws {
    let options = try PasskeyAssertionOptions(json: requestOptions)

    let request = options.request(userVerification: .init(rawValue: options.userVerification))

    #expect(request.userVerificationPreference == .preferred)
  }

  @Test func buildsARegistrationRequestFromCreationOptions() throws {
    let request = try PasskeyRegistrationOptions(json: creationOptions).request()

    #expect(request.challenge == challenge)
    #expect(request.relyingPartyIdentifier == "example.com")
    #expect(request.userID == userHandle)
    #expect(request.name == "jeff")
    #expect(request.excludedCredentials?.map(\.credentialID) == [credentialID])
    #expect(request.userVerificationPreference == .required)
    #expect(request.attestationPreference == .none)
  }

  @Test func writesAnAssertionAsABrowsersToJSONDoes() throws {
    let assertion = PasskeyAssertion(
      credentialID: credentialID,
      clientDataJSON: Data(#"{"type":"webauthn.get"}"#.utf8),
      authenticatorData: challenge,
      signature: Data([0xff]),
      userHandle: userHandle,
      attachment: .platform)

    let json = String(decoding: try assertion.json(), as: UTF8.self)

    #expect(
      json
        == #"{"authenticatorAttachment":"platform","clientExtensionResults":{},"id":"-v4","#
        + #""rawId":"-v4","response":{"authenticatorData":"-_8B","#
        + #""clientDataJSON":"eyJ0eXBlIjoid2ViYXV0aG4uZ2V0In0","signature":"_w","#
        + #""userHandle":"AQIDBA"},"type":"public-key"}"#)
  }

  @Test func writesAnAssertionWithNoUserHandleWithoutOne() throws {
    let assertion = PasskeyAssertion(
      credentialID: credentialID, clientDataJSON: Data(), authenticatorData: Data(),
      signature: Data())

    let json = String(decoding: try assertion.json(), as: UTF8.self)

    #expect(!json.contains("userHandle"))
    #expect(!json.contains("authenticatorAttachment"))
  }

  @Test func writesARegistrationAsABrowsersToJSONDoes() throws {
    let registration = PasskeyRegistration(
      credentialID: credentialID,
      clientDataJSON: Data(#"{"type":"webauthn.create"}"#.utf8),
      attestationObject: challenge,
      attachment: .crossPlatform)

    let json = String(decoding: try registration.json(), as: UTF8.self)

    #expect(
      json
        == #"{"authenticatorAttachment":"cross-platform","clientExtensionResults":{},"id":"-v4","#
        + #""rawId":"-v4","response":{"attestationObject":"-_8B","#
        + #""clientDataJSON":"eyJ0eXBlIjoid2ViYXV0aG4uY3JlYXRlIn0"},"type":"public-key"}"#)
  }
}
