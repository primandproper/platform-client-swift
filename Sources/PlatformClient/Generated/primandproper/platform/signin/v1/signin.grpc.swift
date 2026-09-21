// Package primandproper.platform.signin.v1 is the wire schema for proving
// somebody is who they say they are: registering them, the password door, the
// administrative door, the credential writes they make about themselves, and
// the two reads a client makes on load.
//
// This file is shipped inside the published Go module, and it is the file
// itself that is shipped -- not a copy for you to keep in sync. A consumer puts
// the module's proto directories on protoc's path and imports this file by its
// canonical name, exactly as identity.proto and filtering.proto already work:
//
//	PLATFORM_PROTO := $(shell go list -m -f '{{.Dir}}' github.com/primandproper/platform-go/v14)
//
//	protoc --proto_path proto/ \
//	    --proto_path $(PLATFORM_PROTO)/authentication/signin/proto \
//	    --proto_path $(PLATFORM_PROTO)/identity/proto \
//	    --proto_path $(PLATFORM_PROTO)/filtering/proto \
//	    --go_opt=Mprimandproper/platform/signin/v1/signin.proto=github.com/primandproper/platform-go/v14/authentication/signin/signinpb \
//	    --go_opt=Mprimandproper/platform/identity/v1/identity.proto=github.com/primandproper/platform-go/v14/identity/identitypb \
//	    $(CONSUMER_PROTO_FILES)   # the platform files deliberately absent from that list
//
// Go links against the bindings this module already generated, in
// github.com/primandproper/platform-go/v14/authentication/signin/signinpb.
// Swift, TypeScript and Kotlin have no such bindings to link against and
// generate this file directly, which is the whole point of shipping the schema.
//
// Field numbers are the compatibility promise, across every language a consumer
// generates into. Numbers are never reused and never repurposed: a field that
// goes away is reserved.
//
// # The user, and why it is identity's
//
// This file imports identity.proto and answers with its User rather than
// defining one of its own. There is one directory and one user, and a sign-in
// service that shipped a second message for the same row would be a second
// message a client has to convert between -- for the sole benefit of not having
// to put two files on protoc's path. What this file adds beside that user is
// [AuthStatus], which carries the three facts a redacted user cannot: whether
// they hold a password at all, whether their second factor has actually been
// proven, whether their address has been. All three are computed from columns no
// response ever carries.
//
// # What is not here, and why
//
// No scope field, anywhere, and the name is reserved so there cannot be one.
// The reason identity.proto gives at greater length: a scope a client could
// name is a cross-tenant read hiding behind a request field. Sign-in is the one
// place in the module where the scope cannot come off a principal, because the
// caller has not proved they are one yet, so it comes off the connection
// instead -- a resolver the consumer supplies, from a host, a header, or
// nothing at all in a single-tenant deployment. See authentication/signin/grpc.
//
// That is what makes the reservation matter more here than anywhere else on
// this lane. Every other surface resolves the scope from a caller who has
// already been authenticated; these two doors resolve it for a request nobody
// has vouched for, so a scope field would be one an anonymous caller fills in.
// Reserving the name rather than only saying so is audit.proto's pattern:
// `reserved "scope";` is a schema protoc refuses to accept a scope field into,
// in this repository and in a consumer's fork of the file alike, whereas a
// comment is a request to the next author. It is reserved on every request
// message, on the inputs they are built from -- [Credentials],
// [RegistrationInvitation] -- and on [IssuedToken], [AuthStatus] and
// [Registered], which the responses are built from.
//
// No hashed password and no stored second-factor secret, in either direction.
// The two secrets that do cross are the ones that have to: a plaintext password
// on the way in, which is the only thing a password can be proved with, and a
// freshly minted TOTP secret on the way out, which is the whole content of an
// enrollment. Both make this service's transport security a requirement rather
// than a recommendation -- see [RefreshTOTPSecretResponse] for what the second
// one costs.
//
// A refresh token, and still no session. [IssuedToken] carries a second
// credential that mints the first again without a password, and a family
// identifier naming the login both belong to. What it does not carry is a
// session: keeping either token in a cookie is
// github.com/primandproper/platform-go/v14/sessions, and turning one back into a
// caller is the consumer's interceptor. Neither is a decision a schema should be
// making for everybody.
//
// A service that stores no refresh tokens leaves both new fields empty, which is
// the shape this file described before they existed and is still a valid one --
// see signin.WithRefreshTokenStore. family_id is populated either way, because it
// names a sign-in rather than a stored row, and it is the same value the access
// token carries as its conventional "sid" claim.
//
// Registration is here, and the password is why. identity's schema carries no
// password in either direction and should not: that package never hashes, it
// stores what an engine produced, so a plaintext password on its wire would put
// the choice of hashing engine into the transport. This service holds the
// authenticator, so a registration that carries a credential is its RPC --
// Register below hashes what arrives and hands identity the hash. The directory
// work is still identity's, done through its own service on one transaction.
//
// A registration names the credential the registrant chose, as a oneof, and a
// request that names neither arm is refused rather than read as passwordless.
// Choosing email-only authentication and forgetting to populate a password
// field look identical to a server reading an empty string, and the first is a
// product decision while the second mints an account nobody can reach. A oneof
// is what makes that distinction the schema's rather than one server's.
//
// No verification token in any response. The secret a registration mints
// travels to the person it is about, in mail the consumer sends from inside the
// transaction that wrote the row -- it is never handed back to whoever called
// Register, who is a client rather than the subject. It arrives back here only
// as a request field on the two RPCs that answer a link, which is identity's
// rule for an invitation's token and is the same rule for the same reason.
//
// No passkeys, no password reset and no session management. Each is a flow of
// its own over an engine this module already ships, and each is its own file
// rather than a branch in this one. Email-link sign-in -- a door that mints a
// token from a clicked link rather than from a password -- is not here either:
// it is a sibling of LoginForToken rather than a branch inside it, and it is
// the one thing a registrant who named no password still needs.

// DO NOT EDIT.
// swift-format-ignore-file
// swiftlint:disable all
//
// Generated by the gRPC Swift generator plugin for the protocol buffer compiler.
// Source: primandproper/platform/signin/v1/signin.proto
//
// For information on using the generated types, please see the documentation:
//   https://github.com/grpc/grpc-swift

import GRPCCore
import GRPCProtobuf

// MARK: - primandproper.platform.signin.v1.SignInService

/// Namespace containing generated types for the "primandproper.platform.signin.v1.SignInService" service.
@available(macOS 15.0, iOS 18.0, watchOS 11.0, tvOS 18.0, visionOS 2.0, *)
internal enum Primandproper_Platform_Signin_V1_SignInService {
    /// Service descriptor for the "primandproper.platform.signin.v1.SignInService" service.
    internal static let descriptor = GRPCCore.ServiceDescriptor(fullyQualifiedService: "primandproper.platform.signin.v1.SignInService")
    /// Namespace for method metadata.
    internal enum Method {
        /// Namespace for "Register" metadata.
        internal enum Register {
            /// Request type for "Register".
            internal typealias Input = Primandproper_Platform_Signin_V1_RegisterRequest
            /// Response type for "Register".
            internal typealias Output = Primandproper_Platform_Signin_V1_RegisterResponse
            /// Descriptor for "Register".
            internal static let descriptor = GRPCCore.MethodDescriptor(
                service: GRPCCore.ServiceDescriptor(fullyQualifiedService: "primandproper.platform.signin.v1.SignInService"),
                method: "Register"
            )
        }
        /// Namespace for "AttachPassword" metadata.
        internal enum AttachPassword {
            /// Request type for "AttachPassword".
            internal typealias Input = Primandproper_Platform_Signin_V1_AttachPasswordRequest
            /// Response type for "AttachPassword".
            internal typealias Output = Primandproper_Platform_Signin_V1_AttachPasswordResponse
            /// Descriptor for "AttachPassword".
            internal static let descriptor = GRPCCore.MethodDescriptor(
                service: GRPCCore.ServiceDescriptor(fullyQualifiedService: "primandproper.platform.signin.v1.SignInService"),
                method: "AttachPassword"
            )
        }
        /// Namespace for "VerifyEmailAddress" metadata.
        internal enum VerifyEmailAddress {
            /// Request type for "VerifyEmailAddress".
            internal typealias Input = Primandproper_Platform_Signin_V1_VerifyEmailAddressRequest
            /// Response type for "VerifyEmailAddress".
            internal typealias Output = Primandproper_Platform_Signin_V1_VerifyEmailAddressResponse
            /// Descriptor for "VerifyEmailAddress".
            internal static let descriptor = GRPCCore.MethodDescriptor(
                service: GRPCCore.ServiceDescriptor(fullyQualifiedService: "primandproper.platform.signin.v1.SignInService"),
                method: "VerifyEmailAddress"
            )
        }
        /// Namespace for "RequestMagicLink" metadata.
        internal enum RequestMagicLink {
            /// Request type for "RequestMagicLink".
            internal typealias Input = Primandproper_Platform_Signin_V1_RequestMagicLinkRequest
            /// Response type for "RequestMagicLink".
            internal typealias Output = Primandproper_Platform_Signin_V1_RequestMagicLinkResponse
            /// Descriptor for "RequestMagicLink".
            internal static let descriptor = GRPCCore.MethodDescriptor(
                service: GRPCCore.ServiceDescriptor(fullyQualifiedService: "primandproper.platform.signin.v1.SignInService"),
                method: "RequestMagicLink"
            )
        }
        /// Namespace for "RedeemMagicLink" metadata.
        internal enum RedeemMagicLink {
            /// Request type for "RedeemMagicLink".
            internal typealias Input = Primandproper_Platform_Signin_V1_RedeemMagicLinkRequest
            /// Response type for "RedeemMagicLink".
            internal typealias Output = Primandproper_Platform_Signin_V1_RedeemMagicLinkResponse
            /// Descriptor for "RedeemMagicLink".
            internal static let descriptor = GRPCCore.MethodDescriptor(
                service: GRPCCore.ServiceDescriptor(fullyQualifiedService: "primandproper.platform.signin.v1.SignInService"),
                method: "RedeemMagicLink"
            )
        }
        /// Namespace for "LoginForToken" metadata.
        internal enum LoginForToken {
            /// Request type for "LoginForToken".
            internal typealias Input = Primandproper_Platform_Signin_V1_LoginForTokenRequest
            /// Response type for "LoginForToken".
            internal typealias Output = Primandproper_Platform_Signin_V1_LoginForTokenResponse
            /// Descriptor for "LoginForToken".
            internal static let descriptor = GRPCCore.MethodDescriptor(
                service: GRPCCore.ServiceDescriptor(fullyQualifiedService: "primandproper.platform.signin.v1.SignInService"),
                method: "LoginForToken"
            )
        }
        /// Namespace for "AdminLoginForToken" metadata.
        internal enum AdminLoginForToken {
            /// Request type for "AdminLoginForToken".
            internal typealias Input = Primandproper_Platform_Signin_V1_AdminLoginForTokenRequest
            /// Response type for "AdminLoginForToken".
            internal typealias Output = Primandproper_Platform_Signin_V1_AdminLoginForTokenResponse
            /// Descriptor for "AdminLoginForToken".
            internal static let descriptor = GRPCCore.MethodDescriptor(
                service: GRPCCore.ServiceDescriptor(fullyQualifiedService: "primandproper.platform.signin.v1.SignInService"),
                method: "AdminLoginForToken"
            )
        }
        /// Namespace for "ExchangeRefreshToken" metadata.
        internal enum ExchangeRefreshToken {
            /// Request type for "ExchangeRefreshToken".
            internal typealias Input = Primandproper_Platform_Signin_V1_ExchangeRefreshTokenRequest
            /// Response type for "ExchangeRefreshToken".
            internal typealias Output = Primandproper_Platform_Signin_V1_ExchangeRefreshTokenResponse
            /// Descriptor for "ExchangeRefreshToken".
            internal static let descriptor = GRPCCore.MethodDescriptor(
                service: GRPCCore.ServiceDescriptor(fullyQualifiedService: "primandproper.platform.signin.v1.SignInService"),
                method: "ExchangeRefreshToken"
            )
        }
        /// Namespace for "GetAuthStatus" metadata.
        internal enum GetAuthStatus {
            /// Request type for "GetAuthStatus".
            internal typealias Input = Primandproper_Platform_Signin_V1_GetAuthStatusRequest
            /// Response type for "GetAuthStatus".
            internal typealias Output = Primandproper_Platform_Signin_V1_GetAuthStatusResponse
            /// Descriptor for "GetAuthStatus".
            internal static let descriptor = GRPCCore.MethodDescriptor(
                service: GRPCCore.ServiceDescriptor(fullyQualifiedService: "primandproper.platform.signin.v1.SignInService"),
                method: "GetAuthStatus"
            )
        }
        /// Namespace for "GetSelf" metadata.
        internal enum GetSelf {
            /// Request type for "GetSelf".
            internal typealias Input = Primandproper_Platform_Signin_V1_GetSelfRequest
            /// Response type for "GetSelf".
            internal typealias Output = Primandproper_Platform_Signin_V1_GetSelfResponse
            /// Descriptor for "GetSelf".
            internal static let descriptor = GRPCCore.MethodDescriptor(
                service: GRPCCore.ServiceDescriptor(fullyQualifiedService: "primandproper.platform.signin.v1.SignInService"),
                method: "GetSelf"
            )
        }
        /// Namespace for "UpdatePassword" metadata.
        internal enum UpdatePassword {
            /// Request type for "UpdatePassword".
            internal typealias Input = Primandproper_Platform_Signin_V1_UpdatePasswordRequest
            /// Response type for "UpdatePassword".
            internal typealias Output = Primandproper_Platform_Signin_V1_UpdatePasswordResponse
            /// Descriptor for "UpdatePassword".
            internal static let descriptor = GRPCCore.MethodDescriptor(
                service: GRPCCore.ServiceDescriptor(fullyQualifiedService: "primandproper.platform.signin.v1.SignInService"),
                method: "UpdatePassword"
            )
        }
        /// Namespace for "RefreshTOTPSecret" metadata.
        internal enum RefreshTOTPSecret {
            /// Request type for "RefreshTOTPSecret".
            internal typealias Input = Primandproper_Platform_Signin_V1_RefreshTOTPSecretRequest
            /// Response type for "RefreshTOTPSecret".
            internal typealias Output = Primandproper_Platform_Signin_V1_RefreshTOTPSecretResponse
            /// Descriptor for "RefreshTOTPSecret".
            internal static let descriptor = GRPCCore.MethodDescriptor(
                service: GRPCCore.ServiceDescriptor(fullyQualifiedService: "primandproper.platform.signin.v1.SignInService"),
                method: "RefreshTOTPSecret"
            )
        }
        /// Namespace for "VerifyTOTPSecret" metadata.
        internal enum VerifyTOTPSecret {
            /// Request type for "VerifyTOTPSecret".
            internal typealias Input = Primandproper_Platform_Signin_V1_VerifyTOTPSecretRequest
            /// Response type for "VerifyTOTPSecret".
            internal typealias Output = Primandproper_Platform_Signin_V1_VerifyTOTPSecretResponse
            /// Descriptor for "VerifyTOTPSecret".
            internal static let descriptor = GRPCCore.MethodDescriptor(
                service: GRPCCore.ServiceDescriptor(fullyQualifiedService: "primandproper.platform.signin.v1.SignInService"),
                method: "VerifyTOTPSecret"
            )
        }
        /// Descriptors for all methods in the "primandproper.platform.signin.v1.SignInService" service.
        internal static let descriptors: [GRPCCore.MethodDescriptor] = [
            Register.descriptor,
            AttachPassword.descriptor,
            VerifyEmailAddress.descriptor,
            RequestMagicLink.descriptor,
            RedeemMagicLink.descriptor,
            LoginForToken.descriptor,
            AdminLoginForToken.descriptor,
            ExchangeRefreshToken.descriptor,
            GetAuthStatus.descriptor,
            GetSelf.descriptor,
            UpdatePassword.descriptor,
            RefreshTOTPSecret.descriptor,
            VerifyTOTPSecret.descriptor
        ]
    }
}

