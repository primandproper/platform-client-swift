// Package primandproper.platform.oauth2clients.v1 is the wire schema for an
// administered registry of OAuth2 clients: the registrations an operator
// creates on purpose, listed, read and withdrawn.
//
// It is not RFC 7591 dynamic client registration. That is an anonymous POST to
// /authorize's sibling endpoint, it is served by
// github.com/primandproper/primitives-go/v2/authentication/oauth2server, and a
// deployment using this registry turns it off. What is here is the API a
// console and a CLI drive.
//
// This file is shipped inside the published Go module, and it is the file
// itself that is shipped -- not a copy for you to keep in sync. A consumer puts
// the module's proto directories on protoc's path and imports this file by its
// canonical name, exactly as identity.proto and filtering.proto already work:
//
//	PLATFORM_PROTO := $(shell go list -m -f '{{.Dir}}' github.com/primandproper/platform-go/v14)
//
//	protoc --proto_path proto/ \
//	    --proto_path $(PLATFORM_PROTO)/authentication/oauth2clients/proto \
//	    --proto_path $(PLATFORM_PROTO)/filtering/proto \
//	    --go_opt=Mprimandproper/platform/oauth2clients/v1/oauth2clients.proto=github.com/primandproper/platform-go/v14/authentication/oauth2clients/oauth2clientspb \
//	    $(CONSUMER_PROTO_FILES)   # the platform files deliberately absent from that list
//
// Field numbers are the compatibility promise, across every language a consumer
// generates into. Numbers are never reused and never repurposed: a field that
// goes away is reserved.
//
// # Why there are four RPCs
//
// Because create, get, list and archive are the operations a registry of
// clients is called for. Six further methods had shipped here -- an update,
// and a self-service mirror of all five operations -- and they answered no
// caller. They were removed before anything consumed this package.
//
// The self-service half is the one worth recording, because it was not merely
// unused. Its five methods were reachable behind no permission at all, on the
// theory that owning the row is the authorization, which made them the surface
// in this package with the most ways to be wrong and the fewest readers checking.
// Surface nobody asked for is not free, and permissionless surface nobody asked
// for is the expensive kind.
//
// # If a self-service half is ever wanted
//
// The Go API still models the arrangement -- a registration carries an owner,
// and oauth2clients.Store lists by one -- so what is missing is a transport, and
// there is a right and a wrong shape for it. The right one is mirrored methods:
// CreateOAuth2Client and a separate CreateOwnOAuth2Client, so the decision is on
// the method name.
//
// A consumer's interceptor gates an RPC by its full method name, and it runs
// before the request body is parsed -- see
// github.com/primandproper/primitives-go/v2/authorization/grpc. A single
// CreateOAuth2Client whose required permission depended on an "ownership" field
// would be one the enforcer could not gate: it would have to be declared public
// and gate itself, which is the arrangement that puts an authorization decision
// somewhere nobody auditing the permission map can see it. The other shape, one
// set of RPCs that silently narrows to the caller's own rows when they hold no
// grant, is the antipattern oauth2server names about scopes: silently narrowing
// hands back an answer that looks like the one that was asked for and is not.
//
// # What is not here, and why
//
// No scope field, anywhere, and the name is reserved so there cannot be one. A
// scope a client could name is a cross-tenant read hiding behind a request
// field; it comes off the principal the consumer's interceptor put on the
// context. See identity.proto, which says this at greater length.
//
// Reserving the name rather than only saying so is audit.proto's pattern:
// `reserved "scope";` is a schema protoc refuses to accept a scope field into,
// in this repository and in a consumer's fork of the file alike, whereas a
// comment is a request to the next author. It is reserved on every request
// message, on [OAuth2ClientCreationInput], which one of them is built from,
// and on [OAuth2Client] and [IssuedOAuth2Client], which the responses are built
// from.
//
// The reservation is of the singular name only, and this is the one file on the
// lane where that has to be said out loud: OAuth2Client.scopes and
// OAuth2ClientCreationInput.scopes are OAuth2 authorization scopes, which are
// what a client may ask for at /authorize and have nothing to do with a tenant.
// Two different words that happen to be spelled the same; protoc reserves
// "scope" and leaves "scopes" alone, which is the outcome wanted here.
//
// No belongs_to_user in any request, for the same reason one level in. An owner
// a client could name is a credential minted in somebody else's name. It is
// output-only: a response carries it so a console can show who owns a row.
//
// No client_secret on OAuth2Client. The plaintext exists on exactly one message
// -- [IssuedOAuth2Client], returned by the creation RPC -- because a field that
// is populated once and empty on every other read is the field that ends up in a
// log. It is not recoverable: what the row holds is a digest, and losing a
// secret means archiving the registration and minting another.
//
// No update of any kind. A registration's descriptive fields are revisable
// through the Go API and no consumer has asked to revise them over the wire; the
// owner, the client_id and the secret are not revisable at all, the first two
// because they are immutable facts about a row and the third because rotating it
// is a call that hands back a new credential rather than an UPDATE nobody sees.

