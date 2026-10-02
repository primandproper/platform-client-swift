// Package primandproper.platform.webhooks.v1 is the wire schema for webhook
// endpoint management: the settings screen half of webhooks, where an
// operator registers a URL, picks the events it wants, rotates its signing
// keys, and reads back what was actually delivered.
//
// It is not the delivery pipeline. Some of the methods on webhooks.Store are
// here and the rest deliberately are not; the service comment at the bottom of
// this file names each absence and why it stays off the wire.
//
// This file is shipped inside the published Go module, and it is the file
// itself that is shipped -- not a copy for you to keep in sync. A consumer puts
// the module's proto directories on protoc's path and imports this file by its
// canonical name, exactly as identity.proto and filtering.proto already work:
//
//	PLATFORM_PROTO := $(shell go list -m -f '{{.Dir}}' github.com/primandproper/platform-go/v14)
//
//	protoc --proto_path proto/ \
//	    --proto_path $(PLATFORM_PROTO)/webhooks/proto \
//	    --proto_path $(PLATFORM_PROTO)/filtering/proto \
//	    --go_opt=Mprimandproper/platform/webhooks/v1/webhooks.proto=github.com/primandproper/platform-go/v14/webhooks/webhookspb \
//	    $(CONSUMER_PROTO_FILES)   # the platform files deliberately absent from that list
//
// Field numbers are the compatibility promise, across every language a consumer
// generates into. Numbers are never reused and never repurposed: a field that
// goes away is reserved.
//
// # event_type is a string, and will not become an enum
//
// Every event type in this schema is an opaque string. The set of them is the
// consumer's catalog -- webhooks.Catalog, supplied at construction because what
// an event means is an application opinion and this library has none -- and a
// generated enum would put that vocabulary on this module's release cadence,
// which is the first of the three objections the README's Transports section
// says the module split answered. Adding "order.refunded" would become a
// platform-go release.
//
// It is the same ruling issuereports.Kind and comments.TargetType are under,
// and comments' own documentation calls its catalog "the webhooks event
// catalog's idea applied to a second problem," so the two agree by
// construction. What a client gets instead of compile-time checking is a
// refusal: an event type outside the catalog is rejected at subscription with
// webhooks.ErrUnknownEventType rather than accepted into an endpoint that never
// fires.
//
// # What is not here, and why
//
// No scope field, anywhere, and the name is reserved so there cannot be one. A
// scope a client could name is a cross-tenant read hiding behind a request
// field -- on this surface, a read of where another tenant's events are being
// sent. It comes off the principal the consumer's interceptor put on the
// context, and every statement behind these RPCs binds it, so an endpoint in
// another tenant's scope reads as one that does not exist.
//
// Reserving the name rather than only saying so is audit.proto's pattern and is
// the half that holds: `reserved "scope";` is a schema protoc refuses to accept
// a scope field into, in this repository and in a consumer's fork of the file
// alike, whereas a comment is a request to the next author. It is reserved on
// every request message and on the three messages a response is built from --
// those carry no scope either, because every row a response returns belongs to
// the scope the connection resolved, so the field would be telling a client
// something it supplied.
//
// See identity.proto, which says the underlying rule at greater length.
//
// No signing key on any response. Key material appears on exactly two messages
// in this schema -- [SaveEndpointRequest] and [RotateSecretRequest] -- and on
// both it travels in one direction only. webhooks.Store.GetEndpoint reads an
// endpoint "secrets included" and [WebhookEndpoint] has nowhere to put them,
// which is the property rather than an oversight: a subscriber authenticates a
// delivery by its HMAC, so a key readable back over an administrative API is a
// key anybody who can read that API can forge deliveries with.
//
// [RotateSecretResponse] is empty for that reason and not because there is
// nothing to say. A rotation moves the outgoing key into the previous slot
// inside the statement, so no message and no process holds it; the incoming key
// is on the request because the client minted it and is about to hand it to the
// subscriber, who is the party that verifies with it.
//
// The consequence is that a save is a full re-registration, keys included,
// because there is no read that hands the current ones back. That is deliberate
// and is not a silent hazard: an endpoint saved without keys is refused rather
// than saved with none, so the failure is an error at the console and never a
// subscriber whose signature checks quietly stopped matching. Rotation is the
// one thing a caller would otherwise need that read for, and [RotateSecret] is
// why they do not: it names the incoming key alone, so rolling a subscriber's
// key never obliges anybody to have been able to read the outgoing one.
//
// No created_by in any request. It is output-only, filled from the principal
// the consumer's interceptor resolved, because provenance a caller could name
// is provenance that says whatever the caller wanted it to.
//
// No payload, no delivery, no dispatch and no replay. Those belong to the
// pipeline, and the service comment below says which of them were considered
// and refused.

// DO NOT EDIT.
// swift-format-ignore-file
// swiftlint:disable all
//
// Generated by the gRPC Swift generator plugin for the protocol buffer compiler.
// Source: primandproper/platform/webhooks/v1/webhooks.proto
//
// For information on using the generated types, please see the documentation:
//   https://github.com/grpc/grpc-swift

import GRPCCore
import GRPCProtobuf

// MARK: - primandproper.platform.webhooks.v1.WebhooksService

/// Namespace containing generated types for the "primandproper.platform.webhooks.v1.WebhooksService" service.
@available(macOS 15.0, iOS 18.0, watchOS 11.0, tvOS 18.0, visionOS 2.0, *)
internal enum Primandproper_Platform_Webhooks_V1_WebhooksService: Sendable {
    /// Service descriptor for the "primandproper.platform.webhooks.v1.WebhooksService" service.
    internal static let descriptor = GRPCCore.ServiceDescriptor(fullyQualifiedService: "primandproper.platform.webhooks.v1.WebhooksService")
    /// Namespace for method metadata.
    internal enum Method: Sendable {
        /// Namespace for "SaveEndpoint" metadata.
        internal enum SaveEndpoint: Sendable {
            /// Request type for "SaveEndpoint".
            internal typealias Input = Primandproper_Platform_Webhooks_V1_SaveEndpointRequest
            /// Response type for "SaveEndpoint".
            internal typealias Output = Primandproper_Platform_Webhooks_V1_SaveEndpointResponse
            /// Descriptor for "SaveEndpoint".
            internal static let descriptor = GRPCCore.MethodDescriptor(
                service: GRPCCore.ServiceDescriptor(fullyQualifiedService: "primandproper.platform.webhooks.v1.WebhooksService"),
                method: "SaveEndpoint",
                type: .unary
            )
        }
        /// Namespace for "GetEndpoint" metadata.
        internal enum GetEndpoint: Sendable {
            /// Request type for "GetEndpoint".
            internal typealias Input = Primandproper_Platform_Webhooks_V1_GetEndpointRequest
            /// Response type for "GetEndpoint".
            internal typealias Output = Primandproper_Platform_Webhooks_V1_GetEndpointResponse
            /// Descriptor for "GetEndpoint".
            internal static let descriptor = GRPCCore.MethodDescriptor(
                service: GRPCCore.ServiceDescriptor(fullyQualifiedService: "primandproper.platform.webhooks.v1.WebhooksService"),
                method: "GetEndpoint",
                type: .unary
            )
        }
        /// Namespace for "ListEndpoints" metadata.
        internal enum ListEndpoints: Sendable {
            /// Request type for "ListEndpoints".
            internal typealias Input = Primandproper_Platform_Webhooks_V1_ListEndpointsRequest
            /// Response type for "ListEndpoints".
            internal typealias Output = Primandproper_Platform_Webhooks_V1_ListEndpointsResponse
            /// Descriptor for "ListEndpoints".
            internal static let descriptor = GRPCCore.MethodDescriptor(
                service: GRPCCore.ServiceDescriptor(fullyQualifiedService: "primandproper.platform.webhooks.v1.WebhooksService"),
                method: "ListEndpoints",
                type: .unary
            )
        }
        /// Namespace for "ArchiveEndpoint" metadata.
        internal enum ArchiveEndpoint: Sendable {
            /// Request type for "ArchiveEndpoint".
            internal typealias Input = Primandproper_Platform_Webhooks_V1_ArchiveEndpointRequest
            /// Response type for "ArchiveEndpoint".
            internal typealias Output = Primandproper_Platform_Webhooks_V1_ArchiveEndpointResponse
            /// Descriptor for "ArchiveEndpoint".
            internal static let descriptor = GRPCCore.MethodDescriptor(
                service: GRPCCore.ServiceDescriptor(fullyQualifiedService: "primandproper.platform.webhooks.v1.WebhooksService"),
                method: "ArchiveEndpoint",
                type: .unary
            )
        }
        /// Namespace for "RotateSecret" metadata.
        internal enum RotateSecret: Sendable {
            /// Request type for "RotateSecret".
            internal typealias Input = Primandproper_Platform_Webhooks_V1_RotateSecretRequest
            /// Response type for "RotateSecret".
            internal typealias Output = Primandproper_Platform_Webhooks_V1_RotateSecretResponse
            /// Descriptor for "RotateSecret".
            internal static let descriptor = GRPCCore.MethodDescriptor(
                service: GRPCCore.ServiceDescriptor(fullyQualifiedService: "primandproper.platform.webhooks.v1.WebhooksService"),
                method: "RotateSecret",
                type: .unary
            )
        }
        /// Namespace for "AddSubscription" metadata.
        internal enum AddSubscription: Sendable {
            /// Request type for "AddSubscription".
            internal typealias Input = Primandproper_Platform_Webhooks_V1_AddSubscriptionRequest
            /// Response type for "AddSubscription".
            internal typealias Output = Primandproper_Platform_Webhooks_V1_AddSubscriptionResponse
            /// Descriptor for "AddSubscription".
            internal static let descriptor = GRPCCore.MethodDescriptor(
                service: GRPCCore.ServiceDescriptor(fullyQualifiedService: "primandproper.platform.webhooks.v1.WebhooksService"),
                method: "AddSubscription",
                type: .unary
            )
        }
        /// Namespace for "GetSubscription" metadata.
        internal enum GetSubscription: Sendable {
            /// Request type for "GetSubscription".
            internal typealias Input = Primandproper_Platform_Webhooks_V1_GetSubscriptionRequest
            /// Response type for "GetSubscription".
            internal typealias Output = Primandproper_Platform_Webhooks_V1_GetSubscriptionResponse
            /// Descriptor for "GetSubscription".
            internal static let descriptor = GRPCCore.MethodDescriptor(
                service: GRPCCore.ServiceDescriptor(fullyQualifiedService: "primandproper.platform.webhooks.v1.WebhooksService"),
                method: "GetSubscription",
                type: .unary
            )
        }
        /// Namespace for "ListSubscriptions" metadata.
        internal enum ListSubscriptions: Sendable {
            /// Request type for "ListSubscriptions".
            internal typealias Input = Primandproper_Platform_Webhooks_V1_ListSubscriptionsRequest
            /// Response type for "ListSubscriptions".
            internal typealias Output = Primandproper_Platform_Webhooks_V1_ListSubscriptionsResponse
            /// Descriptor for "ListSubscriptions".
            internal static let descriptor = GRPCCore.MethodDescriptor(
                service: GRPCCore.ServiceDescriptor(fullyQualifiedService: "primandproper.platform.webhooks.v1.WebhooksService"),
                method: "ListSubscriptions",
                type: .unary
            )
        }
        /// Namespace for "ArchiveSubscription" metadata.
        internal enum ArchiveSubscription: Sendable {
            /// Request type for "ArchiveSubscription".
            internal typealias Input = Primandproper_Platform_Webhooks_V1_ArchiveSubscriptionRequest
            /// Response type for "ArchiveSubscription".
            internal typealias Output = Primandproper_Platform_Webhooks_V1_ArchiveSubscriptionResponse
            /// Descriptor for "ArchiveSubscription".
            internal static let descriptor = GRPCCore.MethodDescriptor(
                service: GRPCCore.ServiceDescriptor(fullyQualifiedService: "primandproper.platform.webhooks.v1.WebhooksService"),
                method: "ArchiveSubscription",
                type: .unary
            )
        }
        /// Namespace for "ListAttempts" metadata.
        internal enum ListAttempts: Sendable {
            /// Request type for "ListAttempts".
            internal typealias Input = Primandproper_Platform_Webhooks_V1_ListAttemptsRequest
            /// Response type for "ListAttempts".
            internal typealias Output = Primandproper_Platform_Webhooks_V1_ListAttemptsResponse
            /// Descriptor for "ListAttempts".
            internal static let descriptor = GRPCCore.MethodDescriptor(
                service: GRPCCore.ServiceDescriptor(fullyQualifiedService: "primandproper.platform.webhooks.v1.WebhooksService"),
                method: "ListAttempts",
                type: .unary
            )
        }
        /// Namespace for "ListEventTypes" metadata.
        internal enum ListEventTypes: Sendable {
            /// Request type for "ListEventTypes".
            internal typealias Input = Primandproper_Platform_Webhooks_V1_ListEventTypesRequest
            /// Response type for "ListEventTypes".
            internal typealias Output = Primandproper_Platform_Webhooks_V1_ListEventTypesResponse
            /// Descriptor for "ListEventTypes".
            internal static let descriptor = GRPCCore.MethodDescriptor(
                service: GRPCCore.ServiceDescriptor(fullyQualifiedService: "primandproper.platform.webhooks.v1.WebhooksService"),
                method: "ListEventTypes",
                type: .unary
            )
        }
        /// Descriptors for all methods in the "primandproper.platform.webhooks.v1.WebhooksService" service.
        internal static let descriptors: [GRPCCore.MethodDescriptor] = [
            SaveEndpoint.descriptor,
            GetEndpoint.descriptor,
            ListEndpoints.descriptor,
            ArchiveEndpoint.descriptor,
            RotateSecret.descriptor,
            AddSubscription.descriptor,
            GetSubscription.descriptor,
            ListSubscriptions.descriptor,
            ArchiveSubscription.descriptor,
            ListAttempts.descriptor,
            ListEventTypes.descriptor
        ]
    }
}