@available(macOS 15.0, iOS 18.0, watchOS 11.0, tvOS 18.0, visionOS 2.0, *)
extension GRPCCore.ServiceDescriptor {
    /// Service descriptor for the "primandproper.platform.signin.v1.SignInService" service.
    internal static let primandproper_platform_signin_v1_SignInService = GRPCCore.ServiceDescriptor(fullyQualifiedService: "primandproper.platform.signin.v1.SignInService")
}

// MARK: primandproper.platform.signin.v1.SignInService (client)

@available(macOS 15.0, iOS 18.0, watchOS 11.0, tvOS 18.0, visionOS 2.0, *)
extension Primandproper_Platform_Signin_V1_SignInService {
    /// Generated client protocol for the "primandproper.platform.signin.v1.SignInService" service.
    ///
    /// You don't need to implement this protocol directly, use the generated
    /// implementation, ``Client``.
    ///
    /// > Source IDL Documentation:
    /// >
    /// > SignInService is sign-in.
    /// > 
    /// > Eight of its RPCs are anonymous by definition and five require a caller. What
    /// > none of them requires is a permission: there is no grant that would make
    /// > "sign in" safer, and the four authenticated ones take their subject from the
    /// > caller and have no field that could name anybody else. See
    /// > authentication/signin/grpc's Require for how that is declared to an
    /// > authorization policy, which is not the same thing as being left out of one.
    internal protocol ClientProtocol: Sendable {
        /// Call the "Register" method.
        ///
        /// > Source IDL Documentation:
        /// >
        /// > Arriving, and the two ways a registration is finished. Register requires a
        /// > caller -- the consumer's own registrar, for the reason identity's Register
        /// > requires one: an open sign-up is a flow with policy in it, a captcha, a rate
        /// > limit, an email domain rule, and this service holds none of that. The other
        /// > two are anonymous and carry their own authority, which is the token that was
        /// > mailed to the person they are about.
        ///
        /// - Parameters:
        ///   - request: A request containing a single `Primandproper_Platform_Signin_V1_RegisterRequest` message.
        ///   - serializer: A serializer for `Primandproper_Platform_Signin_V1_RegisterRequest` messages.
        ///   - deserializer: A deserializer for `Primandproper_Platform_Signin_V1_RegisterResponse` messages.
        ///   - options: Options to apply to this RPC.
        ///   - handleResponse: A closure which handles the response, the result of which is
        ///       returned to the caller. Returning from the closure will cancel the RPC if it
        ///       hasn't already finished.
        /// - Returns: The result of `handleResponse`.
        func register<Result>(
            request: GRPCCore.ClientRequest<Primandproper_Platform_Signin_V1_RegisterRequest>,
            serializer: some GRPCCore.MessageSerializer<Primandproper_Platform_Signin_V1_RegisterRequest>,
            deserializer: some GRPCCore.MessageDeserializer<Primandproper_Platform_Signin_V1_RegisterResponse>,
            options: GRPCCore.CallOptions,
            onResponse handleResponse: @Sendable @escaping (GRPCCore.ClientResponse<Primandproper_Platform_Signin_V1_RegisterResponse>) async throws -> Result
        ) async throws -> Result where Result: Sendable

        /// Call the "AttachPassword" method.
        ///
        /// - Parameters:
        ///   - request: A request containing a single `Primandproper_Platform_Signin_V1_AttachPasswordRequest` message.
        ///   - serializer: A serializer for `Primandproper_Platform_Signin_V1_AttachPasswordRequest` messages.
        ///   - deserializer: A deserializer for `Primandproper_Platform_Signin_V1_AttachPasswordResponse` messages.
        ///   - options: Options to apply to this RPC.
        ///   - handleResponse: A closure which handles the response, the result of which is
        ///       returned to the caller. Returning from the closure will cancel the RPC if it
        ///       hasn't already finished.
        /// - Returns: The result of `handleResponse`.
        func attachPassword<Result>(
            request: GRPCCore.ClientRequest<Primandproper_Platform_Signin_V1_AttachPasswordRequest>,
            serializer: some GRPCCore.MessageSerializer<Primandproper_Platform_Signin_V1_AttachPasswordRequest>,
            deserializer: some GRPCCore.MessageDeserializer<Primandproper_Platform_Signin_V1_AttachPasswordResponse>,
            options: GRPCCore.CallOptions,
            onResponse handleResponse: @Sendable @escaping (GRPCCore.ClientResponse<Primandproper_Platform_Signin_V1_AttachPasswordResponse>) async throws -> Result
        ) async throws -> Result where Result: Sendable

        /// Call the "VerifyEmailAddress" method.
        ///
        /// - Parameters:
        ///   - request: A request containing a single `Primandproper_Platform_Signin_V1_VerifyEmailAddressRequest` message.
        ///   - serializer: A serializer for `Primandproper_Platform_Signin_V1_VerifyEmailAddressRequest` messages.
        ///   - deserializer: A deserializer for `Primandproper_Platform_Signin_V1_VerifyEmailAddressResponse` messages.
        ///   - options: Options to apply to this RPC.
        ///   - handleResponse: A closure which handles the response, the result of which is
        ///       returned to the caller. Returning from the closure will cancel the RPC if it
        ///       hasn't already finished.
        /// - Returns: The result of `handleResponse`.
        func verifyEmailAddress<Result>(
            request: GRPCCore.ClientRequest<Primandproper_Platform_Signin_V1_VerifyEmailAddressRequest>,
            serializer: some GRPCCore.MessageSerializer<Primandproper_Platform_Signin_V1_VerifyEmailAddressRequest>,
            deserializer: some GRPCCore.MessageDeserializer<Primandproper_Platform_Signin_V1_VerifyEmailAddressResponse>,
            options: GRPCCore.CallOptions,
            onResponse handleResponse: @Sendable @escaping (GRPCCore.ClientResponse<Primandproper_Platform_Signin_V1_VerifyEmailAddressResponse>) async throws -> Result
        ) async throws -> Result where Result: Sendable

        /// Call the "RequestMagicLink" method.
        ///
        /// > Source IDL Documentation:
        /// >
        /// > The passwordless door, both halves anonymous. Requesting a link names an
        /// > address and is answered the same way whoever holds it; redeeming one carries
        /// > the token that was mailed, which is the whole of its authority. Neither can
        /// > name a user, so neither is a way to ask about one.
        /// > 
        /// > Rate limiting is the consumer's, in front of RequestMagicLink, and it is not
        /// > optional: this is the one RPC in this service that sends mail on request.
        ///
        /// - Parameters:
        ///   - request: A request containing a single `Primandproper_Platform_Signin_V1_RequestMagicLinkRequest` message.
        ///   - serializer: A serializer for `Primandproper_Platform_Signin_V1_RequestMagicLinkRequest` messages.
        ///   - deserializer: A deserializer for `Primandproper_Platform_Signin_V1_RequestMagicLinkResponse` messages.
        ///   - options: Options to apply to this RPC.
        ///   - handleResponse: A closure which handles the response, the result of which is
        ///       returned to the caller. Returning from the closure will cancel the RPC if it
        ///       hasn't already finished.
        /// - Returns: The result of `handleResponse`.
        func requestMagicLink<Result>(
            request: GRPCCore.ClientRequest<Primandproper_Platform_Signin_V1_RequestMagicLinkRequest>,
            serializer: some GRPCCore.MessageSerializer<Primandproper_Platform_Signin_V1_RequestMagicLinkRequest>,
            deserializer: some GRPCCore.MessageDeserializer<Primandproper_Platform_Signin_V1_RequestMagicLinkResponse>,
            options: GRPCCore.CallOptions,
            onResponse handleResponse: @Sendable @escaping (GRPCCore.ClientResponse<Primandproper_Platform_Signin_V1_RequestMagicLinkResponse>) async throws -> Result
        ) async throws -> Result where Result: Sendable

