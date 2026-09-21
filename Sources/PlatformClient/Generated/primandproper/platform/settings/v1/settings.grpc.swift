// Package primandproper.platform.settings.v1 is the wire schema for runtime
// settings: the catalog an operator administers, the answers a person gives
// about themselves, and what a setting resolves to for somebody who has not
// answered it.
//
// Resolution is the point of it. A stored value falling back to the
// definition's default, and a third answer for a setting nobody has decided, is
// what a hand-written settings service gets subtly wrong -- a screen showing
// blanks where it should show defaults -- so [ResolvedSetting] is the message
// the rest of this file exists to make readable.
//
// This file is shipped inside the published Go module, and it is the file
// itself that is shipped -- not a copy for you to keep in sync. A consumer puts
// the module's proto directories on protoc's path and imports this file by its
// canonical name, exactly as identity.proto and filtering.proto already work:
//
//	PLATFORM_PROTO := $(shell go list -m -f '{{.Dir}}' github.com/primandproper/platform-go/v14)
//
//	protoc --proto_path proto/ \
//	    --proto_path $(PLATFORM_PROTO)/settings/proto \
//	    --proto_path $(PLATFORM_PROTO)/filtering/proto \
//	    --go_opt=Mprimandproper/platform/settings/v1/settings.proto=github.com/primandproper/platform-go/v14/settings/settingspb \
//	    $(CONSUMER_PROTO_FILES)   # the platform files deliberately absent from that list
//
// Field numbers are the compatibility promise, across every language a consumer
// generates into. Numbers are never reused and never repurposed: a field that
// goes away is reserved.
//
// # A value is typed where this package parses one, and a string where it compares bytes
//
// The one design decision in this file. settings.Kind is a closed set of four
// -- string, boolean, integer, float -- and every value is stored as text, so
// there are two honest ways to put one on a wire: a string plus the kind, which
// makes every client re-derive the parse this package exists to have made once,
// or a value that carries its own type. This schema does the second, in
// [TypedValue], and applies it in exactly two places.
//
// Typed: [ResolvedSetting.typed_value], which is what Resolve and ResolveAll
// answer with, and [SetValueRequest.value], which is what a person's choice
// arrives as. Both are the parse. A client rendering a checkbox reads
// bool_value rather than comparing a string against "true", and a client saving
// one sends bool_value rather than formatting one -- and a bool_value sent for
// an integer setting is refused with settings.ErrKindMismatch at the boundary
// rather than stored as a row nothing can read back.
//
// A string: [SettingValue.raw], which is the row as stored and which GetValue
// is documented to hand back unparsed; and [SettingDefinition.default_value]
// and [SettingDefinition.enumeration], which are what every write is checked
// against, byte for byte. That last one is the reason for the split rather than
// a taste for consistency. A definition read as typed values and written back
// unchanged would round-trip through a parse and a format -- "1.50" arriving
// back as "1.5" -- and the enumeration is compared to stored values by string
// equality, so an edit that changed nothing could refuse itself with
// settings.ErrStrandedValues. A default is held to its own enumeration by the
// same comparison.
//
// # Presence, and why the value is a oneof rather than a string
//
// "Absence is distinguishable from zero" is this package's doctrine and not a
// preference: a text setting defaulting to "" answers every subject who has not
// chosen, and one with no default answers none of them. A proto3 string cannot
// hold that difference. A oneof can -- a string_value of "" sets the case and
// is a value somebody chose, where naming no case at all is a request that
// named no value -- and default_value is `optional` for the same reason, which
// is the presence the Go *string carries.
//
// The third state has a field rather than an error. A setting the subject has
// not answered and that has no default resolves to
// [ValueSource.VALUE_SOURCE_UNSET] with no typed_value, because it is an answer
// -- "nobody has decided" -- and the caller's own policy applies.
// settings.ErrSettingUnset is what the Go accessors report for the same state
// and is mapped for a consumer's own handlers, but no RPC here raises it.
//
// # What is a generated enum here, and what is not
//
// [SettingKind] and [ValueSource] are enums because they are closed sets this
// package defines: a kind decides how a stored string is parsed, so a kind this
// module does not implement is a value nothing can read back. That is the
// opposite case from issuereports.Kind and comments.TargetType, which are the
// consumer's catalog and stay opaque strings.
//
// The two vocabularies that are the consumer's stay strings here too. A
// definition's name is one -- "notifications.digest" is the application's word,
// and a generated enum would put it on this module's release cadence -- and so
// is [SettingSubject.type], which settings.SubjectType documents as a bare
// string precisely so that an application whose settings hang off a device, a
// workspace or an API client can say so.
//
// # What is not here, and why
//
// No scope field, anywhere, and the name is reserved so there cannot be one. A
// scope a client could name is a cross-tenant read hiding behind a request
// field -- here, a read or a write of another tenant's catalog. It comes off
// the principal the consumer's interceptor put on the context, and every
// statement behind these RPCs binds it. Reserving the name rather than only
// saying so is audit.proto's pattern: `reserved "scope";` is a schema protoc
// refuses to accept a scope field into, in this repository and in a consumer's
// fork of the file alike, whereas a comment is a request to the next author. It
// is reserved on every request message and on the four messages a response is
// built from. See identity.proto, which says the underlying rule at greater
// length.
//
// No erasure. settings.Store.DeleteValuesForSubject destroys everything one
// subject answered, cleared answers included, and it is the one hard delete in
// that package -- called by a dataprivacy.Eraser from inside the transaction
// that removes the rest of the person. An RPC moves that write out of the
// transaction that was the entire point of it, which leaves a subject erased
// from one table and present in the others. The service comment below says so
// again where a reader counting RPCs will be standing.
//
// No subject in a response's own right. Every value message carries the
// [SettingSubject] it is about, because a page of one definition's values is a
// page across subjects, but nothing here lets a caller ask for a subject
// without the surface asking whether they may -- see settings/grpc's
// SubjectAuthorizer, which is the half of authorization a per-method grant
// cannot reach.
//
// # include_archived is a request and not an instruction
//
// Every paged read here carries a QueryFilter, and its include_archived says
// "give me the archived rows too". It is a field on a message a client fills in,
// so it is a request the server rules on rather than a switch it obeys, and this
// service retires two nouns under two grants: [ListDefinitionsRequest] honors
// it for a caller holding settings.definitions.archive, and the two value reads
// for one holding settings.values.write -- which is the grant that clears a
// value, so whoever may take an answer back may see the answers that were taken
// back. For everybody else the field is cleared before the read.
//
// It is cleared and not refused. A read that failed because the caller asked for
// too much turns a console's checkbox into an error, and a client cannot tell
// that refusal from a malformed filter; the page a caller gets is the page they
// would have got had they never set the field.
//
// On [ListValuesForSubjectRequest] this is asked in addition to the
// SubjectAuthorizer question above and not instead of it: the authorizer says
// whose page this is, and this says whether the cleared rows are on it.
//
// The same rule, under each surface's own archive grant, is in comments.proto,
// issuereports.proto and waitlists.proto.

// DO NOT EDIT.
// swift-format-ignore-file
// swiftlint:disable all
//
// Generated by the gRPC Swift generator plugin for the protocol buffer compiler.
// Source: primandproper/platform/settings/v1/settings.proto
//
// For information on using the generated types, please see the documentation:
//   https://github.com/grpc/grpc-swift

import GRPCCore
import GRPCProtobuf

// MARK: - primandproper.platform.settings.v1.SettingsService