// DO NOT EDIT.
// swift-format-ignore-file
// swiftlint:disable all
//
// Generated by the gRPC Swift generator plugin for the protocol buffer compiler.
// Source: primandproper/platform/oauth2clients/v1/oauth2clients.proto
//
// For information on using the generated types, please see the documentation:
//   https://github.com/grpc/grpc-swift

import GRPCCore
import GRPCProtobuf

// MARK: - primandproper.platform.oauth2clients.v1.OAuth2ClientsService

/// Namespace containing generated types for the "primandproper.platform.oauth2clients.v1.OAuth2ClientsService" service.
@available(macOS 15.0, iOS 18.0, watchOS 11.0, tvOS 18.0, visionOS 2.0, *)
public enum Primandproper_Platform_Oauth2clients_V1_OAuth2ClientsService: Sendable {
    /// Service descriptor for the "primandproper.platform.oauth2clients.v1.OAuth2ClientsService" service.
    public static let descriptor = GRPCCore.ServiceDescriptor(fullyQualifiedService: "primandproper.platform.oauth2clients.v1.OAuth2ClientsService")
    /// Namespace for method metadata.
    public enum Method: Sendable {
        /// Namespace for "CreateOAuth2Client" metadata.
        public enum CreateOAuth2Client: Sendable {
            /// Request type for "CreateOAuth2Client".
            public typealias Input = Primandproper_Platform_Oauth2clients_V1_CreateOAuth2ClientRequest
            /// Response type for "CreateOAuth2Client".
            public typealias Output = Primandproper_Platform_Oauth2clients_V1_CreateOAuth2ClientResponse
            /// Descriptor for "CreateOAuth2Client".
            public static let descriptor = GRPCCore.MethodDescriptor(
                service: GRPCCore.ServiceDescriptor(fullyQualifiedService: "primandproper.platform.oauth2clients.v1.OAuth2ClientsService"),
                method: "CreateOAuth2Client",
                type: .unary
            )
        }
        /// Namespace for "GetOAuth2Client" metadata.
        public enum GetOAuth2Client: Sendable {
            /// Request type for "GetOAuth2Client".
            public typealias Input = Primandproper_Platform_Oauth2clients_V1_GetOAuth2ClientRequest
            /// Response type for "GetOAuth2Client".
            public typealias Output = Primandproper_Platform_Oauth2clients_V1_GetOAuth2ClientResponse
            /// Descriptor for "GetOAuth2Client".
            public static let descriptor = GRPCCore.MethodDescriptor(
                service: GRPCCore.ServiceDescriptor(fullyQualifiedService: "primandproper.platform.oauth2clients.v1.OAuth2ClientsService"),
                method: "GetOAuth2Client",
                type: .unary
            )
        }
        /// Namespace for "ListOAuth2Clients" metadata.
        public enum ListOAuth2Clients: Sendable {
            /// Request type for "ListOAuth2Clients".
            public typealias Input = Primandproper_Platform_Oauth2clients_V1_ListOAuth2ClientsRequest
            /// Response type for "ListOAuth2Clients".
            public typealias Output = Primandproper_Platform_Oauth2clients_V1_ListOAuth2ClientsResponse
            /// Descriptor for "ListOAuth2Clients".
            public static let descriptor = GRPCCore.MethodDescriptor(
                service: GRPCCore.ServiceDescriptor(fullyQualifiedService: "primandproper.platform.oauth2clients.v1.OAuth2ClientsService"),
                method: "ListOAuth2Clients",
                type: .unary
            )
        }
        /// Namespace for "ArchiveOAuth2Client" metadata.
        public enum ArchiveOAuth2Client: Sendable {
            /// Request type for "ArchiveOAuth2Client".
            public typealias Input = Primandproper_Platform_Oauth2clients_V1_ArchiveOAuth2ClientRequest
            /// Response type for "ArchiveOAuth2Client".
            public typealias Output = Primandproper_Platform_Oauth2clients_V1_ArchiveOAuth2ClientResponse
            /// Descriptor for "ArchiveOAuth2Client".
            public static let descriptor = GRPCCore.MethodDescriptor(
                service: GRPCCore.ServiceDescriptor(fullyQualifiedService: "primandproper.platform.oauth2clients.v1.OAuth2ClientsService"),
                method: "ArchiveOAuth2Client",
                type: .unary
            )
        }
        /// Descriptors for all methods in the "primandproper.platform.oauth2clients.v1.OAuth2ClientsService" service.
        public static let descriptors: [GRPCCore.MethodDescriptor] = [
            CreateOAuth2Client.descriptor,
            GetOAuth2Client.descriptor,
            ListOAuth2Clients.descriptor,
            ArchiveOAuth2Client.descriptor
        ]
    }
}