        /// Call the "RedeemMagicLink" method.
        ///
        /// - Parameters:
        ///   - request: A request containing a single `Primandproper_Platform_Signin_V1_RedeemMagicLinkRequest` message.
        ///   - serializer: A serializer for `Primandproper_Platform_Signin_V1_RedeemMagicLinkRequest` messages.
        ///   - deserializer: A deserializer for `Primandproper_Platform_Signin_V1_RedeemMagicLinkResponse` messages.
        ///   - options: Options to apply to this RPC.
        ///   - handleResponse: A closure which handles the response, the result of which is
        ///       returned to the caller. Returning from the closure will cancel the RPC if it
        ///       hasn't already finished.
        /// - Returns: The result of `handleResponse`.
        func redeemMagicLink<Result>(
            request: GRPCCore.ClientRequest<Primandproper_Platform_Signin_V1_RedeemMagicLinkRequest>,
            serializer: some GRPCCore.MessageSerializer<Primandproper_Platform_Signin_V1_RedeemMagicLinkRequest>,
            deserializer: some GRPCCore.MessageDeserializer<Primandproper_Platform_Signin_V1_RedeemMagicLinkResponse>,
            options: GRPCCore.CallOptions,
            onResponse handleResponse: @Sendable @escaping (GRPCCore.ClientResponse<Primandproper_Platform_Signin_V1_RedeemMagicLinkResponse>) async throws -> Result
        ) async throws -> Result where Result: Sendable

        /// Call the "LoginForToken" method.
        ///
        /// > Source IDL Documentation:
        /// >
        /// > The two doors, and the one that keeps a sign-in alive without reopening
        /// > either of them.
        ///
        /// - Parameters:
        ///   - request: A request containing a single `Primandproper_Platform_Signin_V1_LoginForTokenRequest` message.
        ///   - serializer: A serializer for `Primandproper_Platform_Signin_V1_LoginForTokenRequest` messages.
        ///   - deserializer: A deserializer for `Primandproper_Platform_Signin_V1_LoginForTokenResponse` messages.
        ///   - options: Options to apply to this RPC.
        ///   - handleResponse: A closure which handles the response, the result of which is
        ///       returned to the caller. Returning from the closure will cancel the RPC if it
        ///       hasn't already finished.
        /// - Returns: The result of `handleResponse`.
        func loginForToken<Result>(
            request: GRPCCore.ClientRequest<Primandproper_Platform_Signin_V1_LoginForTokenRequest>,
            serializer: some GRPCCore.MessageSerializer<Primandproper_Platform_Signin_V1_LoginForTokenRequest>,
            deserializer: some GRPCCore.MessageDeserializer<Primandproper_Platform_Signin_V1_LoginForTokenResponse>,
            options: GRPCCore.CallOptions,
            onResponse handleResponse: @Sendable @escaping (GRPCCore.ClientResponse<Primandproper_Platform_Signin_V1_LoginForTokenResponse>) async throws -> Result
        ) async throws -> Result where Result: Sendable

        /// Call the "AdminLoginForToken" method.
        ///
        /// - Parameters:
        ///   - request: A request containing a single `Primandproper_Platform_Signin_V1_AdminLoginForTokenRequest` message.
        ///   - serializer: A serializer for `Primandproper_Platform_Signin_V1_AdminLoginForTokenRequest` messages.
        ///   - deserializer: A deserializer for `Primandproper_Platform_Signin_V1_AdminLoginForTokenResponse` messages.
        ///   - options: Options to apply to this RPC.
        ///   - handleResponse: A closure which handles the response, the result of which is
        ///       returned to the caller. Returning from the closure will cancel the RPC if it
        ///       hasn't already finished.
        /// - Returns: The result of `handleResponse`.
        func adminLoginForToken<Result>(
            request: GRPCCore.ClientRequest<Primandproper_Platform_Signin_V1_AdminLoginForTokenRequest>,
            serializer: some GRPCCore.MessageSerializer<Primandproper_Platform_Signin_V1_AdminLoginForTokenRequest>,
            deserializer: some GRPCCore.MessageDeserializer<Primandproper_Platform_Signin_V1_AdminLoginForTokenResponse>,
            options: GRPCCore.CallOptions,
            onResponse handleResponse: @Sendable @escaping (GRPCCore.ClientResponse<Primandproper_Platform_Signin_V1_AdminLoginForTokenResponse>) async throws -> Result
        ) async throws -> Result where Result: Sendable

        /// Call the "ExchangeRefreshToken" method.
        ///
        /// - Parameters:
        ///   - request: A request containing a single `Primandproper_Platform_Signin_V1_ExchangeRefreshTokenRequest` message.
        ///   - serializer: A serializer for `Primandproper_Platform_Signin_V1_ExchangeRefreshTokenRequest` messages.
        ///   - deserializer: A deserializer for `Primandproper_Platform_Signin_V1_ExchangeRefreshTokenResponse` messages.
        ///   - options: Options to apply to this RPC.
        ///   - handleResponse: A closure which handles the response, the result of which is
        ///       returned to the caller. Returning from the closure will cancel the RPC if it
        ///       hasn't already finished.
        /// - Returns: The result of `handleResponse`.
        func exchangeRefreshToken<Result>(
            request: GRPCCore.ClientRequest<Primandproper_Platform_Signin_V1_ExchangeRefreshTokenRequest>,
            serializer: some GRPCCore.MessageSerializer<Primandproper_Platform_Signin_V1_ExchangeRefreshTokenRequest>,
            deserializer: some GRPCCore.MessageDeserializer<Primandproper_Platform_Signin_V1_ExchangeRefreshTokenResponse>,
            options: GRPCCore.CallOptions,
            onResponse handleResponse: @Sendable @escaping (GRPCCore.ClientResponse<Primandproper_Platform_Signin_V1_ExchangeRefreshTokenResponse>) async throws -> Result
        ) async throws -> Result where Result: Sendable

        /// Call the "GetAuthStatus" method.
        ///
        /// > Source IDL Documentation:
        /// >
        /// > The two reads a client makes on load.
        ///
        /// - Parameters:
        ///   - request: A request containing a single `Primandproper_Platform_Signin_V1_GetAuthStatusRequest` message.
        ///   - serializer: A serializer for `Primandproper_Platform_Signin_V1_GetAuthStatusRequest` messages.
        ///   - deserializer: A deserializer for `Primandproper_Platform_Signin_V1_GetAuthStatusResponse` messages.
        ///   - options: Options to apply to this RPC.
        ///   - handleResponse: A closure which handles the response, the result of which is
        ///       returned to the caller. Returning from the closure will cancel the RPC if it
        ///       hasn't already finished.
        /// - Returns: The result of `handleResponse`.
        func getAuthStatus<Result>(
            request: GRPCCore.ClientRequest<Primandproper_Platform_Signin_V1_GetAuthStatusRequest>,
            serializer: some GRPCCore.MessageSerializer<Primandproper_Platform_Signin_V1_GetAuthStatusRequest>,
            deserializer: some GRPCCore.MessageDeserializer<Primandproper_Platform_Signin_V1_GetAuthStatusResponse>,
            options: GRPCCore.CallOptions,
            onResponse handleResponse: @Sendable @escaping (GRPCCore.ClientResponse<Primandproper_Platform_Signin_V1_GetAuthStatusResponse>) async throws -> Result
        ) async throws -> Result where Result: Sendable

        /// Call the "GetSelf" method.
        ///
        /// - Parameters:
        ///   - request: A request containing a single `Primandproper_Platform_Signin_V1_GetSelfRequest` message.
        ///   - serializer: A serializer for `Primandproper_Platform_Signin_V1_GetSelfRequest` messages.
        ///   - deserializer: A deserializer for `Primandproper_Platform_Signin_V1_GetSelfResponse` messages.
        ///   - options: Options to apply to this RPC.
        ///   - handleResponse: A closure which handles the response, the result of which is
        ///       returned to the caller. Returning from the closure will cancel the RPC if it
        ///       hasn't already finished.
        /// - Returns: The result of `handleResponse`.
        func getSelf<Result>(
            request: GRPCCore.ClientRequest<Primandproper_Platform_Signin_V1_GetSelfRequest>,
            serializer: some GRPCCore.MessageSerializer<Primandproper_Platform_Signin_V1_GetSelfRequest>,
            deserializer: some GRPCCore.MessageDeserializer<Primandproper_Platform_Signin_V1_GetSelfResponse>,
            options: GRPCCore.CallOptions,
            onResponse handleResponse: @Sendable @escaping (GRPCCore.ClientResponse<Primandproper_Platform_Signin_V1_GetSelfResponse>) async throws -> Result
        ) async throws -> Result where Result: Sendable

        /// Call the "UpdatePassword" method.
        ///
        /// > Source IDL Documentation:
        /// >
        /// > The three writes a signed-in person makes about their own credentials.
        ///
        /// - Parameters:
        ///   - request: A request containing a single `Primandproper_Platform_Signin_V1_UpdatePasswordRequest` message.
        ///   - serializer: A serializer for `Primandproper_Platform_Signin_V1_UpdatePasswordRequest` messages.
        ///   - deserializer: A deserializer for `Primandproper_Platform_Signin_V1_UpdatePasswordResponse` messages.
        ///   - options: Options to apply to this RPC.
        ///   - handleResponse: A closure which handles the response, the result of which is
        ///       returned to the caller. Returning from the closure will cancel the RPC if it
        ///       hasn't already finished.
        /// - Returns: The result of `handleResponse`.
        func updatePassword<Result>(
            request: GRPCCore.ClientRequest<Primandproper_Platform_Signin_V1_UpdatePasswordRequest>,
            serializer: some GRPCCore.MessageSerializer<Primandproper_Platform_Signin_V1_UpdatePasswordRequest>,
            deserializer: some GRPCCore.MessageDeserializer<Primandproper_Platform_Signin_V1_UpdatePasswordResponse>,
            options: GRPCCore.CallOptions,
            onResponse handleResponse: @Sendable @escaping (GRPCCore.ClientResponse<Primandproper_Platform_Signin_V1_UpdatePasswordResponse>) async throws -> Result
        ) async throws -> Result where Result: Sendable

        /// Call the "RefreshTOTPSecret" method.
        ///
        /// - Parameters:
        ///   - request: A request containing a single `Primandproper_Platform_Signin_V1_RefreshTOTPSecretRequest` message.
        ///   - serializer: A serializer for `Primandproper_Platform_Signin_V1_RefreshTOTPSecretRequest` messages.
        ///   - deserializer: A deserializer for `Primandproper_Platform_Signin_V1_RefreshTOTPSecretResponse` messages.
        ///   - options: Options to apply to this RPC.
        ///   - handleResponse: A closure which handles the response, the result of which is
        ///       returned to the caller. Returning from the closure will cancel the RPC if it
        ///       hasn't already finished.
        /// - Returns: The result of `handleResponse`.
        func refreshTOTPSecret<Result>(
            request: GRPCCore.ClientRequest<Primandproper_Platform_Signin_V1_RefreshTOTPSecretRequest>,
            serializer: some GRPCCore.MessageSerializer<Primandproper_Platform_Signin_V1_RefreshTOTPSecretRequest>,
            deserializer: some GRPCCore.MessageDeserializer<Primandproper_Platform_Signin_V1_RefreshTOTPSecretResponse>,
            options: GRPCCore.CallOptions,
            onResponse handleResponse: @Sendable @escaping (GRPCCore.ClientResponse<Primandproper_Platform_Signin_V1_RefreshTOTPSecretResponse>) async throws -> Result
        ) async throws -> Result where Result: Sendable

        /// Call the "VerifyTOTPSecret" method.
        ///
        /// - Parameters:
        ///   - request: A request containing a single `Primandproper_Platform_Signin_V1_VerifyTOTPSecretRequest` message.
        ///   - serializer: A serializer for `Primandproper_Platform_Signin_V1_VerifyTOTPSecretRequest` messages.
        ///   - deserializer: A deserializer for `Primandproper_Platform_Signin_V1_VerifyTOTPSecretResponse` messages.
        ///   - options: Options to apply to this RPC.
        ///   - handleResponse: A closure which handles the response, the result of which is
        ///       returned to the caller. Returning from the closure will cancel the RPC if it
        ///       hasn't already finished.
        /// - Returns: The result of `handleResponse`.
        func verifyTOTPSecret<Result>(
            request: GRPCCore.ClientRequest<Primandproper_Platform_Signin_V1_VerifyTOTPSecretRequest>,
            serializer: some GRPCCore.MessageSerializer<Primandproper_Platform_Signin_V1_VerifyTOTPSecretRequest>,
            deserializer: some GRPCCore.MessageDeserializer<Primandproper_Platform_Signin_V1_VerifyTOTPSecretResponse>,
            options: GRPCCore.CallOptions,
            onResponse handleResponse: @Sendable @escaping (GRPCCore.ClientResponse<Primandproper_Platform_Signin_V1_VerifyTOTPSecretResponse>) async throws -> Result
        ) async throws -> Result where Result: Sendable
    }

