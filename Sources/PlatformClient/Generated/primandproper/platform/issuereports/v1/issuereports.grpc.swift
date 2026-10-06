// Package primandproper.platform.issuereports.v1 is the wire schema for what
// your users told you was wrong: the report they filed, and where it stands.
//
// This file is shipped inside the published Go module, and it is the file
// itself that is shipped -- not a copy for you to keep in sync. A consumer puts
// the module's proto directories on protoc's path and imports this file by its
// canonical name, exactly as identity.proto and filtering.proto already work:
//
//	PLATFORM_PROTO := $(shell go list -m -f '{{.Dir}}' github.com/primandproper/platform-go/v15)
//
//	protoc --proto_path proto/ \
//	    --proto_path $(PLATFORM_PROTO)/issuereports/proto \
//	    --proto_path $(PLATFORM_PROTO)/filtering/proto \
//	    --go_opt=Mprimandproper/platform/issuereports/v1/issuereports.proto=github.com/primandproper/platform-go/v15/issuereports/issuereportspb \
//	    $(CONSUMER_PROTO_FILES)   # the platform files deliberately absent from that list
//
// Field numbers are the compatibility promise, across every language a consumer
// generates into. Numbers are never reused and never repurposed: a field that
// goes away is reserved.
//
// # The lifecycle, and why a move carries two statuses
//
// A report is open, acknowledged, resolved or declined. It is born open, it can
// be picked up, it stops in one of the two terminal states, and it reopens to
// open rather than to acknowledged -- because reopening is what happens when the
// resolution turned out not to hold, so nobody has dealt with it.
//
// [TransitionReportRequest] carries both the status the caller believed the
// report held and the one it should move to, and the statement requires the row
// to still hold the first. That is the difference between a queue two people can
// work and one they cannot: without the guard, two triagers resolving the same
// report both succeed, the second note overwrites the first, and nothing
// anywhere says so. With it, one of them is refused and re-reads.
//
// The guard is worth more over a wire than it is in process, not less. The
// window between the read a triager decided from and the write they sent is a
// screen and a person wide, so the conflict this refuses is the ordinary case
// rather than the rare one.
//
// # Why status is an enum and kind is not
//
// [ReportStatus] is a closed set this module owns and validates every write
// against, so a value outside the enum is a row the store would have refused;
// the generated constant is exactly as complete as the column, in every
// language.
//
// [IssueReport.kind] and [IssueReport.subject_type] are strings, and they are
// the borrowed vocabulary in this file. What a report is *about*, and what
// categories a product sorts its reports into, are the application's -- bug,
// billing, abuse; article, workspace, newsletter -- and the Go package says so:
// what varies is the catalog of categories and what a report can be about, and
// both of those are opaque to this package. An enum here would put a consumer's
// vocabulary on this module's release cadence, and a category they added would
// render as UNSPECIFIED until this file caught up. A string cannot be behind.
//
// # What is not here, and why
//
// No scope field, anywhere, and the reservation is what makes that a schema
// protoc enforces rather than a comment somebody can add a field beneath. A
// scope a client could name is a cross-tenant read hiding behind a request
// field; it comes off the principal the consumer's interceptor put on the
// context. See identity.proto, which says this at greater length.
//
// One message says whose a report is, and no request does. The operator's two
// reads -- [ListReportsAcrossScopesRequest] and
// [ListReportsByStatusAcrossScopesRequest] -- page every tenant's reports, so
// each row they answer with is a [ScopedIssueReport], which carries the scope as
// output. Everywhere else a row's scope is the one the connection resolved, and
// a field repeating it would tell a client something it supplied.
//
// No reporter on any write. A report is filed by whoever is calling, and the
// name is taken off the principal for the same reason the scope is: a reporter a
// client could name is a report filed in somebody else's words. It is output
// only, and the one request that carries a reporter is
// [ListReportsByReporterRequest], which names whose reports to page rather than
// whose report to write -- and which is gated on the row question as well as on
// the method, since a person reading their own reports and a triager reading
// everybody's are not the same grant.
//
// No status on a create. A report is born open; a value arriving resolved is a
// transition spelled as a create, which is the one move that would skip the
// guard the rest of the lifecycle rests on.
//
// No erasure. issuereports.Store.DeleteReportsByReporter destroys every report
// one person filed, and it is absent from this service deliberately: it runs
// inside the caller's transaction so that a subject's reports and the rest of
// their footprint commit or roll back together, which is a property an RPC
// cannot have. It is reached through dataprivacy's eraser, from the consumer's
// own erasure run, and issuereports/grpc/doc.go carries the ruling.
//
// # include_archived is a request and not an instruction
//
// Every paged read here carries a QueryFilter, and its include_archived says
// "give me the archived rows too". It is a field on a message a client fills in,
// so it is a request the server rules on rather than a switch it obeys: a caller
// holding issues.reports.archive gets the reports somebody took out of the
// queue, and for everybody else the field is cleared before the read and the
// page is the live queue.
//
// It is cleared and not refused. A read that failed because the caller asked for
// too much turns a console's checkbox into an error, and a client cannot tell
// that refusal from a malformed filter; the page a caller gets is the page they
// would have got had they never set the field.
//
// The grant is issues.reports.archive rather than issues.reports.read or
// issues.reports.triage because taking a report out of the queue is its own act
// with its own grant, and a read that hands the removed rows back under a
// lighter one makes that split a name. The same rule, under each surface's own
// archive grant, is in comments.proto, waitlists.proto and settings.proto.

// DO NOT EDIT.
// swift-format-ignore-file
// swiftlint:disable all
//
// Generated by the gRPC Swift generator plugin for the protocol buffer compiler.
// Source: primandproper/platform/issuereports/v1/issuereports.proto
//
// For information on using the generated types, please see the documentation:
//   https://github.com/grpc/grpc-swift

import GRPCCore
import GRPCProtobuf

// MARK: - primandproper.platform.issuereports.v1.IssueReportsService

/// Namespace containing generated types for the "primandproper.platform.issuereports.v1.IssueReportsService" service.
@available(macOS 15.0, iOS 18.0, watchOS 11.0, tvOS 18.0, visionOS 2.0, *)
public enum Primandproper_Platform_Issuereports_V1_IssueReportsService: Sendable {
    /// Service descriptor for the "primandproper.platform.issuereports.v1.IssueReportsService" service.
    public static let descriptor = GRPCCore.ServiceDescriptor(fullyQualifiedService: "primandproper.platform.issuereports.v1.IssueReportsService")
    /// Namespace for method metadata.
    public enum Method: Sendable {
        /// Namespace for "CreateReport" metadata.
        public enum CreateReport: Sendable {
            /// Request type for "CreateReport".
            public typealias Input = Primandproper_Platform_Issuereports_V1_CreateReportRequest
            /// Response type for "CreateReport".
            public typealias Output = Primandproper_Platform_Issuereports_V1_CreateReportResponse
            /// Descriptor for "CreateReport".
            public static let descriptor = GRPCCore.MethodDescriptor(
                service: GRPCCore.ServiceDescriptor(fullyQualifiedService: "primandproper.platform.issuereports.v1.IssueReportsService"),
                method: "CreateReport",
                type: .unary
            )
        }
        /// Namespace for "GetReport" metadata.
        public enum GetReport: Sendable {
            /// Request type for "GetReport".
            public typealias Input = Primandproper_Platform_Issuereports_V1_GetReportRequest
            /// Response type for "GetReport".
            public typealias Output = Primandproper_Platform_Issuereports_V1_GetReportResponse
            /// Descriptor for "GetReport".
            public static let descriptor = GRPCCore.MethodDescriptor(
                service: GRPCCore.ServiceDescriptor(fullyQualifiedService: "primandproper.platform.issuereports.v1.IssueReportsService"),
                method: "GetReport",
                type: .unary
            )
        }
        /// Namespace for "ListReports" metadata.
        public enum ListReports: Sendable {
            /// Request type for "ListReports".
            public typealias Input = Primandproper_Platform_Issuereports_V1_ListReportsRequest
            /// Response type for "ListReports".
            public typealias Output = Primandproper_Platform_Issuereports_V1_ListReportsResponse
            /// Descriptor for "ListReports".
            public static let descriptor = GRPCCore.MethodDescriptor(
                service: GRPCCore.ServiceDescriptor(fullyQualifiedService: "primandproper.platform.issuereports.v1.IssueReportsService"),
                method: "ListReports",
                type: .unary
            )
        }
        /// Namespace for "ListReportsByStatus" metadata.
        public enum ListReportsByStatus: Sendable {
            /// Request type for "ListReportsByStatus".
            public typealias Input = Primandproper_Platform_Issuereports_V1_ListReportsByStatusRequest
            /// Response type for "ListReportsByStatus".
            public typealias Output = Primandproper_Platform_Issuereports_V1_ListReportsByStatusResponse
            /// Descriptor for "ListReportsByStatus".
            public static let descriptor = GRPCCore.MethodDescriptor(
                service: GRPCCore.ServiceDescriptor(fullyQualifiedService: "primandproper.platform.issuereports.v1.IssueReportsService"),
                method: "ListReportsByStatus",
                type: .unary
            )
        }
        /// Namespace for "ListReportsByReporter" metadata.
        public enum ListReportsByReporter: Sendable {
            /// Request type for "ListReportsByReporter".
            public typealias Input = Primandproper_Platform_Issuereports_V1_ListReportsByReporterRequest
            /// Response type for "ListReportsByReporter".
            public typealias Output = Primandproper_Platform_Issuereports_V1_ListReportsByReporterResponse
            /// Descriptor for "ListReportsByReporter".
            public static let descriptor = GRPCCore.MethodDescriptor(
                service: GRPCCore.ServiceDescriptor(fullyQualifiedService: "primandproper.platform.issuereports.v1.IssueReportsService"),
                method: "ListReportsByReporter",
                type: .unary
            )
        }
        /// Namespace for "ListReportsBySubjectType" metadata.
        public enum ListReportsBySubjectType: Sendable {
            /// Request type for "ListReportsBySubjectType".
            public typealias Input = Primandproper_Platform_Issuereports_V1_ListReportsBySubjectTypeRequest
            /// Response type for "ListReportsBySubjectType".
            public typealias Output = Primandproper_Platform_Issuereports_V1_ListReportsBySubjectTypeResponse
            /// Descriptor for "ListReportsBySubjectType".
            public static let descriptor = GRPCCore.MethodDescriptor(
                service: GRPCCore.ServiceDescriptor(fullyQualifiedService: "primandproper.platform.issuereports.v1.IssueReportsService"),
                method: "ListReportsBySubjectType",
                type: .unary
            )
        }
        /// Namespace for "ListReportsForSubject" metadata.
        public enum ListReportsForSubject: Sendable {
            /// Request type for "ListReportsForSubject".
            public typealias Input = Primandproper_Platform_Issuereports_V1_ListReportsForSubjectRequest
            /// Response type for "ListReportsForSubject".
            public typealias Output = Primandproper_Platform_Issuereports_V1_ListReportsForSubjectResponse
            /// Descriptor for "ListReportsForSubject".
            public static let descriptor = GRPCCore.MethodDescriptor(
                service: GRPCCore.ServiceDescriptor(fullyQualifiedService: "primandproper.platform.issuereports.v1.IssueReportsService"),
                method: "ListReportsForSubject",
                type: .unary
            )
        }
        /// Namespace for "ListReportsAcrossScopes" metadata.
        public enum ListReportsAcrossScopes: Sendable {
            /// Request type for "ListReportsAcrossScopes".
            public typealias Input = Primandproper_Platform_Issuereports_V1_ListReportsAcrossScopesRequest
            /// Response type for "ListReportsAcrossScopes".
            public typealias Output = Primandproper_Platform_Issuereports_V1_ListReportsAcrossScopesResponse
            /// Descriptor for "ListReportsAcrossScopes".
            public static let descriptor = GRPCCore.MethodDescriptor(
                service: GRPCCore.ServiceDescriptor(fullyQualifiedService: "primandproper.platform.issuereports.v1.IssueReportsService"),
                method: "ListReportsAcrossScopes",
                type: .unary
            )
        }
        /// Namespace for "ListReportsByStatusAcrossScopes" metadata.
        public enum ListReportsByStatusAcrossScopes: Sendable {
            /// Request type for "ListReportsByStatusAcrossScopes".
            public typealias Input = Primandproper_Platform_Issuereports_V1_ListReportsByStatusAcrossScopesRequest
            /// Response type for "ListReportsByStatusAcrossScopes".
            public typealias Output = Primandproper_Platform_Issuereports_V1_ListReportsByStatusAcrossScopesResponse
            /// Descriptor for "ListReportsByStatusAcrossScopes".
            public static let descriptor = GRPCCore.MethodDescriptor(
                service: GRPCCore.ServiceDescriptor(fullyQualifiedService: "primandproper.platform.issuereports.v1.IssueReportsService"),
                method: "ListReportsByStatusAcrossScopes",
                type: .unary
            )
        }
        /// Namespace for "UpdateReport" metadata.
        public enum UpdateReport: Sendable {
            /// Request type for "UpdateReport".
            public typealias Input = Primandproper_Platform_Issuereports_V1_UpdateReportRequest
            /// Response type for "UpdateReport".
            public typealias Output = Primandproper_Platform_Issuereports_V1_UpdateReportResponse
            /// Descriptor for "UpdateReport".
            public static let descriptor = GRPCCore.MethodDescriptor(
                service: GRPCCore.ServiceDescriptor(fullyQualifiedService: "primandproper.platform.issuereports.v1.IssueReportsService"),
                method: "UpdateReport",
                type: .unary
            )
        }
        /// Namespace for "TransitionReport" metadata.
        public enum TransitionReport: Sendable {
            /// Request type for "TransitionReport".
            public typealias Input = Primandproper_Platform_Issuereports_V1_TransitionReportRequest
            /// Response type for "TransitionReport".
            public typealias Output = Primandproper_Platform_Issuereports_V1_TransitionReportResponse
            /// Descriptor for "TransitionReport".
            public static let descriptor = GRPCCore.MethodDescriptor(
                service: GRPCCore.ServiceDescriptor(fullyQualifiedService: "primandproper.platform.issuereports.v1.IssueReportsService"),
                method: "TransitionReport",
                type: .unary
            )
        }
        /// Namespace for "ArchiveReport" metadata.
        public enum ArchiveReport: Sendable {
            /// Request type for "ArchiveReport".
            public typealias Input = Primandproper_Platform_Issuereports_V1_ArchiveReportRequest
            /// Response type for "ArchiveReport".
            public typealias Output = Primandproper_Platform_Issuereports_V1_ArchiveReportResponse
            /// Descriptor for "ArchiveReport".
            public static let descriptor = GRPCCore.MethodDescriptor(
                service: GRPCCore.ServiceDescriptor(fullyQualifiedService: "primandproper.platform.issuereports.v1.IssueReportsService"),
                method: "ArchiveReport",
                type: .unary
            )
        }
        /// Descriptors for all methods in the "primandproper.platform.issuereports.v1.IssueReportsService" service.
        public static let descriptors: [GRPCCore.MethodDescriptor] = [
            CreateReport.descriptor,
            GetReport.descriptor,
            ListReports.descriptor,
            ListReportsByStatus.descriptor,
            ListReportsByReporter.descriptor,
            ListReportsBySubjectType.descriptor,
            ListReportsForSubject.descriptor,
            ListReportsAcrossScopes.descriptor,
            ListReportsByStatusAcrossScopes.descriptor,
            UpdateReport.descriptor,
            TransitionReport.descriptor,
            ArchiveReport.descriptor
        ]
    }
}