@available(macOS 15.0, iOS 18.0, watchOS 11.0, tvOS 18.0, visionOS 2.0, *)
extension GRPCCore.ServiceDescriptor {
    /// Service descriptor for the "primandproper.platform.oauth2clients.v1.OAuth2ClientsService" service.
    public static let primandproper_platform_oauth2Clients_v1_OAuth2ClientsService = GRPCCore.ServiceDescriptor(fullyQualifiedService: "primandproper.platform.oauth2clients.v1.OAuth2ClientsService")
}

// MARK: primandproper.platform.oauth2clients.v1.OAuth2ClientsService (client)

@available(macOS 15.0, iOS 18.0, watchOS 11.0, tvOS 18.0, visionOS 2.0, *)
extension Primandproper_Platform_Oauth2clients_V1_OAuth2ClientsService {
    /// Generated client protocol for the "primandproper.platform.oauth2clients.v1.OAuth2ClientsService" service.
    ///
    /// You don't need to implement this protocol directly, use the generated
    /// implementation, ``Client``.
    ///
    /// > Source IDL Documentation:
    /// >
    /// > OAuth2ClientsService administers the registry.
    /// > 
    /// > Every method acts on any registration in the caller's registry and every one
    /// > of them requires a grant. The registry comes off the caller's principal; the
    /// > registration belongs to no person. See the file comment for why there are four
    /// > of them and what a self-service half would have to look like.
    public protocol ClientProtocol: Sendable {
        /// Call the "CreateOAuth2Client" method.
        ///
        /// - Parameters:
        ///   - request: A request containing a single `Primandproper_Platform_Oauth2clients_V1_CreateOAuth2ClientRequest` message.
        ///   - serializer: A serializer for `Primandproper_Platform_Oauth2clients_V1_CreateOAuth2ClientRequest` messages.
        ///   - deserializer: A deserializer for `Primandproper_Platform_Oauth2clients_V1_CreateOAuth2ClientResponse` messages.
        ///   - options: Options to apply to this RPC.
        ///   - handleResponse: A closure which handles the response and returns its result to
        ///       the caller. Returning from the closure will cancel the RPC if it hasn't
        ///       already finished.
        /// - Returns: The result of `handleResponse`.
        func createOAuth2Client<Result>(
            request: GRPCCore.ClientRequest<Primandproper_Platform_Oauth2clients_V1_CreateOAuth2ClientRequest>,
            serializer: some GRPCCore.MessageSerializer<Primandproper_Platform_Oauth2clients_V1_CreateOAuth2ClientRequest>,
            deserializer: some GRPCCore.MessageDeserializer<Primandproper_Platform_Oauth2clients_V1_CreateOAuth2ClientResponse>,
            options: GRPCCore.CallOptions,
            onResponse handleResponse: @Sendable @escaping (GRPCCore.ClientResponse<Primandproper_Platform_Oauth2clients_V1_CreateOAuth2ClientResponse>) async throws -> Result
        ) async throws -> Result where Result: Sendable

        /// Call the "GetOAuth2Client" method.
        ///
        /// - Parameters:
        ///   - request: A request containing a single `Primandproper_Platform_Oauth2clients_V1_GetOAuth2ClientRequest` message.
        ///   - serializer: A serializer for `Primandproper_Platform_Oauth2clients_V1_GetOAuth2ClientRequest` messages.
        ///   - deserializer: A deserializer for `Primandproper_Platform_Oauth2clients_V1_GetOAuth2ClientResponse` messages.
        ///   - options: Options to apply to this RPC.
        ///   - handleResponse: A closure which handles the response and returns its result to
        ///       the caller. Returning from the closure will cancel the RPC if it hasn't
        ///       already finished.
        /// - Returns: The result of `handleResponse`.
        func getOAuth2Client<Result>(
            request: GRPCCore.ClientRequest<Primandproper_Platform_Oauth2clients_V1_GetOAuth2ClientRequest>,
            serializer: some GRPCCore.MessageSerializer<Primandproper_Platform_Oauth2clients_V1_GetOAuth2ClientRequest>,
            deserializer: some GRPCCore.MessageDeserializer<Primandproper_Platform_Oauth2clients_V1_GetOAuth2ClientResponse>,
            options: GRPCCore.CallOptions,
            onResponse handleResponse: @Sendable @escaping (GRPCCore.ClientResponse<Primandproper_Platform_Oauth2clients_V1_GetOAuth2ClientResponse>) async throws -> Result
        ) async throws -> Result where Result: Sendable