    /// Generated client for the "primandproper.platform.signin.v1.SignInService" service.
    ///
    /// The ``Client`` provides an implementation of ``ClientProtocol`` which wraps
    /// a `GRPCCore.GRPCCClient`. The underlying `GRPCClient` provides the long-lived
    /// means of communication with the remote peer.
    ///
    /// > Source IDL Documentation:
    /// >
    /// > SignInService is sign-in.
    /// > 
    /// > Eight of its RPCs are anonymous by definition and five require a caller. What
    /// > none of them requires is a permission: there is no grant that would make
    /// > "sign in" safer, and the four authenticated ones take their subject from the
    /// > caller and have no field that could name anybody else. See
    /// > authentication/signin/grpc's Require for how that is declared to an
    /// > authorization policy, which is not the same thing as being left out of one.
    internal struct Client<Transport>: ClientProtocol where Transport: GRPCCore.ClientTransport {
        private let client: GRPCCore.GRPCClient<Transport>

        /// Creates a new client wrapping the provided `GRPCCore.GRPCClient`.
        ///
        /// - Parameters:
        ///   - client: A `GRPCCore.GRPCClient` providing a communication channel to the service.
        internal init(wrapping client: GRPCCore.GRPCClient<Transport>) {
            self.client = client
        }

        /// Call the "Register" method.
        ///
        /// > Source IDL Documentation:
        /// >
        /// > Arriving, and the two ways a registration is finished. Register requires a
        /// > caller -- the consumer's own registrar, for the reason identity's Register
        /// > requires one: an open sign-up is a flow with policy in it, a captcha, a rate
        /// > limit, an email domain rule, and this service holds none of that. The other
        /// > two are anonymous and carry their own authority, which is the token that was
        /// > mailed to the person they are about.
        ///
        /// - Parameters:
        ///   - request: A request containing a single `Primandproper_Platform_Signin_V1_RegisterRequest` message.
        ///   - serializer: A serializer for `Primandproper_Platform_Signin_V1_RegisterRequest` messages.
        ///   - deserializer: A deserializer for `Primandproper_Platform_Signin_V1_RegisterResponse` messages.
        ///   - options: Options to apply to this RPC.
        ///   - handleResponse: A closure which handles the response, the result of which is
        ///       returned to the caller. Returning from the closure will cancel the RPC if it
        ///       hasn't already finished.
        /// - Returns: The result of `handleResponse`.
        internal func register<Result>(
            request: GRPCCore.ClientRequest<Primandproper_Platform_Signin_V1_RegisterRequest>,
            serializer: some GRPCCore.MessageSerializer<Primandproper_Platform_Signin_V1_RegisterRequest>,
            deserializer: some GRPCCore.MessageDeserializer<Primandproper_Platform_Signin_V1_RegisterResponse>,
            options: GRPCCore.CallOptions = .defaults,
            onResponse handleResponse: @Sendable @escaping (GRPCCore.ClientResponse<Primandproper_Platform_Signin_V1_RegisterResponse>) async throws -> Result = { response in
                try response.message
            }
        ) async throws -> Result where Result: Sendable {
            try await self.client.unary(
                request: request,
                descriptor: Primandproper_Platform_Signin_V1_SignInService.Method.Register.descriptor,
                serializer: serializer,
                deserializer: deserializer,
                options: options,
                onResponse: handleResponse
            )
        }

        /// Call the "AttachPassword" method.
        ///
        /// - Parameters:
        ///   - request: A request containing a single `Primandproper_Platform_Signin_V1_AttachPasswordRequest` message.
        ///   - serializer: A serializer for `Primandproper_Platform_Signin_V1_AttachPasswordRequest` messages.
        ///   - deserializer: A deserializer for `Primandproper_Platform_Signin_V1_AttachPasswordResponse` messages.
        ///   - options: Options to apply to this RPC.
        ///   - handleResponse: A closure which handles the response, the result of which is
        ///       returned to the caller. Returning from the closure will cancel the RPC if it
        ///       hasn't already finished.
        /// - Returns: The result of `handleResponse`.
        internal func attachPassword<Result>(
            request: GRPCCore.ClientRequest<Primandproper_Platform_Signin_V1_AttachPasswordRequest>,
            serializer: some GRPCCore.MessageSerializer<Primandproper_Platform_Signin_V1_AttachPasswordRequest>,
            deserializer: some GRPCCore.MessageDeserializer<Primandproper_Platform_Signin_V1_AttachPasswordResponse>,
            options: GRPCCore.CallOptions = .defaults,
            onResponse handleResponse: @Sendable @escaping (GRPCCore.ClientResponse<Primandproper_Platform_Signin_V1_AttachPasswordResponse>) async throws -> Result = { response in
                try response.message
            }
        ) async throws -> Result where Result: Sendable {
            try await self.client.unary(
                request: request,
                descriptor: Primandproper_Platform_Signin_V1_SignInService.Method.AttachPassword.descriptor,
                serializer: serializer,
                deserializer: deserializer,
                options: options,
                onResponse: handleResponse
            )
        }

        /// Call the "VerifyEmailAddress" method.
        ///
        /// - Parameters:
        ///   - request: A request containing a single `Primandproper_Platform_Signin_V1_VerifyEmailAddressRequest` message.
        ///   - serializer: A serializer for `Primandproper_Platform_Signin_V1_VerifyEmailAddressRequest` messages.
        ///   - deserializer: A deserializer for `Primandproper_Platform_Signin_V1_VerifyEmailAddressResponse` messages.
        ///   - options: Options to apply to this RPC.
        ///   - handleResponse: A closure which handles the response, the result of which is
        ///       returned to the caller. Returning from the closure will cancel the RPC if it
        ///       hasn't already finished.
        /// - Returns: The result of `handleResponse`.
        internal func verifyEmailAddress<Result>(
            request: GRPCCore.ClientRequest<Primandproper_Platform_Signin_V1_VerifyEmailAddressRequest>,
            serializer: some GRPCCore.MessageSerializer<Primandproper_Platform_Signin_V1_VerifyEmailAddressRequest>,
            deserializer: some GRPCCore.MessageDeserializer<Primandproper_Platform_Signin_V1_VerifyEmailAddressResponse>,
            options: GRPCCore.CallOptions = .defaults,
            onResponse handleResponse: @Sendable @escaping (GRPCCore.ClientResponse<Primandproper_Platform_Signin_V1_VerifyEmailAddressResponse>) async throws -> Result = { response in
                try response.message
            }
        ) async throws -> Result where Result: Sendable {
            try await self.client.unary(
                request: request,
                descriptor: Primandproper_Platform_Signin_V1_SignInService.Method.VerifyEmailAddress.descriptor,
                serializer: serializer,
                deserializer: deserializer,
                options: options,
                onResponse: handleResponse
            )
        }

        /// Call the "RequestMagicLink" method.
        ///
        /// > Source IDL Documentation:
        /// >
        /// > The passwordless door, both halves anonymous. Requesting a link names an
        /// > address and is answered the same way whoever holds it; redeeming one carries
        /// > the token that was mailed, which is the whole of its authority. Neither can
        /// > name a user, so neither is a way to ask about one.
        /// > 
        /// > Rate limiting is the consumer's, in front of RequestMagicLink, and it is not
        /// > optional: this is the one RPC in this service that sends mail on request.
        ///
        /// - Parameters:
        ///   - request: A request containing a single `Primandproper_Platform_Signin_V1_RequestMagicLinkRequest` message.
        ///   - serializer: A serializer for `Primandproper_Platform_Signin_V1_RequestMagicLinkRequest` messages.
        ///   - deserializer: A deserializer for `Primandproper_Platform_Signin_V1_RequestMagicLinkResponse` messages.
        ///   - options: Options to apply to this RPC.
        ///   - handleResponse: A closure which handles the response, the result of which is
        ///       returned to the caller. Returning from the closure will cancel the RPC if it
        ///       hasn't already finished.
        /// - Returns: The result of `handleResponse`.
        internal func requestMagicLink<Result>(
            request: GRPCCore.ClientRequest<Primandproper_Platform_Signin_V1_RequestMagicLinkRequest>,
            serializer: some GRPCCore.MessageSerializer<Primandproper_Platform_Signin_V1_RequestMagicLinkRequest>,
            deserializer: some GRPCCore.MessageDeserializer<Primandproper_Platform_Signin_V1_RequestMagicLinkResponse>,
            options: GRPCCore.CallOptions = .defaults,
            onResponse handleResponse: @Sendable @escaping (GRPCCore.ClientResponse<Primandproper_Platform_Signin_V1_RequestMagicLinkResponse>) async throws -> Result = { response in
                try response.message
            }
        ) async throws -> Result where Result: Sendable {
            try await self.client.unary(
                request: request,
                descriptor: Primandproper_Platform_Signin_V1_SignInService.Method.RequestMagicLink.descriptor,
                serializer: serializer,
                deserializer: deserializer,
                options: options,
                onResponse: handleResponse
            )
        }

        /// Call the "RedeemMagicLink" method.
        ///
        /// - Parameters:
        ///   - request: A request containing a single `Primandproper_Platform_Signin_V1_RedeemMagicLinkRequest` message.
        ///   - serializer: A serializer for `Primandproper_Platform_Signin_V1_RedeemMagicLinkRequest` messages.
        ///   - deserializer: A deserializer for `Primandproper_Platform_Signin_V1_RedeemMagicLinkResponse` messages.
        ///   - options: Options to apply to this RPC.
        ///   - handleResponse: A closure which handles the response, the result of which is
        ///       returned to the caller. Returning from the closure will cancel the RPC if it
        ///       hasn't already finished.
        /// - Returns: The result of `handleResponse`.
        internal func redeemMagicLink<Result>(
            request: GRPCCore.ClientRequest<Primandproper_Platform_Signin_V1_RedeemMagicLinkRequest>,
            serializer: some GRPCCore.MessageSerializer<Primandproper_Platform_Signin_V1_RedeemMagicLinkRequest>,
            deserializer: some GRPCCore.MessageDeserializer<Primandproper_Platform_Signin_V1_RedeemMagicLinkResponse>,
            options: GRPCCore.CallOptions = .defaults,
            onResponse handleResponse: @Sendable @escaping (GRPCCore.ClientResponse<Primandproper_Platform_Signin_V1_RedeemMagicLinkResponse>) async throws -> Result = { response in
                try response.message
            }
        ) async throws -> Result where Result: Sendable {
            try await self.client.unary(
                request: request,
                descriptor: Primandproper_Platform_Signin_V1_SignInService.Method.RedeemMagicLink.descriptor,
                serializer: serializer,
                deserializer: deserializer,
                options: options,
                onResponse: handleResponse
            )
        }

        /// Call the "LoginForToken" method.
        ///
        /// > Source IDL Documentation:
        /// >
        /// > The two doors, and the one that keeps a sign-in alive without reopening
        /// > either of them.
        ///
        /// - Parameters:
        ///   - request: A request containing a single `Primandproper_Platform_Signin_V1_LoginForTokenRequest` message.
        ///   - serializer: A serializer for `Primandproper_Platform_Signin_V1_LoginForTokenRequest` messages.
        ///   - deserializer: A deserializer for `Primandproper_Platform_Signin_V1_LoginForTokenResponse` messages.
        ///   - options: Options to apply to this RPC.
        ///   - handleResponse: A closure which handles the response, the result of which is
        ///       returned to the caller. Returning from the closure will cancel the RPC if it
        ///       hasn't already finished.
        /// - Returns: The result of `handleResponse`.
        internal func loginForToken<Result>(
            request: GRPCCore.ClientRequest<Primandproper_Platform_Signin_V1_LoginForTokenRequest>,
            serializer: some GRPCCore.MessageSerializer<Primandproper_Platform_Signin_V1_LoginForTokenRequest>,
            deserializer: some GRPCCore.MessageDeserializer<Primandproper_Platform_Signin_V1_LoginForTokenResponse>,
            options: GRPCCore.CallOptions = .defaults,
            onResponse handleResponse: @Sendable @escaping (GRPCCore.ClientResponse<Primandproper_Platform_Signin_V1_LoginForTokenResponse>) async throws -> Result = { response in
                try response.message
            }
        ) async throws -> Result where Result: Sendable {
            try await self.client.unary(
                request: request,
                descriptor: Primandproper_Platform_Signin_V1_SignInService.Method.LoginForToken.descriptor,
                serializer: serializer,
                deserializer: deserializer,
                options: options,
                onResponse: handleResponse
            )
        }

