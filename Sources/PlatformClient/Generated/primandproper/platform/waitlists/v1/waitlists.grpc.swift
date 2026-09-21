// Package primandproper.platform.waitlists.v1 is the wire schema for the queue
// people join before the thing they are queueing for exists: the lists an
// operator opens, and the signups against them with a lifecycle of their own.
//
// It is one service with two audiences, which is what makes it different from
// the three domain surfaces that came before it. Three RPCs are the signup page
// — the open lists, the form, and the unsubscribe — and are reachable by
// somebody who has not signed in and frequently does not have an account to
// sign in to. The other fourteen are whoever is running the launch, and every
// one of them is behind a grant. See the service comment at the bottom.
//
// This file is shipped inside the published Go module, and it is the file
// itself that is shipped -- not a copy for you to keep in sync. A consumer puts
// the module's proto directories on protoc's path and imports this file by its
// canonical name, exactly as identity.proto and filtering.proto already work:
//
//	PLATFORM_PROTO := $(shell go list -m -f '{{.Dir}}' github.com/primandproper/platform-go/v14)
//
//	protoc --proto_path proto/ \
//	    --proto_path $(PLATFORM_PROTO)/waitlists/proto \
//	    --proto_path $(PLATFORM_PROTO)/filtering/proto \
//	    --go_opt=Mprimandproper/platform/waitlists/v1/waitlists.proto=github.com/primandproper/platform-go/v14/waitlists/waitlistspb \
//	    $(CONSUMER_PROTO_FILES)   # the platform files deliberately absent from that list
//
// Field numbers are the compatibility promise, across every language a consumer
// generates into. Numbers are never reused and never repurposed: a field that
// goes away is reserved.
//
// # status is an enum, and that is not the usual answer
//
// [SignupStatus] is a generated enum, where webhooks' event type, comments'
// target type and issuereports' kind are all opaque strings. The rule those
// three are under is that a consumer's catalog stays a string, because a
// generated enum puts the application's vocabulary on this module's release
// cadence. This is the opposite case and waitlists.Status says so in its own
// documentation: the four statuses decide which transitions the store will
// make and what a withdrawal means, so a fifth is not a word an application
// adds -- it is a row nothing can move. settings.Kind is the other one of these.
//
// SubjectType is the string on this surface, and it is the one that is genuinely
// the consumer's: "user" and "account" are suggestions, and an application whose
// signups hang off a device or a workspace should say so rather than misfile it.
//
// # What is not here, and why
//
// No scope field, anywhere, and the name is reserved so there cannot be one. A
// scope a client could name is a cross-tenant read hiding behind a request
// field -- on this surface, one tenant reading another's signup list, or joining
// somebody to it. It is resolved off the caller where there is one and off the
// connection where there is not; see waitlists/grpc.
//
// Reserving the name rather than only saying so is audit.proto's pattern:
// `reserved "scope";` is a schema protoc refuses to accept a scope field into,
// in this repository and in a consumer's fork of the file alike, whereas a
// comment is a request to the next author. It is reserved on every request
// message and on the three messages a response is built from.
//
// No subject on [JoinRequest], and the name is reserved there too. A signup's
// subject is provenance -- who this row belongs to -- and provenance a caller
// could name is provenance that says whatever the caller wanted it to. It is
// filled from the principal the consumer's interceptor resolved, so a signed-in
// person's signup is theirs and an anonymous one belongs to nobody, which is the
// ordinary case for a pre-launch list. It is the same reading webhooks.proto
// takes of created_by. A deployment queueing whole organizations writes that
// signup through waitlists.SignupStore.Join in the transaction that carries the
// rest of what it knows about the organization, which is where a subject that is
// not the caller can actually be vouched for.
//
// No notes on [JoinRequest], reserved for the same reason by a shorter argument:
// Signup.notes is what whoever administers the list wrote about somebody, and
// UpdateSignupNotes is behind a grant. A form that could write it would be a
// form that writes the operator's column.
//
// No contact_digest on [Signup], and the name is reserved. The digest is what
// the row is found by and what survives a withdrawal, and it is deliberately
// unsalted over a fast hash -- so a client holding one can test any address it
// likes against it offline. waitlists.SQLStore.Digest still exports it in
// process, for the deployment migrating off a hand-written table, which is a
// caller with the addresses already in hand.
//
// No queue position. "You are 4,102nd in line" is a count that changes under
// whoever is reading it, and the paged reads here carry the counts a caller
// needs to render a position it is willing to stand behind.
//
// # include_archived is a request and not an instruction
//
// Every paged read here carries a QueryFilter, and its include_archived says
// "give me the archived rows too". It is a field on a message a client fills in,
// so it is a request the server rules on rather than a switch it obeys, and this
// service archives two nouns under two grants: the list reads honor it for a
// caller holding waitlists.lists.archive and the signup reads for one holding
// waitlists.signups.archive. For everybody else the field is cleared before the
// read, which on [ListOpenListsRequest] is everybody the RPC exists for --
// somebody who has not signed in carries no grants at all.
//
// It is cleared and not refused. A read that failed because the caller asked for
// too much turns a console's checkbox into an error, and a client cannot tell
// that refusal from a malformed filter; the page a caller gets is the page they
// would have got had they never set the field.
//
// The same rule, under each surface's own archive grant, is in comments.proto,
// issuereports.proto and settings.proto.

// DO NOT EDIT.
// swift-format-ignore-file
// swiftlint:disable all
//
// Generated by the gRPC Swift generator plugin for the protocol buffer compiler.
// Source: primandproper/platform/waitlists/v1/waitlists.proto
//
// For information on using the generated types, please see the documentation:
//   https://github.com/grpc/grpc-swift

import GRPCCore
import GRPCProtobuf

// MARK: - primandproper.platform.waitlists.v1.WaitlistsService

/// Namespace containing generated types for the "primandproper.platform.waitlists.v1.WaitlistsService" service.
@available(macOS 15.0, iOS 18.0, watchOS 11.0, tvOS 18.0, visionOS 2.0, *)
internal enum Primandproper_Platform_Waitlists_V1_WaitlistsService {
    /// Service descriptor for the "primandproper.platform.waitlists.v1.WaitlistsService" service.
    internal static let descriptor = GRPCCore.ServiceDescriptor(fullyQualifiedService: "primandproper.platform.waitlists.v1.WaitlistsService")
    /// Namespace for method metadata.
    internal enum Method {
        /// Namespace for "CreateList" metadata.
        internal enum CreateList {
            /// Request type for "CreateList".
            internal typealias Input = Primandproper_Platform_Waitlists_V1_CreateListRequest
            /// Response type for "CreateList".
            internal typealias Output = Primandproper_Platform_Waitlists_V1_CreateListResponse
            /// Descriptor for "CreateList".
            internal static let descriptor = GRPCCore.MethodDescriptor(
                service: GRPCCore.ServiceDescriptor(fullyQualifiedService: "primandproper.platform.waitlists.v1.WaitlistsService"),
                method: "CreateList"
            )
        }
        /// Namespace for "GetList" metadata.
        internal enum GetList {
            /// Request type for "GetList".
            internal typealias Input = Primandproper_Platform_Waitlists_V1_GetListRequest
            /// Response type for "GetList".
            internal typealias Output = Primandproper_Platform_Waitlists_V1_GetListResponse
            /// Descriptor for "GetList".
            internal static let descriptor = GRPCCore.MethodDescriptor(
                service: GRPCCore.ServiceDescriptor(fullyQualifiedService: "primandproper.platform.waitlists.v1.WaitlistsService"),
                method: "GetList"
            )
        }
        /// Namespace for "ListLists" metadata.
        internal enum ListLists {
            /// Request type for "ListLists".
            internal typealias Input = Primandproper_Platform_Waitlists_V1_ListListsRequest
            /// Response type for "ListLists".
            internal typealias Output = Primandproper_Platform_Waitlists_V1_ListListsResponse
            /// Descriptor for "ListLists".
            internal static let descriptor = GRPCCore.MethodDescriptor(
                service: GRPCCore.ServiceDescriptor(fullyQualifiedService: "primandproper.platform.waitlists.v1.WaitlistsService"),
                method: "ListLists"
            )
        }
        /// Namespace for "ListOpenLists" metadata.
        internal enum ListOpenLists {
            /// Request type for "ListOpenLists".
            internal typealias Input = Primandproper_Platform_Waitlists_V1_ListOpenListsRequest
            /// Response type for "ListOpenLists".
            internal typealias Output = Primandproper_Platform_Waitlists_V1_ListOpenListsResponse
            /// Descriptor for "ListOpenLists".
            internal static let descriptor = GRPCCore.MethodDescriptor(
                service: GRPCCore.ServiceDescriptor(fullyQualifiedService: "primandproper.platform.waitlists.v1.WaitlistsService"),
                method: "ListOpenLists"
            )
        }
        /// Namespace for "UpdateList" metadata.
        internal enum UpdateList {
            /// Request type for "UpdateList".
            internal typealias Input = Primandproper_Platform_Waitlists_V1_UpdateListRequest
            /// Response type for "UpdateList".
            internal typealias Output = Primandproper_Platform_Waitlists_V1_UpdateListResponse
            /// Descriptor for "UpdateList".
            internal static let descriptor = GRPCCore.MethodDescriptor(
                service: GRPCCore.ServiceDescriptor(fullyQualifiedService: "primandproper.platform.waitlists.v1.WaitlistsService"),
                method: "UpdateList"
            )
        }
        /// Namespace for "ArchiveList" metadata.
        internal enum ArchiveList {
            /// Request type for "ArchiveList".
            internal typealias Input = Primandproper_Platform_Waitlists_V1_ArchiveListRequest
            /// Response type for "ArchiveList".
            internal typealias Output = Primandproper_Platform_Waitlists_V1_ArchiveListResponse
            /// Descriptor for "ArchiveList".
            internal static let descriptor = GRPCCore.MethodDescriptor(
                service: GRPCCore.ServiceDescriptor(fullyQualifiedService: "primandproper.platform.waitlists.v1.WaitlistsService"),
                method: "ArchiveList"
            )
        }
        /// Namespace for "Join" metadata.
        internal enum Join {
            /// Request type for "Join".
            internal typealias Input = Primandproper_Platform_Waitlists_V1_JoinRequest
            /// Response type for "Join".
            internal typealias Output = Primandproper_Platform_Waitlists_V1_JoinResponse
            /// Descriptor for "Join".
            internal static let descriptor = GRPCCore.MethodDescriptor(
                service: GRPCCore.ServiceDescriptor(fullyQualifiedService: "primandproper.platform.waitlists.v1.WaitlistsService"),
                method: "Join"
            )
        }
        /// Namespace for "GetSignup" metadata.
        internal enum GetSignup {
            /// Request type for "GetSignup".
            internal typealias Input = Primandproper_Platform_Waitlists_V1_GetSignupRequest
            /// Response type for "GetSignup".
            internal typealias Output = Primandproper_Platform_Waitlists_V1_GetSignupResponse
            /// Descriptor for "GetSignup".
            internal static let descriptor = GRPCCore.MethodDescriptor(
                service: GRPCCore.ServiceDescriptor(fullyQualifiedService: "primandproper.platform.waitlists.v1.WaitlistsService"),
                method: "GetSignup"
            )
        }
        /// Namespace for "GetSignupByContact" metadata.
        internal enum GetSignupByContact {
            /// Request type for "GetSignupByContact".
            internal typealias Input = Primandproper_Platform_Waitlists_V1_GetSignupByContactRequest
            /// Response type for "GetSignupByContact".
            internal typealias Output = Primandproper_Platform_Waitlists_V1_GetSignupByContactResponse
            /// Descriptor for "GetSignupByContact".
            internal static let descriptor = GRPCCore.MethodDescriptor(
                service: GRPCCore.ServiceDescriptor(fullyQualifiedService: "primandproper.platform.waitlists.v1.WaitlistsService"),
                method: "GetSignupByContact"
            )
        }
        /// Namespace for "ListSignups" metadata.
        internal enum ListSignups {
            /// Request type for "ListSignups".
            internal typealias Input = Primandproper_Platform_Waitlists_V1_ListSignupsRequest
            /// Response type for "ListSignups".
            internal typealias Output = Primandproper_Platform_Waitlists_V1_ListSignupsResponse
            /// Descriptor for "ListSignups".
            internal static let descriptor = GRPCCore.MethodDescriptor(
                service: GRPCCore.ServiceDescriptor(fullyQualifiedService: "primandproper.platform.waitlists.v1.WaitlistsService"),
                method: "ListSignups"
            )
        }
        /// Namespace for "ListSignupsForSubject" metadata.
        internal enum ListSignupsForSubject {
            /// Request type for "ListSignupsForSubject".
            internal typealias Input = Primandproper_Platform_Waitlists_V1_ListSignupsForSubjectRequest
            /// Response type for "ListSignupsForSubject".
            internal typealias Output = Primandproper_Platform_Waitlists_V1_ListSignupsForSubjectResponse
            /// Descriptor for "ListSignupsForSubject".
            internal static let descriptor = GRPCCore.MethodDescriptor(
                service: GRPCCore.ServiceDescriptor(fullyQualifiedService: "primandproper.platform.waitlists.v1.WaitlistsService"),
                method: "ListSignupsForSubject"
            )
        }
        /// Namespace for "UpdateSignupNotes" metadata.
        internal enum UpdateSignupNotes {
            /// Request type for "UpdateSignupNotes".
            internal typealias Input = Primandproper_Platform_Waitlists_V1_UpdateSignupNotesRequest
            /// Response type for "UpdateSignupNotes".
            internal typealias Output = Primandproper_Platform_Waitlists_V1_UpdateSignupNotesResponse
            /// Descriptor for "UpdateSignupNotes".
            internal static let descriptor = GRPCCore.MethodDescriptor(
                service: GRPCCore.ServiceDescriptor(fullyQualifiedService: "primandproper.platform.waitlists.v1.WaitlistsService"),
                method: "UpdateSignupNotes"
            )
        }
        /// Namespace for "Invite" metadata.
        internal enum Invite {
            /// Request type for "Invite".
            internal typealias Input = Primandproper_Platform_Waitlists_V1_InviteRequest
            /// Response type for "Invite".
            internal typealias Output = Primandproper_Platform_Waitlists_V1_InviteResponse
            /// Descriptor for "Invite".
            internal static let descriptor = GRPCCore.MethodDescriptor(
                service: GRPCCore.ServiceDescriptor(fullyQualifiedService: "primandproper.platform.waitlists.v1.WaitlistsService"),
                method: "Invite"
            )
        }
        /// Namespace for "Convert" metadata.
        internal enum Convert {
            /// Request type for "Convert".
            internal typealias Input = Primandproper_Platform_Waitlists_V1_ConvertRequest
            /// Response type for "Convert".
            internal typealias Output = Primandproper_Platform_Waitlists_V1_ConvertResponse
            /// Descriptor for "Convert".
            internal static let descriptor = GRPCCore.MethodDescriptor(
                service: GRPCCore.ServiceDescriptor(fullyQualifiedService: "primandproper.platform.waitlists.v1.WaitlistsService"),
                method: "Convert"
            )
        }
        /// Namespace for "Withdraw" metadata.
        internal enum Withdraw {
            /// Request type for "Withdraw".
            internal typealias Input = Primandproper_Platform_Waitlists_V1_WithdrawRequest
            /// Response type for "Withdraw".
            internal typealias Output = Primandproper_Platform_Waitlists_V1_WithdrawResponse
            /// Descriptor for "Withdraw".
            internal static let descriptor = GRPCCore.MethodDescriptor(
                service: GRPCCore.ServiceDescriptor(fullyQualifiedService: "primandproper.platform.waitlists.v1.WaitlistsService"),
                method: "Withdraw"
            )
        }
        /// Namespace for "WithdrawSignupsForSubject" metadata.
        internal enum WithdrawSignupsForSubject {
            /// Request type for "WithdrawSignupsForSubject".
            internal typealias Input = Primandproper_Platform_Waitlists_V1_WithdrawSignupsForSubjectRequest
            /// Response type for "WithdrawSignupsForSubject".
            internal typealias Output = Primandproper_Platform_Waitlists_V1_WithdrawSignupsForSubjectResponse
            /// Descriptor for "WithdrawSignupsForSubject".
            internal static let descriptor = GRPCCore.MethodDescriptor(
                service: GRPCCore.ServiceDescriptor(fullyQualifiedService: "primandproper.platform.waitlists.v1.WaitlistsService"),
                method: "WithdrawSignupsForSubject"
            )
        }
        /// Namespace for "ArchiveSignup" metadata.
        internal enum ArchiveSignup {
            /// Request type for "ArchiveSignup".
            internal typealias Input = Primandproper_Platform_Waitlists_V1_ArchiveSignupRequest
            /// Response type for "ArchiveSignup".
            internal typealias Output = Primandproper_Platform_Waitlists_V1_ArchiveSignupResponse
            /// Descriptor for "ArchiveSignup".
            internal static let descriptor = GRPCCore.MethodDescriptor(
                service: GRPCCore.ServiceDescriptor(fullyQualifiedService: "primandproper.platform.waitlists.v1.WaitlistsService"),
                method: "ArchiveSignup"
            )
        }
        /// Descriptors for all methods in the "primandproper.platform.waitlists.v1.WaitlistsService" service.
        internal static let descriptors: [GRPCCore.MethodDescriptor] = [
            CreateList.descriptor,
            GetList.descriptor,
            ListLists.descriptor,
            ListOpenLists.descriptor,
            UpdateList.descriptor,
            ArchiveList.descriptor,
            Join.descriptor,
            GetSignup.descriptor,
            GetSignupByContact.descriptor,
            ListSignups.descriptor,
            ListSignupsForSubject.descriptor,
            UpdateSignupNotes.descriptor,
            Invite.descriptor,
            Convert.descriptor,
            Withdraw.descriptor,
            WithdrawSignupsForSubject.descriptor,
            ArchiveSignup.descriptor
        ]
    }
}