@available(macOS 15.0, iOS 18.0, watchOS 11.0, tvOS 18.0, visionOS 2.0, *)
extension GRPCCore.ServiceDescriptor {
    /// Service descriptor for the "primandproper.platform.webhooks.v1.WebhooksService" service.
    internal static let primandproper_platform_webhooks_v1_WebhooksService = GRPCCore.ServiceDescriptor(fullyQualifiedService: "primandproper.platform.webhooks.v1.WebhooksService")
}

// MARK: primandproper.platform.webhooks.v1.WebhooksService (client)

@available(macOS 15.0, iOS 18.0, watchOS 11.0, tvOS 18.0, visionOS 2.0, *)
extension Primandproper_Platform_Webhooks_V1_WebhooksService {
    /// Generated client protocol for the "primandproper.platform.webhooks.v1.WebhooksService" service.
    ///
    /// You don't need to implement this protocol directly, use the generated
    /// implementation, ``Client``.
    ///
    /// > Source IDL Documentation:
    /// >
    /// > WebhooksService is endpoint management and delivery history: the half of
    /// > webhooks that is a resource rather than a protocol, and the only half a
    /// > person ever touches.
    /// > 
    /// > Every RPC here is behind a grant and acts only within the tenant the caller's
    /// > principal names. The methods of webhooks.Store that are not here are absent
    /// > on purpose, in three groups.
    /// > 
    /// > Seven are the delivery machinery, which webhooks.Store already documents
    /// > under "The delivery machinery takes neither": Claim, MarkDelivered,
    /// > RecordFailure, RecordAttempt, Requeue, Backlog and Reap take no executor at
    /// > all and run on the handle the store was built with. They are a worker
    /// > draining a queue on a timer, servicing itself; the queue protocol's
    /// > correctness is that a claim commits before the request goes out, and a caller
    /// > supplying a transaction -- which is what an RPC is -- would be choosing when
    /// > that commit happens.
    /// > 
    /// > EndpointsForEvent is the second group, and it is the internal fan-out: the
    /// > dispatcher asking itself who is subscribed on the way to its own work. Its
    /// > own documentation calls it "the query whose missing filter delivers one
    /// > account's event to every other account's subscribers," which is a sentence
    /// > about a query nobody outside the component should be issuing.
    /// > 
    /// > Enqueue is the third and is the sharpest of them, because it is the one that
    /// > looks like it belongs here. It is consumer-facing: an application calls it to
    /// > fan an event out. But it "writes a delivery and one dispatch per endpoint, in
    /// > the caller's transaction, so both commit with whatever else that transaction
    /// > did" -- and that is the whole reason it exists. An RPC moves the write out of
    /// > the caller's transaction, so you get a delivery for a row that rolled back,
    /// > or a committed row nobody was ever told about. It is the same fact
    /// > audit.Recorder states about an audit entry: a record that can commit while
    /// > the change it describes rolls back is not a record of what happened, and no
    /// > amount of retrying fixes it after the fact.
    /// > 
    /// > A consumer who wants an event dispatched from another process sends that
    /// > process's own RPC -- the one whose handler owns the transaction the write
    /// > belongs in -- and calls webhooks.Dispatcher.Dispatch inside it.
    internal protocol ClientProtocol: Sendable {
        /// Call the "SaveEndpoint" method.
        ///
        /// - Parameters:
        ///   - request: A request containing a single `Primandproper_Platform_Webhooks_V1_SaveEndpointRequest` message.
        ///   - serializer: A serializer for `Primandproper_Platform_Webhooks_V1_SaveEndpointRequest` messages.
        ///   - deserializer: A deserializer for `Primandproper_Platform_Webhooks_V1_SaveEndpointResponse` messages.
        ///   - options: Options to apply to this RPC.
        ///   - handleResponse: A closure which handles the response and returns its result to
        ///       the caller. Returning from the closure will cancel the RPC if it hasn't
        ///       already finished.
        /// - Returns: The result of `handleResponse`.
        func saveEndpoint<Result>(
            request: GRPCCore.ClientRequest<Primandproper_Platform_Webhooks_V1_SaveEndpointRequest>,
            serializer: some GRPCCore.MessageSerializer<Primandproper_Platform_Webhooks_V1_SaveEndpointRequest>,
            deserializer: some GRPCCore.MessageDeserializer<Primandproper_Platform_Webhooks_V1_SaveEndpointResponse>,
            options: GRPCCore.CallOptions,
            onResponse handleResponse: @Sendable @escaping (GRPCCore.ClientResponse<Primandproper_Platform_Webhooks_V1_SaveEndpointResponse>) async throws -> Result
        ) async throws -> Result where Result: Sendable

        /// Call the "GetEndpoint" method.
        ///
        /// - Parameters:
        ///   - request: A request containing a single `Primandproper_Platform_Webhooks_V1_GetEndpointRequest` message.
        ///   - serializer: A serializer for `Primandproper_Platform_Webhooks_V1_GetEndpointRequest` messages.
        ///   - deserializer: A deserializer for `Primandproper_Platform_Webhooks_V1_GetEndpointResponse` messages.
        ///   - options: Options to apply to this RPC.
        ///   - handleResponse: A closure which handles the response and returns its result to
        ///       the caller. Returning from the closure will cancel the RPC if it hasn't
        ///       already finished.
        /// - Returns: The result of `handleResponse`.
        func getEndpoint<Result>(
            request: GRPCCore.ClientRequest<Primandproper_Platform_Webhooks_V1_GetEndpointRequest>,
            serializer: some GRPCCore.MessageSerializer<Primandproper_Platform_Webhooks_V1_GetEndpointRequest>,
            deserializer: some GRPCCore.MessageDeserializer<Primandproper_Platform_Webhooks_V1_GetEndpointResponse>,
            options: GRPCCore.CallOptions,
            onResponse handleResponse: @Sendable @escaping (GRPCCore.ClientResponse<Primandproper_Platform_Webhooks_V1_GetEndpointResponse>) async throws -> Result
        ) async throws -> Result where Result: Sendable

        /// Call the "ListEndpoints" method.
        ///
        /// - Parameters:
        ///   - request: A request containing a single `Primandproper_Platform_Webhooks_V1_ListEndpointsRequest` message.
        ///   - serializer: A serializer for `Primandproper_Platform_Webhooks_V1_ListEndpointsRequest` messages.
        ///   - deserializer: A deserializer for `Primandproper_Platform_Webhooks_V1_ListEndpointsResponse` messages.
        ///   - options: Options to apply to this RPC.
        ///   - handleResponse: A closure which handles the response and returns its result to
        ///       the caller. Returning from the closure will cancel the RPC if it hasn't
        ///       already finished.
        /// - Returns: The result of `handleResponse`.
        func listEndpoints<Result>(
            request: GRPCCore.ClientRequest<Primandproper_Platform_Webhooks_V1_ListEndpointsRequest>,
            serializer: some GRPCCore.MessageSerializer<Primandproper_Platform_Webhooks_V1_ListEndpointsRequest>,
            deserializer: some GRPCCore.MessageDeserializer<Primandproper_Platform_Webhooks_V1_ListEndpointsResponse>,
            options: GRPCCore.CallOptions,
            onResponse handleResponse: @Sendable @escaping (GRPCCore.ClientResponse<Primandproper_Platform_Webhooks_V1_ListEndpointsResponse>) async throws -> Result
        ) async throws -> Result where Result: Sendable