        /// Call the "ListOAuth2Clients" method.
        ///
        /// - Parameters:
        ///   - request: A request containing a single `Primandproper_Platform_Oauth2clients_V1_ListOAuth2ClientsRequest` message.
        ///   - serializer: A serializer for `Primandproper_Platform_Oauth2clients_V1_ListOAuth2ClientsRequest` messages.
        ///   - deserializer: A deserializer for `Primandproper_Platform_Oauth2clients_V1_ListOAuth2ClientsResponse` messages.
        ///   - options: Options to apply to this RPC.
        ///   - handleResponse: A closure which handles the response and returns its result to
        ///       the caller. Returning from the closure will cancel the RPC if it hasn't
        ///       already finished.
        /// - Returns: The result of `handleResponse`.
        func listOAuth2Clients<Result>(
            request: GRPCCore.ClientRequest<Primandproper_Platform_Oauth2clients_V1_ListOAuth2ClientsRequest>,
            serializer: some GRPCCore.MessageSerializer<Primandproper_Platform_Oauth2clients_V1_ListOAuth2ClientsRequest>,
            deserializer: some GRPCCore.MessageDeserializer<Primandproper_Platform_Oauth2clients_V1_ListOAuth2ClientsResponse>,
            options: GRPCCore.CallOptions,
            onResponse handleResponse: @Sendable @escaping (GRPCCore.ClientResponse<Primandproper_Platform_Oauth2clients_V1_ListOAuth2ClientsResponse>) async throws -> Result
        ) async throws -> Result where Result: Sendable

        /// Call the "ArchiveOAuth2Client" method.
        ///
        /// - Parameters:
        ///   - request: A request containing a single `Primandproper_Platform_Oauth2clients_V1_ArchiveOAuth2ClientRequest` message.
        ///   - serializer: A serializer for `Primandproper_Platform_Oauth2clients_V1_ArchiveOAuth2ClientRequest` messages.
        ///   - deserializer: A deserializer for `Primandproper_Platform_Oauth2clients_V1_ArchiveOAuth2ClientResponse` messages.
        ///   - options: Options to apply to this RPC.
        ///   - handleResponse: A closure which handles the response and returns its result to
        ///       the caller. Returning from the closure will cancel the RPC if it hasn't
        ///       already finished.
        /// - Returns: The result of `handleResponse`.
        func archiveOAuth2Client<Result>(
            request: GRPCCore.ClientRequest<Primandproper_Platform_Oauth2clients_V1_ArchiveOAuth2ClientRequest>,
            serializer: some GRPCCore.MessageSerializer<Primandproper_Platform_Oauth2clients_V1_ArchiveOAuth2ClientRequest>,
            deserializer: some GRPCCore.MessageDeserializer<Primandproper_Platform_Oauth2clients_V1_ArchiveOAuth2ClientResponse>,
            options: GRPCCore.CallOptions,
            onResponse handleResponse: @Sendable @escaping (GRPCCore.ClientResponse<Primandproper_Platform_Oauth2clients_V1_ArchiveOAuth2ClientResponse>) async throws -> Result
        ) async throws -> Result where Result: Sendable
    }

    /// Generated client for the "primandproper.platform.oauth2clients.v1.OAuth2ClientsService" service.
    ///
    /// The ``Client`` provides an implementation of ``ClientProtocol`` which wraps
    /// a `GRPCCore.GRPCCClient`. The underlying `GRPCClient` provides the long-lived
    /// means of communication with the remote peer.
    ///
    /// > Source IDL Documentation:
    /// >
    /// > OAuth2ClientsService administers the registry.
    /// > 
    /// > Every method acts on any registration in the caller's registry and every one
    /// > of them requires a grant. The registry comes off the caller's principal; the
    /// > registration belongs to no person. See the file comment for why there are four
    /// > of them and what a self-service half would have to look like.
    public struct Client<Transport>: ClientProtocol where Transport: GRPCCore.ClientTransport {
        private let client: GRPCCore.GRPCClient<Transport>

        /// Creates a new client wrapping the provided `GRPCCore.GRPCClient`.
        ///
        /// - Parameters:
        ///   - client: A `GRPCCore.GRPCClient` providing a communication channel to the service.
        public init(wrapping client: GRPCCore.GRPCClient<Transport>) {
            self.client = client
        }