@available(macOS 15.0, iOS 18.0, watchOS 11.0, tvOS 18.0, visionOS 2.0, *)
extension GRPCCore.ServiceDescriptor {
    /// Service descriptor for the "primandproper.platform.waitlists.v1.WaitlistsService" service.
    internal static let primandproper_platform_waitlists_v1_WaitlistsService = GRPCCore.ServiceDescriptor(fullyQualifiedService: "primandproper.platform.waitlists.v1.WaitlistsService")
}

// MARK: primandproper.platform.waitlists.v1.WaitlistsService (client)

@available(macOS 15.0, iOS 18.0, watchOS 11.0, tvOS 18.0, visionOS 2.0, *)
extension Primandproper_Platform_Waitlists_V1_WaitlistsService {
    /// Generated client protocol for the "primandproper.platform.waitlists.v1.WaitlistsService" service.
    ///
    /// You don't need to implement this protocol directly, use the generated
    /// implementation, ``Client``.
    ///
    /// > Source IDL Documentation:
    /// >
    /// > WaitlistsService is the whole of waitlists on the wire: all seventeen methods
    /// > of waitlists.Store, split by who calls them.
    /// > 
    /// > There are no absences, which is unusual on this lane and is the reason this
    /// > was the first of the ten domains to cross. Every other surface in the module
    /// > carves something out because its realistic caller is a worker on a timer, a
    /// > processor callback, or the consumer's own code inside its own transaction.
    /// > Nothing here has that shape: a waitlist has no queue protocol, no fan-out and
    /// > no provider callback, and every one of the seventeen is either a form
    /// > somebody submitted or a console somebody is looking at.
    /// > 
    /// > # The public three
    /// > 
    /// > ListOpenLists, Join and Withdraw are reachable without a grant, because the
    /// > caller is a person on a signup page who has not signed in and frequently has
    /// > no account to sign in to. That is the whole of what "public" means here: the
    /// > consumer's authentication interceptor still runs, and a caller who does arrive
    /// > with a principal has their signup attributed to them.
    /// > 
    /// > Public is not unguarded, and it is not talkative either. Join is refused for a
    /// > closed list, which is a fact about the list rather than about anybody's
    /// > address, and it answers uniformly for every outcome that is about an address
    /// > -- see JoinResponse, which is empty for that reason. Withdraw names a row, so
    /// > the standing to move it is asked of a seam the consumer implements -- see
    /// > WithdrawRequest. And the read a public caller gets is the catalog of open
    /// > lists, which is what a signup page publishes anyway.
    /// > 
    /// > # The administrative fourteen
    /// > 
    /// > List CRUD, the signup reads, the two lifecycle transitions, the note, the
    /// > archive and the erasure. Each is behind a grant, and waitlists/grpc's
    /// > Permissions is the default map a consumer composes into their policy.
    /// > 
    /// > GetSignupByContact is the one to look at twice. It is a read, it looks
    /// > harmless beside Join, and it is the difference between a service and an oracle
    /// > over which addresses are on which list. It is also the only place on this wire
    /// > that answers "is this address on this list" at all, now that the public Join
    /// > does not.
    internal protocol ClientProtocol: Sendable {
        /// Call the "CreateList" method.
        ///
        /// > Source IDL Documentation:
        /// >
        /// > The catalog: what lists exist, what they are for, and when each stops
        /// > taking signups. ListOpenLists is the public one.
        ///
        /// - Parameters:
        ///   - request: A request containing a single `Primandproper_Platform_Waitlists_V1_CreateListRequest` message.
        ///   - serializer: A serializer for `Primandproper_Platform_Waitlists_V1_CreateListRequest` messages.
        ///   - deserializer: A deserializer for `Primandproper_Platform_Waitlists_V1_CreateListResponse` messages.
        ///   - options: Options to apply to this RPC.
        ///   - handleResponse: A closure which handles the response, the result of which is
        ///       returned to the caller. Returning from the closure will cancel the RPC if it
        ///       hasn't already finished.
        /// - Returns: The result of `handleResponse`.
        func createList<Result>(
            request: GRPCCore.ClientRequest<Primandproper_Platform_Waitlists_V1_CreateListRequest>,
            serializer: some GRPCCore.MessageSerializer<Primandproper_Platform_Waitlists_V1_CreateListRequest>,
            deserializer: some GRPCCore.MessageDeserializer<Primandproper_Platform_Waitlists_V1_CreateListResponse>,
            options: GRPCCore.CallOptions,
            onResponse handleResponse: @Sendable @escaping (GRPCCore.ClientResponse<Primandproper_Platform_Waitlists_V1_CreateListResponse>) async throws -> Result
        ) async throws -> Result where Result: Sendable

        /// Call the "GetList" method.
        ///
        /// - Parameters:
        ///   - request: A request containing a single `Primandproper_Platform_Waitlists_V1_GetListRequest` message.
        ///   - serializer: A serializer for `Primandproper_Platform_Waitlists_V1_GetListRequest` messages.
        ///   - deserializer: A deserializer for `Primandproper_Platform_Waitlists_V1_GetListResponse` messages.
        ///   - options: Options to apply to this RPC.
        ///   - handleResponse: A closure which handles the response, the result of which is
        ///       returned to the caller. Returning from the closure will cancel the RPC if it
        ///       hasn't already finished.
        /// - Returns: The result of `handleResponse`.
        func getList<Result>(
            request: GRPCCore.ClientRequest<Primandproper_Platform_Waitlists_V1_GetListRequest>,
            serializer: some GRPCCore.MessageSerializer<Primandproper_Platform_Waitlists_V1_GetListRequest>,
            deserializer: some GRPCCore.MessageDeserializer<Primandproper_Platform_Waitlists_V1_GetListResponse>,
            options: GRPCCore.CallOptions,
            onResponse handleResponse: @Sendable @escaping (GRPCCore.ClientResponse<Primandproper_Platform_Waitlists_V1_GetListResponse>) async throws -> Result
        ) async throws -> Result where Result: Sendable

        /// Call the "ListLists" method.
        ///
        /// - Parameters:
        ///   - request: A request containing a single `Primandproper_Platform_Waitlists_V1_ListListsRequest` message.
        ///   - serializer: A serializer for `Primandproper_Platform_Waitlists_V1_ListListsRequest` messages.
        ///   - deserializer: A deserializer for `Primandproper_Platform_Waitlists_V1_ListListsResponse` messages.
        ///   - options: Options to apply to this RPC.
        ///   - handleResponse: A closure which handles the response, the result of which is
        ///       returned to the caller. Returning from the closure will cancel the RPC if it
        ///       hasn't already finished.
        /// - Returns: The result of `handleResponse`.
        func listLists<Result>(
            request: GRPCCore.ClientRequest<Primandproper_Platform_Waitlists_V1_ListListsRequest>,
            serializer: some GRPCCore.MessageSerializer<Primandproper_Platform_Waitlists_V1_ListListsRequest>,
            deserializer: some GRPCCore.MessageDeserializer<Primandproper_Platform_Waitlists_V1_ListListsResponse>,
            options: GRPCCore.CallOptions,
            onResponse handleResponse: @Sendable @escaping (GRPCCore.ClientResponse<Primandproper_Platform_Waitlists_V1_ListListsResponse>) async throws -> Result
        ) async throws -> Result where Result: Sendable

        /// Call the "ListOpenLists" method.
        ///
        /// - Parameters:
        ///   - request: A request containing a single `Primandproper_Platform_Waitlists_V1_ListOpenListsRequest` message.
        ///   - serializer: A serializer for `Primandproper_Platform_Waitlists_V1_ListOpenListsRequest` messages.
        ///   - deserializer: A deserializer for `Primandproper_Platform_Waitlists_V1_ListOpenListsResponse` messages.
        ///   - options: Options to apply to this RPC.
        ///   - handleResponse: A closure which handles the response, the result of which is
        ///       returned to the caller. Returning from the closure will cancel the RPC if it
        ///       hasn't already finished.
        /// - Returns: The result of `handleResponse`.
        func listOpenLists<Result>(
            request: GRPCCore.ClientRequest<Primandproper_Platform_Waitlists_V1_ListOpenListsRequest>,
            serializer: some GRPCCore.MessageSerializer<Primandproper_Platform_Waitlists_V1_ListOpenListsRequest>,
            deserializer: some GRPCCore.MessageDeserializer<Primandproper_Platform_Waitlists_V1_ListOpenListsResponse>,
            options: GRPCCore.CallOptions,
            onResponse handleResponse: @Sendable @escaping (GRPCCore.ClientResponse<Primandproper_Platform_Waitlists_V1_ListOpenListsResponse>) async throws -> Result
        ) async throws -> Result where Result: Sendable

        /// Call the "UpdateList" method.
        ///
        /// - Parameters:
        ///   - request: A request containing a single `Primandproper_Platform_Waitlists_V1_UpdateListRequest` message.
        ///   - serializer: A serializer for `Primandproper_Platform_Waitlists_V1_UpdateListRequest` messages.
        ///   - deserializer: A deserializer for `Primandproper_Platform_Waitlists_V1_UpdateListResponse` messages.
        ///   - options: Options to apply to this RPC.
        ///   - handleResponse: A closure which handles the response, the result of which is
        ///       returned to the caller. Returning from the closure will cancel the RPC if it
        ///       hasn't already finished.
        /// - Returns: The result of `handleResponse`.
        func updateList<Result>(
            request: GRPCCore.ClientRequest<Primandproper_Platform_Waitlists_V1_UpdateListRequest>,
            serializer: some GRPCCore.MessageSerializer<Primandproper_Platform_Waitlists_V1_UpdateListRequest>,
            deserializer: some GRPCCore.MessageDeserializer<Primandproper_Platform_Waitlists_V1_UpdateListResponse>,
            options: GRPCCore.CallOptions,
            onResponse handleResponse: @Sendable @escaping (GRPCCore.ClientResponse<Primandproper_Platform_Waitlists_V1_UpdateListResponse>) async throws -> Result
        ) async throws -> Result where Result: Sendable

        /// Call the "ArchiveList" method.
        ///
        /// - Parameters:
        ///   - request: A request containing a single `Primandproper_Platform_Waitlists_V1_ArchiveListRequest` message.
        ///   - serializer: A serializer for `Primandproper_Platform_Waitlists_V1_ArchiveListRequest` messages.
        ///   - deserializer: A deserializer for `Primandproper_Platform_Waitlists_V1_ArchiveListResponse` messages.
        ///   - options: Options to apply to this RPC.
        ///   - handleResponse: A closure which handles the response, the result of which is
        ///       returned to the caller. Returning from the closure will cancel the RPC if it
        ///       hasn't already finished.
        /// - Returns: The result of `handleResponse`.
        func archiveList<Result>(
            request: GRPCCore.ClientRequest<Primandproper_Platform_Waitlists_V1_ArchiveListRequest>,
            serializer: some GRPCCore.MessageSerializer<Primandproper_Platform_Waitlists_V1_ArchiveListRequest>,
            deserializer: some GRPCCore.MessageDeserializer<Primandproper_Platform_Waitlists_V1_ArchiveListResponse>,
            options: GRPCCore.CallOptions,
            onResponse handleResponse: @Sendable @escaping (GRPCCore.ClientResponse<Primandproper_Platform_Waitlists_V1_ArchiveListResponse>) async throws -> Result
        ) async throws -> Result where Result: Sendable

        /// Call the "Join" method.
        ///
        /// > Source IDL Documentation:
        /// >
        /// > The queue. Join and Withdraw are the person's own; the rest are the
        /// > operator's.
        ///
        /// - Parameters:
        ///   - request: A request containing a single `Primandproper_Platform_Waitlists_V1_JoinRequest` message.
        ///   - serializer: A serializer for `Primandproper_Platform_Waitlists_V1_JoinRequest` messages.
        ///   - deserializer: A deserializer for `Primandproper_Platform_Waitlists_V1_JoinResponse` messages.
        ///   - options: Options to apply to this RPC.
        ///   - handleResponse: A closure which handles the response, the result of which is
        ///       returned to the caller. Returning from the closure will cancel the RPC if it
        ///       hasn't already finished.
        /// - Returns: The result of `handleResponse`.
        func join<Result>(
            request: GRPCCore.ClientRequest<Primandproper_Platform_Waitlists_V1_JoinRequest>,
            serializer: some GRPCCore.MessageSerializer<Primandproper_Platform_Waitlists_V1_JoinRequest>,
            deserializer: some GRPCCore.MessageDeserializer<Primandproper_Platform_Waitlists_V1_JoinResponse>,
            options: GRPCCore.CallOptions,
            onResponse handleResponse: @Sendable @escaping (GRPCCore.ClientResponse<Primandproper_Platform_Waitlists_V1_JoinResponse>) async throws -> Result
        ) async throws -> Result where Result: Sendable