@available(macOS 15.0, iOS 18.0, watchOS 11.0, tvOS 18.0, visionOS 2.0, *)
extension GRPCCore.ServiceDescriptor {
    /// Service descriptor for the "primandproper.platform.issuereports.v1.IssueReportsService" service.
    public static let primandproper_platform_issuereports_v1_IssueReportsService = GRPCCore.ServiceDescriptor(fullyQualifiedService: "primandproper.platform.issuereports.v1.IssueReportsService")
}

// MARK: primandproper.platform.issuereports.v1.IssueReportsService (client)

@available(macOS 15.0, iOS 18.0, watchOS 11.0, tvOS 18.0, visionOS 2.0, *)
extension Primandproper_Platform_Issuereports_V1_IssueReportsService {
    /// Generated client protocol for the "primandproper.platform.issuereports.v1.IssueReportsService" service.
    ///
    /// You don't need to implement this protocol directly, use the generated
    /// implementation, ``Client``.
    ///
    /// > Source IDL Documentation:
    /// >
    /// > IssueReportsService is the report queue: what your users filed, and the
    /// > lifecycle a triager works it through.
    /// > 
    /// > Its methods serve the two audiences this table has. A reporter files, reads
    /// > what they filed, and reads their own list; a triager pages the queue by
    /// > status, by what a report is about, or whole, and moves, revises and archives.
    /// > Every method requires a grant -- see issuereports/grpc's Permissions -- and
    /// > the two whose target is a person or somebody's row ask a second question of
    /// > the consumer's own rule.
    /// > 
    /// > The tenant is not among any method's arguments. It comes off the principal
    /// > the consumer's interceptor resolved, and no request can name another one.
    /// > 
    /// > The two exceptions are the operator's, and they are exceptions by being
    /// > separate methods rather than by a request field: ListReportsAcrossScopes and
    /// > ListReportsByStatusAcrossScopes read every tenant's reports, behind
    /// > issues.reports.read_any, which issuereports/grpc declares and grants to
    /// > nobody. A deployment gives it to its operators or to no one.
    public protocol ClientProtocol: Sendable {
        /// Call the "CreateReport" method.
        ///
        /// - Parameters:
        ///   - request: A request containing a single `Primandproper_Platform_Issuereports_V1_CreateReportRequest` message.
        ///   - serializer: A serializer for `Primandproper_Platform_Issuereports_V1_CreateReportRequest` messages.
        ///   - deserializer: A deserializer for `Primandproper_Platform_Issuereports_V1_CreateReportResponse` messages.
        ///   - options: Options to apply to this RPC.
        ///   - handleResponse: A closure which handles the response and returns its result to
        ///       the caller. Returning from the closure will cancel the RPC if it hasn't
        ///       already finished.
        /// - Returns: The result of `handleResponse`.
        func createReport<Result>(
            request: GRPCCore.ClientRequest<Primandproper_Platform_Issuereports_V1_CreateReportRequest>,
            serializer: some GRPCCore.MessageSerializer<Primandproper_Platform_Issuereports_V1_CreateReportRequest>,
            deserializer: some GRPCCore.MessageDeserializer<Primandproper_Platform_Issuereports_V1_CreateReportResponse>,
            options: GRPCCore.CallOptions,
            onResponse handleResponse: @Sendable @escaping (GRPCCore.ClientResponse<Primandproper_Platform_Issuereports_V1_CreateReportResponse>) async throws -> Result
        ) async throws -> Result where Result: Sendable

        /// Call the "GetReport" method.
        ///
        /// - Parameters:
        ///   - request: A request containing a single `Primandproper_Platform_Issuereports_V1_GetReportRequest` message.
        ///   - serializer: A serializer for `Primandproper_Platform_Issuereports_V1_GetReportRequest` messages.
        ///   - deserializer: A deserializer for `Primandproper_Platform_Issuereports_V1_GetReportResponse` messages.
        ///   - options: Options to apply to this RPC.
        ///   - handleResponse: A closure which handles the response and returns its result to
        ///       the caller. Returning from the closure will cancel the RPC if it hasn't
        ///       already finished.
        /// - Returns: The result of `handleResponse`.
        func getReport<Result>(
            request: GRPCCore.ClientRequest<Primandproper_Platform_Issuereports_V1_GetReportRequest>,
            serializer: some GRPCCore.MessageSerializer<Primandproper_Platform_Issuereports_V1_GetReportRequest>,
            deserializer: some GRPCCore.MessageDeserializer<Primandproper_Platform_Issuereports_V1_GetReportResponse>,
            options: GRPCCore.CallOptions,
            onResponse handleResponse: @Sendable @escaping (GRPCCore.ClientResponse<Primandproper_Platform_Issuereports_V1_GetReportResponse>) async throws -> Result
        ) async throws -> Result where Result: Sendable

        /// Call the "ListReports" method.
        ///
        /// - Parameters:
        ///   - request: A request containing a single `Primandproper_Platform_Issuereports_V1_ListReportsRequest` message.
        ///   - serializer: A serializer for `Primandproper_Platform_Issuereports_V1_ListReportsRequest` messages.
        ///   - deserializer: A deserializer for `Primandproper_Platform_Issuereports_V1_ListReportsResponse` messages.
        ///   - options: Options to apply to this RPC.
        ///   - handleResponse: A closure which handles the response and returns its result to
        ///       the caller. Returning from the closure will cancel the RPC if it hasn't
        ///       already finished.
        /// - Returns: The result of `handleResponse`.
        func listReports<Result>(
            request: GRPCCore.ClientRequest<Primandproper_Platform_Issuereports_V1_ListReportsRequest>,
            serializer: some GRPCCore.MessageSerializer<Primandproper_Platform_Issuereports_V1_ListReportsRequest>,
            deserializer: some GRPCCore.MessageDeserializer<Primandproper_Platform_Issuereports_V1_ListReportsResponse>,
            options: GRPCCore.CallOptions,
            onResponse handleResponse: @Sendable @escaping (GRPCCore.ClientResponse<Primandproper_Platform_Issuereports_V1_ListReportsResponse>) async throws -> Result
        ) async throws -> Result where Result: Sendable

