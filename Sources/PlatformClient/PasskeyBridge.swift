import Foundation

#if canImport(AuthenticationServices)
  import AuthenticationServices
#endif

// The passkeys service speaks WebAuthn JSON, which a browser hands straight to
// `navigator.credentials` and iOS has no API for. These types are the bridge: the options a
// Begin call answers, decoded into what AuthenticationServices takes, and the credential it
// answers with, encoded into the JSON a browser's `toJSON()` produces for the Finish call.
// Every binary field is base64url, unpadded, in both directions, never base64.

/// PasskeyBridgeError is options or a credential the bridge cannot carry across.
public struct PasskeyBridgeError: Error, Sendable, Hashable, CustomStringConvertible {
  public let description: String

  init(_ description: String) {
    self.description = description
  }
}

/// PasskeyAttachment is how the authenticator was reached: this device's own, or another one,
/// a phone over hybrid or a security key.
public enum PasskeyAttachment: String, Sendable, Hashable {
  case platform
  case crossPlatform = "cross-platform"
}

/// PasskeyAssertionOptions is BeginLogin's options, the PublicKeyCredentialRequestOptions JSON.
public struct PasskeyAssertionOptions: Sendable, Hashable {
  public var challenge: Data
  public var relyingPartyID: String
  /// allowedCredentialIDs is empty for a discoverable login.
  public var allowedCredentialIDs: [Data]
  /// userVerification is what the server asked for, `required`, `preferred` or
  /// `discouraged`, and empty when it asked nothing.
  public var userVerification: String

  /// init(json:) reads the options either as the server sends them, under `publicKey`, or
  /// bare, as a browser's `parseRequestOptionsFromJSON` reads them.
  public init(json: Data) throws {
    let options = try decodeOptions(RequestOptionsJSON.self, from: json)
    guard let rpID = options.rpId, !rpID.isEmpty else {
      throw PasskeyBridgeError("the passkey request options name no rpId")
    }
    challenge = options.challenge.data
    relyingPartyID = rpID
    allowedCredentialIDs = (options.allowCredentials ?? []).map(\.id.data)
    userVerification = options.userVerification ?? ""
  }
}

/// PasskeyRegistrationOptions is BeginRegistration's options, the
/// PublicKeyCredentialCreationOptions JSON.
public struct PasskeyRegistrationOptions: Sendable, Hashable {
  public var challenge: Data
  public var relyingPartyID: String
  /// userID is the caller's WebAuthn user handle, which a discoverable login's authenticator
  /// returns as the assertion's `userHandle`.
  public var userID: Data
  public var userName: String
  /// excludedCredentialIDs are the caller's existing passkeys, which an authenticator already
  /// holding one of declines to register again.
  public var excludedCredentialIDs: [Data]
  /// userVerification is what the server asked for, and empty when it asked nothing.
  public var userVerification: String
  /// attestation is the conveyance the server asked for, and empty when it asked nothing.
  public var attestation: String

  /// init(json:) reads the options either as the server sends them, under `publicKey`, or
  /// bare, as a browser's `parseCreationOptionsFromJSON` reads them.
  public init(json: Data) throws {
    let options = try decodeOptions(CreationOptionsJSON.self, from: json)
    guard !options.rp.id.isEmpty else {
      throw PasskeyBridgeError("the passkey creation options name no rp.id")
    }
    challenge = options.challenge.data
    relyingPartyID = options.rp.id
    userID = options.user.id.data
    userName = options.user.name
    excludedCredentialIDs = (options.excludeCredentials ?? []).map(\.id.data)
    userVerification = options.authenticatorSelection?.userVerification ?? ""
    attestation = options.attestation ?? ""
  }
}

/// PasskeyAssertion is the credential a passkey sign-in's ceremony answered with.
public struct PasskeyAssertion: Sendable, Hashable {
  public var credentialID: Data
  public var clientDataJSON: Data
  public var authenticatorData: Data
  public var signature: Data
  /// userHandle is the user handle the authenticator holds, which a discoverable login is
  /// resolved by. nil when it returned none.
  public var userHandle: Data?
  public var attachment: PasskeyAttachment?

  public init(
    credentialID: Data,
    clientDataJSON: Data,
    authenticatorData: Data,
    signature: Data,
    userHandle: Data? = nil,
    attachment: PasskeyAttachment? = nil
  ) {
    self.credentialID = credentialID
    self.clientDataJSON = clientDataJSON
    self.authenticatorData = authenticatorData
    self.signature = signature
    self.userHandle = userHandle
    self.attachment = attachment
  }