/// Namespace containing generated types for the "primandproper.platform.settings.v1.SettingsService" service.
@available(macOS 15.0, iOS 18.0, watchOS 11.0, tvOS 18.0, visionOS 2.0, *)
internal enum Primandproper_Platform_Settings_V1_SettingsService: Sendable {
    /// Service descriptor for the "primandproper.platform.settings.v1.SettingsService" service.
    internal static let descriptor = GRPCCore.ServiceDescriptor(fullyQualifiedService: "primandproper.platform.settings.v1.SettingsService")
    /// Namespace for method metadata.
    internal enum Method: Sendable {
        /// Namespace for "CreateDefinition" metadata.
        internal enum CreateDefinition: Sendable {
            /// Request type for "CreateDefinition".
            internal typealias Input = Primandproper_Platform_Settings_V1_CreateDefinitionRequest
            /// Response type for "CreateDefinition".
            internal typealias Output = Primandproper_Platform_Settings_V1_CreateDefinitionResponse
            /// Descriptor for "CreateDefinition".
            internal static let descriptor = GRPCCore.MethodDescriptor(
                service: GRPCCore.ServiceDescriptor(fullyQualifiedService: "primandproper.platform.settings.v1.SettingsService"),
                method: "CreateDefinition",
                type: .unary
            )
        }
        /// Namespace for "GetDefinition" metadata.
        internal enum GetDefinition: Sendable {
            /// Request type for "GetDefinition".
            internal typealias Input = Primandproper_Platform_Settings_V1_GetDefinitionRequest
            /// Response type for "GetDefinition".
            internal typealias Output = Primandproper_Platform_Settings_V1_GetDefinitionResponse
            /// Descriptor for "GetDefinition".
            internal static let descriptor = GRPCCore.MethodDescriptor(
                service: GRPCCore.ServiceDescriptor(fullyQualifiedService: "primandproper.platform.settings.v1.SettingsService"),
                method: "GetDefinition",
                type: .unary
            )
        }
        /// Namespace for "GetDefinitionByName" metadata.
        internal enum GetDefinitionByName: Sendable {
            /// Request type for "GetDefinitionByName".
            internal typealias Input = Primandproper_Platform_Settings_V1_GetDefinitionByNameRequest
            /// Response type for "GetDefinitionByName".
            internal typealias Output = Primandproper_Platform_Settings_V1_GetDefinitionByNameResponse
            /// Descriptor for "GetDefinitionByName".
            internal static let descriptor = GRPCCore.MethodDescriptor(
                service: GRPCCore.ServiceDescriptor(fullyQualifiedService: "primandproper.platform.settings.v1.SettingsService"),
                method: "GetDefinitionByName",
                type: .unary
            )
        }
        /// Namespace for "ListDefinitions" metadata.
        internal enum ListDefinitions: Sendable {
            /// Request type for "ListDefinitions".
            internal typealias Input = Primandproper_Platform_Settings_V1_ListDefinitionsRequest
            /// Response type for "ListDefinitions".
            internal typealias Output = Primandproper_Platform_Settings_V1_ListDefinitionsResponse
            /// Descriptor for "ListDefinitions".
            internal static let descriptor = GRPCCore.MethodDescriptor(
                service: GRPCCore.ServiceDescriptor(fullyQualifiedService: "primandproper.platform.settings.v1.SettingsService"),
                method: "ListDefinitions",
                type: .unary
            )
        }
        /// Namespace for "UpdateDefinition" metadata.
        internal enum UpdateDefinition: Sendable {
            /// Request type for "UpdateDefinition".
            internal typealias Input = Primandproper_Platform_Settings_V1_UpdateDefinitionRequest
            /// Response type for "UpdateDefinition".
            internal typealias Output = Primandproper_Platform_Settings_V1_UpdateDefinitionResponse
            /// Descriptor for "UpdateDefinition".
            internal static let descriptor = GRPCCore.MethodDescriptor(
                service: GRPCCore.ServiceDescriptor(fullyQualifiedService: "primandproper.platform.settings.v1.SettingsService"),
                method: "UpdateDefinition",
                type: .unary
            )
        }
        /// Namespace for "ArchiveDefinition" metadata.
        internal enum ArchiveDefinition: Sendable {
            /// Request type for "ArchiveDefinition".
            internal typealias Input = Primandproper_Platform_Settings_V1_ArchiveDefinitionRequest
            /// Response type for "ArchiveDefinition".
            internal typealias Output = Primandproper_Platform_Settings_V1_ArchiveDefinitionResponse
            /// Descriptor for "ArchiveDefinition".
            internal static let descriptor = GRPCCore.MethodDescriptor(
                service: GRPCCore.ServiceDescriptor(fullyQualifiedService: "primandproper.platform.settings.v1.SettingsService"),
                method: "ArchiveDefinition",
                type: .unary
            )
        }
        /// Namespace for "ListValuesForDefinition" metadata.
        internal enum ListValuesForDefinition: Sendable {
            /// Request type for "ListValuesForDefinition".
            internal typealias Input = Primandproper_Platform_Settings_V1_ListValuesForDefinitionRequest
            /// Response type for "ListValuesForDefinition".
            internal typealias Output = Primandproper_Platform_Settings_V1_ListValuesForDefinitionResponse
            /// Descriptor for "ListValuesForDefinition".
            internal static let descriptor = GRPCCore.MethodDescriptor(
                service: GRPCCore.ServiceDescriptor(fullyQualifiedService: "primandproper.platform.settings.v1.SettingsService"),
                method: "ListValuesForDefinition",
                type: .unary
            )
        }
        /// Namespace for "SetValue" metadata.
        internal enum SetValue: Sendable {
            /// Request type for "SetValue".
            internal typealias Input = Primandproper_Platform_Settings_V1_SetValueRequest
            /// Response type for "SetValue".
            internal typealias Output = Primandproper_Platform_Settings_V1_SetValueResponse
            /// Descriptor for "SetValue".
            internal static let descriptor = GRPCCore.MethodDescriptor(
                service: GRPCCore.ServiceDescriptor(fullyQualifiedService: "primandproper.platform.settings.v1.SettingsService"),
                method: "SetValue",
                type: .unary
            )
        }
        /// Namespace for "GetValue" metadata.
        internal enum GetValue: Sendable {
            /// Request type for "GetValue".
            internal typealias Input = Primandproper_Platform_Settings_V1_GetValueRequest
            /// Response type for "GetValue".
            internal typealias Output = Primandproper_Platform_Settings_V1_GetValueResponse
            /// Descriptor for "GetValue".
            internal static let descriptor = GRPCCore.MethodDescriptor(
                service: GRPCCore.ServiceDescriptor(fullyQualifiedService: "primandproper.platform.settings.v1.SettingsService"),
                method: "GetValue",
                type: .unary
            )
        }
        /// Namespace for "ClearValue" metadata.
        internal enum ClearValue: Sendable {
            /// Request type for "ClearValue".
            internal typealias Input = Primandproper_Platform_Settings_V1_ClearValueRequest
            /// Response type for "ClearValue".
            internal typealias Output = Primandproper_Platform_Settings_V1_ClearValueResponse
            /// Descriptor for "ClearValue".
            internal static let descriptor = GRPCCore.MethodDescriptor(
                service: GRPCCore.ServiceDescriptor(fullyQualifiedService: "primandproper.platform.settings.v1.SettingsService"),
                method: "ClearValue",
                type: .unary
            )
        }
        /// Namespace for "ListValuesForSubject" metadata.
        internal enum ListValuesForSubject: Sendable {
            /// Request type for "ListValuesForSubject".
            internal typealias Input = Primandproper_Platform_Settings_V1_ListValuesForSubjectRequest
            /// Response type for "ListValuesForSubject".
            internal typealias Output = Primandproper_Platform_Settings_V1_ListValuesForSubjectResponse
            /// Descriptor for "ListValuesForSubject".
            internal static let descriptor = GRPCCore.MethodDescriptor(
                service: GRPCCore.ServiceDescriptor(fullyQualifiedService: "primandproper.platform.settings.v1.SettingsService"),
                method: "ListValuesForSubject",
                type: .unary
            )
        }
        /// Namespace for "Resolve" metadata.
        internal enum Resolve: Sendable {
            /// Request type for "Resolve".
            internal typealias Input = Primandproper_Platform_Settings_V1_ResolveRequest
            /// Response type for "Resolve".
            internal typealias Output = Primandproper_Platform_Settings_V1_ResolveResponse
            /// Descriptor for "Resolve".
            internal static let descriptor = GRPCCore.MethodDescriptor(
                service: GRPCCore.ServiceDescriptor(fullyQualifiedService: "primandproper.platform.settings.v1.SettingsService"),
                method: "Resolve",
                type: .unary
            )
        }
        /// Namespace for "ResolveAll" metadata.
        internal enum ResolveAll: Sendable {
            /// Request type for "ResolveAll".
            internal typealias Input = Primandproper_Platform_Settings_V1_ResolveAllRequest
            /// Response type for "ResolveAll".
            internal typealias Output = Primandproper_Platform_Settings_V1_ResolveAllResponse
            /// Descriptor for "ResolveAll".
            internal static let descriptor = GRPCCore.MethodDescriptor(
                service: GRPCCore.ServiceDescriptor(fullyQualifiedService: "primandproper.platform.settings.v1.SettingsService"),
                method: "ResolveAll",
                type: .unary
            )
        }
        /// Descriptors for all methods in the "primandproper.platform.settings.v1.SettingsService" service.
        internal static let descriptors: [GRPCCore.MethodDescriptor] = [
            CreateDefinition.descriptor,
            GetDefinition.descriptor,
            GetDefinitionByName.descriptor,
            ListDefinitions.descriptor,
            UpdateDefinition.descriptor,
            ArchiveDefinition.descriptor,
            ListValuesForDefinition.descriptor,
            SetValue.descriptor,
            GetValue.descriptor,
            ClearValue.descriptor,
            ListValuesForSubject.descriptor,
            Resolve.descriptor,
            ResolveAll.descriptor
        ]
    }
}

@available(macOS 15.0, iOS 18.0, watchOS 11.0, tvOS 18.0, visionOS 2.0, *)
extension GRPCCore.ServiceDescriptor {
    /// Service descriptor for the "primandproper.platform.settings.v1.SettingsService" service.
    internal static let primandproper_platform_settings_v1_SettingsService = GRPCCore.ServiceDescriptor(fullyQualifiedService: "primandproper.platform.settings.v1.SettingsService")
}

// MARK: primandproper.platform.settings.v1.SettingsService (client)

@available(macOS 15.0, iOS 18.0, watchOS 11.0, tvOS 18.0, visionOS 2.0, *)
extension Primandproper_Platform_Settings_V1_SettingsService {
    /// Generated client protocol for the "primandproper.platform.settings.v1.SettingsService" service.
    ///
    /// You don't need to implement this protocol directly, use the generated
    /// implementation, ``Client``.
    ///
    /// > Source IDL Documentation:
    /// >
    /// > SettingsService is the catalog and the answers stored against it.
    /// > 
    /// > Thirteen RPCs over the fourteen methods of settings.Store, and the split in
    /// > them is two audiences rather than two nouns. The seven definition methods are
    /// > an operator's: what settings exist, what each holds, and who has overridden
    /// > one. The six value methods are a person acting on themselves, and they are
    /// > the settings screen every consumer ships.
    /// > 
    /// > The fourteenth is DeleteValuesForSubject and it is deliberately absent. It
    /// > destroys everything one subject answered, cleared answers included, and it is
    /// > erasure machinery -- a dataprivacy.Eraser or a retention sweep calling on a
    /// > subject's behalf from inside the transaction that removes the rest of them.
    /// > A write whose whole property is that it commits with its caller's other
    /// > writes is not an RPC: over a wire it lands in a transaction of its own, at a
    /// > moment the caller does not choose, and what you get is a person erased from
    /// > one table and present in the others. settings.Store documents the same
    /// > absence on the method itself.
    /// > 
    /// > Every method takes its scope off the caller's principal, and six of them take
    /// > a subject from the request -- which a grant on the method cannot check, so
    /// > settings/grpc asks a SubjectAuthorizer before any of the six reads or writes
    /// > a row.
    internal protocol ClientProtocol: Sendable {
        /// Call the "CreateDefinition" method.
        ///
        /// - Parameters:
        ///   - request: A request containing a single `Primandproper_Platform_Settings_V1_CreateDefinitionRequest` message.
        ///   - serializer: A serializer for `Primandproper_Platform_Settings_V1_CreateDefinitionRequest` messages.
        ///   - deserializer: A deserializer for `Primandproper_Platform_Settings_V1_CreateDefinitionResponse` messages.
        ///   - options: Options to apply to this RPC.
        ///   - handleResponse: A closure which handles the response and returns its result to
        ///       the caller. Returning from the closure will cancel the RPC if it hasn't
        ///       already finished.
        /// - Returns: The result of `handleResponse`.
        func createDefinition<Result>(
            request: GRPCCore.ClientRequest<Primandproper_Platform_Settings_V1_CreateDefinitionRequest>,
            serializer: some GRPCCore.MessageSerializer<Primandproper_Platform_Settings_V1_CreateDefinitionRequest>,
            deserializer: some GRPCCore.MessageDeserializer<Primandproper_Platform_Settings_V1_CreateDefinitionResponse>,
            options: GRPCCore.CallOptions,
            onResponse handleResponse: @Sendable @escaping (GRPCCore.ClientResponse<Primandproper_Platform_Settings_V1_CreateDefinitionResponse>) async throws -> Result
        ) async throws -> Result where Result: Sendable

        /// Call the "GetDefinition" method.
        ///
        /// - Parameters:
        ///   - request: A request containing a single `Primandproper_Platform_Settings_V1_GetDefinitionRequest` message.
        ///   - serializer: A serializer for `Primandproper_Platform_Settings_V1_GetDefinitionRequest` messages.
        ///   - deserializer: A deserializer for `Primandproper_Platform_Settings_V1_GetDefinitionResponse` messages.
        ///   - options: Options to apply to this RPC.
        ///   - handleResponse: A closure which handles the response and returns its result to
        ///       the caller. Returning from the closure will cancel the RPC if it hasn't
        ///       already finished.
        /// - Returns: The result of `handleResponse`.
        func getDefinition<Result>(
            request: GRPCCore.ClientRequest<Primandproper_Platform_Settings_V1_GetDefinitionRequest>,
            serializer: some GRPCCore.MessageSerializer<Primandproper_Platform_Settings_V1_GetDefinitionRequest>,
            deserializer: some GRPCCore.MessageDeserializer<Primandproper_Platform_Settings_V1_GetDefinitionResponse>,
            options: GRPCCore.CallOptions,
            onResponse handleResponse: @Sendable @escaping (GRPCCore.ClientResponse<Primandproper_Platform_Settings_V1_GetDefinitionResponse>) async throws -> Result
        ) async throws -> Result where Result: Sendable

        /// Call the "GetDefinitionByName" method.
        ///
        /// - Parameters:
        ///   - request: A request containing a single `Primandproper_Platform_Settings_V1_GetDefinitionByNameRequest` message.
        ///   - serializer: A serializer for `Primandproper_Platform_Settings_V1_GetDefinitionByNameRequest` messages.
        ///   - deserializer: A deserializer for `Primandproper_Platform_Settings_V1_GetDefinitionByNameResponse` messages.
        ///   - options: Options to apply to this RPC.
        ///   - handleResponse: A closure which handles the response and returns its result to
        ///       the caller. Returning from the closure will cancel the RPC if it hasn't
        ///       already finished.
        /// - Returns: The result of `handleResponse`.
        func getDefinitionByName<Result>(
            request: GRPCCore.ClientRequest<Primandproper_Platform_Settings_V1_GetDefinitionByNameRequest>,
            serializer: some GRPCCore.MessageSerializer<Primandproper_Platform_Settings_V1_GetDefinitionByNameRequest>,
            deserializer: some GRPCCore.MessageDeserializer<Primandproper_Platform_Settings_V1_GetDefinitionByNameResponse>,
            options: GRPCCore.CallOptions,
            onResponse handleResponse: @Sendable @escaping (GRPCCore.ClientResponse<Primandproper_Platform_Settings_V1_GetDefinitionByNameResponse>) async throws -> Result
        ) async throws -> Result where Result: Sendable