        /// Call the "ArchiveEndpoint" method.
        ///
        /// - Parameters:
        ///   - request: A request containing a single `Primandproper_Platform_Webhooks_V1_ArchiveEndpointRequest` message.
        ///   - serializer: A serializer for `Primandproper_Platform_Webhooks_V1_ArchiveEndpointRequest` messages.
        ///   - deserializer: A deserializer for `Primandproper_Platform_Webhooks_V1_ArchiveEndpointResponse` messages.
        ///   - options: Options to apply to this RPC.
        ///   - handleResponse: A closure which handles the response and returns its result to
        ///       the caller. Returning from the closure will cancel the RPC if it hasn't
        ///       already finished.
        /// - Returns: The result of `handleResponse`.
        func archiveEndpoint<Result>(
            request: GRPCCore.ClientRequest<Primandproper_Platform_Webhooks_V1_ArchiveEndpointRequest>,
            serializer: some GRPCCore.MessageSerializer<Primandproper_Platform_Webhooks_V1_ArchiveEndpointRequest>,
            deserializer: some GRPCCore.MessageDeserializer<Primandproper_Platform_Webhooks_V1_ArchiveEndpointResponse>,
            options: GRPCCore.CallOptions,
            onResponse handleResponse: @Sendable @escaping (GRPCCore.ClientResponse<Primandproper_Platform_Webhooks_V1_ArchiveEndpointResponse>) async throws -> Result
        ) async throws -> Result where Result: Sendable

        /// Call the "RotateSecret" method.
        ///
        /// - Parameters:
        ///   - request: A request containing a single `Primandproper_Platform_Webhooks_V1_RotateSecretRequest` message.
        ///   - serializer: A serializer for `Primandproper_Platform_Webhooks_V1_RotateSecretRequest` messages.
        ///   - deserializer: A deserializer for `Primandproper_Platform_Webhooks_V1_RotateSecretResponse` messages.
        ///   - options: Options to apply to this RPC.
        ///   - handleResponse: A closure which handles the response and returns its result to
        ///       the caller. Returning from the closure will cancel the RPC if it hasn't
        ///       already finished.
        /// - Returns: The result of `handleResponse`.
        func rotateSecret<Result>(
            request: GRPCCore.ClientRequest<Primandproper_Platform_Webhooks_V1_RotateSecretRequest>,
            serializer: some GRPCCore.MessageSerializer<Primandproper_Platform_Webhooks_V1_RotateSecretRequest>,
            deserializer: some GRPCCore.MessageDeserializer<Primandproper_Platform_Webhooks_V1_RotateSecretResponse>,
            options: GRPCCore.CallOptions,
            onResponse handleResponse: @Sendable @escaping (GRPCCore.ClientResponse<Primandproper_Platform_Webhooks_V1_RotateSecretResponse>) async throws -> Result
        ) async throws -> Result where Result: Sendable

        /// Call the "AddSubscription" method.
        ///
        /// - Parameters:
        ///   - request: A request containing a single `Primandproper_Platform_Webhooks_V1_AddSubscriptionRequest` message.
        ///   - serializer: A serializer for `Primandproper_Platform_Webhooks_V1_AddSubscriptionRequest` messages.
        ///   - deserializer: A deserializer for `Primandproper_Platform_Webhooks_V1_AddSubscriptionResponse` messages.
        ///   - options: Options to apply to this RPC.
        ///   - handleResponse: A closure which handles the response and returns its result to
        ///       the caller. Returning from the closure will cancel the RPC if it hasn't
        ///       already finished.
        /// - Returns: The result of `handleResponse`.
        func addSubscription<Result>(
            request: GRPCCore.ClientRequest<Primandproper_Platform_Webhooks_V1_AddSubscriptionRequest>,
            serializer: some GRPCCore.MessageSerializer<Primandproper_Platform_Webhooks_V1_AddSubscriptionRequest>,
            deserializer: some GRPCCore.MessageDeserializer<Primandproper_Platform_Webhooks_V1_AddSubscriptionResponse>,
            options: GRPCCore.CallOptions,
            onResponse handleResponse: @Sendable @escaping (GRPCCore.ClientResponse<Primandproper_Platform_Webhooks_V1_AddSubscriptionResponse>) async throws -> Result
        ) async throws -> Result where Result: Sendable

        /// Call the "GetSubscription" method.
        ///
        /// - Parameters:
        ///   - request: A request containing a single `Primandproper_Platform_Webhooks_V1_GetSubscriptionRequest` message.
        ///   - serializer: A serializer for `Primandproper_Platform_Webhooks_V1_GetSubscriptionRequest` messages.
        ///   - deserializer: A deserializer for `Primandproper_Platform_Webhooks_V1_GetSubscriptionResponse` messages.
        ///   - options: Options to apply to this RPC.
        ///   - handleResponse: A closure which handles the response and returns its result to
        ///       the caller. Returning from the closure will cancel the RPC if it hasn't
        ///       already finished.
        /// - Returns: The result of `handleResponse`.
        func getSubscription<Result>(
            request: GRPCCore.ClientRequest<Primandproper_Platform_Webhooks_V1_GetSubscriptionRequest>,
            serializer: some GRPCCore.MessageSerializer<Primandproper_Platform_Webhooks_V1_GetSubscriptionRequest>,
            deserializer: some GRPCCore.MessageDeserializer<Primandproper_Platform_Webhooks_V1_GetSubscriptionResponse>,
            options: GRPCCore.CallOptions,
            onResponse handleResponse: @Sendable @escaping (GRPCCore.ClientResponse<Primandproper_Platform_Webhooks_V1_GetSubscriptionResponse>) async throws -> Result
        ) async throws -> Result where Result: Sendable

        /// Call the "ListSubscriptions" method.
        ///
        /// - Parameters:
        ///   - request: A request containing a single `Primandproper_Platform_Webhooks_V1_ListSubscriptionsRequest` message.
        ///   - serializer: A serializer for `Primandproper_Platform_Webhooks_V1_ListSubscriptionsRequest` messages.
        ///   - deserializer: A deserializer for `Primandproper_Platform_Webhooks_V1_ListSubscriptionsResponse` messages.
        ///   - options: Options to apply to this RPC.
        ///   - handleResponse: A closure which handles the response and returns its result to
        ///       the caller. Returning from the closure will cancel the RPC if it hasn't
        ///       already finished.
        /// - Returns: The result of `handleResponse`.
        func listSubscriptions<Result>(
            request: GRPCCore.ClientRequest<Primandproper_Platform_Webhooks_V1_ListSubscriptionsRequest>,
            serializer: some GRPCCore.MessageSerializer<Primandproper_Platform_Webhooks_V1_ListSubscriptionsRequest>,
            deserializer: some GRPCCore.MessageDeserializer<Primandproper_Platform_Webhooks_V1_ListSubscriptionsResponse>,
            options: GRPCCore.CallOptions,
            onResponse handleResponse: @Sendable @escaping (GRPCCore.ClientResponse<Primandproper_Platform_Webhooks_V1_ListSubscriptionsResponse>) async throws -> Result
        ) async throws -> Result where Result: Sendable

        /// Call the "ArchiveSubscription" method.
        ///
        /// - Parameters:
        ///   - request: A request containing a single `Primandproper_Platform_Webhooks_V1_ArchiveSubscriptionRequest` message.
        ///   - serializer: A serializer for `Primandproper_Platform_Webhooks_V1_ArchiveSubscriptionRequest` messages.
        ///   - deserializer: A deserializer for `Primandproper_Platform_Webhooks_V1_ArchiveSubscriptionResponse` messages.
        ///   - options: Options to apply to this RPC.
        ///   - handleResponse: A closure which handles the response and returns its result to
        ///       the caller. Returning from the closure will cancel the RPC if it hasn't
        ///       already finished.
        /// - Returns: The result of `handleResponse`.
        func archiveSubscription<Result>(
            request: GRPCCore.ClientRequest<Primandproper_Platform_Webhooks_V1_ArchiveSubscriptionRequest>,
            serializer: some GRPCCore.MessageSerializer<Primandproper_Platform_Webhooks_V1_ArchiveSubscriptionRequest>,
            deserializer: some GRPCCore.MessageDeserializer<Primandproper_Platform_Webhooks_V1_ArchiveSubscriptionResponse>,
            options: GRPCCore.CallOptions,
            onResponse handleResponse: @Sendable @escaping (GRPCCore.ClientResponse<Primandproper_Platform_Webhooks_V1_ArchiveSubscriptionResponse>) async throws -> Result
        ) async throws -> Result where Result: Sendable

        /// Call the "ListAttempts" method.
        ///
        /// - Parameters:
        ///   - request: A request containing a single `Primandproper_Platform_Webhooks_V1_ListAttemptsRequest` message.
        ///   - serializer: A serializer for `Primandproper_Platform_Webhooks_V1_ListAttemptsRequest` messages.
        ///   - deserializer: A deserializer for `Primandproper_Platform_Webhooks_V1_ListAttemptsResponse` messages.
        ///   - options: Options to apply to this RPC.
        ///   - handleResponse: A closure which handles the response and returns its result to
        ///       the caller. Returning from the closure will cancel the RPC if it hasn't
        ///       already finished.
        /// - Returns: The result of `handleResponse`.
        func listAttempts<Result>(
            request: GRPCCore.ClientRequest<Primandproper_Platform_Webhooks_V1_ListAttemptsRequest>,
            serializer: some GRPCCore.MessageSerializer<Primandproper_Platform_Webhooks_V1_ListAttemptsRequest>,
            deserializer: some GRPCCore.MessageDeserializer<Primandproper_Platform_Webhooks_V1_ListAttemptsResponse>,
            options: GRPCCore.CallOptions,
            onResponse handleResponse: @Sendable @escaping (GRPCCore.ClientResponse<Primandproper_Platform_Webhooks_V1_ListAttemptsResponse>) async throws -> Result
        ) async throws -> Result where Result: Sendable

