// Package primandproper.platform.comments.v1 is the wire schema for the
// discussion half of a product: what somebody said, about something the
// application owns, possibly in reply to something else somebody said.
//
// Every method on comments.Store is here but two, and those two are
// bulk erasure — DeleteCommentsForTarget and DeleteCommentsByAuthor — and the
// service comment at the bottom of this file says why neither has an RPC.
//
// This file is shipped inside the published Go module, and it is the file
// itself that is shipped -- not a copy for you to keep in sync. A consumer puts
// the module's proto directories on protoc's path and imports this file by its
// canonical name, exactly as identity.proto and filtering.proto already work:
//
//	PLATFORM_PROTO := $(shell go list -m -f '{{.Dir}}' github.com/primandproper/platform-go/v14)
//
//	protoc --proto_path proto/ \
//	    --proto_path $(PLATFORM_PROTO)/comments/proto \
//	    --proto_path $(PLATFORM_PROTO)/filtering/proto \
//	    --go_opt=Mprimandproper/platform/comments/v1/comments.proto=github.com/primandproper/platform-go/v14/comments/commentspb \
//	    $(CONSUMER_PROTO_FILES)   # the platform files deliberately absent from that list
//
// Field numbers are the compatibility promise, across every language a consumer
// generates into. Numbers are never reused and never repurposed: a field that
// goes away is reserved.
//
// # target type is a string, and will not become an enum
//
// [CommentTarget.type] is an opaque string everywhere it appears. The set of
// values is the consumer's catalog -- comments.Targets, supplied through
// WithTargets because "which kinds of thing can be commented on" is an
// application fact and this library has none -- and a generated enum would put
// that vocabulary on this module's release cadence. Adding a "newsletter" target
// would become a platform-go release.
//
// It is the same ruling issuereports.Kind and webhooks' event types are under,
// and comments' own documentation calls its catalog "the webhooks event
// catalog's idea applied to a second problem," so the three agree by
// construction. What a client gets instead of compile-time checking is a
// refusal: a target type outside the catalog is rejected at the write with
// comments.ErrUnknownTargetType rather than accepted into a comment that no
// view will ever list.
//
// The existence check does not cross the wire either, and could not. A target
// definition optionally carries a Go func the consumer registers, which reads
// the consumer's own table on the consumer's own connection; the RPC calls the
// store, the store runs the check, and comments.ErrTargetNotFound is what comes
// back. There is nothing about it for a schema to describe.
//
// # What is not here, and why
//
// No scope field, anywhere, and the name is reserved so there cannot be one. A
// scope a client could name is a cross-tenant read hiding behind a request
// field -- on this surface, a read of what another tenant's users have been
// saying to each other. It comes off the principal the consumer's interceptor
// put on the context, and every statement behind these RPCs binds it, so a
// comment in another tenant's scope reads as one that does not exist.
//
// Reserving the name rather than only saying so is audit.proto's pattern and is
// the half that holds: `reserved "scope";` is a schema protoc refuses to accept
// a scope field into, in this repository and in a consumer's fork of the file
// alike, whereas a comment is a request to the next author. It is reserved on
// every message in this file, responses included -- every row a response
// returns belongs to the scope the connection resolved, so the field would be
// telling a client something it supplied.
//
// See identity.proto, which says the underlying rule at greater length.
//
// No author on any input. [CommentInput] and [UpdateCommentRequest] reserve the
// name for the same reason [CommentInput] reserves scope: authorship a caller
// could name is authorship that says whatever the caller wanted it to, and the
// one thing a comment is is a sentence attributed to somebody. It is filled
// from the principal the consumer's interceptor resolved, on the way in, and it
// is read back on [Comment] like any other stored fact.
//
// No id on [CommentInput]. comments.Store assigns one where the caller left it
// empty, and a client-chosen identifier on this surface would be a client able
// to collide with a row it cannot see -- which is a unique-key violation
// answered 500, not a refusal that says anything useful.
//
// No target on an update. The store's own write assigns the body and nothing
// else, because the target is what the comment is about, the parent is which
// conversation it is in, and the author is who said it. A message that carried
// them would describe an edit this schema's server cannot perform.
//
// # include_archived is a request and not an instruction
//
// Every paged read here carries a QueryFilter, and its include_archived says
// "give me the removed rows too". It is a field on a message a client fills in,
// so it is a request the server rules on rather than a switch it obeys: a caller
// holding comments.archive gets the comments a moderator took out of the
// discussion, and for everybody else the field is cleared before the read and
// the page is the live discussion.
//
// It is cleared and not refused. A read that failed because the caller asked for
// too much turns a console's checkbox into an error, and a client cannot tell
// that refusal from a malformed filter; the page a caller gets is the page they
// would have got had they never set the field.
//
// The grant is comments.archive rather than comments.read or comments.moderate
// because removing something somebody said is its own act with its own grant,
// and a read that hands the removed text back under a lighter one makes that
// split a name. The same rule, under each surface's own archive grant, is in
// issuereports.proto, waitlists.proto and settings.proto.

// DO NOT EDIT.
// swift-format-ignore-file
// swiftlint:disable all
//
// Generated by the gRPC Swift generator plugin for the protocol buffer compiler.
// Source: primandproper/platform/comments/v1/comments.proto
//
// For information on using the generated types, please see the documentation:
//   https://github.com/grpc/grpc-swift

import GRPCCore
import GRPCProtobuf

// MARK: - primandproper.platform.comments.v1.CommentsService