        /// Call the "CreateOAuth2Client" method.
        ///
        /// - Parameters:
        ///   - request: A request containing a single `Primandproper_Platform_Oauth2clients_V1_CreateOAuth2ClientRequest` message.
        ///   - serializer: A serializer for `Primandproper_Platform_Oauth2clients_V1_CreateOAuth2ClientRequest` messages.
        ///   - deserializer: A deserializer for `Primandproper_Platform_Oauth2clients_V1_CreateOAuth2ClientResponse` messages.
        ///   - options: Options to apply to this RPC.
        ///   - handleResponse: A closure which handles the response and returns its result to
        ///       the caller. Returning from the closure will cancel the RPC if it hasn't
        ///       already finished.
        /// - Returns: The result of `handleResponse`.
        public func createOAuth2Client<Result>(
            request: GRPCCore.ClientRequest<Primandproper_Platform_Oauth2clients_V1_CreateOAuth2ClientRequest>,
            serializer: some GRPCCore.MessageSerializer<Primandproper_Platform_Oauth2clients_V1_CreateOAuth2ClientRequest>,
            deserializer: some GRPCCore.MessageDeserializer<Primandproper_Platform_Oauth2clients_V1_CreateOAuth2ClientResponse>,
            options: GRPCCore.CallOptions = .defaults,
            onResponse handleResponse: @Sendable @escaping (GRPCCore.ClientResponse<Primandproper_Platform_Oauth2clients_V1_CreateOAuth2ClientResponse>) async throws -> Result = { response in
                try response.message
            }
        ) async throws -> Result where Result: Sendable {
            try await self.client.unary(
                request: request,
                descriptor: Primandproper_Platform_Oauth2clients_V1_OAuth2ClientsService.Method.CreateOAuth2Client.descriptor,
                serializer: serializer,
                deserializer: deserializer,
                options: options,
                onResponse: handleResponse
            )
        }

        /// Call the "GetOAuth2Client" method.
        ///
        /// - Parameters:
        ///   - request: A request containing a single `Primandproper_Platform_Oauth2clients_V1_GetOAuth2ClientRequest` message.
        ///   - serializer: A serializer for `Primandproper_Platform_Oauth2clients_V1_GetOAuth2ClientRequest` messages.
        ///   - deserializer: A deserializer for `Primandproper_Platform_Oauth2clients_V1_GetOAuth2ClientResponse` messages.
        ///   - options: Options to apply to this RPC.
        ///   - handleResponse: A closure which handles the response and returns its result to
        ///       the caller. Returning from the closure will cancel the RPC if it hasn't
        ///       already finished.
        /// - Returns: The result of `handleResponse`.
        public func getOAuth2Client<Result>(
            request: GRPCCore.ClientRequest<Primandproper_Platform_Oauth2clients_V1_GetOAuth2ClientRequest>,
            serializer: some GRPCCore.MessageSerializer<Primandproper_Platform_Oauth2clients_V1_GetOAuth2ClientRequest>,
            deserializer: some GRPCCore.MessageDeserializer<Primandproper_Platform_Oauth2clients_V1_GetOAuth2ClientResponse>,
            options: GRPCCore.CallOptions = .defaults,
            onResponse handleResponse: @Sendable @escaping (GRPCCore.ClientResponse<Primandproper_Platform_Oauth2clients_V1_GetOAuth2ClientResponse>) async throws -> Result = { response in
                try response.message
            }
        ) async throws -> Result where Result: Sendable {
            try await self.client.unary(
                request: request,
                descriptor: Primandproper_Platform_Oauth2clients_V1_OAuth2ClientsService.Method.GetOAuth2Client.descriptor,
                serializer: serializer,
                deserializer: deserializer,
                options: options,
                onResponse: handleResponse
            )
        }

        /// Call the "ListOAuth2Clients" method.
        ///
        /// - Parameters:
        ///   - request: A request containing a single `Primandproper_Platform_Oauth2clients_V1_ListOAuth2ClientsRequest` message.
        ///   - serializer: A serializer for `Primandproper_Platform_Oauth2clients_V1_ListOAuth2ClientsRequest` messages.
        ///   - deserializer: A deserializer for `Primandproper_Platform_Oauth2clients_V1_ListOAuth2ClientsResponse` messages.
        ///   - options: Options to apply to this RPC.
        ///   - handleResponse: A closure which handles the response and returns its result to
        ///       the caller. Returning from the closure will cancel the RPC if it hasn't
        ///       already finished.
        /// - Returns: The result of `handleResponse`.
        public func listOAuth2Clients<Result>(
            request: GRPCCore.ClientRequest<Primandproper_Platform_Oauth2clients_V1_ListOAuth2ClientsRequest>,
            serializer: some GRPCCore.MessageSerializer<Primandproper_Platform_Oauth2clients_V1_ListOAuth2ClientsRequest>,
            deserializer: some GRPCCore.MessageDeserializer<Primandproper_Platform_Oauth2clients_V1_ListOAuth2ClientsResponse>,
            options: GRPCCore.CallOptions = .defaults,
            onResponse handleResponse: @Sendable @escaping (GRPCCore.ClientResponse<Primandproper_Platform_Oauth2clients_V1_ListOAuth2ClientsResponse>) async throws -> Result = { response in
                try response.message
            }
        ) async throws -> Result where Result: Sendable {
            try await self.client.unary(
                request: request,
                descriptor: Primandproper_Platform_Oauth2clients_V1_OAuth2ClientsService.Method.ListOAuth2Clients.descriptor,
                serializer: serializer,
                deserializer: deserializer,
                options: options,
                onResponse: handleResponse
            )
        }