        /// Call the "GetSignup" method.
        ///
        /// - Parameters:
        ///   - request: A request containing a single `Primandproper_Platform_Waitlists_V1_GetSignupRequest` message.
        ///   - serializer: A serializer for `Primandproper_Platform_Waitlists_V1_GetSignupRequest` messages.
        ///   - deserializer: A deserializer for `Primandproper_Platform_Waitlists_V1_GetSignupResponse` messages.
        ///   - options: Options to apply to this RPC.
        ///   - handleResponse: A closure which handles the response, the result of which is
        ///       returned to the caller. Returning from the closure will cancel the RPC if it
        ///       hasn't already finished.
        /// - Returns: The result of `handleResponse`.
        func getSignup<Result>(
            request: GRPCCore.ClientRequest<Primandproper_Platform_Waitlists_V1_GetSignupRequest>,
            serializer: some GRPCCore.MessageSerializer<Primandproper_Platform_Waitlists_V1_GetSignupRequest>,
            deserializer: some GRPCCore.MessageDeserializer<Primandproper_Platform_Waitlists_V1_GetSignupResponse>,
            options: GRPCCore.CallOptions,
            onResponse handleResponse: @Sendable @escaping (GRPCCore.ClientResponse<Primandproper_Platform_Waitlists_V1_GetSignupResponse>) async throws -> Result
        ) async throws -> Result where Result: Sendable

        /// Call the "GetSignupByContact" method.
        ///
        /// - Parameters:
        ///   - request: A request containing a single `Primandproper_Platform_Waitlists_V1_GetSignupByContactRequest` message.
        ///   - serializer: A serializer for `Primandproper_Platform_Waitlists_V1_GetSignupByContactRequest` messages.
        ///   - deserializer: A deserializer for `Primandproper_Platform_Waitlists_V1_GetSignupByContactResponse` messages.
        ///   - options: Options to apply to this RPC.
        ///   - handleResponse: A closure which handles the response, the result of which is
        ///       returned to the caller. Returning from the closure will cancel the RPC if it
        ///       hasn't already finished.
        /// - Returns: The result of `handleResponse`.
        func getSignupByContact<Result>(
            request: GRPCCore.ClientRequest<Primandproper_Platform_Waitlists_V1_GetSignupByContactRequest>,
            serializer: some GRPCCore.MessageSerializer<Primandproper_Platform_Waitlists_V1_GetSignupByContactRequest>,
            deserializer: some GRPCCore.MessageDeserializer<Primandproper_Platform_Waitlists_V1_GetSignupByContactResponse>,
            options: GRPCCore.CallOptions,
            onResponse handleResponse: @Sendable @escaping (GRPCCore.ClientResponse<Primandproper_Platform_Waitlists_V1_GetSignupByContactResponse>) async throws -> Result
        ) async throws -> Result where Result: Sendable

        /// Call the "ListSignups" method.
        ///
        /// - Parameters:
        ///   - request: A request containing a single `Primandproper_Platform_Waitlists_V1_ListSignupsRequest` message.
        ///   - serializer: A serializer for `Primandproper_Platform_Waitlists_V1_ListSignupsRequest` messages.
        ///   - deserializer: A deserializer for `Primandproper_Platform_Waitlists_V1_ListSignupsResponse` messages.
        ///   - options: Options to apply to this RPC.
        ///   - handleResponse: A closure which handles the response, the result of which is
        ///       returned to the caller. Returning from the closure will cancel the RPC if it
        ///       hasn't already finished.
        /// - Returns: The result of `handleResponse`.
        func listSignups<Result>(
            request: GRPCCore.ClientRequest<Primandproper_Platform_Waitlists_V1_ListSignupsRequest>,
            serializer: some GRPCCore.MessageSerializer<Primandproper_Platform_Waitlists_V1_ListSignupsRequest>,
            deserializer: some GRPCCore.MessageDeserializer<Primandproper_Platform_Waitlists_V1_ListSignupsResponse>,
            options: GRPCCore.CallOptions,
            onResponse handleResponse: @Sendable @escaping (GRPCCore.ClientResponse<Primandproper_Platform_Waitlists_V1_ListSignupsResponse>) async throws -> Result
        ) async throws -> Result where Result: Sendable

        /// Call the "ListSignupsForSubject" method.
        ///
        /// - Parameters:
        ///   - request: A request containing a single `Primandproper_Platform_Waitlists_V1_ListSignupsForSubjectRequest` message.
        ///   - serializer: A serializer for `Primandproper_Platform_Waitlists_V1_ListSignupsForSubjectRequest` messages.
        ///   - deserializer: A deserializer for `Primandproper_Platform_Waitlists_V1_ListSignupsForSubjectResponse` messages.
        ///   - options: Options to apply to this RPC.
        ///   - handleResponse: A closure which handles the response, the result of which is
        ///       returned to the caller. Returning from the closure will cancel the RPC if it
        ///       hasn't already finished.
        /// - Returns: The result of `handleResponse`.
        func listSignupsForSubject<Result>(
            request: GRPCCore.ClientRequest<Primandproper_Platform_Waitlists_V1_ListSignupsForSubjectRequest>,
            serializer: some GRPCCore.MessageSerializer<Primandproper_Platform_Waitlists_V1_ListSignupsForSubjectRequest>,
            deserializer: some GRPCCore.MessageDeserializer<Primandproper_Platform_Waitlists_V1_ListSignupsForSubjectResponse>,
            options: GRPCCore.CallOptions,
            onResponse handleResponse: @Sendable @escaping (GRPCCore.ClientResponse<Primandproper_Platform_Waitlists_V1_ListSignupsForSubjectResponse>) async throws -> Result
        ) async throws -> Result where Result: Sendable

        /// Call the "UpdateSignupNotes" method.
        ///
        /// - Parameters:
        ///   - request: A request containing a single `Primandproper_Platform_Waitlists_V1_UpdateSignupNotesRequest` message.
        ///   - serializer: A serializer for `Primandproper_Platform_Waitlists_V1_UpdateSignupNotesRequest` messages.
        ///   - deserializer: A deserializer for `Primandproper_Platform_Waitlists_V1_UpdateSignupNotesResponse` messages.
        ///   - options: Options to apply to this RPC.
        ///   - handleResponse: A closure which handles the response, the result of which is
        ///       returned to the caller. Returning from the closure will cancel the RPC if it
        ///       hasn't already finished.
        /// - Returns: The result of `handleResponse`.
        func updateSignupNotes<Result>(
            request: GRPCCore.ClientRequest<Primandproper_Platform_Waitlists_V1_UpdateSignupNotesRequest>,
            serializer: some GRPCCore.MessageSerializer<Primandproper_Platform_Waitlists_V1_UpdateSignupNotesRequest>,
            deserializer: some GRPCCore.MessageDeserializer<Primandproper_Platform_Waitlists_V1_UpdateSignupNotesResponse>,
            options: GRPCCore.CallOptions,
            onResponse handleResponse: @Sendable @escaping (GRPCCore.ClientResponse<Primandproper_Platform_Waitlists_V1_UpdateSignupNotesResponse>) async throws -> Result
        ) async throws -> Result where Result: Sendable

        /// Call the "Invite" method.
        ///
        /// - Parameters:
        ///   - request: A request containing a single `Primandproper_Platform_Waitlists_V1_InviteRequest` message.
        ///   - serializer: A serializer for `Primandproper_Platform_Waitlists_V1_InviteRequest` messages.
        ///   - deserializer: A deserializer for `Primandproper_Platform_Waitlists_V1_InviteResponse` messages.
        ///   - options: Options to apply to this RPC.
        ///   - handleResponse: A closure which handles the response, the result of which is
        ///       returned to the caller. Returning from the closure will cancel the RPC if it
        ///       hasn't already finished.
        /// - Returns: The result of `handleResponse`.
        func invite<Result>(
            request: GRPCCore.ClientRequest<Primandproper_Platform_Waitlists_V1_InviteRequest>,
            serializer: some GRPCCore.MessageSerializer<Primandproper_Platform_Waitlists_V1_InviteRequest>,
            deserializer: some GRPCCore.MessageDeserializer<Primandproper_Platform_Waitlists_V1_InviteResponse>,
            options: GRPCCore.CallOptions,
            onResponse handleResponse: @Sendable @escaping (GRPCCore.ClientResponse<Primandproper_Platform_Waitlists_V1_InviteResponse>) async throws -> Result
        ) async throws -> Result where Result: Sendable

        /// Call the "Convert" method.
        ///
        /// - Parameters:
        ///   - request: A request containing a single `Primandproper_Platform_Waitlists_V1_ConvertRequest` message.
        ///   - serializer: A serializer for `Primandproper_Platform_Waitlists_V1_ConvertRequest` messages.
        ///   - deserializer: A deserializer for `Primandproper_Platform_Waitlists_V1_ConvertResponse` messages.
        ///   - options: Options to apply to this RPC.
        ///   - handleResponse: A closure which handles the response, the result of which is
        ///       returned to the caller. Returning from the closure will cancel the RPC if it
        ///       hasn't already finished.
        /// - Returns: The result of `handleResponse`.
        func convert<Result>(
            request: GRPCCore.ClientRequest<Primandproper_Platform_Waitlists_V1_ConvertRequest>,
            serializer: some GRPCCore.MessageSerializer<Primandproper_Platform_Waitlists_V1_ConvertRequest>,
            deserializer: some GRPCCore.MessageDeserializer<Primandproper_Platform_Waitlists_V1_ConvertResponse>,
            options: GRPCCore.CallOptions,
            onResponse handleResponse: @Sendable @escaping (GRPCCore.ClientResponse<Primandproper_Platform_Waitlists_V1_ConvertResponse>) async throws -> Result
        ) async throws -> Result where Result: Sendable

        /// Call the "Withdraw" method.
        ///
        /// - Parameters:
        ///   - request: A request containing a single `Primandproper_Platform_Waitlists_V1_WithdrawRequest` message.
        ///   - serializer: A serializer for `Primandproper_Platform_Waitlists_V1_WithdrawRequest` messages.
        ///   - deserializer: A deserializer for `Primandproper_Platform_Waitlists_V1_WithdrawResponse` messages.
        ///   - options: Options to apply to this RPC.
        ///   - handleResponse: A closure which handles the response, the result of which is
        ///       returned to the caller. Returning from the closure will cancel the RPC if it
        ///       hasn't already finished.
        /// - Returns: The result of `handleResponse`.
        func withdraw<Result>(
            request: GRPCCore.ClientRequest<Primandproper_Platform_Waitlists_V1_WithdrawRequest>,
            serializer: some GRPCCore.MessageSerializer<Primandproper_Platform_Waitlists_V1_WithdrawRequest>,
            deserializer: some GRPCCore.MessageDeserializer<Primandproper_Platform_Waitlists_V1_WithdrawResponse>,
            options: GRPCCore.CallOptions,
            onResponse handleResponse: @Sendable @escaping (GRPCCore.ClientResponse<Primandproper_Platform_Waitlists_V1_WithdrawResponse>) async throws -> Result
        ) async throws -> Result where Result: Sendable

        /// Call the "WithdrawSignupsForSubject" method.
        ///
        /// - Parameters:
        ///   - request: A request containing a single `Primandproper_Platform_Waitlists_V1_WithdrawSignupsForSubjectRequest` message.
        ///   - serializer: A serializer for `Primandproper_Platform_Waitlists_V1_WithdrawSignupsForSubjectRequest` messages.
        ///   - deserializer: A deserializer for `Primandproper_Platform_Waitlists_V1_WithdrawSignupsForSubjectResponse` messages.
        ///   - options: Options to apply to this RPC.
        ///   - handleResponse: A closure which handles the response, the result of which is
        ///       returned to the caller. Returning from the closure will cancel the RPC if it
        ///       hasn't already finished.
        /// - Returns: The result of `handleResponse`.
        func withdrawSignupsForSubject<Result>(
            request: GRPCCore.ClientRequest<Primandproper_Platform_Waitlists_V1_WithdrawSignupsForSubjectRequest>,
            serializer: some GRPCCore.MessageSerializer<Primandproper_Platform_Waitlists_V1_WithdrawSignupsForSubjectRequest>,
            deserializer: some GRPCCore.MessageDeserializer<Primandproper_Platform_Waitlists_V1_WithdrawSignupsForSubjectResponse>,
            options: GRPCCore.CallOptions,
            onResponse handleResponse: @Sendable @escaping (GRPCCore.ClientResponse<Primandproper_Platform_Waitlists_V1_WithdrawSignupsForSubjectResponse>) async throws -> Result
        ) async throws -> Result where Result: Sendable

        /// Call the "ArchiveSignup" method.
        ///
        /// - Parameters:
        ///   - request: A request containing a single `Primandproper_Platform_Waitlists_V1_ArchiveSignupRequest` message.
        ///   - serializer: A serializer for `Primandproper_Platform_Waitlists_V1_ArchiveSignupRequest` messages.
        ///   - deserializer: A deserializer for `Primandproper_Platform_Waitlists_V1_ArchiveSignupResponse` messages.
        ///   - options: Options to apply to this RPC.
        ///   - handleResponse: A closure which handles the response, the result of which is
        ///       returned to the caller. Returning from the closure will cancel the RPC if it
        ///       hasn't already finished.
        /// - Returns: The result of `handleResponse`.
        func archiveSignup<Result>(
            request: GRPCCore.ClientRequest<Primandproper_Platform_Waitlists_V1_ArchiveSignupRequest>,
            serializer: some GRPCCore.MessageSerializer<Primandproper_Platform_Waitlists_V1_ArchiveSignupRequest>,
            deserializer: some GRPCCore.MessageDeserializer<Primandproper_Platform_Waitlists_V1_ArchiveSignupResponse>,
            options: GRPCCore.CallOptions,
            onResponse handleResponse: @Sendable @escaping (GRPCCore.ClientResponse<Primandproper_Platform_Waitlists_V1_ArchiveSignupResponse>) async throws -> Result
        ) async throws -> Result where Result: Sendable
    }