/// Namespace containing generated types for the "primandproper.platform.comments.v1.CommentsService" service.
@available(macOS 15.0, iOS 18.0, watchOS 11.0, tvOS 18.0, visionOS 2.0, *)
public enum Primandproper_Platform_Comments_V1_CommentsService: Sendable {
    /// Service descriptor for the "primandproper.platform.comments.v1.CommentsService" service.
    public static let descriptor = GRPCCore.ServiceDescriptor(fullyQualifiedService: "primandproper.platform.comments.v1.CommentsService")
    /// Namespace for method metadata.
    public enum Method: Sendable {
        /// Namespace for "CreateComment" metadata.
        public enum CreateComment: Sendable {
            /// Request type for "CreateComment".
            public typealias Input = Primandproper_Platform_Comments_V1_CreateCommentRequest
            /// Response type for "CreateComment".
            public typealias Output = Primandproper_Platform_Comments_V1_CreateCommentResponse
            /// Descriptor for "CreateComment".
            public static let descriptor = GRPCCore.MethodDescriptor(
                service: GRPCCore.ServiceDescriptor(fullyQualifiedService: "primandproper.platform.comments.v1.CommentsService"),
                method: "CreateComment",
                type: .unary
            )
        }
        /// Namespace for "GetComment" metadata.
        public enum GetComment: Sendable {
            /// Request type for "GetComment".
            public typealias Input = Primandproper_Platform_Comments_V1_GetCommentRequest
            /// Response type for "GetComment".
            public typealias Output = Primandproper_Platform_Comments_V1_GetCommentResponse
            /// Descriptor for "GetComment".
            public static let descriptor = GRPCCore.MethodDescriptor(
                service: GRPCCore.ServiceDescriptor(fullyQualifiedService: "primandproper.platform.comments.v1.CommentsService"),
                method: "GetComment",
                type: .unary
            )
        }
        /// Namespace for "ListRootComments" metadata.
        public enum ListRootComments: Sendable {
            /// Request type for "ListRootComments".
            public typealias Input = Primandproper_Platform_Comments_V1_ListRootCommentsRequest
            /// Response type for "ListRootComments".
            public typealias Output = Primandproper_Platform_Comments_V1_ListRootCommentsResponse
            /// Descriptor for "ListRootComments".
            public static let descriptor = GRPCCore.MethodDescriptor(
                service: GRPCCore.ServiceDescriptor(fullyQualifiedService: "primandproper.platform.comments.v1.CommentsService"),
                method: "ListRootComments",
                type: .unary
            )
        }
        /// Namespace for "ListReplies" metadata.
        public enum ListReplies: Sendable {
            /// Request type for "ListReplies".
            public typealias Input = Primandproper_Platform_Comments_V1_ListRepliesRequest
            /// Response type for "ListReplies".
            public typealias Output = Primandproper_Platform_Comments_V1_ListRepliesResponse
            /// Descriptor for "ListReplies".
            public static let descriptor = GRPCCore.MethodDescriptor(
                service: GRPCCore.ServiceDescriptor(fullyQualifiedService: "primandproper.platform.comments.v1.CommentsService"),
                method: "ListReplies",
                type: .unary
            )
        }
        /// Namespace for "ListCommentsByTargetType" metadata.
        public enum ListCommentsByTargetType: Sendable {
            /// Request type for "ListCommentsByTargetType".
            public typealias Input = Primandproper_Platform_Comments_V1_ListCommentsByTargetTypeRequest
            /// Response type for "ListCommentsByTargetType".
            public typealias Output = Primandproper_Platform_Comments_V1_ListCommentsByTargetTypeResponse
            /// Descriptor for "ListCommentsByTargetType".
            public static let descriptor = GRPCCore.MethodDescriptor(
                service: GRPCCore.ServiceDescriptor(fullyQualifiedService: "primandproper.platform.comments.v1.CommentsService"),
                method: "ListCommentsByTargetType",
                type: .unary
            )
        }
        /// Namespace for "ListCommentsByAuthor" metadata.
        public enum ListCommentsByAuthor: Sendable {
            /// Request type for "ListCommentsByAuthor".
            public typealias Input = Primandproper_Platform_Comments_V1_ListCommentsByAuthorRequest
            /// Response type for "ListCommentsByAuthor".
            public typealias Output = Primandproper_Platform_Comments_V1_ListCommentsByAuthorResponse
            /// Descriptor for "ListCommentsByAuthor".
            public static let descriptor = GRPCCore.MethodDescriptor(
                service: GRPCCore.ServiceDescriptor(fullyQualifiedService: "primandproper.platform.comments.v1.CommentsService"),
                method: "ListCommentsByAuthor",
                type: .unary
            )
        }
        /// Namespace for "UpdateComment" metadata.
        public enum UpdateComment: Sendable {
            /// Request type for "UpdateComment".
            public typealias Input = Primandproper_Platform_Comments_V1_UpdateCommentRequest
            /// Response type for "UpdateComment".
            public typealias Output = Primandproper_Platform_Comments_V1_UpdateCommentResponse
            /// Descriptor for "UpdateComment".
            public static let descriptor = GRPCCore.MethodDescriptor(
                service: GRPCCore.ServiceDescriptor(fullyQualifiedService: "primandproper.platform.comments.v1.CommentsService"),
                method: "UpdateComment",
                type: .unary
            )
        }
        /// Namespace for "ArchiveComment" metadata.
        public enum ArchiveComment: Sendable {
            /// Request type for "ArchiveComment".
            public typealias Input = Primandproper_Platform_Comments_V1_ArchiveCommentRequest
            /// Response type for "ArchiveComment".
            public typealias Output = Primandproper_Platform_Comments_V1_ArchiveCommentResponse
            /// Descriptor for "ArchiveComment".
            public static let descriptor = GRPCCore.MethodDescriptor(
                service: GRPCCore.ServiceDescriptor(fullyQualifiedService: "primandproper.platform.comments.v1.CommentsService"),
                method: "ArchiveComment",
                type: .unary
            )
        }
        /// Descriptors for all methods in the "primandproper.platform.comments.v1.CommentsService" service.
        public static let descriptors: [GRPCCore.MethodDescriptor] = [
            CreateComment.descriptor,
            GetComment.descriptor,
            ListRootComments.descriptor,
            ListReplies.descriptor,
            ListCommentsByTargetType.descriptor,
            ListCommentsByAuthor.descriptor,
            UpdateComment.descriptor,
            ArchiveComment.descriptor
        ]
    }
}

@available(macOS 15.0, iOS 18.0, watchOS 11.0, tvOS 18.0, visionOS 2.0, *)
extension GRPCCore.ServiceDescriptor {
    /// Service descriptor for the "primandproper.platform.comments.v1.CommentsService" service.
    public static let primandproper_platform_comments_v1_CommentsService = GRPCCore.ServiceDescriptor(fullyQualifiedService: "primandproper.platform.comments.v1.CommentsService")
}

// MARK: primandproper.platform.comments.v1.CommentsService (client)

@available(macOS 15.0, iOS 18.0, watchOS 11.0, tvOS 18.0, visionOS 2.0, *)
extension Primandproper_Platform_Comments_V1_CommentsService {
    /// Generated client protocol for the "primandproper.platform.comments.v1.CommentsService" service.
    ///
    /// You don't need to implement this protocol directly, use the generated
    /// implementation, ``Client``.
    ///
    /// > Source IDL Documentation:
    /// >
    /// > CommentsService is one noun and its whole lifecycle: write a comment, read
    /// > one, page a discussion, page a person's or a target type's, edit a body,
    /// > archive a row.
    /// > 
    /// > Every comments.Store method but the bulk erasures, each behind a grant and
    /// > each acting only within the tenant the caller's principal names.
    /// > 
    /// > The two absences are the bulk erasures, and they are one case rather than
    /// > two. DeleteCommentsForTarget is called from the transaction that removes the
    /// > thing being discussed -- that is the whole of what the store's Tx parameter
    /// > is for, and the package's dangling-target ruling names this method as the
    /// > consumer's only fix. DeleteCommentsByAuthor is the right-to-be-forgotten
    /// > path, called by comments/privacy's dataprivacy.Eraser inside the transaction
    /// > that destroys the rest of a subject's footprint. Both are hard deletes of
    /// > everything matching, archived rows included, and both exist to commit with
    /// > somebody else's write; an RPC moves them into a transaction of their own, at
    /// > a moment the caller does not choose, so the target is gone and its comments
    /// > are not, or a subject is erased everywhere but here. It is the same fact
    /// > audit.Recorder states about an audit entry: a record that can commit while
    /// > the change it describes rolls back is not a record of what happened, and no
    /// > amount of retrying fixes it after the fact.
    /// > 
    /// > A moderator removing one comment is not that case and has ArchiveComment.
    public protocol ClientProtocol: Sendable {
        /// Call the "CreateComment" method.
        ///
        /// - Parameters:
        ///   - request: A request containing a single `Primandproper_Platform_Comments_V1_CreateCommentRequest` message.
        ///   - serializer: A serializer for `Primandproper_Platform_Comments_V1_CreateCommentRequest` messages.
        ///   - deserializer: A deserializer for `Primandproper_Platform_Comments_V1_CreateCommentResponse` messages.
        ///   - options: Options to apply to this RPC.
        ///   - handleResponse: A closure which handles the response and returns its result to
        ///       the caller. Returning from the closure will cancel the RPC if it hasn't
        ///       already finished.
        /// - Returns: The result of `handleResponse`.
        func createComment<Result>(
            request: GRPCCore.ClientRequest<Primandproper_Platform_Comments_V1_CreateCommentRequest>,
            serializer: some GRPCCore.MessageSerializer<Primandproper_Platform_Comments_V1_CreateCommentRequest>,
            deserializer: some GRPCCore.MessageDeserializer<Primandproper_Platform_Comments_V1_CreateCommentResponse>,
            options: GRPCCore.CallOptions,
            onResponse handleResponse: @Sendable @escaping (GRPCCore.ClientResponse<Primandproper_Platform_Comments_V1_CreateCommentResponse>) async throws -> Result
        ) async throws -> Result where Result: Sendable