        /// Call the "ListEventTypes" method.
        ///
        /// - Parameters:
        ///   - request: A request containing a single `Primandproper_Platform_Webhooks_V1_ListEventTypesRequest` message.
        ///   - serializer: A serializer for `Primandproper_Platform_Webhooks_V1_ListEventTypesRequest` messages.
        ///   - deserializer: A deserializer for `Primandproper_Platform_Webhooks_V1_ListEventTypesResponse` messages.
        ///   - options: Options to apply to this RPC.
        ///   - handleResponse: A closure which handles the response and returns its result to
        ///       the caller. Returning from the closure will cancel the RPC if it hasn't
        ///       already finished.
        /// - Returns: The result of `handleResponse`.
        func listEventTypes<Result>(
            request: GRPCCore.ClientRequest<Primandproper_Platform_Webhooks_V1_ListEventTypesRequest>,
            serializer: some GRPCCore.MessageSerializer<Primandproper_Platform_Webhooks_V1_ListEventTypesRequest>,
            deserializer: some GRPCCore.MessageDeserializer<Primandproper_Platform_Webhooks_V1_ListEventTypesResponse>,
            options: GRPCCore.CallOptions,
            onResponse handleResponse: @Sendable @escaping (GRPCCore.ClientResponse<Primandproper_Platform_Webhooks_V1_ListEventTypesResponse>) async throws -> Result
        ) async throws -> Result where Result: Sendable
    }

    /// Generated client for the "primandproper.platform.webhooks.v1.WebhooksService" service.
    ///
    /// The ``Client`` provides an implementation of ``ClientProtocol`` which wraps
    /// a `GRPCCore.GRPCCClient`. The underlying `GRPCClient` provides the long-lived
    /// means of communication with the remote peer.
    ///
    /// > Source IDL Documentation:
    /// >
    /// > WebhooksService is endpoint management and delivery history: the half of
    /// > webhooks that is a resource rather than a protocol, and the only half a
    /// > person ever touches.
    /// > 
    /// > Every RPC here is behind a grant and acts only within the tenant the caller's
    /// > principal names. The methods of webhooks.Store that are not here are absent
    /// > on purpose, in three groups.
    /// > 
    /// > Seven are the delivery machinery, which webhooks.Store already documents
    /// > under "The delivery machinery takes neither": Claim, MarkDelivered,
    /// > RecordFailure, RecordAttempt, Requeue, Backlog and Reap take no executor at
    /// > all and run on the handle the store was built with. They are a worker
    /// > draining a queue on a timer, servicing itself; the queue protocol's
    /// > correctness is that a claim commits before the request goes out, and a caller
    /// > supplying a transaction -- which is what an RPC is -- would be choosing when
    /// > that commit happens.
    /// > 
    /// > EndpointsForEvent is the second group, and it is the internal fan-out: the
    /// > dispatcher asking itself who is subscribed on the way to its own work. Its
    /// > own documentation calls it "the query whose missing filter delivers one
    /// > account's event to every other account's subscribers," which is a sentence
    /// > about a query nobody outside the component should be issuing.
    /// > 
    /// > Enqueue is the third and is the sharpest of them, because it is the one that
    /// > looks like it belongs here. It is consumer-facing: an application calls it to
    /// > fan an event out. But it "writes a delivery and one dispatch per endpoint, in
    /// > the caller's transaction, so both commit with whatever else that transaction
    /// > did" -- and that is the whole reason it exists. An RPC moves the write out of
    /// > the caller's transaction, so you get a delivery for a row that rolled back,
    /// > or a committed row nobody was ever told about. It is the same fact
    /// > audit.Recorder states about an audit entry: a record that can commit while
    /// > the change it describes rolls back is not a record of what happened, and no
    /// > amount of retrying fixes it after the fact.
    /// > 
    /// > A consumer who wants an event dispatched from another process sends that
    /// > process's own RPC -- the one whose handler owns the transaction the write
    /// > belongs in -- and calls webhooks.Dispatcher.Dispatch inside it.
    internal struct Client<Transport>: ClientProtocol where Transport: GRPCCore.ClientTransport {
        private let client: GRPCCore.GRPCClient<Transport>

        /// Creates a new client wrapping the provided `GRPCCore.GRPCClient`.
        ///
        /// - Parameters:
        ///   - client: A `GRPCCore.GRPCClient` providing a communication channel to the service.
        internal init(wrapping client: GRPCCore.GRPCClient<Transport>) {
            self.client = client
        }

        /// Call the "SaveEndpoint" method.
        ///
        /// - Parameters:
        ///   - request: A request containing a single `Primandproper_Platform_Webhooks_V1_SaveEndpointRequest` message.
        ///   - serializer: A serializer for `Primandproper_Platform_Webhooks_V1_SaveEndpointRequest` messages.
        ///   - deserializer: A deserializer for `Primandproper_Platform_Webhooks_V1_SaveEndpointResponse` messages.
        ///   - options: Options to apply to this RPC.
        ///   - handleResponse: A closure which handles the response and returns its result to
        ///       the caller. Returning from the closure will cancel the RPC if it hasn't
        ///       already finished.
        /// - Returns: The result of `handleResponse`.
        internal func saveEndpoint<Result>(
            request: GRPCCore.ClientRequest<Primandproper_Platform_Webhooks_V1_SaveEndpointRequest>,
            serializer: some GRPCCore.MessageSerializer<Primandproper_Platform_Webhooks_V1_SaveEndpointRequest>,
            deserializer: some GRPCCore.MessageDeserializer<Primandproper_Platform_Webhooks_V1_SaveEndpointResponse>,
            options: GRPCCore.CallOptions = .defaults,
            onResponse handleResponse: @Sendable @escaping (GRPCCore.ClientResponse<Primandproper_Platform_Webhooks_V1_SaveEndpointResponse>) async throws -> Result = { response in
                try response.message
            }
        ) async throws -> Result where Result: Sendable {
            try await self.client.unary(
                request: request,
                descriptor: Primandproper_Platform_Webhooks_V1_WebhooksService.Method.SaveEndpoint.descriptor,
                serializer: serializer,
                deserializer: deserializer,
                options: options,
                onResponse: handleResponse
            )
        }

        /// Call the "GetEndpoint" method.
        ///
        /// - Parameters:
        ///   - request: A request containing a single `Primandproper_Platform_Webhooks_V1_GetEndpointRequest` message.
        ///   - serializer: A serializer for `Primandproper_Platform_Webhooks_V1_GetEndpointRequest` messages.
        ///   - deserializer: A deserializer for `Primandproper_Platform_Webhooks_V1_GetEndpointResponse` messages.
        ///   - options: Options to apply to this RPC.
        ///   - handleResponse: A closure which handles the response and returns its result to
        ///       the caller. Returning from the closure will cancel the RPC if it hasn't
        ///       already finished.
        /// - Returns: The result of `handleResponse`.
        internal func getEndpoint<Result>(
            request: GRPCCore.ClientRequest<Primandproper_Platform_Webhooks_V1_GetEndpointRequest>,
            serializer: some GRPCCore.MessageSerializer<Primandproper_Platform_Webhooks_V1_GetEndpointRequest>,
            deserializer: some GRPCCore.MessageDeserializer<Primandproper_Platform_Webhooks_V1_GetEndpointResponse>,
            options: GRPCCore.CallOptions = .defaults,
            onResponse handleResponse: @Sendable @escaping (GRPCCore.ClientResponse<Primandproper_Platform_Webhooks_V1_GetEndpointResponse>) async throws -> Result = { response in
                try response.message
            }
        ) async throws -> Result where Result: Sendable {
            try await self.client.unary(
                request: request,
                descriptor: Primandproper_Platform_Webhooks_V1_WebhooksService.Method.GetEndpoint.descriptor,
                serializer: serializer,
                deserializer: deserializer,
                options: options,
                onResponse: handleResponse
            )
        }

        /// Call the "ListEndpoints" method.
        ///
        /// - Parameters:
        ///   - request: A request containing a single `Primandproper_Platform_Webhooks_V1_ListEndpointsRequest` message.
        ///   - serializer: A serializer for `Primandproper_Platform_Webhooks_V1_ListEndpointsRequest` messages.
        ///   - deserializer: A deserializer for `Primandproper_Platform_Webhooks_V1_ListEndpointsResponse` messages.
        ///   - options: Options to apply to this RPC.
        ///   - handleResponse: A closure which handles the response and returns its result to
        ///       the caller. Returning from the closure will cancel the RPC if it hasn't
        ///       already finished.
        /// - Returns: The result of `handleResponse`.
        internal func listEndpoints<Result>(
            request: GRPCCore.ClientRequest<Primandproper_Platform_Webhooks_V1_ListEndpointsRequest>,
            serializer: some GRPCCore.MessageSerializer<Primandproper_Platform_Webhooks_V1_ListEndpointsRequest>,
            deserializer: some GRPCCore.MessageDeserializer<Primandproper_Platform_Webhooks_V1_ListEndpointsResponse>,
            options: GRPCCore.CallOptions = .defaults,
            onResponse handleResponse: @Sendable @escaping (GRPCCore.ClientResponse<Primandproper_Platform_Webhooks_V1_ListEndpointsResponse>) async throws -> Result = { response in
                try response.message
            }
        ) async throws -> Result where Result: Sendable {
            try await self.client.unary(
                request: request,
                descriptor: Primandproper_Platform_Webhooks_V1_WebhooksService.Method.ListEndpoints.descriptor,
                serializer: serializer,
                deserializer: deserializer,
                options: options,
                onResponse: handleResponse
            )
        }