        /// Call the "ListDefinitions" method.
        ///
        /// - Parameters:
        ///   - request: A request containing a single `Primandproper_Platform_Settings_V1_ListDefinitionsRequest` message.
        ///   - serializer: A serializer for `Primandproper_Platform_Settings_V1_ListDefinitionsRequest` messages.
        ///   - deserializer: A deserializer for `Primandproper_Platform_Settings_V1_ListDefinitionsResponse` messages.
        ///   - options: Options to apply to this RPC.
        ///   - handleResponse: A closure which handles the response and returns its result to
        ///       the caller. Returning from the closure will cancel the RPC if it hasn't
        ///       already finished.
        /// - Returns: The result of `handleResponse`.
        func listDefinitions<Result>(
            request: GRPCCore.ClientRequest<Primandproper_Platform_Settings_V1_ListDefinitionsRequest>,
            serializer: some GRPCCore.MessageSerializer<Primandproper_Platform_Settings_V1_ListDefinitionsRequest>,
            deserializer: some GRPCCore.MessageDeserializer<Primandproper_Platform_Settings_V1_ListDefinitionsResponse>,
            options: GRPCCore.CallOptions,
            onResponse handleResponse: @Sendable @escaping (GRPCCore.ClientResponse<Primandproper_Platform_Settings_V1_ListDefinitionsResponse>) async throws -> Result
        ) async throws -> Result where Result: Sendable

        /// Call the "UpdateDefinition" method.
        ///
        /// - Parameters:
        ///   - request: A request containing a single `Primandproper_Platform_Settings_V1_UpdateDefinitionRequest` message.
        ///   - serializer: A serializer for `Primandproper_Platform_Settings_V1_UpdateDefinitionRequest` messages.
        ///   - deserializer: A deserializer for `Primandproper_Platform_Settings_V1_UpdateDefinitionResponse` messages.
        ///   - options: Options to apply to this RPC.
        ///   - handleResponse: A closure which handles the response and returns its result to
        ///       the caller. Returning from the closure will cancel the RPC if it hasn't
        ///       already finished.
        /// - Returns: The result of `handleResponse`.
        func updateDefinition<Result>(
            request: GRPCCore.ClientRequest<Primandproper_Platform_Settings_V1_UpdateDefinitionRequest>,
            serializer: some GRPCCore.MessageSerializer<Primandproper_Platform_Settings_V1_UpdateDefinitionRequest>,
            deserializer: some GRPCCore.MessageDeserializer<Primandproper_Platform_Settings_V1_UpdateDefinitionResponse>,
            options: GRPCCore.CallOptions,
            onResponse handleResponse: @Sendable @escaping (GRPCCore.ClientResponse<Primandproper_Platform_Settings_V1_UpdateDefinitionResponse>) async throws -> Result
        ) async throws -> Result where Result: Sendable

        /// Call the "ArchiveDefinition" method.
        ///
        /// - Parameters:
        ///   - request: A request containing a single `Primandproper_Platform_Settings_V1_ArchiveDefinitionRequest` message.
        ///   - serializer: A serializer for `Primandproper_Platform_Settings_V1_ArchiveDefinitionRequest` messages.
        ///   - deserializer: A deserializer for `Primandproper_Platform_Settings_V1_ArchiveDefinitionResponse` messages.
        ///   - options: Options to apply to this RPC.
        ///   - handleResponse: A closure which handles the response and returns its result to
        ///       the caller. Returning from the closure will cancel the RPC if it hasn't
        ///       already finished.
        /// - Returns: The result of `handleResponse`.
        func archiveDefinition<Result>(
            request: GRPCCore.ClientRequest<Primandproper_Platform_Settings_V1_ArchiveDefinitionRequest>,
            serializer: some GRPCCore.MessageSerializer<Primandproper_Platform_Settings_V1_ArchiveDefinitionRequest>,
            deserializer: some GRPCCore.MessageDeserializer<Primandproper_Platform_Settings_V1_ArchiveDefinitionResponse>,
            options: GRPCCore.CallOptions,
            onResponse handleResponse: @Sendable @escaping (GRPCCore.ClientResponse<Primandproper_Platform_Settings_V1_ArchiveDefinitionResponse>) async throws -> Result
        ) async throws -> Result where Result: Sendable

        /// Call the "ListValuesForDefinition" method.
        ///
        /// - Parameters:
        ///   - request: A request containing a single `Primandproper_Platform_Settings_V1_ListValuesForDefinitionRequest` message.
        ///   - serializer: A serializer for `Primandproper_Platform_Settings_V1_ListValuesForDefinitionRequest` messages.
        ///   - deserializer: A deserializer for `Primandproper_Platform_Settings_V1_ListValuesForDefinitionResponse` messages.
        ///   - options: Options to apply to this RPC.
        ///   - handleResponse: A closure which handles the response and returns its result to
        ///       the caller. Returning from the closure will cancel the RPC if it hasn't
        ///       already finished.
        /// - Returns: The result of `handleResponse`.
        func listValuesForDefinition<Result>(
            request: GRPCCore.ClientRequest<Primandproper_Platform_Settings_V1_ListValuesForDefinitionRequest>,
            serializer: some GRPCCore.MessageSerializer<Primandproper_Platform_Settings_V1_ListValuesForDefinitionRequest>,
            deserializer: some GRPCCore.MessageDeserializer<Primandproper_Platform_Settings_V1_ListValuesForDefinitionResponse>,
            options: GRPCCore.CallOptions,
            onResponse handleResponse: @Sendable @escaping (GRPCCore.ClientResponse<Primandproper_Platform_Settings_V1_ListValuesForDefinitionResponse>) async throws -> Result
        ) async throws -> Result where Result: Sendable

        /// Call the "SetValue" method.
        ///
        /// - Parameters:
        ///   - request: A request containing a single `Primandproper_Platform_Settings_V1_SetValueRequest` message.
        ///   - serializer: A serializer for `Primandproper_Platform_Settings_V1_SetValueRequest` messages.
        ///   - deserializer: A deserializer for `Primandproper_Platform_Settings_V1_SetValueResponse` messages.
        ///   - options: Options to apply to this RPC.
        ///   - handleResponse: A closure which handles the response and returns its result to
        ///       the caller. Returning from the closure will cancel the RPC if it hasn't
        ///       already finished.
        /// - Returns: The result of `handleResponse`.
        func setValue<Result>(
            request: GRPCCore.ClientRequest<Primandproper_Platform_Settings_V1_SetValueRequest>,
            serializer: some GRPCCore.MessageSerializer<Primandproper_Platform_Settings_V1_SetValueRequest>,
            deserializer: some GRPCCore.MessageDeserializer<Primandproper_Platform_Settings_V1_SetValueResponse>,
            options: GRPCCore.CallOptions,
            onResponse handleResponse: @Sendable @escaping (GRPCCore.ClientResponse<Primandproper_Platform_Settings_V1_SetValueResponse>) async throws -> Result
        ) async throws -> Result where Result: Sendable

        /// Call the "GetValue" method.
        ///
        /// - Parameters:
        ///   - request: A request containing a single `Primandproper_Platform_Settings_V1_GetValueRequest` message.
        ///   - serializer: A serializer for `Primandproper_Platform_Settings_V1_GetValueRequest` messages.
        ///   - deserializer: A deserializer for `Primandproper_Platform_Settings_V1_GetValueResponse` messages.
        ///   - options: Options to apply to this RPC.
        ///   - handleResponse: A closure which handles the response and returns its result to
        ///       the caller. Returning from the closure will cancel the RPC if it hasn't
        ///       already finished.
        /// - Returns: The result of `handleResponse`.
        func getValue<Result>(
            request: GRPCCore.ClientRequest<Primandproper_Platform_Settings_V1_GetValueRequest>,
            serializer: some GRPCCore.MessageSerializer<Primandproper_Platform_Settings_V1_GetValueRequest>,
            deserializer: some GRPCCore.MessageDeserializer<Primandproper_Platform_Settings_V1_GetValueResponse>,
            options: GRPCCore.CallOptions,
            onResponse handleResponse: @Sendable @escaping (GRPCCore.ClientResponse<Primandproper_Platform_Settings_V1_GetValueResponse>) async throws -> Result
        ) async throws -> Result where Result: Sendable

        /// Call the "ClearValue" method.
        ///
        /// - Parameters:
        ///   - request: A request containing a single `Primandproper_Platform_Settings_V1_ClearValueRequest` message.
        ///   - serializer: A serializer for `Primandproper_Platform_Settings_V1_ClearValueRequest` messages.
        ///   - deserializer: A deserializer for `Primandproper_Platform_Settings_V1_ClearValueResponse` messages.
        ///   - options: Options to apply to this RPC.
        ///   - handleResponse: A closure which handles the response and returns its result to
        ///       the caller. Returning from the closure will cancel the RPC if it hasn't
        ///       already finished.
        /// - Returns: The result of `handleResponse`.
        func clearValue<Result>(
            request: GRPCCore.ClientRequest<Primandproper_Platform_Settings_V1_ClearValueRequest>,
            serializer: some GRPCCore.MessageSerializer<Primandproper_Platform_Settings_V1_ClearValueRequest>,
            deserializer: some GRPCCore.MessageDeserializer<Primandproper_Platform_Settings_V1_ClearValueResponse>,
            options: GRPCCore.CallOptions,
            onResponse handleResponse: @Sendable @escaping (GRPCCore.ClientResponse<Primandproper_Platform_Settings_V1_ClearValueResponse>) async throws -> Result
        ) async throws -> Result where Result: Sendable

        /// Call the "ListValuesForSubject" method.
        ///
        /// - Parameters:
        ///   - request: A request containing a single `Primandproper_Platform_Settings_V1_ListValuesForSubjectRequest` message.
        ///   - serializer: A serializer for `Primandproper_Platform_Settings_V1_ListValuesForSubjectRequest` messages.
        ///   - deserializer: A deserializer for `Primandproper_Platform_Settings_V1_ListValuesForSubjectResponse` messages.
        ///   - options: Options to apply to this RPC.
        ///   - handleResponse: A closure which handles the response and returns its result to
        ///       the caller. Returning from the closure will cancel the RPC if it hasn't
        ///       already finished.
        /// - Returns: The result of `handleResponse`.
        func listValuesForSubject<Result>(
            request: GRPCCore.ClientRequest<Primandproper_Platform_Settings_V1_ListValuesForSubjectRequest>,
            serializer: some GRPCCore.MessageSerializer<Primandproper_Platform_Settings_V1_ListValuesForSubjectRequest>,
            deserializer: some GRPCCore.MessageDeserializer<Primandproper_Platform_Settings_V1_ListValuesForSubjectResponse>,
            options: GRPCCore.CallOptions,
            onResponse handleResponse: @Sendable @escaping (GRPCCore.ClientResponse<Primandproper_Platform_Settings_V1_ListValuesForSubjectResponse>) async throws -> Result
        ) async throws -> Result where Result: Sendable

        /// Call the "Resolve" method.
        ///
        /// - Parameters:
        ///   - request: A request containing a single `Primandproper_Platform_Settings_V1_ResolveRequest` message.
        ///   - serializer: A serializer for `Primandproper_Platform_Settings_V1_ResolveRequest` messages.
        ///   - deserializer: A deserializer for `Primandproper_Platform_Settings_V1_ResolveResponse` messages.
        ///   - options: Options to apply to this RPC.
        ///   - handleResponse: A closure which handles the response and returns its result to
        ///       the caller. Returning from the closure will cancel the RPC if it hasn't
        ///       already finished.
        /// - Returns: The result of `handleResponse`.
        func resolve<Result>(
            request: GRPCCore.ClientRequest<Primandproper_Platform_Settings_V1_ResolveRequest>,
            serializer: some GRPCCore.MessageSerializer<Primandproper_Platform_Settings_V1_ResolveRequest>,
            deserializer: some GRPCCore.MessageDeserializer<Primandproper_Platform_Settings_V1_ResolveResponse>,
            options: GRPCCore.CallOptions,
            onResponse handleResponse: @Sendable @escaping (GRPCCore.ClientResponse<Primandproper_Platform_Settings_V1_ResolveResponse>) async throws -> Result
        ) async throws -> Result where Result: Sendable