    /// Generated client for the "primandproper.platform.waitlists.v1.WaitlistsService" service.
    ///
    /// The ``Client`` provides an implementation of ``ClientProtocol`` which wraps
    /// a `GRPCCore.GRPCCClient`. The underlying `GRPCClient` provides the long-lived
    /// means of communication with the remote peer.
    ///
    /// > Source IDL Documentation:
    /// >
    /// > WaitlistsService is the whole of waitlists on the wire: all seventeen methods
    /// > of waitlists.Store, split by who calls them.
    /// > 
    /// > There are no absences, which is unusual on this lane and is the reason this
    /// > was the first of the ten domains to cross. Every other surface in the module
    /// > carves something out because its realistic caller is a worker on a timer, a
    /// > processor callback, or the consumer's own code inside its own transaction.
    /// > Nothing here has that shape: a waitlist has no queue protocol, no fan-out and
    /// > no provider callback, and every one of the seventeen is either a form
    /// > somebody submitted or a console somebody is looking at.
    /// > 
    /// > # The public three
    /// > 
    /// > ListOpenLists, Join and Withdraw are reachable without a grant, because the
    /// > caller is a person on a signup page who has not signed in and frequently has
    /// > no account to sign in to. That is the whole of what "public" means here: the
    /// > consumer's authentication interceptor still runs, and a caller who does arrive
    /// > with a principal has their signup attributed to them.
    /// > 
    /// > Public is not unguarded, and it is not talkative either. Join is refused for a
    /// > closed list, which is a fact about the list rather than about anybody's
    /// > address, and it answers uniformly for every outcome that is about an address
    /// > -- see JoinResponse, which is empty for that reason. Withdraw names a row, so
    /// > the standing to move it is asked of a seam the consumer implements -- see
    /// > WithdrawRequest. And the read a public caller gets is the catalog of open
    /// > lists, which is what a signup page publishes anyway.
    /// > 
    /// > # The administrative fourteen
    /// > 
    /// > List CRUD, the signup reads, the two lifecycle transitions, the note, the
    /// > archive and the erasure. Each is behind a grant, and waitlists/grpc's
    /// > Permissions is the default map a consumer composes into their policy.
    /// > 
    /// > GetSignupByContact is the one to look at twice. It is a read, it looks
    /// > harmless beside Join, and it is the difference between a service and an oracle
    /// > over which addresses are on which list. It is also the only place on this wire
    /// > that answers "is this address on this list" at all, now that the public Join
    /// > does not.
    internal struct Client<Transport>: ClientProtocol where Transport: GRPCCore.ClientTransport {
        private let client: GRPCCore.GRPCClient<Transport>

        /// Creates a new client wrapping the provided `GRPCCore.GRPCClient`.
        ///
        /// - Parameters:
        ///   - client: A `GRPCCore.GRPCClient` providing a communication channel to the service.
        internal init(wrapping client: GRPCCore.GRPCClient<Transport>) {
            self.client = client
        }

        /// Call the "CreateList" method.
        ///
        /// > Source IDL Documentation:
        /// >
        /// > The catalog: what lists exist, what they are for, and when each stops
        /// > taking signups. ListOpenLists is the public one.
        ///
        /// - Parameters:
        ///   - request: A request containing a single `Primandproper_Platform_Waitlists_V1_CreateListRequest` message.
        ///   - serializer: A serializer for `Primandproper_Platform_Waitlists_V1_CreateListRequest` messages.
        ///   - deserializer: A deserializer for `Primandproper_Platform_Waitlists_V1_CreateListResponse` messages.
        ///   - options: Options to apply to this RPC.
        ///   - handleResponse: A closure which handles the response, the result of which is
        ///       returned to the caller. Returning from the closure will cancel the RPC if it
        ///       hasn't already finished.
        /// - Returns: The result of `handleResponse`.
        internal func createList<Result>(
            request: GRPCCore.ClientRequest<Primandproper_Platform_Waitlists_V1_CreateListRequest>,
            serializer: some GRPCCore.MessageSerializer<Primandproper_Platform_Waitlists_V1_CreateListRequest>,
            deserializer: some GRPCCore.MessageDeserializer<Primandproper_Platform_Waitlists_V1_CreateListResponse>,
            options: GRPCCore.CallOptions = .defaults,
            onResponse handleResponse: @Sendable @escaping (GRPCCore.ClientResponse<Primandproper_Platform_Waitlists_V1_CreateListResponse>) async throws -> Result = { response in
                try response.message
            }
        ) async throws -> Result where Result: Sendable {
            try await self.client.unary(
                request: request,
                descriptor: Primandproper_Platform_Waitlists_V1_WaitlistsService.Method.CreateList.descriptor,
                serializer: serializer,
                deserializer: deserializer,
                options: options,
                onResponse: handleResponse
            )
        }

        /// Call the "GetList" method.
        ///
        /// - Parameters:
        ///   - request: A request containing a single `Primandproper_Platform_Waitlists_V1_GetListRequest` message.
        ///   - serializer: A serializer for `Primandproper_Platform_Waitlists_V1_GetListRequest` messages.
        ///   - deserializer: A deserializer for `Primandproper_Platform_Waitlists_V1_GetListResponse` messages.
        ///   - options: Options to apply to this RPC.
        ///   - handleResponse: A closure which handles the response, the result of which is
        ///       returned to the caller. Returning from the closure will cancel the RPC if it
        ///       hasn't already finished.
        /// - Returns: The result of `handleResponse`.
        internal func getList<Result>(
            request: GRPCCore.ClientRequest<Primandproper_Platform_Waitlists_V1_GetListRequest>,
            serializer: some GRPCCore.MessageSerializer<Primandproper_Platform_Waitlists_V1_GetListRequest>,
            deserializer: some GRPCCore.MessageDeserializer<Primandproper_Platform_Waitlists_V1_GetListResponse>,
            options: GRPCCore.CallOptions = .defaults,
            onResponse handleResponse: @Sendable @escaping (GRPCCore.ClientResponse<Primandproper_Platform_Waitlists_V1_GetListResponse>) async throws -> Result = { response in
                try response.message
            }
        ) async throws -> Result where Result: Sendable {
            try await self.client.unary(
                request: request,
                descriptor: Primandproper_Platform_Waitlists_V1_WaitlistsService.Method.GetList.descriptor,
                serializer: serializer,
                deserializer: deserializer,
                options: options,
                onResponse: handleResponse
            )
        }

        /// Call the "ListLists" method.
        ///
        /// - Parameters:
        ///   - request: A request containing a single `Primandproper_Platform_Waitlists_V1_ListListsRequest` message.
        ///   - serializer: A serializer for `Primandproper_Platform_Waitlists_V1_ListListsRequest` messages.
        ///   - deserializer: A deserializer for `Primandproper_Platform_Waitlists_V1_ListListsResponse` messages.
        ///   - options: Options to apply to this RPC.
        ///   - handleResponse: A closure which handles the response, the result of which is
        ///       returned to the caller. Returning from the closure will cancel the RPC if it
        ///       hasn't already finished.
        /// - Returns: The result of `handleResponse`.
        internal func listLists<Result>(
            request: GRPCCore.ClientRequest<Primandproper_Platform_Waitlists_V1_ListListsRequest>,
            serializer: some GRPCCore.MessageSerializer<Primandproper_Platform_Waitlists_V1_ListListsRequest>,
            deserializer: some GRPCCore.MessageDeserializer<Primandproper_Platform_Waitlists_V1_ListListsResponse>,
            options: GRPCCore.CallOptions = .defaults,
            onResponse handleResponse: @Sendable @escaping (GRPCCore.ClientResponse<Primandproper_Platform_Waitlists_V1_ListListsResponse>) async throws -> Result = { response in
                try response.message
            }
        ) async throws -> Result where Result: Sendable {
            try await self.client.unary(
                request: request,
                descriptor: Primandproper_Platform_Waitlists_V1_WaitlistsService.Method.ListLists.descriptor,
                serializer: serializer,
                deserializer: deserializer,
                options: options,
                onResponse: handleResponse
            )
        }

        /// Call the "ListOpenLists" method.
        ///
        /// - Parameters:
        ///   - request: A request containing a single `Primandproper_Platform_Waitlists_V1_ListOpenListsRequest` message.
        ///   - serializer: A serializer for `Primandproper_Platform_Waitlists_V1_ListOpenListsRequest` messages.
        ///   - deserializer: A deserializer for `Primandproper_Platform_Waitlists_V1_ListOpenListsResponse` messages.
        ///   - options: Options to apply to this RPC.
        ///   - handleResponse: A closure which handles the response, the result of which is
        ///       returned to the caller. Returning from the closure will cancel the RPC if it
        ///       hasn't already finished.
        /// - Returns: The result of `handleResponse`.
        internal func listOpenLists<Result>(
            request: GRPCCore.ClientRequest<Primandproper_Platform_Waitlists_V1_ListOpenListsRequest>,
            serializer: some GRPCCore.MessageSerializer<Primandproper_Platform_Waitlists_V1_ListOpenListsRequest>,
            deserializer: some GRPCCore.MessageDeserializer<Primandproper_Platform_Waitlists_V1_ListOpenListsResponse>,
            options: GRPCCore.CallOptions = .defaults,
            onResponse handleResponse: @Sendable @escaping (GRPCCore.ClientResponse<Primandproper_Platform_Waitlists_V1_ListOpenListsResponse>) async throws -> Result = { response in
                try response.message
            }
        ) async throws -> Result where Result: Sendable {
            try await self.client.unary(
                request: request,
                descriptor: Primandproper_Platform_Waitlists_V1_WaitlistsService.Method.ListOpenLists.descriptor,
                serializer: serializer,
                deserializer: deserializer,
                options: options,
                onResponse: handleResponse
            )
        }

        /// Call the "UpdateList" method.
        ///
        /// - Parameters:
        ///   - request: A request containing a single `Primandproper_Platform_Waitlists_V1_UpdateListRequest` message.
        ///   - serializer: A serializer for `Primandproper_Platform_Waitlists_V1_UpdateListRequest` messages.
        ///   - deserializer: A deserializer for `Primandproper_Platform_Waitlists_V1_UpdateListResponse` messages.
        ///   - options: Options to apply to this RPC.
        ///   - handleResponse: A closure which handles the response, the result of which is
        ///       returned to the caller. Returning from the closure will cancel the RPC if it
        ///       hasn't already finished.
        /// - Returns: The result of `handleResponse`.
        internal func updateList<Result>(
            request: GRPCCore.ClientRequest<Primandproper_Platform_Waitlists_V1_UpdateListRequest>,
            serializer: some GRPCCore.MessageSerializer<Primandproper_Platform_Waitlists_V1_UpdateListRequest>,
            deserializer: some GRPCCore.MessageDeserializer<Primandproper_Platform_Waitlists_V1_UpdateListResponse>,
            options: GRPCCore.CallOptions = .defaults,
            onResponse handleResponse: @Sendable @escaping (GRPCCore.ClientResponse<Primandproper_Platform_Waitlists_V1_UpdateListResponse>) async throws -> Result = { response in
                try response.message
            }
        ) async throws -> Result where Result: Sendable {
            try await self.client.unary(
                request: request,
                descriptor: Primandproper_Platform_Waitlists_V1_WaitlistsService.Method.UpdateList.descriptor,
                serializer: serializer,
                deserializer: deserializer,
                options: options,
                onResponse: handleResponse
            )
        }

        /// Call the "ArchiveList" method.
        ///
        /// - Parameters:
        ///   - request: A request containing a single `Primandproper_Platform_Waitlists_V1_ArchiveListRequest` message.
        ///   - serializer: A serializer for `Primandproper_Platform_Waitlists_V1_ArchiveListRequest` messages.
        ///   - deserializer: A deserializer for `Primandproper_Platform_Waitlists_V1_ArchiveListResponse` messages.
        ///   - options: Options to apply to this RPC.
        ///   - handleResponse: A closure which handles the response, the result of which is
        ///       returned to the caller. Returning from the closure will cancel the RPC if it
        ///       hasn't already finished.
        /// - Returns: The result of `handleResponse`.
        internal func archiveList<Result>(
            request: GRPCCore.ClientRequest<Primandproper_Platform_Waitlists_V1_ArchiveListRequest>,
            serializer: some GRPCCore.MessageSerializer<Primandproper_Platform_Waitlists_V1_ArchiveListRequest>,
            deserializer: some GRPCCore.MessageDeserializer<Primandproper_Platform_Waitlists_V1_ArchiveListResponse>,
            options: GRPCCore.CallOptions = .defaults,
            onResponse handleResponse: @Sendable @escaping (GRPCCore.ClientResponse<Primandproper_Platform_Waitlists_V1_ArchiveListResponse>) async throws -> Result = { response in
                try response.message
            }
        ) async throws -> Result where Result: Sendable {
            try await self.client.unary(
                request: request,
                descriptor: Primandproper_Platform_Waitlists_V1_WaitlistsService.Method.ArchiveList.descriptor,
                serializer: serializer,
                deserializer: deserializer,
                options: options,
                onResponse: handleResponse
            )
        }

        /// Call the "Join" method.
        ///
        /// > Source IDL Documentation:
        /// >
        /// > The queue. Join and Withdraw are the person's own; the rest are the
        /// > operator's.
        ///
        /// - Parameters:
        ///   - request: A request containing a single `Primandproper_Platform_Waitlists_V1_JoinRequest` message.
        ///   - serializer: A serializer for `Primandproper_Platform_Waitlists_V1_JoinRequest` messages.
        ///   - deserializer: A deserializer for `Primandproper_Platform_Waitlists_V1_JoinResponse` messages.
        ///   - options: Options to apply to this RPC.
        ///   - handleResponse: A closure which handles the response, the result of which is
        ///       returned to the caller. Returning from the closure will cancel the RPC if it
        ///       hasn't already finished.
        /// - Returns: The result of `handleResponse`.
        internal func join<Result>(
            request: GRPCCore.ClientRequest<Primandproper_Platform_Waitlists_V1_JoinRequest>,
            serializer: some GRPCCore.MessageSerializer<Primandproper_Platform_Waitlists_V1_JoinRequest>,
            deserializer: some GRPCCore.MessageDeserializer<Primandproper_Platform_Waitlists_V1_JoinResponse>,
            options: GRPCCore.CallOptions = .defaults,
            onResponse handleResponse: @Sendable @escaping (GRPCCore.ClientResponse<Primandproper_Platform_Waitlists_V1_JoinResponse>) async throws -> Result = { response in
                try response.message
            }
        ) async throws -> Result where Result: Sendable {
            try await self.client.unary(
                request: request,
                descriptor: Primandproper_Platform_Waitlists_V1_WaitlistsService.Method.Join.descriptor,
                serializer: serializer,
                deserializer: deserializer,
                options: options,
                onResponse: handleResponse
            )
        }