        /// Call the "AdminLoginForToken" method.
        ///
        /// - Parameters:
        ///   - request: A request containing a single `Primandproper_Platform_Signin_V1_AdminLoginForTokenRequest` message.
        ///   - serializer: A serializer for `Primandproper_Platform_Signin_V1_AdminLoginForTokenRequest` messages.
        ///   - deserializer: A deserializer for `Primandproper_Platform_Signin_V1_AdminLoginForTokenResponse` messages.
        ///   - options: Options to apply to this RPC.
        ///   - handleResponse: A closure which handles the response, the result of which is
        ///       returned to the caller. Returning from the closure will cancel the RPC if it
        ///       hasn't already finished.
        /// - Returns: The result of `handleResponse`.
        internal func adminLoginForToken<Result>(
            request: GRPCCore.ClientRequest<Primandproper_Platform_Signin_V1_AdminLoginForTokenRequest>,
            serializer: some GRPCCore.MessageSerializer<Primandproper_Platform_Signin_V1_AdminLoginForTokenRequest>,
            deserializer: some GRPCCore.MessageDeserializer<Primandproper_Platform_Signin_V1_AdminLoginForTokenResponse>,
            options: GRPCCore.CallOptions = .defaults,
            onResponse handleResponse: @Sendable @escaping (GRPCCore.ClientResponse<Primandproper_Platform_Signin_V1_AdminLoginForTokenResponse>) async throws -> Result = { response in
                try response.message
            }
        ) async throws -> Result where Result: Sendable {
            try await self.client.unary(
                request: request,
                descriptor: Primandproper_Platform_Signin_V1_SignInService.Method.AdminLoginForToken.descriptor,
                serializer: serializer,
                deserializer: deserializer,
                options: options,
                onResponse: handleResponse
            )
        }

        /// Call the "ExchangeRefreshToken" method.
        ///
        /// - Parameters:
        ///   - request: A request containing a single `Primandproper_Platform_Signin_V1_ExchangeRefreshTokenRequest` message.
        ///   - serializer: A serializer for `Primandproper_Platform_Signin_V1_ExchangeRefreshTokenRequest` messages.
        ///   - deserializer: A deserializer for `Primandproper_Platform_Signin_V1_ExchangeRefreshTokenResponse` messages.
        ///   - options: Options to apply to this RPC.
        ///   - handleResponse: A closure which handles the response, the result of which is
        ///       returned to the caller. Returning from the closure will cancel the RPC if it
        ///       hasn't already finished.
        /// - Returns: The result of `handleResponse`.
        internal func exchangeRefreshToken<Result>(
            request: GRPCCore.ClientRequest<Primandproper_Platform_Signin_V1_ExchangeRefreshTokenRequest>,
            serializer: some GRPCCore.MessageSerializer<Primandproper_Platform_Signin_V1_ExchangeRefreshTokenRequest>,
            deserializer: some GRPCCore.MessageDeserializer<Primandproper_Platform_Signin_V1_ExchangeRefreshTokenResponse>,
            options: GRPCCore.CallOptions = .defaults,
            onResponse handleResponse: @Sendable @escaping (GRPCCore.ClientResponse<Primandproper_Platform_Signin_V1_ExchangeRefreshTokenResponse>) async throws -> Result = { response in
                try response.message
            }
        ) async throws -> Result where Result: Sendable {
            try await self.client.unary(
                request: request,
                descriptor: Primandproper_Platform_Signin_V1_SignInService.Method.ExchangeRefreshToken.descriptor,
                serializer: serializer,
                deserializer: deserializer,
                options: options,
                onResponse: handleResponse
            )
        }

        /// Call the "GetAuthStatus" method.
        ///
        /// > Source IDL Documentation:
        /// >
        /// > The two reads a client makes on load.
        ///
        /// - Parameters:
        ///   - request: A request containing a single `Primandproper_Platform_Signin_V1_GetAuthStatusRequest` message.
        ///   - serializer: A serializer for `Primandproper_Platform_Signin_V1_GetAuthStatusRequest` messages.
        ///   - deserializer: A deserializer for `Primandproper_Platform_Signin_V1_GetAuthStatusResponse` messages.
        ///   - options: Options to apply to this RPC.
        ///   - handleResponse: A closure which handles the response, the result of which is
        ///       returned to the caller. Returning from the closure will cancel the RPC if it
        ///       hasn't already finished.
        /// - Returns: The result of `handleResponse`.
        internal func getAuthStatus<Result>(
            request: GRPCCore.ClientRequest<Primandproper_Platform_Signin_V1_GetAuthStatusRequest>,
            serializer: some GRPCCore.MessageSerializer<Primandproper_Platform_Signin_V1_GetAuthStatusRequest>,
            deserializer: some GRPCCore.MessageDeserializer<Primandproper_Platform_Signin_V1_GetAuthStatusResponse>,
            options: GRPCCore.CallOptions = .defaults,
            onResponse handleResponse: @Sendable @escaping (GRPCCore.ClientResponse<Primandproper_Platform_Signin_V1_GetAuthStatusResponse>) async throws -> Result = { response in
                try response.message
            }
        ) async throws -> Result where Result: Sendable {
            try await self.client.unary(
                request: request,
                descriptor: Primandproper_Platform_Signin_V1_SignInService.Method.GetAuthStatus.descriptor,
                serializer: serializer,
                deserializer: deserializer,
                options: options,
                onResponse: handleResponse
            )
        }

        /// Call the "GetSelf" method.
        ///
        /// - Parameters:
        ///   - request: A request containing a single `Primandproper_Platform_Signin_V1_GetSelfRequest` message.
        ///   - serializer: A serializer for `Primandproper_Platform_Signin_V1_GetSelfRequest` messages.
        ///   - deserializer: A deserializer for `Primandproper_Platform_Signin_V1_GetSelfResponse` messages.
        ///   - options: Options to apply to this RPC.
        ///   - handleResponse: A closure which handles the response, the result of which is
        ///       returned to the caller. Returning from the closure will cancel the RPC if it
        ///       hasn't already finished.
        /// - Returns: The result of `handleResponse`.
        internal func getSelf<Result>(
            request: GRPCCore.ClientRequest<Primandproper_Platform_Signin_V1_GetSelfRequest>,
            serializer: some GRPCCore.MessageSerializer<Primandproper_Platform_Signin_V1_GetSelfRequest>,
            deserializer: some GRPCCore.MessageDeserializer<Primandproper_Platform_Signin_V1_GetSelfResponse>,
            options: GRPCCore.CallOptions = .defaults,
            onResponse handleResponse: @Sendable @escaping (GRPCCore.ClientResponse<Primandproper_Platform_Signin_V1_GetSelfResponse>) async throws -> Result = { response in
                try response.message
            }
        ) async throws -> Result where Result: Sendable {
            try await self.client.unary(
                request: request,
                descriptor: Primandproper_Platform_Signin_V1_SignInService.Method.GetSelf.descriptor,
                serializer: serializer,
                deserializer: deserializer,
                options: options,
                onResponse: handleResponse
            )
        }

        /// Call the "UpdatePassword" method.
        ///
        /// > Source IDL Documentation:
        /// >
        /// > The three writes a signed-in person makes about their own credentials.
        ///
        /// - Parameters:
        ///   - request: A request containing a single `Primandproper_Platform_Signin_V1_UpdatePasswordRequest` message.
        ///   - serializer: A serializer for `Primandproper_Platform_Signin_V1_UpdatePasswordRequest` messages.
        ///   - deserializer: A deserializer for `Primandproper_Platform_Signin_V1_UpdatePasswordResponse` messages.
        ///   - options: Options to apply to this RPC.
        ///   - handleResponse: A closure which handles the response, the result of which is
        ///       returned to the caller. Returning from the closure will cancel the RPC if it
        ///       hasn't already finished.
        /// - Returns: The result of `handleResponse`.
        internal func updatePassword<Result>(
            request: GRPCCore.ClientRequest<Primandproper_Platform_Signin_V1_UpdatePasswordRequest>,
            serializer: some GRPCCore.MessageSerializer<Primandproper_Platform_Signin_V1_UpdatePasswordRequest>,
            deserializer: some GRPCCore.MessageDeserializer<Primandproper_Platform_Signin_V1_UpdatePasswordResponse>,
            options: GRPCCore.CallOptions = .defaults,
            onResponse handleResponse: @Sendable @escaping (GRPCCore.ClientResponse<Primandproper_Platform_Signin_V1_UpdatePasswordResponse>) async throws -> Result = { response in
                try response.message
            }
        ) async throws -> Result where Result: Sendable {
            try await self.client.unary(
                request: request,
                descriptor: Primandproper_Platform_Signin_V1_SignInService.Method.UpdatePassword.descriptor,
                serializer: serializer,
                deserializer: deserializer,
                options: options,
                onResponse: handleResponse
            )
        }

        /// Call the "RefreshTOTPSecret" method.
        ///
        /// - Parameters:
        ///   - request: A request containing a single `Primandproper_Platform_Signin_V1_RefreshTOTPSecretRequest` message.
        ///   - serializer: A serializer for `Primandproper_Platform_Signin_V1_RefreshTOTPSecretRequest` messages.
        ///   - deserializer: A deserializer for `Primandproper_Platform_Signin_V1_RefreshTOTPSecretResponse` messages.
        ///   - options: Options to apply to this RPC.
        ///   - handleResponse: A closure which handles the response, the result of which is
        ///       returned to the caller. Returning from the closure will cancel the RPC if it
        ///       hasn't already finished.
        /// - Returns: The result of `handleResponse`.
        internal func refreshTOTPSecret<Result>(
            request: GRPCCore.ClientRequest<Primandproper_Platform_Signin_V1_RefreshTOTPSecretRequest>,
            serializer: some GRPCCore.MessageSerializer<Primandproper_Platform_Signin_V1_RefreshTOTPSecretRequest>,
            deserializer: some GRPCCore.MessageDeserializer<Primandproper_Platform_Signin_V1_RefreshTOTPSecretResponse>,
            options: GRPCCore.CallOptions = .defaults,
            onResponse handleResponse: @Sendable @escaping (GRPCCore.ClientResponse<Primandproper_Platform_Signin_V1_RefreshTOTPSecretResponse>) async throws -> Result = { response in
                try response.message
            }
        ) async throws -> Result where Result: Sendable {
            try await self.client.unary(
                request: request,
                descriptor: Primandproper_Platform_Signin_V1_SignInService.Method.RefreshTOTPSecret.descriptor,
                serializer: serializer,
                deserializer: deserializer,
                options: options,
                onResponse: handleResponse
            )
        }

        /// Call the "VerifyTOTPSecret" method.
        ///
        /// - Parameters:
        ///   - request: A request containing a single `Primandproper_Platform_Signin_V1_VerifyTOTPSecretRequest` message.
        ///   - serializer: A serializer for `Primandproper_Platform_Signin_V1_VerifyTOTPSecretRequest` messages.
        ///   - deserializer: A deserializer for `Primandproper_Platform_Signin_V1_VerifyTOTPSecretResponse` messages.
        ///   - options: Options to apply to this RPC.
        ///   - handleResponse: A closure which handles the response, the result of which is
        ///       returned to the caller. Returning from the closure will cancel the RPC if it
        ///       hasn't already finished.
        /// - Returns: The result of `handleResponse`.
        internal func verifyTOTPSecret<Result>(
            request: GRPCCore.ClientRequest<Primandproper_Platform_Signin_V1_VerifyTOTPSecretRequest>,
            serializer: some GRPCCore.MessageSerializer<Primandproper_Platform_Signin_V1_VerifyTOTPSecretRequest>,
            deserializer: some GRPCCore.MessageDeserializer<Primandproper_Platform_Signin_V1_VerifyTOTPSecretResponse>,
            options: GRPCCore.CallOptions = .defaults,
            onResponse handleResponse: @Sendable @escaping (GRPCCore.ClientResponse<Primandproper_Platform_Signin_V1_VerifyTOTPSecretResponse>) async throws -> Result = { response in
                try response.message
            }
        ) async throws -> Result where Result: Sendable {
            try await self.client.unary(
                request: request,
                descriptor: Primandproper_Platform_Signin_V1_SignInService.Method.VerifyTOTPSecret.descriptor,
                serializer: serializer,
                deserializer: deserializer,
                options: options,
                onResponse: handleResponse
            )
        }
    }
}