        /// Call the "ListReportsByStatus" method.
        ///
        /// - Parameters:
        ///   - request: A request containing a single `Primandproper_Platform_Issuereports_V1_ListReportsByStatusRequest` message.
        ///   - serializer: A serializer for `Primandproper_Platform_Issuereports_V1_ListReportsByStatusRequest` messages.
        ///   - deserializer: A deserializer for `Primandproper_Platform_Issuereports_V1_ListReportsByStatusResponse` messages.
        ///   - options: Options to apply to this RPC.
        ///   - handleResponse: A closure which handles the response and returns its result to
        ///       the caller. Returning from the closure will cancel the RPC if it hasn't
        ///       already finished.
        /// - Returns: The result of `handleResponse`.
        func listReportsByStatus<Result>(
            request: GRPCCore.ClientRequest<Primandproper_Platform_Issuereports_V1_ListReportsByStatusRequest>,
            serializer: some GRPCCore.MessageSerializer<Primandproper_Platform_Issuereports_V1_ListReportsByStatusRequest>,
            deserializer: some GRPCCore.MessageDeserializer<Primandproper_Platform_Issuereports_V1_ListReportsByStatusResponse>,
            options: GRPCCore.CallOptions,
            onResponse handleResponse: @Sendable @escaping (GRPCCore.ClientResponse<Primandproper_Platform_Issuereports_V1_ListReportsByStatusResponse>) async throws -> Result
        ) async throws -> Result where Result: Sendable

        /// Call the "ListReportsByReporter" method.
        ///
        /// - Parameters:
        ///   - request: A request containing a single `Primandproper_Platform_Issuereports_V1_ListReportsByReporterRequest` message.
        ///   - serializer: A serializer for `Primandproper_Platform_Issuereports_V1_ListReportsByReporterRequest` messages.
        ///   - deserializer: A deserializer for `Primandproper_Platform_Issuereports_V1_ListReportsByReporterResponse` messages.
        ///   - options: Options to apply to this RPC.
        ///   - handleResponse: A closure which handles the response and returns its result to
        ///       the caller. Returning from the closure will cancel the RPC if it hasn't
        ///       already finished.
        /// - Returns: The result of `handleResponse`.
        func listReportsByReporter<Result>(
            request: GRPCCore.ClientRequest<Primandproper_Platform_Issuereports_V1_ListReportsByReporterRequest>,
            serializer: some GRPCCore.MessageSerializer<Primandproper_Platform_Issuereports_V1_ListReportsByReporterRequest>,
            deserializer: some GRPCCore.MessageDeserializer<Primandproper_Platform_Issuereports_V1_ListReportsByReporterResponse>,
            options: GRPCCore.CallOptions,
            onResponse handleResponse: @Sendable @escaping (GRPCCore.ClientResponse<Primandproper_Platform_Issuereports_V1_ListReportsByReporterResponse>) async throws -> Result
        ) async throws -> Result where Result: Sendable

        /// Call the "ListReportsBySubjectType" method.
        ///
        /// - Parameters:
        ///   - request: A request containing a single `Primandproper_Platform_Issuereports_V1_ListReportsBySubjectTypeRequest` message.
        ///   - serializer: A serializer for `Primandproper_Platform_Issuereports_V1_ListReportsBySubjectTypeRequest` messages.
        ///   - deserializer: A deserializer for `Primandproper_Platform_Issuereports_V1_ListReportsBySubjectTypeResponse` messages.
        ///   - options: Options to apply to this RPC.
        ///   - handleResponse: A closure which handles the response and returns its result to
        ///       the caller. Returning from the closure will cancel the RPC if it hasn't
        ///       already finished.
        /// - Returns: The result of `handleResponse`.
        func listReportsBySubjectType<Result>(
            request: GRPCCore.ClientRequest<Primandproper_Platform_Issuereports_V1_ListReportsBySubjectTypeRequest>,
            serializer: some GRPCCore.MessageSerializer<Primandproper_Platform_Issuereports_V1_ListReportsBySubjectTypeRequest>,
            deserializer: some GRPCCore.MessageDeserializer<Primandproper_Platform_Issuereports_V1_ListReportsBySubjectTypeResponse>,
            options: GRPCCore.CallOptions,
            onResponse handleResponse: @Sendable @escaping (GRPCCore.ClientResponse<Primandproper_Platform_Issuereports_V1_ListReportsBySubjectTypeResponse>) async throws -> Result
        ) async throws -> Result where Result: Sendable

        /// Call the "ListReportsForSubject" method.
        ///
        /// - Parameters:
        ///   - request: A request containing a single `Primandproper_Platform_Issuereports_V1_ListReportsForSubjectRequest` message.
        ///   - serializer: A serializer for `Primandproper_Platform_Issuereports_V1_ListReportsForSubjectRequest` messages.
        ///   - deserializer: A deserializer for `Primandproper_Platform_Issuereports_V1_ListReportsForSubjectResponse` messages.
        ///   - options: Options to apply to this RPC.
        ///   - handleResponse: A closure which handles the response and returns its result to
        ///       the caller. Returning from the closure will cancel the RPC if it hasn't
        ///       already finished.
        /// - Returns: The result of `handleResponse`.
        func listReportsForSubject<Result>(
            request: GRPCCore.ClientRequest<Primandproper_Platform_Issuereports_V1_ListReportsForSubjectRequest>,
            serializer: some GRPCCore.MessageSerializer<Primandproper_Platform_Issuereports_V1_ListReportsForSubjectRequest>,
            deserializer: some GRPCCore.MessageDeserializer<Primandproper_Platform_Issuereports_V1_ListReportsForSubjectResponse>,
            options: GRPCCore.CallOptions,
            onResponse handleResponse: @Sendable @escaping (GRPCCore.ClientResponse<Primandproper_Platform_Issuereports_V1_ListReportsForSubjectResponse>) async throws -> Result
        ) async throws -> Result where Result: Sendable

        /// Call the "ListReportsAcrossScopes" method.
        ///
        /// - Parameters:
        ///   - request: A request containing a single `Primandproper_Platform_Issuereports_V1_ListReportsAcrossScopesRequest` message.
        ///   - serializer: A serializer for `Primandproper_Platform_Issuereports_V1_ListReportsAcrossScopesRequest` messages.
        ///   - deserializer: A deserializer for `Primandproper_Platform_Issuereports_V1_ListReportsAcrossScopesResponse` messages.
        ///   - options: Options to apply to this RPC.
        ///   - handleResponse: A closure which handles the response and returns its result to
        ///       the caller. Returning from the closure will cancel the RPC if it hasn't
        ///       already finished.
        /// - Returns: The result of `handleResponse`.
        func listReportsAcrossScopes<Result>(
            request: GRPCCore.ClientRequest<Primandproper_Platform_Issuereports_V1_ListReportsAcrossScopesRequest>,
            serializer: some GRPCCore.MessageSerializer<Primandproper_Platform_Issuereports_V1_ListReportsAcrossScopesRequest>,
            deserializer: some GRPCCore.MessageDeserializer<Primandproper_Platform_Issuereports_V1_ListReportsAcrossScopesResponse>,
            options: GRPCCore.CallOptions,
            onResponse handleResponse: @Sendable @escaping (GRPCCore.ClientResponse<Primandproper_Platform_Issuereports_V1_ListReportsAcrossScopesResponse>) async throws -> Result
        ) async throws -> Result where Result: Sendable

        /// Call the "ListReportsByStatusAcrossScopes" method.
        ///
        /// - Parameters:
        ///   - request: A request containing a single `Primandproper_Platform_Issuereports_V1_ListReportsByStatusAcrossScopesRequest` message.
        ///   - serializer: A serializer for `Primandproper_Platform_Issuereports_V1_ListReportsByStatusAcrossScopesRequest` messages.
        ///   - deserializer: A deserializer for `Primandproper_Platform_Issuereports_V1_ListReportsByStatusAcrossScopesResponse` messages.
        ///   - options: Options to apply to this RPC.
        ///   - handleResponse: A closure which handles the response and returns its result to
        ///       the caller. Returning from the closure will cancel the RPC if it hasn't
        ///       already finished.
        /// - Returns: The result of `handleResponse`.
        func listReportsByStatusAcrossScopes<Result>(
            request: GRPCCore.ClientRequest<Primandproper_Platform_Issuereports_V1_ListReportsByStatusAcrossScopesRequest>,
            serializer: some GRPCCore.MessageSerializer<Primandproper_Platform_Issuereports_V1_ListReportsByStatusAcrossScopesRequest>,
            deserializer: some GRPCCore.MessageDeserializer<Primandproper_Platform_Issuereports_V1_ListReportsByStatusAcrossScopesResponse>,
            options: GRPCCore.CallOptions,
            onResponse handleResponse: @Sendable @escaping (GRPCCore.ClientResponse<Primandproper_Platform_Issuereports_V1_ListReportsByStatusAcrossScopesResponse>) async throws -> Result
        ) async throws -> Result where Result: Sendable

        /// Call the "UpdateReport" method.
        ///
        /// - Parameters:
        ///   - request: A request containing a single `Primandproper_Platform_Issuereports_V1_UpdateReportRequest` message.
        ///   - serializer: A serializer for `Primandproper_Platform_Issuereports_V1_UpdateReportRequest` messages.
        ///   - deserializer: A deserializer for `Primandproper_Platform_Issuereports_V1_UpdateReportResponse` messages.
        ///   - options: Options to apply to this RPC.
        ///   - handleResponse: A closure which handles the response and returns its result to
        ///       the caller. Returning from the closure will cancel the RPC if it hasn't
        ///       already finished.
        /// - Returns: The result of `handleResponse`.
        func updateReport<Result>(
            request: GRPCCore.ClientRequest<Primandproper_Platform_Issuereports_V1_UpdateReportRequest>,
            serializer: some GRPCCore.MessageSerializer<Primandproper_Platform_Issuereports_V1_UpdateReportRequest>,
            deserializer: some GRPCCore.MessageDeserializer<Primandproper_Platform_Issuereports_V1_UpdateReportResponse>,
            options: GRPCCore.CallOptions,
            onResponse handleResponse: @Sendable @escaping (GRPCCore.ClientResponse<Primandproper_Platform_Issuereports_V1_UpdateReportResponse>) async throws -> Result
        ) async throws -> Result where Result: Sendable

        /// Call the "TransitionReport" method.
        ///
        /// - Parameters:
        ///   - request: A request containing a single `Primandproper_Platform_Issuereports_V1_TransitionReportRequest` message.
        ///   - serializer: A serializer for `Primandproper_Platform_Issuereports_V1_TransitionReportRequest` messages.
        ///   - deserializer: A deserializer for `Primandproper_Platform_Issuereports_V1_TransitionReportResponse` messages.
        ///   - options: Options to apply to this RPC.
        ///   - handleResponse: A closure which handles the response and returns its result to
        ///       the caller. Returning from the closure will cancel the RPC if it hasn't
        ///       already finished.
        /// - Returns: The result of `handleResponse`.
        func transitionReport<Result>(
            request: GRPCCore.ClientRequest<Primandproper_Platform_Issuereports_V1_TransitionReportRequest>,
            serializer: some GRPCCore.MessageSerializer<Primandproper_Platform_Issuereports_V1_TransitionReportRequest>,
            deserializer: some GRPCCore.MessageDeserializer<Primandproper_Platform_Issuereports_V1_TransitionReportResponse>,
            options: GRPCCore.CallOptions,
            onResponse handleResponse: @Sendable @escaping (GRPCCore.ClientResponse<Primandproper_Platform_Issuereports_V1_TransitionReportResponse>) async throws -> Result
        ) async throws -> Result where Result: Sendable