        /// Call the "GetComment" method.
        ///
        /// - Parameters:
        ///   - request: A request containing a single `Primandproper_Platform_Comments_V1_GetCommentRequest` message.
        ///   - serializer: A serializer for `Primandproper_Platform_Comments_V1_GetCommentRequest` messages.
        ///   - deserializer: A deserializer for `Primandproper_Platform_Comments_V1_GetCommentResponse` messages.
        ///   - options: Options to apply to this RPC.
        ///   - handleResponse: A closure which handles the response and returns its result to
        ///       the caller. Returning from the closure will cancel the RPC if it hasn't
        ///       already finished.
        /// - Returns: The result of `handleResponse`.
        func getComment<Result>(
            request: GRPCCore.ClientRequest<Primandproper_Platform_Comments_V1_GetCommentRequest>,
            serializer: some GRPCCore.MessageSerializer<Primandproper_Platform_Comments_V1_GetCommentRequest>,
            deserializer: some GRPCCore.MessageDeserializer<Primandproper_Platform_Comments_V1_GetCommentResponse>,
            options: GRPCCore.CallOptions,
            onResponse handleResponse: @Sendable @escaping (GRPCCore.ClientResponse<Primandproper_Platform_Comments_V1_GetCommentResponse>) async throws -> Result
        ) async throws -> Result where Result: Sendable

        /// Call the "ListRootComments" method.
        ///
        /// - Parameters:
        ///   - request: A request containing a single `Primandproper_Platform_Comments_V1_ListRootCommentsRequest` message.
        ///   - serializer: A serializer for `Primandproper_Platform_Comments_V1_ListRootCommentsRequest` messages.
        ///   - deserializer: A deserializer for `Primandproper_Platform_Comments_V1_ListRootCommentsResponse` messages.
        ///   - options: Options to apply to this RPC.
        ///   - handleResponse: A closure which handles the response and returns its result to
        ///       the caller. Returning from the closure will cancel the RPC if it hasn't
        ///       already finished.
        /// - Returns: The result of `handleResponse`.
        func listRootComments<Result>(
            request: GRPCCore.ClientRequest<Primandproper_Platform_Comments_V1_ListRootCommentsRequest>,
            serializer: some GRPCCore.MessageSerializer<Primandproper_Platform_Comments_V1_ListRootCommentsRequest>,
            deserializer: some GRPCCore.MessageDeserializer<Primandproper_Platform_Comments_V1_ListRootCommentsResponse>,
            options: GRPCCore.CallOptions,
            onResponse handleResponse: @Sendable @escaping (GRPCCore.ClientResponse<Primandproper_Platform_Comments_V1_ListRootCommentsResponse>) async throws -> Result
        ) async throws -> Result where Result: Sendable

        /// Call the "ListReplies" method.
        ///
        /// - Parameters:
        ///   - request: A request containing a single `Primandproper_Platform_Comments_V1_ListRepliesRequest` message.
        ///   - serializer: A serializer for `Primandproper_Platform_Comments_V1_ListRepliesRequest` messages.
        ///   - deserializer: A deserializer for `Primandproper_Platform_Comments_V1_ListRepliesResponse` messages.
        ///   - options: Options to apply to this RPC.
        ///   - handleResponse: A closure which handles the response and returns its result to
        ///       the caller. Returning from the closure will cancel the RPC if it hasn't
        ///       already finished.
        /// - Returns: The result of `handleResponse`.
        func listReplies<Result>(
            request: GRPCCore.ClientRequest<Primandproper_Platform_Comments_V1_ListRepliesRequest>,
            serializer: some GRPCCore.MessageSerializer<Primandproper_Platform_Comments_V1_ListRepliesRequest>,
            deserializer: some GRPCCore.MessageDeserializer<Primandproper_Platform_Comments_V1_ListRepliesResponse>,
            options: GRPCCore.CallOptions,
            onResponse handleResponse: @Sendable @escaping (GRPCCore.ClientResponse<Primandproper_Platform_Comments_V1_ListRepliesResponse>) async throws -> Result
        ) async throws -> Result where Result: Sendable

        /// Call the "ListCommentsByTargetType" method.
        ///
        /// - Parameters:
        ///   - request: A request containing a single `Primandproper_Platform_Comments_V1_ListCommentsByTargetTypeRequest` message.
        ///   - serializer: A serializer for `Primandproper_Platform_Comments_V1_ListCommentsByTargetTypeRequest` messages.
        ///   - deserializer: A deserializer for `Primandproper_Platform_Comments_V1_ListCommentsByTargetTypeResponse` messages.
        ///   - options: Options to apply to this RPC.
        ///   - handleResponse: A closure which handles the response and returns its result to
        ///       the caller. Returning from the closure will cancel the RPC if it hasn't
        ///       already finished.
        /// - Returns: The result of `handleResponse`.
        func listCommentsByTargetType<Result>(
            request: GRPCCore.ClientRequest<Primandproper_Platform_Comments_V1_ListCommentsByTargetTypeRequest>,
            serializer: some GRPCCore.MessageSerializer<Primandproper_Platform_Comments_V1_ListCommentsByTargetTypeRequest>,
            deserializer: some GRPCCore.MessageDeserializer<Primandproper_Platform_Comments_V1_ListCommentsByTargetTypeResponse>,
            options: GRPCCore.CallOptions,
            onResponse handleResponse: @Sendable @escaping (GRPCCore.ClientResponse<Primandproper_Platform_Comments_V1_ListCommentsByTargetTypeResponse>) async throws -> Result
        ) async throws -> Result where Result: Sendable

        /// Call the "ListCommentsByAuthor" method.
        ///
        /// - Parameters:
        ///   - request: A request containing a single `Primandproper_Platform_Comments_V1_ListCommentsByAuthorRequest` message.
        ///   - serializer: A serializer for `Primandproper_Platform_Comments_V1_ListCommentsByAuthorRequest` messages.
        ///   - deserializer: A deserializer for `Primandproper_Platform_Comments_V1_ListCommentsByAuthorResponse` messages.
        ///   - options: Options to apply to this RPC.
        ///   - handleResponse: A closure which handles the response and returns its result to
        ///       the caller. Returning from the closure will cancel the RPC if it hasn't
        ///       already finished.
        /// - Returns: The result of `handleResponse`.
        func listCommentsByAuthor<Result>(
            request: GRPCCore.ClientRequest<Primandproper_Platform_Comments_V1_ListCommentsByAuthorRequest>,
            serializer: some GRPCCore.MessageSerializer<Primandproper_Platform_Comments_V1_ListCommentsByAuthorRequest>,
            deserializer: some GRPCCore.MessageDeserializer<Primandproper_Platform_Comments_V1_ListCommentsByAuthorResponse>,
            options: GRPCCore.CallOptions,
            onResponse handleResponse: @Sendable @escaping (GRPCCore.ClientResponse<Primandproper_Platform_Comments_V1_ListCommentsByAuthorResponse>) async throws -> Result
        ) async throws -> Result where Result: Sendable