  /// json is the assertion as a browser's `PublicKeyCredential.toJSON()` renders it, which is
  /// what `PasskeySignIn.response` carries.
  public func json() throws -> Data {
    try encodeCredential(
      id: credentialID,
      attachment: attachment,
      response: AssertionResponseJSON(
        clientDataJSON: Base64URL(clientDataJSON),
        authenticatorData: Base64URL(authenticatorData),
        signature: Base64URL(signature),
        userHandle: userHandle.map(Base64URL.init)))
  }
}

/// PasskeyRegistration is the credential a passkey registration's ceremony answered with.
public struct PasskeyRegistration: Sendable, Hashable {
  public var credentialID: Data
  public var clientDataJSON: Data
  public var attestationObject: Data
  public var attachment: PasskeyAttachment?

  public init(
    credentialID: Data,
    clientDataJSON: Data,
    attestationObject: Data,
    attachment: PasskeyAttachment? = nil
  ) {
    self.credentialID = credentialID
    self.clientDataJSON = clientDataJSON
    self.attestationObject = attestationObject
    self.attachment = attachment
  }

  /// json is the registration as a browser's `PublicKeyCredential.toJSON()` renders it, which
  /// is what FinishRegistration's `response` carries.
  public func json() throws -> Data {
    try encodeCredential(
      id: credentialID,
      attachment: attachment,
      response: RegistrationResponseJSON(
        clientDataJSON: Base64URL(clientDataJSON),
        attestationObject: Base64URL(attestationObject)))
  }
}

#if canImport(AuthenticationServices)
  extension PasskeyAssertionOptions {
    /// request is the assertion request to hand an ASAuthorizationController.
    ///
    /// It asks for user verification, Face ID or the passcode, whatever the server asked,
    /// because a verified passkey is two factors on its own. That makes R19's
    /// `secondFactorRequired` unreachable through this bridge by default: only a key tapped
    /// without verification is one factor. Pass `userVerification` to ask for something else,
    /// such as the server's own `userVerification`.
    public func request(
      userVerification: ASAuthorizationPublicKeyCredentialUserVerificationPreference = .required
    ) -> ASAuthorizationPlatformPublicKeyCredentialAssertionRequest {
      let provider = ASAuthorizationPlatformPublicKeyCredentialProvider(
        relyingPartyIdentifier: relyingPartyID)
      let request = provider.createCredentialAssertionRequest(challenge: challenge)
      request.allowedCredentials = allowedCredentialIDs.map {
        ASAuthorizationPlatformPublicKeyCredentialDescriptor(credentialID: $0)
      }
      request.userVerificationPreference = userVerification
      return request
    }
  }

  extension PasskeyRegistrationOptions {
    /// request is the registration request to hand an ASAuthorizationController. It asks for
    /// user verification whatever the server asked, as `PasskeyAssertionOptions.request` does,
    /// and for the server's attestation conveyance where it named one.
    public func request(
      userVerification: ASAuthorizationPublicKeyCredentialUserVerificationPreference = .required
    ) -> ASAuthorizationPlatformPublicKeyCredentialRegistrationRequest {
      let provider = ASAuthorizationPlatformPublicKeyCredentialProvider(
        relyingPartyIdentifier: relyingPartyID)
      let request = provider.createCredentialRegistrationRequest(
        challenge: challenge, name: userName, userID: userID)
      request.excludedCredentials = excludedCredentialIDs.map {
        ASAuthorizationPlatformPublicKeyCredentialDescriptor(credentialID: $0)
      }
      request.userVerificationPreference = userVerification
      if !attestation.isEmpty {
        request.attestationPreference = .init(rawValue: attestation)
      }
      return request
    }
  }

  extension PasskeyAssertion {
    /// init(_:) reads the credential an ASAuthorizationController answered an assertion
    /// request with.
    public init(_ credential: ASAuthorizationPlatformPublicKeyCredentialAssertion) throws {
      guard let authenticatorData = credential.rawAuthenticatorData else {
        throw PasskeyBridgeError("the passkey assertion carries no authenticator data")
      }
      guard let signature = credential.signature else {
        throw PasskeyBridgeError("the passkey assertion carries no signature")
      }
      let userHandle = credential.userID.flatMap { $0.isEmpty ? nil : $0 }
      self.init(
        credentialID: credential.credentialID,
        clientDataJSON: credential.rawClientDataJSON,
        authenticatorData: authenticatorData,
        signature: signature,
        userHandle: userHandle,
        attachment: PasskeyAttachment(credential.attachment))
    }
  }

  extension PasskeyRegistration {
    /// init(_:) reads the credential an ASAuthorizationController answered a registration
    /// request with.
    public init(_ credential: ASAuthorizationPlatformPublicKeyCredentialRegistration) throws {
      guard let attestationObject = credential.rawAttestationObject else {
        throw PasskeyBridgeError("the passkey registration carries no attestation object")
      }
      self.init(
        credentialID: credential.credentialID,
        clientDataJSON: credential.rawClientDataJSON,
        attestationObject: attestationObject,
        attachment: PasskeyAttachment(credential.attachment))
    }
  }

  extension PasskeyAttachment {
    init?(_ attachment: ASAuthorizationPublicKeyCredentialAttachment) {
      switch attachment {
      case .platform: self = .platform
      case .crossPlatform: self = .crossPlatform
      @unknown default: return nil
      }
    }
  }