        /// Call the "ArchiveReport" method.
        ///
        /// - Parameters:
        ///   - request: A request containing a single `Primandproper_Platform_Issuereports_V1_ArchiveReportRequest` message.
        ///   - serializer: A serializer for `Primandproper_Platform_Issuereports_V1_ArchiveReportRequest` messages.
        ///   - deserializer: A deserializer for `Primandproper_Platform_Issuereports_V1_ArchiveReportResponse` messages.
        ///   - options: Options to apply to this RPC.
        ///   - handleResponse: A closure which handles the response and returns its result to
        ///       the caller. Returning from the closure will cancel the RPC if it hasn't
        ///       already finished.
        /// - Returns: The result of `handleResponse`.
        func archiveReport<Result>(
            request: GRPCCore.ClientRequest<Primandproper_Platform_Issuereports_V1_ArchiveReportRequest>,
            serializer: some GRPCCore.MessageSerializer<Primandproper_Platform_Issuereports_V1_ArchiveReportRequest>,
            deserializer: some GRPCCore.MessageDeserializer<Primandproper_Platform_Issuereports_V1_ArchiveReportResponse>,
            options: GRPCCore.CallOptions,
            onResponse handleResponse: @Sendable @escaping (GRPCCore.ClientResponse<Primandproper_Platform_Issuereports_V1_ArchiveReportResponse>) async throws -> Result
        ) async throws -> Result where Result: Sendable
    }

    /// Generated client for the "primandproper.platform.issuereports.v1.IssueReportsService" service.
    ///
    /// The ``Client`` provides an implementation of ``ClientProtocol`` which wraps
    /// a `GRPCCore.GRPCCClient`. The underlying `GRPCClient` provides the long-lived
    /// means of communication with the remote peer.
    ///
    /// > Source IDL Documentation:
    /// >
    /// > IssueReportsService is the report queue: what your users filed, and the
    /// > lifecycle a triager works it through.
    /// > 
    /// > Its methods serve the two audiences this table has. A reporter files, reads
    /// > what they filed, and reads their own list; a triager pages the queue by
    /// > status, by what a report is about, or whole, and moves, revises and archives.
    /// > Every method requires a grant -- see issuereports/grpc's Permissions -- and
    /// > the two whose target is a person or somebody's row ask a second question of
    /// > the consumer's own rule.
    /// > 
    /// > The tenant is not among any method's arguments. It comes off the principal
    /// > the consumer's interceptor resolved, and no request can name another one.
    /// > 
    /// > The two exceptions are the operator's, and they are exceptions by being
    /// > separate methods rather than by a request field: ListReportsAcrossScopes and
    /// > ListReportsByStatusAcrossScopes read every tenant's reports, behind
    /// > issues.reports.read_any, which issuereports/grpc declares and grants to
    /// > nobody. A deployment gives it to its operators or to no one.
    public struct Client<Transport>: ClientProtocol where Transport: GRPCCore.ClientTransport {
        private let client: GRPCCore.GRPCClient<Transport>

        /// Creates a new client wrapping the provided `GRPCCore.GRPCClient`.
        ///
        /// - Parameters:
        ///   - client: A `GRPCCore.GRPCClient` providing a communication channel to the service.
        public init(wrapping client: GRPCCore.GRPCClient<Transport>) {
            self.client = client
        }

        /// Call the "CreateReport" method.
        ///
        /// - Parameters:
        ///   - request: A request containing a single `Primandproper_Platform_Issuereports_V1_CreateReportRequest` message.
        ///   - serializer: A serializer for `Primandproper_Platform_Issuereports_V1_CreateReportRequest` messages.
        ///   - deserializer: A deserializer for `Primandproper_Platform_Issuereports_V1_CreateReportResponse` messages.
        ///   - options: Options to apply to this RPC.
        ///   - handleResponse: A closure which handles the response and returns its result to
        ///       the caller. Returning from the closure will cancel the RPC if it hasn't
        ///       already finished.
        /// - Returns: The result of `handleResponse`.
        public func createReport<Result>(
            request: GRPCCore.ClientRequest<Primandproper_Platform_Issuereports_V1_CreateReportRequest>,
            serializer: some GRPCCore.MessageSerializer<Primandproper_Platform_Issuereports_V1_CreateReportRequest>,
            deserializer: some GRPCCore.MessageDeserializer<Primandproper_Platform_Issuereports_V1_CreateReportResponse>,
            options: GRPCCore.CallOptions = .defaults,
            onResponse handleResponse: @Sendable @escaping (GRPCCore.ClientResponse<Primandproper_Platform_Issuereports_V1_CreateReportResponse>) async throws -> Result = { response in
                try response.message
            }
        ) async throws -> Result where Result: Sendable {
            try await self.client.unary(
                request: request,
                descriptor: Primandproper_Platform_Issuereports_V1_IssueReportsService.Method.CreateReport.descriptor,
                serializer: serializer,
                deserializer: deserializer,
                options: options,
                onResponse: handleResponse
            )
        }

        /// Call the "GetReport" method.
        ///
        /// - Parameters:
        ///   - request: A request containing a single `Primandproper_Platform_Issuereports_V1_GetReportRequest` message.
        ///   - serializer: A serializer for `Primandproper_Platform_Issuereports_V1_GetReportRequest` messages.
        ///   - deserializer: A deserializer for `Primandproper_Platform_Issuereports_V1_GetReportResponse` messages.
        ///   - options: Options to apply to this RPC.
        ///   - handleResponse: A closure which handles the response and returns its result to
        ///       the caller. Returning from the closure will cancel the RPC if it hasn't
        ///       already finished.
        /// - Returns: The result of `handleResponse`.
        public func getReport<Result>(
            request: GRPCCore.ClientRequest<Primandproper_Platform_Issuereports_V1_GetReportRequest>,
            serializer: some GRPCCore.MessageSerializer<Primandproper_Platform_Issuereports_V1_GetReportRequest>,
            deserializer: some GRPCCore.MessageDeserializer<Primandproper_Platform_Issuereports_V1_GetReportResponse>,
            options: GRPCCore.CallOptions = .defaults,
            onResponse handleResponse: @Sendable @escaping (GRPCCore.ClientResponse<Primandproper_Platform_Issuereports_V1_GetReportResponse>) async throws -> Result = { response in
                try response.message
            }
        ) async throws -> Result where Result: Sendable {
            try await self.client.unary(
                request: request,
                descriptor: Primandproper_Platform_Issuereports_V1_IssueReportsService.Method.GetReport.descriptor,
                serializer: serializer,
                deserializer: deserializer,
                options: options,
                onResponse: handleResponse
            )
        }

        /// Call the "ListReports" method.
        ///
        /// - Parameters:
        ///   - request: A request containing a single `Primandproper_Platform_Issuereports_V1_ListReportsRequest` message.
        ///   - serializer: A serializer for `Primandproper_Platform_Issuereports_V1_ListReportsRequest` messages.
        ///   - deserializer: A deserializer for `Primandproper_Platform_Issuereports_V1_ListReportsResponse` messages.
        ///   - options: Options to apply to this RPC.
        ///   - handleResponse: A closure which handles the response and returns its result to
        ///       the caller. Returning from the closure will cancel the RPC if it hasn't
        ///       already finished.
        /// - Returns: The result of `handleResponse`.
        public func listReports<Result>(
            request: GRPCCore.ClientRequest<Primandproper_Platform_Issuereports_V1_ListReportsRequest>,
            serializer: some GRPCCore.MessageSerializer<Primandproper_Platform_Issuereports_V1_ListReportsRequest>,
            deserializer: some GRPCCore.MessageDeserializer<Primandproper_Platform_Issuereports_V1_ListReportsResponse>,
            options: GRPCCore.CallOptions = .defaults,
            onResponse handleResponse: @Sendable @escaping (GRPCCore.ClientResponse<Primandproper_Platform_Issuereports_V1_ListReportsResponse>) async throws -> Result = { response in
                try response.message
            }
        ) async throws -> Result where Result: Sendable {
            try await self.client.unary(
                request: request,
                descriptor: Primandproper_Platform_Issuereports_V1_IssueReportsService.Method.ListReports.descriptor,
                serializer: serializer,
                deserializer: deserializer,
                options: options,
                onResponse: handleResponse
            )
        }

        /// Call the "ListReportsByStatus" method.
        ///
        /// - Parameters:
        ///   - request: A request containing a single `Primandproper_Platform_Issuereports_V1_ListReportsByStatusRequest` message.
        ///   - serializer: A serializer for `Primandproper_Platform_Issuereports_V1_ListReportsByStatusRequest` messages.
        ///   - deserializer: A deserializer for `Primandproper_Platform_Issuereports_V1_ListReportsByStatusResponse` messages.
        ///   - options: Options to apply to this RPC.
        ///   - handleResponse: A closure which handles the response and returns its result to
        ///       the caller. Returning from the closure will cancel the RPC if it hasn't
        ///       already finished.
        /// - Returns: The result of `handleResponse`.
        public func listReportsByStatus<Result>(
            request: GRPCCore.ClientRequest<Primandproper_Platform_Issuereports_V1_ListReportsByStatusRequest>,
            serializer: some GRPCCore.MessageSerializer<Primandproper_Platform_Issuereports_V1_ListReportsByStatusRequest>,
            deserializer: some GRPCCore.MessageDeserializer<Primandproper_Platform_Issuereports_V1_ListReportsByStatusResponse>,
            options: GRPCCore.CallOptions = .defaults,
            onResponse handleResponse: @Sendable @escaping (GRPCCore.ClientResponse<Primandproper_Platform_Issuereports_V1_ListReportsByStatusResponse>) async throws -> Result = { response in
                try response.message
            }
        ) async throws -> Result where Result: Sendable {
            try await self.client.unary(
                request: request,
                descriptor: Primandproper_Platform_Issuereports_V1_IssueReportsService.Method.ListReportsByStatus.descriptor,
                serializer: serializer,
                deserializer: deserializer,
                options: options,
                onResponse: handleResponse
            )
        }

        /// Call the "ListReportsByReporter" method.
        ///
        /// - Parameters:
        ///   - request: A request containing a single `Primandproper_Platform_Issuereports_V1_ListReportsByReporterRequest` message.
        ///   - serializer: A serializer for `Primandproper_Platform_Issuereports_V1_ListReportsByReporterRequest` messages.
        ///   - deserializer: A deserializer for `Primandproper_Platform_Issuereports_V1_ListReportsByReporterResponse` messages.
        ///   - options: Options to apply to this RPC.
        ///   - handleResponse: A closure which handles the response and returns its result to
        ///       the caller. Returning from the closure will cancel the RPC if it hasn't
        ///       already finished.
        /// - Returns: The result of `handleResponse`.
        public func listReportsByReporter<Result>(
            request: GRPCCore.ClientRequest<Primandproper_Platform_Issuereports_V1_ListReportsByReporterRequest>,
            serializer: some GRPCCore.MessageSerializer<Primandproper_Platform_Issuereports_V1_ListReportsByReporterRequest>,
            deserializer: some GRPCCore.MessageDeserializer<Primandproper_Platform_Issuereports_V1_ListReportsByReporterResponse>,
            options: GRPCCore.CallOptions = .defaults,
            onResponse handleResponse: @Sendable @escaping (GRPCCore.ClientResponse<Primandproper_Platform_Issuereports_V1_ListReportsByReporterResponse>) async throws -> Result = { response in
                try response.message
            }
        ) async throws -> Result where Result: Sendable {
            try await self.client.unary(
                request: request,
                descriptor: Primandproper_Platform_Issuereports_V1_IssueReportsService.Method.ListReportsByReporter.descriptor,
                serializer: serializer,
                deserializer: deserializer,
                options: options,
                onResponse: handleResponse
            )
        }

