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
// [RegistrationInvitation] -- and on [IssuedToken], [AuthStatus],
// [Registered] and [TOTPEnrollment], which the responses are built from.
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
// Register, since calling it proves nothing about who holds the address. It
// arrives back here only
// as a request field on the RPCs that answer a link, which is identity's
// rule for an invitation's token and is the same rule for the same reason.
//
// No passkeys and no password reset. Each is a flow of its own over an engine
// this module already ships, and each is its own file rather than a branch in
// this one. The logins a person holds are here -- ListSignIns and EndSignIn read
// and end the refresh token families above -- and a session in the sense of
// github.com/primandproper/platform-go/v14/sessions still is not. Email-link sign-in -- a door that mints a
// token from a clicked link rather than from a password -- is not here either:
// it is a sibling of LoginForToken rather than a branch inside it, and it is
// the one thing a registrant who named no password still needs.
//
// # Two services, and why the second exists
//
// SignInService permissions nothing: every RPC on it is a door, a finish of a
// registration, or about the caller and nobody else. An operator's view of
// somebody else's logins is a different act, and it is SignInAdministrationService
// rather than a field on those RPCs naming a user -- a field that would turn every
// "about the caller" guarantee on SignInService into a question about the
// caller's grants. The second service is the one that is permissioned, one
// declared permission per RPC and no default grant for any of them, so which
// callers are operators stays the deployment's policy. See
// authentication/signin/grpc's Permissions.

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
internal enum Primandproper_Platform_Signin_V1_SignInService: Sendable {
    /// Service descriptor for the "primandproper.platform.signin.v1.SignInService" service.
    internal static let descriptor = GRPCCore.ServiceDescriptor(fullyQualifiedService: "primandproper.platform.signin.v1.SignInService")
    /// Namespace for method metadata.
    internal enum Method: Sendable {
        /// Namespace for "Register" metadata.
        internal enum Register: Sendable {
            /// Request type for "Register".
            internal typealias Input = Primandproper_Platform_Signin_V1_RegisterRequest
            /// Response type for "Register".
            internal typealias Output = Primandproper_Platform_Signin_V1_RegisterResponse
            /// Descriptor for "Register".
            internal static let descriptor = GRPCCore.MethodDescriptor(
                service: GRPCCore.ServiceDescriptor(fullyQualifiedService: "primandproper.platform.signin.v1.SignInService"),
                method: "Register",
                type: .unary
            )
        }
        /// Namespace for "AttachPassword" metadata.
        internal enum AttachPassword: Sendable {
            /// Request type for "AttachPassword".
            internal typealias Input = Primandproper_Platform_Signin_V1_AttachPasswordRequest
            /// Response type for "AttachPassword".
            internal typealias Output = Primandproper_Platform_Signin_V1_AttachPasswordResponse
            /// Descriptor for "AttachPassword".
            internal static let descriptor = GRPCCore.MethodDescriptor(
                service: GRPCCore.ServiceDescriptor(fullyQualifiedService: "primandproper.platform.signin.v1.SignInService"),
                method: "AttachPassword",
                type: .unary
            )
        }
        /// Namespace for "VerifyEmailAddress" metadata.
        internal enum VerifyEmailAddress: Sendable {
            /// Request type for "VerifyEmailAddress".
            internal typealias Input = Primandproper_Platform_Signin_V1_VerifyEmailAddressRequest
            /// Response type for "VerifyEmailAddress".
            internal typealias Output = Primandproper_Platform_Signin_V1_VerifyEmailAddressResponse
            /// Descriptor for "VerifyEmailAddress".
            internal static let descriptor = GRPCCore.MethodDescriptor(
                service: GRPCCore.ServiceDescriptor(fullyQualifiedService: "primandproper.platform.signin.v1.SignInService"),
                method: "VerifyEmailAddress",
                type: .unary
            )
        }
        /// Namespace for "RequestVerificationEmail" metadata.
        internal enum RequestVerificationEmail: Sendable {
            /// Request type for "RequestVerificationEmail".
            internal typealias Input = Primandproper_Platform_Signin_V1_RequestVerificationEmailRequest
            /// Response type for "RequestVerificationEmail".
            internal typealias Output = Primandproper_Platform_Signin_V1_RequestVerificationEmailResponse
            /// Descriptor for "RequestVerificationEmail".
            internal static let descriptor = GRPCCore.MethodDescriptor(
                service: GRPCCore.ServiceDescriptor(fullyQualifiedService: "primandproper.platform.signin.v1.SignInService"),
                method: "RequestVerificationEmail",
                type: .unary
            )
        }
        /// Namespace for "RequestVerificationEmailByAddress" metadata.
        internal enum RequestVerificationEmailByAddress: Sendable {
            /// Request type for "RequestVerificationEmailByAddress".
            internal typealias Input = Primandproper_Platform_Signin_V1_RequestVerificationEmailByAddressRequest
            /// Response type for "RequestVerificationEmailByAddress".
            internal typealias Output = Primandproper_Platform_Signin_V1_RequestVerificationEmailByAddressResponse
            /// Descriptor for "RequestVerificationEmailByAddress".
            internal static let descriptor = GRPCCore.MethodDescriptor(
                service: GRPCCore.ServiceDescriptor(fullyQualifiedService: "primandproper.platform.signin.v1.SignInService"),
                method: "RequestVerificationEmailByAddress",
                type: .unary
            )
        }
        /// Namespace for "RequestMagicLink" metadata.
        internal enum RequestMagicLink: Sendable {
            /// Request type for "RequestMagicLink".
            internal typealias Input = Primandproper_Platform_Signin_V1_RequestMagicLinkRequest
            /// Response type for "RequestMagicLink".
            internal typealias Output = Primandproper_Platform_Signin_V1_RequestMagicLinkResponse
            /// Descriptor for "RequestMagicLink".
            internal static let descriptor = GRPCCore.MethodDescriptor(
                service: GRPCCore.ServiceDescriptor(fullyQualifiedService: "primandproper.platform.signin.v1.SignInService"),
                method: "RequestMagicLink",
                type: .unary
            )
        }
        /// Namespace for "RedeemMagicLink" metadata.
        internal enum RedeemMagicLink: Sendable {
            /// Request type for "RedeemMagicLink".
            internal typealias Input = Primandproper_Platform_Signin_V1_RedeemMagicLinkRequest
            /// Response type for "RedeemMagicLink".
            internal typealias Output = Primandproper_Platform_Signin_V1_RedeemMagicLinkResponse
            /// Descriptor for "RedeemMagicLink".
            internal static let descriptor = GRPCCore.MethodDescriptor(
                service: GRPCCore.ServiceDescriptor(fullyQualifiedService: "primandproper.platform.signin.v1.SignInService"),
                method: "RedeemMagicLink",
                type: .unary
            )
        }
        /// Namespace for "RequestHandleReminder" metadata.
        internal enum RequestHandleReminder: Sendable {
            /// Request type for "RequestHandleReminder".
            internal typealias Input = Primandproper_Platform_Signin_V1_RequestHandleReminderRequest
            /// Response type for "RequestHandleReminder".
            internal typealias Output = Primandproper_Platform_Signin_V1_RequestHandleReminderResponse
            /// Descriptor for "RequestHandleReminder".
            internal static let descriptor = GRPCCore.MethodDescriptor(
                service: GRPCCore.ServiceDescriptor(fullyQualifiedService: "primandproper.platform.signin.v1.SignInService"),
                method: "RequestHandleReminder",
                type: .unary
            )
        }
        /// Namespace for "LoginForToken" metadata.
        internal enum LoginForToken: Sendable {
            /// Request type for "LoginForToken".
            internal typealias Input = Primandproper_Platform_Signin_V1_LoginForTokenRequest
            /// Response type for "LoginForToken".
            internal typealias Output = Primandproper_Platform_Signin_V1_LoginForTokenResponse
            /// Descriptor for "LoginForToken".
            internal static let descriptor = GRPCCore.MethodDescriptor(
                service: GRPCCore.ServiceDescriptor(fullyQualifiedService: "primandproper.platform.signin.v1.SignInService"),
                method: "LoginForToken",
                type: .unary
            )
        }
        /// Namespace for "AdminLoginForToken" metadata.
        internal enum AdminLoginForToken: Sendable {
            /// Request type for "AdminLoginForToken".
            internal typealias Input = Primandproper_Platform_Signin_V1_AdminLoginForTokenRequest
            /// Response type for "AdminLoginForToken".
            internal typealias Output = Primandproper_Platform_Signin_V1_AdminLoginForTokenResponse
            /// Descriptor for "AdminLoginForToken".
            internal static let descriptor = GRPCCore.MethodDescriptor(
                service: GRPCCore.ServiceDescriptor(fullyQualifiedService: "primandproper.platform.signin.v1.SignInService"),
                method: "AdminLoginForToken",
                type: .unary
            )
        }
        /// Namespace for "ExchangeRefreshToken" metadata.
        internal enum ExchangeRefreshToken: Sendable {
            /// Request type for "ExchangeRefreshToken".
            internal typealias Input = Primandproper_Platform_Signin_V1_ExchangeRefreshTokenRequest
            /// Response type for "ExchangeRefreshToken".
            internal typealias Output = Primandproper_Platform_Signin_V1_ExchangeRefreshTokenResponse
            /// Descriptor for "ExchangeRefreshToken".
            internal static let descriptor = GRPCCore.MethodDescriptor(
                service: GRPCCore.ServiceDescriptor(fullyQualifiedService: "primandproper.platform.signin.v1.SignInService"),
                method: "ExchangeRefreshToken",
                type: .unary
            )
        }
        /// Namespace for "SwitchAccount" metadata.
        internal enum SwitchAccount: Sendable {
            /// Request type for "SwitchAccount".
            internal typealias Input = Primandproper_Platform_Signin_V1_SwitchAccountRequest
            /// Response type for "SwitchAccount".
            internal typealias Output = Primandproper_Platform_Signin_V1_SwitchAccountResponse
            /// Descriptor for "SwitchAccount".
            internal static let descriptor = GRPCCore.MethodDescriptor(
                service: GRPCCore.ServiceDescriptor(fullyQualifiedService: "primandproper.platform.signin.v1.SignInService"),
                method: "SwitchAccount",
                type: .unary
            )
        }
        /// Namespace for "SignOut" metadata.
        internal enum SignOut: Sendable {
            /// Request type for "SignOut".
            internal typealias Input = Primandproper_Platform_Signin_V1_SignOutRequest
            /// Response type for "SignOut".
            internal typealias Output = Primandproper_Platform_Signin_V1_SignOutResponse
            /// Descriptor for "SignOut".
            internal static let descriptor = GRPCCore.MethodDescriptor(
                service: GRPCCore.ServiceDescriptor(fullyQualifiedService: "primandproper.platform.signin.v1.SignInService"),
                method: "SignOut",
                type: .unary
            )
        }
        /// Namespace for "SignOutEverywhere" metadata.
        internal enum SignOutEverywhere: Sendable {
            /// Request type for "SignOutEverywhere".
            internal typealias Input = Primandproper_Platform_Signin_V1_SignOutEverywhereRequest
            /// Response type for "SignOutEverywhere".
            internal typealias Output = Primandproper_Platform_Signin_V1_SignOutEverywhereResponse
            /// Descriptor for "SignOutEverywhere".
            internal static let descriptor = GRPCCore.MethodDescriptor(
                service: GRPCCore.ServiceDescriptor(fullyQualifiedService: "primandproper.platform.signin.v1.SignInService"),
                method: "SignOutEverywhere",
                type: .unary
            )
        }
        /// Namespace for "ListSignIns" metadata.
        internal enum ListSignIns: Sendable {
            /// Request type for "ListSignIns".
            internal typealias Input = Primandproper_Platform_Signin_V1_ListSignInsRequest
            /// Response type for "ListSignIns".
            internal typealias Output = Primandproper_Platform_Signin_V1_ListSignInsResponse
            /// Descriptor for "ListSignIns".
            internal static let descriptor = GRPCCore.MethodDescriptor(
                service: GRPCCore.ServiceDescriptor(fullyQualifiedService: "primandproper.platform.signin.v1.SignInService"),
                method: "ListSignIns",
                type: .unary
            )
        }
        /// Namespace for "EndSignIn" metadata.
        internal enum EndSignIn: Sendable {
            /// Request type for "EndSignIn".
            internal typealias Input = Primandproper_Platform_Signin_V1_EndSignInRequest
            /// Response type for "EndSignIn".
            internal typealias Output = Primandproper_Platform_Signin_V1_EndSignInResponse
            /// Descriptor for "EndSignIn".
            internal static let descriptor = GRPCCore.MethodDescriptor(
                service: GRPCCore.ServiceDescriptor(fullyQualifiedService: "primandproper.platform.signin.v1.SignInService"),
                method: "EndSignIn",
                type: .unary
            )
        }
        /// Namespace for "EndOtherSignIns" metadata.
        internal enum EndOtherSignIns: Sendable {
            /// Request type for "EndOtherSignIns".
            internal typealias Input = Primandproper_Platform_Signin_V1_EndOtherSignInsRequest
            /// Response type for "EndOtherSignIns".
            internal typealias Output = Primandproper_Platform_Signin_V1_EndOtherSignInsResponse
            /// Descriptor for "EndOtherSignIns".
            internal static let descriptor = GRPCCore.MethodDescriptor(
                service: GRPCCore.ServiceDescriptor(fullyQualifiedService: "primandproper.platform.signin.v1.SignInService"),
                method: "EndOtherSignIns",
                type: .unary
            )
        }
        /// Namespace for "GetAuthStatus" metadata.
        internal enum GetAuthStatus: Sendable {
            /// Request type for "GetAuthStatus".
            internal typealias Input = Primandproper_Platform_Signin_V1_GetAuthStatusRequest
            /// Response type for "GetAuthStatus".
            internal typealias Output = Primandproper_Platform_Signin_V1_GetAuthStatusResponse
            /// Descriptor for "GetAuthStatus".
            internal static let descriptor = GRPCCore.MethodDescriptor(
                service: GRPCCore.ServiceDescriptor(fullyQualifiedService: "primandproper.platform.signin.v1.SignInService"),
                method: "GetAuthStatus",
                type: .unary
            )
        }
        /// Namespace for "GetSelf" metadata.
        internal enum GetSelf: Sendable {
            /// Request type for "GetSelf".
            internal typealias Input = Primandproper_Platform_Signin_V1_GetSelfRequest
            /// Response type for "GetSelf".
            internal typealias Output = Primandproper_Platform_Signin_V1_GetSelfResponse
            /// Descriptor for "GetSelf".
            internal static let descriptor = GRPCCore.MethodDescriptor(
                service: GRPCCore.ServiceDescriptor(fullyQualifiedService: "primandproper.platform.signin.v1.SignInService"),
                method: "GetSelf",
                type: .unary
            )
        }
        /// Namespace for "UpdatePassword" metadata.
        internal enum UpdatePassword: Sendable {
            /// Request type for "UpdatePassword".
            internal typealias Input = Primandproper_Platform_Signin_V1_UpdatePasswordRequest
            /// Response type for "UpdatePassword".
            internal typealias Output = Primandproper_Platform_Signin_V1_UpdatePasswordResponse
            /// Descriptor for "UpdatePassword".
            internal static let descriptor = GRPCCore.MethodDescriptor(
                service: GRPCCore.ServiceDescriptor(fullyQualifiedService: "primandproper.platform.signin.v1.SignInService"),
                method: "UpdatePassword",
                type: .unary
            )
        }
        /// Namespace for "RefreshTOTPSecret" metadata.
        internal enum RefreshTOTPSecret: Sendable {
            /// Request type for "RefreshTOTPSecret".
            internal typealias Input = Primandproper_Platform_Signin_V1_RefreshTOTPSecretRequest
            /// Response type for "RefreshTOTPSecret".
            internal typealias Output = Primandproper_Platform_Signin_V1_RefreshTOTPSecretResponse
            /// Descriptor for "RefreshTOTPSecret".
            internal static let descriptor = GRPCCore.MethodDescriptor(
                service: GRPCCore.ServiceDescriptor(fullyQualifiedService: "primandproper.platform.signin.v1.SignInService"),
                method: "RefreshTOTPSecret",
                type: .unary
            )
        }
        /// Namespace for "VerifyTOTPSecret" metadata.
        internal enum VerifyTOTPSecret: Sendable {
            /// Request type for "VerifyTOTPSecret".
            internal typealias Input = Primandproper_Platform_Signin_V1_VerifyTOTPSecretRequest
            /// Response type for "VerifyTOTPSecret".
            internal typealias Output = Primandproper_Platform_Signin_V1_VerifyTOTPSecretResponse
            /// Descriptor for "VerifyTOTPSecret".
            internal static let descriptor = GRPCCore.MethodDescriptor(
                service: GRPCCore.ServiceDescriptor(fullyQualifiedService: "primandproper.platform.signin.v1.SignInService"),
                method: "VerifyTOTPSecret",
                type: .unary
            )
        }
        /// Namespace for "UpdateEmailAddress" metadata.
        internal enum UpdateEmailAddress: Sendable {
            /// Request type for "UpdateEmailAddress".
            internal typealias Input = Primandproper_Platform_Signin_V1_UpdateEmailAddressRequest
            /// Response type for "UpdateEmailAddress".
            internal typealias Output = Primandproper_Platform_Signin_V1_UpdateEmailAddressResponse
            /// Descriptor for "UpdateEmailAddress".
            internal static let descriptor = GRPCCore.MethodDescriptor(
                service: GRPCCore.ServiceDescriptor(fullyQualifiedService: "primandproper.platform.signin.v1.SignInService"),
                method: "UpdateEmailAddress",
                type: .unary
            )
        }
        /// Namespace for "UpdateUsername" metadata.
        internal enum UpdateUsername: Sendable {
            /// Request type for "UpdateUsername".
            internal typealias Input = Primandproper_Platform_Signin_V1_UpdateUsernameRequest
            /// Response type for "UpdateUsername".
            internal typealias Output = Primandproper_Platform_Signin_V1_UpdateUsernameResponse
            /// Descriptor for "UpdateUsername".
            internal static let descriptor = GRPCCore.MethodDescriptor(
                service: GRPCCore.ServiceDescriptor(fullyQualifiedService: "primandproper.platform.signin.v1.SignInService"),
                method: "UpdateUsername",
                type: .unary
            )
        }
        /// Descriptors for all methods in the "primandproper.platform.signin.v1.SignInService" service.
        internal static let descriptors: [GRPCCore.MethodDescriptor] = [
            Register.descriptor,
            AttachPassword.descriptor,
            VerifyEmailAddress.descriptor,
            RequestVerificationEmail.descriptor,
            RequestVerificationEmailByAddress.descriptor,
            RequestMagicLink.descriptor,
            RedeemMagicLink.descriptor,
            RequestHandleReminder.descriptor,
            LoginForToken.descriptor,
            AdminLoginForToken.descriptor,
            ExchangeRefreshToken.descriptor,
            SwitchAccount.descriptor,
            SignOut.descriptor,
            SignOutEverywhere.descriptor,
            ListSignIns.descriptor,
            EndSignIn.descriptor,
            EndOtherSignIns.descriptor,
            GetAuthStatus.descriptor,
            GetSelf.descriptor,
            UpdatePassword.descriptor,
            RefreshTOTPSecret.descriptor,
            VerifyTOTPSecret.descriptor,
            UpdateEmailAddress.descriptor,
            UpdateUsername.descriptor
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
    /// > Some of its RPCs are anonymous by definition and the rest require a caller.
    /// > What none of them requires is a permission: there is no grant that would make
    /// > "sign in" safer, and every authenticated one takes its subject from the
    /// > caller and has no field that could name anybody else. See
    /// > authentication/signin/grpc's Require for how that is declared to an
    /// > authorization policy, which is not the same thing as being left out of one.
    /// > What an operator does to somebody else's logins is
    /// > SignInAdministrationService, which is permissioned, and which is a service of
    /// > its own so that this statement stays true of this one.
    internal protocol ClientProtocol: Sendable {
        /// Call the "Register" method.
        ///
        /// > Source IDL Documentation:
        /// >
        /// > Arriving, and the two ways a registration is finished. All three are
        /// > anonymous. Register is the sign-up door, and it is open by default: the
        /// > policy an open sign-up has in it -- who may register, which agreements
        /// > they must accept, what standing and roles they start with -- is the
        /// > deployment's registration policy, which the service runs on every
        /// > registration before anything is hashed, minted or written, and the roles
        /// > a registrant owns their account with are the deployment's, never the
        /// > request's. A caller who is signed in still reaches it, and an operator
        /// > provisioning users calls it that way. A deployment that does not want
        /// > sign-up closes the door by name, and is then answered with
        /// > UNIMPLEMENTED carrying REGISTRATION_CLOSED, so a client can tell a closed
        /// > door from a broken one. Rate limiting it is the consumer's, in front of
        /// > it, as it is for the sign-in doors. The other two carry their own
        /// > authority, which is the token that was mailed to the person they are
        /// > about.
        ///
        /// - Parameters:
        ///   - request: A request containing a single `Primandproper_Platform_Signin_V1_RegisterRequest` message.
        ///   - serializer: A serializer for `Primandproper_Platform_Signin_V1_RegisterRequest` messages.
        ///   - deserializer: A deserializer for `Primandproper_Platform_Signin_V1_RegisterResponse` messages.
        ///   - options: Options to apply to this RPC.
        ///   - handleResponse: A closure which handles the response and returns its result to
        ///       the caller. Returning from the closure will cancel the RPC if it hasn't
        ///       already finished.
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
        ///   - handleResponse: A closure which handles the response and returns its result to
        ///       the caller. Returning from the closure will cancel the RPC if it hasn't
        ///       already finished.
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
        ///   - handleResponse: A closure which handles the response and returns its result to
        ///       the caller. Returning from the closure will cancel the RPC if it hasn't
        ///       already finished.
        /// - Returns: The result of `handleResponse`.
        func verifyEmailAddress<Result>(
            request: GRPCCore.ClientRequest<Primandproper_Platform_Signin_V1_VerifyEmailAddressRequest>,
            serializer: some GRPCCore.MessageSerializer<Primandproper_Platform_Signin_V1_VerifyEmailAddressRequest>,
            deserializer: some GRPCCore.MessageDeserializer<Primandproper_Platform_Signin_V1_VerifyEmailAddressResponse>,
            options: GRPCCore.CallOptions,
            onResponse handleResponse: @Sendable @escaping (GRPCCore.ClientResponse<Primandproper_Platform_Signin_V1_VerifyEmailAddressResponse>) async throws -> Result
        ) async throws -> Result where Result: Sendable

        /// Call the "RequestVerificationEmail" method.
        ///
        /// > Source IDL Documentation:
        /// >
        /// > Asking for another verification link. The first requires a caller and
        /// > names nobody, for somebody signed in whose address changed; the second is
        /// > anonymous and names an address, for a registrant who cannot sign in until
        /// > they answer one, and is answered the same way whoever holds it.
        ///
        /// - Parameters:
        ///   - request: A request containing a single `Primandproper_Platform_Signin_V1_RequestVerificationEmailRequest` message.
        ///   - serializer: A serializer for `Primandproper_Platform_Signin_V1_RequestVerificationEmailRequest` messages.
        ///   - deserializer: A deserializer for `Primandproper_Platform_Signin_V1_RequestVerificationEmailResponse` messages.
        ///   - options: Options to apply to this RPC.
        ///   - handleResponse: A closure which handles the response and returns its result to
        ///       the caller. Returning from the closure will cancel the RPC if it hasn't
        ///       already finished.
        /// - Returns: The result of `handleResponse`.
        func requestVerificationEmail<Result>(
            request: GRPCCore.ClientRequest<Primandproper_Platform_Signin_V1_RequestVerificationEmailRequest>,
            serializer: some GRPCCore.MessageSerializer<Primandproper_Platform_Signin_V1_RequestVerificationEmailRequest>,
            deserializer: some GRPCCore.MessageDeserializer<Primandproper_Platform_Signin_V1_RequestVerificationEmailResponse>,
            options: GRPCCore.CallOptions,
            onResponse handleResponse: @Sendable @escaping (GRPCCore.ClientResponse<Primandproper_Platform_Signin_V1_RequestVerificationEmailResponse>) async throws -> Result
        ) async throws -> Result where Result: Sendable

        /// Call the "RequestVerificationEmailByAddress" method.
        ///
        /// - Parameters:
        ///   - request: A request containing a single `Primandproper_Platform_Signin_V1_RequestVerificationEmailByAddressRequest` message.
        ///   - serializer: A serializer for `Primandproper_Platform_Signin_V1_RequestVerificationEmailByAddressRequest` messages.
        ///   - deserializer: A deserializer for `Primandproper_Platform_Signin_V1_RequestVerificationEmailByAddressResponse` messages.
        ///   - options: Options to apply to this RPC.
        ///   - handleResponse: A closure which handles the response and returns its result to
        ///       the caller. Returning from the closure will cancel the RPC if it hasn't
        ///       already finished.
        /// - Returns: The result of `handleResponse`.
        func requestVerificationEmailByAddress<Result>(
            request: GRPCCore.ClientRequest<Primandproper_Platform_Signin_V1_RequestVerificationEmailByAddressRequest>,
            serializer: some GRPCCore.MessageSerializer<Primandproper_Platform_Signin_V1_RequestVerificationEmailByAddressRequest>,
            deserializer: some GRPCCore.MessageDeserializer<Primandproper_Platform_Signin_V1_RequestVerificationEmailByAddressResponse>,
            options: GRPCCore.CallOptions,
            onResponse handleResponse: @Sendable @escaping (GRPCCore.ClientResponse<Primandproper_Platform_Signin_V1_RequestVerificationEmailByAddressResponse>) async throws -> Result
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
        /// > optional: it sends mail on request.
        ///
        /// - Parameters:
        ///   - request: A request containing a single `Primandproper_Platform_Signin_V1_RequestMagicLinkRequest` message.
        ///   - serializer: A serializer for `Primandproper_Platform_Signin_V1_RequestMagicLinkRequest` messages.
        ///   - deserializer: A deserializer for `Primandproper_Platform_Signin_V1_RequestMagicLinkResponse` messages.
        ///   - options: Options to apply to this RPC.
        ///   - handleResponse: A closure which handles the response and returns its result to
        ///       the caller. Returning from the closure will cancel the RPC if it hasn't
        ///       already finished.
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
        ///   - handleResponse: A closure which handles the response and returns its result to
        ///       the caller. Returning from the closure will cancel the RPC if it hasn't
        ///       already finished.
        /// - Returns: The result of `handleResponse`.
        func redeemMagicLink<Result>(
            request: GRPCCore.ClientRequest<Primandproper_Platform_Signin_V1_RedeemMagicLinkRequest>,
            serializer: some GRPCCore.MessageSerializer<Primandproper_Platform_Signin_V1_RedeemMagicLinkRequest>,
            deserializer: some GRPCCore.MessageDeserializer<Primandproper_Platform_Signin_V1_RedeemMagicLinkResponse>,
            options: GRPCCore.CallOptions,
            onResponse handleResponse: @Sendable @escaping (GRPCCore.ClientResponse<Primandproper_Platform_Signin_V1_RedeemMagicLinkResponse>) async throws -> Result
        ) async throws -> Result where Result: Sendable

        /// Call the "RequestHandleReminder" method.
        ///
        /// > Source IDL Documentation:
        /// >
        /// > The door for somebody who has forgotten what they sign in as. It is
        /// > anonymous and answered the same way whoever holds the address, as
        /// > RequestMagicLink is, and its rate limit is the consumer's for the same
        /// > reason: it sends mail on request.
        ///
        /// - Parameters:
        ///   - request: A request containing a single `Primandproper_Platform_Signin_V1_RequestHandleReminderRequest` message.
        ///   - serializer: A serializer for `Primandproper_Platform_Signin_V1_RequestHandleReminderRequest` messages.
        ///   - deserializer: A deserializer for `Primandproper_Platform_Signin_V1_RequestHandleReminderResponse` messages.
        ///   - options: Options to apply to this RPC.
        ///   - handleResponse: A closure which handles the response and returns its result to
        ///       the caller. Returning from the closure will cancel the RPC if it hasn't
        ///       already finished.
        /// - Returns: The result of `handleResponse`.
        func requestHandleReminder<Result>(
            request: GRPCCore.ClientRequest<Primandproper_Platform_Signin_V1_RequestHandleReminderRequest>,
            serializer: some GRPCCore.MessageSerializer<Primandproper_Platform_Signin_V1_RequestHandleReminderRequest>,
            deserializer: some GRPCCore.MessageDeserializer<Primandproper_Platform_Signin_V1_RequestHandleReminderResponse>,
            options: GRPCCore.CallOptions,
            onResponse handleResponse: @Sendable @escaping (GRPCCore.ClientResponse<Primandproper_Platform_Signin_V1_RequestHandleReminderResponse>) async throws -> Result
        ) async throws -> Result where Result: Sendable

        /// Call the "LoginForToken" method.
        ///
        /// > Source IDL Documentation:
        /// >
        /// > The two doors, the one that keeps a sign-in alive without reopening
        /// > either of them, and the one that moves it to another of the person's
        /// > accounts without reopening them either.
        ///
        /// - Parameters:
        ///   - request: A request containing a single `Primandproper_Platform_Signin_V1_LoginForTokenRequest` message.
        ///   - serializer: A serializer for `Primandproper_Platform_Signin_V1_LoginForTokenRequest` messages.
        ///   - deserializer: A deserializer for `Primandproper_Platform_Signin_V1_LoginForTokenResponse` messages.
        ///   - options: Options to apply to this RPC.
        ///   - handleResponse: A closure which handles the response and returns its result to
        ///       the caller. Returning from the closure will cancel the RPC if it hasn't
        ///       already finished.
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
        ///   - handleResponse: A closure which handles the response and returns its result to
        ///       the caller. Returning from the closure will cancel the RPC if it hasn't
        ///       already finished.
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
        ///   - handleResponse: A closure which handles the response and returns its result to
        ///       the caller. Returning from the closure will cancel the RPC if it hasn't
        ///       already finished.
        /// - Returns: The result of `handleResponse`.
        func exchangeRefreshToken<Result>(
            request: GRPCCore.ClientRequest<Primandproper_Platform_Signin_V1_ExchangeRefreshTokenRequest>,
            serializer: some GRPCCore.MessageSerializer<Primandproper_Platform_Signin_V1_ExchangeRefreshTokenRequest>,
            deserializer: some GRPCCore.MessageDeserializer<Primandproper_Platform_Signin_V1_ExchangeRefreshTokenResponse>,
            options: GRPCCore.CallOptions,
            onResponse handleResponse: @Sendable @escaping (GRPCCore.ClientResponse<Primandproper_Platform_Signin_V1_ExchangeRefreshTokenResponse>) async throws -> Result
        ) async throws -> Result where Result: Sendable

        /// Call the "SwitchAccount" method.
        ///
        /// - Parameters:
        ///   - request: A request containing a single `Primandproper_Platform_Signin_V1_SwitchAccountRequest` message.
        ///   - serializer: A serializer for `Primandproper_Platform_Signin_V1_SwitchAccountRequest` messages.
        ///   - deserializer: A deserializer for `Primandproper_Platform_Signin_V1_SwitchAccountResponse` messages.
        ///   - options: Options to apply to this RPC.
        ///   - handleResponse: A closure which handles the response and returns its result to
        ///       the caller. Returning from the closure will cancel the RPC if it hasn't
        ///       already finished.
        /// - Returns: The result of `handleResponse`.
        func switchAccount<Result>(
            request: GRPCCore.ClientRequest<Primandproper_Platform_Signin_V1_SwitchAccountRequest>,
            serializer: some GRPCCore.MessageSerializer<Primandproper_Platform_Signin_V1_SwitchAccountRequest>,
            deserializer: some GRPCCore.MessageDeserializer<Primandproper_Platform_Signin_V1_SwitchAccountResponse>,
            options: GRPCCore.CallOptions,
            onResponse handleResponse: @Sendable @escaping (GRPCCore.ClientResponse<Primandproper_Platform_Signin_V1_SwitchAccountResponse>) async throws -> Result
        ) async throws -> Result where Result: Sendable

        /// Call the "SignOut" method.
        ///
        /// > Source IDL Documentation:
        /// >
        /// > The way out, in its two sizes. Ending this login carries the credential and
        /// > needs no caller, so an application whose access token expired while it was
        /// > closed can still sign out; ending every login needs a caller and names
        /// > nobody. Both are a client's to call and neither is an operator's tool --
        /// > revoking somebody else's sessions is SignInAdministrationService's.
        ///
        /// - Parameters:
        ///   - request: A request containing a single `Primandproper_Platform_Signin_V1_SignOutRequest` message.
        ///   - serializer: A serializer for `Primandproper_Platform_Signin_V1_SignOutRequest` messages.
        ///   - deserializer: A deserializer for `Primandproper_Platform_Signin_V1_SignOutResponse` messages.
        ///   - options: Options to apply to this RPC.
        ///   - handleResponse: A closure which handles the response and returns its result to
        ///       the caller. Returning from the closure will cancel the RPC if it hasn't
        ///       already finished.
        /// - Returns: The result of `handleResponse`.
        func signOut<Result>(
            request: GRPCCore.ClientRequest<Primandproper_Platform_Signin_V1_SignOutRequest>,
            serializer: some GRPCCore.MessageSerializer<Primandproper_Platform_Signin_V1_SignOutRequest>,
            deserializer: some GRPCCore.MessageDeserializer<Primandproper_Platform_Signin_V1_SignOutResponse>,
            options: GRPCCore.CallOptions,
            onResponse handleResponse: @Sendable @escaping (GRPCCore.ClientResponse<Primandproper_Platform_Signin_V1_SignOutResponse>) async throws -> Result
        ) async throws -> Result where Result: Sendable

        /// Call the "SignOutEverywhere" method.
        ///
        /// - Parameters:
        ///   - request: A request containing a single `Primandproper_Platform_Signin_V1_SignOutEverywhereRequest` message.
        ///   - serializer: A serializer for `Primandproper_Platform_Signin_V1_SignOutEverywhereRequest` messages.
        ///   - deserializer: A deserializer for `Primandproper_Platform_Signin_V1_SignOutEverywhereResponse` messages.
        ///   - options: Options to apply to this RPC.
        ///   - handleResponse: A closure which handles the response and returns its result to
        ///       the caller. Returning from the closure will cancel the RPC if it hasn't
        ///       already finished.
        /// - Returns: The result of `handleResponse`.
        func signOutEverywhere<Result>(
            request: GRPCCore.ClientRequest<Primandproper_Platform_Signin_V1_SignOutEverywhereRequest>,
            serializer: some GRPCCore.MessageSerializer<Primandproper_Platform_Signin_V1_SignOutEverywhereRequest>,
            deserializer: some GRPCCore.MessageDeserializer<Primandproper_Platform_Signin_V1_SignOutEverywhereResponse>,
            options: GRPCCore.CallOptions,
            onResponse handleResponse: @Sendable @escaping (GRPCCore.ClientResponse<Primandproper_Platform_Signin_V1_SignOutEverywhereResponse>) async throws -> Result
        ) async throws -> Result where Result: Sendable

        /// Call the "ListSignIns" method.
        ///
        /// > Source IDL Documentation:
        /// >
        /// > The screen between those two sizes: the calling user's live logins, ending
        /// > one of them by name, and ending all of them but the one asking. All three
        /// > need a caller and name nobody else; an operator doing any of them for
        /// > somebody else calls SignInAdministrationService.
        ///
        /// - Parameters:
        ///   - request: A request containing a single `Primandproper_Platform_Signin_V1_ListSignInsRequest` message.
        ///   - serializer: A serializer for `Primandproper_Platform_Signin_V1_ListSignInsRequest` messages.
        ///   - deserializer: A deserializer for `Primandproper_Platform_Signin_V1_ListSignInsResponse` messages.
        ///   - options: Options to apply to this RPC.
        ///   - handleResponse: A closure which handles the response and returns its result to
        ///       the caller. Returning from the closure will cancel the RPC if it hasn't
        ///       already finished.
        /// - Returns: The result of `handleResponse`.
        func listSignIns<Result>(
            request: GRPCCore.ClientRequest<Primandproper_Platform_Signin_V1_ListSignInsRequest>,
            serializer: some GRPCCore.MessageSerializer<Primandproper_Platform_Signin_V1_ListSignInsRequest>,
            deserializer: some GRPCCore.MessageDeserializer<Primandproper_Platform_Signin_V1_ListSignInsResponse>,
            options: GRPCCore.CallOptions,
            onResponse handleResponse: @Sendable @escaping (GRPCCore.ClientResponse<Primandproper_Platform_Signin_V1_ListSignInsResponse>) async throws -> Result
        ) async throws -> Result where Result: Sendable

        /// Call the "EndSignIn" method.
        ///
        /// - Parameters:
        ///   - request: A request containing a single `Primandproper_Platform_Signin_V1_EndSignInRequest` message.
        ///   - serializer: A serializer for `Primandproper_Platform_Signin_V1_EndSignInRequest` messages.
        ///   - deserializer: A deserializer for `Primandproper_Platform_Signin_V1_EndSignInResponse` messages.
        ///   - options: Options to apply to this RPC.
        ///   - handleResponse: A closure which handles the response and returns its result to
        ///       the caller. Returning from the closure will cancel the RPC if it hasn't
        ///       already finished.
        /// - Returns: The result of `handleResponse`.
        func endSignIn<Result>(
            request: GRPCCore.ClientRequest<Primandproper_Platform_Signin_V1_EndSignInRequest>,
            serializer: some GRPCCore.MessageSerializer<Primandproper_Platform_Signin_V1_EndSignInRequest>,
            deserializer: some GRPCCore.MessageDeserializer<Primandproper_Platform_Signin_V1_EndSignInResponse>,
            options: GRPCCore.CallOptions,
            onResponse handleResponse: @Sendable @escaping (GRPCCore.ClientResponse<Primandproper_Platform_Signin_V1_EndSignInResponse>) async throws -> Result
        ) async throws -> Result where Result: Sendable

        /// Call the "EndOtherSignIns" method.
        ///
        /// - Parameters:
        ///   - request: A request containing a single `Primandproper_Platform_Signin_V1_EndOtherSignInsRequest` message.
        ///   - serializer: A serializer for `Primandproper_Platform_Signin_V1_EndOtherSignInsRequest` messages.
        ///   - deserializer: A deserializer for `Primandproper_Platform_Signin_V1_EndOtherSignInsResponse` messages.
        ///   - options: Options to apply to this RPC.
        ///   - handleResponse: A closure which handles the response and returns its result to
        ///       the caller. Returning from the closure will cancel the RPC if it hasn't
        ///       already finished.
        /// - Returns: The result of `handleResponse`.
        func endOtherSignIns<Result>(
            request: GRPCCore.ClientRequest<Primandproper_Platform_Signin_V1_EndOtherSignInsRequest>,
            serializer: some GRPCCore.MessageSerializer<Primandproper_Platform_Signin_V1_EndOtherSignInsRequest>,
            deserializer: some GRPCCore.MessageDeserializer<Primandproper_Platform_Signin_V1_EndOtherSignInsResponse>,
            options: GRPCCore.CallOptions,
            onResponse handleResponse: @Sendable @escaping (GRPCCore.ClientResponse<Primandproper_Platform_Signin_V1_EndOtherSignInsResponse>) async throws -> Result
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
        ///   - handleResponse: A closure which handles the response and returns its result to
        ///       the caller. Returning from the closure will cancel the RPC if it hasn't
        ///       already finished.
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
        ///   - handleResponse: A closure which handles the response and returns its result to
        ///       the caller. Returning from the closure will cancel the RPC if it hasn't
        ///       already finished.
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
        /// > The writes a signed-in person makes about their own credentials, and the
        /// > two handles that are credentials in all but name. identity's UpdateProfile
        /// > refuses both handles; these are where they change.
        ///
        /// - Parameters:
        ///   - request: A request containing a single `Primandproper_Platform_Signin_V1_UpdatePasswordRequest` message.
        ///   - serializer: A serializer for `Primandproper_Platform_Signin_V1_UpdatePasswordRequest` messages.
        ///   - deserializer: A deserializer for `Primandproper_Platform_Signin_V1_UpdatePasswordResponse` messages.
        ///   - options: Options to apply to this RPC.
        ///   - handleResponse: A closure which handles the response and returns its result to
        ///       the caller. Returning from the closure will cancel the RPC if it hasn't
        ///       already finished.
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
        ///   - handleResponse: A closure which handles the response and returns its result to
        ///       the caller. Returning from the closure will cancel the RPC if it hasn't
        ///       already finished.
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
        ///   - handleResponse: A closure which handles the response and returns its result to
        ///       the caller. Returning from the closure will cancel the RPC if it hasn't
        ///       already finished.
        /// - Returns: The result of `handleResponse`.
        func verifyTOTPSecret<Result>(
            request: GRPCCore.ClientRequest<Primandproper_Platform_Signin_V1_VerifyTOTPSecretRequest>,
            serializer: some GRPCCore.MessageSerializer<Primandproper_Platform_Signin_V1_VerifyTOTPSecretRequest>,
            deserializer: some GRPCCore.MessageDeserializer<Primandproper_Platform_Signin_V1_VerifyTOTPSecretResponse>,
            options: GRPCCore.CallOptions,
            onResponse handleResponse: @Sendable @escaping (GRPCCore.ClientResponse<Primandproper_Platform_Signin_V1_VerifyTOTPSecretResponse>) async throws -> Result
        ) async throws -> Result where Result: Sendable

        /// Call the "UpdateEmailAddress" method.
        ///
        /// - Parameters:
        ///   - request: A request containing a single `Primandproper_Platform_Signin_V1_UpdateEmailAddressRequest` message.
        ///   - serializer: A serializer for `Primandproper_Platform_Signin_V1_UpdateEmailAddressRequest` messages.
        ///   - deserializer: A deserializer for `Primandproper_Platform_Signin_V1_UpdateEmailAddressResponse` messages.
        ///   - options: Options to apply to this RPC.
        ///   - handleResponse: A closure which handles the response and returns its result to
        ///       the caller. Returning from the closure will cancel the RPC if it hasn't
        ///       already finished.
        /// - Returns: The result of `handleResponse`.
        func updateEmailAddress<Result>(
            request: GRPCCore.ClientRequest<Primandproper_Platform_Signin_V1_UpdateEmailAddressRequest>,
            serializer: some GRPCCore.MessageSerializer<Primandproper_Platform_Signin_V1_UpdateEmailAddressRequest>,
            deserializer: some GRPCCore.MessageDeserializer<Primandproper_Platform_Signin_V1_UpdateEmailAddressResponse>,
            options: GRPCCore.CallOptions,
            onResponse handleResponse: @Sendable @escaping (GRPCCore.ClientResponse<Primandproper_Platform_Signin_V1_UpdateEmailAddressResponse>) async throws -> Result
        ) async throws -> Result where Result: Sendable

        /// Call the "UpdateUsername" method.
        ///
        /// - Parameters:
        ///   - request: A request containing a single `Primandproper_Platform_Signin_V1_UpdateUsernameRequest` message.
        ///   - serializer: A serializer for `Primandproper_Platform_Signin_V1_UpdateUsernameRequest` messages.
        ///   - deserializer: A deserializer for `Primandproper_Platform_Signin_V1_UpdateUsernameResponse` messages.
        ///   - options: Options to apply to this RPC.
        ///   - handleResponse: A closure which handles the response and returns its result to
        ///       the caller. Returning from the closure will cancel the RPC if it hasn't
        ///       already finished.
        /// - Returns: The result of `handleResponse`.
        func updateUsername<Result>(
            request: GRPCCore.ClientRequest<Primandproper_Platform_Signin_V1_UpdateUsernameRequest>,
            serializer: some GRPCCore.MessageSerializer<Primandproper_Platform_Signin_V1_UpdateUsernameRequest>,
            deserializer: some GRPCCore.MessageDeserializer<Primandproper_Platform_Signin_V1_UpdateUsernameResponse>,
            options: GRPCCore.CallOptions,
            onResponse handleResponse: @Sendable @escaping (GRPCCore.ClientResponse<Primandproper_Platform_Signin_V1_UpdateUsernameResponse>) async throws -> Result
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
    /// > Some of its RPCs are anonymous by definition and the rest require a caller.
    /// > What none of them requires is a permission: there is no grant that would make
    /// > "sign in" safer, and every authenticated one takes its subject from the
    /// > caller and has no field that could name anybody else. See
    /// > authentication/signin/grpc's Require for how that is declared to an
    /// > authorization policy, which is not the same thing as being left out of one.
    /// > What an operator does to somebody else's logins is
    /// > SignInAdministrationService, which is permissioned, and which is a service of
    /// > its own so that this statement stays true of this one.
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
        /// > Arriving, and the two ways a registration is finished. All three are
        /// > anonymous. Register is the sign-up door, and it is open by default: the
        /// > policy an open sign-up has in it -- who may register, which agreements
        /// > they must accept, what standing and roles they start with -- is the
        /// > deployment's registration policy, which the service runs on every
        /// > registration before anything is hashed, minted or written, and the roles
        /// > a registrant owns their account with are the deployment's, never the
        /// > request's. A caller who is signed in still reaches it, and an operator
        /// > provisioning users calls it that way. A deployment that does not want
        /// > sign-up closes the door by name, and is then answered with
        /// > UNIMPLEMENTED carrying REGISTRATION_CLOSED, so a client can tell a closed
        /// > door from a broken one. Rate limiting it is the consumer's, in front of
        /// > it, as it is for the sign-in doors. The other two carry their own
        /// > authority, which is the token that was mailed to the person they are
        /// > about.
        ///
        /// - Parameters:
        ///   - request: A request containing a single `Primandproper_Platform_Signin_V1_RegisterRequest` message.
        ///   - serializer: A serializer for `Primandproper_Platform_Signin_V1_RegisterRequest` messages.
        ///   - deserializer: A deserializer for `Primandproper_Platform_Signin_V1_RegisterResponse` messages.
        ///   - options: Options to apply to this RPC.
        ///   - handleResponse: A closure which handles the response and returns its result to
        ///       the caller. Returning from the closure will cancel the RPC if it hasn't
        ///       already finished.
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
        ///   - handleResponse: A closure which handles the response and returns its result to
        ///       the caller. Returning from the closure will cancel the RPC if it hasn't
        ///       already finished.
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
        ///   - handleResponse: A closure which handles the response and returns its result to
        ///       the caller. Returning from the closure will cancel the RPC if it hasn't
        ///       already finished.
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

        /// Call the "RequestVerificationEmail" method.
        ///
        /// > Source IDL Documentation:
        /// >
        /// > Asking for another verification link. The first requires a caller and
        /// > names nobody, for somebody signed in whose address changed; the second is
        /// > anonymous and names an address, for a registrant who cannot sign in until
        /// > they answer one, and is answered the same way whoever holds it.
        ///
        /// - Parameters:
        ///   - request: A request containing a single `Primandproper_Platform_Signin_V1_RequestVerificationEmailRequest` message.
        ///   - serializer: A serializer for `Primandproper_Platform_Signin_V1_RequestVerificationEmailRequest` messages.
        ///   - deserializer: A deserializer for `Primandproper_Platform_Signin_V1_RequestVerificationEmailResponse` messages.
        ///   - options: Options to apply to this RPC.
        ///   - handleResponse: A closure which handles the response and returns its result to
        ///       the caller. Returning from the closure will cancel the RPC if it hasn't
        ///       already finished.
        /// - Returns: The result of `handleResponse`.
        internal func requestVerificationEmail<Result>(
            request: GRPCCore.ClientRequest<Primandproper_Platform_Signin_V1_RequestVerificationEmailRequest>,
            serializer: some GRPCCore.MessageSerializer<Primandproper_Platform_Signin_V1_RequestVerificationEmailRequest>,
            deserializer: some GRPCCore.MessageDeserializer<Primandproper_Platform_Signin_V1_RequestVerificationEmailResponse>,
            options: GRPCCore.CallOptions = .defaults,
            onResponse handleResponse: @Sendable @escaping (GRPCCore.ClientResponse<Primandproper_Platform_Signin_V1_RequestVerificationEmailResponse>) async throws -> Result = { response in
                try response.message
            }
        ) async throws -> Result where Result: Sendable {
            try await self.client.unary(
                request: request,
                descriptor: Primandproper_Platform_Signin_V1_SignInService.Method.RequestVerificationEmail.descriptor,
                serializer: serializer,
                deserializer: deserializer,
                options: options,
                onResponse: handleResponse
            )
        }

        /// Call the "RequestVerificationEmailByAddress" method.
        ///
        /// - Parameters:
        ///   - request: A request containing a single `Primandproper_Platform_Signin_V1_RequestVerificationEmailByAddressRequest` message.
        ///   - serializer: A serializer for `Primandproper_Platform_Signin_V1_RequestVerificationEmailByAddressRequest` messages.
        ///   - deserializer: A deserializer for `Primandproper_Platform_Signin_V1_RequestVerificationEmailByAddressResponse` messages.
        ///   - options: Options to apply to this RPC.
        ///   - handleResponse: A closure which handles the response and returns its result to
        ///       the caller. Returning from the closure will cancel the RPC if it hasn't
        ///       already finished.
        /// - Returns: The result of `handleResponse`.
        internal func requestVerificationEmailByAddress<Result>(
            request: GRPCCore.ClientRequest<Primandproper_Platform_Signin_V1_RequestVerificationEmailByAddressRequest>,
            serializer: some GRPCCore.MessageSerializer<Primandproper_Platform_Signin_V1_RequestVerificationEmailByAddressRequest>,
            deserializer: some GRPCCore.MessageDeserializer<Primandproper_Platform_Signin_V1_RequestVerificationEmailByAddressResponse>,
            options: GRPCCore.CallOptions = .defaults,
            onResponse handleResponse: @Sendable @escaping (GRPCCore.ClientResponse<Primandproper_Platform_Signin_V1_RequestVerificationEmailByAddressResponse>) async throws -> Result = { response in
                try response.message
            }
        ) async throws -> Result where Result: Sendable {
            try await self.client.unary(
                request: request,
                descriptor: Primandproper_Platform_Signin_V1_SignInService.Method.RequestVerificationEmailByAddress.descriptor,
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
        /// > optional: it sends mail on request.
        ///
        /// - Parameters:
        ///   - request: A request containing a single `Primandproper_Platform_Signin_V1_RequestMagicLinkRequest` message.
        ///   - serializer: A serializer for `Primandproper_Platform_Signin_V1_RequestMagicLinkRequest` messages.
        ///   - deserializer: A deserializer for `Primandproper_Platform_Signin_V1_RequestMagicLinkResponse` messages.
        ///   - options: Options to apply to this RPC.
        ///   - handleResponse: A closure which handles the response and returns its result to
        ///       the caller. Returning from the closure will cancel the RPC if it hasn't
        ///       already finished.
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
        ///   - handleResponse: A closure which handles the response and returns its result to
        ///       the caller. Returning from the closure will cancel the RPC if it hasn't
        ///       already finished.
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

        /// Call the "RequestHandleReminder" method.
        ///
        /// > Source IDL Documentation:
        /// >
        /// > The door for somebody who has forgotten what they sign in as. It is
        /// > anonymous and answered the same way whoever holds the address, as
        /// > RequestMagicLink is, and its rate limit is the consumer's for the same
        /// > reason: it sends mail on request.
        ///
        /// - Parameters:
        ///   - request: A request containing a single `Primandproper_Platform_Signin_V1_RequestHandleReminderRequest` message.
        ///   - serializer: A serializer for `Primandproper_Platform_Signin_V1_RequestHandleReminderRequest` messages.
        ///   - deserializer: A deserializer for `Primandproper_Platform_Signin_V1_RequestHandleReminderResponse` messages.
        ///   - options: Options to apply to this RPC.
        ///   - handleResponse: A closure which handles the response and returns its result to
        ///       the caller. Returning from the closure will cancel the RPC if it hasn't
        ///       already finished.
        /// - Returns: The result of `handleResponse`.
        internal func requestHandleReminder<Result>(
            request: GRPCCore.ClientRequest<Primandproper_Platform_Signin_V1_RequestHandleReminderRequest>,
            serializer: some GRPCCore.MessageSerializer<Primandproper_Platform_Signin_V1_RequestHandleReminderRequest>,
            deserializer: some GRPCCore.MessageDeserializer<Primandproper_Platform_Signin_V1_RequestHandleReminderResponse>,
            options: GRPCCore.CallOptions = .defaults,
            onResponse handleResponse: @Sendable @escaping (GRPCCore.ClientResponse<Primandproper_Platform_Signin_V1_RequestHandleReminderResponse>) async throws -> Result = { response in
                try response.message
            }
        ) async throws -> Result where Result: Sendable {
            try await self.client.unary(
                request: request,
                descriptor: Primandproper_Platform_Signin_V1_SignInService.Method.RequestHandleReminder.descriptor,
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
        /// > The two doors, the one that keeps a sign-in alive without reopening
        /// > either of them, and the one that moves it to another of the person's
        /// > accounts without reopening them either.
        ///
        /// - Parameters:
        ///   - request: A request containing a single `Primandproper_Platform_Signin_V1_LoginForTokenRequest` message.
        ///   - serializer: A serializer for `Primandproper_Platform_Signin_V1_LoginForTokenRequest` messages.
        ///   - deserializer: A deserializer for `Primandproper_Platform_Signin_V1_LoginForTokenResponse` messages.
        ///   - options: Options to apply to this RPC.
        ///   - handleResponse: A closure which handles the response and returns its result to
        ///       the caller. Returning from the closure will cancel the RPC if it hasn't
        ///       already finished.
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
        ///   - handleResponse: A closure which handles the response and returns its result to
        ///       the caller. Returning from the closure will cancel the RPC if it hasn't
        ///       already finished.
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
        ///   - handleResponse: A closure which handles the response and returns its result to
        ///       the caller. Returning from the closure will cancel the RPC if it hasn't
        ///       already finished.
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

        /// Call the "SwitchAccount" method.
        ///
        /// - Parameters:
        ///   - request: A request containing a single `Primandproper_Platform_Signin_V1_SwitchAccountRequest` message.
        ///   - serializer: A serializer for `Primandproper_Platform_Signin_V1_SwitchAccountRequest` messages.
        ///   - deserializer: A deserializer for `Primandproper_Platform_Signin_V1_SwitchAccountResponse` messages.
        ///   - options: Options to apply to this RPC.
        ///   - handleResponse: A closure which handles the response and returns its result to
        ///       the caller. Returning from the closure will cancel the RPC if it hasn't
        ///       already finished.
        /// - Returns: The result of `handleResponse`.
        internal func switchAccount<Result>(
            request: GRPCCore.ClientRequest<Primandproper_Platform_Signin_V1_SwitchAccountRequest>,
            serializer: some GRPCCore.MessageSerializer<Primandproper_Platform_Signin_V1_SwitchAccountRequest>,
            deserializer: some GRPCCore.MessageDeserializer<Primandproper_Platform_Signin_V1_SwitchAccountResponse>,
            options: GRPCCore.CallOptions = .defaults,
            onResponse handleResponse: @Sendable @escaping (GRPCCore.ClientResponse<Primandproper_Platform_Signin_V1_SwitchAccountResponse>) async throws -> Result = { response in
                try response.message
            }
        ) async throws -> Result where Result: Sendable {
            try await self.client.unary(
                request: request,
                descriptor: Primandproper_Platform_Signin_V1_SignInService.Method.SwitchAccount.descriptor,
                serializer: serializer,
                deserializer: deserializer,
                options: options,
                onResponse: handleResponse
            )
        }

        /// Call the "SignOut" method.
        ///
        /// > Source IDL Documentation:
        /// >
        /// > The way out, in its two sizes. Ending this login carries the credential and
        /// > needs no caller, so an application whose access token expired while it was
        /// > closed can still sign out; ending every login needs a caller and names
        /// > nobody. Both are a client's to call and neither is an operator's tool --
        /// > revoking somebody else's sessions is SignInAdministrationService's.
        ///
        /// - Parameters:
        ///   - request: A request containing a single `Primandproper_Platform_Signin_V1_SignOutRequest` message.
        ///   - serializer: A serializer for `Primandproper_Platform_Signin_V1_SignOutRequest` messages.
        ///   - deserializer: A deserializer for `Primandproper_Platform_Signin_V1_SignOutResponse` messages.
        ///   - options: Options to apply to this RPC.
        ///   - handleResponse: A closure which handles the response and returns its result to
        ///       the caller. Returning from the closure will cancel the RPC if it hasn't
        ///       already finished.
        /// - Returns: The result of `handleResponse`.
        internal func signOut<Result>(
            request: GRPCCore.ClientRequest<Primandproper_Platform_Signin_V1_SignOutRequest>,
            serializer: some GRPCCore.MessageSerializer<Primandproper_Platform_Signin_V1_SignOutRequest>,
            deserializer: some GRPCCore.MessageDeserializer<Primandproper_Platform_Signin_V1_SignOutResponse>,
            options: GRPCCore.CallOptions = .defaults,
            onResponse handleResponse: @Sendable @escaping (GRPCCore.ClientResponse<Primandproper_Platform_Signin_V1_SignOutResponse>) async throws -> Result = { response in
                try response.message
            }
        ) async throws -> Result where Result: Sendable {
            try await self.client.unary(
                request: request,
                descriptor: Primandproper_Platform_Signin_V1_SignInService.Method.SignOut.descriptor,
                serializer: serializer,
                deserializer: deserializer,
                options: options,
                onResponse: handleResponse
            )
        }

        /// Call the "SignOutEverywhere" method.
        ///
        /// - Parameters:
        ///   - request: A request containing a single `Primandproper_Platform_Signin_V1_SignOutEverywhereRequest` message.
        ///   - serializer: A serializer for `Primandproper_Platform_Signin_V1_SignOutEverywhereRequest` messages.
        ///   - deserializer: A deserializer for `Primandproper_Platform_Signin_V1_SignOutEverywhereResponse` messages.
        ///   - options: Options to apply to this RPC.
        ///   - handleResponse: A closure which handles the response and returns its result to
        ///       the caller. Returning from the closure will cancel the RPC if it hasn't
        ///       already finished.
        /// - Returns: The result of `handleResponse`.
        internal func signOutEverywhere<Result>(
            request: GRPCCore.ClientRequest<Primandproper_Platform_Signin_V1_SignOutEverywhereRequest>,
            serializer: some GRPCCore.MessageSerializer<Primandproper_Platform_Signin_V1_SignOutEverywhereRequest>,
            deserializer: some GRPCCore.MessageDeserializer<Primandproper_Platform_Signin_V1_SignOutEverywhereResponse>,
            options: GRPCCore.CallOptions = .defaults,
            onResponse handleResponse: @Sendable @escaping (GRPCCore.ClientResponse<Primandproper_Platform_Signin_V1_SignOutEverywhereResponse>) async throws -> Result = { response in
                try response.message
            }
        ) async throws -> Result where Result: Sendable {
            try await self.client.unary(
                request: request,
                descriptor: Primandproper_Platform_Signin_V1_SignInService.Method.SignOutEverywhere.descriptor,
                serializer: serializer,
                deserializer: deserializer,
                options: options,
                onResponse: handleResponse
            )
        }

        /// Call the "ListSignIns" method.
        ///
        /// > Source IDL Documentation:
        /// >
        /// > The screen between those two sizes: the calling user's live logins, ending
        /// > one of them by name, and ending all of them but the one asking. All three
        /// > need a caller and name nobody else; an operator doing any of them for
        /// > somebody else calls SignInAdministrationService.
        ///
        /// - Parameters:
        ///   - request: A request containing a single `Primandproper_Platform_Signin_V1_ListSignInsRequest` message.
        ///   - serializer: A serializer for `Primandproper_Platform_Signin_V1_ListSignInsRequest` messages.
        ///   - deserializer: A deserializer for `Primandproper_Platform_Signin_V1_ListSignInsResponse` messages.
        ///   - options: Options to apply to this RPC.
        ///   - handleResponse: A closure which handles the response and returns its result to
        ///       the caller. Returning from the closure will cancel the RPC if it hasn't
        ///       already finished.
        /// - Returns: The result of `handleResponse`.
        internal func listSignIns<Result>(
            request: GRPCCore.ClientRequest<Primandproper_Platform_Signin_V1_ListSignInsRequest>,
            serializer: some GRPCCore.MessageSerializer<Primandproper_Platform_Signin_V1_ListSignInsRequest>,
            deserializer: some GRPCCore.MessageDeserializer<Primandproper_Platform_Signin_V1_ListSignInsResponse>,
            options: GRPCCore.CallOptions = .defaults,
            onResponse handleResponse: @Sendable @escaping (GRPCCore.ClientResponse<Primandproper_Platform_Signin_V1_ListSignInsResponse>) async throws -> Result = { response in
                try response.message
            }
        ) async throws -> Result where Result: Sendable {
            try await self.client.unary(
                request: request,
                descriptor: Primandproper_Platform_Signin_V1_SignInService.Method.ListSignIns.descriptor,
                serializer: serializer,
                deserializer: deserializer,
                options: options,
                onResponse: handleResponse
            )
        }

        /// Call the "EndSignIn" method.
        ///
        /// - Parameters:
        ///   - request: A request containing a single `Primandproper_Platform_Signin_V1_EndSignInRequest` message.
        ///   - serializer: A serializer for `Primandproper_Platform_Signin_V1_EndSignInRequest` messages.
        ///   - deserializer: A deserializer for `Primandproper_Platform_Signin_V1_EndSignInResponse` messages.
        ///   - options: Options to apply to this RPC.
        ///   - handleResponse: A closure which handles the response and returns its result to
        ///       the caller. Returning from the closure will cancel the RPC if it hasn't
        ///       already finished.
        /// - Returns: The result of `handleResponse`.
        internal func endSignIn<Result>(
            request: GRPCCore.ClientRequest<Primandproper_Platform_Signin_V1_EndSignInRequest>,
            serializer: some GRPCCore.MessageSerializer<Primandproper_Platform_Signin_V1_EndSignInRequest>,
            deserializer: some GRPCCore.MessageDeserializer<Primandproper_Platform_Signin_V1_EndSignInResponse>,
            options: GRPCCore.CallOptions = .defaults,
            onResponse handleResponse: @Sendable @escaping (GRPCCore.ClientResponse<Primandproper_Platform_Signin_V1_EndSignInResponse>) async throws -> Result = { response in
                try response.message
            }
        ) async throws -> Result where Result: Sendable {
            try await self.client.unary(
                request: request,
                descriptor: Primandproper_Platform_Signin_V1_SignInService.Method.EndSignIn.descriptor,
                serializer: serializer,
                deserializer: deserializer,
                options: options,
                onResponse: handleResponse
            )
        }

        /// Call the "EndOtherSignIns" method.
        ///
        /// - Parameters:
        ///   - request: A request containing a single `Primandproper_Platform_Signin_V1_EndOtherSignInsRequest` message.
        ///   - serializer: A serializer for `Primandproper_Platform_Signin_V1_EndOtherSignInsRequest` messages.
        ///   - deserializer: A deserializer for `Primandproper_Platform_Signin_V1_EndOtherSignInsResponse` messages.
        ///   - options: Options to apply to this RPC.
        ///   - handleResponse: A closure which handles the response and returns its result to
        ///       the caller. Returning from the closure will cancel the RPC if it hasn't
        ///       already finished.
        /// - Returns: The result of `handleResponse`.
        internal func endOtherSignIns<Result>(
            request: GRPCCore.ClientRequest<Primandproper_Platform_Signin_V1_EndOtherSignInsRequest>,
            serializer: some GRPCCore.MessageSerializer<Primandproper_Platform_Signin_V1_EndOtherSignInsRequest>,
            deserializer: some GRPCCore.MessageDeserializer<Primandproper_Platform_Signin_V1_EndOtherSignInsResponse>,
            options: GRPCCore.CallOptions = .defaults,
            onResponse handleResponse: @Sendable @escaping (GRPCCore.ClientResponse<Primandproper_Platform_Signin_V1_EndOtherSignInsResponse>) async throws -> Result = { response in
                try response.message
            }
        ) async throws -> Result where Result: Sendable {
            try await self.client.unary(
                request: request,
                descriptor: Primandproper_Platform_Signin_V1_SignInService.Method.EndOtherSignIns.descriptor,
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
        ///   - handleResponse: A closure which handles the response and returns its result to
        ///       the caller. Returning from the closure will cancel the RPC if it hasn't
        ///       already finished.
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
        ///   - handleResponse: A closure which handles the response and returns its result to
        ///       the caller. Returning from the closure will cancel the RPC if it hasn't
        ///       already finished.
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
        /// > The writes a signed-in person makes about their own credentials, and the
        /// > two handles that are credentials in all but name. identity's UpdateProfile
        /// > refuses both handles; these are where they change.
        ///
        /// - Parameters:
        ///   - request: A request containing a single `Primandproper_Platform_Signin_V1_UpdatePasswordRequest` message.
        ///   - serializer: A serializer for `Primandproper_Platform_Signin_V1_UpdatePasswordRequest` messages.
        ///   - deserializer: A deserializer for `Primandproper_Platform_Signin_V1_UpdatePasswordResponse` messages.
        ///   - options: Options to apply to this RPC.
        ///   - handleResponse: A closure which handles the response and returns its result to
        ///       the caller. Returning from the closure will cancel the RPC if it hasn't
        ///       already finished.
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
        ///   - handleResponse: A closure which handles the response and returns its result to
        ///       the caller. Returning from the closure will cancel the RPC if it hasn't
        ///       already finished.
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
        ///   - handleResponse: A closure which handles the response and returns its result to
        ///       the caller. Returning from the closure will cancel the RPC if it hasn't
        ///       already finished.
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

        /// Call the "UpdateEmailAddress" method.
        ///
        /// - Parameters:
        ///   - request: A request containing a single `Primandproper_Platform_Signin_V1_UpdateEmailAddressRequest` message.
        ///   - serializer: A serializer for `Primandproper_Platform_Signin_V1_UpdateEmailAddressRequest` messages.
        ///   - deserializer: A deserializer for `Primandproper_Platform_Signin_V1_UpdateEmailAddressResponse` messages.
        ///   - options: Options to apply to this RPC.
        ///   - handleResponse: A closure which handles the response and returns its result to
        ///       the caller. Returning from the closure will cancel the RPC if it hasn't
        ///       already finished.
        /// - Returns: The result of `handleResponse`.
        internal func updateEmailAddress<Result>(
            request: GRPCCore.ClientRequest<Primandproper_Platform_Signin_V1_UpdateEmailAddressRequest>,
            serializer: some GRPCCore.MessageSerializer<Primandproper_Platform_Signin_V1_UpdateEmailAddressRequest>,
            deserializer: some GRPCCore.MessageDeserializer<Primandproper_Platform_Signin_V1_UpdateEmailAddressResponse>,
            options: GRPCCore.CallOptions = .defaults,
            onResponse handleResponse: @Sendable @escaping (GRPCCore.ClientResponse<Primandproper_Platform_Signin_V1_UpdateEmailAddressResponse>) async throws -> Result = { response in
                try response.message
            }
        ) async throws -> Result where Result: Sendable {
            try await self.client.unary(
                request: request,
                descriptor: Primandproper_Platform_Signin_V1_SignInService.Method.UpdateEmailAddress.descriptor,
                serializer: serializer,
                deserializer: deserializer,
                options: options,
                onResponse: handleResponse
            )
        }

        /// Call the "UpdateUsername" method.
        ///
        /// - Parameters:
        ///   - request: A request containing a single `Primandproper_Platform_Signin_V1_UpdateUsernameRequest` message.
        ///   - serializer: A serializer for `Primandproper_Platform_Signin_V1_UpdateUsernameRequest` messages.
        ///   - deserializer: A deserializer for `Primandproper_Platform_Signin_V1_UpdateUsernameResponse` messages.
        ///   - options: Options to apply to this RPC.
        ///   - handleResponse: A closure which handles the response and returns its result to
        ///       the caller. Returning from the closure will cancel the RPC if it hasn't
        ///       already finished.
        /// - Returns: The result of `handleResponse`.
        internal func updateUsername<Result>(
            request: GRPCCore.ClientRequest<Primandproper_Platform_Signin_V1_UpdateUsernameRequest>,
            serializer: some GRPCCore.MessageSerializer<Primandproper_Platform_Signin_V1_UpdateUsernameRequest>,
            deserializer: some GRPCCore.MessageDeserializer<Primandproper_Platform_Signin_V1_UpdateUsernameResponse>,
            options: GRPCCore.CallOptions = .defaults,
            onResponse handleResponse: @Sendable @escaping (GRPCCore.ClientResponse<Primandproper_Platform_Signin_V1_UpdateUsernameResponse>) async throws -> Result = { response in
                try response.message
            }
        ) async throws -> Result where Result: Sendable {
            try await self.client.unary(
                request: request,
                descriptor: Primandproper_Platform_Signin_V1_SignInService.Method.UpdateUsername.descriptor,
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
    /// > Arriving, and the two ways a registration is finished. All three are
    /// > anonymous. Register is the sign-up door, and it is open by default: the
    /// > policy an open sign-up has in it -- who may register, which agreements
    /// > they must accept, what standing and roles they start with -- is the
    /// > deployment's registration policy, which the service runs on every
    /// > registration before anything is hashed, minted or written, and the roles
    /// > a registrant owns their account with are the deployment's, never the
    /// > request's. A caller who is signed in still reaches it, and an operator
    /// > provisioning users calls it that way. A deployment that does not want
    /// > sign-up closes the door by name, and is then answered with
    /// > UNIMPLEMENTED carrying REGISTRATION_CLOSED, so a client can tell a closed
    /// > door from a broken one. Rate limiting it is the consumer's, in front of
    /// > it, as it is for the sign-in doors. The other two carry their own
    /// > authority, which is the token that was mailed to the person they are
    /// > about.
    ///
    /// - Parameters:
    ///   - request: A request containing a single `Primandproper_Platform_Signin_V1_RegisterRequest` message.
    ///   - options: Options to apply to this RPC.
    ///   - handleResponse: A closure which handles the response and returns its result to
    ///       the caller. Returning from the closure will cancel the RPC if it hasn't
    ///       already finished.
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
    ///   - handleResponse: A closure which handles the response and returns its result to
    ///       the caller. Returning from the closure will cancel the RPC if it hasn't
    ///       already finished.
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
    ///   - handleResponse: A closure which handles the response and returns its result to
    ///       the caller. Returning from the closure will cancel the RPC if it hasn't
    ///       already finished.
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

    /// Call the "RequestVerificationEmail" method.
    ///
    /// > Source IDL Documentation:
    /// >
    /// > Asking for another verification link. The first requires a caller and
    /// > names nobody, for somebody signed in whose address changed; the second is
    /// > anonymous and names an address, for a registrant who cannot sign in until
    /// > they answer one, and is answered the same way whoever holds it.
    ///
    /// - Parameters:
    ///   - request: A request containing a single `Primandproper_Platform_Signin_V1_RequestVerificationEmailRequest` message.
    ///   - options: Options to apply to this RPC.
    ///   - handleResponse: A closure which handles the response and returns its result to
    ///       the caller. Returning from the closure will cancel the RPC if it hasn't
    ///       already finished.
    /// - Returns: The result of `handleResponse`.
    internal func requestVerificationEmail<Result>(
        request: GRPCCore.ClientRequest<Primandproper_Platform_Signin_V1_RequestVerificationEmailRequest>,
        options: GRPCCore.CallOptions = .defaults,
        onResponse handleResponse: @Sendable @escaping (GRPCCore.ClientResponse<Primandproper_Platform_Signin_V1_RequestVerificationEmailResponse>) async throws -> Result = { response in
            try response.message
        }
    ) async throws -> Result where Result: Sendable {
        try await self.requestVerificationEmail(
            request: request,
            serializer: GRPCProtobuf.ProtobufSerializer<Primandproper_Platform_Signin_V1_RequestVerificationEmailRequest>(),
            deserializer: GRPCProtobuf.ProtobufDeserializer<Primandproper_Platform_Signin_V1_RequestVerificationEmailResponse>(),
            options: options,
            onResponse: handleResponse
        )
    }

    /// Call the "RequestVerificationEmailByAddress" method.
    ///
    /// - Parameters:
    ///   - request: A request containing a single `Primandproper_Platform_Signin_V1_RequestVerificationEmailByAddressRequest` message.
    ///   - options: Options to apply to this RPC.
    ///   - handleResponse: A closure which handles the response and returns its result to
    ///       the caller. Returning from the closure will cancel the RPC if it hasn't
    ///       already finished.
    /// - Returns: The result of `handleResponse`.
    internal func requestVerificationEmailByAddress<Result>(
        request: GRPCCore.ClientRequest<Primandproper_Platform_Signin_V1_RequestVerificationEmailByAddressRequest>,
        options: GRPCCore.CallOptions = .defaults,
        onResponse handleResponse: @Sendable @escaping (GRPCCore.ClientResponse<Primandproper_Platform_Signin_V1_RequestVerificationEmailByAddressResponse>) async throws -> Result = { response in
            try response.message
        }
    ) async throws -> Result where Result: Sendable {
        try await self.requestVerificationEmailByAddress(
            request: request,
            serializer: GRPCProtobuf.ProtobufSerializer<Primandproper_Platform_Signin_V1_RequestVerificationEmailByAddressRequest>(),
            deserializer: GRPCProtobuf.ProtobufDeserializer<Primandproper_Platform_Signin_V1_RequestVerificationEmailByAddressResponse>(),
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
    /// > optional: it sends mail on request.
    ///
    /// - Parameters:
    ///   - request: A request containing a single `Primandproper_Platform_Signin_V1_RequestMagicLinkRequest` message.
    ///   - options: Options to apply to this RPC.
    ///   - handleResponse: A closure which handles the response and returns its result to
    ///       the caller. Returning from the closure will cancel the RPC if it hasn't
    ///       already finished.
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
    ///   - handleResponse: A closure which handles the response and returns its result to
    ///       the caller. Returning from the closure will cancel the RPC if it hasn't
    ///       already finished.
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

    /// Call the "RequestHandleReminder" method.
    ///
    /// > Source IDL Documentation:
    /// >
    /// > The door for somebody who has forgotten what they sign in as. It is
    /// > anonymous and answered the same way whoever holds the address, as
    /// > RequestMagicLink is, and its rate limit is the consumer's for the same
    /// > reason: it sends mail on request.
    ///
    /// - Parameters:
    ///   - request: A request containing a single `Primandproper_Platform_Signin_V1_RequestHandleReminderRequest` message.
    ///   - options: Options to apply to this RPC.
    ///   - handleResponse: A closure which handles the response and returns its result to
    ///       the caller. Returning from the closure will cancel the RPC if it hasn't
    ///       already finished.
    /// - Returns: The result of `handleResponse`.
    internal func requestHandleReminder<Result>(
        request: GRPCCore.ClientRequest<Primandproper_Platform_Signin_V1_RequestHandleReminderRequest>,
        options: GRPCCore.CallOptions = .defaults,
        onResponse handleResponse: @Sendable @escaping (GRPCCore.ClientResponse<Primandproper_Platform_Signin_V1_RequestHandleReminderResponse>) async throws -> Result = { response in
            try response.message
        }
    ) async throws -> Result where Result: Sendable {
        try await self.requestHandleReminder(
            request: request,
            serializer: GRPCProtobuf.ProtobufSerializer<Primandproper_Platform_Signin_V1_RequestHandleReminderRequest>(),
            deserializer: GRPCProtobuf.ProtobufDeserializer<Primandproper_Platform_Signin_V1_RequestHandleReminderResponse>(),
            options: options,
            onResponse: handleResponse
        )
    }

    /// Call the "LoginForToken" method.
    ///
    /// > Source IDL Documentation:
    /// >
    /// > The two doors, the one that keeps a sign-in alive without reopening
    /// > either of them, and the one that moves it to another of the person's
    /// > accounts without reopening them either.
    ///
    /// - Parameters:
    ///   - request: A request containing a single `Primandproper_Platform_Signin_V1_LoginForTokenRequest` message.
    ///   - options: Options to apply to this RPC.
    ///   - handleResponse: A closure which handles the response and returns its result to
    ///       the caller. Returning from the closure will cancel the RPC if it hasn't
    ///       already finished.
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
    ///   - handleResponse: A closure which handles the response and returns its result to
    ///       the caller. Returning from the closure will cancel the RPC if it hasn't
    ///       already finished.
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
    ///   - handleResponse: A closure which handles the response and returns its result to
    ///       the caller. Returning from the closure will cancel the RPC if it hasn't
    ///       already finished.
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

    /// Call the "SwitchAccount" method.
    ///
    /// - Parameters:
    ///   - request: A request containing a single `Primandproper_Platform_Signin_V1_SwitchAccountRequest` message.
    ///   - options: Options to apply to this RPC.
    ///   - handleResponse: A closure which handles the response and returns its result to
    ///       the caller. Returning from the closure will cancel the RPC if it hasn't
    ///       already finished.
    /// - Returns: The result of `handleResponse`.
    internal func switchAccount<Result>(
        request: GRPCCore.ClientRequest<Primandproper_Platform_Signin_V1_SwitchAccountRequest>,
        options: GRPCCore.CallOptions = .defaults,
        onResponse handleResponse: @Sendable @escaping (GRPCCore.ClientResponse<Primandproper_Platform_Signin_V1_SwitchAccountResponse>) async throws -> Result = { response in
            try response.message
        }
    ) async throws -> Result where Result: Sendable {
        try await self.switchAccount(
            request: request,
            serializer: GRPCProtobuf.ProtobufSerializer<Primandproper_Platform_Signin_V1_SwitchAccountRequest>(),
            deserializer: GRPCProtobuf.ProtobufDeserializer<Primandproper_Platform_Signin_V1_SwitchAccountResponse>(),
            options: options,
            onResponse: handleResponse
        )
    }

    /// Call the "SignOut" method.
    ///
    /// > Source IDL Documentation:
    /// >
    /// > The way out, in its two sizes. Ending this login carries the credential and
    /// > needs no caller, so an application whose access token expired while it was
    /// > closed can still sign out; ending every login needs a caller and names
    /// > nobody. Both are a client's to call and neither is an operator's tool --
    /// > revoking somebody else's sessions is SignInAdministrationService's.
    ///
    /// - Parameters:
    ///   - request: A request containing a single `Primandproper_Platform_Signin_V1_SignOutRequest` message.
    ///   - options: Options to apply to this RPC.
    ///   - handleResponse: A closure which handles the response and returns its result to
    ///       the caller. Returning from the closure will cancel the RPC if it hasn't
    ///       already finished.
    /// - Returns: The result of `handleResponse`.
    internal func signOut<Result>(
        request: GRPCCore.ClientRequest<Primandproper_Platform_Signin_V1_SignOutRequest>,
        options: GRPCCore.CallOptions = .defaults,
        onResponse handleResponse: @Sendable @escaping (GRPCCore.ClientResponse<Primandproper_Platform_Signin_V1_SignOutResponse>) async throws -> Result = { response in
            try response.message
        }
    ) async throws -> Result where Result: Sendable {
        try await self.signOut(
            request: request,
            serializer: GRPCProtobuf.ProtobufSerializer<Primandproper_Platform_Signin_V1_SignOutRequest>(),
            deserializer: GRPCProtobuf.ProtobufDeserializer<Primandproper_Platform_Signin_V1_SignOutResponse>(),
            options: options,
            onResponse: handleResponse
        )
    }

    /// Call the "SignOutEverywhere" method.
    ///
    /// - Parameters:
    ///   - request: A request containing a single `Primandproper_Platform_Signin_V1_SignOutEverywhereRequest` message.
    ///   - options: Options to apply to this RPC.
    ///   - handleResponse: A closure which handles the response and returns its result to
    ///       the caller. Returning from the closure will cancel the RPC if it hasn't
    ///       already finished.
    /// - Returns: The result of `handleResponse`.
    internal func signOutEverywhere<Result>(
        request: GRPCCore.ClientRequest<Primandproper_Platform_Signin_V1_SignOutEverywhereRequest>,
        options: GRPCCore.CallOptions = .defaults,
        onResponse handleResponse: @Sendable @escaping (GRPCCore.ClientResponse<Primandproper_Platform_Signin_V1_SignOutEverywhereResponse>) async throws -> Result = { response in
            try response.message
        }
    ) async throws -> Result where Result: Sendable {
        try await self.signOutEverywhere(
            request: request,
            serializer: GRPCProtobuf.ProtobufSerializer<Primandproper_Platform_Signin_V1_SignOutEverywhereRequest>(),
            deserializer: GRPCProtobuf.ProtobufDeserializer<Primandproper_Platform_Signin_V1_SignOutEverywhereResponse>(),
            options: options,
            onResponse: handleResponse
        )
    }

    /// Call the "ListSignIns" method.
    ///
    /// > Source IDL Documentation:
    /// >
    /// > The screen between those two sizes: the calling user's live logins, ending
    /// > one of them by name, and ending all of them but the one asking. All three
    /// > need a caller and name nobody else; an operator doing any of them for
    /// > somebody else calls SignInAdministrationService.
    ///
    /// - Parameters:
    ///   - request: A request containing a single `Primandproper_Platform_Signin_V1_ListSignInsRequest` message.
    ///   - options: Options to apply to this RPC.
    ///   - handleResponse: A closure which handles the response and returns its result to
    ///       the caller. Returning from the closure will cancel the RPC if it hasn't
    ///       already finished.
    /// - Returns: The result of `handleResponse`.
    internal func listSignIns<Result>(
        request: GRPCCore.ClientRequest<Primandproper_Platform_Signin_V1_ListSignInsRequest>,
        options: GRPCCore.CallOptions = .defaults,
        onResponse handleResponse: @Sendable @escaping (GRPCCore.ClientResponse<Primandproper_Platform_Signin_V1_ListSignInsResponse>) async throws -> Result = { response in
            try response.message
        }
    ) async throws -> Result where Result: Sendable {
        try await self.listSignIns(
            request: request,
            serializer: GRPCProtobuf.ProtobufSerializer<Primandproper_Platform_Signin_V1_ListSignInsRequest>(),
            deserializer: GRPCProtobuf.ProtobufDeserializer<Primandproper_Platform_Signin_V1_ListSignInsResponse>(),
            options: options,
            onResponse: handleResponse
        )
    }

    /// Call the "EndSignIn" method.
    ///
    /// - Parameters:
    ///   - request: A request containing a single `Primandproper_Platform_Signin_V1_EndSignInRequest` message.
    ///   - options: Options to apply to this RPC.
    ///   - handleResponse: A closure which handles the response and returns its result to
    ///       the caller. Returning from the closure will cancel the RPC if it hasn't
    ///       already finished.
    /// - Returns: The result of `handleResponse`.
    internal func endSignIn<Result>(
        request: GRPCCore.ClientRequest<Primandproper_Platform_Signin_V1_EndSignInRequest>,
        options: GRPCCore.CallOptions = .defaults,
        onResponse handleResponse: @Sendable @escaping (GRPCCore.ClientResponse<Primandproper_Platform_Signin_V1_EndSignInResponse>) async throws -> Result = { response in
            try response.message
        }
    ) async throws -> Result where Result: Sendable {
        try await self.endSignIn(
            request: request,
            serializer: GRPCProtobuf.ProtobufSerializer<Primandproper_Platform_Signin_V1_EndSignInRequest>(),
            deserializer: GRPCProtobuf.ProtobufDeserializer<Primandproper_Platform_Signin_V1_EndSignInResponse>(),
            options: options,
            onResponse: handleResponse
        )
    }

    /// Call the "EndOtherSignIns" method.
    ///
    /// - Parameters:
    ///   - request: A request containing a single `Primandproper_Platform_Signin_V1_EndOtherSignInsRequest` message.
    ///   - options: Options to apply to this RPC.
    ///   - handleResponse: A closure which handles the response and returns its result to
    ///       the caller. Returning from the closure will cancel the RPC if it hasn't
    ///       already finished.
    /// - Returns: The result of `handleResponse`.
    internal func endOtherSignIns<Result>(
        request: GRPCCore.ClientRequest<Primandproper_Platform_Signin_V1_EndOtherSignInsRequest>,
        options: GRPCCore.CallOptions = .defaults,
        onResponse handleResponse: @Sendable @escaping (GRPCCore.ClientResponse<Primandproper_Platform_Signin_V1_EndOtherSignInsResponse>) async throws -> Result = { response in
            try response.message
        }
    ) async throws -> Result where Result: Sendable {
        try await self.endOtherSignIns(
            request: request,
            serializer: GRPCProtobuf.ProtobufSerializer<Primandproper_Platform_Signin_V1_EndOtherSignInsRequest>(),
            deserializer: GRPCProtobuf.ProtobufDeserializer<Primandproper_Platform_Signin_V1_EndOtherSignInsResponse>(),
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
    ///   - handleResponse: A closure which handles the response and returns its result to
    ///       the caller. Returning from the closure will cancel the RPC if it hasn't
    ///       already finished.
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
    ///   - handleResponse: A closure which handles the response and returns its result to
    ///       the caller. Returning from the closure will cancel the RPC if it hasn't
    ///       already finished.
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
    /// > The writes a signed-in person makes about their own credentials, and the
    /// > two handles that are credentials in all but name. identity's UpdateProfile
    /// > refuses both handles; these are where they change.
    ///
    /// - Parameters:
    ///   - request: A request containing a single `Primandproper_Platform_Signin_V1_UpdatePasswordRequest` message.
    ///   - options: Options to apply to this RPC.
    ///   - handleResponse: A closure which handles the response and returns its result to
    ///       the caller. Returning from the closure will cancel the RPC if it hasn't
    ///       already finished.
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
    ///   - handleResponse: A closure which handles the response and returns its result to
    ///       the caller. Returning from the closure will cancel the RPC if it hasn't
    ///       already finished.
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
    ///   - handleResponse: A closure which handles the response and returns its result to
    ///       the caller. Returning from the closure will cancel the RPC if it hasn't
    ///       already finished.
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

    /// Call the "UpdateEmailAddress" method.
    ///
    /// - Parameters:
    ///   - request: A request containing a single `Primandproper_Platform_Signin_V1_UpdateEmailAddressRequest` message.
    ///   - options: Options to apply to this RPC.
    ///   - handleResponse: A closure which handles the response and returns its result to
    ///       the caller. Returning from the closure will cancel the RPC if it hasn't
    ///       already finished.
    /// - Returns: The result of `handleResponse`.
    internal func updateEmailAddress<Result>(
        request: GRPCCore.ClientRequest<Primandproper_Platform_Signin_V1_UpdateEmailAddressRequest>,
        options: GRPCCore.CallOptions = .defaults,
        onResponse handleResponse: @Sendable @escaping (GRPCCore.ClientResponse<Primandproper_Platform_Signin_V1_UpdateEmailAddressResponse>) async throws -> Result = { response in
            try response.message
        }
    ) async throws -> Result where Result: Sendable {
        try await self.updateEmailAddress(
            request: request,
            serializer: GRPCProtobuf.ProtobufSerializer<Primandproper_Platform_Signin_V1_UpdateEmailAddressRequest>(),
            deserializer: GRPCProtobuf.ProtobufDeserializer<Primandproper_Platform_Signin_V1_UpdateEmailAddressResponse>(),
            options: options,
            onResponse: handleResponse
        )
    }

    /// Call the "UpdateUsername" method.
    ///
    /// - Parameters:
    ///   - request: A request containing a single `Primandproper_Platform_Signin_V1_UpdateUsernameRequest` message.
    ///   - options: Options to apply to this RPC.
    ///   - handleResponse: A closure which handles the response and returns its result to
    ///       the caller. Returning from the closure will cancel the RPC if it hasn't
    ///       already finished.
    /// - Returns: The result of `handleResponse`.
    internal func updateUsername<Result>(
        request: GRPCCore.ClientRequest<Primandproper_Platform_Signin_V1_UpdateUsernameRequest>,
        options: GRPCCore.CallOptions = .defaults,
        onResponse handleResponse: @Sendable @escaping (GRPCCore.ClientResponse<Primandproper_Platform_Signin_V1_UpdateUsernameResponse>) async throws -> Result = { response in
            try response.message
        }
    ) async throws -> Result where Result: Sendable {
        try await self.updateUsername(
            request: request,
            serializer: GRPCProtobuf.ProtobufSerializer<Primandproper_Platform_Signin_V1_UpdateUsernameRequest>(),
            deserializer: GRPCProtobuf.ProtobufDeserializer<Primandproper_Platform_Signin_V1_UpdateUsernameResponse>(),
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
    /// > Arriving, and the two ways a registration is finished. All three are
    /// > anonymous. Register is the sign-up door, and it is open by default: the
    /// > policy an open sign-up has in it -- who may register, which agreements
    /// > they must accept, what standing and roles they start with -- is the
    /// > deployment's registration policy, which the service runs on every
    /// > registration before anything is hashed, minted or written, and the roles
    /// > a registrant owns their account with are the deployment's, never the
    /// > request's. A caller who is signed in still reaches it, and an operator
    /// > provisioning users calls it that way. A deployment that does not want
    /// > sign-up closes the door by name, and is then answered with
    /// > UNIMPLEMENTED carrying REGISTRATION_CLOSED, so a client can tell a closed
    /// > door from a broken one. Rate limiting it is the consumer's, in front of
    /// > it, as it is for the sign-in doors. The other two carry their own
    /// > authority, which is the token that was mailed to the person they are
    /// > about.
    ///
    /// - Parameters:
    ///   - message: request message to send.
    ///   - metadata: Additional metadata to send, defaults to empty.
    ///   - options: Options to apply to this RPC, defaults to `.defaults`.
    ///   - handleResponse: A closure which handles the response and returns its result to
    ///       the caller. Returning from the closure will cancel the RPC if it hasn't
    ///       already finished.
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
    ///   - handleResponse: A closure which handles the response and returns its result to
    ///       the caller. Returning from the closure will cancel the RPC if it hasn't
    ///       already finished.
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
    ///   - handleResponse: A closure which handles the response and returns its result to
    ///       the caller. Returning from the closure will cancel the RPC if it hasn't
    ///       already finished.
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

    /// Call the "RequestVerificationEmail" method.
    ///
    /// > Source IDL Documentation:
    /// >
    /// > Asking for another verification link. The first requires a caller and
    /// > names nobody, for somebody signed in whose address changed; the second is
    /// > anonymous and names an address, for a registrant who cannot sign in until
    /// > they answer one, and is answered the same way whoever holds it.
    ///
    /// - Parameters:
    ///   - message: request message to send.
    ///   - metadata: Additional metadata to send, defaults to empty.
    ///   - options: Options to apply to this RPC, defaults to `.defaults`.
    ///   - handleResponse: A closure which handles the response and returns its result to
    ///       the caller. Returning from the closure will cancel the RPC if it hasn't
    ///       already finished.
    /// - Returns: The result of `handleResponse`.
    internal func requestVerificationEmail<Result>(
        _ message: Primandproper_Platform_Signin_V1_RequestVerificationEmailRequest,
        metadata: GRPCCore.Metadata = [:],
        options: GRPCCore.CallOptions = .defaults,
        onResponse handleResponse: @Sendable @escaping (GRPCCore.ClientResponse<Primandproper_Platform_Signin_V1_RequestVerificationEmailResponse>) async throws -> Result = { response in
            try response.message
        }
    ) async throws -> Result where Result: Sendable {
        let request = GRPCCore.ClientRequest<Primandproper_Platform_Signin_V1_RequestVerificationEmailRequest>(
            message: message,
            metadata: metadata
        )
        return try await self.requestVerificationEmail(
            request: request,
            options: options,
            onResponse: handleResponse
        )
    }

    /// Call the "RequestVerificationEmailByAddress" method.
    ///
    /// - Parameters:
    ///   - message: request message to send.
    ///   - metadata: Additional metadata to send, defaults to empty.
    ///   - options: Options to apply to this RPC, defaults to `.defaults`.
    ///   - handleResponse: A closure which handles the response and returns its result to
    ///       the caller. Returning from the closure will cancel the RPC if it hasn't
    ///       already finished.
    /// - Returns: The result of `handleResponse`.
    internal func requestVerificationEmailByAddress<Result>(
        _ message: Primandproper_Platform_Signin_V1_RequestVerificationEmailByAddressRequest,
        metadata: GRPCCore.Metadata = [:],
        options: GRPCCore.CallOptions = .defaults,
        onResponse handleResponse: @Sendable @escaping (GRPCCore.ClientResponse<Primandproper_Platform_Signin_V1_RequestVerificationEmailByAddressResponse>) async throws -> Result = { response in
            try response.message
        }
    ) async throws -> Result where Result: Sendable {
        let request = GRPCCore.ClientRequest<Primandproper_Platform_Signin_V1_RequestVerificationEmailByAddressRequest>(
            message: message,
            metadata: metadata
        )
        return try await self.requestVerificationEmailByAddress(
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
    /// > optional: it sends mail on request.
    ///
    /// - Parameters:
    ///   - message: request message to send.
    ///   - metadata: Additional metadata to send, defaults to empty.
    ///   - options: Options to apply to this RPC, defaults to `.defaults`.
    ///   - handleResponse: A closure which handles the response and returns its result to
    ///       the caller. Returning from the closure will cancel the RPC if it hasn't
    ///       already finished.
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
    ///   - handleResponse: A closure which handles the response and returns its result to
    ///       the caller. Returning from the closure will cancel the RPC if it hasn't
    ///       already finished.
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

    /// Call the "RequestHandleReminder" method.
    ///
    /// > Source IDL Documentation:
    /// >
    /// > The door for somebody who has forgotten what they sign in as. It is
    /// > anonymous and answered the same way whoever holds the address, as
    /// > RequestMagicLink is, and its rate limit is the consumer's for the same
    /// > reason: it sends mail on request.
    ///
    /// - Parameters:
    ///   - message: request message to send.
    ///   - metadata: Additional metadata to send, defaults to empty.
    ///   - options: Options to apply to this RPC, defaults to `.defaults`.
    ///   - handleResponse: A closure which handles the response and returns its result to
    ///       the caller. Returning from the closure will cancel the RPC if it hasn't
    ///       already finished.
    /// - Returns: The result of `handleResponse`.
    internal func requestHandleReminder<Result>(
        _ message: Primandproper_Platform_Signin_V1_RequestHandleReminderRequest,
        metadata: GRPCCore.Metadata = [:],
        options: GRPCCore.CallOptions = .defaults,
        onResponse handleResponse: @Sendable @escaping (GRPCCore.ClientResponse<Primandproper_Platform_Signin_V1_RequestHandleReminderResponse>) async throws -> Result = { response in
            try response.message
        }
    ) async throws -> Result where Result: Sendable {
        let request = GRPCCore.ClientRequest<Primandproper_Platform_Signin_V1_RequestHandleReminderRequest>(
            message: message,
            metadata: metadata
        )
        return try await self.requestHandleReminder(
            request: request,
            options: options,
            onResponse: handleResponse
        )
    }

    /// Call the "LoginForToken" method.
    ///
    /// > Source IDL Documentation:
    /// >
    /// > The two doors, the one that keeps a sign-in alive without reopening
    /// > either of them, and the one that moves it to another of the person's
    /// > accounts without reopening them either.
    ///
    /// - Parameters:
    ///   - message: request message to send.
    ///   - metadata: Additional metadata to send, defaults to empty.
    ///   - options: Options to apply to this RPC, defaults to `.defaults`.
    ///   - handleResponse: A closure which handles the response and returns its result to
    ///       the caller. Returning from the closure will cancel the RPC if it hasn't
    ///       already finished.
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
    ///   - handleResponse: A closure which handles the response and returns its result to
    ///       the caller. Returning from the closure will cancel the RPC if it hasn't
    ///       already finished.
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
    ///   - handleResponse: A closure which handles the response and returns its result to
    ///       the caller. Returning from the closure will cancel the RPC if it hasn't
    ///       already finished.
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

    /// Call the "SwitchAccount" method.
    ///
    /// - Parameters:
    ///   - message: request message to send.
    ///   - metadata: Additional metadata to send, defaults to empty.
    ///   - options: Options to apply to this RPC, defaults to `.defaults`.
    ///   - handleResponse: A closure which handles the response and returns its result to
    ///       the caller. Returning from the closure will cancel the RPC if it hasn't
    ///       already finished.
    /// - Returns: The result of `handleResponse`.
    internal func switchAccount<Result>(
        _ message: Primandproper_Platform_Signin_V1_SwitchAccountRequest,
        metadata: GRPCCore.Metadata = [:],
        options: GRPCCore.CallOptions = .defaults,
        onResponse handleResponse: @Sendable @escaping (GRPCCore.ClientResponse<Primandproper_Platform_Signin_V1_SwitchAccountResponse>) async throws -> Result = { response in
            try response.message
        }
    ) async throws -> Result where Result: Sendable {
        let request = GRPCCore.ClientRequest<Primandproper_Platform_Signin_V1_SwitchAccountRequest>(
            message: message,
            metadata: metadata
        )
        return try await self.switchAccount(
            request: request,
            options: options,
            onResponse: handleResponse
        )
    }

    /// Call the "SignOut" method.
    ///
    /// > Source IDL Documentation:
    /// >
    /// > The way out, in its two sizes. Ending this login carries the credential and
    /// > needs no caller, so an application whose access token expired while it was
    /// > closed can still sign out; ending every login needs a caller and names
    /// > nobody. Both are a client's to call and neither is an operator's tool --
    /// > revoking somebody else's sessions is SignInAdministrationService's.
    ///
    /// - Parameters:
    ///   - message: request message to send.
    ///   - metadata: Additional metadata to send, defaults to empty.
    ///   - options: Options to apply to this RPC, defaults to `.defaults`.
    ///   - handleResponse: A closure which handles the response and returns its result to
    ///       the caller. Returning from the closure will cancel the RPC if it hasn't
    ///       already finished.
    /// - Returns: The result of `handleResponse`.
    internal func signOut<Result>(
        _ message: Primandproper_Platform_Signin_V1_SignOutRequest,
        metadata: GRPCCore.Metadata = [:],
        options: GRPCCore.CallOptions = .defaults,
        onResponse handleResponse: @Sendable @escaping (GRPCCore.ClientResponse<Primandproper_Platform_Signin_V1_SignOutResponse>) async throws -> Result = { response in
            try response.message
        }
    ) async throws -> Result where Result: Sendable {
        let request = GRPCCore.ClientRequest<Primandproper_Platform_Signin_V1_SignOutRequest>(
            message: message,
            metadata: metadata
        )
        return try await self.signOut(
            request: request,
            options: options,
            onResponse: handleResponse
        )
    }

    /// Call the "SignOutEverywhere" method.
    ///
    /// - Parameters:
    ///   - message: request message to send.
    ///   - metadata: Additional metadata to send, defaults to empty.
    ///   - options: Options to apply to this RPC, defaults to `.defaults`.
    ///   - handleResponse: A closure which handles the response and returns its result to
    ///       the caller. Returning from the closure will cancel the RPC if it hasn't
    ///       already finished.
    /// - Returns: The result of `handleResponse`.
    internal func signOutEverywhere<Result>(
        _ message: Primandproper_Platform_Signin_V1_SignOutEverywhereRequest,
        metadata: GRPCCore.Metadata = [:],
        options: GRPCCore.CallOptions = .defaults,
        onResponse handleResponse: @Sendable @escaping (GRPCCore.ClientResponse<Primandproper_Platform_Signin_V1_SignOutEverywhereResponse>) async throws -> Result = { response in
            try response.message
        }
    ) async throws -> Result where Result: Sendable {
        let request = GRPCCore.ClientRequest<Primandproper_Platform_Signin_V1_SignOutEverywhereRequest>(
            message: message,
            metadata: metadata
        )
        return try await self.signOutEverywhere(
            request: request,
            options: options,
            onResponse: handleResponse
        )
    }

    /// Call the "ListSignIns" method.
    ///
    /// > Source IDL Documentation:
    /// >
    /// > The screen between those two sizes: the calling user's live logins, ending
    /// > one of them by name, and ending all of them but the one asking. All three
    /// > need a caller and name nobody else; an operator doing any of them for
    /// > somebody else calls SignInAdministrationService.
    ///
    /// - Parameters:
    ///   - message: request message to send.
    ///   - metadata: Additional metadata to send, defaults to empty.
    ///   - options: Options to apply to this RPC, defaults to `.defaults`.
    ///   - handleResponse: A closure which handles the response and returns its result to
    ///       the caller. Returning from the closure will cancel the RPC if it hasn't
    ///       already finished.
    /// - Returns: The result of `handleResponse`.
    internal func listSignIns<Result>(
        _ message: Primandproper_Platform_Signin_V1_ListSignInsRequest,
        metadata: GRPCCore.Metadata = [:],
        options: GRPCCore.CallOptions = .defaults,
        onResponse handleResponse: @Sendable @escaping (GRPCCore.ClientResponse<Primandproper_Platform_Signin_V1_ListSignInsResponse>) async throws -> Result = { response in
            try response.message
        }
    ) async throws -> Result where Result: Sendable {
        let request = GRPCCore.ClientRequest<Primandproper_Platform_Signin_V1_ListSignInsRequest>(
            message: message,
            metadata: metadata
        )
        return try await self.listSignIns(
            request: request,
            options: options,
            onResponse: handleResponse
        )
    }

    /// Call the "EndSignIn" method.
    ///
    /// - Parameters:
    ///   - message: request message to send.
    ///   - metadata: Additional metadata to send, defaults to empty.
    ///   - options: Options to apply to this RPC, defaults to `.defaults`.
    ///   - handleResponse: A closure which handles the response and returns its result to
    ///       the caller. Returning from the closure will cancel the RPC if it hasn't
    ///       already finished.
    /// - Returns: The result of `handleResponse`.
    internal func endSignIn<Result>(
        _ message: Primandproper_Platform_Signin_V1_EndSignInRequest,
        metadata: GRPCCore.Metadata = [:],
        options: GRPCCore.CallOptions = .defaults,
        onResponse handleResponse: @Sendable @escaping (GRPCCore.ClientResponse<Primandproper_Platform_Signin_V1_EndSignInResponse>) async throws -> Result = { response in
            try response.message
        }
    ) async throws -> Result where Result: Sendable {
        let request = GRPCCore.ClientRequest<Primandproper_Platform_Signin_V1_EndSignInRequest>(
            message: message,
            metadata: metadata
        )
        return try await self.endSignIn(
            request: request,
            options: options,
            onResponse: handleResponse
        )
    }

    /// Call the "EndOtherSignIns" method.
    ///
    /// - Parameters:
    ///   - message: request message to send.
    ///   - metadata: Additional metadata to send, defaults to empty.
    ///   - options: Options to apply to this RPC, defaults to `.defaults`.
    ///   - handleResponse: A closure which handles the response and returns its result to
    ///       the caller. Returning from the closure will cancel the RPC if it hasn't
    ///       already finished.
    /// - Returns: The result of `handleResponse`.
    internal func endOtherSignIns<Result>(
        _ message: Primandproper_Platform_Signin_V1_EndOtherSignInsRequest,
        metadata: GRPCCore.Metadata = [:],
        options: GRPCCore.CallOptions = .defaults,
        onResponse handleResponse: @Sendable @escaping (GRPCCore.ClientResponse<Primandproper_Platform_Signin_V1_EndOtherSignInsResponse>) async throws -> Result = { response in
            try response.message
        }
    ) async throws -> Result where Result: Sendable {
        let request = GRPCCore.ClientRequest<Primandproper_Platform_Signin_V1_EndOtherSignInsRequest>(
            message: message,
            metadata: metadata
        )
        return try await self.endOtherSignIns(
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
    ///   - handleResponse: A closure which handles the response and returns its result to
    ///       the caller. Returning from the closure will cancel the RPC if it hasn't
    ///       already finished.
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
    ///   - handleResponse: A closure which handles the response and returns its result to
    ///       the caller. Returning from the closure will cancel the RPC if it hasn't
    ///       already finished.
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
    /// > The writes a signed-in person makes about their own credentials, and the
    /// > two handles that are credentials in all but name. identity's UpdateProfile
    /// > refuses both handles; these are where they change.
    ///
    /// - Parameters:
    ///   - message: request message to send.
    ///   - metadata: Additional metadata to send, defaults to empty.
    ///   - options: Options to apply to this RPC, defaults to `.defaults`.
    ///   - handleResponse: A closure which handles the response and returns its result to
    ///       the caller. Returning from the closure will cancel the RPC if it hasn't
    ///       already finished.
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
    ///   - handleResponse: A closure which handles the response and returns its result to
    ///       the caller. Returning from the closure will cancel the RPC if it hasn't
    ///       already finished.
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
    ///   - handleResponse: A closure which handles the response and returns its result to
    ///       the caller. Returning from the closure will cancel the RPC if it hasn't
    ///       already finished.
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

    /// Call the "UpdateEmailAddress" method.
    ///
    /// - Parameters:
    ///   - message: request message to send.
    ///   - metadata: Additional metadata to send, defaults to empty.
    ///   - options: Options to apply to this RPC, defaults to `.defaults`.
    ///   - handleResponse: A closure which handles the response and returns its result to
    ///       the caller. Returning from the closure will cancel the RPC if it hasn't
    ///       already finished.
    /// - Returns: The result of `handleResponse`.
    internal func updateEmailAddress<Result>(
        _ message: Primandproper_Platform_Signin_V1_UpdateEmailAddressRequest,
        metadata: GRPCCore.Metadata = [:],
        options: GRPCCore.CallOptions = .defaults,
        onResponse handleResponse: @Sendable @escaping (GRPCCore.ClientResponse<Primandproper_Platform_Signin_V1_UpdateEmailAddressResponse>) async throws -> Result = { response in
            try response.message
        }
    ) async throws -> Result where Result: Sendable {
        let request = GRPCCore.ClientRequest<Primandproper_Platform_Signin_V1_UpdateEmailAddressRequest>(
            message: message,
            metadata: metadata
        )
        return try await self.updateEmailAddress(
            request: request,
            options: options,
            onResponse: handleResponse
        )
    }

    /// Call the "UpdateUsername" method.
    ///
    /// - Parameters:
    ///   - message: request message to send.
    ///   - metadata: Additional metadata to send, defaults to empty.
    ///   - options: Options to apply to this RPC, defaults to `.defaults`.
    ///   - handleResponse: A closure which handles the response and returns its result to
    ///       the caller. Returning from the closure will cancel the RPC if it hasn't
    ///       already finished.
    /// - Returns: The result of `handleResponse`.
    internal func updateUsername<Result>(
        _ message: Primandproper_Platform_Signin_V1_UpdateUsernameRequest,
        metadata: GRPCCore.Metadata = [:],
        options: GRPCCore.CallOptions = .defaults,
        onResponse handleResponse: @Sendable @escaping (GRPCCore.ClientResponse<Primandproper_Platform_Signin_V1_UpdateUsernameResponse>) async throws -> Result = { response in
            try response.message
        }
    ) async throws -> Result where Result: Sendable {
        let request = GRPCCore.ClientRequest<Primandproper_Platform_Signin_V1_UpdateUsernameRequest>(
            message: message,
            metadata: metadata
        )
        return try await self.updateUsername(
            request: request,
            options: options,
            onResponse: handleResponse
        )
    }
}

// MARK: - primandproper.platform.signin.v1.SignInAdministrationService

/// Namespace containing generated types for the "primandproper.platform.signin.v1.SignInAdministrationService" service.
@available(macOS 15.0, iOS 18.0, watchOS 11.0, tvOS 18.0, visionOS 2.0, *)
internal enum Primandproper_Platform_Signin_V1_SignInAdministrationService: Sendable {
    /// Service descriptor for the "primandproper.platform.signin.v1.SignInAdministrationService" service.
    internal static let descriptor = GRPCCore.ServiceDescriptor(fullyQualifiedService: "primandproper.platform.signin.v1.SignInAdministrationService")
    /// Namespace for method metadata.
    internal enum Method: Sendable {
        /// Namespace for "ListSignInsForUser" metadata.
        internal enum ListSignInsForUser: Sendable {
            /// Request type for "ListSignInsForUser".
            internal typealias Input = Primandproper_Platform_Signin_V1_ListSignInsForUserRequest
            /// Response type for "ListSignInsForUser".
            internal typealias Output = Primandproper_Platform_Signin_V1_ListSignInsForUserResponse
            /// Descriptor for "ListSignInsForUser".
            internal static let descriptor = GRPCCore.MethodDescriptor(
                service: GRPCCore.ServiceDescriptor(fullyQualifiedService: "primandproper.platform.signin.v1.SignInAdministrationService"),
                method: "ListSignInsForUser",
                type: .unary
            )
        }
        /// Namespace for "EndSignInForUser" metadata.
        internal enum EndSignInForUser: Sendable {
            /// Request type for "EndSignInForUser".
            internal typealias Input = Primandproper_Platform_Signin_V1_EndSignInForUserRequest
            /// Response type for "EndSignInForUser".
            internal typealias Output = Primandproper_Platform_Signin_V1_EndSignInForUserResponse
            /// Descriptor for "EndSignInForUser".
            internal static let descriptor = GRPCCore.MethodDescriptor(
                service: GRPCCore.ServiceDescriptor(fullyQualifiedService: "primandproper.platform.signin.v1.SignInAdministrationService"),
                method: "EndSignInForUser",
                type: .unary
            )
        }
        /// Namespace for "EndAllSignInsForUser" metadata.
        internal enum EndAllSignInsForUser: Sendable {
            /// Request type for "EndAllSignInsForUser".
            internal typealias Input = Primandproper_Platform_Signin_V1_EndAllSignInsForUserRequest
            /// Response type for "EndAllSignInsForUser".
            internal typealias Output = Primandproper_Platform_Signin_V1_EndAllSignInsForUserResponse
            /// Descriptor for "EndAllSignInsForUser".
            internal static let descriptor = GRPCCore.MethodDescriptor(
                service: GRPCCore.ServiceDescriptor(fullyQualifiedService: "primandproper.platform.signin.v1.SignInAdministrationService"),
                method: "EndAllSignInsForUser",
                type: .unary
            )
        }
        /// Descriptors for all methods in the "primandproper.platform.signin.v1.SignInAdministrationService" service.
        internal static let descriptors: [GRPCCore.MethodDescriptor] = [
            ListSignInsForUser.descriptor,
            EndSignInForUser.descriptor,
            EndAllSignInsForUser.descriptor
        ]
    }
}

@available(macOS 15.0, iOS 18.0, watchOS 11.0, tvOS 18.0, visionOS 2.0, *)
extension GRPCCore.ServiceDescriptor {
    /// Service descriptor for the "primandproper.platform.signin.v1.SignInAdministrationService" service.
    internal static let primandproper_platform_signin_v1_SignInAdministrationService = GRPCCore.ServiceDescriptor(fullyQualifiedService: "primandproper.platform.signin.v1.SignInAdministrationService")
}

// MARK: primandproper.platform.signin.v1.SignInAdministrationService (client)

@available(macOS 15.0, iOS 18.0, watchOS 11.0, tvOS 18.0, visionOS 2.0, *)
extension Primandproper_Platform_Signin_V1_SignInAdministrationService {
    /// Generated client protocol for the "primandproper.platform.signin.v1.SignInAdministrationService" service.
    ///
    /// You don't need to implement this protocol directly, use the generated
    /// implementation, ``Client``.
    ///
    /// > Source IDL Documentation:
    /// >
    /// > SignInAdministrationService is what an operator does to somebody else's
    /// > logins: read them, end one, end all of them.
    /// > 
    /// > Every RPC requires a caller and names a user, and each is gated by a
    /// > permission authentication/signin/grpc declares -- signin.sign_ins.read_any
    /// > for the read, signin.sign_ins.end_any for the two ends -- which no role holds
    /// > by default. Who holds them is the deployment's policy; this schema codifies
    /// > nothing about who an operator is.
    /// > 
    /// > An end is reported to the sign-in service's revocation hook as an
    /// > operator's, with the caller as the actor, so an audit trail tells "an
    /// > operator signed me out" from "I signed out". Like every end, it stops the
    /// > login's access tokens being replaced rather than stopping the one already
    /// > issued, unless the deployment checks each token's login on every request.
    internal protocol ClientProtocol: Sendable {
        /// Call the "ListSignInsForUser" method.
        ///
        /// - Parameters:
        ///   - request: A request containing a single `Primandproper_Platform_Signin_V1_ListSignInsForUserRequest` message.
        ///   - serializer: A serializer for `Primandproper_Platform_Signin_V1_ListSignInsForUserRequest` messages.
        ///   - deserializer: A deserializer for `Primandproper_Platform_Signin_V1_ListSignInsForUserResponse` messages.
        ///   - options: Options to apply to this RPC.
        ///   - handleResponse: A closure which handles the response and returns its result to
        ///       the caller. Returning from the closure will cancel the RPC if it hasn't
        ///       already finished.
        /// - Returns: The result of `handleResponse`.
        func listSignInsForUser<Result>(
            request: GRPCCore.ClientRequest<Primandproper_Platform_Signin_V1_ListSignInsForUserRequest>,
            serializer: some GRPCCore.MessageSerializer<Primandproper_Platform_Signin_V1_ListSignInsForUserRequest>,
            deserializer: some GRPCCore.MessageDeserializer<Primandproper_Platform_Signin_V1_ListSignInsForUserResponse>,
            options: GRPCCore.CallOptions,
            onResponse handleResponse: @Sendable @escaping (GRPCCore.ClientResponse<Primandproper_Platform_Signin_V1_ListSignInsForUserResponse>) async throws -> Result
        ) async throws -> Result where Result: Sendable

        /// Call the "EndSignInForUser" method.
        ///
        /// - Parameters:
        ///   - request: A request containing a single `Primandproper_Platform_Signin_V1_EndSignInForUserRequest` message.
        ///   - serializer: A serializer for `Primandproper_Platform_Signin_V1_EndSignInForUserRequest` messages.
        ///   - deserializer: A deserializer for `Primandproper_Platform_Signin_V1_EndSignInForUserResponse` messages.
        ///   - options: Options to apply to this RPC.
        ///   - handleResponse: A closure which handles the response and returns its result to
        ///       the caller. Returning from the closure will cancel the RPC if it hasn't
        ///       already finished.
        /// - Returns: The result of `handleResponse`.
        func endSignInForUser<Result>(
            request: GRPCCore.ClientRequest<Primandproper_Platform_Signin_V1_EndSignInForUserRequest>,
            serializer: some GRPCCore.MessageSerializer<Primandproper_Platform_Signin_V1_EndSignInForUserRequest>,
            deserializer: some GRPCCore.MessageDeserializer<Primandproper_Platform_Signin_V1_EndSignInForUserResponse>,
            options: GRPCCore.CallOptions,
            onResponse handleResponse: @Sendable @escaping (GRPCCore.ClientResponse<Primandproper_Platform_Signin_V1_EndSignInForUserResponse>) async throws -> Result
        ) async throws -> Result where Result: Sendable

        /// Call the "EndAllSignInsForUser" method.
        ///
        /// - Parameters:
        ///   - request: A request containing a single `Primandproper_Platform_Signin_V1_EndAllSignInsForUserRequest` message.
        ///   - serializer: A serializer for `Primandproper_Platform_Signin_V1_EndAllSignInsForUserRequest` messages.
        ///   - deserializer: A deserializer for `Primandproper_Platform_Signin_V1_EndAllSignInsForUserResponse` messages.
        ///   - options: Options to apply to this RPC.
        ///   - handleResponse: A closure which handles the response and returns its result to
        ///       the caller. Returning from the closure will cancel the RPC if it hasn't
        ///       already finished.
        /// - Returns: The result of `handleResponse`.
        func endAllSignInsForUser<Result>(
            request: GRPCCore.ClientRequest<Primandproper_Platform_Signin_V1_EndAllSignInsForUserRequest>,
            serializer: some GRPCCore.MessageSerializer<Primandproper_Platform_Signin_V1_EndAllSignInsForUserRequest>,
            deserializer: some GRPCCore.MessageDeserializer<Primandproper_Platform_Signin_V1_EndAllSignInsForUserResponse>,
            options: GRPCCore.CallOptions,
            onResponse handleResponse: @Sendable @escaping (GRPCCore.ClientResponse<Primandproper_Platform_Signin_V1_EndAllSignInsForUserResponse>) async throws -> Result
        ) async throws -> Result where Result: Sendable
    }

    /// Generated client for the "primandproper.platform.signin.v1.SignInAdministrationService" service.
    ///
    /// The ``Client`` provides an implementation of ``ClientProtocol`` which wraps
    /// a `GRPCCore.GRPCCClient`. The underlying `GRPCClient` provides the long-lived
    /// means of communication with the remote peer.
    ///
    /// > Source IDL Documentation:
    /// >
    /// > SignInAdministrationService is what an operator does to somebody else's
    /// > logins: read them, end one, end all of them.
    /// > 
    /// > Every RPC requires a caller and names a user, and each is gated by a
    /// > permission authentication/signin/grpc declares -- signin.sign_ins.read_any
    /// > for the read, signin.sign_ins.end_any for the two ends -- which no role holds
    /// > by default. Who holds them is the deployment's policy; this schema codifies
    /// > nothing about who an operator is.
    /// > 
    /// > An end is reported to the sign-in service's revocation hook as an
    /// > operator's, with the caller as the actor, so an audit trail tells "an
    /// > operator signed me out" from "I signed out". Like every end, it stops the
    /// > login's access tokens being replaced rather than stopping the one already
    /// > issued, unless the deployment checks each token's login on every request.
    internal struct Client<Transport>: ClientProtocol where Transport: GRPCCore.ClientTransport {
        private let client: GRPCCore.GRPCClient<Transport>

        /// Creates a new client wrapping the provided `GRPCCore.GRPCClient`.
        ///
        /// - Parameters:
        ///   - client: A `GRPCCore.GRPCClient` providing a communication channel to the service.
        internal init(wrapping client: GRPCCore.GRPCClient<Transport>) {
            self.client = client
        }

        /// Call the "ListSignInsForUser" method.
        ///
        /// - Parameters:
        ///   - request: A request containing a single `Primandproper_Platform_Signin_V1_ListSignInsForUserRequest` message.
        ///   - serializer: A serializer for `Primandproper_Platform_Signin_V1_ListSignInsForUserRequest` messages.
        ///   - deserializer: A deserializer for `Primandproper_Platform_Signin_V1_ListSignInsForUserResponse` messages.
        ///   - options: Options to apply to this RPC.
        ///   - handleResponse: A closure which handles the response and returns its result to
        ///       the caller. Returning from the closure will cancel the RPC if it hasn't
        ///       already finished.
        /// - Returns: The result of `handleResponse`.
        internal func listSignInsForUser<Result>(
            request: GRPCCore.ClientRequest<Primandproper_Platform_Signin_V1_ListSignInsForUserRequest>,
            serializer: some GRPCCore.MessageSerializer<Primandproper_Platform_Signin_V1_ListSignInsForUserRequest>,
            deserializer: some GRPCCore.MessageDeserializer<Primandproper_Platform_Signin_V1_ListSignInsForUserResponse>,
            options: GRPCCore.CallOptions = .defaults,
            onResponse handleResponse: @Sendable @escaping (GRPCCore.ClientResponse<Primandproper_Platform_Signin_V1_ListSignInsForUserResponse>) async throws -> Result = { response in
                try response.message
            }
        ) async throws -> Result where Result: Sendable {
            try await self.client.unary(
                request: request,
                descriptor: Primandproper_Platform_Signin_V1_SignInAdministrationService.Method.ListSignInsForUser.descriptor,
                serializer: serializer,
                deserializer: deserializer,
                options: options,
                onResponse: handleResponse
            )
        }

        /// Call the "EndSignInForUser" method.
        ///
        /// - Parameters:
        ///   - request: A request containing a single `Primandproper_Platform_Signin_V1_EndSignInForUserRequest` message.
        ///   - serializer: A serializer for `Primandproper_Platform_Signin_V1_EndSignInForUserRequest` messages.
        ///   - deserializer: A deserializer for `Primandproper_Platform_Signin_V1_EndSignInForUserResponse` messages.
        ///   - options: Options to apply to this RPC.
        ///   - handleResponse: A closure which handles the response and returns its result to
        ///       the caller. Returning from the closure will cancel the RPC if it hasn't
        ///       already finished.
        /// - Returns: The result of `handleResponse`.
        internal func endSignInForUser<Result>(
            request: GRPCCore.ClientRequest<Primandproper_Platform_Signin_V1_EndSignInForUserRequest>,
            serializer: some GRPCCore.MessageSerializer<Primandproper_Platform_Signin_V1_EndSignInForUserRequest>,
            deserializer: some GRPCCore.MessageDeserializer<Primandproper_Platform_Signin_V1_EndSignInForUserResponse>,
            options: GRPCCore.CallOptions = .defaults,
            onResponse handleResponse: @Sendable @escaping (GRPCCore.ClientResponse<Primandproper_Platform_Signin_V1_EndSignInForUserResponse>) async throws -> Result = { response in
                try response.message
            }
        ) async throws -> Result where Result: Sendable {
            try await self.client.unary(
                request: request,
                descriptor: Primandproper_Platform_Signin_V1_SignInAdministrationService.Method.EndSignInForUser.descriptor,
                serializer: serializer,
                deserializer: deserializer,
                options: options,
                onResponse: handleResponse
            )
        }

        /// Call the "EndAllSignInsForUser" method.
        ///
        /// - Parameters:
        ///   - request: A request containing a single `Primandproper_Platform_Signin_V1_EndAllSignInsForUserRequest` message.
        ///   - serializer: A serializer for `Primandproper_Platform_Signin_V1_EndAllSignInsForUserRequest` messages.
        ///   - deserializer: A deserializer for `Primandproper_Platform_Signin_V1_EndAllSignInsForUserResponse` messages.
        ///   - options: Options to apply to this RPC.
        ///   - handleResponse: A closure which handles the response and returns its result to
        ///       the caller. Returning from the closure will cancel the RPC if it hasn't
        ///       already finished.
        /// - Returns: The result of `handleResponse`.
        internal func endAllSignInsForUser<Result>(
            request: GRPCCore.ClientRequest<Primandproper_Platform_Signin_V1_EndAllSignInsForUserRequest>,
            serializer: some GRPCCore.MessageSerializer<Primandproper_Platform_Signin_V1_EndAllSignInsForUserRequest>,
            deserializer: some GRPCCore.MessageDeserializer<Primandproper_Platform_Signin_V1_EndAllSignInsForUserResponse>,
            options: GRPCCore.CallOptions = .defaults,
            onResponse handleResponse: @Sendable @escaping (GRPCCore.ClientResponse<Primandproper_Platform_Signin_V1_EndAllSignInsForUserResponse>) async throws -> Result = { response in
                try response.message
            }
        ) async throws -> Result where Result: Sendable {
            try await self.client.unary(
                request: request,
                descriptor: Primandproper_Platform_Signin_V1_SignInAdministrationService.Method.EndAllSignInsForUser.descriptor,
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
extension Primandproper_Platform_Signin_V1_SignInAdministrationService.ClientProtocol {
    /// Call the "ListSignInsForUser" method.
    ///
    /// - Parameters:
    ///   - request: A request containing a single `Primandproper_Platform_Signin_V1_ListSignInsForUserRequest` message.
    ///   - options: Options to apply to this RPC.
    ///   - handleResponse: A closure which handles the response and returns its result to
    ///       the caller. Returning from the closure will cancel the RPC if it hasn't
    ///       already finished.
    /// - Returns: The result of `handleResponse`.
    internal func listSignInsForUser<Result>(
        request: GRPCCore.ClientRequest<Primandproper_Platform_Signin_V1_ListSignInsForUserRequest>,
        options: GRPCCore.CallOptions = .defaults,
        onResponse handleResponse: @Sendable @escaping (GRPCCore.ClientResponse<Primandproper_Platform_Signin_V1_ListSignInsForUserResponse>) async throws -> Result = { response in
            try response.message
        }
    ) async throws -> Result where Result: Sendable {
        try await self.listSignInsForUser(
            request: request,
            serializer: GRPCProtobuf.ProtobufSerializer<Primandproper_Platform_Signin_V1_ListSignInsForUserRequest>(),
            deserializer: GRPCProtobuf.ProtobufDeserializer<Primandproper_Platform_Signin_V1_ListSignInsForUserResponse>(),
            options: options,
            onResponse: handleResponse
        )
    }

    /// Call the "EndSignInForUser" method.
    ///
    /// - Parameters:
    ///   - request: A request containing a single `Primandproper_Platform_Signin_V1_EndSignInForUserRequest` message.
    ///   - options: Options to apply to this RPC.
    ///   - handleResponse: A closure which handles the response and returns its result to
    ///       the caller. Returning from the closure will cancel the RPC if it hasn't
    ///       already finished.
    /// - Returns: The result of `handleResponse`.
    internal func endSignInForUser<Result>(
        request: GRPCCore.ClientRequest<Primandproper_Platform_Signin_V1_EndSignInForUserRequest>,
        options: GRPCCore.CallOptions = .defaults,
        onResponse handleResponse: @Sendable @escaping (GRPCCore.ClientResponse<Primandproper_Platform_Signin_V1_EndSignInForUserResponse>) async throws -> Result = { response in
            try response.message
        }
    ) async throws -> Result where Result: Sendable {
        try await self.endSignInForUser(
            request: request,
            serializer: GRPCProtobuf.ProtobufSerializer<Primandproper_Platform_Signin_V1_EndSignInForUserRequest>(),
            deserializer: GRPCProtobuf.ProtobufDeserializer<Primandproper_Platform_Signin_V1_EndSignInForUserResponse>(),
            options: options,
            onResponse: handleResponse
        )
    }

    /// Call the "EndAllSignInsForUser" method.
    ///
    /// - Parameters:
    ///   - request: A request containing a single `Primandproper_Platform_Signin_V1_EndAllSignInsForUserRequest` message.
    ///   - options: Options to apply to this RPC.
    ///   - handleResponse: A closure which handles the response and returns its result to
    ///       the caller. Returning from the closure will cancel the RPC if it hasn't
    ///       already finished.
    /// - Returns: The result of `handleResponse`.
    internal func endAllSignInsForUser<Result>(
        request: GRPCCore.ClientRequest<Primandproper_Platform_Signin_V1_EndAllSignInsForUserRequest>,
        options: GRPCCore.CallOptions = .defaults,
        onResponse handleResponse: @Sendable @escaping (GRPCCore.ClientResponse<Primandproper_Platform_Signin_V1_EndAllSignInsForUserResponse>) async throws -> Result = { response in
            try response.message
        }
    ) async throws -> Result where Result: Sendable {
        try await self.endAllSignInsForUser(
            request: request,
            serializer: GRPCProtobuf.ProtobufSerializer<Primandproper_Platform_Signin_V1_EndAllSignInsForUserRequest>(),
            deserializer: GRPCProtobuf.ProtobufDeserializer<Primandproper_Platform_Signin_V1_EndAllSignInsForUserResponse>(),
            options: options,
            onResponse: handleResponse
        )
    }
}

// Helpers providing sugared APIs for 'ClientProtocol' methods.
@available(macOS 15.0, iOS 18.0, watchOS 11.0, tvOS 18.0, visionOS 2.0, *)
extension Primandproper_Platform_Signin_V1_SignInAdministrationService.ClientProtocol {
    /// Call the "ListSignInsForUser" method.
    ///
    /// - Parameters:
    ///   - message: request message to send.
    ///   - metadata: Additional metadata to send, defaults to empty.
    ///   - options: Options to apply to this RPC, defaults to `.defaults`.
    ///   - handleResponse: A closure which handles the response and returns its result to
    ///       the caller. Returning from the closure will cancel the RPC if it hasn't
    ///       already finished.
    /// - Returns: The result of `handleResponse`.
    internal func listSignInsForUser<Result>(
        _ message: Primandproper_Platform_Signin_V1_ListSignInsForUserRequest,
        metadata: GRPCCore.Metadata = [:],
        options: GRPCCore.CallOptions = .defaults,
        onResponse handleResponse: @Sendable @escaping (GRPCCore.ClientResponse<Primandproper_Platform_Signin_V1_ListSignInsForUserResponse>) async throws -> Result = { response in
            try response.message
        }
    ) async throws -> Result where Result: Sendable {
        let request = GRPCCore.ClientRequest<Primandproper_Platform_Signin_V1_ListSignInsForUserRequest>(
            message: message,
            metadata: metadata
        )
        return try await self.listSignInsForUser(
            request: request,
            options: options,
            onResponse: handleResponse
        )
    }

    /// Call the "EndSignInForUser" method.
    ///
    /// - Parameters:
    ///   - message: request message to send.
    ///   - metadata: Additional metadata to send, defaults to empty.
    ///   - options: Options to apply to this RPC, defaults to `.defaults`.
    ///   - handleResponse: A closure which handles the response and returns its result to
    ///       the caller. Returning from the closure will cancel the RPC if it hasn't
    ///       already finished.
    /// - Returns: The result of `handleResponse`.
    internal func endSignInForUser<Result>(
        _ message: Primandproper_Platform_Signin_V1_EndSignInForUserRequest,
        metadata: GRPCCore.Metadata = [:],
        options: GRPCCore.CallOptions = .defaults,
        onResponse handleResponse: @Sendable @escaping (GRPCCore.ClientResponse<Primandproper_Platform_Signin_V1_EndSignInForUserResponse>) async throws -> Result = { response in
            try response.message
        }
    ) async throws -> Result where Result: Sendable {
        let request = GRPCCore.ClientRequest<Primandproper_Platform_Signin_V1_EndSignInForUserRequest>(
            message: message,
            metadata: metadata
        )
        return try await self.endSignInForUser(
            request: request,
            options: options,
            onResponse: handleResponse
        )
    }

    /// Call the "EndAllSignInsForUser" method.
    ///
    /// - Parameters:
    ///   - message: request message to send.
    ///   - metadata: Additional metadata to send, defaults to empty.
    ///   - options: Options to apply to this RPC, defaults to `.defaults`.
    ///   - handleResponse: A closure which handles the response and returns its result to
    ///       the caller. Returning from the closure will cancel the RPC if it hasn't
    ///       already finished.
    /// - Returns: The result of `handleResponse`.
    internal func endAllSignInsForUser<Result>(
        _ message: Primandproper_Platform_Signin_V1_EndAllSignInsForUserRequest,
        metadata: GRPCCore.Metadata = [:],
        options: GRPCCore.CallOptions = .defaults,
        onResponse handleResponse: @Sendable @escaping (GRPCCore.ClientResponse<Primandproper_Platform_Signin_V1_EndAllSignInsForUserResponse>) async throws -> Result = { response in
            try response.message
        }
    ) async throws -> Result where Result: Sendable {
        let request = GRPCCore.ClientRequest<Primandproper_Platform_Signin_V1_EndAllSignInsForUserRequest>(
            message: message,
            metadata: metadata
        )
        return try await self.endAllSignInsForUser(
            request: request,
            options: options,
            onResponse: handleResponse
        )
    }
}