        /// Call the "ArchiveEndpoint" method.
        ///
        /// - Parameters:
        ///   - request: A request containing a single `Primandproper_Platform_Webhooks_V1_ArchiveEndpointRequest` message.
        ///   - serializer: A serializer for `Primandproper_Platform_Webhooks_V1_ArchiveEndpointRequest` messages.
        ///   - deserializer: A deserializer for `Primandproper_Platform_Webhooks_V1_ArchiveEndpointResponse` messages.
        ///   - options: Options to apply to this RPC.
        ///   - handleResponse: A closure which handles the response and returns its result to
        ///       the caller. Returning from the closure will cancel the RPC if it hasn't
        ///       already finished.
        /// - Returns: The result of `handleResponse`.
        internal func archiveEndpoint<Result>(
            request: GRPCCore.ClientRequest<Primandproper_Platform_Webhooks_V1_ArchiveEndpointRequest>,
            serializer: some GRPCCore.MessageSerializer<Primandproper_Platform_Webhooks_V1_ArchiveEndpointRequest>,
            deserializer: some GRPCCore.MessageDeserializer<Primandproper_Platform_Webhooks_V1_ArchiveEndpointResponse>,
            options: GRPCCore.CallOptions = .defaults,
            onResponse handleResponse: @Sendable @escaping (GRPCCore.ClientResponse<Primandproper_Platform_Webhooks_V1_ArchiveEndpointResponse>) async throws -> Result = { response in
                try response.message
            }
        ) async throws -> Result where Result: Sendable {
            try await self.client.unary(
                request: request,
                descriptor: Primandproper_Platform_Webhooks_V1_WebhooksService.Method.ArchiveEndpoint.descriptor,
                serializer: serializer,
                deserializer: deserializer,
                options: options,
                onResponse: handleResponse
            )
        }

        /// Call the "RotateSecret" method.
        ///
        /// - Parameters:
        ///   - request: A request containing a single `Primandproper_Platform_Webhooks_V1_RotateSecretRequest` message.
        ///   - serializer: A serializer for `Primandproper_Platform_Webhooks_V1_RotateSecretRequest` messages.
        ///   - deserializer: A deserializer for `Primandproper_Platform_Webhooks_V1_RotateSecretResponse` messages.
        ///   - options: Options to apply to this RPC.
        ///   - handleResponse: A closure which handles the response and returns its result to
        ///       the caller. Returning from the closure will cancel the RPC if it hasn't
        ///       already finished.
        /// - Returns: The result of `handleResponse`.
        internal func rotateSecret<Result>(
            request: GRPCCore.ClientRequest<Primandproper_Platform_Webhooks_V1_RotateSecretRequest>,
            serializer: some GRPCCore.MessageSerializer<Primandproper_Platform_Webhooks_V1_RotateSecretRequest>,
            deserializer: some GRPCCore.MessageDeserializer<Primandproper_Platform_Webhooks_V1_RotateSecretResponse>,
            options: GRPCCore.CallOptions = .defaults,
            onResponse handleResponse: @Sendable @escaping (GRPCCore.ClientResponse<Primandproper_Platform_Webhooks_V1_RotateSecretResponse>) async throws -> Result = { response in
                try response.message
            }
        ) async throws -> Result where Result: Sendable {
            try await self.client.unary(
                request: request,
                descriptor: Primandproper_Platform_Webhooks_V1_WebhooksService.Method.RotateSecret.descriptor,
                serializer: serializer,
                deserializer: deserializer,
                options: options,
                onResponse: handleResponse
            )
        }

        /// Call the "AddSubscription" method.
        ///
        /// - Parameters:
        ///   - request: A request containing a single `Primandproper_Platform_Webhooks_V1_AddSubscriptionRequest` message.
        ///   - serializer: A serializer for `Primandproper_Platform_Webhooks_V1_AddSubscriptionRequest` messages.
        ///   - deserializer: A deserializer for `Primandproper_Platform_Webhooks_V1_AddSubscriptionResponse` messages.
        ///   - options: Options to apply to this RPC.
        ///   - handleResponse: A closure which handles the response and returns its result to
        ///       the caller. Returning from the closure will cancel the RPC if it hasn't
        ///       already finished.
        /// - Returns: The result of `handleResponse`.
        internal func addSubscription<Result>(
            request: GRPCCore.ClientRequest<Primandproper_Platform_Webhooks_V1_AddSubscriptionRequest>,
            serializer: some GRPCCore.MessageSerializer<Primandproper_Platform_Webhooks_V1_AddSubscriptionRequest>,
            deserializer: some GRPCCore.MessageDeserializer<Primandproper_Platform_Webhooks_V1_AddSubscriptionResponse>,
            options: GRPCCore.CallOptions = .defaults,
            onResponse handleResponse: @Sendable @escaping (GRPCCore.ClientResponse<Primandproper_Platform_Webhooks_V1_AddSubscriptionResponse>) async throws -> Result = { response in
                try response.message
            }
        ) async throws -> Result where Result: Sendable {
            try await self.client.unary(
                request: request,
                descriptor: Primandproper_Platform_Webhooks_V1_WebhooksService.Method.AddSubscription.descriptor,
                serializer: serializer,
                deserializer: deserializer,
                options: options,
                onResponse: handleResponse
            )
        }

        /// Call the "GetSubscription" method.
        ///
        /// - Parameters:
        ///   - request: A request containing a single `Primandproper_Platform_Webhooks_V1_GetSubscriptionRequest` message.
        ///   - serializer: A serializer for `Primandproper_Platform_Webhooks_V1_GetSubscriptionRequest` messages.
        ///   - deserializer: A deserializer for `Primandproper_Platform_Webhooks_V1_GetSubscriptionResponse` messages.
        ///   - options: Options to apply to this RPC.
        ///   - handleResponse: A closure which handles the response and returns its result to
        ///       the caller. Returning from the closure will cancel the RPC if it hasn't
        ///       already finished.
        /// - Returns: The result of `handleResponse`.
        internal func getSubscription<Result>(
            request: GRPCCore.ClientRequest<Primandproper_Platform_Webhooks_V1_GetSubscriptionRequest>,
            serializer: some GRPCCore.MessageSerializer<Primandproper_Platform_Webhooks_V1_GetSubscriptionRequest>,
            deserializer: some GRPCCore.MessageDeserializer<Primandproper_Platform_Webhooks_V1_GetSubscriptionResponse>,
            options: GRPCCore.CallOptions = .defaults,
            onResponse handleResponse: @Sendable @escaping (GRPCCore.ClientResponse<Primandproper_Platform_Webhooks_V1_GetSubscriptionResponse>) async throws -> Result = { response in
                try response.message
            }
        ) async throws -> Result where Result: Sendable {
            try await self.client.unary(
                request: request,
                descriptor: Primandproper_Platform_Webhooks_V1_WebhooksService.Method.GetSubscription.descriptor,
                serializer: serializer,
                deserializer: deserializer,
                options: options,
                onResponse: handleResponse
            )
        }

        /// Call the "ListSubscriptions" method.
        ///
        /// - Parameters:
        ///   - request: A request containing a single `Primandproper_Platform_Webhooks_V1_ListSubscriptionsRequest` message.
        ///   - serializer: A serializer for `Primandproper_Platform_Webhooks_V1_ListSubscriptionsRequest` messages.
        ///   - deserializer: A deserializer for `Primandproper_Platform_Webhooks_V1_ListSubscriptionsResponse` messages.
        ///   - options: Options to apply to this RPC.
        ///   - handleResponse: A closure which handles the response and returns its result to
        ///       the caller. Returning from the closure will cancel the RPC if it hasn't
        ///       already finished.
        /// - Returns: The result of `handleResponse`.
        internal func listSubscriptions<Result>(
            request: GRPCCore.ClientRequest<Primandproper_Platform_Webhooks_V1_ListSubscriptionsRequest>,
            serializer: some GRPCCore.MessageSerializer<Primandproper_Platform_Webhooks_V1_ListSubscriptionsRequest>,
            deserializer: some GRPCCore.MessageDeserializer<Primandproper_Platform_Webhooks_V1_ListSubscriptionsResponse>,
            options: GRPCCore.CallOptions = .defaults,
            onResponse handleResponse: @Sendable @escaping (GRPCCore.ClientResponse<Primandproper_Platform_Webhooks_V1_ListSubscriptionsResponse>) async throws -> Result = { response in
                try response.message
            }
        ) async throws -> Result where Result: Sendable {
            try await self.client.unary(
                request: request,
                descriptor: Primandproper_Platform_Webhooks_V1_WebhooksService.Method.ListSubscriptions.descriptor,
                serializer: serializer,
                deserializer: deserializer,
                options: options,
                onResponse: handleResponse
            )
        }

        /// Call the "ArchiveSubscription" method.
        ///
        /// - Parameters:
        ///   - request: A request containing a single `Primandproper_Platform_Webhooks_V1_ArchiveSubscriptionRequest` message.
        ///   - serializer: A serializer for `Primandproper_Platform_Webhooks_V1_ArchiveSubscriptionRequest` messages.
        ///   - deserializer: A deserializer for `Primandproper_Platform_Webhooks_V1_ArchiveSubscriptionResponse` messages.
        ///   - options: Options to apply to this RPC.
        ///   - handleResponse: A closure which handles the response and returns its result to
        ///       the caller. Returning from the closure will cancel the RPC if it hasn't
        ///       already finished.
        /// - Returns: The result of `handleResponse`.
        internal func archiveSubscription<Result>(
            request: GRPCCore.ClientRequest<Primandproper_Platform_Webhooks_V1_ArchiveSubscriptionRequest>,
            serializer: some GRPCCore.MessageSerializer<Primandproper_Platform_Webhooks_V1_ArchiveSubscriptionRequest>,
            deserializer: some GRPCCore.MessageDeserializer<Primandproper_Platform_Webhooks_V1_ArchiveSubscriptionResponse>,
            options: GRPCCore.CallOptions = .defaults,
            onResponse handleResponse: @Sendable @escaping (GRPCCore.ClientResponse<Primandproper_Platform_Webhooks_V1_ArchiveSubscriptionResponse>) async throws -> Result = { response in
                try response.message
            }
        ) async throws -> Result where Result: Sendable {
            try await self.client.unary(
                request: request,
                descriptor: Primandproper_Platform_Webhooks_V1_WebhooksService.Method.ArchiveSubscription.descriptor,
                serializer: serializer,
                deserializer: deserializer,
                options: options,
                onResponse: handleResponse
            )
        }