        /// Call the "ListReportsBySubjectType" method.
        ///
        /// - Parameters:
        ///   - request: A request containing a single `Primandproper_Platform_Issuereports_V1_ListReportsBySubjectTypeRequest` message.
        ///   - serializer: A serializer for `Primandproper_Platform_Issuereports_V1_ListReportsBySubjectTypeRequest` messages.
        ///   - deserializer: A deserializer for `Primandproper_Platform_Issuereports_V1_ListReportsBySubjectTypeResponse` messages.
        ///   - options: Options to apply to this RPC.
        ///   - handleResponse: A closure which handles the response and returns its result to
        ///       the caller. Returning from the closure will cancel the RPC if it hasn't
        ///       already finished.
        /// - Returns: The result of `handleResponse`.
        public func listReportsBySubjectType<Result>(
            request: GRPCCore.ClientRequest<Primandproper_Platform_Issuereports_V1_ListReportsBySubjectTypeRequest>,
            serializer: some GRPCCore.MessageSerializer<Primandproper_Platform_Issuereports_V1_ListReportsBySubjectTypeRequest>,
            deserializer: some GRPCCore.MessageDeserializer<Primandproper_Platform_Issuereports_V1_ListReportsBySubjectTypeResponse>,
            options: GRPCCore.CallOptions = .defaults,
            onResponse handleResponse: @Sendable @escaping (GRPCCore.ClientResponse<Primandproper_Platform_Issuereports_V1_ListReportsBySubjectTypeResponse>) async throws -> Result = { response in
                try response.message
            }
        ) async throws -> Result where Result: Sendable {
            try await self.client.unary(
                request: request,
                descriptor: Primandproper_Platform_Issuereports_V1_IssueReportsService.Method.ListReportsBySubjectType.descriptor,
                serializer: serializer,
                deserializer: deserializer,
                options: options,
                onResponse: handleResponse
            )
        }

        /// Call the "ListReportsForSubject" method.
        ///
        /// - Parameters:
        ///   - request: A request containing a single `Primandproper_Platform_Issuereports_V1_ListReportsForSubjectRequest` message.
        ///   - serializer: A serializer for `Primandproper_Platform_Issuereports_V1_ListReportsForSubjectRequest` messages.
        ///   - deserializer: A deserializer for `Primandproper_Platform_Issuereports_V1_ListReportsForSubjectResponse` messages.
        ///   - options: Options to apply to this RPC.
        ///   - handleResponse: A closure which handles the response and returns its result to
        ///       the caller. Returning from the closure will cancel the RPC if it hasn't
        ///       already finished.
        /// - Returns: The result of `handleResponse`.
        public func listReportsForSubject<Result>(
            request: GRPCCore.ClientRequest<Primandproper_Platform_Issuereports_V1_ListReportsForSubjectRequest>,
            serializer: some GRPCCore.MessageSerializer<Primandproper_Platform_Issuereports_V1_ListReportsForSubjectRequest>,
            deserializer: some GRPCCore.MessageDeserializer<Primandproper_Platform_Issuereports_V1_ListReportsForSubjectResponse>,
            options: GRPCCore.CallOptions = .defaults,
            onResponse handleResponse: @Sendable @escaping (GRPCCore.ClientResponse<Primandproper_Platform_Issuereports_V1_ListReportsForSubjectResponse>) async throws -> Result = { response in
                try response.message
            }
        ) async throws -> Result where Result: Sendable {
            try await self.client.unary(
                request: request,
                descriptor: Primandproper_Platform_Issuereports_V1_IssueReportsService.Method.ListReportsForSubject.descriptor,
                serializer: serializer,
                deserializer: deserializer,
                options: options,
                onResponse: handleResponse
            )
        }

        /// Call the "ListReportsAcrossScopes" method.
        ///
        /// - Parameters:
        ///   - request: A request containing a single `Primandproper_Platform_Issuereports_V1_ListReportsAcrossScopesRequest` message.
        ///   - serializer: A serializer for `Primandproper_Platform_Issuereports_V1_ListReportsAcrossScopesRequest` messages.
        ///   - deserializer: A deserializer for `Primandproper_Platform_Issuereports_V1_ListReportsAcrossScopesResponse` messages.
        ///   - options: Options to apply to this RPC.
        ///   - handleResponse: A closure which handles the response and returns its result to
        ///       the caller. Returning from the closure will cancel the RPC if it hasn't
        ///       already finished.
        /// - Returns: The result of `handleResponse`.
        public func listReportsAcrossScopes<Result>(
            request: GRPCCore.ClientRequest<Primandproper_Platform_Issuereports_V1_ListReportsAcrossScopesRequest>,
            serializer: some GRPCCore.MessageSerializer<Primandproper_Platform_Issuereports_V1_ListReportsAcrossScopesRequest>,
            deserializer: some GRPCCore.MessageDeserializer<Primandproper_Platform_Issuereports_V1_ListReportsAcrossScopesResponse>,
            options: GRPCCore.CallOptions = .defaults,
            onResponse handleResponse: @Sendable @escaping (GRPCCore.ClientResponse<Primandproper_Platform_Issuereports_V1_ListReportsAcrossScopesResponse>) async throws -> Result = { response in
                try response.message
            }
        ) async throws -> Result where Result: Sendable {
            try await self.client.unary(
                request: request,
                descriptor: Primandproper_Platform_Issuereports_V1_IssueReportsService.Method.ListReportsAcrossScopes.descriptor,
                serializer: serializer,
                deserializer: deserializer,
                options: options,
                onResponse: handleResponse
            )
        }

        /// Call the "ListReportsByStatusAcrossScopes" method.
        ///
        /// - Parameters:
        ///   - request: A request containing a single `Primandproper_Platform_Issuereports_V1_ListReportsByStatusAcrossScopesRequest` message.
        ///   - serializer: A serializer for `Primandproper_Platform_Issuereports_V1_ListReportsByStatusAcrossScopesRequest` messages.
        ///   - deserializer: A deserializer for `Primandproper_Platform_Issuereports_V1_ListReportsByStatusAcrossScopesResponse` messages.
        ///   - options: Options to apply to this RPC.
        ///   - handleResponse: A closure which handles the response and returns its result to
        ///       the caller. Returning from the closure will cancel the RPC if it hasn't
        ///       already finished.
        /// - Returns: The result of `handleResponse`.
        public func listReportsByStatusAcrossScopes<Result>(
            request: GRPCCore.ClientRequest<Primandproper_Platform_Issuereports_V1_ListReportsByStatusAcrossScopesRequest>,
            serializer: some GRPCCore.MessageSerializer<Primandproper_Platform_Issuereports_V1_ListReportsByStatusAcrossScopesRequest>,
            deserializer: some GRPCCore.MessageDeserializer<Primandproper_Platform_Issuereports_V1_ListReportsByStatusAcrossScopesResponse>,
            options: GRPCCore.CallOptions = .defaults,
            onResponse handleResponse: @Sendable @escaping (GRPCCore.ClientResponse<Primandproper_Platform_Issuereports_V1_ListReportsByStatusAcrossScopesResponse>) async throws -> Result = { response in
                try response.message
            }
        ) async throws -> Result where Result: Sendable {
            try await self.client.unary(
                request: request,
                descriptor: Primandproper_Platform_Issuereports_V1_IssueReportsService.Method.ListReportsByStatusAcrossScopes.descriptor,
                serializer: serializer,
                deserializer: deserializer,
                options: options,
                onResponse: handleResponse
            )
        }

        /// Call the "UpdateReport" method.
        ///
        /// - Parameters:
        ///   - request: A request containing a single `Primandproper_Platform_Issuereports_V1_UpdateReportRequest` message.
        ///   - serializer: A serializer for `Primandproper_Platform_Issuereports_V1_UpdateReportRequest` messages.
        ///   - deserializer: A deserializer for `Primandproper_Platform_Issuereports_V1_UpdateReportResponse` messages.
        ///   - options: Options to apply to this RPC.
        ///   - handleResponse: A closure which handles the response and returns its result to
        ///       the caller. Returning from the closure will cancel the RPC if it hasn't
        ///       already finished.
        /// - Returns: The result of `handleResponse`.
        public func updateReport<Result>(
            request: GRPCCore.ClientRequest<Primandproper_Platform_Issuereports_V1_UpdateReportRequest>,
            serializer: some GRPCCore.MessageSerializer<Primandproper_Platform_Issuereports_V1_UpdateReportRequest>,
            deserializer: some GRPCCore.MessageDeserializer<Primandproper_Platform_Issuereports_V1_UpdateReportResponse>,
            options: GRPCCore.CallOptions = .defaults,
            onResponse handleResponse: @Sendable @escaping (GRPCCore.ClientResponse<Primandproper_Platform_Issuereports_V1_UpdateReportResponse>) async throws -> Result = { response in
                try response.message
            }
        ) async throws -> Result where Result: Sendable {
            try await self.client.unary(
                request: request,
                descriptor: Primandproper_Platform_Issuereports_V1_IssueReportsService.Method.UpdateReport.descriptor,
                serializer: serializer,
                deserializer: deserializer,
                options: options,
                onResponse: handleResponse
            )
        }

        /// Call the "TransitionReport" method.
        ///
        /// - Parameters:
        ///   - request: A request containing a single `Primandproper_Platform_Issuereports_V1_TransitionReportRequest` message.
        ///   - serializer: A serializer for `Primandproper_Platform_Issuereports_V1_TransitionReportRequest` messages.
        ///   - deserializer: A deserializer for `Primandproper_Platform_Issuereports_V1_TransitionReportResponse` messages.
        ///   - options: Options to apply to this RPC.
        ///   - handleResponse: A closure which handles the response and returns its result to
        ///       the caller. Returning from the closure will cancel the RPC if it hasn't
        ///       already finished.
        /// - Returns: The result of `handleResponse`.
        public func transitionReport<Result>(
            request: GRPCCore.ClientRequest<Primandproper_Platform_Issuereports_V1_TransitionReportRequest>,
            serializer: some GRPCCore.MessageSerializer<Primandproper_Platform_Issuereports_V1_TransitionReportRequest>,
            deserializer: some GRPCCore.MessageDeserializer<Primandproper_Platform_Issuereports_V1_TransitionReportResponse>,
            options: GRPCCore.CallOptions = .defaults,
            onResponse handleResponse: @Sendable @escaping (GRPCCore.ClientResponse<Primandproper_Platform_Issuereports_V1_TransitionReportResponse>) async throws -> Result = { response in
                try response.message
            }
        ) async throws -> Result where Result: Sendable {
            try await self.client.unary(
                request: request,
                descriptor: Primandproper_Platform_Issuereports_V1_IssueReportsService.Method.TransitionReport.descriptor,
                serializer: serializer,
                deserializer: deserializer,
                options: options,
                onResponse: handleResponse
            )
        }