        /// Call the "ResolveAll" method.
        ///
        /// - Parameters:
        ///   - request: A request containing a single `Primandproper_Platform_Settings_V1_ResolveAllRequest` message.
        ///   - serializer: A serializer for `Primandproper_Platform_Settings_V1_ResolveAllRequest` messages.
        ///   - deserializer: A deserializer for `Primandproper_Platform_Settings_V1_ResolveAllResponse` messages.
        ///   - options: Options to apply to this RPC.
        ///   - handleResponse: A closure which handles the response and returns its result to
        ///       the caller. Returning from the closure will cancel the RPC if it hasn't
        ///       already finished.
        /// - Returns: The result of `handleResponse`.
        func resolveAll<Result>(
            request: GRPCCore.ClientRequest<Primandproper_Platform_Settings_V1_ResolveAllRequest>,
            serializer: some GRPCCore.MessageSerializer<Primandproper_Platform_Settings_V1_ResolveAllRequest>,
            deserializer: some GRPCCore.MessageDeserializer<Primandproper_Platform_Settings_V1_ResolveAllResponse>,
            options: GRPCCore.CallOptions,
            onResponse handleResponse: @Sendable @escaping (GRPCCore.ClientResponse<Primandproper_Platform_Settings_V1_ResolveAllResponse>) async throws -> Result
        ) async throws -> Result where Result: Sendable
    }

    /// Generated client for the "primandproper.platform.settings.v1.SettingsService" service.
    ///
    /// The ``Client`` provides an implementation of ``ClientProtocol`` which wraps
    /// a `GRPCCore.GRPCCClient`. The underlying `GRPCClient` provides the long-lived
    /// means of communication with the remote peer.
    ///
    /// > Source IDL Documentation:
    /// >
    /// > SettingsService is the catalog and the answers stored against it.
    /// > 
    /// > Thirteen RPCs over the fourteen methods of settings.Store, and the split in
    /// > them is two audiences rather than two nouns. The seven definition methods are
    /// > an operator's: what settings exist, what each holds, and who has overridden
    /// > one. The six value methods are a person acting on themselves, and they are
    /// > the settings screen every consumer ships.
    /// > 
    /// > The fourteenth is DeleteValuesForSubject and it is deliberately absent. It
    /// > destroys everything one subject answered, cleared answers included, and it is
    /// > erasure machinery -- a dataprivacy.Eraser or a retention sweep calling on a
    /// > subject's behalf from inside the transaction that removes the rest of them.
    /// > A write whose whole property is that it commits with its caller's other
    /// > writes is not an RPC: over a wire it lands in a transaction of its own, at a
    /// > moment the caller does not choose, and what you get is a person erased from
    /// > one table and present in the others. settings.Store documents the same
    /// > absence on the method itself.
    /// > 
    /// > Every method takes its scope off the caller's principal, and six of them take
    /// > a subject from the request -- which a grant on the method cannot check, so
    /// > settings/grpc asks a SubjectAuthorizer before any of the six reads or writes
    /// > a row.
    internal struct Client<Transport>: ClientProtocol where Transport: GRPCCore.ClientTransport {
        private let client: GRPCCore.GRPCClient<Transport>

        /// Creates a new client wrapping the provided `GRPCCore.GRPCClient`.
        ///
        /// - Parameters:
        ///   - client: A `GRPCCore.GRPCClient` providing a communication channel to the service.
        internal init(wrapping client: GRPCCore.GRPCClient<Transport>) {
            self.client = client
        }

        /// Call the "CreateDefinition" method.
        ///
        /// - Parameters:
        ///   - request: A request containing a single `Primandproper_Platform_Settings_V1_CreateDefinitionRequest` message.
        ///   - serializer: A serializer for `Primandproper_Platform_Settings_V1_CreateDefinitionRequest` messages.
        ///   - deserializer: A deserializer for `Primandproper_Platform_Settings_V1_CreateDefinitionResponse` messages.
        ///   - options: Options to apply to this RPC.
        ///   - handleResponse: A closure which handles the response and returns its result to
        ///       the caller. Returning from the closure will cancel the RPC if it hasn't
        ///       already finished.
        /// - Returns: The result of `handleResponse`.
        internal func createDefinition<Result>(
            request: GRPCCore.ClientRequest<Primandproper_Platform_Settings_V1_CreateDefinitionRequest>,
            serializer: some GRPCCore.MessageSerializer<Primandproper_Platform_Settings_V1_CreateDefinitionRequest>,
            deserializer: some GRPCCore.MessageDeserializer<Primandproper_Platform_Settings_V1_CreateDefinitionResponse>,
            options: GRPCCore.CallOptions = .defaults,
            onResponse handleResponse: @Sendable @escaping (GRPCCore.ClientResponse<Primandproper_Platform_Settings_V1_CreateDefinitionResponse>) async throws -> Result = { response in
                try response.message
            }
        ) async throws -> Result where Result: Sendable {
            try await self.client.unary(
                request: request,
                descriptor: Primandproper_Platform_Settings_V1_SettingsService.Method.CreateDefinition.descriptor,
                serializer: serializer,
                deserializer: deserializer,
                options: options,
                onResponse: handleResponse
            )
        }

        /// Call the "GetDefinition" method.
        ///
        /// - Parameters:
        ///   - request: A request containing a single `Primandproper_Platform_Settings_V1_GetDefinitionRequest` message.
        ///   - serializer: A serializer for `Primandproper_Platform_Settings_V1_GetDefinitionRequest` messages.
        ///   - deserializer: A deserializer for `Primandproper_Platform_Settings_V1_GetDefinitionResponse` messages.
        ///   - options: Options to apply to this RPC.
        ///   - handleResponse: A closure which handles the response and returns its result to
        ///       the caller. Returning from the closure will cancel the RPC if it hasn't
        ///       already finished.
        /// - Returns: The result of `handleResponse`.
        internal func getDefinition<Result>(
            request: GRPCCore.ClientRequest<Primandproper_Platform_Settings_V1_GetDefinitionRequest>,
            serializer: some GRPCCore.MessageSerializer<Primandproper_Platform_Settings_V1_GetDefinitionRequest>,
            deserializer: some GRPCCore.MessageDeserializer<Primandproper_Platform_Settings_V1_GetDefinitionResponse>,
            options: GRPCCore.CallOptions = .defaults,
            onResponse handleResponse: @Sendable @escaping (GRPCCore.ClientResponse<Primandproper_Platform_Settings_V1_GetDefinitionResponse>) async throws -> Result = { response in
                try response.message
            }
        ) async throws -> Result where Result: Sendable {
            try await self.client.unary(
                request: request,
                descriptor: Primandproper_Platform_Settings_V1_SettingsService.Method.GetDefinition.descriptor,
                serializer: serializer,
                deserializer: deserializer,
                options: options,
                onResponse: handleResponse
            )
        }

        /// Call the "GetDefinitionByName" method.
        ///
        /// - Parameters:
        ///   - request: A request containing a single `Primandproper_Platform_Settings_V1_GetDefinitionByNameRequest` message.
        ///   - serializer: A serializer for `Primandproper_Platform_Settings_V1_GetDefinitionByNameRequest` messages.
        ///   - deserializer: A deserializer for `Primandproper_Platform_Settings_V1_GetDefinitionByNameResponse` messages.
        ///   - options: Options to apply to this RPC.
        ///   - handleResponse: A closure which handles the response and returns its result to
        ///       the caller. Returning from the closure will cancel the RPC if it hasn't
        ///       already finished.
        /// - Returns: The result of `handleResponse`.
        internal func getDefinitionByName<Result>(
            request: GRPCCore.ClientRequest<Primandproper_Platform_Settings_V1_GetDefinitionByNameRequest>,
            serializer: some GRPCCore.MessageSerializer<Primandproper_Platform_Settings_V1_GetDefinitionByNameRequest>,
            deserializer: some GRPCCore.MessageDeserializer<Primandproper_Platform_Settings_V1_GetDefinitionByNameResponse>,
            options: GRPCCore.CallOptions = .defaults,
            onResponse handleResponse: @Sendable @escaping (GRPCCore.ClientResponse<Primandproper_Platform_Settings_V1_GetDefinitionByNameResponse>) async throws -> Result = { response in
                try response.message
            }
        ) async throws -> Result where Result: Sendable {
            try await self.client.unary(
                request: request,
                descriptor: Primandproper_Platform_Settings_V1_SettingsService.Method.GetDefinitionByName.descriptor,
                serializer: serializer,
                deserializer: deserializer,
                options: options,
                onResponse: handleResponse
            )
        }

        /// Call the "ListDefinitions" method.
        ///
        /// - Parameters:
        ///   - request: A request containing a single `Primandproper_Platform_Settings_V1_ListDefinitionsRequest` message.
        ///   - serializer: A serializer for `Primandproper_Platform_Settings_V1_ListDefinitionsRequest` messages.
        ///   - deserializer: A deserializer for `Primandproper_Platform_Settings_V1_ListDefinitionsResponse` messages.
        ///   - options: Options to apply to this RPC.
        ///   - handleResponse: A closure which handles the response and returns its result to
        ///       the caller. Returning from the closure will cancel the RPC if it hasn't
        ///       already finished.
        /// - Returns: The result of `handleResponse`.
        internal func listDefinitions<Result>(
            request: GRPCCore.ClientRequest<Primandproper_Platform_Settings_V1_ListDefinitionsRequest>,
            serializer: some GRPCCore.MessageSerializer<Primandproper_Platform_Settings_V1_ListDefinitionsRequest>,
            deserializer: some GRPCCore.MessageDeserializer<Primandproper_Platform_Settings_V1_ListDefinitionsResponse>,
            options: GRPCCore.CallOptions = .defaults,
            onResponse handleResponse: @Sendable @escaping (GRPCCore.ClientResponse<Primandproper_Platform_Settings_V1_ListDefinitionsResponse>) async throws -> Result = { response in
                try response.message
            }
        ) async throws -> Result where Result: Sendable {
            try await self.client.unary(
                request: request,
                descriptor: Primandproper_Platform_Settings_V1_SettingsService.Method.ListDefinitions.descriptor,
                serializer: serializer,
                deserializer: deserializer,
                options: options,
                onResponse: handleResponse
            )
        }

        /// Call the "UpdateDefinition" method.
        ///
        /// - Parameters:
        ///   - request: A request containing a single `Primandproper_Platform_Settings_V1_UpdateDefinitionRequest` message.
        ///   - serializer: A serializer for `Primandproper_Platform_Settings_V1_UpdateDefinitionRequest` messages.
        ///   - deserializer: A deserializer for `Primandproper_Platform_Settings_V1_UpdateDefinitionResponse` messages.
        ///   - options: Options to apply to this RPC.
        ///   - handleResponse: A closure which handles the response and returns its result to
        ///       the caller. Returning from the closure will cancel the RPC if it hasn't
        ///       already finished.
        /// - Returns: The result of `handleResponse`.
        internal func updateDefinition<Result>(
            request: GRPCCore.ClientRequest<Primandproper_Platform_Settings_V1_UpdateDefinitionRequest>,
            serializer: some GRPCCore.MessageSerializer<Primandproper_Platform_Settings_V1_UpdateDefinitionRequest>,
            deserializer: some GRPCCore.MessageDeserializer<Primandproper_Platform_Settings_V1_UpdateDefinitionResponse>,
            options: GRPCCore.CallOptions = .defaults,
            onResponse handleResponse: @Sendable @escaping (GRPCCore.ClientResponse<Primandproper_Platform_Settings_V1_UpdateDefinitionResponse>) async throws -> Result = { response in
                try response.message
            }
        ) async throws -> Result where Result: Sendable {
            try await self.client.unary(
                request: request,
                descriptor: Primandproper_Platform_Settings_V1_SettingsService.Method.UpdateDefinition.descriptor,
                serializer: serializer,
                deserializer: deserializer,
                options: options,
                onResponse: handleResponse
            )
        }