        /// Call the "UpdateComment" method.
        ///
        /// - Parameters:
        ///   - request: A request containing a single `Primandproper_Platform_Comments_V1_UpdateCommentRequest` message.
        ///   - serializer: A serializer for `Primandproper_Platform_Comments_V1_UpdateCommentRequest` messages.
        ///   - deserializer: A deserializer for `Primandproper_Platform_Comments_V1_UpdateCommentResponse` messages.
        ///   - options: Options to apply to this RPC.
        ///   - handleResponse: A closure which handles the response and returns its result to
        ///       the caller. Returning from the closure will cancel the RPC if it hasn't
        ///       already finished.
        /// - Returns: The result of `handleResponse`.
        func updateComment<Result>(
            request: GRPCCore.ClientRequest<Primandproper_Platform_Comments_V1_UpdateCommentRequest>,
            serializer: some GRPCCore.MessageSerializer<Primandproper_Platform_Comments_V1_UpdateCommentRequest>,
            deserializer: some GRPCCore.MessageDeserializer<Primandproper_Platform_Comments_V1_UpdateCommentResponse>,
            options: GRPCCore.CallOptions,
            onResponse handleResponse: @Sendable @escaping (GRPCCore.ClientResponse<Primandproper_Platform_Comments_V1_UpdateCommentResponse>) async throws -> Result
        ) async throws -> Result where Result: Sendable

        /// Call the "ArchiveComment" method.
        ///
        /// - Parameters:
        ///   - request: A request containing a single `Primandproper_Platform_Comments_V1_ArchiveCommentRequest` message.
        ///   - serializer: A serializer for `Primandproper_Platform_Comments_V1_ArchiveCommentRequest` messages.
        ///   - deserializer: A deserializer for `Primandproper_Platform_Comments_V1_ArchiveCommentResponse` messages.
        ///   - options: Options to apply to this RPC.
        ///   - handleResponse: A closure which handles the response and returns its result to
        ///       the caller. Returning from the closure will cancel the RPC if it hasn't
        ///       already finished.
        /// - Returns: The result of `handleResponse`.
        func archiveComment<Result>(
            request: GRPCCore.ClientRequest<Primandproper_Platform_Comments_V1_ArchiveCommentRequest>,
            serializer: some GRPCCore.MessageSerializer<Primandproper_Platform_Comments_V1_ArchiveCommentRequest>,
            deserializer: some GRPCCore.MessageDeserializer<Primandproper_Platform_Comments_V1_ArchiveCommentResponse>,
            options: GRPCCore.CallOptions,
            onResponse handleResponse: @Sendable @escaping (GRPCCore.ClientResponse<Primandproper_Platform_Comments_V1_ArchiveCommentResponse>) async throws -> Result
        ) async throws -> Result where Result: Sendable
    }

    /// Generated client for the "primandproper.platform.comments.v1.CommentsService" service.
    ///
    /// The ``Client`` provides an implementation of ``ClientProtocol`` which wraps
    /// a `GRPCCore.GRPCCClient`. The underlying `GRPCClient` provides the long-lived
    /// means of communication with the remote peer.
    ///
    /// > Source IDL Documentation:
    /// >
    /// > CommentsService is one noun and its whole lifecycle: write a comment, read
    /// > one, page a discussion, page a person's or a target type's, edit a body,
    /// > archive a row.
    /// > 
    /// > Every comments.Store method but the bulk erasures, each behind a grant and
    /// > each acting only within the tenant the caller's principal names.
    /// > 
    /// > The two absences are the bulk erasures, and they are one case rather than
    /// > two. DeleteCommentsForTarget is called from the transaction that removes the
    /// > thing being discussed -- that is the whole of what the store's Tx parameter
    /// > is for, and the package's dangling-target ruling names this method as the
    /// > consumer's only fix. DeleteCommentsByAuthor is the right-to-be-forgotten
    /// > path, called by comments/privacy's dataprivacy.Eraser inside the transaction
    /// > that destroys the rest of a subject's footprint. Both are hard deletes of
    /// > everything matching, archived rows included, and both exist to commit with
    /// > somebody else's write; an RPC moves them into a transaction of their own, at
    /// > a moment the caller does not choose, so the target is gone and its comments
    /// > are not, or a subject is erased everywhere but here. It is the same fact
    /// > audit.Recorder states about an audit entry: a record that can commit while
    /// > the change it describes rolls back is not a record of what happened, and no
    /// > amount of retrying fixes it after the fact.
    /// > 
    /// > A moderator removing one comment is not that case and has ArchiveComment.
    public struct Client<Transport>: ClientProtocol where Transport: GRPCCore.ClientTransport {
        private let client: GRPCCore.GRPCClient<Transport>

        /// Creates a new client wrapping the provided `GRPCCore.GRPCClient`.
        ///
        /// - Parameters:
        ///   - client: A `GRPCCore.GRPCClient` providing a communication channel to the service.
        public init(wrapping client: GRPCCore.GRPCClient<Transport>) {
            self.client = client
        }

        /// Call the "CreateComment" method.
        ///
        /// - Parameters:
        ///   - request: A request containing a single `Primandproper_Platform_Comments_V1_CreateCommentRequest` message.
        ///   - serializer: A serializer for `Primandproper_Platform_Comments_V1_CreateCommentRequest` messages.
        ///   - deserializer: A deserializer for `Primandproper_Platform_Comments_V1_CreateCommentResponse` messages.
        ///   - options: Options to apply to this RPC.
        ///   - handleResponse: A closure which handles the response and returns its result to
        ///       the caller. Returning from the closure will cancel the RPC if it hasn't
        ///       already finished.
        /// - Returns: The result of `handleResponse`.
        public func createComment<Result>(
            request: GRPCCore.ClientRequest<Primandproper_Platform_Comments_V1_CreateCommentRequest>,
            serializer: some GRPCCore.MessageSerializer<Primandproper_Platform_Comments_V1_CreateCommentRequest>,
            deserializer: some GRPCCore.MessageDeserializer<Primandproper_Platform_Comments_V1_CreateCommentResponse>,
            options: GRPCCore.CallOptions = .defaults,
            onResponse handleResponse: @Sendable @escaping (GRPCCore.ClientResponse<Primandproper_Platform_Comments_V1_CreateCommentResponse>) async throws -> Result = { response in
                try response.message
            }
        ) async throws -> Result where Result: Sendable {
            try await self.client.unary(
                request: request,
                descriptor: Primandproper_Platform_Comments_V1_CommentsService.Method.CreateComment.descriptor,
                serializer: serializer,
                deserializer: deserializer,
                options: options,
                onResponse: handleResponse
            )
        }

        /// Call the "GetComment" method.
        ///
        /// - Parameters:
        ///   - request: A request containing a single `Primandproper_Platform_Comments_V1_GetCommentRequest` message.
        ///   - serializer: A serializer for `Primandproper_Platform_Comments_V1_GetCommentRequest` messages.
        ///   - deserializer: A deserializer for `Primandproper_Platform_Comments_V1_GetCommentResponse` messages.
        ///   - options: Options to apply to this RPC.
        ///   - handleResponse: A closure which handles the response and returns its result to
        ///       the caller. Returning from the closure will cancel the RPC if it hasn't
        ///       already finished.
        /// - Returns: The result of `handleResponse`.
        public func getComment<Result>(
            request: GRPCCore.ClientRequest<Primandproper_Platform_Comments_V1_GetCommentRequest>,
            serializer: some GRPCCore.MessageSerializer<Primandproper_Platform_Comments_V1_GetCommentRequest>,
            deserializer: some GRPCCore.MessageDeserializer<Primandproper_Platform_Comments_V1_GetCommentResponse>,
            options: GRPCCore.CallOptions = .defaults,
            onResponse handleResponse: @Sendable @escaping (GRPCCore.ClientResponse<Primandproper_Platform_Comments_V1_GetCommentResponse>) async throws -> Result = { response in
                try response.message
            }
        ) async throws -> Result where Result: Sendable {
            try await self.client.unary(
                request: request,
                descriptor: Primandproper_Platform_Comments_V1_CommentsService.Method.GetComment.descriptor,
                serializer: serializer,
                deserializer: deserializer,
                options: options,
                onResponse: handleResponse
            )
        }