// Helpers providing default arguments to 'ClientProtocol' methods.
@available(macOS 15.0, iOS 18.0, watchOS 11.0, tvOS 18.0, visionOS 2.0, *)
extension Primandproper_Platform_Signin_V1_SignInService.ClientProtocol {
    /// Call the "Register" method.
    ///
    /// > Source IDL Documentation:
    /// >
    /// > Arriving, and the two ways a registration is finished. Register requires a
    /// > caller -- the consumer's own registrar, for the reason identity's Register
    /// > requires one: an open sign-up is a flow with policy in it, a captcha, a rate
    /// > limit, an email domain rule, and this service holds none of that. The other
    /// > two are anonymous and carry their own authority, which is the token that was
    /// > mailed to the person they are about.
    ///
    /// - Parameters:
    ///   - request: A request containing a single `Primandproper_Platform_Signin_V1_RegisterRequest` message.
    ///   - options: Options to apply to this RPC.
    ///   - handleResponse: A closure which handles the response, the result of which is
    ///       returned to the caller. Returning from the closure will cancel the RPC if it
    ///       hasn't already finished.
    /// - Returns: The result of `handleResponse`.
    internal func register<Result>(
        request: GRPCCore.ClientRequest<Primandproper_Platform_Signin_V1_RegisterRequest>,
        options: GRPCCore.CallOptions = .defaults,
        onResponse handleResponse: @Sendable @escaping (GRPCCore.ClientResponse<Primandproper_Platform_Signin_V1_RegisterResponse>) async throws -> Result = { response in
            try response.message
        }
    ) async throws -> Result where Result: Sendable {
        try await self.register(
            request: request,
            serializer: GRPCProtobuf.ProtobufSerializer<Primandproper_Platform_Signin_V1_RegisterRequest>(),
            deserializer: GRPCProtobuf.ProtobufDeserializer<Primandproper_Platform_Signin_V1_RegisterResponse>(),
            options: options,
            onResponse: handleResponse
        )
    }

    /// Call the "AttachPassword" method.
    ///
    /// - Parameters:
    ///   - request: A request containing a single `Primandproper_Platform_Signin_V1_AttachPasswordRequest` message.
    ///   - options: Options to apply to this RPC.
    ///   - handleResponse: A closure which handles the response, the result of which is
    ///       returned to the caller. Returning from the closure will cancel the RPC if it
    ///       hasn't already finished.
    /// - Returns: The result of `handleResponse`.
    internal func attachPassword<Result>(
        request: GRPCCore.ClientRequest<Primandproper_Platform_Signin_V1_AttachPasswordRequest>,
        options: GRPCCore.CallOptions = .defaults,
        onResponse handleResponse: @Sendable @escaping (GRPCCore.ClientResponse<Primandproper_Platform_Signin_V1_AttachPasswordResponse>) async throws -> Result = { response in
            try response.message
        }
    ) async throws -> Result where Result: Sendable {
        try await self.attachPassword(
            request: request,
            serializer: GRPCProtobuf.ProtobufSerializer<Primandproper_Platform_Signin_V1_AttachPasswordRequest>(),
            deserializer: GRPCProtobuf.ProtobufDeserializer<Primandproper_Platform_Signin_V1_AttachPasswordResponse>(),
            options: options,
            onResponse: handleResponse
        )
    }

    /// Call the "VerifyEmailAddress" method.
    ///
    /// - Parameters:
    ///   - request: A request containing a single `Primandproper_Platform_Signin_V1_VerifyEmailAddressRequest` message.
    ///   - options: Options to apply to this RPC.
    ///   - handleResponse: A closure which handles the response, the result of which is
    ///       returned to the caller. Returning from the closure will cancel the RPC if it
    ///       hasn't already finished.
    /// - Returns: The result of `handleResponse`.
    internal func verifyEmailAddress<Result>(
        request: GRPCCore.ClientRequest<Primandproper_Platform_Signin_V1_VerifyEmailAddressRequest>,
        options: GRPCCore.CallOptions = .defaults,
        onResponse handleResponse: @Sendable @escaping (GRPCCore.ClientResponse<Primandproper_Platform_Signin_V1_VerifyEmailAddressResponse>) async throws -> Result = { response in
            try response.message
        }
    ) async throws -> Result where Result: Sendable {
        try await self.verifyEmailAddress(
            request: request,
            serializer: GRPCProtobuf.ProtobufSerializer<Primandproper_Platform_Signin_V1_VerifyEmailAddressRequest>(),
            deserializer: GRPCProtobuf.ProtobufDeserializer<Primandproper_Platform_Signin_V1_VerifyEmailAddressResponse>(),
            options: options,
            onResponse: handleResponse
        )
    }

    /// Call the "RequestMagicLink" method.
    ///
    /// > Source IDL Documentation:
    /// >
    /// > The passwordless door, both halves anonymous. Requesting a link names an
    /// > address and is answered the same way whoever holds it; redeeming one carries
    /// > the token that was mailed, which is the whole of its authority. Neither can
    /// > name a user, so neither is a way to ask about one.
    /// > 
    /// > Rate limiting is the consumer's, in front of RequestMagicLink, and it is not
    /// > optional: this is the one RPC in this service that sends mail on request.
    ///
    /// - Parameters:
    ///   - request: A request containing a single `Primandproper_Platform_Signin_V1_RequestMagicLinkRequest` message.
    ///   - options: Options to apply to this RPC.
    ///   - handleResponse: A closure which handles the response, the result of which is
    ///       returned to the caller. Returning from the closure will cancel the RPC if it
    ///       hasn't already finished.
    /// - Returns: The result of `handleResponse`.
    internal func requestMagicLink<Result>(
        request: GRPCCore.ClientRequest<Primandproper_Platform_Signin_V1_RequestMagicLinkRequest>,
        options: GRPCCore.CallOptions = .defaults,
        onResponse handleResponse: @Sendable @escaping (GRPCCore.ClientResponse<Primandproper_Platform_Signin_V1_RequestMagicLinkResponse>) async throws -> Result = { response in
            try response.message
        }
    ) async throws -> Result where Result: Sendable {
        try await self.requestMagicLink(
            request: request,
            serializer: GRPCProtobuf.ProtobufSerializer<Primandproper_Platform_Signin_V1_RequestMagicLinkRequest>(),
            deserializer: GRPCProtobuf.ProtobufDeserializer<Primandproper_Platform_Signin_V1_RequestMagicLinkResponse>(),
            options: options,
            onResponse: handleResponse
        )
    }

    /// Call the "RedeemMagicLink" method.
    ///
    /// - Parameters:
    ///   - request: A request containing a single `Primandproper_Platform_Signin_V1_RedeemMagicLinkRequest` message.
    ///   - options: Options to apply to this RPC.
    ///   - handleResponse: A closure which handles the response, the result of which is
    ///       returned to the caller. Returning from the closure will cancel the RPC if it
    ///       hasn't already finished.
    /// - Returns: The result of `handleResponse`.
    internal func redeemMagicLink<Result>(
        request: GRPCCore.ClientRequest<Primandproper_Platform_Signin_V1_RedeemMagicLinkRequest>,
        options: GRPCCore.CallOptions = .defaults,
        onResponse handleResponse: @Sendable @escaping (GRPCCore.ClientResponse<Primandproper_Platform_Signin_V1_RedeemMagicLinkResponse>) async throws -> Result = { response in
            try response.message
        }
    ) async throws -> Result where Result: Sendable {
        try await self.redeemMagicLink(
            request: request,
            serializer: GRPCProtobuf.ProtobufSerializer<Primandproper_Platform_Signin_V1_RedeemMagicLinkRequest>(),
            deserializer: GRPCProtobuf.ProtobufDeserializer<Primandproper_Platform_Signin_V1_RedeemMagicLinkResponse>(),
            options: options,
            onResponse: handleResponse
        )
    }

    /// Call the "LoginForToken" method.
    ///
    /// > Source IDL Documentation:
    /// >
    /// > The two doors, and the one that keeps a sign-in alive without reopening
    /// > either of them.
    ///
    /// - Parameters:
    ///   - request: A request containing a single `Primandproper_Platform_Signin_V1_LoginForTokenRequest` message.
    ///   - options: Options to apply to this RPC.
    ///   - handleResponse: A closure which handles the response, the result of which is
    ///       returned to the caller. Returning from the closure will cancel the RPC if it
    ///       hasn't already finished.
    /// - Returns: The result of `handleResponse`.
    internal func loginForToken<Result>(
        request: GRPCCore.ClientRequest<Primandproper_Platform_Signin_V1_LoginForTokenRequest>,
        options: GRPCCore.CallOptions = .defaults,
        onResponse handleResponse: @Sendable @escaping (GRPCCore.ClientResponse<Primandproper_Platform_Signin_V1_LoginForTokenResponse>) async throws -> Result = { response in
            try response.message
        }
    ) async throws -> Result where Result: Sendable {
        try await self.loginForToken(
            request: request,
            serializer: GRPCProtobuf.ProtobufSerializer<Primandproper_Platform_Signin_V1_LoginForTokenRequest>(),
            deserializer: GRPCProtobuf.ProtobufDeserializer<Primandproper_Platform_Signin_V1_LoginForTokenResponse>(),
            options: options,
            onResponse: handleResponse
        )
    }

    /// Call the "AdminLoginForToken" method.
    ///
    /// - Parameters:
    ///   - request: A request containing a single `Primandproper_Platform_Signin_V1_AdminLoginForTokenRequest` message.
    ///   - options: Options to apply to this RPC.
    ///   - handleResponse: A closure which handles the response, the result of which is
    ///       returned to the caller. Returning from the closure will cancel the RPC if it
    ///       hasn't already finished.
    /// - Returns: The result of `handleResponse`.
    internal func adminLoginForToken<Result>(
        request: GRPCCore.ClientRequest<Primandproper_Platform_Signin_V1_AdminLoginForTokenRequest>,
        options: GRPCCore.CallOptions = .defaults,
        onResponse handleResponse: @Sendable @escaping (GRPCCore.ClientResponse<Primandproper_Platform_Signin_V1_AdminLoginForTokenResponse>) async throws -> Result = { response in
            try response.message
        }
    ) async throws -> Result where Result: Sendable {
        try await self.adminLoginForToken(
            request: request,
            serializer: GRPCProtobuf.ProtobufSerializer<Primandproper_Platform_Signin_V1_AdminLoginForTokenRequest>(),
            deserializer: GRPCProtobuf.ProtobufDeserializer<Primandproper_Platform_Signin_V1_AdminLoginForTokenResponse>(),
            options: options,
            onResponse: handleResponse
        )
    }

    /// Call the "ExchangeRefreshToken" method.
    ///
    /// - Parameters:
    ///   - request: A request containing a single `Primandproper_Platform_Signin_V1_ExchangeRefreshTokenRequest` message.
    ///   - options: Options to apply to this RPC.
    ///   - handleResponse: A closure which handles the response, the result of which is
    ///       returned to the caller. Returning from the closure will cancel the RPC if it
    ///       hasn't already finished.
    /// - Returns: The result of `handleResponse`.
    internal func exchangeRefreshToken<Result>(
        request: GRPCCore.ClientRequest<Primandproper_Platform_Signin_V1_ExchangeRefreshTokenRequest>,
        options: GRPCCore.CallOptions = .defaults,
        onResponse handleResponse: @Sendable @escaping (GRPCCore.ClientResponse<Primandproper_Platform_Signin_V1_ExchangeRefreshTokenResponse>) async throws -> Result = { response in
            try response.message
        }
    ) async throws -> Result where Result: Sendable {
        try await self.exchangeRefreshToken(
            request: request,
            serializer: GRPCProtobuf.ProtobufSerializer<Primandproper_Platform_Signin_V1_ExchangeRefreshTokenRequest>(),
            deserializer: GRPCProtobuf.ProtobufDeserializer<Primandproper_Platform_Signin_V1_ExchangeRefreshTokenResponse>(),
            options: options,
            onResponse: handleResponse
        )
    }