        /// Call the "ArchiveReport" method.
        ///
        /// - Parameters:
        ///   - request: A request containing a single `Primandproper_Platform_Issuereports_V1_ArchiveReportRequest` message.
        ///   - serializer: A serializer for `Primandproper_Platform_Issuereports_V1_ArchiveReportRequest` messages.
        ///   - deserializer: A deserializer for `Primandproper_Platform_Issuereports_V1_ArchiveReportResponse` messages.
        ///   - options: Options to apply to this RPC.
        ///   - handleResponse: A closure which handles the response and returns its result to
        ///       the caller. Returning from the closure will cancel the RPC if it hasn't
        ///       already finished.
        /// - Returns: The result of `handleResponse`.
        public func archiveReport<Result>(
            request: GRPCCore.ClientRequest<Primandproper_Platform_Issuereports_V1_ArchiveReportRequest>,
            serializer: some GRPCCore.MessageSerializer<Primandproper_Platform_Issuereports_V1_ArchiveReportRequest>,
            deserializer: some GRPCCore.MessageDeserializer<Primandproper_Platform_Issuereports_V1_ArchiveReportResponse>,
            options: GRPCCore.CallOptions = .defaults,
            onResponse handleResponse: @Sendable @escaping (GRPCCore.ClientResponse<Primandproper_Platform_Issuereports_V1_ArchiveReportResponse>) async throws -> Result = { response in
                try response.message
            }
        ) async throws -> Result where Result: Sendable {
            try await self.client.unary(
                request: request,
                descriptor: Primandproper_Platform_Issuereports_V1_IssueReportsService.Method.ArchiveReport.descriptor,
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
extension Primandproper_Platform_Issuereports_V1_IssueReportsService.ClientProtocol {
    /// Call the "CreateReport" method.
    ///
    /// - Parameters:
    ///   - request: A request containing a single `Primandproper_Platform_Issuereports_V1_CreateReportRequest` message.
    ///   - options: Options to apply to this RPC.
    ///   - handleResponse: A closure which handles the response and returns its result to
    ///       the caller. Returning from the closure will cancel the RPC if it hasn't
    ///       already finished.
    /// - Returns: The result of `handleResponse`.
    public func createReport<Result>(
        request: GRPCCore.ClientRequest<Primandproper_Platform_Issuereports_V1_CreateReportRequest>,
        options: GRPCCore.CallOptions = .defaults,
        onResponse handleResponse: @Sendable @escaping (GRPCCore.ClientResponse<Primandproper_Platform_Issuereports_V1_CreateReportResponse>) async throws -> Result = { response in
            try response.message
        }
    ) async throws -> Result where Result: Sendable {
        try await self.createReport(
            request: request,
            serializer: GRPCProtobuf.ProtobufSerializer<Primandproper_Platform_Issuereports_V1_CreateReportRequest>(),
            deserializer: GRPCProtobuf.ProtobufDeserializer<Primandproper_Platform_Issuereports_V1_CreateReportResponse>(),
            options: options,
            onResponse: handleResponse
        )
    }

    /// Call the "GetReport" method.
    ///
    /// - Parameters:
    ///   - request: A request containing a single `Primandproper_Platform_Issuereports_V1_GetReportRequest` message.
    ///   - options: Options to apply to this RPC.
    ///   - handleResponse: A closure which handles the response and returns its result to
    ///       the caller. Returning from the closure will cancel the RPC if it hasn't
    ///       already finished.
    /// - Returns: The result of `handleResponse`.
    public func getReport<Result>(
        request: GRPCCore.ClientRequest<Primandproper_Platform_Issuereports_V1_GetReportRequest>,
        options: GRPCCore.CallOptions = .defaults,
        onResponse handleResponse: @Sendable @escaping (GRPCCore.ClientResponse<Primandproper_Platform_Issuereports_V1_GetReportResponse>) async throws -> Result = { response in
            try response.message
        }
    ) async throws -> Result where Result: Sendable {
        try await self.getReport(
            request: request,
            serializer: GRPCProtobuf.ProtobufSerializer<Primandproper_Platform_Issuereports_V1_GetReportRequest>(),
            deserializer: GRPCProtobuf.ProtobufDeserializer<Primandproper_Platform_Issuereports_V1_GetReportResponse>(),
            options: options,
            onResponse: handleResponse
        )
    }

    /// Call the "ListReports" method.
    ///
    /// - Parameters:
    ///   - request: A request containing a single `Primandproper_Platform_Issuereports_V1_ListReportsRequest` message.
    ///   - options: Options to apply to this RPC.
    ///   - handleResponse: A closure which handles the response and returns its result to
    ///       the caller. Returning from the closure will cancel the RPC if it hasn't
    ///       already finished.
    /// - Returns: The result of `handleResponse`.
    public func listReports<Result>(
        request: GRPCCore.ClientRequest<Primandproper_Platform_Issuereports_V1_ListReportsRequest>,
        options: GRPCCore.CallOptions = .defaults,
        onResponse handleResponse: @Sendable @escaping (GRPCCore.ClientResponse<Primandproper_Platform_Issuereports_V1_ListReportsResponse>) async throws -> Result = { response in
            try response.message
        }
    ) async throws -> Result where Result: Sendable {
        try await self.listReports(
            request: request,
            serializer: GRPCProtobuf.ProtobufSerializer<Primandproper_Platform_Issuereports_V1_ListReportsRequest>(),
            deserializer: GRPCProtobuf.ProtobufDeserializer<Primandproper_Platform_Issuereports_V1_ListReportsResponse>(),
            options: options,
            onResponse: handleResponse
        )
    }

    /// Call the "ListReportsByStatus" method.
    ///
    /// - Parameters:
    ///   - request: A request containing a single `Primandproper_Platform_Issuereports_V1_ListReportsByStatusRequest` message.
    ///   - options: Options to apply to this RPC.
    ///   - handleResponse: A closure which handles the response and returns its result to
    ///       the caller. Returning from the closure will cancel the RPC if it hasn't
    ///       already finished.
    /// - Returns: The result of `handleResponse`.
    public func listReportsByStatus<Result>(
        request: GRPCCore.ClientRequest<Primandproper_Platform_Issuereports_V1_ListReportsByStatusRequest>,
        options: GRPCCore.CallOptions = .defaults,
        onResponse handleResponse: @Sendable @escaping (GRPCCore.ClientResponse<Primandproper_Platform_Issuereports_V1_ListReportsByStatusResponse>) async throws -> Result = { response in
            try response.message
        }
    ) async throws -> Result where Result: Sendable {
        try await self.listReportsByStatus(
            request: request,
            serializer: GRPCProtobuf.ProtobufSerializer<Primandproper_Platform_Issuereports_V1_ListReportsByStatusRequest>(),
            deserializer: GRPCProtobuf.ProtobufDeserializer<Primandproper_Platform_Issuereports_V1_ListReportsByStatusResponse>(),
            options: options,
            onResponse: handleResponse
        )
    }

    /// Call the "ListReportsByReporter" method.
    ///
    /// - Parameters:
    ///   - request: A request containing a single `Primandproper_Platform_Issuereports_V1_ListReportsByReporterRequest` message.
    ///   - options: Options to apply to this RPC.
    ///   - handleResponse: A closure which handles the response and returns its result to
    ///       the caller. Returning from the closure will cancel the RPC if it hasn't
    ///       already finished.
    /// - Returns: The result of `handleResponse`.
    public func listReportsByReporter<Result>(
        request: GRPCCore.ClientRequest<Primandproper_Platform_Issuereports_V1_ListReportsByReporterRequest>,
        options: GRPCCore.CallOptions = .defaults,
        onResponse handleResponse: @Sendable @escaping (GRPCCore.ClientResponse<Primandproper_Platform_Issuereports_V1_ListReportsByReporterResponse>) async throws -> Result = { response in
            try response.message
        }
    ) async throws -> Result where Result: Sendable {
        try await self.listReportsByReporter(
            request: request,
            serializer: GRPCProtobuf.ProtobufSerializer<Primandproper_Platform_Issuereports_V1_ListReportsByReporterRequest>(),
            deserializer: GRPCProtobuf.ProtobufDeserializer<Primandproper_Platform_Issuereports_V1_ListReportsByReporterResponse>(),
            options: options,
            onResponse: handleResponse
        )
    }

    /// Call the "ListReportsBySubjectType" method.
    ///
    /// - Parameters:
    ///   - request: A request containing a single `Primandproper_Platform_Issuereports_V1_ListReportsBySubjectTypeRequest` message.
    ///   - options: Options to apply to this RPC.
    ///   - handleResponse: A closure which handles the response and returns its result to
    ///       the caller. Returning from the closure will cancel the RPC if it hasn't
    ///       already finished.
    /// - Returns: The result of `handleResponse`.
    public func listReportsBySubjectType<Result>(
        request: GRPCCore.ClientRequest<Primandproper_Platform_Issuereports_V1_ListReportsBySubjectTypeRequest>,
        options: GRPCCore.CallOptions = .defaults,
        onResponse handleResponse: @Sendable @escaping (GRPCCore.ClientResponse<Primandproper_Platform_Issuereports_V1_ListReportsBySubjectTypeResponse>) async throws -> Result = { response in
            try response.message
        }
    ) async throws -> Result where Result: Sendable {
        try await self.listReportsBySubjectType(
            request: request,
            serializer: GRPCProtobuf.ProtobufSerializer<Primandproper_Platform_Issuereports_V1_ListReportsBySubjectTypeRequest>(),
            deserializer: GRPCProtobuf.ProtobufDeserializer<Primandproper_Platform_Issuereports_V1_ListReportsBySubjectTypeResponse>(),
            options: options,
            onResponse: handleResponse
        )
    }

    /// Call the "ListReportsForSubject" method.
    ///
    /// - Parameters:
    ///   - request: A request containing a single `Primandproper_Platform_Issuereports_V1_ListReportsForSubjectRequest` message.
    ///   - options: Options to apply to this RPC.
    ///   - handleResponse: A closure which handles the response and returns its result to
    ///       the caller. Returning from the closure will cancel the RPC if it hasn't
    ///       already finished.
    /// - Returns: The result of `handleResponse`.
    public func listReportsForSubject<Result>(
        request: GRPCCore.ClientRequest<Primandproper_Platform_Issuereports_V1_ListReportsForSubjectRequest>,
        options: GRPCCore.CallOptions = .defaults,
        onResponse handleResponse: @Sendable @escaping (GRPCCore.ClientResponse<Primandproper_Platform_Issuereports_V1_ListReportsForSubjectResponse>) async throws -> Result = { response in
            try response.message
        }
    ) async throws -> Result where Result: Sendable {
        try await self.listReportsForSubject(
            request: request,
            serializer: GRPCProtobuf.ProtobufSerializer<Primandproper_Platform_Issuereports_V1_ListReportsForSubjectRequest>(),
            deserializer: GRPCProtobuf.ProtobufDeserializer<Primandproper_Platform_Issuereports_V1_ListReportsForSubjectResponse>(),
            options: options,
            onResponse: handleResponse
        )
    }

    /// Call the "ListReportsAcrossScopes" method.
    ///
    /// - Parameters:
    ///   - request: A request containing a single `Primandproper_Platform_Issuereports_V1_ListReportsAcrossScopesRequest` message.
    ///   - options: Options to apply to this RPC.
    ///   - handleResponse: A closure which handles the response and returns its result to
    ///       the caller. Returning from the closure will cancel the RPC if it hasn't
    ///       already finished.
    /// - Returns: The result of `handleResponse`.
    public func listReportsAcrossScopes<Result>(
        request: GRPCCore.ClientRequest<Primandproper_Platform_Issuereports_V1_ListReportsAcrossScopesRequest>,
        options: GRPCCore.CallOptions = .defaults,
        onResponse handleResponse: @Sendable @escaping (GRPCCore.ClientResponse<Primandproper_Platform_Issuereports_V1_ListReportsAcrossScopesResponse>) async throws -> Result = { response in
            try response.message
        }
    ) async throws -> Result where Result: Sendable {
        try await self.listReportsAcrossScopes(
            request: request,
            serializer: GRPCProtobuf.ProtobufSerializer<Primandproper_Platform_Issuereports_V1_ListReportsAcrossScopesRequest>(),
            deserializer: GRPCProtobuf.ProtobufDeserializer<Primandproper_Platform_Issuereports_V1_ListReportsAcrossScopesResponse>(),
            options: options,
            onResponse: handleResponse
        )
    }

    /// Call the "ListReportsByStatusAcrossScopes" method.
    ///
    /// - Parameters:
    ///   - request: A request containing a single `Primandproper_Platform_Issuereports_V1_ListReportsByStatusAcrossScopesRequest` message.
    ///   - options: Options to apply to this RPC.
    ///   - handleResponse: A closure which handles the response and returns its result to
    ///       the caller. Returning from the closure will cancel the RPC if it hasn't
    ///       already finished.
    /// - Returns: The result of `handleResponse`.
    public func listReportsByStatusAcrossScopes<Result>(
        request: GRPCCore.ClientRequest<Primandproper_Platform_Issuereports_V1_ListReportsByStatusAcrossScopesRequest>,
        options: GRPCCore.CallOptions = .defaults,
        onResponse handleResponse: @Sendable @escaping (GRPCCore.ClientResponse<Primandproper_Platform_Issuereports_V1_ListReportsByStatusAcrossScopesResponse>) async throws -> Result = { response in
            try response.message
        }
    ) async throws -> Result where Result: Sendable {
        try await self.listReportsByStatusAcrossScopes(
            request: request,
            serializer: GRPCProtobuf.ProtobufSerializer<Primandproper_Platform_Issuereports_V1_ListReportsByStatusAcrossScopesRequest>(),
            deserializer: GRPCProtobuf.ProtobufDeserializer<Primandproper_Platform_Issuereports_V1_ListReportsByStatusAcrossScopesResponse>(),
            options: options,
            onResponse: handleResponse
        )
    }

    /// Call the "UpdateReport" method.
    ///
    /// - Parameters:
    ///   - request: A request containing a single `Primandproper_Platform_Issuereports_V1_UpdateReportRequest` message.
    ///   - options: Options to apply to this RPC.
    ///   - handleResponse: A closure which handles the response and returns its result to
    ///       the caller. Returning from the closure will cancel the RPC if it hasn't
    ///       already finished.
    /// - Returns: The result of `handleResponse`.
    public func updateReport<Result>(
        request: GRPCCore.ClientRequest<Primandproper_Platform_Issuereports_V1_UpdateReportRequest>,
        options: GRPCCore.CallOptions = .defaults,
        onResponse handleResponse: @Sendable @escaping (GRPCCore.ClientResponse<Primandproper_Platform_Issuereports_V1_UpdateReportResponse>) async throws -> Result = { response in
            try response.message
        }
    ) async throws -> Result where Result: Sendable {
        try await self.updateReport(
            request: request,
            serializer: GRPCProtobuf.ProtobufSerializer<Primandproper_Platform_Issuereports_V1_UpdateReportRequest>(),
            deserializer: GRPCProtobuf.ProtobufDeserializer<Primandproper_Platform_Issuereports_V1_UpdateReportResponse>(),
            options: options,
            onResponse: handleResponse
        )
    }

    /// Call the "TransitionReport" method.
    ///
    /// - Parameters:
    ///   - request: A request containing a single `Primandproper_Platform_Issuereports_V1_TransitionReportRequest` message.
    ///   - options: Options to apply to this RPC.
    ///   - handleResponse: A closure which handles the response and returns its result to
    ///       the caller. Returning from the closure will cancel the RPC if it hasn't
    ///       already finished.
    /// - Returns: The result of `handleResponse`.
    public func transitionReport<Result>(
        request: GRPCCore.ClientRequest<Primandproper_Platform_Issuereports_V1_TransitionReportRequest>,
        options: GRPCCore.CallOptions = .defaults,
        onResponse handleResponse: @Sendable @escaping (GRPCCore.ClientResponse<Primandproper_Platform_Issuereports_V1_TransitionReportResponse>) async throws -> Result = { response in
            try response.message
        }
    ) async throws -> Result where Result: Sendable {
        try await self.transitionReport(
            request: request,
            serializer: GRPCProtobuf.ProtobufSerializer<Primandproper_Platform_Issuereports_V1_TransitionReportRequest>(),
            deserializer: GRPCProtobuf.ProtobufDeserializer<Primandproper_Platform_Issuereports_V1_TransitionReportResponse>(),
            options: options,
            onResponse: handleResponse
        )
    }

    /// Call the "ArchiveReport" method.
    ///
    /// - Parameters:
    ///   - request: A request containing a single `Primandproper_Platform_Issuereports_V1_ArchiveReportRequest` message.
    ///   - options: Options to apply to this RPC.
    ///   - handleResponse: A closure which handles the response and returns its result to
    ///       the caller. Returning from the closure will cancel the RPC if it hasn't
    ///       already finished.
    /// - Returns: The result of `handleResponse`.
    public func archiveReport<Result>(
        request: GRPCCore.ClientRequest<Primandproper_Platform_Issuereports_V1_ArchiveReportRequest>,
        options: GRPCCore.CallOptions = .defaults,
        onResponse handleResponse: @Sendable @escaping (GRPCCore.ClientResponse<Primandproper_Platform_Issuereports_V1_ArchiveReportResponse>) async throws -> Result = { response in
            try response.message
        }
    ) async throws -> Result where Result: Sendable {
        try await self.archiveReport(
            request: request,
            serializer: GRPCProtobuf.ProtobufSerializer<Primandproper_Platform_Issuereports_V1_ArchiveReportRequest>(),
            deserializer: GRPCProtobuf.ProtobufDeserializer<Primandproper_Platform_Issuereports_V1_ArchiveReportResponse>(),
            options: options,
            onResponse: handleResponse
        )
    }
}

// Helpers providing sugared APIs for 'ClientProtocol' methods.
@available(macOS 15.0, iOS 18.0, watchOS 11.0, tvOS 18.0, visionOS 2.0, *)
extension Primandproper_Platform_Issuereports_V1_IssueReportsService.ClientProtocol {
    /// Call the "CreateReport" method.
    ///
    /// - Parameters:
    ///   - message: request message to send.
    ///   - metadata: Additional metadata to send, defaults to empty.
    ///   - options: Options to apply to this RPC, defaults to `.defaults`.
    ///   - handleResponse: A closure which handles the response and returns its result to
    ///       the caller. Returning from the closure will cancel the RPC if it hasn't
    ///       already finished.
    /// - Returns: The result of `handleResponse`.
    public func createReport<Result>(
        _ message: Primandproper_Platform_Issuereports_V1_CreateReportRequest,
        metadata: GRPCCore.Metadata = [:],
        options: GRPCCore.CallOptions = .defaults,
        onResponse handleResponse: @Sendable @escaping (GRPCCore.ClientResponse<Primandproper_Platform_Issuereports_V1_CreateReportResponse>) async throws -> Result = { response in
            try response.message
        }
    ) async throws -> Result where Result: Sendable {
        let request = GRPCCore.ClientRequest<Primandproper_Platform_Issuereports_V1_CreateReportRequest>(
            message: message,
            metadata: metadata
        )
        return try await self.createReport(
            request: request,
            options: options,
            onResponse: handleResponse
        )
    }

    /// Call the "GetReport" method.
    ///
    /// - Parameters:
    ///   - message: request message to send.
    ///   - metadata: Additional metadata to send, defaults to empty.
    ///   - options: Options to apply to this RPC, defaults to `.defaults`.
    ///   - handleResponse: A closure which handles the response and returns its result to
    ///       the caller. Returning from the closure will cancel the RPC if it hasn't
    ///       already finished.
    /// - Returns: The result of `handleResponse`.
    public func getReport<Result>(
        _ message: Primandproper_Platform_Issuereports_V1_GetReportRequest,
        metadata: GRPCCore.Metadata = [:],
        options: GRPCCore.CallOptions = .defaults,
        onResponse handleResponse: @Sendable @escaping (GRPCCore.ClientResponse<Primandproper_Platform_Issuereports_V1_GetReportResponse>) async throws -> Result = { response in
            try response.message
        }
    ) async throws -> Result where Result: Sendable {
        let request = GRPCCore.ClientRequest<Primandproper_Platform_Issuereports_V1_GetReportRequest>(
            message: message,
            metadata: metadata
        )
        return try await self.getReport(
            request: request,
            options: options,
            onResponse: handleResponse
        )
    }

    /// Call the "ListReports" method.
    ///
    /// - Parameters:
    ///   - message: request message to send.
    ///   - metadata: Additional metadata to send, defaults to empty.
    ///   - options: Options to apply to this RPC, defaults to `.defaults`.
    ///   - handleResponse: A closure which handles the response and returns its result to
    ///       the caller. Returning from the closure will cancel the RPC if it hasn't
    ///       already finished.
    /// - Returns: The result of `handleResponse`.
    public func listReports<Result>(
        _ message: Primandproper_Platform_Issuereports_V1_ListReportsRequest,
        metadata: GRPCCore.Metadata = [:],
        options: GRPCCore.CallOptions = .defaults,
        onResponse handleResponse: @Sendable @escaping (GRPCCore.ClientResponse<Primandproper_Platform_Issuereports_V1_ListReportsResponse>) async throws -> Result = { response in
            try response.message
        }
    ) async throws -> Result where Result: Sendable {
        let request = GRPCCore.ClientRequest<Primandproper_Platform_Issuereports_V1_ListReportsRequest>(
            message: message,
            metadata: metadata
        )
        return try await self.listReports(
            request: request,
            options: options,
            onResponse: handleResponse
        )
    }

    /// Call the "ListReportsByStatus" method.
    ///
    /// - Parameters:
    ///   - message: request message to send.
    ///   - metadata: Additional metadata to send, defaults to empty.
    ///   - options: Options to apply to this RPC, defaults to `.defaults`.
    ///   - handleResponse: A closure which handles the response and returns its result to
    ///       the caller. Returning from the closure will cancel the RPC if it hasn't
    ///       already finished.
    /// - Returns: The result of `handleResponse`.
    public func listReportsByStatus<Result>(
        _ message: Primandproper_Platform_Issuereports_V1_ListReportsByStatusRequest,
        metadata: GRPCCore.Metadata = [:],
        options: GRPCCore.CallOptions = .defaults,
        onResponse handleResponse: @Sendable @escaping (GRPCCore.ClientResponse<Primandproper_Platform_Issuereports_V1_ListReportsByStatusResponse>) async throws -> Result = { response in
            try response.message
        }
    ) async throws -> Result where Result: Sendable {
        let request = GRPCCore.ClientRequest<Primandproper_Platform_Issuereports_V1_ListReportsByStatusRequest>(
            message: message,
            metadata: metadata
        )
        return try await self.listReportsByStatus(
            request: request,
            options: options,
            onResponse: handleResponse
        )
    }

    /// Call the "ListReportsByReporter" method.
    ///
    /// - Parameters:
    ///   - message: request message to send.
    ///   - metadata: Additional metadata to send, defaults to empty.
    ///   - options: Options to apply to this RPC, defaults to `.defaults`.
    ///   - handleResponse: A closure which handles the response and returns its result to
    ///       the caller. Returning from the closure will cancel the RPC if it hasn't
    ///       already finished.
    /// - Returns: The result of `handleResponse`.
    public func listReportsByReporter<Result>(
        _ message: Primandproper_Platform_Issuereports_V1_ListReportsByReporterRequest,
        metadata: GRPCCore.Metadata = [:],
        options: GRPCCore.CallOptions = .defaults,
        onResponse handleResponse: @Sendable @escaping (GRPCCore.ClientResponse<Primandproper_Platform_Issuereports_V1_ListReportsByReporterResponse>) async throws -> Result = { response in
            try response.message
        }
    ) async throws -> Result where Result: Sendable {
        let request = GRPCCore.ClientRequest<Primandproper_Platform_Issuereports_V1_ListReportsByReporterRequest>(
            message: message,
            metadata: metadata
        )
        return try await self.listReportsByReporter(
            request: request,
            options: options,
            onResponse: handleResponse
        )
    }

    /// Call the "ListReportsBySubjectType" method.
    ///
    /// - Parameters:
    ///   - message: request message to send.
    ///   - metadata: Additional metadata to send, defaults to empty.
    ///   - options: Options to apply to this RPC, defaults to `.defaults`.
    ///   - handleResponse: A closure which handles the response and returns its result to
    ///       the caller. Returning from the closure will cancel the RPC if it hasn't
    ///       already finished.
    /// - Returns: The result of `handleResponse`.
    public func listReportsBySubjectType<Result>(
        _ message: Primandproper_Platform_Issuereports_V1_ListReportsBySubjectTypeRequest,
        metadata: GRPCCore.Metadata = [:],
        options: GRPCCore.CallOptions = .defaults,
        onResponse handleResponse: @Sendable @escaping (GRPCCore.ClientResponse<Primandproper_Platform_Issuereports_V1_ListReportsBySubjectTypeResponse>) async throws -> Result = { response in
            try response.message
        }
    ) async throws -> Result where Result: Sendable {
        let request = GRPCCore.ClientRequest<Primandproper_Platform_Issuereports_V1_ListReportsBySubjectTypeRequest>(
            message: message,
            metadata: metadata
        )
        return try await self.listReportsBySubjectType(
            request: request,
            options: options,
            onResponse: handleResponse
        )
    }

    /// Call the "ListReportsForSubject" method.
    ///
    /// - Parameters:
    ///   - message: request message to send.
    ///   - metadata: Additional metadata to send, defaults to empty.
    ///   - options: Options to apply to this RPC, defaults to `.defaults`.
    ///   - handleResponse: A closure which handles the response and returns its result to
    ///       the caller. Returning from the closure will cancel the RPC if it hasn't
    ///       already finished.
    /// - Returns: The result of `handleResponse`.
    public func listReportsForSubject<Result>(
        _ message: Primandproper_Platform_Issuereports_V1_ListReportsForSubjectRequest,
        metadata: GRPCCore.Metadata = [:],
        options: GRPCCore.CallOptions = .defaults,
        onResponse handleResponse: @Sendable @escaping (GRPCCore.ClientResponse<Primandproper_Platform_Issuereports_V1_ListReportsForSubjectResponse>) async throws -> Result = { response in
            try response.message
        }
    ) async throws -> Result where Result: Sendable {
        let request = GRPCCore.ClientRequest<Primandproper_Platform_Issuereports_V1_ListReportsForSubjectRequest>(
            message: message,
            metadata: metadata
        )
        return try await self.listReportsForSubject(
            request: request,
            options: options,
            onResponse: handleResponse
        )
    }

    /// Call the "ListReportsAcrossScopes" method.
    ///
    /// - Parameters:
    ///   - message: request message to send.
    ///   - metadata: Additional metadata to send, defaults to empty.
    ///   - options: Options to apply to this RPC, defaults to `.defaults`.
    ///   - handleResponse: A closure which handles the response and returns its result to
    ///       the caller. Returning from the closure will cancel the RPC if it hasn't
    ///       already finished.
    /// - Returns: The result of `handleResponse`.
    public func listReportsAcrossScopes<Result>(
        _ message: Primandproper_Platform_Issuereports_V1_ListReportsAcrossScopesRequest,
        metadata: GRPCCore.Metadata = [:],
        options: GRPCCore.CallOptions = .defaults,
        onResponse handleResponse: @Sendable @escaping (GRPCCore.ClientResponse<Primandproper_Platform_Issuereports_V1_ListReportsAcrossScopesResponse>) async throws -> Result = { response in
            try response.message
        }
    ) async throws -> Result where Result: Sendable {
        let request = GRPCCore.ClientRequest<Primandproper_Platform_Issuereports_V1_ListReportsAcrossScopesRequest>(
            message: message,
            metadata: metadata
        )
        return try await self.listReportsAcrossScopes(
            request: request,
            options: options,
            onResponse: handleResponse
        )
    }

    /// Call the "ListReportsByStatusAcrossScopes" method.
    ///
    /// - Parameters:
    ///   - message: request message to send.
    ///   - metadata: Additional metadata to send, defaults to empty.
    ///   - options: Options to apply to this RPC, defaults to `.defaults`.
    ///   - handleResponse: A closure which handles the response and returns its result to
    ///       the caller. Returning from the closure will cancel the RPC if it hasn't
    ///       already finished.
    /// - Returns: The result of `handleResponse`.
    public func listReportsByStatusAcrossScopes<Result>(
        _ message: Primandproper_Platform_Issuereports_V1_ListReportsByStatusAcrossScopesRequest,
        metadata: GRPCCore.Metadata = [:],
        options: GRPCCore.CallOptions = .defaults,
        onResponse handleResponse: @Sendable @escaping (GRPCCore.ClientResponse<Primandproper_Platform_Issuereports_V1_ListReportsByStatusAcrossScopesResponse>) async throws -> Result = { response in
            try response.message
        }
    ) async throws -> Result where Result: Sendable {
        let request = GRPCCore.ClientRequest<Primandproper_Platform_Issuereports_V1_ListReportsByStatusAcrossScopesRequest>(
            message: message,
            metadata: metadata
        )
        return try await self.listReportsByStatusAcrossScopes(
            request: request,
            options: options,
            onResponse: handleResponse
        )
    }

    /// Call the "UpdateReport" method.
    ///
    /// - Parameters:
    ///   - message: request message to send.
    ///   - metadata: Additional metadata to send, defaults to empty.
    ///   - options: Options to apply to this RPC, defaults to `.defaults`.
    ///   - handleResponse: A closure which handles the response and returns its result to
    ///       the caller. Returning from the closure will cancel the RPC if it hasn't
    ///       already finished.
    /// - Returns: The result of `handleResponse`.
    public func updateReport<Result>(
        _ message: Primandproper_Platform_Issuereports_V1_UpdateReportRequest,
        metadata: GRPCCore.Metadata = [:],
        options: GRPCCore.CallOptions = .defaults,
        onResponse handleResponse: @Sendable @escaping (GRPCCore.ClientResponse<Primandproper_Platform_Issuereports_V1_UpdateReportResponse>) async throws -> Result = { response in
            try response.message
        }
    ) async throws -> Result where Result: Sendable {
        let request = GRPCCore.ClientRequest<Primandproper_Platform_Issuereports_V1_UpdateReportRequest>(
            message: message,
            metadata: metadata
        )
        return try await self.updateReport(
            request: request,
            options: options,
            onResponse: handleResponse
        )
    }

    /// Call the "TransitionReport" method.
    ///
    /// - Parameters:
    ///   - message: request message to send.
    ///   - metadata: Additional metadata to send, defaults to empty.
    ///   - options: Options to apply to this RPC, defaults to `.defaults`.
    ///   - handleResponse: A closure which handles the response and returns its result to
    ///       the caller. Returning from the closure will cancel the RPC if it hasn't
    ///       already finished.
    /// - Returns: The result of `handleResponse`.
    public func transitionReport<Result>(
        _ message: Primandproper_Platform_Issuereports_V1_TransitionReportRequest,
        metadata: GRPCCore.Metadata = [:],
        options: GRPCCore.CallOptions = .defaults,
        onResponse handleResponse: @Sendable @escaping (GRPCCore.ClientResponse<Primandproper_Platform_Issuereports_V1_TransitionReportResponse>) async throws -> Result = { response in
            try response.message
        }
    ) async throws -> Result where Result: Sendable {
        let request = GRPCCore.ClientRequest<Primandproper_Platform_Issuereports_V1_TransitionReportRequest>(
            message: message,
            metadata: metadata
        )
        return try await self.transitionReport(
            request: request,
            options: options,
            onResponse: handleResponse
        )
    }

    /// Call the "ArchiveReport" method.
    ///
    /// - Parameters:
    ///   - message: request message to send.
    ///   - metadata: Additional metadata to send, defaults to empty.
    ///   - options: Options to apply to this RPC, defaults to `.defaults`.
    ///   - handleResponse: A closure which handles the response and returns its result to
    ///       the caller. Returning from the closure will cancel the RPC if it hasn't
    ///       already finished.
    /// - Returns: The result of `handleResponse`.
    public func archiveReport<Result>(
        _ message: Primandproper_Platform_Issuereports_V1_ArchiveReportRequest,
        metadata: GRPCCore.Metadata = [:],
        options: GRPCCore.CallOptions = .defaults,
        onResponse handleResponse: @Sendable @escaping (GRPCCore.ClientResponse<Primandproper_Platform_Issuereports_V1_ArchiveReportResponse>) async throws -> Result = { response in
            try response.message
        }
    ) async throws -> Result where Result: Sendable {
        let request = GRPCCore.ClientRequest<Primandproper_Platform_Issuereports_V1_ArchiveReportRequest>(
            message: message,
            metadata: metadata
        )
        return try await self.archiveReport(
            request: request,
            options: options,
            onResponse: handleResponse
        )
    }
}