        /// Call the "GetSignup" method.
        ///
        /// - Parameters:
        ///   - request: A request containing a single `Primandproper_Platform_Waitlists_V1_GetSignupRequest` message.
        ///   - serializer: A serializer for `Primandproper_Platform_Waitlists_V1_GetSignupRequest` messages.
        ///   - deserializer: A deserializer for `Primandproper_Platform_Waitlists_V1_GetSignupResponse` messages.
        ///   - options: Options to apply to this RPC.
        ///   - handleResponse: A closure which handles the response, the result of which is
        ///       returned to the caller. Returning from the closure will cancel the RPC if it
        ///       hasn't already finished.
        /// - Returns: The result of `handleResponse`.
        internal func getSignup<Result>(
            request: GRPCCore.ClientRequest<Primandproper_Platform_Waitlists_V1_GetSignupRequest>,
            serializer: some GRPCCore.MessageSerializer<Primandproper_Platform_Waitlists_V1_GetSignupRequest>,
            deserializer: some GRPCCore.MessageDeserializer<Primandproper_Platform_Waitlists_V1_GetSignupResponse>,
            options: GRPCCore.CallOptions = .defaults,
            onResponse handleResponse: @Sendable @escaping (GRPCCore.ClientResponse<Primandproper_Platform_Waitlists_V1_GetSignupResponse>) async throws -> Result = { response in
                try response.message
            }
        ) async throws -> Result where Result: Sendable {
            try await self.client.unary(
                request: request,
                descriptor: Primandproper_Platform_Waitlists_V1_WaitlistsService.Method.GetSignup.descriptor,
                serializer: serializer,
                deserializer: deserializer,
                options: options,
                onResponse: handleResponse
            )
        }

        /// Call the "GetSignupByContact" method.
        ///
        /// - Parameters:
        ///   - request: A request containing a single `Primandproper_Platform_Waitlists_V1_GetSignupByContactRequest` message.
        ///   - serializer: A serializer for `Primandproper_Platform_Waitlists_V1_GetSignupByContactRequest` messages.
        ///   - deserializer: A deserializer for `Primandproper_Platform_Waitlists_V1_GetSignupByContactResponse` messages.
        ///   - options: Options to apply to this RPC.
        ///   - handleResponse: A closure which handles the response, the result of which is
        ///       returned to the caller. Returning from the closure will cancel the RPC if it
        ///       hasn't already finished.
        /// - Returns: The result of `handleResponse`.
        internal func getSignupByContact<Result>(
            request: GRPCCore.ClientRequest<Primandproper_Platform_Waitlists_V1_GetSignupByContactRequest>,
            serializer: some GRPCCore.MessageSerializer<Primandproper_Platform_Waitlists_V1_GetSignupByContactRequest>,
            deserializer: some GRPCCore.MessageDeserializer<Primandproper_Platform_Waitlists_V1_GetSignupByContactResponse>,
            options: GRPCCore.CallOptions = .defaults,
            onResponse handleResponse: @Sendable @escaping (GRPCCore.ClientResponse<Primandproper_Platform_Waitlists_V1_GetSignupByContactResponse>) async throws -> Result = { response in
                try response.message
            }
        ) async throws -> Result where Result: Sendable {
            try await self.client.unary(
                request: request,
                descriptor: Primandproper_Platform_Waitlists_V1_WaitlistsService.Method.GetSignupByContact.descriptor,
                serializer: serializer,
                deserializer: deserializer,
                options: options,
                onResponse: handleResponse
            )
        }

        /// Call the "ListSignups" method.
        ///
        /// - Parameters:
        ///   - request: A request containing a single `Primandproper_Platform_Waitlists_V1_ListSignupsRequest` message.
        ///   - serializer: A serializer for `Primandproper_Platform_Waitlists_V1_ListSignupsRequest` messages.
        ///   - deserializer: A deserializer for `Primandproper_Platform_Waitlists_V1_ListSignupsResponse` messages.
        ///   - options: Options to apply to this RPC.
        ///   - handleResponse: A closure which handles the response, the result of which is
        ///       returned to the caller. Returning from the closure will cancel the RPC if it
        ///       hasn't already finished.
        /// - Returns: The result of `handleResponse`.
        internal func listSignups<Result>(
            request: GRPCCore.ClientRequest<Primandproper_Platform_Waitlists_V1_ListSignupsRequest>,
            serializer: some GRPCCore.MessageSerializer<Primandproper_Platform_Waitlists_V1_ListSignupsRequest>,
            deserializer: some GRPCCore.MessageDeserializer<Primandproper_Platform_Waitlists_V1_ListSignupsResponse>,
            options: GRPCCore.CallOptions = .defaults,
            onResponse handleResponse: @Sendable @escaping (GRPCCore.ClientResponse<Primandproper_Platform_Waitlists_V1_ListSignupsResponse>) async throws -> Result = { response in
                try response.message
            }
        ) async throws -> Result where Result: Sendable {
            try await self.client.unary(
                request: request,
                descriptor: Primandproper_Platform_Waitlists_V1_WaitlistsService.Method.ListSignups.descriptor,
                serializer: serializer,
                deserializer: deserializer,
                options: options,
                onResponse: handleResponse
            )
        }

        /// Call the "ListSignupsForSubject" method.
        ///
        /// - Parameters:
        ///   - request: A request containing a single `Primandproper_Platform_Waitlists_V1_ListSignupsForSubjectRequest` message.
        ///   - serializer: A serializer for `Primandproper_Platform_Waitlists_V1_ListSignupsForSubjectRequest` messages.
        ///   - deserializer: A deserializer for `Primandproper_Platform_Waitlists_V1_ListSignupsForSubjectResponse` messages.
        ///   - options: Options to apply to this RPC.
        ///   - handleResponse: A closure which handles the response, the result of which is
        ///       returned to the caller. Returning from the closure will cancel the RPC if it
        ///       hasn't already finished.
        /// - Returns: The result of `handleResponse`.
        internal func listSignupsForSubject<Result>(
            request: GRPCCore.ClientRequest<Primandproper_Platform_Waitlists_V1_ListSignupsForSubjectRequest>,
            serializer: some GRPCCore.MessageSerializer<Primandproper_Platform_Waitlists_V1_ListSignupsForSubjectRequest>,
            deserializer: some GRPCCore.MessageDeserializer<Primandproper_Platform_Waitlists_V1_ListSignupsForSubjectResponse>,
            options: GRPCCore.CallOptions = .defaults,
            onResponse handleResponse: @Sendable @escaping (GRPCCore.ClientResponse<Primandproper_Platform_Waitlists_V1_ListSignupsForSubjectResponse>) async throws -> Result = { response in
                try response.message
            }
        ) async throws -> Result where Result: Sendable {
            try await self.client.unary(
                request: request,
                descriptor: Primandproper_Platform_Waitlists_V1_WaitlistsService.Method.ListSignupsForSubject.descriptor,
                serializer: serializer,
                deserializer: deserializer,
                options: options,
                onResponse: handleResponse
            )
        }

        /// Call the "UpdateSignupNotes" method.
        ///
        /// - Parameters:
        ///   - request: A request containing a single `Primandproper_Platform_Waitlists_V1_UpdateSignupNotesRequest` message.
        ///   - serializer: A serializer for `Primandproper_Platform_Waitlists_V1_UpdateSignupNotesRequest` messages.
        ///   - deserializer: A deserializer for `Primandproper_Platform_Waitlists_V1_UpdateSignupNotesResponse` messages.
        ///   - options: Options to apply to this RPC.
        ///   - handleResponse: A closure which handles the response, the result of which is
        ///       returned to the caller. Returning from the closure will cancel the RPC if it
        ///       hasn't already finished.
        /// - Returns: The result of `handleResponse`.
        internal func updateSignupNotes<Result>(
            request: GRPCCore.ClientRequest<Primandproper_Platform_Waitlists_V1_UpdateSignupNotesRequest>,
            serializer: some GRPCCore.MessageSerializer<Primandproper_Platform_Waitlists_V1_UpdateSignupNotesRequest>,
            deserializer: some GRPCCore.MessageDeserializer<Primandproper_Platform_Waitlists_V1_UpdateSignupNotesResponse>,
            options: GRPCCore.CallOptions = .defaults,
            onResponse handleResponse: @Sendable @escaping (GRPCCore.ClientResponse<Primandproper_Platform_Waitlists_V1_UpdateSignupNotesResponse>) async throws -> Result = { response in
                try response.message
            }
        ) async throws -> Result where Result: Sendable {
            try await self.client.unary(
                request: request,
                descriptor: Primandproper_Platform_Waitlists_V1_WaitlistsService.Method.UpdateSignupNotes.descriptor,
                serializer: serializer,
                deserializer: deserializer,
                options: options,
                onResponse: handleResponse
            )
        }

        /// Call the "Invite" method.
        ///
        /// - Parameters:
        ///   - request: A request containing a single `Primandproper_Platform_Waitlists_V1_InviteRequest` message.
        ///   - serializer: A serializer for `Primandproper_Platform_Waitlists_V1_InviteRequest` messages.
        ///   - deserializer: A deserializer for `Primandproper_Platform_Waitlists_V1_InviteResponse` messages.
        ///   - options: Options to apply to this RPC.
        ///   - handleResponse: A closure which handles the response, the result of which is
        ///       returned to the caller. Returning from the closure will cancel the RPC if it
        ///       hasn't already finished.
        /// - Returns: The result of `handleResponse`.
        internal func invite<Result>(
            request: GRPCCore.ClientRequest<Primandproper_Platform_Waitlists_V1_InviteRequest>,
            serializer: some GRPCCore.MessageSerializer<Primandproper_Platform_Waitlists_V1_InviteRequest>,
            deserializer: some GRPCCore.MessageDeserializer<Primandproper_Platform_Waitlists_V1_InviteResponse>,
            options: GRPCCore.CallOptions = .defaults,
            onResponse handleResponse: @Sendable @escaping (GRPCCore.ClientResponse<Primandproper_Platform_Waitlists_V1_InviteResponse>) async throws -> Result = { response in
                try response.message
            }
        ) async throws -> Result where Result: Sendable {
            try await self.client.unary(
                request: request,
                descriptor: Primandproper_Platform_Waitlists_V1_WaitlistsService.Method.Invite.descriptor,
                serializer: serializer,
                deserializer: deserializer,
                options: options,
                onResponse: handleResponse
            )
        }

        /// Call the "Convert" method.
        ///
        /// - Parameters:
        ///   - request: A request containing a single `Primandproper_Platform_Waitlists_V1_ConvertRequest` message.
        ///   - serializer: A serializer for `Primandproper_Platform_Waitlists_V1_ConvertRequest` messages.
        ///   - deserializer: A deserializer for `Primandproper_Platform_Waitlists_V1_ConvertResponse` messages.
        ///   - options: Options to apply to this RPC.
        ///   - handleResponse: A closure which handles the response, the result of which is
        ///       returned to the caller. Returning from the closure will cancel the RPC if it
        ///       hasn't already finished.
        /// - Returns: The result of `handleResponse`.
        internal func convert<Result>(
            request: GRPCCore.ClientRequest<Primandproper_Platform_Waitlists_V1_ConvertRequest>,
            serializer: some GRPCCore.MessageSerializer<Primandproper_Platform_Waitlists_V1_ConvertRequest>,
            deserializer: some GRPCCore.MessageDeserializer<Primandproper_Platform_Waitlists_V1_ConvertResponse>,
            options: GRPCCore.CallOptions = .defaults,
            onResponse handleResponse: @Sendable @escaping (GRPCCore.ClientResponse<Primandproper_Platform_Waitlists_V1_ConvertResponse>) async throws -> Result = { response in
                try response.message
            }
        ) async throws -> Result where Result: Sendable {
            try await self.client.unary(
                request: request,
                descriptor: Primandproper_Platform_Waitlists_V1_WaitlistsService.Method.Convert.descriptor,
                serializer: serializer,
                deserializer: deserializer,
                options: options,
                onResponse: handleResponse
            )
        }

        /// Call the "Withdraw" method.
        ///
        /// - Parameters:
        ///   - request: A request containing a single `Primandproper_Platform_Waitlists_V1_WithdrawRequest` message.
        ///   - serializer: A serializer for `Primandproper_Platform_Waitlists_V1_WithdrawRequest` messages.
        ///   - deserializer: A deserializer for `Primandproper_Platform_Waitlists_V1_WithdrawResponse` messages.
        ///   - options: Options to apply to this RPC.
        ///   - handleResponse: A closure which handles the response, the result of which is
        ///       returned to the caller. Returning from the closure will cancel the RPC if it
        ///       hasn't already finished.
        /// - Returns: The result of `handleResponse`.
        internal func withdraw<Result>(
            request: GRPCCore.ClientRequest<Primandproper_Platform_Waitlists_V1_WithdrawRequest>,
            serializer: some GRPCCore.MessageSerializer<Primandproper_Platform_Waitlists_V1_WithdrawRequest>,
            deserializer: some GRPCCore.MessageDeserializer<Primandproper_Platform_Waitlists_V1_WithdrawResponse>,
            options: GRPCCore.CallOptions = .defaults,
            onResponse handleResponse: @Sendable @escaping (GRPCCore.ClientResponse<Primandproper_Platform_Waitlists_V1_WithdrawResponse>) async throws -> Result = { response in
                try response.message
            }
        ) async throws -> Result where Result: Sendable {
            try await self.client.unary(
                request: request,
                descriptor: Primandproper_Platform_Waitlists_V1_WaitlistsService.Method.Withdraw.descriptor,
                serializer: serializer,
                deserializer: deserializer,
                options: options,
                onResponse: handleResponse
            )
        }

        /// Call the "WithdrawSignupsForSubject" method.
        ///
        /// - Parameters:
        ///   - request: A request containing a single `Primandproper_Platform_Waitlists_V1_WithdrawSignupsForSubjectRequest` message.
        ///   - serializer: A serializer for `Primandproper_Platform_Waitlists_V1_WithdrawSignupsForSubjectRequest` messages.
        ///   - deserializer: A deserializer for `Primandproper_Platform_Waitlists_V1_WithdrawSignupsForSubjectResponse` messages.
        ///   - options: Options to apply to this RPC.
        ///   - handleResponse: A closure which handles the response, the result of which is
        ///       returned to the caller. Returning from the closure will cancel the RPC if it
        ///       hasn't already finished.
        /// - Returns: The result of `handleResponse`.
        internal func withdrawSignupsForSubject<Result>(
            request: GRPCCore.ClientRequest<Primandproper_Platform_Waitlists_V1_WithdrawSignupsForSubjectRequest>,
            serializer: some GRPCCore.MessageSerializer<Primandproper_Platform_Waitlists_V1_WithdrawSignupsForSubjectRequest>,
            deserializer: some GRPCCore.MessageDeserializer<Primandproper_Platform_Waitlists_V1_WithdrawSignupsForSubjectResponse>,
            options: GRPCCore.CallOptions = .defaults,
            onResponse handleResponse: @Sendable @escaping (GRPCCore.ClientResponse<Primandproper_Platform_Waitlists_V1_WithdrawSignupsForSubjectResponse>) async throws -> Result = { response in
                try response.message
            }
        ) async throws -> Result where Result: Sendable {
            try await self.client.unary(
                request: request,
                descriptor: Primandproper_Platform_Waitlists_V1_WaitlistsService.Method.WithdrawSignupsForSubject.descriptor,
                serializer: serializer,
                deserializer: deserializer,
                options: options,
                onResponse: handleResponse
            )
        }