    /// Call the "GetAuthStatus" method.
    ///
    /// > Source IDL Documentation:
    /// >
    /// > The two reads a client makes on load.
    ///
    /// - Parameters:
    ///   - request: A request containing a single `Primandproper_Platform_Signin_V1_GetAuthStatusRequest` message.
    ///   - options: Options to apply to this RPC.
    ///   - handleResponse: A closure which handles the response, the result of which is
    ///       returned to the caller. Returning from the closure will cancel the RPC if it
    ///       hasn't already finished.
    /// - Returns: The result of `handleResponse`.
    internal func getAuthStatus<Result>(
        request: GRPCCore.ClientRequest<Primandproper_Platform_Signin_V1_GetAuthStatusRequest>,
        options: GRPCCore.CallOptions = .defaults,
        onResponse handleResponse: @Sendable @escaping (GRPCCore.ClientResponse<Primandproper_Platform_Signin_V1_GetAuthStatusResponse>) async throws -> Result = { response in
            try response.message
        }
    ) async throws -> Result where Result: Sendable {
        try await self.getAuthStatus(
            request: request,
            serializer: GRPCProtobuf.ProtobufSerializer<Primandproper_Platform_Signin_V1_GetAuthStatusRequest>(),
            deserializer: GRPCProtobuf.ProtobufDeserializer<Primandproper_Platform_Signin_V1_GetAuthStatusResponse>(),
            options: options,
            onResponse: handleResponse
        )
    }

    /// Call the "GetSelf" method.
    ///
    /// - Parameters:
    ///   - request: A request containing a single `Primandproper_Platform_Signin_V1_GetSelfRequest` message.
    ///   - options: Options to apply to this RPC.
    ///   - handleResponse: A closure which handles the response, the result of which is
    ///       returned to the caller. Returning from the closure will cancel the RPC if it
    ///       hasn't already finished.
    /// - Returns: The result of `handleResponse`.
    internal func getSelf<Result>(
        request: GRPCCore.ClientRequest<Primandproper_Platform_Signin_V1_GetSelfRequest>,
        options: GRPCCore.CallOptions = .defaults,
        onResponse handleResponse: @Sendable @escaping (GRPCCore.ClientResponse<Primandproper_Platform_Signin_V1_GetSelfResponse>) async throws -> Result = { response in
            try response.message
        }
    ) async throws -> Result where Result: Sendable {
        try await self.getSelf(
            request: request,
            serializer: GRPCProtobuf.ProtobufSerializer<Primandproper_Platform_Signin_V1_GetSelfRequest>(),
            deserializer: GRPCProtobuf.ProtobufDeserializer<Primandproper_Platform_Signin_V1_GetSelfResponse>(),
            options: options,
            onResponse: handleResponse
        )
    }

    /// Call the "UpdatePassword" method.
    ///
    /// > Source IDL Documentation:
    /// >
    /// > The three writes a signed-in person makes about their own credentials.
    ///
    /// - Parameters:
    ///   - request: A request containing a single `Primandproper_Platform_Signin_V1_UpdatePasswordRequest` message.
    ///   - options: Options to apply to this RPC.
    ///   - handleResponse: A closure which handles the response, the result of which is
    ///       returned to the caller. Returning from the closure will cancel the RPC if it
    ///       hasn't already finished.
    /// - Returns: The result of `handleResponse`.
    internal func updatePassword<Result>(
        request: GRPCCore.ClientRequest<Primandproper_Platform_Signin_V1_UpdatePasswordRequest>,
        options: GRPCCore.CallOptions = .defaults,
        onResponse handleResponse: @Sendable @escaping (GRPCCore.ClientResponse<Primandproper_Platform_Signin_V1_UpdatePasswordResponse>) async throws -> Result = { response in
            try response.message
        }
    ) async throws -> Result where Result: Sendable {
        try await self.updatePassword(
            request: request,
            serializer: GRPCProtobuf.ProtobufSerializer<Primandproper_Platform_Signin_V1_UpdatePasswordRequest>(),
            deserializer: GRPCProtobuf.ProtobufDeserializer<Primandproper_Platform_Signin_V1_UpdatePasswordResponse>(),
            options: options,
            onResponse: handleResponse
        )
    }

    /// Call the "RefreshTOTPSecret" method.
    ///
    /// - Parameters:
    ///   - request: A request containing a single `Primandproper_Platform_Signin_V1_RefreshTOTPSecretRequest` message.
    ///   - options: Options to apply to this RPC.
    ///   - handleResponse: A closure which handles the response, the result of which is
    ///       returned to the caller. Returning from the closure will cancel the RPC if it
    ///       hasn't already finished.
    /// - Returns: The result of `handleResponse`.
    internal func refreshTOTPSecret<Result>(
        request: GRPCCore.ClientRequest<Primandproper_Platform_Signin_V1_RefreshTOTPSecretRequest>,
        options: GRPCCore.CallOptions = .defaults,
        onResponse handleResponse: @Sendable @escaping (GRPCCore.ClientResponse<Primandproper_Platform_Signin_V1_RefreshTOTPSecretResponse>) async throws -> Result = { response in
            try response.message
        }
    ) async throws -> Result where Result: Sendable {
        try await self.refreshTOTPSecret(
            request: request,
            serializer: GRPCProtobuf.ProtobufSerializer<Primandproper_Platform_Signin_V1_RefreshTOTPSecretRequest>(),
            deserializer: GRPCProtobuf.ProtobufDeserializer<Primandproper_Platform_Signin_V1_RefreshTOTPSecretResponse>(),
            options: options,
            onResponse: handleResponse
        )
    }

    /// Call the "VerifyTOTPSecret" method.
    ///
    /// - Parameters:
    ///   - request: A request containing a single `Primandproper_Platform_Signin_V1_VerifyTOTPSecretRequest` message.
    ///   - options: Options to apply to this RPC.
    ///   - handleResponse: A closure which handles the response, the result of which is
    ///       returned to the caller. Returning from the closure will cancel the RPC if it
    ///       hasn't already finished.
    /// - Returns: The result of `handleResponse`.
    internal func verifyTOTPSecret<Result>(
        request: GRPCCore.ClientRequest<Primandproper_Platform_Signin_V1_VerifyTOTPSecretRequest>,
        options: GRPCCore.CallOptions = .defaults,
        onResponse handleResponse: @Sendable @escaping (GRPCCore.ClientResponse<Primandproper_Platform_Signin_V1_VerifyTOTPSecretResponse>) async throws -> Result = { response in
            try response.message
        }
    ) async throws -> Result where Result: Sendable {
        try await self.verifyTOTPSecret(
            request: request,
            serializer: GRPCProtobuf.ProtobufSerializer<Primandproper_Platform_Signin_V1_VerifyTOTPSecretRequest>(),
            deserializer: GRPCProtobuf.ProtobufDeserializer<Primandproper_Platform_Signin_V1_VerifyTOTPSecretResponse>(),
            options: options,
            onResponse: handleResponse
        )
    }
}

// Helpers providing sugared APIs for 'ClientProtocol' methods.
@available(macOS 15.0, iOS 18.0, watchOS 11.0, tvOS 18.0, visionOS 2.0, *)
extension Primandproper_Platform_Signin_V1_SignInService.ClientProtocol {
    /// Call the "Register" method.
    ///
    /// > Source IDL Documentation:
    /// >
    /// > Arriving, and the two ways a registration is finished. Register requires a
    /// > caller -- the consumer's own registrar, for the reason identity's Register
    /// > requires one: an open sign-up is a flow with policy in it, a captcha, a rate
    /// > limit, an email domain rule, and this service holds none of that. The other
    /// > two are anonymous and carry their own authority, which is the token that was
    /// > mailed to the person they are about.
    ///
    /// - Parameters:
    ///   - message: request message to send.
    ///   - metadata: Additional metadata to send, defaults to empty.
    ///   - options: Options to apply to this RPC, defaults to `.defaults`.
    ///   - handleResponse: A closure which handles the response, the result of which is
    ///       returned to the caller. Returning from the closure will cancel the RPC if it
    ///       hasn't already finished.
    /// - Returns: The result of `handleResponse`.
    internal func register<Result>(
        _ message: Primandproper_Platform_Signin_V1_RegisterRequest,
        metadata: GRPCCore.Metadata = [:],
        options: GRPCCore.CallOptions = .defaults,
        onResponse handleResponse: @Sendable @escaping (GRPCCore.ClientResponse<Primandproper_Platform_Signin_V1_RegisterResponse>) async throws -> Result = { response in
            try response.message
        }
    ) async throws -> Result where Result: Sendable {
        let request = GRPCCore.ClientRequest<Primandproper_Platform_Signin_V1_RegisterRequest>(
            message: message,
            metadata: metadata
        )
        return try await self.register(
            request: request,
            options: options,
            onResponse: handleResponse
        )
    }

    /// Call the "AttachPassword" method.
    ///
    /// - Parameters:
    ///   - message: request message to send.
    ///   - metadata: Additional metadata to send, defaults to empty.
    ///   - options: Options to apply to this RPC, defaults to `.defaults`.
    ///   - handleResponse: A closure which handles the response, the result of which is
    ///       returned to the caller. Returning from the closure will cancel the RPC if it
    ///       hasn't already finished.
    /// - Returns: The result of `handleResponse`.
    internal func attachPassword<Result>(
        _ message: Primandproper_Platform_Signin_V1_AttachPasswordRequest,
        metadata: GRPCCore.Metadata = [:],
        options: GRPCCore.CallOptions = .defaults,
        onResponse handleResponse: @Sendable @escaping (GRPCCore.ClientResponse<Primandproper_Platform_Signin_V1_AttachPasswordResponse>) async throws -> Result = { response in
            try response.message
        }
    ) async throws -> Result where Result: Sendable {
        let request = GRPCCore.ClientRequest<Primandproper_Platform_Signin_V1_AttachPasswordRequest>(
            message: message,
            metadata: metadata
        )
        return try await self.attachPassword(
            request: request,
            options: options,
            onResponse: handleResponse
        )
    }

    /// Call the "VerifyEmailAddress" method.
    ///
    /// - Parameters:
    ///   - message: request message to send.
    ///   - metadata: Additional metadata to send, defaults to empty.
    ///   - options: Options to apply to this RPC, defaults to `.defaults`.
    ///   - handleResponse: A closure which handles the response, the result of which is
    ///       returned to the caller. Returning from the closure will cancel the RPC if it
    ///       hasn't already finished.
    /// - Returns: The result of `handleResponse`.
    internal func verifyEmailAddress<Result>(
        _ message: Primandproper_Platform_Signin_V1_VerifyEmailAddressRequest,
        metadata: GRPCCore.Metadata = [:],
        options: GRPCCore.CallOptions = .defaults,
        onResponse handleResponse: @Sendable @escaping (GRPCCore.ClientResponse<Primandproper_Platform_Signin_V1_VerifyEmailAddressResponse>) async throws -> Result = { response in
            try response.message
        }
    ) async throws -> Result where Result: Sendable {
        let request = GRPCCore.ClientRequest<Primandproper_Platform_Signin_V1_VerifyEmailAddressRequest>(
            message: message,
            metadata: metadata
        )
        return try await self.verifyEmailAddress(
            request: request,
            options: options,
            onResponse: handleResponse
        )
    }

    /// Call the "RequestMagicLink" method.
    ///
    /// > Source IDL Documentation:
    /// >
    /// > The passwordless door, both halves anonymous. Requesting a link names an
    /// > address and is answered the same way whoever holds it; redeeming one carries
    /// > the token that was mailed, which is the whole of its authority. Neither can
    /// > name a user, so neither is a way to ask about one.
    /// > 
    /// > Rate limiting is the consumer's, in front of RequestMagicLink, and it is not
    /// > optional: this is the one RPC in this service that sends mail on request.
    ///
    /// - Parameters:
    ///   - message: request message to send.
    ///   - metadata: Additional metadata to send, defaults to empty.
    ///   - options: Options to apply to this RPC, defaults to `.defaults`.
    ///   - handleResponse: A closure which handles the response, the result of which is
    ///       returned to the caller. Returning from the closure will cancel the RPC if it
    ///       hasn't already finished.
    /// - Returns: The result of `handleResponse`.
    internal func requestMagicLink<Result>(
        _ message: Primandproper_Platform_Signin_V1_RequestMagicLinkRequest,
        metadata: GRPCCore.Metadata = [:],
        options: GRPCCore.CallOptions = .defaults,
        onResponse handleResponse: @Sendable @escaping (GRPCCore.ClientResponse<Primandproper_Platform_Signin_V1_RequestMagicLinkResponse>) async throws -> Result = { response in
            try response.message
        }
    ) async throws -> Result where Result: Sendable {
        let request = GRPCCore.ClientRequest<Primandproper_Platform_Signin_V1_RequestMagicLinkRequest>(
            message: message,
            metadata: metadata
        )
        return try await self.requestMagicLink(
            request: request,
            options: options,
            onResponse: handleResponse
        )
    }