        /// Call the "ListAttempts" method.
        ///
        /// - Parameters:
        ///   - request: A request containing a single `Primandproper_Platform_Webhooks_V1_ListAttemptsRequest` message.
        ///   - serializer: A serializer for `Primandproper_Platform_Webhooks_V1_ListAttemptsRequest` messages.
        ///   - deserializer: A deserializer for `Primandproper_Platform_Webhooks_V1_ListAttemptsResponse` messages.
        ///   - options: Options to apply to this RPC.
        ///   - handleResponse: A closure which handles the response and returns its result to
        ///       the caller. Returning from the closure will cancel the RPC if it hasn't
        ///       already finished.
        /// - Returns: The result of `handleResponse`.
        internal func listAttempts<Result>(
            request: GRPCCore.ClientRequest<Primandproper_Platform_Webhooks_V1_ListAttemptsRequest>,
            serializer: some GRPCCore.MessageSerializer<Primandproper_Platform_Webhooks_V1_ListAttemptsRequest>,
            deserializer: some GRPCCore.MessageDeserializer<Primandproper_Platform_Webhooks_V1_ListAttemptsResponse>,
            options: GRPCCore.CallOptions = .defaults,
            onResponse handleResponse: @Sendable @escaping (GRPCCore.ClientResponse<Primandproper_Platform_Webhooks_V1_ListAttemptsResponse>) async throws -> Result = { response in
                try response.message
            }
        ) async throws -> Result where Result: Sendable {
            try await self.client.unary(
                request: request,
                descriptor: Primandproper_Platform_Webhooks_V1_WebhooksService.Method.ListAttempts.descriptor,
                serializer: serializer,
                deserializer: deserializer,
                options: options,
                onResponse: handleResponse
            )
        }