        /// Call the "ListRootComments" method.
        ///
        /// - Parameters:
        ///   - request: A request containing a single `Primandproper_Platform_Comments_V1_ListRootCommentsRequest` message.
        ///   - serializer: A serializer for `Primandproper_Platform_Comments_V1_ListRootCommentsRequest` messages.
        ///   - deserializer: A deserializer for `Primandproper_Platform_Comments_V1_ListRootCommentsResponse` messages.
        ///   - options: Options to apply to this RPC.
        ///   - handleResponse: A closure which handles the response and returns its result to
        ///       the caller. Returning from the closure will cancel the RPC if it hasn't
        ///       already finished.
        /// - Returns: The result of `handleResponse`.
        public func listRootComments<Result>(
            request: GRPCCore.ClientRequest<Primandproper_Platform_Comments_V1_ListRootCommentsRequest>,
            serializer: some GRPCCore.MessageSerializer<Primandproper_Platform_Comments_V1_ListRootCommentsRequest>,
            deserializer: some GRPCCore.MessageDeserializer<Primandproper_Platform_Comments_V1_ListRootCommentsResponse>,
            options: GRPCCore.CallOptions = .defaults,
            onResponse handleResponse: @Sendable @escaping (GRPCCore.ClientResponse<Primandproper_Platform_Comments_V1_ListRootCommentsResponse>) async throws -> Result = { response in
                try response.message
            }
        ) async throws -> Result where Result: Sendable {
            try await self.client.unary(
                request: request,
                descriptor: Primandproper_Platform_Comments_V1_CommentsService.Method.ListRootComments.descriptor,
                serializer: serializer,
                deserializer: deserializer,
                options: options,
                onResponse: handleResponse
            )
        }

        /// Call the "ListReplies" method.
        ///
        /// - Parameters:
        ///   - request: A request containing a single `Primandproper_Platform_Comments_V1_ListRepliesRequest` message.
        ///   - serializer: A serializer for `Primandproper_Platform_Comments_V1_ListRepliesRequest` messages.
        ///   - deserializer: A deserializer for `Primandproper_Platform_Comments_V1_ListRepliesResponse` messages.
        ///   - options: Options to apply to this RPC.
        ///   - handleResponse: A closure which handles the response and returns its result to
        ///       the caller. Returning from the closure will cancel the RPC if it hasn't
        ///       already finished.
        /// - Returns: The result of `handleResponse`.
        public func listReplies<Result>(
            request: GRPCCore.ClientRequest<Primandproper_Platform_Comments_V1_ListRepliesRequest>,
            serializer: some GRPCCore.MessageSerializer<Primandproper_Platform_Comments_V1_ListRepliesRequest>,
            deserializer: some GRPCCore.MessageDeserializer<Primandproper_Platform_Comments_V1_ListRepliesResponse>,
            options: GRPCCore.CallOptions = .defaults,
            onResponse handleResponse: @Sendable @escaping (GRPCCore.ClientResponse<Primandproper_Platform_Comments_V1_ListRepliesResponse>) async throws -> Result = { response in
                try response.message
            }
        ) async throws -> Result where Result: Sendable {
            try await self.client.unary(
                request: request,
                descriptor: Primandproper_Platform_Comments_V1_CommentsService.Method.ListReplies.descriptor,
                serializer: serializer,
                deserializer: deserializer,
                options: options,
                onResponse: handleResponse
            )
        }

        /// Call the "ListCommentsByTargetType" method.
        ///
        /// - Parameters:
        ///   - request: A request containing a single `Primandproper_Platform_Comments_V1_ListCommentsByTargetTypeRequest` message.
        ///   - serializer: A serializer for `Primandproper_Platform_Comments_V1_ListCommentsByTargetTypeRequest` messages.
        ///   - deserializer: A deserializer for `Primandproper_Platform_Comments_V1_ListCommentsByTargetTypeResponse` messages.
        ///   - options: Options to apply to this RPC.
        ///   - handleResponse: A closure which handles the response and returns its result to
        ///       the caller. Returning from the closure will cancel the RPC if it hasn't
        ///       already finished.
        /// - Returns: The result of `handleResponse`.
        public func listCommentsByTargetType<Result>(
            request: GRPCCore.ClientRequest<Primandproper_Platform_Comments_V1_ListCommentsByTargetTypeRequest>,
            serializer: some GRPCCore.MessageSerializer<Primandproper_Platform_Comments_V1_ListCommentsByTargetTypeRequest>,
            deserializer: some GRPCCore.MessageDeserializer<Primandproper_Platform_Comments_V1_ListCommentsByTargetTypeResponse>,
            options: GRPCCore.CallOptions = .defaults,
            onResponse handleResponse: @Sendable @escaping (GRPCCore.ClientResponse<Primandproper_Platform_Comments_V1_ListCommentsByTargetTypeResponse>) async throws -> Result = { response in
                try response.message
            }
        ) async throws -> Result where Result: Sendable {
            try await self.client.unary(
                request: request,
                descriptor: Primandproper_Platform_Comments_V1_CommentsService.Method.ListCommentsByTargetType.descriptor,
                serializer: serializer,
                deserializer: deserializer,
                options: options,
                onResponse: handleResponse
            )
        }

        /// Call the "ListCommentsByAuthor" method.
        ///
        /// - Parameters:
        ///   - request: A request containing a single `Primandproper_Platform_Comments_V1_ListCommentsByAuthorRequest` message.
        ///   - serializer: A serializer for `Primandproper_Platform_Comments_V1_ListCommentsByAuthorRequest` messages.
        ///   - deserializer: A deserializer for `Primandproper_Platform_Comments_V1_ListCommentsByAuthorResponse` messages.
        ///   - options: Options to apply to this RPC.
        ///   - handleResponse: A closure which handles the response and returns its result to
        ///       the caller. Returning from the closure will cancel the RPC if it hasn't
        ///       already finished.
        /// - Returns: The result of `handleResponse`.
        public func listCommentsByAuthor<Result>(
            request: GRPCCore.ClientRequest<Primandproper_Platform_Comments_V1_ListCommentsByAuthorRequest>,
            serializer: some GRPCCore.MessageSerializer<Primandproper_Platform_Comments_V1_ListCommentsByAuthorRequest>,
            deserializer: some GRPCCore.MessageDeserializer<Primandproper_Platform_Comments_V1_ListCommentsByAuthorResponse>,
            options: GRPCCore.CallOptions = .defaults,
            onResponse handleResponse: @Sendable @escaping (GRPCCore.ClientResponse<Primandproper_Platform_Comments_V1_ListCommentsByAuthorResponse>) async throws -> Result = { response in
                try response.message
            }
        ) async throws -> Result where Result: Sendable {
            try await self.client.unary(
                request: request,
                descriptor: Primandproper_Platform_Comments_V1_CommentsService.Method.ListCommentsByAuthor.descriptor,
                serializer: serializer,
                deserializer: deserializer,
                options: options,
                onResponse: handleResponse
            )
        }

        /// Call the "UpdateComment" method.
        ///
        /// - Parameters:
        ///   - request: A request containing a single `Primandproper_Platform_Comments_V1_UpdateCommentRequest` message.
        ///   - serializer: A serializer for `Primandproper_Platform_Comments_V1_UpdateCommentRequest` messages.
        ///   - deserializer: A deserializer for `Primandproper_Platform_Comments_V1_UpdateCommentResponse` messages.
        ///   - options: Options to apply to this RPC.
        ///   - handleResponse: A closure which handles the response and returns its result to
        ///       the caller. Returning from the closure will cancel the RPC if it hasn't
        ///       already finished.
        /// - Returns: The result of `handleResponse`.
        public func updateComment<Result>(
            request: GRPCCore.ClientRequest<Primandproper_Platform_Comments_V1_UpdateCommentRequest>,
            serializer: some GRPCCore.MessageSerializer<Primandproper_Platform_Comments_V1_UpdateCommentRequest>,
            deserializer: some GRPCCore.MessageDeserializer<Primandproper_Platform_Comments_V1_UpdateCommentResponse>,
            options: GRPCCore.CallOptions = .defaults,
            onResponse handleResponse: @Sendable @escaping (GRPCCore.ClientResponse<Primandproper_Platform_Comments_V1_UpdateCommentResponse>) async throws -> Result = { response in
                try response.message
            }
        ) async throws -> Result where Result: Sendable {
            try await self.client.unary(
                request: request,
                descriptor: Primandproper_Platform_Comments_V1_CommentsService.Method.UpdateComment.descriptor,
                serializer: serializer,
                deserializer: deserializer,
                options: options,
                onResponse: handleResponse
            )
        }