    /// Call the "RedeemMagicLink" method.
    ///
    /// - Parameters:
    ///   - message: request message to send.
    ///   - metadata: Additional metadata to send, defaults to empty.
    ///   - options: Options to apply to this RPC, defaults to `.defaults`.
    ///   - handleResponse: A closure which handles the response, the result of which is
    ///       returned to the caller. Returning from the closure will cancel the RPC if it
    ///       hasn't already finished.
    /// - Returns: The result of `handleResponse`.
    internal func redeemMagicLink<Result>(
        _ message: Primandproper_Platform_Signin_V1_RedeemMagicLinkRequest,
        metadata: GRPCCore.Metadata = [:],
        options: GRPCCore.CallOptions = .defaults,
        onResponse handleResponse: @Sendable @escaping (GRPCCore.ClientResponse<Primandproper_Platform_Signin_V1_RedeemMagicLinkResponse>) async throws -> Result = { response in
            try response.message
        }
    ) async throws -> Result where Result: Sendable {
        let request = GRPCCore.ClientRequest<Primandproper_Platform_Signin_V1_RedeemMagicLinkRequest>(
            message: message,
            metadata: metadata
        )
        return try await self.redeemMagicLink(
            request: request,
            options: options,
            onResponse: handleResponse
        )
    }

    /// Call the "LoginForToken" method.
    ///
    /// > Source IDL Documentation:
    /// >
    /// > The two doors, and the one that keeps a sign-in alive without reopening
    /// > either of them.
    ///
    /// - Parameters:
    ///   - message: request message to send.
    ///   - metadata: Additional metadata to send, defaults to empty.
    ///   - options: Options to apply to this RPC, defaults to `.defaults`.
    ///   - handleResponse: A closure which handles the response, the result of which is
    ///       returned to the caller. Returning from the closure will cancel the RPC if it
    ///       hasn't already finished.
    /// - Returns: The result of `handleResponse`.
    internal func loginForToken<Result>(
        _ message: Primandproper_Platform_Signin_V1_LoginForTokenRequest,
        metadata: GRPCCore.Metadata = [:],
        options: GRPCCore.CallOptions = .defaults,
        onResponse handleResponse: @Sendable @escaping (GRPCCore.ClientResponse<Primandproper_Platform_Signin_V1_LoginForTokenResponse>) async throws -> Result = { response in
            try response.message
        }
    ) async throws -> Result where Result: Sendable {
        let request = GRPCCore.ClientRequest<Primandproper_Platform_Signin_V1_LoginForTokenRequest>(
            message: message,
            metadata: metadata
        )
        return try await self.loginForToken(
            request: request,
            options: options,
            onResponse: handleResponse
        )
    }

    /// Call the "AdminLoginForToken" method.
    ///
    /// - Parameters:
    ///   - message: request message to send.
    ///   - metadata: Additional metadata to send, defaults to empty.
    ///   - options: Options to apply to this RPC, defaults to `.defaults`.
    ///   - handleResponse: A closure which handles the response, the result of which is
    ///       returned to the caller. Returning from the closure will cancel the RPC if it
    ///       hasn't already finished.
    /// - Returns: The result of `handleResponse`.
    internal func adminLoginForToken<Result>(
        _ message: Primandproper_Platform_Signin_V1_AdminLoginForTokenRequest,
        metadata: GRPCCore.Metadata = [:],
        options: GRPCCore.CallOptions = .defaults,
        onResponse handleResponse: @Sendable @escaping (GRPCCore.ClientResponse<Primandproper_Platform_Signin_V1_AdminLoginForTokenResponse>) async throws -> Result = { response in
            try response.message
        }
    ) async throws -> Result where Result: Sendable {
        let request = GRPCCore.ClientRequest<Primandproper_Platform_Signin_V1_AdminLoginForTokenRequest>(
            message: message,
            metadata: metadata
        )
        return try await self.adminLoginForToken(
            request: request,
            options: options,
            onResponse: handleResponse
        )
    }

    /// Call the "ExchangeRefreshToken" method.
    ///
    /// - Parameters:
    ///   - message: request message to send.
    ///   - metadata: Additional metadata to send, defaults to empty.
    ///   - options: Options to apply to this RPC, defaults to `.defaults`.
    ///   - handleResponse: A closure which handles the response, the result of which is
    ///       returned to the caller. Returning from the closure will cancel the RPC if it
    ///       hasn't already finished.
    /// - Returns: The result of `handleResponse`.
    internal func exchangeRefreshToken<Result>(
        _ message: Primandproper_Platform_Signin_V1_ExchangeRefreshTokenRequest,
        metadata: GRPCCore.Metadata = [:],
        options: GRPCCore.CallOptions = .defaults,
        onResponse handleResponse: @Sendable @escaping (GRPCCore.ClientResponse<Primandproper_Platform_Signin_V1_ExchangeRefreshTokenResponse>) async throws -> Result = { response in
            try response.message
        }
    ) async throws -> Result where Result: Sendable {
        let request = GRPCCore.ClientRequest<Primandproper_Platform_Signin_V1_ExchangeRefreshTokenRequest>(
            message: message,
            metadata: metadata
        )
        return try await self.exchangeRefreshToken(
            request: request,
            options: options,
            onResponse: handleResponse
        )
    }

    /// Call the "GetAuthStatus" method.
    ///
    /// > Source IDL Documentation:
    /// >
    /// > The two reads a client makes on load.
    ///
    /// - Parameters:
    ///   - message: request message to send.
    ///   - metadata: Additional metadata to send, defaults to empty.
    ///   - options: Options to apply to this RPC, defaults to `.defaults`.
    ///   - handleResponse: A closure which handles the response, the result of which is
    ///       returned to the caller. Returning from the closure will cancel the RPC if it
    ///       hasn't already finished.
    /// - Returns: The result of `handleResponse`.
    internal func getAuthStatus<Result>(
        _ message: Primandproper_Platform_Signin_V1_GetAuthStatusRequest,
        metadata: GRPCCore.Metadata = [:],
        options: GRPCCore.CallOptions = .defaults,
        onResponse handleResponse: @Sendable @escaping (GRPCCore.ClientResponse<Primandproper_Platform_Signin_V1_GetAuthStatusResponse>) async throws -> Result = { response in
            try response.message
        }
    ) async throws -> Result where Result: Sendable {
        let request = GRPCCore.ClientRequest<Primandproper_Platform_Signin_V1_GetAuthStatusRequest>(
            message: message,
            metadata: metadata
        )
        return try await self.getAuthStatus(
            request: request,
            options: options,
            onResponse: handleResponse
        )
    }

    /// Call the "GetSelf" method.
    ///
    /// - Parameters:
    ///   - message: request message to send.
    ///   - metadata: Additional metadata to send, defaults to empty.
    ///   - options: Options to apply to this RPC, defaults to `.defaults`.
    ///   - handleResponse: A closure which handles the response, the result of which is
    ///       returned to the caller. Returning from the closure will cancel the RPC if it
    ///       hasn't already finished.
    /// - Returns: The result of `handleResponse`.
    internal func getSelf<Result>(
        _ message: Primandproper_Platform_Signin_V1_GetSelfRequest,
        metadata: GRPCCore.Metadata = [:],
        options: GRPCCore.CallOptions = .defaults,
        onResponse handleResponse: @Sendable @escaping (GRPCCore.ClientResponse<Primandproper_Platform_Signin_V1_GetSelfResponse>) async throws -> Result = { response in
            try response.message
        }
    ) async throws -> Result where Result: Sendable {
        let request = GRPCCore.ClientRequest<Primandproper_Platform_Signin_V1_GetSelfRequest>(
            message: message,
            metadata: metadata
        )
        return try await self.getSelf(
            request: request,
            options: options,
            onResponse: handleResponse
        )
    }

    /// Call the "UpdatePassword" method.
    ///
    /// > Source IDL Documentation:
    /// >
    /// > The three writes a signed-in person makes about their own credentials.
    ///
    /// - Parameters:
    ///   - message: request message to send.
    ///   - metadata: Additional metadata to send, defaults to empty.
    ///   - options: Options to apply to this RPC, defaults to `.defaults`.
    ///   - handleResponse: A closure which handles the response, the result of which is
    ///       returned to the caller. Returning from the closure will cancel the RPC if it
    ///       hasn't already finished.
    /// - Returns: The result of `handleResponse`.
    internal func updatePassword<Result>(
        _ message: Primandproper_Platform_Signin_V1_UpdatePasswordRequest,
        metadata: GRPCCore.Metadata = [:],
        options: GRPCCore.CallOptions = .defaults,
        onResponse handleResponse: @Sendable @escaping (GRPCCore.ClientResponse<Primandproper_Platform_Signin_V1_UpdatePasswordResponse>) async throws -> Result = { response in
            try response.message
        }
    ) async throws -> Result where Result: Sendable {
        let request = GRPCCore.ClientRequest<Primandproper_Platform_Signin_V1_UpdatePasswordRequest>(
            message: message,
            metadata: metadata
        )
        return try await self.updatePassword(
            request: request,
            options: options,
            onResponse: handleResponse
        )
    }

    /// Call the "RefreshTOTPSecret" method.
    ///
    /// - Parameters:
    ///   - message: request message to send.
    ///   - metadata: Additional metadata to send, defaults to empty.
    ///   - options: Options to apply to this RPC, defaults to `.defaults`.
    ///   - handleResponse: A closure which handles the response, the result of which is
    ///       returned to the caller. Returning from the closure will cancel the RPC if it
    ///       hasn't already finished.
    /// - Returns: The result of `handleResponse`.
    internal func refreshTOTPSecret<Result>(
        _ message: Primandproper_Platform_Signin_V1_RefreshTOTPSecretRequest,
        metadata: GRPCCore.Metadata = [:],
        options: GRPCCore.CallOptions = .defaults,
        onResponse handleResponse: @Sendable @escaping (GRPCCore.ClientResponse<Primandproper_Platform_Signin_V1_RefreshTOTPSecretResponse>) async throws -> Result = { response in
            try response.message
        }
    ) async throws -> Result where Result: Sendable {
        let request = GRPCCore.ClientRequest<Primandproper_Platform_Signin_V1_RefreshTOTPSecretRequest>(
            message: message,
            metadata: metadata
        )
        return try await self.refreshTOTPSecret(
            request: request,
            options: options,
            onResponse: handleResponse
        )
    }

    /// Call the "VerifyTOTPSecret" method.
    ///
    /// - Parameters:
    ///   - message: request message to send.
    ///   - metadata: Additional metadata to send, defaults to empty.
    ///   - options: Options to apply to this RPC, defaults to `.defaults`.
    ///   - handleResponse: A closure which handles the response, the result of which is
    ///       returned to the caller. Returning from the closure will cancel the RPC if it
    ///       hasn't already finished.
    /// - Returns: The result of `handleResponse`.
    internal func verifyTOTPSecret<Result>(
        _ message: Primandproper_Platform_Signin_V1_VerifyTOTPSecretRequest,
        metadata: GRPCCore.Metadata = [:],
        options: GRPCCore.CallOptions = .defaults,
        onResponse handleResponse: @Sendable @escaping (GRPCCore.ClientResponse<Primandproper_Platform_Signin_V1_VerifyTOTPSecretResponse>) async throws -> Result = { response in
            try response.message
        }
    ) async throws -> Result where Result: Sendable {
        let request = GRPCCore.ClientRequest<Primandproper_Platform_Signin_V1_VerifyTOTPSecretRequest>(
            message: message,
            metadata: metadata
        )
        return try await self.verifyTOTPSecret(
            request: request,
            options: options,
            onResponse: handleResponse
        )
    }
}