        /// Call the "ArchiveDefinition" method.
        ///
        /// - Parameters:
        ///   - request: A request containing a single `Primandproper_Platform_Settings_V1_ArchiveDefinitionRequest` message.
        ///   - serializer: A serializer for `Primandproper_Platform_Settings_V1_ArchiveDefinitionRequest` messages.
        ///   - deserializer: A deserializer for `Primandproper_Platform_Settings_V1_ArchiveDefinitionResponse` messages.
        ///   - options: Options to apply to this RPC.
        ///   - handleResponse: A closure which handles the response and returns its result to
        ///       the caller. Returning from the closure will cancel the RPC if it hasn't
        ///       already finished.
        /// - Returns: The result of `handleResponse`.
        internal func archiveDefinition<Result>(
            request: GRPCCore.ClientRequest<Primandproper_Platform_Settings_V1_ArchiveDefinitionRequest>,
            serializer: some GRPCCore.MessageSerializer<Primandproper_Platform_Settings_V1_ArchiveDefinitionRequest>,
            deserializer: some GRPCCore.MessageDeserializer<Primandproper_Platform_Settings_V1_ArchiveDefinitionResponse>,
            options: GRPCCore.CallOptions = .defaults,
            onResponse handleResponse: @Sendable @escaping (GRPCCore.ClientResponse<Primandproper_Platform_Settings_V1_ArchiveDefinitionResponse>) async throws -> Result = { response in
                try response.message
            }
        ) async throws -> Result where Result: Sendable {
            try await self.client.unary(
                request: request,
                descriptor: Primandproper_Platform_Settings_V1_SettingsService.Method.ArchiveDefinition.descriptor,
                serializer: serializer,
                deserializer: deserializer,
                options: options,
                onResponse: handleResponse
            )
        }

        /// Call the "ListValuesForDefinition" method.
        ///
        /// - Parameters:
        ///   - request: A request containing a single `Primandproper_Platform_Settings_V1_ListValuesForDefinitionRequest` message.
        ///   - serializer: A serializer for `Primandproper_Platform_Settings_V1_ListValuesForDefinitionRequest` messages.
        ///   - deserializer: A deserializer for `Primandproper_Platform_Settings_V1_ListValuesForDefinitionResponse` messages.
        ///   - options: Options to apply to this RPC.
        ///   - handleResponse: A closure which handles the response and returns its result to
        ///       the caller. Returning from the closure will cancel the RPC if it hasn't
        ///       already finished.
        /// - Returns: The result of `handleResponse`.
        internal func listValuesForDefinition<Result>(
            request: GRPCCore.ClientRequest<Primandproper_Platform_Settings_V1_ListValuesForDefinitionRequest>,
            serializer: some GRPCCore.MessageSerializer<Primandproper_Platform_Settings_V1_ListValuesForDefinitionRequest>,
            deserializer: some GRPCCore.MessageDeserializer<Primandproper_Platform_Settings_V1_ListValuesForDefinitionResponse>,
            options: GRPCCore.CallOptions = .defaults,
            onResponse handleResponse: @Sendable @escaping (GRPCCore.ClientResponse<Primandproper_Platform_Settings_V1_ListValuesForDefinitionResponse>) async throws -> Result = { response in
                try response.message
            }
        ) async throws -> Result where Result: Sendable {
            try await self.client.unary(
                request: request,
                descriptor: Primandproper_Platform_Settings_V1_SettingsService.Method.ListValuesForDefinition.descriptor,
                serializer: serializer,
                deserializer: deserializer,
                options: options,
                onResponse: handleResponse
            )
        }

        /// Call the "SetValue" method.
        ///
        /// - Parameters:
        ///   - request: A request containing a single `Primandproper_Platform_Settings_V1_SetValueRequest` message.
        ///   - serializer: A serializer for `Primandproper_Platform_Settings_V1_SetValueRequest` messages.
        ///   - deserializer: A deserializer for `Primandproper_Platform_Settings_V1_SetValueResponse` messages.
        ///   - options: Options to apply to this RPC.
        ///   - handleResponse: A closure which handles the response and returns its result to
        ///       the caller. Returning from the closure will cancel the RPC if it hasn't
        ///       already finished.
        /// - Returns: The result of `handleResponse`.
        internal func setValue<Result>(
            request: GRPCCore.ClientRequest<Primandproper_Platform_Settings_V1_SetValueRequest>,
            serializer: some GRPCCore.MessageSerializer<Primandproper_Platform_Settings_V1_SetValueRequest>,
            deserializer: some GRPCCore.MessageDeserializer<Primandproper_Platform_Settings_V1_SetValueResponse>,
            options: GRPCCore.CallOptions = .defaults,
            onResponse handleResponse: @Sendable @escaping (GRPCCore.ClientResponse<Primandproper_Platform_Settings_V1_SetValueResponse>) async throws -> Result = { response in
                try response.message
            }
        ) async throws -> Result where Result: Sendable {
            try await self.client.unary(
                request: request,
                descriptor: Primandproper_Platform_Settings_V1_SettingsService.Method.SetValue.descriptor,
                serializer: serializer,
                deserializer: deserializer,
                options: options,
                onResponse: handleResponse
            )
        }

        /// Call the "GetValue" method.
        ///
        /// - Parameters:
        ///   - request: A request containing a single `Primandproper_Platform_Settings_V1_GetValueRequest` message.
        ///   - serializer: A serializer for `Primandproper_Platform_Settings_V1_GetValueRequest` messages.
        ///   - deserializer: A deserializer for `Primandproper_Platform_Settings_V1_GetValueResponse` messages.
        ///   - options: Options to apply to this RPC.
        ///   - handleResponse: A closure which handles the response and returns its result to
        ///       the caller. Returning from the closure will cancel the RPC if it hasn't
        ///       already finished.
        /// - Returns: The result of `handleResponse`.
        internal func getValue<Result>(
            request: GRPCCore.ClientRequest<Primandproper_Platform_Settings_V1_GetValueRequest>,
            serializer: some GRPCCore.MessageSerializer<Primandproper_Platform_Settings_V1_GetValueRequest>,
            deserializer: some GRPCCore.MessageDeserializer<Primandproper_Platform_Settings_V1_GetValueResponse>,
            options: GRPCCore.CallOptions = .defaults,
            onResponse handleResponse: @Sendable @escaping (GRPCCore.ClientResponse<Primandproper_Platform_Settings_V1_GetValueResponse>) async throws -> Result = { response in
                try response.message
            }
        ) async throws -> Result where Result: Sendable {
            try await self.client.unary(
                request: request,
                descriptor: Primandproper_Platform_Settings_V1_SettingsService.Method.GetValue.descriptor,
                serializer: serializer,
                deserializer: deserializer,
                options: options,
                onResponse: handleResponse
            )
        }

        /// Call the "ClearValue" method.
        ///
        /// - Parameters:
        ///   - request: A request containing a single `Primandproper_Platform_Settings_V1_ClearValueRequest` message.
        ///   - serializer: A serializer for `Primandproper_Platform_Settings_V1_ClearValueRequest` messages.
        ///   - deserializer: A deserializer for `Primandproper_Platform_Settings_V1_ClearValueResponse` messages.
        ///   - options: Options to apply to this RPC.
        ///   - handleResponse: A closure which handles the response and returns its result to
        ///       the caller. Returning from the closure will cancel the RPC if it hasn't
        ///       already finished.
        /// - Returns: The result of `handleResponse`.
        internal func clearValue<Result>(
            request: GRPCCore.ClientRequest<Primandproper_Platform_Settings_V1_ClearValueRequest>,
            serializer: some GRPCCore.MessageSerializer<Primandproper_Platform_Settings_V1_ClearValueRequest>,
            deserializer: some GRPCCore.MessageDeserializer<Primandproper_Platform_Settings_V1_ClearValueResponse>,
            options: GRPCCore.CallOptions = .defaults,
            onResponse handleResponse: @Sendable @escaping (GRPCCore.ClientResponse<Primandproper_Platform_Settings_V1_ClearValueResponse>) async throws -> Result = { response in
                try response.message
            }
        ) async throws -> Result where Result: Sendable {
            try await self.client.unary(
                request: request,
                descriptor: Primandproper_Platform_Settings_V1_SettingsService.Method.ClearValue.descriptor,
                serializer: serializer,
                deserializer: deserializer,
                options: options,
                onResponse: handleResponse
            )
        }

        /// Call the "ListValuesForSubject" method.
        ///
        /// - Parameters:
        ///   - request: A request containing a single `Primandproper_Platform_Settings_V1_ListValuesForSubjectRequest` message.
        ///   - serializer: A serializer for `Primandproper_Platform_Settings_V1_ListValuesForSubjectRequest` messages.
        ///   - deserializer: A deserializer for `Primandproper_Platform_Settings_V1_ListValuesForSubjectResponse` messages.
        ///   - options: Options to apply to this RPC.
        ///   - handleResponse: A closure which handles the response and returns its result to
        ///       the caller. Returning from the closure will cancel the RPC if it hasn't
        ///       already finished.
        /// - Returns: The result of `handleResponse`.
        internal func listValuesForSubject<Result>(
            request: GRPCCore.ClientRequest<Primandproper_Platform_Settings_V1_ListValuesForSubjectRequest>,
            serializer: some GRPCCore.MessageSerializer<Primandproper_Platform_Settings_V1_ListValuesForSubjectRequest>,
            deserializer: some GRPCCore.MessageDeserializer<Primandproper_Platform_Settings_V1_ListValuesForSubjectResponse>,
            options: GRPCCore.CallOptions = .defaults,
            onResponse handleResponse: @Sendable @escaping (GRPCCore.ClientResponse<Primandproper_Platform_Settings_V1_ListValuesForSubjectResponse>) async throws -> Result = { response in
                try response.message
            }
        ) async throws -> Result where Result: Sendable {
            try await self.client.unary(
                request: request,
                descriptor: Primandproper_Platform_Settings_V1_SettingsService.Method.ListValuesForSubject.descriptor,
                serializer: serializer,
                deserializer: deserializer,
                options: options,
                onResponse: handleResponse
            )
        }

        /// Call the "Resolve" method.
        ///
        /// - Parameters:
        ///   - request: A request containing a single `Primandproper_Platform_Settings_V1_ResolveRequest` message.
        ///   - serializer: A serializer for `Primandproper_Platform_Settings_V1_ResolveRequest` messages.
        ///   - deserializer: A deserializer for `Primandproper_Platform_Settings_V1_ResolveResponse` messages.
        ///   - options: Options to apply to this RPC.
        ///   - handleResponse: A closure which handles the response and returns its result to
        ///       the caller. Returning from the closure will cancel the RPC if it hasn't
        ///       already finished.
        /// - Returns: The result of `handleResponse`.
        internal func resolve<Result>(
            request: GRPCCore.ClientRequest<Primandproper_Platform_Settings_V1_ResolveRequest>,
            serializer: some GRPCCore.MessageSerializer<Primandproper_Platform_Settings_V1_ResolveRequest>,
            deserializer: some GRPCCore.MessageDeserializer<Primandproper_Platform_Settings_V1_ResolveResponse>,
            options: GRPCCore.CallOptions = .defaults,
            onResponse handleResponse: @Sendable @escaping (GRPCCore.ClientResponse<Primandproper_Platform_Settings_V1_ResolveResponse>) async throws -> Result = { response in
                try response.message
            }
        ) async throws -> Result where Result: Sendable {
            try await self.client.unary(
                request: request,
                descriptor: Primandproper_Platform_Settings_V1_SettingsService.Method.Resolve.descriptor,
                serializer: serializer,
                deserializer: deserializer,
                options: options,
                onResponse: handleResponse
            )
        }