        /// Call the "ArchiveOAuth2Client" method.
        ///
        /// - Parameters:
        ///   - request: A request containing a single `Primandproper_Platform_Oauth2clients_V1_ArchiveOAuth2ClientRequest` message.
        ///   - serializer: A serializer for `Primandproper_Platform_Oauth2clients_V1_ArchiveOAuth2ClientRequest` messages.
        ///   - deserializer: A deserializer for `Primandproper_Platform_Oauth2clients_V1_ArchiveOAuth2ClientResponse` messages.
        ///   - options: Options to apply to this RPC.
        ///   - handleResponse: A closure which handles the response and returns its result to
        ///       the caller. Returning from the closure will cancel the RPC if it hasn't
        ///       already finished.
        /// - Returns: The result of `handleResponse`.
        public func archiveOAuth2Client<Result>(
            request: GRPCCore.ClientRequest<Primandproper_Platform_Oauth2clients_V1_ArchiveOAuth2ClientRequest>,
            serializer: some GRPCCore.MessageSerializer<Primandproper_Platform_Oauth2clients_V1_ArchiveOAuth2ClientRequest>,
            deserializer: some GRPCCore.MessageDeserializer<Primandproper_Platform_Oauth2clients_V1_ArchiveOAuth2ClientResponse>,
            options: GRPCCore.CallOptions = .defaults,
            onResponse handleResponse: @Sendable @escaping (GRPCCore.ClientResponse<Primandproper_Platform_Oauth2clients_V1_ArchiveOAuth2ClientResponse>) async throws -> Result = { response in
                try response.message
            }
        ) async throws -> Result where Result: Sendable {
            try await self.client.unary(
                request: request,
                descriptor: Primandproper_Platform_Oauth2clients_V1_OAuth2ClientsService.Method.ArchiveOAuth2Client.descriptor,
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
extension Primandproper_Platform_Oauth2clients_V1_OAuth2ClientsService.ClientProtocol {
    /// Call the "CreateOAuth2Client" method.
    ///
    /// - Parameters:
    ///   - request: A request containing a single `Primandproper_Platform_Oauth2clients_V1_CreateOAuth2ClientRequest` message.
    ///   - options: Options to apply to this RPC.
    ///   - handleResponse: A closure which handles the response and returns its result to
    ///       the caller. Returning from the closure will cancel the RPC if it hasn't
    ///       already finished.
    /// - Returns: The result of `handleResponse`.
    public func createOAuth2Client<Result>(
        request: GRPCCore.ClientRequest<Primandproper_Platform_Oauth2clients_V1_CreateOAuth2ClientRequest>,
        options: GRPCCore.CallOptions = .defaults,
        onResponse handleResponse: @Sendable @escaping (GRPCCore.ClientResponse<Primandproper_Platform_Oauth2clients_V1_CreateOAuth2ClientResponse>) async throws -> Result = { response in
            try response.message
        }
    ) async throws -> Result where Result: Sendable {
        try await self.createOAuth2Client(
            request: request,
            serializer: GRPCProtobuf.ProtobufSerializer<Primandproper_Platform_Oauth2clients_V1_CreateOAuth2ClientRequest>(),
            deserializer: GRPCProtobuf.ProtobufDeserializer<Primandproper_Platform_Oauth2clients_V1_CreateOAuth2ClientResponse>(),
            options: options,
            onResponse: handleResponse
        )
    }

    /// Call the "GetOAuth2Client" method.
    ///
    /// - Parameters:
    ///   - request: A request containing a single `Primandproper_Platform_Oauth2clients_V1_GetOAuth2ClientRequest` message.
    ///   - options: Options to apply to this RPC.
    ///   - handleResponse: A closure which handles the response and returns its result to
    ///       the caller. Returning from the closure will cancel the RPC if it hasn't
    ///       already finished.
    /// - Returns: The result of `handleResponse`.
    public func getOAuth2Client<Result>(
        request: GRPCCore.ClientRequest<Primandproper_Platform_Oauth2clients_V1_GetOAuth2ClientRequest>,
        options: GRPCCore.CallOptions = .defaults,
        onResponse handleResponse: @Sendable @escaping (GRPCCore.ClientResponse<Primandproper_Platform_Oauth2clients_V1_GetOAuth2ClientResponse>) async throws -> Result = { response in
            try response.message
        }
    ) async throws -> Result where Result: Sendable {
        try await self.getOAuth2Client(
            request: request,
            serializer: GRPCProtobuf.ProtobufSerializer<Primandproper_Platform_Oauth2clients_V1_GetOAuth2ClientRequest>(),
            deserializer: GRPCProtobuf.ProtobufDeserializer<Primandproper_Platform_Oauth2clients_V1_GetOAuth2ClientResponse>(),
            options: options,
            onResponse: handleResponse
        )
    }

    /// Call the "ListOAuth2Clients" method.
    ///
    /// - Parameters:
    ///   - request: A request containing a single `Primandproper_Platform_Oauth2clients_V1_ListOAuth2ClientsRequest` message.
    ///   - options: Options to apply to this RPC.
    ///   - handleResponse: A closure which handles the response and returns its result to
    ///       the caller. Returning from the closure will cancel the RPC if it hasn't
    ///       already finished.
    /// - Returns: The result of `handleResponse`.
    public func listOAuth2Clients<Result>(
        request: GRPCCore.ClientRequest<Primandproper_Platform_Oauth2clients_V1_ListOAuth2ClientsRequest>,
        options: GRPCCore.CallOptions = .defaults,
        onResponse handleResponse: @Sendable @escaping (GRPCCore.ClientResponse<Primandproper_Platform_Oauth2clients_V1_ListOAuth2ClientsResponse>) async throws -> Result = { response in
            try response.message
        }
    ) async throws -> Result where Result: Sendable {
        try await self.listOAuth2Clients(
            request: request,
            serializer: GRPCProtobuf.ProtobufSerializer<Primandproper_Platform_Oauth2clients_V1_ListOAuth2ClientsRequest>(),
            deserializer: GRPCProtobuf.ProtobufDeserializer<Primandproper_Platform_Oauth2clients_V1_ListOAuth2ClientsResponse>(),
            options: options,
            onResponse: handleResponse
        )
    }

    /// Call the "ArchiveOAuth2Client" method.
    ///
    /// - Parameters:
    ///   - request: A request containing a single `Primandproper_Platform_Oauth2clients_V1_ArchiveOAuth2ClientRequest` message.
    ///   - options: Options to apply to this RPC.
    ///   - handleResponse: A closure which handles the response and returns its result to
    ///       the caller. Returning from the closure will cancel the RPC if it hasn't
    ///       already finished.
    /// - Returns: The result of `handleResponse`.
    public func archiveOAuth2Client<Result>(
        request: GRPCCore.ClientRequest<Primandproper_Platform_Oauth2clients_V1_ArchiveOAuth2ClientRequest>,
        options: GRPCCore.CallOptions = .defaults,
        onResponse handleResponse: @Sendable @escaping (GRPCCore.ClientResponse<Primandproper_Platform_Oauth2clients_V1_ArchiveOAuth2ClientResponse>) async throws -> Result = { response in
            try response.message
        }
    ) async throws -> Result where Result: Sendable {
        try await self.archiveOAuth2Client(
            request: request,
            serializer: GRPCProtobuf.ProtobufSerializer<Primandproper_Platform_Oauth2clients_V1_ArchiveOAuth2ClientRequest>(),
            deserializer: GRPCProtobuf.ProtobufDeserializer<Primandproper_Platform_Oauth2clients_V1_ArchiveOAuth2ClientResponse>(),
            options: options,
            onResponse: handleResponse
        )
    }
}

// Helpers providing sugared APIs for 'ClientProtocol' methods.
@available(macOS 15.0, iOS 18.0, watchOS 11.0, tvOS 18.0, visionOS 2.0, *)
extension Primandproper_Platform_Oauth2clients_V1_OAuth2ClientsService.ClientProtocol {
    /// Call the "CreateOAuth2Client" method.
    ///
    /// - Parameters:
    ///   - message: request message to send.
    ///   - metadata: Additional metadata to send, defaults to empty.
    ///   - options: Options to apply to this RPC, defaults to `.defaults`.
    ///   - handleResponse: A closure which handles the response and returns its result to
    ///       the caller. Returning from the closure will cancel the RPC if it hasn't
    ///       already finished.
    /// - Returns: The result of `handleResponse`.
    public func createOAuth2Client<Result>(
        _ message: Primandproper_Platform_Oauth2clients_V1_CreateOAuth2ClientRequest,
        metadata: GRPCCore.Metadata = [:],
        options: GRPCCore.CallOptions = .defaults,
        onResponse handleResponse: @Sendable @escaping (GRPCCore.ClientResponse<Primandproper_Platform_Oauth2clients_V1_CreateOAuth2ClientResponse>) async throws -> Result = { response in
            try response.message
        }
    ) async throws -> Result where Result: Sendable {
        let request = GRPCCore.ClientRequest<Primandproper_Platform_Oauth2clients_V1_CreateOAuth2ClientRequest>(
            message: message,
            metadata: metadata
        )
        return try await self.createOAuth2Client(
            request: request,
            options: options,
            onResponse: handleResponse
        )
    }

    /// Call the "GetOAuth2Client" method.
    ///
    /// - Parameters:
    ///   - message: request message to send.
    ///   - metadata: Additional metadata to send, defaults to empty.
    ///   - options: Options to apply to this RPC, defaults to `.defaults`.
    ///   - handleResponse: A closure which handles the response and returns its result to
    ///       the caller. Returning from the closure will cancel the RPC if it hasn't
    ///       already finished.
    /// - Returns: The result of `handleResponse`.
    public func getOAuth2Client<Result>(
        _ message: Primandproper_Platform_Oauth2clients_V1_GetOAuth2ClientRequest,
        metadata: GRPCCore.Metadata = [:],
        options: GRPCCore.CallOptions = .defaults,
        onResponse handleResponse: @Sendable @escaping (GRPCCore.ClientResponse<Primandproper_Platform_Oauth2clients_V1_GetOAuth2ClientResponse>) async throws -> Result = { response in
            try response.message
        }
    ) async throws -> Result where Result: Sendable {
        let request = GRPCCore.ClientRequest<Primandproper_Platform_Oauth2clients_V1_GetOAuth2ClientRequest>(
            message: message,
            metadata: metadata
        )
        return try await self.getOAuth2Client(
            request: request,
            options: options,
            onResponse: handleResponse
        )
    }

    /// Call the "ListOAuth2Clients" method.
    ///
    /// - Parameters:
    ///   - message: request message to send.
    ///   - metadata: Additional metadata to send, defaults to empty.
    ///   - options: Options to apply to this RPC, defaults to `.defaults`.
    ///   - handleResponse: A closure which handles the response and returns its result to
    ///       the caller. Returning from the closure will cancel the RPC if it hasn't
    ///       already finished.
    /// - Returns: The result of `handleResponse`.
    public func listOAuth2Clients<Result>(
        _ message: Primandproper_Platform_Oauth2clients_V1_ListOAuth2ClientsRequest,
        metadata: GRPCCore.Metadata = [:],
        options: GRPCCore.CallOptions = .defaults,
        onResponse handleResponse: @Sendable @escaping (GRPCCore.ClientResponse<Primandproper_Platform_Oauth2clients_V1_ListOAuth2ClientsResponse>) async throws -> Result = { response in
            try response.message
        }
    ) async throws -> Result where Result: Sendable {
        let request = GRPCCore.ClientRequest<Primandproper_Platform_Oauth2clients_V1_ListOAuth2ClientsRequest>(
            message: message,
            metadata: metadata
        )
        return try await self.listOAuth2Clients(
            request: request,
            options: options,
            onResponse: handleResponse
        )
    }

    /// Call the "ArchiveOAuth2Client" method.
    ///
    /// - Parameters:
    ///   - message: request message to send.
    ///   - metadata: Additional metadata to send, defaults to empty.
    ///   - options: Options to apply to this RPC, defaults to `.defaults`.
    ///   - handleResponse: A closure which handles the response and returns its result to
    ///       the caller. Returning from the closure will cancel the RPC if it hasn't
    ///       already finished.
    /// - Returns: The result of `handleResponse`.
    public func archiveOAuth2Client<Result>(
        _ message: Primandproper_Platform_Oauth2clients_V1_ArchiveOAuth2ClientRequest,
        metadata: GRPCCore.Metadata = [:],
        options: GRPCCore.CallOptions = .defaults,
        onResponse handleResponse: @Sendable @escaping (GRPCCore.ClientResponse<Primandproper_Platform_Oauth2clients_V1_ArchiveOAuth2ClientResponse>) async throws -> Result = { response in
            try response.message
        }
    ) async throws -> Result where Result: Sendable {
        let request = GRPCCore.ClientRequest<Primandproper_Platform_Oauth2clients_V1_ArchiveOAuth2ClientRequest>(
            message: message,
            metadata: metadata
        )
        return try await self.archiveOAuth2Client(
            request: request,
            options: options,
            onResponse: handleResponse
        )
    }
}