        /// Call the "ArchiveComment" method.
        ///
        /// - Parameters:
        ///   - request: A request containing a single `Primandproper_Platform_Comments_V1_ArchiveCommentRequest` message.
        ///   - serializer: A serializer for `Primandproper_Platform_Comments_V1_ArchiveCommentRequest` messages.
        ///   - deserializer: A deserializer for `Primandproper_Platform_Comments_V1_ArchiveCommentResponse` messages.
        ///   - options: Options to apply to this RPC.
        ///   - handleResponse: A closure which handles the response and returns its result to
        ///       the caller. Returning from the closure will cancel the RPC if it hasn't
        ///       already finished.
        /// - Returns: The result of `handleResponse`.
        public func archiveComment<Result>(
            request: GRPCCore.ClientRequest<Primandproper_Platform_Comments_V1_ArchiveCommentRequest>,
            serializer: some GRPCCore.MessageSerializer<Primandproper_Platform_Comments_V1_ArchiveCommentRequest>,
            deserializer: some GRPCCore.MessageDeserializer<Primandproper_Platform_Comments_V1_ArchiveCommentResponse>,
            options: GRPCCore.CallOptions = .defaults,
            onResponse handleResponse: @Sendable @escaping (GRPCCore.ClientResponse<Primandproper_Platform_Comments_V1_ArchiveCommentResponse>) async throws -> Result = { response in
                try response.message
            }
        ) async throws -> Result where Result: Sendable {
            try await self.client.unary(
                request: request,
                descriptor: Primandproper_Platform_Comments_V1_CommentsService.Method.ArchiveComment.descriptor,
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
extension Primandproper_Platform_Comments_V1_CommentsService.ClientProtocol {
    /// Call the "CreateComment" method.
    ///
    /// - Parameters:
    ///   - request: A request containing a single `Primandproper_Platform_Comments_V1_CreateCommentRequest` message.
    ///   - options: Options to apply to this RPC.
    ///   - handleResponse: A closure which handles the response and returns its result to
    ///       the caller. Returning from the closure will cancel the RPC if it hasn't
    ///       already finished.
    /// - Returns: The result of `handleResponse`.
    public func createComment<Result>(
        request: GRPCCore.ClientRequest<Primandproper_Platform_Comments_V1_CreateCommentRequest>,
        options: GRPCCore.CallOptions = .defaults,
        onResponse handleResponse: @Sendable @escaping (GRPCCore.ClientResponse<Primandproper_Platform_Comments_V1_CreateCommentResponse>) async throws -> Result = { response in
            try response.message
        }
    ) async throws -> Result where Result: Sendable {
        try await self.createComment(
            request: request,
            serializer: GRPCProtobuf.ProtobufSerializer<Primandproper_Platform_Comments_V1_CreateCommentRequest>(),
            deserializer: GRPCProtobuf.ProtobufDeserializer<Primandproper_Platform_Comments_V1_CreateCommentResponse>(),
            options: options,
            onResponse: handleResponse
        )
    }

    /// Call the "GetComment" method.
    ///
    /// - Parameters:
    ///   - request: A request containing a single `Primandproper_Platform_Comments_V1_GetCommentRequest` message.
    ///   - options: Options to apply to this RPC.
    ///   - handleResponse: A closure which handles the response and returns its result to
    ///       the caller. Returning from the closure will cancel the RPC if it hasn't
    ///       already finished.
    /// - Returns: The result of `handleResponse`.
    public func getComment<Result>(
        request: GRPCCore.ClientRequest<Primandproper_Platform_Comments_V1_GetCommentRequest>,
        options: GRPCCore.CallOptions = .defaults,
        onResponse handleResponse: @Sendable @escaping (GRPCCore.ClientResponse<Primandproper_Platform_Comments_V1_GetCommentResponse>) async throws -> Result = { response in
            try response.message
        }
    ) async throws -> Result where Result: Sendable {
        try await self.getComment(
            request: request,
            serializer: GRPCProtobuf.ProtobufSerializer<Primandproper_Platform_Comments_V1_GetCommentRequest>(),
            deserializer: GRPCProtobuf.ProtobufDeserializer<Primandproper_Platform_Comments_V1_GetCommentResponse>(),
            options: options,
            onResponse: handleResponse
        )
    }

    /// Call the "ListRootComments" method.
    ///
    /// - Parameters:
    ///   - request: A request containing a single `Primandproper_Platform_Comments_V1_ListRootCommentsRequest` message.
    ///   - options: Options to apply to this RPC.
    ///   - handleResponse: A closure which handles the response and returns its result to
    ///       the caller. Returning from the closure will cancel the RPC if it hasn't
    ///       already finished.
    /// - Returns: The result of `handleResponse`.
    public func listRootComments<Result>(
        request: GRPCCore.ClientRequest<Primandproper_Platform_Comments_V1_ListRootCommentsRequest>,
        options: GRPCCore.CallOptions = .defaults,
        onResponse handleResponse: @Sendable @escaping (GRPCCore.ClientResponse<Primandproper_Platform_Comments_V1_ListRootCommentsResponse>) async throws -> Result = { response in
            try response.message
        }
    ) async throws -> Result where Result: Sendable {
        try await self.listRootComments(
            request: request,
            serializer: GRPCProtobuf.ProtobufSerializer<Primandproper_Platform_Comments_V1_ListRootCommentsRequest>(),
            deserializer: GRPCProtobuf.ProtobufDeserializer<Primandproper_Platform_Comments_V1_ListRootCommentsResponse>(),
            options: options,
            onResponse: handleResponse
        )
    }

    /// Call the "ListReplies" method.
    ///
    /// - Parameters:
    ///   - request: A request containing a single `Primandproper_Platform_Comments_V1_ListRepliesRequest` message.
    ///   - options: Options to apply to this RPC.
    ///   - handleResponse: A closure which handles the response and returns its result to
    ///       the caller. Returning from the closure will cancel the RPC if it hasn't
    ///       already finished.
    /// - Returns: The result of `handleResponse`.
    public func listReplies<Result>(
        request: GRPCCore.ClientRequest<Primandproper_Platform_Comments_V1_ListRepliesRequest>,
        options: GRPCCore.CallOptions = .defaults,
        onResponse handleResponse: @Sendable @escaping (GRPCCore.ClientResponse<Primandproper_Platform_Comments_V1_ListRepliesResponse>) async throws -> Result = { response in
            try response.message
        }
    ) async throws -> Result where Result: Sendable {
        try await self.listReplies(
            request: request,
            serializer: GRPCProtobuf.ProtobufSerializer<Primandproper_Platform_Comments_V1_ListRepliesRequest>(),
            deserializer: GRPCProtobuf.ProtobufDeserializer<Primandproper_Platform_Comments_V1_ListRepliesResponse>(),
            options: options,
            onResponse: handleResponse
        )
    }

    /// Call the "ListCommentsByTargetType" method.
    ///
    /// - Parameters:
    ///   - request: A request containing a single `Primandproper_Platform_Comments_V1_ListCommentsByTargetTypeRequest` message.
    ///   - options: Options to apply to this RPC.
    ///   - handleResponse: A closure which handles the response and returns its result to
    ///       the caller. Returning from the closure will cancel the RPC if it hasn't
    ///       already finished.
    /// - Returns: The result of `handleResponse`.
    public func listCommentsByTargetType<Result>(
        request: GRPCCore.ClientRequest<Primandproper_Platform_Comments_V1_ListCommentsByTargetTypeRequest>,
        options: GRPCCore.CallOptions = .defaults,
        onResponse handleResponse: @Sendable @escaping (GRPCCore.ClientResponse<Primandproper_Platform_Comments_V1_ListCommentsByTargetTypeResponse>) async throws -> Result = { response in
            try response.message
        }
    ) async throws -> Result where Result: Sendable {
        try await self.listCommentsByTargetType(
            request: request,
            serializer: GRPCProtobuf.ProtobufSerializer<Primandproper_Platform_Comments_V1_ListCommentsByTargetTypeRequest>(),
            deserializer: GRPCProtobuf.ProtobufDeserializer<Primandproper_Platform_Comments_V1_ListCommentsByTargetTypeResponse>(),
            options: options,
            onResponse: handleResponse
        )
    }

    /// Call the "ListCommentsByAuthor" method.
    ///
    /// - Parameters:
    ///   - request: A request containing a single `Primandproper_Platform_Comments_V1_ListCommentsByAuthorRequest` message.
    ///   - options: Options to apply to this RPC.
    ///   - handleResponse: A closure which handles the response and returns its result to
    ///       the caller. Returning from the closure will cancel the RPC if it hasn't
    ///       already finished.
    /// - Returns: The result of `handleResponse`.
    public func listCommentsByAuthor<Result>(
        request: GRPCCore.ClientRequest<Primandproper_Platform_Comments_V1_ListCommentsByAuthorRequest>,
        options: GRPCCore.CallOptions = .defaults,
        onResponse handleResponse: @Sendable @escaping (GRPCCore.ClientResponse<Primandproper_Platform_Comments_V1_ListCommentsByAuthorResponse>) async throws -> Result = { response in
            try response.message
        }
    ) async throws -> Result where Result: Sendable {
        try await self.listCommentsByAuthor(
            request: request,
            serializer: GRPCProtobuf.ProtobufSerializer<Primandproper_Platform_Comments_V1_ListCommentsByAuthorRequest>(),
            deserializer: GRPCProtobuf.ProtobufDeserializer<Primandproper_Platform_Comments_V1_ListCommentsByAuthorResponse>(),
            options: options,
            onResponse: handleResponse
        )
    }

    /// Call the "UpdateComment" method.
    ///
    /// - Parameters:
    ///   - request: A request containing a single `Primandproper_Platform_Comments_V1_UpdateCommentRequest` message.
    ///   - options: Options to apply to this RPC.
    ///   - handleResponse: A closure which handles the response and returns its result to
    ///       the caller. Returning from the closure will cancel the RPC if it hasn't
    ///       already finished.
    /// - Returns: The result of `handleResponse`.
    public func updateComment<Result>(
        request: GRPCCore.ClientRequest<Primandproper_Platform_Comments_V1_UpdateCommentRequest>,
        options: GRPCCore.CallOptions = .defaults,
        onResponse handleResponse: @Sendable @escaping (GRPCCore.ClientResponse<Primandproper_Platform_Comments_V1_UpdateCommentResponse>) async throws -> Result = { response in
            try response.message
        }
    ) async throws -> Result where Result: Sendable {
        try await self.updateComment(
            request: request,
            serializer: GRPCProtobuf.ProtobufSerializer<Primandproper_Platform_Comments_V1_UpdateCommentRequest>(),
            deserializer: GRPCProtobuf.ProtobufDeserializer<Primandproper_Platform_Comments_V1_UpdateCommentResponse>(),
            options: options,
            onResponse: handleResponse
        )
    }

    /// Call the "ArchiveComment" method.
    ///
    /// - Parameters:
    ///   - request: A request containing a single `Primandproper_Platform_Comments_V1_ArchiveCommentRequest` message.
    ///   - options: Options to apply to this RPC.
    ///   - handleResponse: A closure which handles the response and returns its result to
    ///       the caller. Returning from the closure will cancel the RPC if it hasn't
    ///       already finished.
    /// - Returns: The result of `handleResponse`.
    public func archiveComment<Result>(
        request: GRPCCore.ClientRequest<Primandproper_Platform_Comments_V1_ArchiveCommentRequest>,
        options: GRPCCore.CallOptions = .defaults,
        onResponse handleResponse: @Sendable @escaping (GRPCCore.ClientResponse<Primandproper_Platform_Comments_V1_ArchiveCommentResponse>) async throws -> Result = { response in
            try response.message
        }
    ) async throws -> Result where Result: Sendable {
        try await self.archiveComment(
            request: request,
            serializer: GRPCProtobuf.ProtobufSerializer<Primandproper_Platform_Comments_V1_ArchiveCommentRequest>(),
            deserializer: GRPCProtobuf.ProtobufDeserializer<Primandproper_Platform_Comments_V1_ArchiveCommentResponse>(),
            options: options,
            onResponse: handleResponse
        )
    }
}

// Helpers providing sugared APIs for 'ClientProtocol' methods.
@available(macOS 15.0, iOS 18.0, watchOS 11.0, tvOS 18.0, visionOS 2.0, *)
extension Primandproper_Platform_Comments_V1_CommentsService.ClientProtocol {
    /// Call the "CreateComment" method.
    ///
    /// - Parameters:
    ///   - message: request message to send.
    ///   - metadata: Additional metadata to send, defaults to empty.
    ///   - options: Options to apply to this RPC, defaults to `.defaults`.
    ///   - handleResponse: A closure which handles the response and returns its result to
    ///       the caller. Returning from the closure will cancel the RPC if it hasn't
    ///       already finished.
    /// - Returns: The result of `handleResponse`.
    public func createComment<Result>(
        _ message: Primandproper_Platform_Comments_V1_CreateCommentRequest,
        metadata: GRPCCore.Metadata = [:],
        options: GRPCCore.CallOptions = .defaults,
        onResponse handleResponse: @Sendable @escaping (GRPCCore.ClientResponse<Primandproper_Platform_Comments_V1_CreateCommentResponse>) async throws -> Result = { response in
            try response.message
        }
    ) async throws -> Result where Result: Sendable {
        let request = GRPCCore.ClientRequest<Primandproper_Platform_Comments_V1_CreateCommentRequest>(
            message: message,
            metadata: metadata
        )
        return try await self.createComment(
            request: request,
            options: options,
            onResponse: handleResponse
        )
    }

    /// Call the "GetComment" method.
    ///
    /// - Parameters:
    ///   - message: request message to send.
    ///   - metadata: Additional metadata to send, defaults to empty.
    ///   - options: Options to apply to this RPC, defaults to `.defaults`.
    ///   - handleResponse: A closure which handles the response and returns its result to
    ///       the caller. Returning from the closure will cancel the RPC if it hasn't
    ///       already finished.
    /// - Returns: The result of `handleResponse`.
    public func getComment<Result>(
        _ message: Primandproper_Platform_Comments_V1_GetCommentRequest,
        metadata: GRPCCore.Metadata = [:],
        options: GRPCCore.CallOptions = .defaults,
        onResponse handleResponse: @Sendable @escaping (GRPCCore.ClientResponse<Primandproper_Platform_Comments_V1_GetCommentResponse>) async throws -> Result = { response in
            try response.message
        }
    ) async throws -> Result where Result: Sendable {
        let request = GRPCCore.ClientRequest<Primandproper_Platform_Comments_V1_GetCommentRequest>(
            message: message,
            metadata: metadata
        )
        return try await self.getComment(
            request: request,
            options: options,
            onResponse: handleResponse
        )
    }

    /// Call the "ListRootComments" method.
    ///
    /// - Parameters:
    ///   - message: request message to send.
    ///   - metadata: Additional metadata to send, defaults to empty.
    ///   - options: Options to apply to this RPC, defaults to `.defaults`.
    ///   - handleResponse: A closure which handles the response and returns its result to
    ///       the caller. Returning from the closure will cancel the RPC if it hasn't
    ///       already finished.
    /// - Returns: The result of `handleResponse`.
    public func listRootComments<Result>(
        _ message: Primandproper_Platform_Comments_V1_ListRootCommentsRequest,
        metadata: GRPCCore.Metadata = [:],
        options: GRPCCore.CallOptions = .defaults,
        onResponse handleResponse: @Sendable @escaping (GRPCCore.ClientResponse<Primandproper_Platform_Comments_V1_ListRootCommentsResponse>) async throws -> Result = { response in
            try response.message
        }
    ) async throws -> Result where Result: Sendable {
        let request = GRPCCore.ClientRequest<Primandproper_Platform_Comments_V1_ListRootCommentsRequest>(
            message: message,
            metadata: metadata
        )
        return try await self.listRootComments(
            request: request,
            options: options,
            onResponse: handleResponse
        )
    }

    /// Call the "ListReplies" method.
    ///
    /// - Parameters:
    ///   - message: request message to send.
    ///   - metadata: Additional metadata to send, defaults to empty.
    ///   - options: Options to apply to this RPC, defaults to `.defaults`.
    ///   - handleResponse: A closure which handles the response and returns its result to
    ///       the caller. Returning from the closure will cancel the RPC if it hasn't
    ///       already finished.
    /// - Returns: The result of `handleResponse`.
    public func listReplies<Result>(
        _ message: Primandproper_Platform_Comments_V1_ListRepliesRequest,
        metadata: GRPCCore.Metadata = [:],
        options: GRPCCore.CallOptions = .defaults,
        onResponse handleResponse: @Sendable @escaping (GRPCCore.ClientResponse<Primandproper_Platform_Comments_V1_ListRepliesResponse>) async throws -> Result = { response in
            try response.message
        }
    ) async throws -> Result where Result: Sendable {
        let request = GRPCCore.ClientRequest<Primandproper_Platform_Comments_V1_ListRepliesRequest>(
            message: message,
            metadata: metadata
        )
        return try await self.listReplies(
            request: request,
            options: options,
            onResponse: handleResponse
        )
    }

    /// Call the "ListCommentsByTargetType" method.
    ///
    /// - Parameters:
    ///   - message: request message to send.
    ///   - metadata: Additional metadata to send, defaults to empty.
    ///   - options: Options to apply to this RPC, defaults to `.defaults`.
    ///   - handleResponse: A closure which handles the response and returns its result to
    ///       the caller. Returning from the closure will cancel the RPC if it hasn't
    ///       already finished.
    /// - Returns: The result of `handleResponse`.
    public func listCommentsByTargetType<Result>(
        _ message: Primandproper_Platform_Comments_V1_ListCommentsByTargetTypeRequest,
        metadata: GRPCCore.Metadata = [:],
        options: GRPCCore.CallOptions = .defaults,
        onResponse handleResponse: @Sendable @escaping (GRPCCore.ClientResponse<Primandproper_Platform_Comments_V1_ListCommentsByTargetTypeResponse>) async throws -> Result = { response in
            try response.message
        }
    ) async throws -> Result where Result: Sendable {
        let request = GRPCCore.ClientRequest<Primandproper_Platform_Comments_V1_ListCommentsByTargetTypeRequest>(
            message: message,
            metadata: metadata
        )
        return try await self.listCommentsByTargetType(
            request: request,
            options: options,
            onResponse: handleResponse
        )
    }

    /// Call the "ListCommentsByAuthor" method.
    ///
    /// - Parameters:
    ///   - message: request message to send.
    ///   - metadata: Additional metadata to send, defaults to empty.
    ///   - options: Options to apply to this RPC, defaults to `.defaults`.
    ///   - handleResponse: A closure which handles the response and returns its result to
    ///       the caller. Returning from the closure will cancel the RPC if it hasn't
    ///       already finished.
    /// - Returns: The result of `handleResponse`.
    public func listCommentsByAuthor<Result>(
        _ message: Primandproper_Platform_Comments_V1_ListCommentsByAuthorRequest,
        metadata: GRPCCore.Metadata = [:],
        options: GRPCCore.CallOptions = .defaults,
        onResponse handleResponse: @Sendable @escaping (GRPCCore.ClientResponse<Primandproper_Platform_Comments_V1_ListCommentsByAuthorResponse>) async throws -> Result = { response in
            try response.message
        }
    ) async throws -> Result where Result: Sendable {
        let request = GRPCCore.ClientRequest<Primandproper_Platform_Comments_V1_ListCommentsByAuthorRequest>(
            message: message,
            metadata: metadata
        )
        return try await self.listCommentsByAuthor(
            request: request,
            options: options,
            onResponse: handleResponse
        )
    }

    /// Call the "UpdateComment" method.
    ///
    /// - Parameters:
    ///   - message: request message to send.
    ///   - metadata: Additional metadata to send, defaults to empty.
    ///   - options: Options to apply to this RPC, defaults to `.defaults`.
    ///   - handleResponse: A closure which handles the response and returns its result to
    ///       the caller. Returning from the closure will cancel the RPC if it hasn't
    ///       already finished.
    /// - Returns: The result of `handleResponse`.
    public func updateComment<Result>(
        _ message: Primandproper_Platform_Comments_V1_UpdateCommentRequest,
        metadata: GRPCCore.Metadata = [:],
        options: GRPCCore.CallOptions = .defaults,
        onResponse handleResponse: @Sendable @escaping (GRPCCore.ClientResponse<Primandproper_Platform_Comments_V1_UpdateCommentResponse>) async throws -> Result = { response in
            try response.message
        }
    ) async throws -> Result where Result: Sendable {
        let request = GRPCCore.ClientRequest<Primandproper_Platform_Comments_V1_UpdateCommentRequest>(
            message: message,
            metadata: metadata
        )
        return try await self.updateComment(
            request: request,
            options: options,
            onResponse: handleResponse
        )
    }

    /// Call the "ArchiveComment" method.
    ///
    /// - Parameters:
    ///   - message: request message to send.
    ///   - metadata: Additional metadata to send, defaults to empty.
    ///   - options: Options to apply to this RPC, defaults to `.defaults`.
    ///   - handleResponse: A closure which handles the response and returns its result to
    ///       the caller. Returning from the closure will cancel the RPC if it hasn't
    ///       already finished.
    /// - Returns: The result of `handleResponse`.
    public func archiveComment<Result>(
        _ message: Primandproper_Platform_Comments_V1_ArchiveCommentRequest,
        metadata: GRPCCore.Metadata = [:],
        options: GRPCCore.CallOptions = .defaults,
        onResponse handleResponse: @Sendable @escaping (GRPCCore.ClientResponse<Primandproper_Platform_Comments_V1_ArchiveCommentResponse>) async throws -> Result = { response in
            try response.message
        }
    ) async throws -> Result where Result: Sendable {
        let request = GRPCCore.ClientRequest<Primandproper_Platform_Comments_V1_ArchiveCommentRequest>(
            message: message,
            metadata: metadata
        )
        return try await self.archiveComment(
            request: request,
            options: options,
            onResponse: handleResponse
        )
    }
}