        /// Call the "ArchiveSignup" method.
        ///
        /// - Parameters:
        ///   - request: A request containing a single `Primandproper_Platform_Waitlists_V1_ArchiveSignupRequest` message.
        ///   - serializer: A serializer for `Primandproper_Platform_Waitlists_V1_ArchiveSignupRequest` messages.
        ///   - deserializer: A deserializer for `Primandproper_Platform_Waitlists_V1_ArchiveSignupResponse` messages.
        ///   - options: Options to apply to this RPC.
        ///   - handleResponse: A closure which handles the response, the result of which is
        ///       returned to the caller. Returning from the closure will cancel the RPC if it
        ///       hasn't already finished.
        /// - Returns: The result of `handleResponse`.
        internal func archiveSignup<Result>(
            request: GRPCCore.ClientRequest<Primandproper_Platform_Waitlists_V1_ArchiveSignupRequest>,
            serializer: some GRPCCore.MessageSerializer<Primandproper_Platform_Waitlists_V1_ArchiveSignupRequest>,
            deserializer: some GRPCCore.MessageDeserializer<Primandproper_Platform_Waitlists_V1_ArchiveSignupResponse>,
            options: GRPCCore.CallOptions = .defaults,
            onResponse handleResponse: @Sendable @escaping (GRPCCore.ClientResponse<Primandproper_Platform_Waitlists_V1_ArchiveSignupResponse>) async throws -> Result = { response in
                try response.message
            }
        ) async throws -> Result where Result: Sendable {
            try await self.client.unary(
                request: request,
                descriptor: Primandproper_Platform_Waitlists_V1_WaitlistsService.Method.ArchiveSignup.descriptor,
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
extension Primandproper_Platform_Waitlists_V1_WaitlistsService.ClientProtocol {
    /// Call the "CreateList" method.
    ///
    /// > Source IDL Documentation:
    /// >
    /// > The catalog: what lists exist, what they are for, and when each stops
    /// > taking signups. ListOpenLists is the public one.
    ///
    /// - Parameters:
    ///   - request: A request containing a single `Primandproper_Platform_Waitlists_V1_CreateListRequest` message.
    ///   - options: Options to apply to this RPC.
    ///   - handleResponse: A closure which handles the response, the result of which is
    ///       returned to the caller. Returning from the closure will cancel the RPC if it
    ///       hasn't already finished.
    /// - Returns: The result of `handleResponse`.
    internal func createList<Result>(
        request: GRPCCore.ClientRequest<Primandproper_Platform_Waitlists_V1_CreateListRequest>,
        options: GRPCCore.CallOptions = .defaults,
        onResponse handleResponse: @Sendable @escaping (GRPCCore.ClientResponse<Primandproper_Platform_Waitlists_V1_CreateListResponse>) async throws -> Result = { response in
            try response.message
        }
    ) async throws -> Result where Result: Sendable {
        try await self.createList(
            request: request,
            serializer: GRPCProtobuf.ProtobufSerializer<Primandproper_Platform_Waitlists_V1_CreateListRequest>(),
            deserializer: GRPCProtobuf.ProtobufDeserializer<Primandproper_Platform_Waitlists_V1_CreateListResponse>(),
            options: options,
            onResponse: handleResponse
        )
    }

    /// Call the "GetList" method.
    ///
    /// - Parameters:
    ///   - request: A request containing a single `Primandproper_Platform_Waitlists_V1_GetListRequest` message.
    ///   - options: Options to apply to this RPC.
    ///   - handleResponse: A closure which handles the response, the result of which is
    ///       returned to the caller. Returning from the closure will cancel the RPC if it
    ///       hasn't already finished.
    /// - Returns: The result of `handleResponse`.
    internal func getList<Result>(
        request: GRPCCore.ClientRequest<Primandproper_Platform_Waitlists_V1_GetListRequest>,
        options: GRPCCore.CallOptions = .defaults,
        onResponse handleResponse: @Sendable @escaping (GRPCCore.ClientResponse<Primandproper_Platform_Waitlists_V1_GetListResponse>) async throws -> Result = { response in
            try response.message
        }
    ) async throws -> Result where Result: Sendable {
        try await self.getList(
            request: request,
            serializer: GRPCProtobuf.ProtobufSerializer<Primandproper_Platform_Waitlists_V1_GetListRequest>(),
            deserializer: GRPCProtobuf.ProtobufDeserializer<Primandproper_Platform_Waitlists_V1_GetListResponse>(),
            options: options,
            onResponse: handleResponse
        )
    }

    /// Call the "ListLists" method.
    ///
    /// - Parameters:
    ///   - request: A request containing a single `Primandproper_Platform_Waitlists_V1_ListListsRequest` message.
    ///   - options: Options to apply to this RPC.
    ///   - handleResponse: A closure which handles the response, the result of which is
    ///       returned to the caller. Returning from the closure will cancel the RPC if it
    ///       hasn't already finished.
    /// - Returns: The result of `handleResponse`.
    internal func listLists<Result>(
        request: GRPCCore.ClientRequest<Primandproper_Platform_Waitlists_V1_ListListsRequest>,
        options: GRPCCore.CallOptions = .defaults,
        onResponse handleResponse: @Sendable @escaping (GRPCCore.ClientResponse<Primandproper_Platform_Waitlists_V1_ListListsResponse>) async throws -> Result = { response in
            try response.message
        }
    ) async throws -> Result where Result: Sendable {
        try await self.listLists(
            request: request,
            serializer: GRPCProtobuf.ProtobufSerializer<Primandproper_Platform_Waitlists_V1_ListListsRequest>(),
            deserializer: GRPCProtobuf.ProtobufDeserializer<Primandproper_Platform_Waitlists_V1_ListListsResponse>(),
            options: options,
            onResponse: handleResponse
        )
    }

    /// Call the "ListOpenLists" method.
    ///
    /// - Parameters:
    ///   - request: A request containing a single `Primandproper_Platform_Waitlists_V1_ListOpenListsRequest` message.
    ///   - options: Options to apply to this RPC.
    ///   - handleResponse: A closure which handles the response, the result of which is
    ///       returned to the caller. Returning from the closure will cancel the RPC if it
    ///       hasn't already finished.
    /// - Returns: The result of `handleResponse`.
    internal func listOpenLists<Result>(
        request: GRPCCore.ClientRequest<Primandproper_Platform_Waitlists_V1_ListOpenListsRequest>,
        options: GRPCCore.CallOptions = .defaults,
        onResponse handleResponse: @Sendable @escaping (GRPCCore.ClientResponse<Primandproper_Platform_Waitlists_V1_ListOpenListsResponse>) async throws -> Result = { response in
            try response.message
        }
    ) async throws -> Result where Result: Sendable {
        try await self.listOpenLists(
            request: request,
            serializer: GRPCProtobuf.ProtobufSerializer<Primandproper_Platform_Waitlists_V1_ListOpenListsRequest>(),
            deserializer: GRPCProtobuf.ProtobufDeserializer<Primandproper_Platform_Waitlists_V1_ListOpenListsResponse>(),
            options: options,
            onResponse: handleResponse
        )
    }

    /// Call the "UpdateList" method.
    ///
    /// - Parameters:
    ///   - request: A request containing a single `Primandproper_Platform_Waitlists_V1_UpdateListRequest` message.
    ///   - options: Options to apply to this RPC.
    ///   - handleResponse: A closure which handles the response, the result of which is
    ///       returned to the caller. Returning from the closure will cancel the RPC if it
    ///       hasn't already finished.
    /// - Returns: The result of `handleResponse`.
    internal func updateList<Result>(
        request: GRPCCore.ClientRequest<Primandproper_Platform_Waitlists_V1_UpdateListRequest>,
        options: GRPCCore.CallOptions = .defaults,
        onResponse handleResponse: @Sendable @escaping (GRPCCore.ClientResponse<Primandproper_Platform_Waitlists_V1_UpdateListResponse>) async throws -> Result = { response in
            try response.message
        }
    ) async throws -> Result where Result: Sendable {
        try await self.updateList(
            request: request,
            serializer: GRPCProtobuf.ProtobufSerializer<Primandproper_Platform_Waitlists_V1_UpdateListRequest>(),
            deserializer: GRPCProtobuf.ProtobufDeserializer<Primandproper_Platform_Waitlists_V1_UpdateListResponse>(),
            options: options,
            onResponse: handleResponse
        )
    }

    /// Call the "ArchiveList" method.
    ///
    /// - Parameters:
    ///   - request: A request containing a single `Primandproper_Platform_Waitlists_V1_ArchiveListRequest` message.
    ///   - options: Options to apply to this RPC.
    ///   - handleResponse: A closure which handles the response, the result of which is
    ///       returned to the caller. Returning from the closure will cancel the RPC if it
    ///       hasn't already finished.
    /// - Returns: The result of `handleResponse`.
    internal func archiveList<Result>(
        request: GRPCCore.ClientRequest<Primandproper_Platform_Waitlists_V1_ArchiveListRequest>,
        options: GRPCCore.CallOptions = .defaults,
        onResponse handleResponse: @Sendable @escaping (GRPCCore.ClientResponse<Primandproper_Platform_Waitlists_V1_ArchiveListResponse>) async throws -> Result = { response in
            try response.message
        }
    ) async throws -> Result where Result: Sendable {
        try await self.archiveList(
            request: request,
            serializer: GRPCProtobuf.ProtobufSerializer<Primandproper_Platform_Waitlists_V1_ArchiveListRequest>(),
            deserializer: GRPCProtobuf.ProtobufDeserializer<Primandproper_Platform_Waitlists_V1_ArchiveListResponse>(),
            options: options,
            onResponse: handleResponse
        )
    }

    /// Call the "Join" method.
    ///
    /// > Source IDL Documentation:
    /// >
    /// > The queue. Join and Withdraw are the person's own; the rest are the
    /// > operator's.
    ///
    /// - Parameters:
    ///   - request: A request containing a single `Primandproper_Platform_Waitlists_V1_JoinRequest` message.
    ///   - options: Options to apply to this RPC.
    ///   - handleResponse: A closure which handles the response, the result of which is
    ///       returned to the caller. Returning from the closure will cancel the RPC if it
    ///       hasn't already finished.
    /// - Returns: The result of `handleResponse`.
    internal func join<Result>(
        request: GRPCCore.ClientRequest<Primandproper_Platform_Waitlists_V1_JoinRequest>,
        options: GRPCCore.CallOptions = .defaults,
        onResponse handleResponse: @Sendable @escaping (GRPCCore.ClientResponse<Primandproper_Platform_Waitlists_V1_JoinResponse>) async throws -> Result = { response in
            try response.message
        }
    ) async throws -> Result where Result: Sendable {
        try await self.join(
            request: request,
            serializer: GRPCProtobuf.ProtobufSerializer<Primandproper_Platform_Waitlists_V1_JoinRequest>(),
            deserializer: GRPCProtobuf.ProtobufDeserializer<Primandproper_Platform_Waitlists_V1_JoinResponse>(),
            options: options,
            onResponse: handleResponse
        )
    }

    /// Call the "GetSignup" method.
    ///
    /// - Parameters:
    ///   - request: A request containing a single `Primandproper_Platform_Waitlists_V1_GetSignupRequest` message.
    ///   - options: Options to apply to this RPC.
    ///   - handleResponse: A closure which handles the response, the result of which is
    ///       returned to the caller. Returning from the closure will cancel the RPC if it
    ///       hasn't already finished.
    /// - Returns: The result of `handleResponse`.
    internal func getSignup<Result>(
        request: GRPCCore.ClientRequest<Primandproper_Platform_Waitlists_V1_GetSignupRequest>,
        options: GRPCCore.CallOptions = .defaults,
        onResponse handleResponse: @Sendable @escaping (GRPCCore.ClientResponse<Primandproper_Platform_Waitlists_V1_GetSignupResponse>) async throws -> Result = { response in
            try response.message
        }
    ) async throws -> Result where Result: Sendable {
        try await self.getSignup(
            request: request,
            serializer: GRPCProtobuf.ProtobufSerializer<Primandproper_Platform_Waitlists_V1_GetSignupRequest>(),
            deserializer: GRPCProtobuf.ProtobufDeserializer<Primandproper_Platform_Waitlists_V1_GetSignupResponse>(),
            options: options,
            onResponse: handleResponse
        )
    }

    /// Call the "GetSignupByContact" method.
    ///
    /// - Parameters:
    ///   - request: A request containing a single `Primandproper_Platform_Waitlists_V1_GetSignupByContactRequest` message.
    ///   - options: Options to apply to this RPC.
    ///   - handleResponse: A closure which handles the response, the result of which is
    ///       returned to the caller. Returning from the closure will cancel the RPC if it
    ///       hasn't already finished.
    /// - Returns: The result of `handleResponse`.
    internal func getSignupByContact<Result>(
        request: GRPCCore.ClientRequest<Primandproper_Platform_Waitlists_V1_GetSignupByContactRequest>,
        options: GRPCCore.CallOptions = .defaults,
        onResponse handleResponse: @Sendable @escaping (GRPCCore.ClientResponse<Primandproper_Platform_Waitlists_V1_GetSignupByContactResponse>) async throws -> Result = { response in
            try response.message
        }
    ) async throws -> Result where Result: Sendable {
        try await self.getSignupByContact(
            request: request,
            serializer: GRPCProtobuf.ProtobufSerializer<Primandproper_Platform_Waitlists_V1_GetSignupByContactRequest>(),
            deserializer: GRPCProtobuf.ProtobufDeserializer<Primandproper_Platform_Waitlists_V1_GetSignupByContactResponse>(),
            options: options,
            onResponse: handleResponse
        )
    }

    /// Call the "ListSignups" method.
    ///
    /// - Parameters:
    ///   - request: A request containing a single `Primandproper_Platform_Waitlists_V1_ListSignupsRequest` message.
    ///   - options: Options to apply to this RPC.
    ///   - handleResponse: A closure which handles the response, the result of which is
    ///       returned to the caller. Returning from the closure will cancel the RPC if it
    ///       hasn't already finished.
    /// - Returns: The result of `handleResponse`.
    internal func listSignups<Result>(
        request: GRPCCore.ClientRequest<Primandproper_Platform_Waitlists_V1_ListSignupsRequest>,
        options: GRPCCore.CallOptions = .defaults,
        onResponse handleResponse: @Sendable @escaping (GRPCCore.ClientResponse<Primandproper_Platform_Waitlists_V1_ListSignupsResponse>) async throws -> Result = { response in
            try response.message
        }
    ) async throws -> Result where Result: Sendable {
        try await self.listSignups(
            request: request,
            serializer: GRPCProtobuf.ProtobufSerializer<Primandproper_Platform_Waitlists_V1_ListSignupsRequest>(),
            deserializer: GRPCProtobuf.ProtobufDeserializer<Primandproper_Platform_Waitlists_V1_ListSignupsResponse>(),
            options: options,
            onResponse: handleResponse
        )
    }

    /// Call the "ListSignupsForSubject" method.
    ///
    /// - Parameters:
    ///   - request: A request containing a single `Primandproper_Platform_Waitlists_V1_ListSignupsForSubjectRequest` message.
    ///   - options: Options to apply to this RPC.
    ///   - handleResponse: A closure which handles the response, the result of which is
    ///       returned to the caller. Returning from the closure will cancel the RPC if it
    ///       hasn't already finished.
    /// - Returns: The result of `handleResponse`.
    internal func listSignupsForSubject<Result>(
        request: GRPCCore.ClientRequest<Primandproper_Platform_Waitlists_V1_ListSignupsForSubjectRequest>,
        options: GRPCCore.CallOptions = .defaults,
        onResponse handleResponse: @Sendable @escaping (GRPCCore.ClientResponse<Primandproper_Platform_Waitlists_V1_ListSignupsForSubjectResponse>) async throws -> Result = { response in
            try response.message
        }
    ) async throws -> Result where Result: Sendable {
        try await self.listSignupsForSubject(
            request: request,
            serializer: GRPCProtobuf.ProtobufSerializer<Primandproper_Platform_Waitlists_V1_ListSignupsForSubjectRequest>(),
            deserializer: GRPCProtobuf.ProtobufDeserializer<Primandproper_Platform_Waitlists_V1_ListSignupsForSubjectResponse>(),
            options: options,
            onResponse: handleResponse
        )
    }

    /// Call the "UpdateSignupNotes" method.
    ///
    /// - Parameters:
    ///   - request: A request containing a single `Primandproper_Platform_Waitlists_V1_UpdateSignupNotesRequest` message.
    ///   - options: Options to apply to this RPC.
    ///   - handleResponse: A closure which handles the response, the result of which is
    ///       returned to the caller. Returning from the closure will cancel the RPC if it
    ///       hasn't already finished.
    /// - Returns: The result of `handleResponse`.
    internal func updateSignupNotes<Result>(
        request: GRPCCore.ClientRequest<Primandproper_Platform_Waitlists_V1_UpdateSignupNotesRequest>,
        options: GRPCCore.CallOptions = .defaults,
        onResponse handleResponse: @Sendable @escaping (GRPCCore.ClientResponse<Primandproper_Platform_Waitlists_V1_UpdateSignupNotesResponse>) async throws -> Result = { response in
            try response.message
        }
    ) async throws -> Result where Result: Sendable {
        try await self.updateSignupNotes(
            request: request,
            serializer: GRPCProtobuf.ProtobufSerializer<Primandproper_Platform_Waitlists_V1_UpdateSignupNotesRequest>(),
            deserializer: GRPCProtobuf.ProtobufDeserializer<Primandproper_Platform_Waitlists_V1_UpdateSignupNotesResponse>(),
            options: options,
            onResponse: handleResponse
        )
    }

    /// Call the "Invite" method.
    ///
    /// - Parameters:
    ///   - request: A request containing a single `Primandproper_Platform_Waitlists_V1_InviteRequest` message.
    ///   - options: Options to apply to this RPC.
    ///   - handleResponse: A closure which handles the response, the result of which is
    ///       returned to the caller. Returning from the closure will cancel the RPC if it
    ///       hasn't already finished.
    /// - Returns: The result of `handleResponse`.
    internal func invite<Result>(
        request: GRPCCore.ClientRequest<Primandproper_Platform_Waitlists_V1_InviteRequest>,
        options: GRPCCore.CallOptions = .defaults,
        onResponse handleResponse: @Sendable @escaping (GRPCCore.ClientResponse<Primandproper_Platform_Waitlists_V1_InviteResponse>) async throws -> Result = { response in
            try response.message
        }
    ) async throws -> Result where Result: Sendable {
        try await self.invite(
            request: request,
            serializer: GRPCProtobuf.ProtobufSerializer<Primandproper_Platform_Waitlists_V1_InviteRequest>(),
            deserializer: GRPCProtobuf.ProtobufDeserializer<Primandproper_Platform_Waitlists_V1_InviteResponse>(),
            options: options,
            onResponse: handleResponse
        )
    }

    /// Call the "Convert" method.
    ///
    /// - Parameters:
    ///   - request: A request containing a single `Primandproper_Platform_Waitlists_V1_ConvertRequest` message.
    ///   - options: Options to apply to this RPC.
    ///   - handleResponse: A closure which handles the response, the result of which is
    ///       returned to the caller. Returning from the closure will cancel the RPC if it
    ///       hasn't already finished.
    /// - Returns: The result of `handleResponse`.
    internal func convert<Result>(
        request: GRPCCore.ClientRequest<Primandproper_Platform_Waitlists_V1_ConvertRequest>,
        options: GRPCCore.CallOptions = .defaults,
        onResponse handleResponse: @Sendable @escaping (GRPCCore.ClientResponse<Primandproper_Platform_Waitlists_V1_ConvertResponse>) async throws -> Result = { response in
            try response.message
        }
    ) async throws -> Result where Result: Sendable {
        try await self.convert(
            request: request,
            serializer: GRPCProtobuf.ProtobufSerializer<Primandproper_Platform_Waitlists_V1_ConvertRequest>(),
            deserializer: GRPCProtobuf.ProtobufDeserializer<Primandproper_Platform_Waitlists_V1_ConvertResponse>(),
            options: options,
            onResponse: handleResponse
        )
    }

    /// Call the "Withdraw" method.
    ///
    /// - Parameters:
    ///   - request: A request containing a single `Primandproper_Platform_Waitlists_V1_WithdrawRequest` message.
    ///   - options: Options to apply to this RPC.
    ///   - handleResponse: A closure which handles the response, the result of which is
    ///       returned to the caller. Returning from the closure will cancel the RPC if it
    ///       hasn't already finished.
    /// - Returns: The result of `handleResponse`.
    internal func withdraw<Result>(
        request: GRPCCore.ClientRequest<Primandproper_Platform_Waitlists_V1_WithdrawRequest>,
        options: GRPCCore.CallOptions = .defaults,
        onResponse handleResponse: @Sendable @escaping (GRPCCore.ClientResponse<Primandproper_Platform_Waitlists_V1_WithdrawResponse>) async throws -> Result = { response in
            try response.message
        }
    ) async throws -> Result where Result: Sendable {
        try await self.withdraw(
            request: request,
            serializer: GRPCProtobuf.ProtobufSerializer<Primandproper_Platform_Waitlists_V1_WithdrawRequest>(),
            deserializer: GRPCProtobuf.ProtobufDeserializer<Primandproper_Platform_Waitlists_V1_WithdrawResponse>(),
            options: options,
            onResponse: handleResponse
        )
    }

    /// Call the "WithdrawSignupsForSubject" method.
    ///
    /// - Parameters:
    ///   - request: A request containing a single `Primandproper_Platform_Waitlists_V1_WithdrawSignupsForSubjectRequest` message.
    ///   - options: Options to apply to this RPC.
    ///   - handleResponse: A closure which handles the response, the result of which is
    ///       returned to the caller. Returning from the closure will cancel the RPC if it
    ///       hasn't already finished.
    /// - Returns: The result of `handleResponse`.
    internal func withdrawSignupsForSubject<Result>(
        request: GRPCCore.ClientRequest<Primandproper_Platform_Waitlists_V1_WithdrawSignupsForSubjectRequest>,
        options: GRPCCore.CallOptions = .defaults,
        onResponse handleResponse: @Sendable @escaping (GRPCCore.ClientResponse<Primandproper_Platform_Waitlists_V1_WithdrawSignupsForSubjectResponse>) async throws -> Result = { response in
            try response.message
        }
    ) async throws -> Result where Result: Sendable {
        try await self.withdrawSignupsForSubject(
            request: request,
            serializer: GRPCProtobuf.ProtobufSerializer<Primandproper_Platform_Waitlists_V1_WithdrawSignupsForSubjectRequest>(),
            deserializer: GRPCProtobuf.ProtobufDeserializer<Primandproper_Platform_Waitlists_V1_WithdrawSignupsForSubjectResponse>(),
            options: options,
            onResponse: handleResponse
        )
    }

    /// Call the "ArchiveSignup" method.
    ///
    /// - Parameters:
    ///   - request: A request containing a single `Primandproper_Platform_Waitlists_V1_ArchiveSignupRequest` message.
    ///   - options: Options to apply to this RPC.
    ///   - handleResponse: A closure which handles the response, the result of which is
    ///       returned to the caller. Returning from the closure will cancel the RPC if it
    ///       hasn't already finished.
    /// - Returns: The result of `handleResponse`.
    internal func archiveSignup<Result>(
        request: GRPCCore.ClientRequest<Primandproper_Platform_Waitlists_V1_ArchiveSignupRequest>,
        options: GRPCCore.CallOptions = .defaults,
        onResponse handleResponse: @Sendable @escaping (GRPCCore.ClientResponse<Primandproper_Platform_Waitlists_V1_ArchiveSignupResponse>) async throws -> Result = { response in
            try response.message
        }
    ) async throws -> Result where Result: Sendable {
        try await self.archiveSignup(
            request: request,
            serializer: GRPCProtobuf.ProtobufSerializer<Primandproper_Platform_Waitlists_V1_ArchiveSignupRequest>(),
            deserializer: GRPCProtobuf.ProtobufDeserializer<Primandproper_Platform_Waitlists_V1_ArchiveSignupResponse>(),
            options: options,
            onResponse: handleResponse
        )
    }
}

// Helpers providing sugared APIs for 'ClientProtocol' methods.
@available(macOS 15.0, iOS 18.0, watchOS 11.0, tvOS 18.0, visionOS 2.0, *)
extension Primandproper_Platform_Waitlists_V1_WaitlistsService.ClientProtocol {
    /// Call the "CreateList" method.
    ///
    /// > Source IDL Documentation:
    /// >
    /// > The catalog: what lists exist, what they are for, and when each stops
    /// > taking signups. ListOpenLists is the public one.
    ///
    /// - Parameters:
    ///   - message: request message to send.
    ///   - metadata: Additional metadata to send, defaults to empty.
    ///   - options: Options to apply to this RPC, defaults to `.defaults`.
    ///   - handleResponse: A closure which handles the response, the result of which is
    ///       returned to the caller. Returning from the closure will cancel the RPC if it
    ///       hasn't already finished.
    /// - Returns: The result of `handleResponse`.
    internal func createList<Result>(
        _ message: Primandproper_Platform_Waitlists_V1_CreateListRequest,
        metadata: GRPCCore.Metadata = [:],
        options: GRPCCore.CallOptions = .defaults,
        onResponse handleResponse: @Sendable @escaping (GRPCCore.ClientResponse<Primandproper_Platform_Waitlists_V1_CreateListResponse>) async throws -> Result = { response in
            try response.message
        }
    ) async throws -> Result where Result: Sendable {
        let request = GRPCCore.ClientRequest<Primandproper_Platform_Waitlists_V1_CreateListRequest>(
            message: message,
            metadata: metadata
        )
        return try await self.createList(
            request: request,
            options: options,
            onResponse: handleResponse
        )
    }

    /// Call the "GetList" method.
    ///
    /// - Parameters:
    ///   - message: request message to send.
    ///   - metadata: Additional metadata to send, defaults to empty.
    ///   - options: Options to apply to this RPC, defaults to `.defaults`.
    ///   - handleResponse: A closure which handles the response, the result of which is
    ///       returned to the caller. Returning from the closure will cancel the RPC if it
    ///       hasn't already finished.
    /// - Returns: The result of `handleResponse`.
    internal func getList<Result>(
        _ message: Primandproper_Platform_Waitlists_V1_GetListRequest,
        metadata: GRPCCore.Metadata = [:],
        options: GRPCCore.CallOptions = .defaults,
        onResponse handleResponse: @Sendable @escaping (GRPCCore.ClientResponse<Primandproper_Platform_Waitlists_V1_GetListResponse>) async throws -> Result = { response in
            try response.message
        }
    ) async throws -> Result where Result: Sendable {
        let request = GRPCCore.ClientRequest<Primandproper_Platform_Waitlists_V1_GetListRequest>(
            message: message,
            metadata: metadata
        )
        return try await self.getList(
            request: request,
            options: options,
            onResponse: handleResponse
        )
    }

    /// Call the "ListLists" method.
    ///
    /// - Parameters:
    ///   - message: request message to send.
    ///   - metadata: Additional metadata to send, defaults to empty.
    ///   - options: Options to apply to this RPC, defaults to `.defaults`.
    ///   - handleResponse: A closure which handles the response, the result of which is
    ///       returned to the caller. Returning from the closure will cancel the RPC if it
    ///       hasn't already finished.
    /// - Returns: The result of `handleResponse`.
    internal func listLists<Result>(
        _ message: Primandproper_Platform_Waitlists_V1_ListListsRequest,
        metadata: GRPCCore.Metadata = [:],
        options: GRPCCore.CallOptions = .defaults,
        onResponse handleResponse: @Sendable @escaping (GRPCCore.ClientResponse<Primandproper_Platform_Waitlists_V1_ListListsResponse>) async throws -> Result = { response in
            try response.message
        }
    ) async throws -> Result where Result: Sendable {
        let request = GRPCCore.ClientRequest<Primandproper_Platform_Waitlists_V1_ListListsRequest>(
            message: message,
            metadata: metadata
        )
        return try await self.listLists(
            request: request,
            options: options,
            onResponse: handleResponse
        )
    }

    /// Call the "ListOpenLists" method.
    ///
    /// - Parameters:
    ///   - message: request message to send.
    ///   - metadata: Additional metadata to send, defaults to empty.
    ///   - options: Options to apply to this RPC, defaults to `.defaults`.
    ///   - handleResponse: A closure which handles the response, the result of which is
    ///       returned to the caller. Returning from the closure will cancel the RPC if it
    ///       hasn't already finished.
    /// - Returns: The result of `handleResponse`.
    internal func listOpenLists<Result>(
        _ message: Primandproper_Platform_Waitlists_V1_ListOpenListsRequest,
        metadata: GRPCCore.Metadata = [:],
        options: GRPCCore.CallOptions = .defaults,
        onResponse handleResponse: @Sendable @escaping (GRPCCore.ClientResponse<Primandproper_Platform_Waitlists_V1_ListOpenListsResponse>) async throws -> Result = { response in
            try response.message
        }
    ) async throws -> Result where Result: Sendable {
        let request = GRPCCore.ClientRequest<Primandproper_Platform_Waitlists_V1_ListOpenListsRequest>(
            message: message,
            metadata: metadata
        )
        return try await self.listOpenLists(
            request: request,
            options: options,
            onResponse: handleResponse
        )
    }

    /// Call the "UpdateList" method.
    ///
    /// - Parameters:
    ///   - message: request message to send.
    ///   - metadata: Additional metadata to send, defaults to empty.
    ///   - options: Options to apply to this RPC, defaults to `.defaults`.
    ///   - handleResponse: A closure which handles the response, the result of which is
    ///       returned to the caller. Returning from the closure will cancel the RPC if it
    ///       hasn't already finished.
    /// - Returns: The result of `handleResponse`.
    internal func updateList<Result>(
        _ message: Primandproper_Platform_Waitlists_V1_UpdateListRequest,
        metadata: GRPCCore.Metadata = [:],
        options: GRPCCore.CallOptions = .defaults,
        onResponse handleResponse: @Sendable @escaping (GRPCCore.ClientResponse<Primandproper_Platform_Waitlists_V1_UpdateListResponse>) async throws -> Result = { response in
            try response.message
        }
    ) async throws -> Result where Result: Sendable {
        let request = GRPCCore.ClientRequest<Primandproper_Platform_Waitlists_V1_UpdateListRequest>(
            message: message,
            metadata: metadata
        )
        return try await self.updateList(
            request: request,
            options: options,
            onResponse: handleResponse
        )
    }

    /// Call the "ArchiveList" method.
    ///
    /// - Parameters:
    ///   - message: request message to send.
    ///   - metadata: Additional metadata to send, defaults to empty.
    ///   - options: Options to apply to this RPC, defaults to `.defaults`.
    ///   - handleResponse: A closure which handles the response, the result of which is
    ///       returned to the caller. Returning from the closure will cancel the RPC if it
    ///       hasn't already finished.
    /// - Returns: The result of `handleResponse`.
    internal func archiveList<Result>(
        _ message: Primandproper_Platform_Waitlists_V1_ArchiveListRequest,
        metadata: GRPCCore.Metadata = [:],
        options: GRPCCore.CallOptions = .defaults,
        onResponse handleResponse: @Sendable @escaping (GRPCCore.ClientResponse<Primandproper_Platform_Waitlists_V1_ArchiveListResponse>) async throws -> Result = { response in
            try response.message
        }
    ) async throws -> Result where Result: Sendable {
        let request = GRPCCore.ClientRequest<Primandproper_Platform_Waitlists_V1_ArchiveListRequest>(
            message: message,
            metadata: metadata
        )
        return try await self.archiveList(
            request: request,
            options: options,
            onResponse: handleResponse
        )
    }

    /// Call the "Join" method.
    ///
    /// > Source IDL Documentation:
    /// >
    /// > The queue. Join and Withdraw are the person's own; the rest are the
    /// > operator's.
    ///
    /// - Parameters:
    ///   - message: request message to send.
    ///   - metadata: Additional metadata to send, defaults to empty.
    ///   - options: Options to apply to this RPC, defaults to `.defaults`.
    ///   - handleResponse: A closure which handles the response, the result of which is
    ///       returned to the caller. Returning from the closure will cancel the RPC if it
    ///       hasn't already finished.
    /// - Returns: The result of `handleResponse`.
    internal func join<Result>(
        _ message: Primandproper_Platform_Waitlists_V1_JoinRequest,
        metadata: GRPCCore.Metadata = [:],
        options: GRPCCore.CallOptions = .defaults,
        onResponse handleResponse: @Sendable @escaping (GRPCCore.ClientResponse<Primandproper_Platform_Waitlists_V1_JoinResponse>) async throws -> Result = { response in
            try response.message
        }
    ) async throws -> Result where Result: Sendable {
        let request = GRPCCore.ClientRequest<Primandproper_Platform_Waitlists_V1_JoinRequest>(
            message: message,
            metadata: metadata
        )
        return try await self.join(
            request: request,
            options: options,
            onResponse: handleResponse
        )
    }

    /// Call the "GetSignup" method.
    ///
    /// - Parameters:
    ///   - message: request message to send.
    ///   - metadata: Additional metadata to send, defaults to empty.
    ///   - options: Options to apply to this RPC, defaults to `.defaults`.
    ///   - handleResponse: A closure which handles the response, the result of which is
    ///       returned to the caller. Returning from the closure will cancel the RPC if it
    ///       hasn't already finished.
    /// - Returns: The result of `handleResponse`.
    internal func getSignup<Result>(
        _ message: Primandproper_Platform_Waitlists_V1_GetSignupRequest,
        metadata: GRPCCore.Metadata = [:],
        options: GRPCCore.CallOptions = .defaults,
        onResponse handleResponse: @Sendable @escaping (GRPCCore.ClientResponse<Primandproper_Platform_Waitlists_V1_GetSignupResponse>) async throws -> Result = { response in
            try response.message
        }
    ) async throws -> Result where Result: Sendable {
        let request = GRPCCore.ClientRequest<Primandproper_Platform_Waitlists_V1_GetSignupRequest>(
            message: message,
            metadata: metadata
        )
        return try await self.getSignup(
            request: request,
            options: options,
            onResponse: handleResponse
        )
    }

    /// Call the "GetSignupByContact" method.
    ///
    /// - Parameters:
    ///   - message: request message to send.
    ///   - metadata: Additional metadata to send, defaults to empty.
    ///   - options: Options to apply to this RPC, defaults to `.defaults`.
    ///   - handleResponse: A closure which handles the response, the result of which is
    ///       returned to the caller. Returning from the closure will cancel the RPC if it
    ///       hasn't already finished.
    /// - Returns: The result of `handleResponse`.
    internal func getSignupByContact<Result>(
        _ message: Primandproper_Platform_Waitlists_V1_GetSignupByContactRequest,
        metadata: GRPCCore.Metadata = [:],
        options: GRPCCore.CallOptions = .defaults,
        onResponse handleResponse: @Sendable @escaping (GRPCCore.ClientResponse<Primandproper_Platform_Waitlists_V1_GetSignupByContactResponse>) async throws -> Result = { response in
            try response.message
        }
    ) async throws -> Result where Result: Sendable {
        let request = GRPCCore.ClientRequest<Primandproper_Platform_Waitlists_V1_GetSignupByContactRequest>(
            message: message,
            metadata: metadata
        )
        return try await self.getSignupByContact(
            request: request,
            options: options,
            onResponse: handleResponse
        )
    }

    /// Call the "ListSignups" method.
    ///
    /// - Parameters:
    ///   - message: request message to send.
    ///   - metadata: Additional metadata to send, defaults to empty.
    ///   - options: Options to apply to this RPC, defaults to `.defaults`.
    ///   - handleResponse: A closure which handles the response, the result of which is
    ///       returned to the caller. Returning from the closure will cancel the RPC if it
    ///       hasn't already finished.
    /// - Returns: The result of `handleResponse`.
    internal func listSignups<Result>(
        _ message: Primandproper_Platform_Waitlists_V1_ListSignupsRequest,
        metadata: GRPCCore.Metadata = [:],
        options: GRPCCore.CallOptions = .defaults,
        onResponse handleResponse: @Sendable @escaping (GRPCCore.ClientResponse<Primandproper_Platform_Waitlists_V1_ListSignupsResponse>) async throws -> Result = { response in
            try response.message
        }
    ) async throws -> Result where Result: Sendable {
        let request = GRPCCore.ClientRequest<Primandproper_Platform_Waitlists_V1_ListSignupsRequest>(
            message: message,
            metadata: metadata
        )
        return try await self.listSignups(
            request: request,
            options: options,
            onResponse: handleResponse
        )
    }

    /// Call the "ListSignupsForSubject" method.
    ///
    /// - Parameters:
    ///   - message: request message to send.
    ///   - metadata: Additional metadata to send, defaults to empty.
    ///   - options: Options to apply to this RPC, defaults to `.defaults`.
    ///   - handleResponse: A closure which handles the response, the result of which is
    ///       returned to the caller. Returning from the closure will cancel the RPC if it
    ///       hasn't already finished.
    /// - Returns: The result of `handleResponse`.
    internal func listSignupsForSubject<Result>(
        _ message: Primandproper_Platform_Waitlists_V1_ListSignupsForSubjectRequest,
        metadata: GRPCCore.Metadata = [:],
        options: GRPCCore.CallOptions = .defaults,
        onResponse handleResponse: @Sendable @escaping (GRPCCore.ClientResponse<Primandproper_Platform_Waitlists_V1_ListSignupsForSubjectResponse>) async throws -> Result = { response in
            try response.message
        }
    ) async throws -> Result where Result: Sendable {
        let request = GRPCCore.ClientRequest<Primandproper_Platform_Waitlists_V1_ListSignupsForSubjectRequest>(
            message: message,
            metadata: metadata
        )
        return try await self.listSignupsForSubject(
            request: request,
            options: options,
            onResponse: handleResponse
        )
    }

    /// Call the "UpdateSignupNotes" method.
    ///
    /// - Parameters:
    ///   - message: request message to send.
    ///   - metadata: Additional metadata to send, defaults to empty.
    ///   - options: Options to apply to this RPC, defaults to `.defaults`.
    ///   - handleResponse: A closure which handles the response, the result of which is
    ///       returned to the caller. Returning from the closure will cancel the RPC if it
    ///       hasn't already finished.
    /// - Returns: The result of `handleResponse`.
    internal func updateSignupNotes<Result>(
        _ message: Primandproper_Platform_Waitlists_V1_UpdateSignupNotesRequest,
        metadata: GRPCCore.Metadata = [:],
        options: GRPCCore.CallOptions = .defaults,
        onResponse handleResponse: @Sendable @escaping (GRPCCore.ClientResponse<Primandproper_Platform_Waitlists_V1_UpdateSignupNotesResponse>) async throws -> Result = { response in
            try response.message
        }
    ) async throws -> Result where Result: Sendable {
        let request = GRPCCore.ClientRequest<Primandproper_Platform_Waitlists_V1_UpdateSignupNotesRequest>(
            message: message,
            metadata: metadata
        )
        return try await self.updateSignupNotes(
            request: request,
            options: options,
            onResponse: handleResponse
        )
    }

    /// Call the "Invite" method.
    ///
    /// - Parameters:
    ///   - message: request message to send.
    ///   - metadata: Additional metadata to send, defaults to empty.
    ///   - options: Options to apply to this RPC, defaults to `.defaults`.
    ///   - handleResponse: A closure which handles the response, the result of which is
    ///       returned to the caller. Returning from the closure will cancel the RPC if it
    ///       hasn't already finished.
    /// - Returns: The result of `handleResponse`.
    internal func invite<Result>(
        _ message: Primandproper_Platform_Waitlists_V1_InviteRequest,
        metadata: GRPCCore.Metadata = [:],
        options: GRPCCore.CallOptions = .defaults,
        onResponse handleResponse: @Sendable @escaping (GRPCCore.ClientResponse<Primandproper_Platform_Waitlists_V1_InviteResponse>) async throws -> Result = { response in
            try response.message
        }
    ) async throws -> Result where Result: Sendable {
        let request = GRPCCore.ClientRequest<Primandproper_Platform_Waitlists_V1_InviteRequest>(
            message: message,
            metadata: metadata
        )
        return try await self.invite(
            request: request,
            options: options,
            onResponse: handleResponse
        )
    }

    /// Call the "Convert" method.
    ///
    /// - Parameters:
    ///   - message: request message to send.
    ///   - metadata: Additional metadata to send, defaults to empty.
    ///   - options: Options to apply to this RPC, defaults to `.defaults`.
    ///   - handleResponse: A closure which handles the response, the result of which is
    ///       returned to the caller. Returning from the closure will cancel the RPC if it
    ///       hasn't already finished.
    /// - Returns: The result of `handleResponse`.
    internal func convert<Result>(
        _ message: Primandproper_Platform_Waitlists_V1_ConvertRequest,
        metadata: GRPCCore.Metadata = [:],
        options: GRPCCore.CallOptions = .defaults,
        onResponse handleResponse: @Sendable @escaping (GRPCCore.ClientResponse<Primandproper_Platform_Waitlists_V1_ConvertResponse>) async throws -> Result = { response in
            try response.message
        }
    ) async throws -> Result where Result: Sendable {
        let request = GRPCCore.ClientRequest<Primandproper_Platform_Waitlists_V1_ConvertRequest>(
            message: message,
            metadata: metadata
        )
        return try await self.convert(
            request: request,
            options: options,
            onResponse: handleResponse
        )
    }

    /// Call the "Withdraw" method.
    ///
    /// - Parameters:
    ///   - message: request message to send.
    ///   - metadata: Additional metadata to send, defaults to empty.
    ///   - options: Options to apply to this RPC, defaults to `.defaults`.
    ///   - handleResponse: A closure which handles the response, the result of which is
    ///       returned to the caller. Returning from the closure will cancel the RPC if it
    ///       hasn't already finished.
    /// - Returns: The result of `handleResponse`.
    internal func withdraw<Result>(
        _ message: Primandproper_Platform_Waitlists_V1_WithdrawRequest,
        metadata: GRPCCore.Metadata = [:],
        options: GRPCCore.CallOptions = .defaults,
        onResponse handleResponse: @Sendable @escaping (GRPCCore.ClientResponse<Primandproper_Platform_Waitlists_V1_WithdrawResponse>) async throws -> Result = { response in
            try response.message
        }
    ) async throws -> Result where Result: Sendable {
        let request = GRPCCore.ClientRequest<Primandproper_Platform_Waitlists_V1_WithdrawRequest>(
            message: message,
            metadata: metadata
        )
        return try await self.withdraw(
            request: request,
            options: options,
            onResponse: handleResponse
        )
    }

    /// Call the "WithdrawSignupsForSubject" method.
    ///
    /// - Parameters:
    ///   - message: request message to send.
    ///   - metadata: Additional metadata to send, defaults to empty.
    ///   - options: Options to apply to this RPC, defaults to `.defaults`.
    ///   - handleResponse: A closure which handles the response, the result of which is
    ///       returned to the caller. Returning from the closure will cancel the RPC if it
    ///       hasn't already finished.
    /// - Returns: The result of `handleResponse`.
    internal func withdrawSignupsForSubject<Result>(
        _ message: Primandproper_Platform_Waitlists_V1_WithdrawSignupsForSubjectRequest,
        metadata: GRPCCore.Metadata = [:],
        options: GRPCCore.CallOptions = .defaults,
        onResponse handleResponse: @Sendable @escaping (GRPCCore.ClientResponse<Primandproper_Platform_Waitlists_V1_WithdrawSignupsForSubjectResponse>) async throws -> Result = { response in
            try response.message
        }
    ) async throws -> Result where Result: Sendable {
        let request = GRPCCore.ClientRequest<Primandproper_Platform_Waitlists_V1_WithdrawSignupsForSubjectRequest>(
            message: message,
            metadata: metadata
        )
        return try await self.withdrawSignupsForSubject(
            request: request,
            options: options,
            onResponse: handleResponse
        )
    }

    /// Call the "ArchiveSignup" method.
    ///
    /// - Parameters:
    ///   - message: request message to send.
    ///   - metadata: Additional metadata to send, defaults to empty.
    ///   - options: Options to apply to this RPC, defaults to `.defaults`.
    ///   - handleResponse: A closure which handles the response, the result of which is
    ///       returned to the caller. Returning from the closure will cancel the RPC if it
    ///       hasn't already finished.
    /// - Returns: The result of `handleResponse`.
    internal func archiveSignup<Result>(
        _ message: Primandproper_Platform_Waitlists_V1_ArchiveSignupRequest,
        metadata: GRPCCore.Metadata = [:],
        options: GRPCCore.CallOptions = .defaults,
        onResponse handleResponse: @Sendable @escaping (GRPCCore.ClientResponse<Primandproper_Platform_Waitlists_V1_ArchiveSignupResponse>) async throws -> Result = { response in
            try response.message
        }
    ) async throws -> Result where Result: Sendable {
        let request = GRPCCore.ClientRequest<Primandproper_Platform_Waitlists_V1_ArchiveSignupRequest>(
            message: message,
            metadata: metadata
        )
        return try await self.archiveSignup(
            request: request,
            options: options,
            onResponse: handleResponse
        )
    }
}