#endif

// MARK: - JSON

/// Base64URL is binary as WebAuthn JSON carries it. It reads padded and unpadded alike, as
/// the server does, and writes unpadded, as a browser does.
struct Base64URL: Codable, Hashable {
  let data: Data

  init(_ data: Data) {
    self.data = data
  }

  init(from decoder: any Decoder) throws {
    let container = try decoder.singleValueContainer()
    let text = try container.decode(String.self)
    var base64 =
      text
      .trimmingCharacters(in: CharacterSet(charactersIn: "="))
      .replacingOccurrences(of: "-", with: "+")
      .replacingOccurrences(of: "_", with: "/")
    base64 += String(repeating: "=", count: (4 - base64.count % 4) % 4)
    guard !text.contains(where: { $0 == "+" || $0 == "/" }), let data = Data(base64Encoded: base64)
    else {
      throw DecodingError.dataCorruptedError(
        in: container, debugDescription: "\(text) is not base64url")
    }
    self.data = data
  }

  func encode(to encoder: any Encoder) throws {
    var container = encoder.singleValueContainer()
    try container.encode(
      data.base64EncodedString()
        .replacingOccurrences(of: "+", with: "-")
        .replacingOccurrences(of: "/", with: "_")
        .trimmingCharacters(in: CharacterSet(charactersIn: "=")))
  }
}

private struct CredentialDescriptorJSON: Decodable {
  let id: Base64URL
}

private struct RequestOptionsJSON: Decodable {
  let challenge: Base64URL
  let rpId: String?
  let allowCredentials: [CredentialDescriptorJSON]?
  let userVerification: String?
}

private struct CreationOptionsJSON: Decodable {
  struct RelyingParty: Decodable {
    let id: String
  }

  struct User: Decodable {
    let id: Base64URL
    let name: String
  }

  struct AuthenticatorSelection: Decodable {
    let userVerification: String?
  }

  let rp: RelyingParty
  let user: User
  let challenge: Base64URL
  let excludeCredentials: [CredentialDescriptorJSON]?
  let authenticatorSelection: AuthenticatorSelection?
  let attestation: String?
}

/// OptionsEnvelope is go-webauthn's CredentialAssertion and CredentialCreation, which carry
/// the options under `publicKey`.
private struct OptionsEnvelope<Options: Decodable>: Decodable {
  let publicKey: Options?
}

private func decodeOptions<Options: Decodable>(
  _: Options.Type, from json: Data
) throws -> Options {
  let decoder = JSONDecoder()
  if let options = try decoder.decode(OptionsEnvelope<Options>.self, from: json).publicKey {
    return options
  }
  return try decoder.decode(Options.self, from: json)
}

private struct AssertionResponseJSON: Encodable {
  let clientDataJSON: Base64URL
  let authenticatorData: Base64URL
  let signature: Base64URL
  let userHandle: Base64URL?
}

private struct RegistrationResponseJSON: Encodable {
  let clientDataJSON: Base64URL
  let attestationObject: Base64URL
}

private struct CredentialJSON<Response: Encodable>: Encodable {
  let id: Base64URL
  let rawId: Base64URL
  let type = "public-key"
  let response: Response
  let authenticatorAttachment: String?
  let clientExtensionResults: [String: String] = [:]
}

private func encodeCredential(
  id: Data, attachment: PasskeyAttachment?, response: some Encodable
) throws -> Data {
  let encoder = JSONEncoder()
  encoder.outputFormatting = [.sortedKeys, .withoutEscapingSlashes]
  return try encoder.encode(
    CredentialJSON(
      id: Base64URL(id), rawId: Base64URL(id), response: response,
      authenticatorAttachment: attachment?.rawValue))
}