        /// Call the "ResolveAll" method.
        ///
        /// - Parameters:
        ///   - request: A request containing a single `Primandproper_Platform_Settings_V1_ResolveAllRequest` message.
        ///   - serializer: A serializer for `Primandproper_Platform_Settings_V1_ResolveAllRequest` messages.
        ///   - deserializer: A deserializer for `Primandproper_Platform_Settings_V1_ResolveAllResponse` messages.
        ///   - options: Options to apply to this RPC.
        ///   - handleResponse: A closure which handles the response and returns its result to
        ///       the caller. Returning from the closure will cancel the RPC if it hasn't
        ///       already finished.
        /// - Returns: The result of `handleResponse`.
        internal func resolveAll<Result>(
            request: GRPCCore.ClientRequest<Primandproper_Platform_Settings_V1_ResolveAllRequest>,
            serializer: some GRPCCore.MessageSerializer<Primandproper_Platform_Settings_V1_ResolveAllRequest>,
            deserializer: some GRPCCore.MessageDeserializer<Primandproper_Platform_Settings_V1_ResolveAllResponse>,
            options: GRPCCore.CallOptions = .defaults,
            onResponse handleResponse: @Sendable @escaping (GRPCCore.ClientResponse<Primandproper_Platform_Settings_V1_ResolveAllResponse>) async throws -> Result = { response in
                try response.message
            }
        ) async throws -> Result where Result: Sendable {
            try await self.client.unary(
                request: request,
                descriptor: Primandproper_Platform_Settings_V1_SettingsService.Method.ResolveAll.descriptor,
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
extension Primandproper_Platform_Settings_V1_SettingsService.ClientProtocol {
    /// Call the "CreateDefinition" method.
    ///
    /// - Parameters:
    ///   - request: A request containing a single `Primandproper_Platform_Settings_V1_CreateDefinitionRequest` message.
    ///   - options: Options to apply to this RPC.
    ///   - handleResponse: A closure which handles the response and returns its result to
    ///       the caller. Returning from the closure will cancel the RPC if it hasn't
    ///       already finished.
    /// - Returns: The result of `handleResponse`.
    internal func createDefinition<Result>(
        request: GRPCCore.ClientRequest<Primandproper_Platform_Settings_V1_CreateDefinitionRequest>,
        options: GRPCCore.CallOptions = .defaults,
        onResponse handleResponse: @Sendable @escaping (GRPCCore.ClientResponse<Primandproper_Platform_Settings_V1_CreateDefinitionResponse>) async throws -> Result = { response in
            try response.message
        }
    ) async throws -> Result where Result: Sendable {
        try await self.createDefinition(
            request: request,
            serializer: GRPCProtobuf.ProtobufSerializer<Primandproper_Platform_Settings_V1_CreateDefinitionRequest>(),
            deserializer: GRPCProtobuf.ProtobufDeserializer<Primandproper_Platform_Settings_V1_CreateDefinitionResponse>(),
            options: options,
            onResponse: handleResponse
        )
    }

    /// Call the "GetDefinition" method.
    ///
    /// - Parameters:
    ///   - request: A request containing a single `Primandproper_Platform_Settings_V1_GetDefinitionRequest` message.
    ///   - options: Options to apply to this RPC.
    ///   - handleResponse: A closure which handles the response and returns its result to
    ///       the caller. Returning from the closure will cancel the RPC if it hasn't
    ///       already finished.
    /// - Returns: The result of `handleResponse`.
    internal func getDefinition<Result>(
        request: GRPCCore.ClientRequest<Primandproper_Platform_Settings_V1_GetDefinitionRequest>,
        options: GRPCCore.CallOptions = .defaults,
        onResponse handleResponse: @Sendable @escaping (GRPCCore.ClientResponse<Primandproper_Platform_Settings_V1_GetDefinitionResponse>) async throws -> Result = { response in
            try response.message
        }
    ) async throws -> Result where Result: Sendable {
        try await self.getDefinition(
            request: request,
            serializer: GRPCProtobuf.ProtobufSerializer<Primandproper_Platform_Settings_V1_GetDefinitionRequest>(),
            deserializer: GRPCProtobuf.ProtobufDeserializer<Primandproper_Platform_Settings_V1_GetDefinitionResponse>(),
            options: options,
            onResponse: handleResponse
        )
    }

    /// Call the "GetDefinitionByName" method.
    ///
    /// - Parameters:
    ///   - request: A request containing a single `Primandproper_Platform_Settings_V1_GetDefinitionByNameRequest` message.
    ///   - options: Options to apply to this RPC.
    ///   - handleResponse: A closure which handles the response and returns its result to
    ///       the caller. Returning from the closure will cancel the RPC if it hasn't
    ///       already finished.
    /// - Returns: The result of `handleResponse`.
    internal func getDefinitionByName<Result>(
        request: GRPCCore.ClientRequest<Primandproper_Platform_Settings_V1_GetDefinitionByNameRequest>,
        options: GRPCCore.CallOptions = .defaults,
        onResponse handleResponse: @Sendable @escaping (GRPCCore.ClientResponse<Primandproper_Platform_Settings_V1_GetDefinitionByNameResponse>) async throws -> Result = { response in
            try response.message
        }
    ) async throws -> Result where Result: Sendable {
        try await self.getDefinitionByName(
            request: request,
            serializer: GRPCProtobuf.ProtobufSerializer<Primandproper_Platform_Settings_V1_GetDefinitionByNameRequest>(),
            deserializer: GRPCProtobuf.ProtobufDeserializer<Primandproper_Platform_Settings_V1_GetDefinitionByNameResponse>(),
            options: options,
            onResponse: handleResponse
        )
    }

    /// Call the "ListDefinitions" method.
    ///
    /// - Parameters:
    ///   - request: A request containing a single `Primandproper_Platform_Settings_V1_ListDefinitionsRequest` message.
    ///   - options: Options to apply to this RPC.
    ///   - handleResponse: A closure which handles the response and returns its result to
    ///       the caller. Returning from the closure will cancel the RPC if it hasn't
    ///       already finished.
    /// - Returns: The result of `handleResponse`.
    internal func listDefinitions<Result>(
        request: GRPCCore.ClientRequest<Primandproper_Platform_Settings_V1_ListDefinitionsRequest>,
        options: GRPCCore.CallOptions = .defaults,
        onResponse handleResponse: @Sendable @escaping (GRPCCore.ClientResponse<Primandproper_Platform_Settings_V1_ListDefinitionsResponse>) async throws -> Result = { response in
            try response.message
        }
    ) async throws -> Result where Result: Sendable {
        try await self.listDefinitions(
            request: request,
            serializer: GRPCProtobuf.ProtobufSerializer<Primandproper_Platform_Settings_V1_ListDefinitionsRequest>(),
            deserializer: GRPCProtobuf.ProtobufDeserializer<Primandproper_Platform_Settings_V1_ListDefinitionsResponse>(),
            options: options,
            onResponse: handleResponse
        )
    }

    /// Call the "UpdateDefinition" method.
    ///
    /// - Parameters:
    ///   - request: A request containing a single `Primandproper_Platform_Settings_V1_UpdateDefinitionRequest` message.
    ///   - options: Options to apply to this RPC.
    ///   - handleResponse: A closure which handles the response and returns its result to
    ///       the caller. Returning from the closure will cancel the RPC if it hasn't
    ///       already finished.
    /// - Returns: The result of `handleResponse`.
    internal func updateDefinition<Result>(
        request: GRPCCore.ClientRequest<Primandproper_Platform_Settings_V1_UpdateDefinitionRequest>,
        options: GRPCCore.CallOptions = .defaults,
        onResponse handleResponse: @Sendable @escaping (GRPCCore.ClientResponse<Primandproper_Platform_Settings_V1_UpdateDefinitionResponse>) async throws -> Result = { response in
            try response.message
        }
    ) async throws -> Result where Result: Sendable {
        try await self.updateDefinition(
            request: request,
            serializer: GRPCProtobuf.ProtobufSerializer<Primandproper_Platform_Settings_V1_UpdateDefinitionRequest>(),
            deserializer: GRPCProtobuf.ProtobufDeserializer<Primandproper_Platform_Settings_V1_UpdateDefinitionResponse>(),
            options: options,
            onResponse: handleResponse
        )
    }

    /// Call the "ArchiveDefinition" method.
    ///
    /// - Parameters:
    ///   - request: A request containing a single `Primandproper_Platform_Settings_V1_ArchiveDefinitionRequest` message.
    ///   - options: Options to apply to this RPC.
    ///   - handleResponse: A closure which handles the response and returns its result to
    ///       the caller. Returning from the closure will cancel the RPC if it hasn't
    ///       already finished.
    /// - Returns: The result of `handleResponse`.
    internal func archiveDefinition<Result>(
        request: GRPCCore.ClientRequest<Primandproper_Platform_Settings_V1_ArchiveDefinitionRequest>,
        options: GRPCCore.CallOptions = .defaults,
        onResponse handleResponse: @Sendable @escaping (GRPCCore.ClientResponse<Primandproper_Platform_Settings_V1_ArchiveDefinitionResponse>) async throws -> Result = { response in
            try response.message
        }
    ) async throws -> Result where Result: Sendable {
        try await self.archiveDefinition(
            request: request,
            serializer: GRPCProtobuf.ProtobufSerializer<Primandproper_Platform_Settings_V1_ArchiveDefinitionRequest>(),
            deserializer: GRPCProtobuf.ProtobufDeserializer<Primandproper_Platform_Settings_V1_ArchiveDefinitionResponse>(),
            options: options,
            onResponse: handleResponse
        )
    }

    /// Call the "ListValuesForDefinition" method.
    ///
    /// - Parameters:
    ///   - request: A request containing a single `Primandproper_Platform_Settings_V1_ListValuesForDefinitionRequest` message.
    ///   - options: Options to apply to this RPC.
    ///   - handleResponse: A closure which handles the response and returns its result to
    ///       the caller. Returning from the closure will cancel the RPC if it hasn't
    ///       already finished.
    /// - Returns: The result of `handleResponse`.
    internal func listValuesForDefinition<Result>(
        request: GRPCCore.ClientRequest<Primandproper_Platform_Settings_V1_ListValuesForDefinitionRequest>,
        options: GRPCCore.CallOptions = .defaults,
        onResponse handleResponse: @Sendable @escaping (GRPCCore.ClientResponse<Primandproper_Platform_Settings_V1_ListValuesForDefinitionResponse>) async throws -> Result = { response in
            try response.message
        }
    ) async throws -> Result where Result: Sendable {
        try await self.listValuesForDefinition(
            request: request,
            serializer: GRPCProtobuf.ProtobufSerializer<Primandproper_Platform_Settings_V1_ListValuesForDefinitionRequest>(),
            deserializer: GRPCProtobuf.ProtobufDeserializer<Primandproper_Platform_Settings_V1_ListValuesForDefinitionResponse>(),
            options: options,
            onResponse: handleResponse
        )
    }

    /// Call the "SetValue" method.
    ///
    /// - Parameters:
    ///   - request: A request containing a single `Primandproper_Platform_Settings_V1_SetValueRequest` message.
    ///   - options: Options to apply to this RPC.
    ///   - handleResponse: A closure which handles the response and returns its result to
    ///       the caller. Returning from the closure will cancel the RPC if it hasn't
    ///       already finished.
    /// - Returns: The result of `handleResponse`.
    internal func setValue<Result>(
        request: GRPCCore.ClientRequest<Primandproper_Platform_Settings_V1_SetValueRequest>,
        options: GRPCCore.CallOptions = .defaults,
        onResponse handleResponse: @Sendable @escaping (GRPCCore.ClientResponse<Primandproper_Platform_Settings_V1_SetValueResponse>) async throws -> Result = { response in
            try response.message
        }
    ) async throws -> Result where Result: Sendable {
        try await self.setValue(
            request: request,
            serializer: GRPCProtobuf.ProtobufSerializer<Primandproper_Platform_Settings_V1_SetValueRequest>(),
            deserializer: GRPCProtobuf.ProtobufDeserializer<Primandproper_Platform_Settings_V1_SetValueResponse>(),
            options: options,
            onResponse: handleResponse
        )
    }

    /// Call the "GetValue" method.
    ///
    /// - Parameters:
    ///   - request: A request containing a single `Primandproper_Platform_Settings_V1_GetValueRequest` message.
    ///   - options: Options to apply to this RPC.
    ///   - handleResponse: A closure which handles the response and returns its result to
    ///       the caller. Returning from the closure will cancel the RPC if it hasn't
    ///       already finished.
    /// - Returns: The result of `handleResponse`.
    internal func getValue<Result>(
        request: GRPCCore.ClientRequest<Primandproper_Platform_Settings_V1_GetValueRequest>,
        options: GRPCCore.CallOptions = .defaults,
        onResponse handleResponse: @Sendable @escaping (GRPCCore.ClientResponse<Primandproper_Platform_Settings_V1_GetValueResponse>) async throws -> Result = { response in
            try response.message
        }
    ) async throws -> Result where Result: Sendable {
        try await self.getValue(
            request: request,
            serializer: GRPCProtobuf.ProtobufSerializer<Primandproper_Platform_Settings_V1_GetValueRequest>(),
            deserializer: GRPCProtobuf.ProtobufDeserializer<Primandproper_Platform_Settings_V1_GetValueResponse>(),
            options: options,
            onResponse: handleResponse
        )
    }

    /// Call the "ClearValue" method.
    ///
    /// - Parameters:
    ///   - request: A request containing a single `Primandproper_Platform_Settings_V1_ClearValueRequest` message.
    ///   - options: Options to apply to this RPC.
    ///   - handleResponse: A closure which handles the response and returns its result to
    ///       the caller. Returning from the closure will cancel the RPC if it hasn't
    ///       already finished.
    /// - Returns: The result of `handleResponse`.
    internal func clearValue<Result>(
        request: GRPCCore.ClientRequest<Primandproper_Platform_Settings_V1_ClearValueRequest>,
        options: GRPCCore.CallOptions = .defaults,
        onResponse handleResponse: @Sendable @escaping (GRPCCore.ClientResponse<Primandproper_Platform_Settings_V1_ClearValueResponse>) async throws -> Result = { response in
            try response.message
        }
    ) async throws -> Result where Result: Sendable {
        try await self.clearValue(
            request: request,
            serializer: GRPCProtobuf.ProtobufSerializer<Primandproper_Platform_Settings_V1_ClearValueRequest>(),
            deserializer: GRPCProtobuf.ProtobufDeserializer<Primandproper_Platform_Settings_V1_ClearValueResponse>(),
            options: options,
            onResponse: handleResponse
        )
    }

    /// Call the "ListValuesForSubject" method.
    ///
    /// - Parameters:
    ///   - request: A request containing a single `Primandproper_Platform_Settings_V1_ListValuesForSubjectRequest` message.
    ///   - options: Options to apply to this RPC.
    ///   - handleResponse: A closure which handles the response and returns its result to
    ///       the caller. Returning from the closure will cancel the RPC if it hasn't
    ///       already finished.
    /// - Returns: The result of `handleResponse`.
    internal func listValuesForSubject<Result>(
        request: GRPCCore.ClientRequest<Primandproper_Platform_Settings_V1_ListValuesForSubjectRequest>,
        options: GRPCCore.CallOptions = .defaults,
        onResponse handleResponse: @Sendable @escaping (GRPCCore.ClientResponse<Primandproper_Platform_Settings_V1_ListValuesForSubjectResponse>) async throws -> Result = { response in
            try response.message
        }
    ) async throws -> Result where Result: Sendable {
        try await self.listValuesForSubject(
            request: request,
            serializer: GRPCProtobuf.ProtobufSerializer<Primandproper_Platform_Settings_V1_ListValuesForSubjectRequest>(),
            deserializer: GRPCProtobuf.ProtobufDeserializer<Primandproper_Platform_Settings_V1_ListValuesForSubjectResponse>(),
            options: options,
            onResponse: handleResponse
        )
    }

    /// Call the "Resolve" method.
    ///
    /// - Parameters:
    ///   - request: A request containing a single `Primandproper_Platform_Settings_V1_ResolveRequest` message.
    ///   - options: Options to apply to this RPC.
    ///   - handleResponse: A closure which handles the response and returns its result to
    ///       the caller. Returning from the closure will cancel the RPC if it hasn't
    ///       already finished.
    /// - Returns: The result of `handleResponse`.
    internal func resolve<Result>(
        request: GRPCCore.ClientRequest<Primandproper_Platform_Settings_V1_ResolveRequest>,
        options: GRPCCore.CallOptions = .defaults,
        onResponse handleResponse: @Sendable @escaping (GRPCCore.ClientResponse<Primandproper_Platform_Settings_V1_ResolveResponse>) async throws -> Result = { response in
            try response.message
        }
    ) async throws -> Result where Result: Sendable {
        try await self.resolve(
            request: request,
            serializer: GRPCProtobuf.ProtobufSerializer<Primandproper_Platform_Settings_V1_ResolveRequest>(),
            deserializer: GRPCProtobuf.ProtobufDeserializer<Primandproper_Platform_Settings_V1_ResolveResponse>(),
            options: options,
            onResponse: handleResponse
        )
    }

    /// Call the "ResolveAll" method.
    ///
    /// - Parameters:
    ///   - request: A request containing a single `Primandproper_Platform_Settings_V1_ResolveAllRequest` message.
    ///   - options: Options to apply to this RPC.
    ///   - handleResponse: A closure which handles the response and returns its result to
    ///       the caller. Returning from the closure will cancel the RPC if it hasn't
    ///       already finished.
    /// - Returns: The result of `handleResponse`.
    internal func resolveAll<Result>(
        request: GRPCCore.ClientRequest<Primandproper_Platform_Settings_V1_ResolveAllRequest>,
        options: GRPCCore.CallOptions = .defaults,
        onResponse handleResponse: @Sendable @escaping (GRPCCore.ClientResponse<Primandproper_Platform_Settings_V1_ResolveAllResponse>) async throws -> Result = { response in
            try response.message
        }
    ) async throws -> Result where Result: Sendable {
        try await self.resolveAll(
            request: request,
            serializer: GRPCProtobuf.ProtobufSerializer<Primandproper_Platform_Settings_V1_ResolveAllRequest>(),
            deserializer: GRPCProtobuf.ProtobufDeserializer<Primandproper_Platform_Settings_V1_ResolveAllResponse>(),
            options: options,
            onResponse: handleResponse
        )
    }
}

// Helpers providing sugared APIs for 'ClientProtocol' methods.
@available(macOS 15.0, iOS 18.0, watchOS 11.0, tvOS 18.0, visionOS 2.0, *)
extension Primandproper_Platform_Settings_V1_SettingsService.ClientProtocol {
    /// Call the "CreateDefinition" method.
    ///
    /// - Parameters:
    ///   - message: request message to send.
    ///   - metadata: Additional metadata to send, defaults to empty.
    ///   - options: Options to apply to this RPC, defaults to `.defaults`.
    ///   - handleResponse: A closure which handles the response and returns its result to
    ///       the caller. Returning from the closure will cancel the RPC if it hasn't
    ///       already finished.
    /// - Returns: The result of `handleResponse`.
    internal func createDefinition<Result>(
        _ message: Primandproper_Platform_Settings_V1_CreateDefinitionRequest,
        metadata: GRPCCore.Metadata = [:],
        options: GRPCCore.CallOptions = .defaults,
        onResponse handleResponse: @Sendable @escaping (GRPCCore.ClientResponse<Primandproper_Platform_Settings_V1_CreateDefinitionResponse>) async throws -> Result = { response in
            try response.message
        }
    ) async throws -> Result where Result: Sendable {
        let request = GRPCCore.ClientRequest<Primandproper_Platform_Settings_V1_CreateDefinitionRequest>(
            message: message,
            metadata: metadata
        )
        return try await self.createDefinition(
            request: request,
            options: options,
            onResponse: handleResponse
        )
    }

    /// Call the "GetDefinition" method.
    ///
    /// - Parameters:
    ///   - message: request message to send.
    ///   - metadata: Additional metadata to send, defaults to empty.
    ///   - options: Options to apply to this RPC, defaults to `.defaults`.
    ///   - handleResponse: A closure which handles the response and returns its result to
    ///       the caller. Returning from the closure will cancel the RPC if it hasn't
    ///       already finished.
    /// - Returns: The result of `handleResponse`.
    internal func getDefinition<Result>(
        _ message: Primandproper_Platform_Settings_V1_GetDefinitionRequest,
        metadata: GRPCCore.Metadata = [:],
        options: GRPCCore.CallOptions = .defaults,
        onResponse handleResponse: @Sendable @escaping (GRPCCore.ClientResponse<Primandproper_Platform_Settings_V1_GetDefinitionResponse>) async throws -> Result = { response in
            try response.message
        }
    ) async throws -> Result where Result: Sendable {
        let request = GRPCCore.ClientRequest<Primandproper_Platform_Settings_V1_GetDefinitionRequest>(
            message: message,
            metadata: metadata
        )
        return try await self.getDefinition(
            request: request,
            options: options,
            onResponse: handleResponse
        )
    }

    /// Call the "GetDefinitionByName" method.
    ///
    /// - Parameters:
    ///   - message: request message to send.
    ///   - metadata: Additional metadata to send, defaults to empty.
    ///   - options: Options to apply to this RPC, defaults to `.defaults`.
    ///   - handleResponse: A closure which handles the response and returns its result to
    ///       the caller. Returning from the closure will cancel the RPC if it hasn't
    ///       already finished.
    /// - Returns: The result of `handleResponse`.
    internal func getDefinitionByName<Result>(
        _ message: Primandproper_Platform_Settings_V1_GetDefinitionByNameRequest,
        metadata: GRPCCore.Metadata = [:],
        options: GRPCCore.CallOptions = .defaults,
        onResponse handleResponse: @Sendable @escaping (GRPCCore.ClientResponse<Primandproper_Platform_Settings_V1_GetDefinitionByNameResponse>) async throws -> Result = { response in
            try response.message
        }
    ) async throws -> Result where Result: Sendable {
        let request = GRPCCore.ClientRequest<Primandproper_Platform_Settings_V1_GetDefinitionByNameRequest>(
            message: message,
            metadata: metadata
        )
        return try await self.getDefinitionByName(
            request: request,
            options: options,
            onResponse: handleResponse
        )
    }

    /// Call the "ListDefinitions" method.
    ///
    /// - Parameters:
    ///   - message: request message to send.
    ///   - metadata: Additional metadata to send, defaults to empty.
    ///   - options: Options to apply to this RPC, defaults to `.defaults`.
    ///   - handleResponse: A closure which handles the response and returns its result to
    ///       the caller. Returning from the closure will cancel the RPC if it hasn't
    ///       already finished.
    /// - Returns: The result of `handleResponse`.
    internal func listDefinitions<Result>(
        _ message: Primandproper_Platform_Settings_V1_ListDefinitionsRequest,
        metadata: GRPCCore.Metadata = [:],
        options: GRPCCore.CallOptions = .defaults,
        onResponse handleResponse: @Sendable @escaping (GRPCCore.ClientResponse<Primandproper_Platform_Settings_V1_ListDefinitionsResponse>) async throws -> Result = { response in
            try response.message
        }
    ) async throws -> Result where Result: Sendable {
        let request = GRPCCore.ClientRequest<Primandproper_Platform_Settings_V1_ListDefinitionsRequest>(
            message: message,
            metadata: metadata
        )
        return try await self.listDefinitions(
            request: request,
            options: options,
            onResponse: handleResponse
        )
    }

    /// Call the "UpdateDefinition" method.
    ///
    /// - Parameters:
    ///   - message: request message to send.
    ///   - metadata: Additional metadata to send, defaults to empty.
    ///   - options: Options to apply to this RPC, defaults to `.defaults`.
    ///   - handleResponse: A closure which handles the response and returns its result to
    ///       the caller. Returning from the closure will cancel the RPC if it hasn't
    ///       already finished.
    /// - Returns: The result of `handleResponse`.
    internal func updateDefinition<Result>(
        _ message: Primandproper_Platform_Settings_V1_UpdateDefinitionRequest,
        metadata: GRPCCore.Metadata = [:],
        options: GRPCCore.CallOptions = .defaults,
        onResponse handleResponse: @Sendable @escaping (GRPCCore.ClientResponse<Primandproper_Platform_Settings_V1_UpdateDefinitionResponse>) async throws -> Result = { response in
            try response.message
        }
    ) async throws -> Result where Result: Sendable {
        let request = GRPCCore.ClientRequest<Primandproper_Platform_Settings_V1_UpdateDefinitionRequest>(
            message: message,
            metadata: metadata
        )
        return try await self.updateDefinition(
            request: request,
            options: options,
            onResponse: handleResponse
        )
    }

    /// Call the "ArchiveDefinition" method.
    ///
    /// - Parameters:
    ///   - message: request message to send.
    ///   - metadata: Additional metadata to send, defaults to empty.
    ///   - options: Options to apply to this RPC, defaults to `.defaults`.
    ///   - handleResponse: A closure which handles the response and returns its result to
    ///       the caller. Returning from the closure will cancel the RPC if it hasn't
    ///       already finished.
    /// - Returns: The result of `handleResponse`.
    internal func archiveDefinition<Result>(
        _ message: Primandproper_Platform_Settings_V1_ArchiveDefinitionRequest,
        metadata: GRPCCore.Metadata = [:],
        options: GRPCCore.CallOptions = .defaults,
        onResponse handleResponse: @Sendable @escaping (GRPCCore.ClientResponse<Primandproper_Platform_Settings_V1_ArchiveDefinitionResponse>) async throws -> Result = { response in
            try response.message
        }
    ) async throws -> Result where Result: Sendable {
        let request = GRPCCore.ClientRequest<Primandproper_Platform_Settings_V1_ArchiveDefinitionRequest>(
            message: message,
            metadata: metadata
        )
        return try await self.archiveDefinition(
            request: request,
            options: options,
            onResponse: handleResponse
        )
    }

    /// Call the "ListValuesForDefinition" method.
    ///
    /// - Parameters:
    ///   - message: request message to send.
    ///   - metadata: Additional metadata to send, defaults to empty.
    ///   - options: Options to apply to this RPC, defaults to `.defaults`.
    ///   - handleResponse: A closure which handles the response and returns its result to
    ///       the caller. Returning from the closure will cancel the RPC if it hasn't
    ///       already finished.
    /// - Returns: The result of `handleResponse`.
    internal func listValuesForDefinition<Result>(
        _ message: Primandproper_Platform_Settings_V1_ListValuesForDefinitionRequest,
        metadata: GRPCCore.Metadata = [:],
        options: GRPCCore.CallOptions = .defaults,
        onResponse handleResponse: @Sendable @escaping (GRPCCore.ClientResponse<Primandproper_Platform_Settings_V1_ListValuesForDefinitionResponse>) async throws -> Result = { response in
            try response.message
        }
    ) async throws -> Result where Result: Sendable {
        let request = GRPCCore.ClientRequest<Primandproper_Platform_Settings_V1_ListValuesForDefinitionRequest>(
            message: message,
            metadata: metadata
        )
        return try await self.listValuesForDefinition(
            request: request,
            options: options,
            onResponse: handleResponse
        )
    }

    /// Call the "SetValue" method.
    ///
    /// - Parameters:
    ///   - message: request message to send.
    ///   - metadata: Additional metadata to send, defaults to empty.
    ///   - options: Options to apply to this RPC, defaults to `.defaults`.
    ///   - handleResponse: A closure which handles the response and returns its result to
    ///       the caller. Returning from the closure will cancel the RPC if it hasn't
    ///       already finished.
    /// - Returns: The result of `handleResponse`.
    internal func setValue<Result>(
        _ message: Primandproper_Platform_Settings_V1_SetValueRequest,
        metadata: GRPCCore.Metadata = [:],
        options: GRPCCore.CallOptions = .defaults,
        onResponse handleResponse: @Sendable @escaping (GRPCCore.ClientResponse<Primandproper_Platform_Settings_V1_SetValueResponse>) async throws -> Result = { response in
            try response.message
        }
    ) async throws -> Result where Result: Sendable {
        let request = GRPCCore.ClientRequest<Primandproper_Platform_Settings_V1_SetValueRequest>(
            message: message,
            metadata: metadata
        )
        return try await self.setValue(
            request: request,
            options: options,
            onResponse: handleResponse
        )
    }

    /// Call the "GetValue" method.
    ///
    /// - Parameters:
    ///   - message: request message to send.
    ///   - metadata: Additional metadata to send, defaults to empty.
    ///   - options: Options to apply to this RPC, defaults to `.defaults`.
    ///   - handleResponse: A closure which handles the response and returns its result to
    ///       the caller. Returning from the closure will cancel the RPC if it hasn't
    ///       already finished.
    /// - Returns: The result of `handleResponse`.
    internal func getValue<Result>(
        _ message: Primandproper_Platform_Settings_V1_GetValueRequest,
        metadata: GRPCCore.Metadata = [:],
        options: GRPCCore.CallOptions = .defaults,
        onResponse handleResponse: @Sendable @escaping (GRPCCore.ClientResponse<Primandproper_Platform_Settings_V1_GetValueResponse>) async throws -> Result = { response in
            try response.message
        }
    ) async throws -> Result where Result: Sendable {
        let request = GRPCCore.ClientRequest<Primandproper_Platform_Settings_V1_GetValueRequest>(
            message: message,
            metadata: metadata
        )
        return try await self.getValue(
            request: request,
            options: options,
            onResponse: handleResponse
        )
    }

    /// Call the "ClearValue" method.
    ///
    /// - Parameters:
    ///   - message: request message to send.
    ///   - metadata: Additional metadata to send, defaults to empty.
    ///   - options: Options to apply to this RPC, defaults to `.defaults`.
    ///   - handleResponse: A closure which handles the response and returns its result to
    ///       the caller. Returning from the closure will cancel the RPC if it hasn't
    ///       already finished.
    /// - Returns: The result of `handleResponse`.
    internal func clearValue<Result>(
        _ message: Primandproper_Platform_Settings_V1_ClearValueRequest,
        metadata: GRPCCore.Metadata = [:],
        options: GRPCCore.CallOptions = .defaults,
        onResponse handleResponse: @Sendable @escaping (GRPCCore.ClientResponse<Primandproper_Platform_Settings_V1_ClearValueResponse>) async throws -> Result = { response in
            try response.message
        }
    ) async throws -> Result where Result: Sendable {
        let request = GRPCCore.ClientRequest<Primandproper_Platform_Settings_V1_ClearValueRequest>(
            message: message,
            metadata: metadata
        )
        return try await self.clearValue(
            request: request,
            options: options,
            onResponse: handleResponse
        )
    }

    /// Call the "ListValuesForSubject" method.
    ///
    /// - Parameters:
    ///   - message: request message to send.
    ///   - metadata: Additional metadata to send, defaults to empty.
    ///   - options: Options to apply to this RPC, defaults to `.defaults`.
    ///   - handleResponse: A closure which handles the response and returns its result to
    ///       the caller. Returning from the closure will cancel the RPC if it hasn't
    ///       already finished.
    /// - Returns: The result of `handleResponse`.
    internal func listValuesForSubject<Result>(
        _ message: Primandproper_Platform_Settings_V1_ListValuesForSubjectRequest,
        metadata: GRPCCore.Metadata = [:],
        options: GRPCCore.CallOptions = .defaults,
        onResponse handleResponse: @Sendable @escaping (GRPCCore.ClientResponse<Primandproper_Platform_Settings_V1_ListValuesForSubjectResponse>) async throws -> Result = { response in
            try response.message
        }
    ) async throws -> Result where Result: Sendable {
        let request = GRPCCore.ClientRequest<Primandproper_Platform_Settings_V1_ListValuesForSubjectRequest>(
            message: message,
            metadata: metadata
        )
        return try await self.listValuesForSubject(
            request: request,
            options: options,
            onResponse: handleResponse
        )
    }

    /// Call the "Resolve" method.
    ///
    /// - Parameters:
    ///   - message: request message to send.
    ///   - metadata: Additional metadata to send, defaults to empty.
    ///   - options: Options to apply to this RPC, defaults to `.defaults`.
    ///   - handleResponse: A closure which handles the response and returns its result to
    ///       the caller. Returning from the closure will cancel the RPC if it hasn't
    ///       already finished.
    /// - Returns: The result of `handleResponse`.
    internal func resolve<Result>(
        _ message: Primandproper_Platform_Settings_V1_ResolveRequest,
        metadata: GRPCCore.Metadata = [:],
        options: GRPCCore.CallOptions = .defaults,
        onResponse handleResponse: @Sendable @escaping (GRPCCore.ClientResponse<Primandproper_Platform_Settings_V1_ResolveResponse>) async throws -> Result = { response in
            try response.message
        }
    ) async throws -> Result where Result: Sendable {
        let request = GRPCCore.ClientRequest<Primandproper_Platform_Settings_V1_ResolveRequest>(
            message: message,
            metadata: metadata
        )
        return try await self.resolve(
            request: request,
            options: options,
            onResponse: handleResponse
        )
    }

    /// Call the "ResolveAll" method.
    ///
    /// - Parameters:
    ///   - message: request message to send.
    ///   - metadata: Additional metadata to send, defaults to empty.
    ///   - options: Options to apply to this RPC, defaults to `.defaults`.
    ///   - handleResponse: A closure which handles the response and returns its result to
    ///       the caller. Returning from the closure will cancel the RPC if it hasn't
    ///       already finished.
    /// - Returns: The result of `handleResponse`.
    internal func resolveAll<Result>(
        _ message: Primandproper_Platform_Settings_V1_ResolveAllRequest,
        metadata: GRPCCore.Metadata = [:],
        options: GRPCCore.CallOptions = .defaults,
        onResponse handleResponse: @Sendable @escaping (GRPCCore.ClientResponse<Primandproper_Platform_Settings_V1_ResolveAllResponse>) async throws -> Result = { response in
            try response.message
        }
    ) async throws -> Result where Result: Sendable {
        let request = GRPCCore.ClientRequest<Primandproper_Platform_Settings_V1_ResolveAllRequest>(
            message: message,
            metadata: metadata
        )
        return try await self.resolveAll(
            request: request,
            options: options,
            onResponse: handleResponse
        )
    }
}