        /// Call the "ListEventTypes" method.
        ///
        /// - Parameters:
        ///   - request: A request containing a single `Primandproper_Platform_Webhooks_V1_ListEventTypesRequest` message.
        ///   - serializer: A serializer for `Primandproper_Platform_Webhooks_V1_ListEventTypesRequest` messages.
        ///   - deserializer: A deserializer for `Primandproper_Platform_Webhooks_V1_ListEventTypesResponse` messages.
        ///   - options: Options to apply to this RPC.
        ///   - handleResponse: A closure which handles the response and returns its result to
        ///       the caller. Returning from the closure will cancel the RPC if it hasn't
        ///       already finished.
        /// - Returns: The result of `handleResponse`.
        internal func listEventTypes<Result>(
            request: GRPCCore.ClientRequest<Primandproper_Platform_Webhooks_V1_ListEventTypesRequest>,
            serializer: some GRPCCore.MessageSerializer<Primandproper_Platform_Webhooks_V1_ListEventTypesRequest>,
            deserializer: some GRPCCore.MessageDeserializer<Primandproper_Platform_Webhooks_V1_ListEventTypesResponse>,
            options: GRPCCore.CallOptions = .defaults,
            onResponse handleResponse: @Sendable @escaping (GRPCCore.ClientResponse<Primandproper_Platform_Webhooks_V1_ListEventTypesResponse>) async throws -> Result = { response in
                try response.message
            }
        ) async throws -> Result where Result: Sendable {
            try await self.client.unary(
                request: request,
                descriptor: Primandproper_Platform_Webhooks_V1_WebhooksService.Method.ListEventTypes.descriptor,
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
extension Primandproper_Platform_Webhooks_V1_WebhooksService.ClientProtocol {
    /// Call the "SaveEndpoint" method.
    ///
    /// - Parameters:
    ///   - request: A request containing a single `Primandproper_Platform_Webhooks_V1_SaveEndpointRequest` message.
    ///   - options: Options to apply to this RPC.
    ///   - handleResponse: A closure which handles the response and returns its result to
    ///       the caller. Returning from the closure will cancel the RPC if it hasn't
    ///       already finished.
    /// - Returns: The result of `handleResponse`.
    internal func saveEndpoint<Result>(
        request: GRPCCore.ClientRequest<Primandproper_Platform_Webhooks_V1_SaveEndpointRequest>,
        options: GRPCCore.CallOptions = .defaults,
        onResponse handleResponse: @Sendable @escaping (GRPCCore.ClientResponse<Primandproper_Platform_Webhooks_V1_SaveEndpointResponse>) async throws -> Result = { response in
            try response.message
        }
    ) async throws -> Result where Result: Sendable {
        try await self.saveEndpoint(
            request: request,
            serializer: GRPCProtobuf.ProtobufSerializer<Primandproper_Platform_Webhooks_V1_SaveEndpointRequest>(),
            deserializer: GRPCProtobuf.ProtobufDeserializer<Primandproper_Platform_Webhooks_V1_SaveEndpointResponse>(),
            options: options,
            onResponse: handleResponse
        )
    }

    /// Call the "GetEndpoint" method.
    ///
    /// - Parameters:
    ///   - request: A request containing a single `Primandproper_Platform_Webhooks_V1_GetEndpointRequest` message.
    ///   - options: Options to apply to this RPC.
    ///   - handleResponse: A closure which handles the response and returns its result to
    ///       the caller. Returning from the closure will cancel the RPC if it hasn't
    ///       already finished.
    /// - Returns: The result of `handleResponse`.
    internal func getEndpoint<Result>(
        request: GRPCCore.ClientRequest<Primandproper_Platform_Webhooks_V1_GetEndpointRequest>,
        options: GRPCCore.CallOptions = .defaults,
        onResponse handleResponse: @Sendable @escaping (GRPCCore.ClientResponse<Primandproper_Platform_Webhooks_V1_GetEndpointResponse>) async throws -> Result = { response in
            try response.message
        }
    ) async throws -> Result where Result: Sendable {
        try await self.getEndpoint(
            request: request,
            serializer: GRPCProtobuf.ProtobufSerializer<Primandproper_Platform_Webhooks_V1_GetEndpointRequest>(),
            deserializer: GRPCProtobuf.ProtobufDeserializer<Primandproper_Platform_Webhooks_V1_GetEndpointResponse>(),
            options: options,
            onResponse: handleResponse
        )
    }

    /// Call the "ListEndpoints" method.
    ///
    /// - Parameters:
    ///   - request: A request containing a single `Primandproper_Platform_Webhooks_V1_ListEndpointsRequest` message.
    ///   - options: Options to apply to this RPC.
    ///   - handleResponse: A closure which handles the response and returns its result to
    ///       the caller. Returning from the closure will cancel the RPC if it hasn't
    ///       already finished.
    /// - Returns: The result of `handleResponse`.
    internal func listEndpoints<Result>(
        request: GRPCCore.ClientRequest<Primandproper_Platform_Webhooks_V1_ListEndpointsRequest>,
        options: GRPCCore.CallOptions = .defaults,
        onResponse handleResponse: @Sendable @escaping (GRPCCore.ClientResponse<Primandproper_Platform_Webhooks_V1_ListEndpointsResponse>) async throws -> Result = { response in
            try response.message
        }
    ) async throws -> Result where Result: Sendable {
        try await self.listEndpoints(
            request: request,
            serializer: GRPCProtobuf.ProtobufSerializer<Primandproper_Platform_Webhooks_V1_ListEndpointsRequest>(),
            deserializer: GRPCProtobuf.ProtobufDeserializer<Primandproper_Platform_Webhooks_V1_ListEndpointsResponse>(),
            options: options,
            onResponse: handleResponse
        )
    }

    /// Call the "ArchiveEndpoint" method.
    ///
    /// - Parameters:
    ///   - request: A request containing a single `Primandproper_Platform_Webhooks_V1_ArchiveEndpointRequest` message.
    ///   - options: Options to apply to this RPC.
    ///   - handleResponse: A closure which handles the response and returns its result to
    ///       the caller. Returning from the closure will cancel the RPC if it hasn't
    ///       already finished.
    /// - Returns: The result of `handleResponse`.
    internal func archiveEndpoint<Result>(
        request: GRPCCore.ClientRequest<Primandproper_Platform_Webhooks_V1_ArchiveEndpointRequest>,
        options: GRPCCore.CallOptions = .defaults,
        onResponse handleResponse: @Sendable @escaping (GRPCCore.ClientResponse<Primandproper_Platform_Webhooks_V1_ArchiveEndpointResponse>) async throws -> Result = { response in
            try response.message
        }
    ) async throws -> Result where Result: Sendable {
        try await self.archiveEndpoint(
            request: request,
            serializer: GRPCProtobuf.ProtobufSerializer<Primandproper_Platform_Webhooks_V1_ArchiveEndpointRequest>(),
            deserializer: GRPCProtobuf.ProtobufDeserializer<Primandproper_Platform_Webhooks_V1_ArchiveEndpointResponse>(),
            options: options,
            onResponse: handleResponse
        )
    }

    /// Call the "RotateSecret" method.
    ///
    /// - Parameters:
    ///   - request: A request containing a single `Primandproper_Platform_Webhooks_V1_RotateSecretRequest` message.
    ///   - options: Options to apply to this RPC.
    ///   - handleResponse: A closure which handles the response and returns its result to
    ///       the caller. Returning from the closure will cancel the RPC if it hasn't
    ///       already finished.
    /// - Returns: The result of `handleResponse`.
    internal func rotateSecret<Result>(
        request: GRPCCore.ClientRequest<Primandproper_Platform_Webhooks_V1_RotateSecretRequest>,
        options: GRPCCore.CallOptions = .defaults,
        onResponse handleResponse: @Sendable @escaping (GRPCCore.ClientResponse<Primandproper_Platform_Webhooks_V1_RotateSecretResponse>) async throws -> Result = { response in
            try response.message
        }
    ) async throws -> Result where Result: Sendable {
        try await self.rotateSecret(
            request: request,
            serializer: GRPCProtobuf.ProtobufSerializer<Primandproper_Platform_Webhooks_V1_RotateSecretRequest>(),
            deserializer: GRPCProtobuf.ProtobufDeserializer<Primandproper_Platform_Webhooks_V1_RotateSecretResponse>(),
            options: options,
            onResponse: handleResponse
        )
    }

    /// Call the "AddSubscription" method.
    ///
    /// - Parameters:
    ///   - request: A request containing a single `Primandproper_Platform_Webhooks_V1_AddSubscriptionRequest` message.
    ///   - options: Options to apply to this RPC.
    ///   - handleResponse: A closure which handles the response and returns its result to
    ///       the caller. Returning from the closure will cancel the RPC if it hasn't
    ///       already finished.
    /// - Returns: The result of `handleResponse`.
    internal func addSubscription<Result>(
        request: GRPCCore.ClientRequest<Primandproper_Platform_Webhooks_V1_AddSubscriptionRequest>,
        options: GRPCCore.CallOptions = .defaults,
        onResponse handleResponse: @Sendable @escaping (GRPCCore.ClientResponse<Primandproper_Platform_Webhooks_V1_AddSubscriptionResponse>) async throws -> Result = { response in
            try response.message
        }
    ) async throws -> Result where Result: Sendable {
        try await self.addSubscription(
            request: request,
            serializer: GRPCProtobuf.ProtobufSerializer<Primandproper_Platform_Webhooks_V1_AddSubscriptionRequest>(),
            deserializer: GRPCProtobuf.ProtobufDeserializer<Primandproper_Platform_Webhooks_V1_AddSubscriptionResponse>(),
            options: options,
            onResponse: handleResponse
        )
    }

    /// Call the "GetSubscription" method.
    ///
    /// - Parameters:
    ///   - request: A request containing a single `Primandproper_Platform_Webhooks_V1_GetSubscriptionRequest` message.
    ///   - options: Options to apply to this RPC.
    ///   - handleResponse: A closure which handles the response and returns its result to
    ///       the caller. Returning from the closure will cancel the RPC if it hasn't
    ///       already finished.
    /// - Returns: The result of `handleResponse`.
    internal func getSubscription<Result>(
        request: GRPCCore.ClientRequest<Primandproper_Platform_Webhooks_V1_GetSubscriptionRequest>,
        options: GRPCCore.CallOptions = .defaults,
        onResponse handleResponse: @Sendable @escaping (GRPCCore.ClientResponse<Primandproper_Platform_Webhooks_V1_GetSubscriptionResponse>) async throws -> Result = { response in
            try response.message
        }
    ) async throws -> Result where Result: Sendable {
        try await self.getSubscription(
            request: request,
            serializer: GRPCProtobuf.ProtobufSerializer<Primandproper_Platform_Webhooks_V1_GetSubscriptionRequest>(),
            deserializer: GRPCProtobuf.ProtobufDeserializer<Primandproper_Platform_Webhooks_V1_GetSubscriptionResponse>(),
            options: options,
            onResponse: handleResponse
        )
    }

    /// Call the "ListSubscriptions" method.
    ///
    /// - Parameters:
    ///   - request: A request containing a single `Primandproper_Platform_Webhooks_V1_ListSubscriptionsRequest` message.
    ///   - options: Options to apply to this RPC.
    ///   - handleResponse: A closure which handles the response and returns its result to
    ///       the caller. Returning from the closure will cancel the RPC if it hasn't
    ///       already finished.
    /// - Returns: The result of `handleResponse`.
    internal func listSubscriptions<Result>(
        request: GRPCCore.ClientRequest<Primandproper_Platform_Webhooks_V1_ListSubscriptionsRequest>,
        options: GRPCCore.CallOptions = .defaults,
        onResponse handleResponse: @Sendable @escaping (GRPCCore.ClientResponse<Primandproper_Platform_Webhooks_V1_ListSubscriptionsResponse>) async throws -> Result = { response in
            try response.message
        }
    ) async throws -> Result where Result: Sendable {
        try await self.listSubscriptions(
            request: request,
            serializer: GRPCProtobuf.ProtobufSerializer<Primandproper_Platform_Webhooks_V1_ListSubscriptionsRequest>(),
            deserializer: GRPCProtobuf.ProtobufDeserializer<Primandproper_Platform_Webhooks_V1_ListSubscriptionsResponse>(),
            options: options,
            onResponse: handleResponse
        )
    }

    /// Call the "ArchiveSubscription" method.
    ///
    /// - Parameters:
    ///   - request: A request containing a single `Primandproper_Platform_Webhooks_V1_ArchiveSubscriptionRequest` message.
    ///   - options: Options to apply to this RPC.
    ///   - handleResponse: A closure which handles the response and returns its result to
    ///       the caller. Returning from the closure will cancel the RPC if it hasn't
    ///       already finished.
    /// - Returns: The result of `handleResponse`.
    internal func archiveSubscription<Result>(
        request: GRPCCore.ClientRequest<Primandproper_Platform_Webhooks_V1_ArchiveSubscriptionRequest>,
        options: GRPCCore.CallOptions = .defaults,
        onResponse handleResponse: @Sendable @escaping (GRPCCore.ClientResponse<Primandproper_Platform_Webhooks_V1_ArchiveSubscriptionResponse>) async throws -> Result = { response in
            try response.message
        }
    ) async throws -> Result where Result: Sendable {
        try await self.archiveSubscription(
            request: request,
            serializer: GRPCProtobuf.ProtobufSerializer<Primandproper_Platform_Webhooks_V1_ArchiveSubscriptionRequest>(),
            deserializer: GRPCProtobuf.ProtobufDeserializer<Primandproper_Platform_Webhooks_V1_ArchiveSubscriptionResponse>(),
            options: options,
            onResponse: handleResponse
        )
    }

    /// Call the "ListAttempts" method.
    ///
    /// - Parameters:
    ///   - request: A request containing a single `Primandproper_Platform_Webhooks_V1_ListAttemptsRequest` message.
    ///   - options: Options to apply to this RPC.
    ///   - handleResponse: A closure which handles the response and returns its result to
    ///       the caller. Returning from the closure will cancel the RPC if it hasn't
    ///       already finished.
    /// - Returns: The result of `handleResponse`.
    internal func listAttempts<Result>(
        request: GRPCCore.ClientRequest<Primandproper_Platform_Webhooks_V1_ListAttemptsRequest>,
        options: GRPCCore.CallOptions = .defaults,
        onResponse handleResponse: @Sendable @escaping (GRPCCore.ClientResponse<Primandproper_Platform_Webhooks_V1_ListAttemptsResponse>) async throws -> Result = { response in
            try response.message
        }
    ) async throws -> Result where Result: Sendable {
        try await self.listAttempts(
            request: request,
            serializer: GRPCProtobuf.ProtobufSerializer<Primandproper_Platform_Webhooks_V1_ListAttemptsRequest>(),
            deserializer: GRPCProtobuf.ProtobufDeserializer<Primandproper_Platform_Webhooks_V1_ListAttemptsResponse>(),
            options: options,
            onResponse: handleResponse
        )
    }

    /// Call the "ListEventTypes" method.
    ///
    /// - Parameters:
    ///   - request: A request containing a single `Primandproper_Platform_Webhooks_V1_ListEventTypesRequest` message.
    ///   - options: Options to apply to this RPC.
    ///   - handleResponse: A closure which handles the response and returns its result to
    ///       the caller. Returning from the closure will cancel the RPC if it hasn't
    ///       already finished.
    /// - Returns: The result of `handleResponse`.
    internal func listEventTypes<Result>(
        request: GRPCCore.ClientRequest<Primandproper_Platform_Webhooks_V1_ListEventTypesRequest>,
        options: GRPCCore.CallOptions = .defaults,
        onResponse handleResponse: @Sendable @escaping (GRPCCore.ClientResponse<Primandproper_Platform_Webhooks_V1_ListEventTypesResponse>) async throws -> Result = { response in
            try response.message
        }
    ) async throws -> Result where Result: Sendable {
        try await self.listEventTypes(
            request: request,
            serializer: GRPCProtobuf.ProtobufSerializer<Primandproper_Platform_Webhooks_V1_ListEventTypesRequest>(),
            deserializer: GRPCProtobuf.ProtobufDeserializer<Primandproper_Platform_Webhooks_V1_ListEventTypesResponse>(),
            options: options,
            onResponse: handleResponse
        )
    }
}

// Helpers providing sugared APIs for 'ClientProtocol' methods.
@available(macOS 15.0, iOS 18.0, watchOS 11.0, tvOS 18.0, visionOS 2.0, *)
extension Primandproper_Platform_Webhooks_V1_WebhooksService.ClientProtocol {
    /// Call the "SaveEndpoint" method.
    ///
    /// - Parameters:
    ///   - message: request message to send.
    ///   - metadata: Additional metadata to send, defaults to empty.
    ///   - options: Options to apply to this RPC, defaults to `.defaults`.
    ///   - handleResponse: A closure which handles the response and returns its result to
    ///       the caller. Returning from the closure will cancel the RPC if it hasn't
    ///       already finished.
    /// - Returns: The result of `handleResponse`.
    internal func saveEndpoint<Result>(
        _ message: Primandproper_Platform_Webhooks_V1_SaveEndpointRequest,
        metadata: GRPCCore.Metadata = [:],
        options: GRPCCore.CallOptions = .defaults,
        onResponse handleResponse: @Sendable @escaping (GRPCCore.ClientResponse<Primandproper_Platform_Webhooks_V1_SaveEndpointResponse>) async throws -> Result = { response in
            try response.message
        }
    ) async throws -> Result where Result: Sendable {
        let request = GRPCCore.ClientRequest<Primandproper_Platform_Webhooks_V1_SaveEndpointRequest>(
            message: message,
            metadata: metadata
        )
        return try await self.saveEndpoint(
            request: request,
            options: options,
            onResponse: handleResponse
        )
    }

    /// Call the "GetEndpoint" method.
    ///
    /// - Parameters:
    ///   - message: request message to send.
    ///   - metadata: Additional metadata to send, defaults to empty.
    ///   - options: Options to apply to this RPC, defaults to `.defaults`.
    ///   - handleResponse: A closure which handles the response and returns its result to
    ///       the caller. Returning from the closure will cancel the RPC if it hasn't
    ///       already finished.
    /// - Returns: The result of `handleResponse`.
    internal func getEndpoint<Result>(
        _ message: Primandproper_Platform_Webhooks_V1_GetEndpointRequest,
        metadata: GRPCCore.Metadata = [:],
        options: GRPCCore.CallOptions = .defaults,
        onResponse handleResponse: @Sendable @escaping (GRPCCore.ClientResponse<Primandproper_Platform_Webhooks_V1_GetEndpointResponse>) async throws -> Result = { response in
            try response.message
        }
    ) async throws -> Result where Result: Sendable {
        let request = GRPCCore.ClientRequest<Primandproper_Platform_Webhooks_V1_GetEndpointRequest>(
            message: message,
            metadata: metadata
        )
        return try await self.getEndpoint(
            request: request,
            options: options,
            onResponse: handleResponse
        )
    }

    /// Call the "ListEndpoints" method.
    ///
    /// - Parameters:
    ///   - message: request message to send.
    ///   - metadata: Additional metadata to send, defaults to empty.
    ///   - options: Options to apply to this RPC, defaults to `.defaults`.
    ///   - handleResponse: A closure which handles the response and returns its result to
    ///       the caller. Returning from the closure will cancel the RPC if it hasn't
    ///       already finished.
    /// - Returns: The result of `handleResponse`.
    internal func listEndpoints<Result>(
        _ message: Primandproper_Platform_Webhooks_V1_ListEndpointsRequest,
        metadata: GRPCCore.Metadata = [:],
        options: GRPCCore.CallOptions = .defaults,
        onResponse handleResponse: @Sendable @escaping (GRPCCore.ClientResponse<Primandproper_Platform_Webhooks_V1_ListEndpointsResponse>) async throws -> Result = { response in
            try response.message
        }
    ) async throws -> Result where Result: Sendable {
        let request = GRPCCore.ClientRequest<Primandproper_Platform_Webhooks_V1_ListEndpointsRequest>(
            message: message,
            metadata: metadata
        )
        return try await self.listEndpoints(
            request: request,
            options: options,
            onResponse: handleResponse
        )
    }

    /// Call the "ArchiveEndpoint" method.
    ///
    /// - Parameters:
    ///   - message: request message to send.
    ///   - metadata: Additional metadata to send, defaults to empty.
    ///   - options: Options to apply to this RPC, defaults to `.defaults`.
    ///   - handleResponse: A closure which handles the response and returns its result to
    ///       the caller. Returning from the closure will cancel the RPC if it hasn't
    ///       already finished.
    /// - Returns: The result of `handleResponse`.
    internal func archiveEndpoint<Result>(
        _ message: Primandproper_Platform_Webhooks_V1_ArchiveEndpointRequest,
        metadata: GRPCCore.Metadata = [:],
        options: GRPCCore.CallOptions = .defaults,
        onResponse handleResponse: @Sendable @escaping (GRPCCore.ClientResponse<Primandproper_Platform_Webhooks_V1_ArchiveEndpointResponse>) async throws -> Result = { response in
            try response.message
        }
    ) async throws -> Result where Result: Sendable {
        let request = GRPCCore.ClientRequest<Primandproper_Platform_Webhooks_V1_ArchiveEndpointRequest>(
            message: message,
            metadata: metadata
        )
        return try await self.archiveEndpoint(
            request: request,
            options: options,
            onResponse: handleResponse
        )
    }

    /// Call the "RotateSecret" method.
    ///
    /// - Parameters:
    ///   - message: request message to send.
    ///   - metadata: Additional metadata to send, defaults to empty.
    ///   - options: Options to apply to this RPC, defaults to `.defaults`.
    ///   - handleResponse: A closure which handles the response and returns its result to
    ///       the caller. Returning from the closure will cancel the RPC if it hasn't
    ///       already finished.
    /// - Returns: The result of `handleResponse`.
    internal func rotateSecret<Result>(
        _ message: Primandproper_Platform_Webhooks_V1_RotateSecretRequest,
        metadata: GRPCCore.Metadata = [:],
        options: GRPCCore.CallOptions = .defaults,
        onResponse handleResponse: @Sendable @escaping (GRPCCore.ClientResponse<Primandproper_Platform_Webhooks_V1_RotateSecretResponse>) async throws -> Result = { response in
            try response.message
        }
    ) async throws -> Result where Result: Sendable {
        let request = GRPCCore.ClientRequest<Primandproper_Platform_Webhooks_V1_RotateSecretRequest>(
            message: message,
            metadata: metadata
        )
        return try await self.rotateSecret(
            request: request,
            options: options,
            onResponse: handleResponse
        )
    }

    /// Call the "AddSubscription" method.
    ///
    /// - Parameters:
    ///   - message: request message to send.
    ///   - metadata: Additional metadata to send, defaults to empty.
    ///   - options: Options to apply to this RPC, defaults to `.defaults`.
    ///   - handleResponse: A closure which handles the response and returns its result to
    ///       the caller. Returning from the closure will cancel the RPC if it hasn't
    ///       already finished.
    /// - Returns: The result of `handleResponse`.
    internal func addSubscription<Result>(
        _ message: Primandproper_Platform_Webhooks_V1_AddSubscriptionRequest,
        metadata: GRPCCore.Metadata = [:],
        options: GRPCCore.CallOptions = .defaults,
        onResponse handleResponse: @Sendable @escaping (GRPCCore.ClientResponse<Primandproper_Platform_Webhooks_V1_AddSubscriptionResponse>) async throws -> Result = { response in
            try response.message
        }
    ) async throws -> Result where Result: Sendable {
        let request = GRPCCore.ClientRequest<Primandproper_Platform_Webhooks_V1_AddSubscriptionRequest>(
            message: message,
            metadata: metadata
        )
        return try await self.addSubscription(
            request: request,
            options: options,
            onResponse: handleResponse
        )
    }

    /// Call the "GetSubscription" method.
    ///
    /// - Parameters:
    ///   - message: request message to send.
    ///   - metadata: Additional metadata to send, defaults to empty.
    ///   - options: Options to apply to this RPC, defaults to `.defaults`.
    ///   - handleResponse: A closure which handles the response and returns its result to
    ///       the caller. Returning from the closure will cancel the RPC if it hasn't
    ///       already finished.
    /// - Returns: The result of `handleResponse`.
    internal func getSubscription<Result>(
        _ message: Primandproper_Platform_Webhooks_V1_GetSubscriptionRequest,
        metadata: GRPCCore.Metadata = [:],
        options: GRPCCore.CallOptions = .defaults,
        onResponse handleResponse: @Sendable @escaping (GRPCCore.ClientResponse<Primandproper_Platform_Webhooks_V1_GetSubscriptionResponse>) async throws -> Result = { response in
            try response.message
        }
    ) async throws -> Result where Result: Sendable {
        let request = GRPCCore.ClientRequest<Primandproper_Platform_Webhooks_V1_GetSubscriptionRequest>(
            message: message,
            metadata: metadata
        )
        return try await self.getSubscription(
            request: request,
            options: options,
            onResponse: handleResponse
        )
    }

    /// Call the "ListSubscriptions" method.
    ///
    /// - Parameters:
    ///   - message: request message to send.
    ///   - metadata: Additional metadata to send, defaults to empty.
    ///   - options: Options to apply to this RPC, defaults to `.defaults`.
    ///   - handleResponse: A closure which handles the response and returns its result to
    ///       the caller. Returning from the closure will cancel the RPC if it hasn't
    ///       already finished.
    /// - Returns: The result of `handleResponse`.
    internal func listSubscriptions<Result>(
        _ message: Primandproper_Platform_Webhooks_V1_ListSubscriptionsRequest,
        metadata: GRPCCore.Metadata = [:],
        options: GRPCCore.CallOptions = .defaults,
        onResponse handleResponse: @Sendable @escaping (GRPCCore.ClientResponse<Primandproper_Platform_Webhooks_V1_ListSubscriptionsResponse>) async throws -> Result = { response in
            try response.message
        }
    ) async throws -> Result where Result: Sendable {
        let request = GRPCCore.ClientRequest<Primandproper_Platform_Webhooks_V1_ListSubscriptionsRequest>(
            message: message,
            metadata: metadata
        )
        return try await self.listSubscriptions(
            request: request,
            options: options,
            onResponse: handleResponse
        )
    }

    /// Call the "ArchiveSubscription" method.
    ///
    /// - Parameters:
    ///   - message: request message to send.
    ///   - metadata: Additional metadata to send, defaults to empty.
    ///   - options: Options to apply to this RPC, defaults to `.defaults`.
    ///   - handleResponse: A closure which handles the response and returns its result to
    ///       the caller. Returning from the closure will cancel the RPC if it hasn't
    ///       already finished.
    /// - Returns: The result of `handleResponse`.
    internal func archiveSubscription<Result>(
        _ message: Primandproper_Platform_Webhooks_V1_ArchiveSubscriptionRequest,
        metadata: GRPCCore.Metadata = [:],
        options: GRPCCore.CallOptions = .defaults,
        onResponse handleResponse: @Sendable @escaping (GRPCCore.ClientResponse<Primandproper_Platform_Webhooks_V1_ArchiveSubscriptionResponse>) async throws -> Result = { response in
            try response.message
        }
    ) async throws -> Result where Result: Sendable {
        let request = GRPCCore.ClientRequest<Primandproper_Platform_Webhooks_V1_ArchiveSubscriptionRequest>(
            message: message,
            metadata: metadata
        )
        return try await self.archiveSubscription(
            request: request,
            options: options,
            onResponse: handleResponse
        )
    }

    /// Call the "ListAttempts" method.
    ///
    /// - Parameters:
    ///   - message: request message to send.
    ///   - metadata: Additional metadata to send, defaults to empty.
    ///   - options: Options to apply to this RPC, defaults to `.defaults`.
    ///   - handleResponse: A closure which handles the response and returns its result to
    ///       the caller. Returning from the closure will cancel the RPC if it hasn't
    ///       already finished.
    /// - Returns: The result of `handleResponse`.
    internal func listAttempts<Result>(
        _ message: Primandproper_Platform_Webhooks_V1_ListAttemptsRequest,
        metadata: GRPCCore.Metadata = [:],
        options: GRPCCore.CallOptions = .defaults,
        onResponse handleResponse: @Sendable @escaping (GRPCCore.ClientResponse<Primandproper_Platform_Webhooks_V1_ListAttemptsResponse>) async throws -> Result = { response in
            try response.message
        }
    ) async throws -> Result where Result: Sendable {
        let request = GRPCCore.ClientRequest<Primandproper_Platform_Webhooks_V1_ListAttemptsRequest>(
            message: message,
            metadata: metadata
        )
        return try await self.listAttempts(
            request: request,
            options: options,
            onResponse: handleResponse
        )
    }

    /// Call the "ListEventTypes" method.
    ///
    /// - Parameters:
    ///   - message: request message to send.
    ///   - metadata: Additional metadata to send, defaults to empty.
    ///   - options: Options to apply to this RPC, defaults to `.defaults`.
    ///   - handleResponse: A closure which handles the response and returns its result to
    ///       the caller. Returning from the closure will cancel the RPC if it hasn't
    ///       already finished.
    /// - Returns: The result of `handleResponse`.
    internal func listEventTypes<Result>(
        _ message: Primandproper_Platform_Webhooks_V1_ListEventTypesRequest,
        metadata: GRPCCore.Metadata = [:],
        options: GRPCCore.CallOptions = .defaults,
        onResponse handleResponse: @Sendable @escaping (GRPCCore.ClientResponse<Primandproper_Platform_Webhooks_V1_ListEventTypesResponse>) async throws -> Result = { response in
            try response.message
        }
    ) async throws -> Result where Result: Sendable {
        let request = GRPCCore.ClientRequest<Primandproper_Platform_Webhooks_V1_ListEventTypesRequest>(
            message: message,
            metadata: metadata
        )
        return try await self.listEventTypes(
            request: request,
            options: options,
            onResponse: handleResponse
        )
    }
}