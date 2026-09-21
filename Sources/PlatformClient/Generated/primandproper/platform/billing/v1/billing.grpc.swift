// Package primandproper.platform.billing.v1 is the wire schema for what a
// deployment sells and what its customers paid: the catalog, the recurring
// agreements, the one-time sales, and the ledger of attempts.
//
// This file is shipped inside the published Go module, and it is the file
// itself that is shipped -- not a copy for you to keep in sync. A consumer puts
// the module's proto directories on protoc's path and imports this file by its
// canonical name, exactly as identity.proto and filtering.proto already work:
//
//	PLATFORM_PROTO := $(shell go list -m -f '{{.Dir}}' github.com/primandproper/platform-go/v14)
//
//	protoc --proto_path proto/ \
//	    --proto_path $(PLATFORM_PROTO)/billing/proto \
//	    --proto_path $(PLATFORM_PROTO)/filtering/proto \
//	    --go_opt=Mprimandproper/platform/billing/v1/billing.proto=github.com/primandproper/platform-go/v14/billing/billingpb \
//	    $(CONSUMER_PROTO_FILES)   # the platform files deliberately absent from that list
//
// Field numbers are the compatibility promise, across every language a consumer
// generates into. Numbers are never reused and never repurposed: a field that
// goes away is reserved.
//
// # The one thing this schema will not carry
//
// There is no is_active, entitled, in_good_standing or account standing of any
// kind, on any message here, and there never will be. billing stores facts a
// payment provider owns and interprets none of them; a computed standing is the
// interpretation, it differs between two deployments selling the same thing, and
// putting it on the wire would put every consumer's policy on this module's
// release cadence.
//
// What ships instead is [Subscription.status], which is the fact. A consumer
// reads it and decides. The seam that decision belongs in already exists --
// billing/plans fills entitlements' PlanSource with this store's
// current-subscription read plus a function the consumer writes -- so a
// GetAccountStanding RPC here would be a second home for a policy that already
// has one.
//
// # Why status is a string and the other two are enums
//
// [Product.kind] and [Transaction.status] are enums. Both are closed sets
// billing defines itself and validates every write against, so a value outside
// the enum is a row the store would have refused; the generated constant is
// exactly as complete as the column.
//
// [Subscription.status] is a string, and it is the one borrowed vocabulary in
// this file. The set is capitalism.SubscriptionStatus -- the closed, documented
// set every payment adapter maps its provider's words onto -- and it is defined
// in a different module. An enum here would put that vocabulary on this module's
// release cadence, which is the objection identity/grpc's pattern section raises
// against a generated enum for a catalog somebody else owns; worse, a status
// primitives-go added and billing stored would render as UNSPECIFIED until this
// file caught up, which is a real row reaching a client as "we don't know".
// The wire value is the documented string -- "active", "past_due",
// "incomplete_expired" -- and it is never empty on a stored row, because the
// empty string is capitalism's unknown and billing refuses to store it.
//
// # What is not here, and why
//
// No scope field, anywhere. A scope a client could name is a cross-tenant read
// hiding behind a request field; it comes off the principal the consumer's
// interceptor put on the context. See identity.proto, which says this at
// greater length.
//
// No write that a payment processor's callback makes. Seven of billing's thirty
// store methods are absent from this service: CreateSubscription,
// UpdateSubscription, SetSubscriptionStatus, CreatePurchase, CompletePurchase,
// RecordTransaction and SetTransactionStatus. Their caller is not a client. It
// is a Stripe or RevenueCat receiver the consumer owns, or the checkout handler
// that created the payment intent, and both are already inside a transaction
// that is writing an audit entry and an outbox event beside the billing row. An
// RPC moves that write out of the transaction that was the entire point of it.
// billing/grpc/doc.go carries the ruling and billing.Store documents it on each
// method.
//
// No lookup by a payment provider's identifier. billing.Store has four --
// GetProductByExternalID and its three siblings -- and none is an RPC. The
// caller holding a provider's identifier is the callback that was handed one,
// and it already holds the store; a client that could ask "whose subscription is
// sub_1234" would be reading the provider's namespace rather than its own rows,
// against an id space it did not mint. A response about a row you may already
// read still carries the provider's id for it, which is the opposite direction
// and is how a console links out to the processor.
//
// No amount on any write. The only thing that legitimately changes about a
// ledger row is its status and the only thing that changes about a purchase is
// whether the money arrived, so there is no statement able to assign either --
// see billing's own documentation on why a price is a fact about a moment.

// DO NOT EDIT.
// swift-format-ignore-file
// swiftlint:disable all
//
// Generated by the gRPC Swift generator plugin for the protocol buffer compiler.
// Source: primandproper/platform/billing/v1/billing.proto
//
// For information on using the generated types, please see the documentation:
//   https://github.com/grpc/grpc-swift

import GRPCCore
import GRPCProtobuf

// MARK: - primandproper.platform.billing.v1.BillingService

/// Namespace containing generated types for the "primandproper.platform.billing.v1.BillingService" service.
@available(macOS 15.0, iOS 18.0, watchOS 11.0, tvOS 18.0, visionOS 2.0, *)
internal enum Primandproper_Platform_Billing_V1_BillingService: Sendable {
    /// Service descriptor for the "primandproper.platform.billing.v1.BillingService" service.
    internal static let descriptor = GRPCCore.ServiceDescriptor(fullyQualifiedService: "primandproper.platform.billing.v1.BillingService")
    /// Namespace for method metadata.
    internal enum Method: Sendable {
        /// Namespace for "CreateProduct" metadata.
        internal enum CreateProduct: Sendable {
            /// Request type for "CreateProduct".
            internal typealias Input = Primandproper_Platform_Billing_V1_CreateProductRequest
            /// Response type for "CreateProduct".
            internal typealias Output = Primandproper_Platform_Billing_V1_CreateProductResponse
            /// Descriptor for "CreateProduct".
            internal static let descriptor = GRPCCore.MethodDescriptor(
                service: GRPCCore.ServiceDescriptor(fullyQualifiedService: "primandproper.platform.billing.v1.BillingService"),
                method: "CreateProduct",
                type: .unary
            )
        }
        /// Namespace for "GetProduct" metadata.
        internal enum GetProduct: Sendable {
            /// Request type for "GetProduct".
            internal typealias Input = Primandproper_Platform_Billing_V1_GetProductRequest
            /// Response type for "GetProduct".
            internal typealias Output = Primandproper_Platform_Billing_V1_GetProductResponse
            /// Descriptor for "GetProduct".
            internal static let descriptor = GRPCCore.MethodDescriptor(
                service: GRPCCore.ServiceDescriptor(fullyQualifiedService: "primandproper.platform.billing.v1.BillingService"),
                method: "GetProduct",
                type: .unary
            )
        }
        /// Namespace for "ListProducts" metadata.
        internal enum ListProducts: Sendable {
            /// Request type for "ListProducts".
            internal typealias Input = Primandproper_Platform_Billing_V1_ListProductsRequest
            /// Response type for "ListProducts".
            internal typealias Output = Primandproper_Platform_Billing_V1_ListProductsResponse
            /// Descriptor for "ListProducts".
            internal static let descriptor = GRPCCore.MethodDescriptor(
                service: GRPCCore.ServiceDescriptor(fullyQualifiedService: "primandproper.platform.billing.v1.BillingService"),
                method: "ListProducts",
                type: .unary
            )
        }
        /// Namespace for "UpdateProduct" metadata.
        internal enum UpdateProduct: Sendable {
            /// Request type for "UpdateProduct".
            internal typealias Input = Primandproper_Platform_Billing_V1_UpdateProductRequest
            /// Response type for "UpdateProduct".
            internal typealias Output = Primandproper_Platform_Billing_V1_UpdateProductResponse
            /// Descriptor for "UpdateProduct".
            internal static let descriptor = GRPCCore.MethodDescriptor(
                service: GRPCCore.ServiceDescriptor(fullyQualifiedService: "primandproper.platform.billing.v1.BillingService"),
                method: "UpdateProduct",
                type: .unary
            )
        }
        /// Namespace for "ArchiveProduct" metadata.
        internal enum ArchiveProduct: Sendable {
            /// Request type for "ArchiveProduct".
            internal typealias Input = Primandproper_Platform_Billing_V1_ArchiveProductRequest
            /// Response type for "ArchiveProduct".
            internal typealias Output = Primandproper_Platform_Billing_V1_ArchiveProductResponse
            /// Descriptor for "ArchiveProduct".
            internal static let descriptor = GRPCCore.MethodDescriptor(
                service: GRPCCore.ServiceDescriptor(fullyQualifiedService: "primandproper.platform.billing.v1.BillingService"),
                method: "ArchiveProduct",
                type: .unary
            )
        }
        /// Namespace for "GetSubscription" metadata.
        internal enum GetSubscription: Sendable {
            /// Request type for "GetSubscription".
            internal typealias Input = Primandproper_Platform_Billing_V1_GetSubscriptionRequest
            /// Response type for "GetSubscription".
            internal typealias Output = Primandproper_Platform_Billing_V1_GetSubscriptionResponse
            /// Descriptor for "GetSubscription".
            internal static let descriptor = GRPCCore.MethodDescriptor(
                service: GRPCCore.ServiceDescriptor(fullyQualifiedService: "primandproper.platform.billing.v1.BillingService"),
                method: "GetSubscription",
                type: .unary
            )
        }
        /// Namespace for "ListSubscriptions" metadata.
        internal enum ListSubscriptions: Sendable {
            /// Request type for "ListSubscriptions".
            internal typealias Input = Primandproper_Platform_Billing_V1_ListSubscriptionsRequest
            /// Response type for "ListSubscriptions".
            internal typealias Output = Primandproper_Platform_Billing_V1_ListSubscriptionsResponse
            /// Descriptor for "ListSubscriptions".
            internal static let descriptor = GRPCCore.MethodDescriptor(
                service: GRPCCore.ServiceDescriptor(fullyQualifiedService: "primandproper.platform.billing.v1.BillingService"),
                method: "ListSubscriptions",
                type: .unary
            )
        }
        /// Namespace for "ListSubscriptionsForAccount" metadata.
        internal enum ListSubscriptionsForAccount: Sendable {
            /// Request type for "ListSubscriptionsForAccount".
            internal typealias Input = Primandproper_Platform_Billing_V1_ListSubscriptionsForAccountRequest
            /// Response type for "ListSubscriptionsForAccount".
            internal typealias Output = Primandproper_Platform_Billing_V1_ListSubscriptionsForAccountResponse
            /// Descriptor for "ListSubscriptionsForAccount".
            internal static let descriptor = GRPCCore.MethodDescriptor(
                service: GRPCCore.ServiceDescriptor(fullyQualifiedService: "primandproper.platform.billing.v1.BillingService"),
                method: "ListSubscriptionsForAccount",
                type: .unary
            )
        }
        /// Namespace for "ListCurrentSubscriptions" metadata.
        internal enum ListCurrentSubscriptions: Sendable {
            /// Request type for "ListCurrentSubscriptions".
            internal typealias Input = Primandproper_Platform_Billing_V1_ListCurrentSubscriptionsRequest
            /// Response type for "ListCurrentSubscriptions".
            internal typealias Output = Primandproper_Platform_Billing_V1_ListCurrentSubscriptionsResponse
            /// Descriptor for "ListCurrentSubscriptions".
            internal static let descriptor = GRPCCore.MethodDescriptor(
                service: GRPCCore.ServiceDescriptor(fullyQualifiedService: "primandproper.platform.billing.v1.BillingService"),
                method: "ListCurrentSubscriptions",
                type: .unary
            )
        }
        /// Namespace for "ArchiveSubscription" metadata.
        internal enum ArchiveSubscription: Sendable {
            /// Request type for "ArchiveSubscription".
            internal typealias Input = Primandproper_Platform_Billing_V1_ArchiveSubscriptionRequest
            /// Response type for "ArchiveSubscription".
            internal typealias Output = Primandproper_Platform_Billing_V1_ArchiveSubscriptionResponse
            /// Descriptor for "ArchiveSubscription".
            internal static let descriptor = GRPCCore.MethodDescriptor(
                service: GRPCCore.ServiceDescriptor(fullyQualifiedService: "primandproper.platform.billing.v1.BillingService"),
                method: "ArchiveSubscription",
                type: .unary
            )
        }
        /// Namespace for "GetPurchase" metadata.
        internal enum GetPurchase: Sendable {
            /// Request type for "GetPurchase".
            internal typealias Input = Primandproper_Platform_Billing_V1_GetPurchaseRequest
            /// Response type for "GetPurchase".
            internal typealias Output = Primandproper_Platform_Billing_V1_GetPurchaseResponse
            /// Descriptor for "GetPurchase".
            internal static let descriptor = GRPCCore.MethodDescriptor(
                service: GRPCCore.ServiceDescriptor(fullyQualifiedService: "primandproper.platform.billing.v1.BillingService"),
                method: "GetPurchase",
                type: .unary
            )
        }
        /// Namespace for "ListPurchases" metadata.
        internal enum ListPurchases: Sendable {
            /// Request type for "ListPurchases".
            internal typealias Input = Primandproper_Platform_Billing_V1_ListPurchasesRequest
            /// Response type for "ListPurchases".
            internal typealias Output = Primandproper_Platform_Billing_V1_ListPurchasesResponse
            /// Descriptor for "ListPurchases".
            internal static let descriptor = GRPCCore.MethodDescriptor(
                service: GRPCCore.ServiceDescriptor(fullyQualifiedService: "primandproper.platform.billing.v1.BillingService"),
                method: "ListPurchases",
                type: .unary
            )
        }
        /// Namespace for "ListPurchasesForAccount" metadata.
        internal enum ListPurchasesForAccount: Sendable {
            /// Request type for "ListPurchasesForAccount".
            internal typealias Input = Primandproper_Platform_Billing_V1_ListPurchasesForAccountRequest
            /// Response type for "ListPurchasesForAccount".
            internal typealias Output = Primandproper_Platform_Billing_V1_ListPurchasesForAccountResponse
            /// Descriptor for "ListPurchasesForAccount".
            internal static let descriptor = GRPCCore.MethodDescriptor(
                service: GRPCCore.ServiceDescriptor(fullyQualifiedService: "primandproper.platform.billing.v1.BillingService"),
                method: "ListPurchasesForAccount",
                type: .unary
            )
        }
        /// Namespace for "ArchivePurchase" metadata.
        internal enum ArchivePurchase: Sendable {
            /// Request type for "ArchivePurchase".
            internal typealias Input = Primandproper_Platform_Billing_V1_ArchivePurchaseRequest
            /// Response type for "ArchivePurchase".
            internal typealias Output = Primandproper_Platform_Billing_V1_ArchivePurchaseResponse
            /// Descriptor for "ArchivePurchase".
            internal static let descriptor = GRPCCore.MethodDescriptor(
                service: GRPCCore.ServiceDescriptor(fullyQualifiedService: "primandproper.platform.billing.v1.BillingService"),
                method: "ArchivePurchase",
                type: .unary
            )
        }
        /// Namespace for "GetTransaction" metadata.
        internal enum GetTransaction: Sendable {
            /// Request type for "GetTransaction".
            internal typealias Input = Primandproper_Platform_Billing_V1_GetTransactionRequest
            /// Response type for "GetTransaction".
            internal typealias Output = Primandproper_Platform_Billing_V1_GetTransactionResponse
            /// Descriptor for "GetTransaction".
            internal static let descriptor = GRPCCore.MethodDescriptor(
                service: GRPCCore.ServiceDescriptor(fullyQualifiedService: "primandproper.platform.billing.v1.BillingService"),
                method: "GetTransaction",
                type: .unary
            )
        }
        /// Namespace for "ListTransactions" metadata.
        internal enum ListTransactions: Sendable {
            /// Request type for "ListTransactions".
            internal typealias Input = Primandproper_Platform_Billing_V1_ListTransactionsRequest
            /// Response type for "ListTransactions".
            internal typealias Output = Primandproper_Platform_Billing_V1_ListTransactionsResponse
            /// Descriptor for "ListTransactions".
            internal static let descriptor = GRPCCore.MethodDescriptor(
                service: GRPCCore.ServiceDescriptor(fullyQualifiedService: "primandproper.platform.billing.v1.BillingService"),
                method: "ListTransactions",
                type: .unary
            )
        }
        /// Namespace for "ListTransactionsForAccount" metadata.
        internal enum ListTransactionsForAccount: Sendable {
            /// Request type for "ListTransactionsForAccount".
            internal typealias Input = Primandproper_Platform_Billing_V1_ListTransactionsForAccountRequest
            /// Response type for "ListTransactionsForAccount".
            internal typealias Output = Primandproper_Platform_Billing_V1_ListTransactionsForAccountResponse
            /// Descriptor for "ListTransactionsForAccount".
            internal static let descriptor = GRPCCore.MethodDescriptor(
                service: GRPCCore.ServiceDescriptor(fullyQualifiedService: "primandproper.platform.billing.v1.BillingService"),
                method: "ListTransactionsForAccount",
                type: .unary
            )
        }
        /// Namespace for "ArchiveTransaction" metadata.
        internal enum ArchiveTransaction: Sendable {
            /// Request type for "ArchiveTransaction".
            internal typealias Input = Primandproper_Platform_Billing_V1_ArchiveTransactionRequest
            /// Response type for "ArchiveTransaction".
            internal typealias Output = Primandproper_Platform_Billing_V1_ArchiveTransactionResponse
            /// Descriptor for "ArchiveTransaction".
            internal static let descriptor = GRPCCore.MethodDescriptor(
                service: GRPCCore.ServiceDescriptor(fullyQualifiedService: "primandproper.platform.billing.v1.BillingService"),
                method: "ArchiveTransaction",
                type: .unary
            )
        }
        /// Descriptors for all methods in the "primandproper.platform.billing.v1.BillingService" service.
        internal static let descriptors: [GRPCCore.MethodDescriptor] = [
            CreateProduct.descriptor,
            GetProduct.descriptor,
            ListProducts.descriptor,
            UpdateProduct.descriptor,
            ArchiveProduct.descriptor,
            GetSubscription.descriptor,
            ListSubscriptions.descriptor,
            ListSubscriptionsForAccount.descriptor,
            ListCurrentSubscriptions.descriptor,
            ArchiveSubscription.descriptor,
            GetPurchase.descriptor,
            ListPurchases.descriptor,
            ListPurchasesForAccount.descriptor,
            ArchivePurchase.descriptor,
            GetTransaction.descriptor,
            ListTransactions.descriptor,
            ListTransactionsForAccount.descriptor,
            ArchiveTransaction.descriptor
        ]
    }
}

@available(macOS 15.0, iOS 18.0, watchOS 11.0, tvOS 18.0, visionOS 2.0, *)
extension GRPCCore.ServiceDescriptor {
    /// Service descriptor for the "primandproper.platform.billing.v1.BillingService" service.
    internal static let primandproper_platform_billing_v1_BillingService = GRPCCore.ServiceDescriptor(fullyQualifiedService: "primandproper.platform.billing.v1.BillingService")
}

// MARK: primandproper.platform.billing.v1.BillingService (client)

@available(macOS 15.0, iOS 18.0, watchOS 11.0, tvOS 18.0, visionOS 2.0, *)
extension Primandproper_Platform_Billing_V1_BillingService {
    /// Generated client protocol for the "primandproper.platform.billing.v1.BillingService" service.
    ///
    /// You don't need to implement this protocol directly, use the generated
    /// implementation, ``Client``.
    ///
    /// > Source IDL Documentation:
    /// >
    /// > BillingService serves the record of what a deployment sells and what its
    /// > customers paid.
    /// > 
    /// > Eighteen RPCs over thirty store methods, and the shape of the subset is the
    /// > decision worth reading before the list. Twelve of the eighteen are reads,
    /// > because the writes on this table have a caller who is not a client: seven of
    /// > them are made by a processor callback or a checkout handler already inside the
    /// > consumer's own transaction, and they are named in this file's opening comment
    /// > along with why an RPC would break them. What is left on the write side is
    /// > administrative -- stocking and revising the catalog, and withdrawing a row
    /// > from each of the four tables.
    /// > 
    /// > Reads come in three kinds and each is a different grant. The catalog is
    /// > scope-wide and belongs to everybody in the scope. The account-keyed reads are
    /// > somebody's own, and they name an account the caller has to be permitted
    /// > against -- see billing/grpc's AccountAuthorizer, which is the half of
    /// > authorization a grant on the method cannot reach. The three unqualified list
    /// > reads are an operator's: they page every row in the scope and carry a
    /// > permission of their own, so that a consumer can hand out "read my invoices"
    /// > without handing out the customer ledger.
    internal protocol ClientProtocol: Sendable {
        /// Call the "CreateProduct" method.
        ///
        /// > Source IDL Documentation:
        /// >
        /// > The catalog: two reads any member of the scope may make, and three
        /// > administrative writes.
        ///
        /// - Parameters:
        ///   - request: A request containing a single `Primandproper_Platform_Billing_V1_CreateProductRequest` message.
        ///   - serializer: A serializer for `Primandproper_Platform_Billing_V1_CreateProductRequest` messages.
        ///   - deserializer: A deserializer for `Primandproper_Platform_Billing_V1_CreateProductResponse` messages.
        ///   - options: Options to apply to this RPC.
        ///   - handleResponse: A closure which handles the response and returns its result to
        ///       the caller. Returning from the closure will cancel the RPC if it hasn't
        ///       already finished.
        /// - Returns: The result of `handleResponse`.
        func createProduct<Result>(
            request: GRPCCore.ClientRequest<Primandproper_Platform_Billing_V1_CreateProductRequest>,
            serializer: some GRPCCore.MessageSerializer<Primandproper_Platform_Billing_V1_CreateProductRequest>,
            deserializer: some GRPCCore.MessageDeserializer<Primandproper_Platform_Billing_V1_CreateProductResponse>,
            options: GRPCCore.CallOptions,
            onResponse handleResponse: @Sendable @escaping (GRPCCore.ClientResponse<Primandproper_Platform_Billing_V1_CreateProductResponse>) async throws -> Result
        ) async throws -> Result where Result: Sendable

        /// Call the "GetProduct" method.
        ///
        /// - Parameters:
        ///   - request: A request containing a single `Primandproper_Platform_Billing_V1_GetProductRequest` message.
        ///   - serializer: A serializer for `Primandproper_Platform_Billing_V1_GetProductRequest` messages.
        ///   - deserializer: A deserializer for `Primandproper_Platform_Billing_V1_GetProductResponse` messages.
        ///   - options: Options to apply to this RPC.
        ///   - handleResponse: A closure which handles the response and returns its result to
        ///       the caller. Returning from the closure will cancel the RPC if it hasn't
        ///       already finished.
        /// - Returns: The result of `handleResponse`.
        func getProduct<Result>(
            request: GRPCCore.ClientRequest<Primandproper_Platform_Billing_V1_GetProductRequest>,
            serializer: some GRPCCore.MessageSerializer<Primandproper_Platform_Billing_V1_GetProductRequest>,
            deserializer: some GRPCCore.MessageDeserializer<Primandproper_Platform_Billing_V1_GetProductResponse>,
            options: GRPCCore.CallOptions,
            onResponse handleResponse: @Sendable @escaping (GRPCCore.ClientResponse<Primandproper_Platform_Billing_V1_GetProductResponse>) async throws -> Result
        ) async throws -> Result where Result: Sendable

        /// Call the "ListProducts" method.
        ///
        /// - Parameters:
        ///   - request: A request containing a single `Primandproper_Platform_Billing_V1_ListProductsRequest` message.
        ///   - serializer: A serializer for `Primandproper_Platform_Billing_V1_ListProductsRequest` messages.
        ///   - deserializer: A deserializer for `Primandproper_Platform_Billing_V1_ListProductsResponse` messages.
        ///   - options: Options to apply to this RPC.
        ///   - handleResponse: A closure which handles the response and returns its result to
        ///       the caller. Returning from the closure will cancel the RPC if it hasn't
        ///       already finished.
        /// - Returns: The result of `handleResponse`.
        func listProducts<Result>(
            request: GRPCCore.ClientRequest<Primandproper_Platform_Billing_V1_ListProductsRequest>,
            serializer: some GRPCCore.MessageSerializer<Primandproper_Platform_Billing_V1_ListProductsRequest>,
            deserializer: some GRPCCore.MessageDeserializer<Primandproper_Platform_Billing_V1_ListProductsResponse>,
            options: GRPCCore.CallOptions,
            onResponse handleResponse: @Sendable @escaping (GRPCCore.ClientResponse<Primandproper_Platform_Billing_V1_ListProductsResponse>) async throws -> Result
        ) async throws -> Result where Result: Sendable

        /// Call the "UpdateProduct" method.
        ///
        /// - Parameters:
        ///   - request: A request containing a single `Primandproper_Platform_Billing_V1_UpdateProductRequest` message.
        ///   - serializer: A serializer for `Primandproper_Platform_Billing_V1_UpdateProductRequest` messages.
        ///   - deserializer: A deserializer for `Primandproper_Platform_Billing_V1_UpdateProductResponse` messages.
        ///   - options: Options to apply to this RPC.
        ///   - handleResponse: A closure which handles the response and returns its result to
        ///       the caller. Returning from the closure will cancel the RPC if it hasn't
        ///       already finished.
        /// - Returns: The result of `handleResponse`.
        func updateProduct<Result>(
            request: GRPCCore.ClientRequest<Primandproper_Platform_Billing_V1_UpdateProductRequest>,
            serializer: some GRPCCore.MessageSerializer<Primandproper_Platform_Billing_V1_UpdateProductRequest>,
            deserializer: some GRPCCore.MessageDeserializer<Primandproper_Platform_Billing_V1_UpdateProductResponse>,
            options: GRPCCore.CallOptions,
            onResponse handleResponse: @Sendable @escaping (GRPCCore.ClientResponse<Primandproper_Platform_Billing_V1_UpdateProductResponse>) async throws -> Result
        ) async throws -> Result where Result: Sendable

        /// Call the "ArchiveProduct" method.
        ///
        /// - Parameters:
        ///   - request: A request containing a single `Primandproper_Platform_Billing_V1_ArchiveProductRequest` message.
        ///   - serializer: A serializer for `Primandproper_Platform_Billing_V1_ArchiveProductRequest` messages.
        ///   - deserializer: A deserializer for `Primandproper_Platform_Billing_V1_ArchiveProductResponse` messages.
        ///   - options: Options to apply to this RPC.
        ///   - handleResponse: A closure which handles the response and returns its result to
        ///       the caller. Returning from the closure will cancel the RPC if it hasn't
        ///       already finished.
        /// - Returns: The result of `handleResponse`.
        func archiveProduct<Result>(
            request: GRPCCore.ClientRequest<Primandproper_Platform_Billing_V1_ArchiveProductRequest>,
            serializer: some GRPCCore.MessageSerializer<Primandproper_Platform_Billing_V1_ArchiveProductRequest>,
            deserializer: some GRPCCore.MessageDeserializer<Primandproper_Platform_Billing_V1_ArchiveProductResponse>,
            options: GRPCCore.CallOptions,
            onResponse handleResponse: @Sendable @escaping (GRPCCore.ClientResponse<Primandproper_Platform_Billing_V1_ArchiveProductResponse>) async throws -> Result
        ) async throws -> Result where Result: Sendable

        /// Call the "GetSubscription" method.
        ///
        /// > Source IDL Documentation:
        /// >
        /// > The recurring half. ListCurrentSubscriptions is the one an entitlement
        /// > screen reads: it pages the agreements whose paid period covers now, and
        /// > deliberately does not filter on status, because which status leaves an
        /// > account entitled is the consumer's ruling.
        ///
        /// - Parameters:
        ///   - request: A request containing a single `Primandproper_Platform_Billing_V1_GetSubscriptionRequest` message.
        ///   - serializer: A serializer for `Primandproper_Platform_Billing_V1_GetSubscriptionRequest` messages.
        ///   - deserializer: A deserializer for `Primandproper_Platform_Billing_V1_GetSubscriptionResponse` messages.
        ///   - options: Options to apply to this RPC.
        ///   - handleResponse: A closure which handles the response and returns its result to
        ///       the caller. Returning from the closure will cancel the RPC if it hasn't
        ///       already finished.
        /// - Returns: The result of `handleResponse`.
        func getSubscription<Result>(
            request: GRPCCore.ClientRequest<Primandproper_Platform_Billing_V1_GetSubscriptionRequest>,
            serializer: some GRPCCore.MessageSerializer<Primandproper_Platform_Billing_V1_GetSubscriptionRequest>,
            deserializer: some GRPCCore.MessageDeserializer<Primandproper_Platform_Billing_V1_GetSubscriptionResponse>,
            options: GRPCCore.CallOptions,
            onResponse handleResponse: @Sendable @escaping (GRPCCore.ClientResponse<Primandproper_Platform_Billing_V1_GetSubscriptionResponse>) async throws -> Result
        ) async throws -> Result where Result: Sendable

        /// Call the "ListSubscriptions" method.
        ///
        /// - Parameters:
        ///   - request: A request containing a single `Primandproper_Platform_Billing_V1_ListSubscriptionsRequest` message.
        ///   - serializer: A serializer for `Primandproper_Platform_Billing_V1_ListSubscriptionsRequest` messages.
        ///   - deserializer: A deserializer for `Primandproper_Platform_Billing_V1_ListSubscriptionsResponse` messages.
        ///   - options: Options to apply to this RPC.
        ///   - handleResponse: A closure which handles the response and returns its result to
        ///       the caller. Returning from the closure will cancel the RPC if it hasn't
        ///       already finished.
        /// - Returns: The result of `handleResponse`.
        func listSubscriptions<Result>(
            request: GRPCCore.ClientRequest<Primandproper_Platform_Billing_V1_ListSubscriptionsRequest>,
            serializer: some GRPCCore.MessageSerializer<Primandproper_Platform_Billing_V1_ListSubscriptionsRequest>,
            deserializer: some GRPCCore.MessageDeserializer<Primandproper_Platform_Billing_V1_ListSubscriptionsResponse>,
            options: GRPCCore.CallOptions,
            onResponse handleResponse: @Sendable @escaping (GRPCCore.ClientResponse<Primandproper_Platform_Billing_V1_ListSubscriptionsResponse>) async throws -> Result
        ) async throws -> Result where Result: Sendable

        /// Call the "ListSubscriptionsForAccount" method.
        ///
        /// - Parameters:
        ///   - request: A request containing a single `Primandproper_Platform_Billing_V1_ListSubscriptionsForAccountRequest` message.
        ///   - serializer: A serializer for `Primandproper_Platform_Billing_V1_ListSubscriptionsForAccountRequest` messages.
        ///   - deserializer: A deserializer for `Primandproper_Platform_Billing_V1_ListSubscriptionsForAccountResponse` messages.
        ///   - options: Options to apply to this RPC.
        ///   - handleResponse: A closure which handles the response and returns its result to
        ///       the caller. Returning from the closure will cancel the RPC if it hasn't
        ///       already finished.
        /// - Returns: The result of `handleResponse`.
        func listSubscriptionsForAccount<Result>(
            request: GRPCCore.ClientRequest<Primandproper_Platform_Billing_V1_ListSubscriptionsForAccountRequest>,
            serializer: some GRPCCore.MessageSerializer<Primandproper_Platform_Billing_V1_ListSubscriptionsForAccountRequest>,
            deserializer: some GRPCCore.MessageDeserializer<Primandproper_Platform_Billing_V1_ListSubscriptionsForAccountResponse>,
            options: GRPCCore.CallOptions,
            onResponse handleResponse: @Sendable @escaping (GRPCCore.ClientResponse<Primandproper_Platform_Billing_V1_ListSubscriptionsForAccountResponse>) async throws -> Result
        ) async throws -> Result where Result: Sendable

        /// Call the "ListCurrentSubscriptions" method.
        ///
        /// - Parameters:
        ///   - request: A request containing a single `Primandproper_Platform_Billing_V1_ListCurrentSubscriptionsRequest` message.
        ///   - serializer: A serializer for `Primandproper_Platform_Billing_V1_ListCurrentSubscriptionsRequest` messages.
        ///   - deserializer: A deserializer for `Primandproper_Platform_Billing_V1_ListCurrentSubscriptionsResponse` messages.
        ///   - options: Options to apply to this RPC.
        ///   - handleResponse: A closure which handles the response and returns its result to
        ///       the caller. Returning from the closure will cancel the RPC if it hasn't
        ///       already finished.
        /// - Returns: The result of `handleResponse`.
        func listCurrentSubscriptions<Result>(
            request: GRPCCore.ClientRequest<Primandproper_Platform_Billing_V1_ListCurrentSubscriptionsRequest>,
            serializer: some GRPCCore.MessageSerializer<Primandproper_Platform_Billing_V1_ListCurrentSubscriptionsRequest>,
            deserializer: some GRPCCore.MessageDeserializer<Primandproper_Platform_Billing_V1_ListCurrentSubscriptionsResponse>,
            options: GRPCCore.CallOptions,
            onResponse handleResponse: @Sendable @escaping (GRPCCore.ClientResponse<Primandproper_Platform_Billing_V1_ListCurrentSubscriptionsResponse>) async throws -> Result
        ) async throws -> Result where Result: Sendable

        /// Call the "ArchiveSubscription" method.
        ///
        /// - Parameters:
        ///   - request: A request containing a single `Primandproper_Platform_Billing_V1_ArchiveSubscriptionRequest` message.
        ///   - serializer: A serializer for `Primandproper_Platform_Billing_V1_ArchiveSubscriptionRequest` messages.
        ///   - deserializer: A deserializer for `Primandproper_Platform_Billing_V1_ArchiveSubscriptionResponse` messages.
        ///   - options: Options to apply to this RPC.
        ///   - handleResponse: A closure which handles the response and returns its result to
        ///       the caller. Returning from the closure will cancel the RPC if it hasn't
        ///       already finished.
        /// - Returns: The result of `handleResponse`.
        func archiveSubscription<Result>(
            request: GRPCCore.ClientRequest<Primandproper_Platform_Billing_V1_ArchiveSubscriptionRequest>,
            serializer: some GRPCCore.MessageSerializer<Primandproper_Platform_Billing_V1_ArchiveSubscriptionRequest>,
            deserializer: some GRPCCore.MessageDeserializer<Primandproper_Platform_Billing_V1_ArchiveSubscriptionResponse>,
            options: GRPCCore.CallOptions,
            onResponse handleResponse: @Sendable @escaping (GRPCCore.ClientResponse<Primandproper_Platform_Billing_V1_ArchiveSubscriptionResponse>) async throws -> Result
        ) async throws -> Result where Result: Sendable

        /// Call the "GetPurchase" method.
        ///
        /// > Source IDL Documentation:
        /// >
        /// > The one-time half.
        ///
        /// - Parameters:
        ///   - request: A request containing a single `Primandproper_Platform_Billing_V1_GetPurchaseRequest` message.
        ///   - serializer: A serializer for `Primandproper_Platform_Billing_V1_GetPurchaseRequest` messages.
        ///   - deserializer: A deserializer for `Primandproper_Platform_Billing_V1_GetPurchaseResponse` messages.
        ///   - options: Options to apply to this RPC.
        ///   - handleResponse: A closure which handles the response and returns its result to
        ///       the caller. Returning from the closure will cancel the RPC if it hasn't
        ///       already finished.
        /// - Returns: The result of `handleResponse`.
        func getPurchase<Result>(
            request: GRPCCore.ClientRequest<Primandproper_Platform_Billing_V1_GetPurchaseRequest>,
            serializer: some GRPCCore.MessageSerializer<Primandproper_Platform_Billing_V1_GetPurchaseRequest>,
            deserializer: some GRPCCore.MessageDeserializer<Primandproper_Platform_Billing_V1_GetPurchaseResponse>,
            options: GRPCCore.CallOptions,
            onResponse handleResponse: @Sendable @escaping (GRPCCore.ClientResponse<Primandproper_Platform_Billing_V1_GetPurchaseResponse>) async throws -> Result
        ) async throws -> Result where Result: Sendable

        /// Call the "ListPurchases" method.
        ///
        /// - Parameters:
        ///   - request: A request containing a single `Primandproper_Platform_Billing_V1_ListPurchasesRequest` message.
        ///   - serializer: A serializer for `Primandproper_Platform_Billing_V1_ListPurchasesRequest` messages.
        ///   - deserializer: A deserializer for `Primandproper_Platform_Billing_V1_ListPurchasesResponse` messages.
        ///   - options: Options to apply to this RPC.
        ///   - handleResponse: A closure which handles the response and returns its result to
        ///       the caller. Returning from the closure will cancel the RPC if it hasn't
        ///       already finished.
        /// - Returns: The result of `handleResponse`.
        func listPurchases<Result>(
            request: GRPCCore.ClientRequest<Primandproper_Platform_Billing_V1_ListPurchasesRequest>,
            serializer: some GRPCCore.MessageSerializer<Primandproper_Platform_Billing_V1_ListPurchasesRequest>,
            deserializer: some GRPCCore.MessageDeserializer<Primandproper_Platform_Billing_V1_ListPurchasesResponse>,
            options: GRPCCore.CallOptions,
            onResponse handleResponse: @Sendable @escaping (GRPCCore.ClientResponse<Primandproper_Platform_Billing_V1_ListPurchasesResponse>) async throws -> Result
        ) async throws -> Result where Result: Sendable

        /// Call the "ListPurchasesForAccount" method.
        ///
        /// - Parameters:
        ///   - request: A request containing a single `Primandproper_Platform_Billing_V1_ListPurchasesForAccountRequest` message.
        ///   - serializer: A serializer for `Primandproper_Platform_Billing_V1_ListPurchasesForAccountRequest` messages.
        ///   - deserializer: A deserializer for `Primandproper_Platform_Billing_V1_ListPurchasesForAccountResponse` messages.
        ///   - options: Options to apply to this RPC.
        ///   - handleResponse: A closure which handles the response and returns its result to
        ///       the caller. Returning from the closure will cancel the RPC if it hasn't
        ///       already finished.
        /// - Returns: The result of `handleResponse`.
        func listPurchasesForAccount<Result>(
            request: GRPCCore.ClientRequest<Primandproper_Platform_Billing_V1_ListPurchasesForAccountRequest>,
            serializer: some GRPCCore.MessageSerializer<Primandproper_Platform_Billing_V1_ListPurchasesForAccountRequest>,
            deserializer: some GRPCCore.MessageDeserializer<Primandproper_Platform_Billing_V1_ListPurchasesForAccountResponse>,
            options: GRPCCore.CallOptions,
            onResponse handleResponse: @Sendable @escaping (GRPCCore.ClientResponse<Primandproper_Platform_Billing_V1_ListPurchasesForAccountResponse>) async throws -> Result
        ) async throws -> Result where Result: Sendable

        /// Call the "ArchivePurchase" method.
        ///
        /// - Parameters:
        ///   - request: A request containing a single `Primandproper_Platform_Billing_V1_ArchivePurchaseRequest` message.
        ///   - serializer: A serializer for `Primandproper_Platform_Billing_V1_ArchivePurchaseRequest` messages.
        ///   - deserializer: A deserializer for `Primandproper_Platform_Billing_V1_ArchivePurchaseResponse` messages.
        ///   - options: Options to apply to this RPC.
        ///   - handleResponse: A closure which handles the response and returns its result to
        ///       the caller. Returning from the closure will cancel the RPC if it hasn't
        ///       already finished.
        /// - Returns: The result of `handleResponse`.
        func archivePurchase<Result>(
            request: GRPCCore.ClientRequest<Primandproper_Platform_Billing_V1_ArchivePurchaseRequest>,
            serializer: some GRPCCore.MessageSerializer<Primandproper_Platform_Billing_V1_ArchivePurchaseRequest>,
            deserializer: some GRPCCore.MessageDeserializer<Primandproper_Platform_Billing_V1_ArchivePurchaseResponse>,
            options: GRPCCore.CallOptions,
            onResponse handleResponse: @Sendable @escaping (GRPCCore.ClientResponse<Primandproper_Platform_Billing_V1_ArchivePurchaseResponse>) async throws -> Result
        ) async throws -> Result where Result: Sendable

        /// Call the "GetTransaction" method.
        ///
        /// > Source IDL Documentation:
        /// >
        /// > The ledger.
        ///
        /// - Parameters:
        ///   - request: A request containing a single `Primandproper_Platform_Billing_V1_GetTransactionRequest` message.
        ///   - serializer: A serializer for `Primandproper_Platform_Billing_V1_GetTransactionRequest` messages.
        ///   - deserializer: A deserializer for `Primandproper_Platform_Billing_V1_GetTransactionResponse` messages.
        ///   - options: Options to apply to this RPC.
        ///   - handleResponse: A closure which handles the response and returns its result to
        ///       the caller. Returning from the closure will cancel the RPC if it hasn't
        ///       already finished.
        /// - Returns: The result of `handleResponse`.
        func getTransaction<Result>(
            request: GRPCCore.ClientRequest<Primandproper_Platform_Billing_V1_GetTransactionRequest>,
            serializer: some GRPCCore.MessageSerializer<Primandproper_Platform_Billing_V1_GetTransactionRequest>,
            deserializer: some GRPCCore.MessageDeserializer<Primandproper_Platform_Billing_V1_GetTransactionResponse>,
            options: GRPCCore.CallOptions,
            onResponse handleResponse: @Sendable @escaping (GRPCCore.ClientResponse<Primandproper_Platform_Billing_V1_GetTransactionResponse>) async throws -> Result
        ) async throws -> Result where Result: Sendable

        /// Call the "ListTransactions" method.
        ///
        /// - Parameters:
        ///   - request: A request containing a single `Primandproper_Platform_Billing_V1_ListTransactionsRequest` message.
        ///   - serializer: A serializer for `Primandproper_Platform_Billing_V1_ListTransactionsRequest` messages.
        ///   - deserializer: A deserializer for `Primandproper_Platform_Billing_V1_ListTransactionsResponse` messages.
        ///   - options: Options to apply to this RPC.
        ///   - handleResponse: A closure which handles the response and returns its result to
        ///       the caller. Returning from the closure will cancel the RPC if it hasn't
        ///       already finished.
        /// - Returns: The result of `handleResponse`.
        func listTransactions<Result>(
            request: GRPCCore.ClientRequest<Primandproper_Platform_Billing_V1_ListTransactionsRequest>,
            serializer: some GRPCCore.MessageSerializer<Primandproper_Platform_Billing_V1_ListTransactionsRequest>,
            deserializer: some GRPCCore.MessageDeserializer<Primandproper_Platform_Billing_V1_ListTransactionsResponse>,
            options: GRPCCore.CallOptions,
            onResponse handleResponse: @Sendable @escaping (GRPCCore.ClientResponse<Primandproper_Platform_Billing_V1_ListTransactionsResponse>) async throws -> Result
        ) async throws -> Result where Result: Sendable

        /// Call the "ListTransactionsForAccount" method.
        ///
        /// - Parameters:
        ///   - request: A request containing a single `Primandproper_Platform_Billing_V1_ListTransactionsForAccountRequest` message.
        ///   - serializer: A serializer for `Primandproper_Platform_Billing_V1_ListTransactionsForAccountRequest` messages.
        ///   - deserializer: A deserializer for `Primandproper_Platform_Billing_V1_ListTransactionsForAccountResponse` messages.
        ///   - options: Options to apply to this RPC.
        ///   - handleResponse: A closure which handles the response and returns its result to
        ///       the caller. Returning from the closure will cancel the RPC if it hasn't
        ///       already finished.
        /// - Returns: The result of `handleResponse`.
        func listTransactionsForAccount<Result>(
            request: GRPCCore.ClientRequest<Primandproper_Platform_Billing_V1_ListTransactionsForAccountRequest>,
            serializer: some GRPCCore.MessageSerializer<Primandproper_Platform_Billing_V1_ListTransactionsForAccountRequest>,
            deserializer: some GRPCCore.MessageDeserializer<Primandproper_Platform_Billing_V1_ListTransactionsForAccountResponse>,
            options: GRPCCore.CallOptions,
            onResponse handleResponse: @Sendable @escaping (GRPCCore.ClientResponse<Primandproper_Platform_Billing_V1_ListTransactionsForAccountResponse>) async throws -> Result
        ) async throws -> Result where Result: Sendable

        /// Call the "ArchiveTransaction" method.
        ///
        /// - Parameters:
        ///   - request: A request containing a single `Primandproper_Platform_Billing_V1_ArchiveTransactionRequest` message.
        ///   - serializer: A serializer for `Primandproper_Platform_Billing_V1_ArchiveTransactionRequest` messages.
        ///   - deserializer: A deserializer for `Primandproper_Platform_Billing_V1_ArchiveTransactionResponse` messages.
        ///   - options: Options to apply to this RPC.
        ///   - handleResponse: A closure which handles the response and returns its result to
        ///       the caller. Returning from the closure will cancel the RPC if it hasn't
        ///       already finished.
        /// - Returns: The result of `handleResponse`.
        func archiveTransaction<Result>(
            request: GRPCCore.ClientRequest<Primandproper_Platform_Billing_V1_ArchiveTransactionRequest>,
            serializer: some GRPCCore.MessageSerializer<Primandproper_Platform_Billing_V1_ArchiveTransactionRequest>,
            deserializer: some GRPCCore.MessageDeserializer<Primandproper_Platform_Billing_V1_ArchiveTransactionResponse>,
            options: GRPCCore.CallOptions,
            onResponse handleResponse: @Sendable @escaping (GRPCCore.ClientResponse<Primandproper_Platform_Billing_V1_ArchiveTransactionResponse>) async throws -> Result
        ) async throws -> Result where Result: Sendable
    }

    /// Generated client for the "primandproper.platform.billing.v1.BillingService" service.
    ///
    /// The ``Client`` provides an implementation of ``ClientProtocol`` which wraps
    /// a `GRPCCore.GRPCCClient`. The underlying `GRPCClient` provides the long-lived
    /// means of communication with the remote peer.
    ///
    /// > Source IDL Documentation:
    /// >
    /// > BillingService serves the record of what a deployment sells and what its
    /// > customers paid.
    /// > 
    /// > Eighteen RPCs over thirty store methods, and the shape of the subset is the
    /// > decision worth reading before the list. Twelve of the eighteen are reads,
    /// > because the writes on this table have a caller who is not a client: seven of
    /// > them are made by a processor callback or a checkout handler already inside the
    /// > consumer's own transaction, and they are named in this file's opening comment
    /// > along with why an RPC would break them. What is left on the write side is
    /// > administrative -- stocking and revising the catalog, and withdrawing a row
    /// > from each of the four tables.
    /// > 
    /// > Reads come in three kinds and each is a different grant. The catalog is
    /// > scope-wide and belongs to everybody in the scope. The account-keyed reads are
    /// > somebody's own, and they name an account the caller has to be permitted
    /// > against -- see billing/grpc's AccountAuthorizer, which is the half of
    /// > authorization a grant on the method cannot reach. The three unqualified list
    /// > reads are an operator's: they page every row in the scope and carry a
    /// > permission of their own, so that a consumer can hand out "read my invoices"
    /// > without handing out the customer ledger.
    internal struct Client<Transport>: ClientProtocol where Transport: GRPCCore.ClientTransport {
        private let client: GRPCCore.GRPCClient<Transport>

        /// Creates a new client wrapping the provided `GRPCCore.GRPCClient`.
        ///
        /// - Parameters:
        ///   - client: A `GRPCCore.GRPCClient` providing a communication channel to the service.
        internal init(wrapping client: GRPCCore.GRPCClient<Transport>) {
            self.client = client
        }

        /// Call the "CreateProduct" method.
        ///
        /// > Source IDL Documentation:
        /// >
        /// > The catalog: two reads any member of the scope may make, and three
        /// > administrative writes.
        ///
        /// - Parameters:
        ///   - request: A request containing a single `Primandproper_Platform_Billing_V1_CreateProductRequest` message.
        ///   - serializer: A serializer for `Primandproper_Platform_Billing_V1_CreateProductRequest` messages.
        ///   - deserializer: A deserializer for `Primandproper_Platform_Billing_V1_CreateProductResponse` messages.
        ///   - options: Options to apply to this RPC.
        ///   - handleResponse: A closure which handles the response and returns its result to
        ///       the caller. Returning from the closure will cancel the RPC if it hasn't
        ///       already finished.
        /// - Returns: The result of `handleResponse`.
        internal func createProduct<Result>(
            request: GRPCCore.ClientRequest<Primandproper_Platform_Billing_V1_CreateProductRequest>,
            serializer: some GRPCCore.MessageSerializer<Primandproper_Platform_Billing_V1_CreateProductRequest>,
            deserializer: some GRPCCore.MessageDeserializer<Primandproper_Platform_Billing_V1_CreateProductResponse>,
            options: GRPCCore.CallOptions = .defaults,
            onResponse handleResponse: @Sendable @escaping (GRPCCore.ClientResponse<Primandproper_Platform_Billing_V1_CreateProductResponse>) async throws -> Result = { response in
                try response.message
            }
        ) async throws -> Result where Result: Sendable {
            try await self.client.unary(
                request: request,
                descriptor: Primandproper_Platform_Billing_V1_BillingService.Method.CreateProduct.descriptor,
                serializer: serializer,
                deserializer: deserializer,
                options: options,
                onResponse: handleResponse
            )
        }

        /// Call the "GetProduct" method.
        ///
        /// - Parameters:
        ///   - request: A request containing a single `Primandproper_Platform_Billing_V1_GetProductRequest` message.
        ///   - serializer: A serializer for `Primandproper_Platform_Billing_V1_GetProductRequest` messages.
        ///   - deserializer: A deserializer for `Primandproper_Platform_Billing_V1_GetProductResponse` messages.
        ///   - options: Options to apply to this RPC.
        ///   - handleResponse: A closure which handles the response and returns its result to
        ///       the caller. Returning from the closure will cancel the RPC if it hasn't
        ///       already finished.
        /// - Returns: The result of `handleResponse`.
        internal func getProduct<Result>(
            request: GRPCCore.ClientRequest<Primandproper_Platform_Billing_V1_GetProductRequest>,
            serializer: some GRPCCore.MessageSerializer<Primandproper_Platform_Billing_V1_GetProductRequest>,
            deserializer: some GRPCCore.MessageDeserializer<Primandproper_Platform_Billing_V1_GetProductResponse>,
            options: GRPCCore.CallOptions = .defaults,
            onResponse handleResponse: @Sendable @escaping (GRPCCore.ClientResponse<Primandproper_Platform_Billing_V1_GetProductResponse>) async throws -> Result = { response in
                try response.message
            }
        ) async throws -> Result where Result: Sendable {
            try await self.client.unary(
                request: request,
                descriptor: Primandproper_Platform_Billing_V1_BillingService.Method.GetProduct.descriptor,
                serializer: serializer,
                deserializer: deserializer,
                options: options,
                onResponse: handleResponse
            )
        }

        /// Call the "ListProducts" method.
        ///
        /// - Parameters:
        ///   - request: A request containing a single `Primandproper_Platform_Billing_V1_ListProductsRequest` message.
        ///   - serializer: A serializer for `Primandproper_Platform_Billing_V1_ListProductsRequest` messages.
        ///   - deserializer: A deserializer for `Primandproper_Platform_Billing_V1_ListProductsResponse` messages.
        ///   - options: Options to apply to this RPC.
        ///   - handleResponse: A closure which handles the response and returns its result to
        ///       the caller. Returning from the closure will cancel the RPC if it hasn't
        ///       already finished.
        /// - Returns: The result of `handleResponse`.
        internal func listProducts<Result>(
            request: GRPCCore.ClientRequest<Primandproper_Platform_Billing_V1_ListProductsRequest>,
            serializer: some GRPCCore.MessageSerializer<Primandproper_Platform_Billing_V1_ListProductsRequest>,
            deserializer: some GRPCCore.MessageDeserializer<Primandproper_Platform_Billing_V1_ListProductsResponse>,
            options: GRPCCore.CallOptions = .defaults,
            onResponse handleResponse: @Sendable @escaping (GRPCCore.ClientResponse<Primandproper_Platform_Billing_V1_ListProductsResponse>) async throws -> Result = { response in
                try response.message
            }
        ) async throws -> Result where Result: Sendable {
            try await self.client.unary(
                request: request,
                descriptor: Primandproper_Platform_Billing_V1_BillingService.Method.ListProducts.descriptor,
                serializer: serializer,
                deserializer: deserializer,
                options: options,
                onResponse: handleResponse
            )
        }

        /// Call the "UpdateProduct" method.
        ///
        /// - Parameters:
        ///   - request: A request containing a single `Primandproper_Platform_Billing_V1_UpdateProductRequest` message.
        ///   - serializer: A serializer for `Primandproper_Platform_Billing_V1_UpdateProductRequest` messages.
        ///   - deserializer: A deserializer for `Primandproper_Platform_Billing_V1_UpdateProductResponse` messages.
        ///   - options: Options to apply to this RPC.
        ///   - handleResponse: A closure which handles the response and returns its result to
        ///       the caller. Returning from the closure will cancel the RPC if it hasn't
        ///       already finished.
        /// - Returns: The result of `handleResponse`.
        internal func updateProduct<Result>(
            request: GRPCCore.ClientRequest<Primandproper_Platform_Billing_V1_UpdateProductRequest>,
            serializer: some GRPCCore.MessageSerializer<Primandproper_Platform_Billing_V1_UpdateProductRequest>,
            deserializer: some GRPCCore.MessageDeserializer<Primandproper_Platform_Billing_V1_UpdateProductResponse>,
            options: GRPCCore.CallOptions = .defaults,
            onResponse handleResponse: @Sendable @escaping (GRPCCore.ClientResponse<Primandproper_Platform_Billing_V1_UpdateProductResponse>) async throws -> Result = { response in
                try response.message
            }
        ) async throws -> Result where Result: Sendable {
            try await self.client.unary(
                request: request,
                descriptor: Primandproper_Platform_Billing_V1_BillingService.Method.UpdateProduct.descriptor,
                serializer: serializer,
                deserializer: deserializer,
                options: options,
                onResponse: handleResponse
            )
        }

        /// Call the "ArchiveProduct" method.
        ///
        /// - Parameters:
        ///   - request: A request containing a single `Primandproper_Platform_Billing_V1_ArchiveProductRequest` message.
        ///   - serializer: A serializer for `Primandproper_Platform_Billing_V1_ArchiveProductRequest` messages.
        ///   - deserializer: A deserializer for `Primandproper_Platform_Billing_V1_ArchiveProductResponse` messages.
        ///   - options: Options to apply to this RPC.
        ///   - handleResponse: A closure which handles the response and returns its result to
        ///       the caller. Returning from the closure will cancel the RPC if it hasn't
        ///       already finished.
        /// - Returns: The result of `handleResponse`.
        internal func archiveProduct<Result>(
            request: GRPCCore.ClientRequest<Primandproper_Platform_Billing_V1_ArchiveProductRequest>,
            serializer: some GRPCCore.MessageSerializer<Primandproper_Platform_Billing_V1_ArchiveProductRequest>,
            deserializer: some GRPCCore.MessageDeserializer<Primandproper_Platform_Billing_V1_ArchiveProductResponse>,
            options: GRPCCore.CallOptions = .defaults,
            onResponse handleResponse: @Sendable @escaping (GRPCCore.ClientResponse<Primandproper_Platform_Billing_V1_ArchiveProductResponse>) async throws -> Result = { response in
                try response.message
            }
        ) async throws -> Result where Result: Sendable {
            try await self.client.unary(
                request: request,
                descriptor: Primandproper_Platform_Billing_V1_BillingService.Method.ArchiveProduct.descriptor,
                serializer: serializer,
                deserializer: deserializer,
                options: options,
                onResponse: handleResponse
            )
        }

        /// Call the "GetSubscription" method.
        ///
        /// > Source IDL Documentation:
        /// >
        /// > The recurring half. ListCurrentSubscriptions is the one an entitlement
        /// > screen reads: it pages the agreements whose paid period covers now, and
        /// > deliberately does not filter on status, because which status leaves an
        /// > account entitled is the consumer's ruling.
        ///
        /// - Parameters:
        ///   - request: A request containing a single `Primandproper_Platform_Billing_V1_GetSubscriptionRequest` message.
        ///   - serializer: A serializer for `Primandproper_Platform_Billing_V1_GetSubscriptionRequest` messages.
        ///   - deserializer: A deserializer for `Primandproper_Platform_Billing_V1_GetSubscriptionResponse` messages.
        ///   - options: Options to apply to this RPC.
        ///   - handleResponse: A closure which handles the response and returns its result to
        ///       the caller. Returning from the closure will cancel the RPC if it hasn't
        ///       already finished.
        /// - Returns: The result of `handleResponse`.
        internal func getSubscription<Result>(
            request: GRPCCore.ClientRequest<Primandproper_Platform_Billing_V1_GetSubscriptionRequest>,
            serializer: some GRPCCore.MessageSerializer<Primandproper_Platform_Billing_V1_GetSubscriptionRequest>,
            deserializer: some GRPCCore.MessageDeserializer<Primandproper_Platform_Billing_V1_GetSubscriptionResponse>,
            options: GRPCCore.CallOptions = .defaults,
            onResponse handleResponse: @Sendable @escaping (GRPCCore.ClientResponse<Primandproper_Platform_Billing_V1_GetSubscriptionResponse>) async throws -> Result = { response in
                try response.message
            }
        ) async throws -> Result where Result: Sendable {
            try await self.client.unary(
                request: request,
                descriptor: Primandproper_Platform_Billing_V1_BillingService.Method.GetSubscription.descriptor,
                serializer: serializer,
                deserializer: deserializer,
                options: options,
                onResponse: handleResponse
            )
        }

        /// Call the "ListSubscriptions" method.
        ///
        /// - Parameters:
        ///   - request: A request containing a single `Primandproper_Platform_Billing_V1_ListSubscriptionsRequest` message.
        ///   - serializer: A serializer for `Primandproper_Platform_Billing_V1_ListSubscriptionsRequest` messages.
        ///   - deserializer: A deserializer for `Primandproper_Platform_Billing_V1_ListSubscriptionsResponse` messages.
        ///   - options: Options to apply to this RPC.
        ///   - handleResponse: A closure which handles the response and returns its result to
        ///       the caller. Returning from the closure will cancel the RPC if it hasn't
        ///       already finished.
        /// - Returns: The result of `handleResponse`.
        internal func listSubscriptions<Result>(
            request: GRPCCore.ClientRequest<Primandproper_Platform_Billing_V1_ListSubscriptionsRequest>,
            serializer: some GRPCCore.MessageSerializer<Primandproper_Platform_Billing_V1_ListSubscriptionsRequest>,
            deserializer: some GRPCCore.MessageDeserializer<Primandproper_Platform_Billing_V1_ListSubscriptionsResponse>,
            options: GRPCCore.CallOptions = .defaults,
            onResponse handleResponse: @Sendable @escaping (GRPCCore.ClientResponse<Primandproper_Platform_Billing_V1_ListSubscriptionsResponse>) async throws -> Result = { response in
                try response.message
            }
        ) async throws -> Result where Result: Sendable {
            try await self.client.unary(
                request: request,
                descriptor: Primandproper_Platform_Billing_V1_BillingService.Method.ListSubscriptions.descriptor,
                serializer: serializer,
                deserializer: deserializer,
                options: options,
                onResponse: handleResponse
            )
        }

        /// Call the "ListSubscriptionsForAccount" method.
        ///
        /// - Parameters:
        ///   - request: A request containing a single `Primandproper_Platform_Billing_V1_ListSubscriptionsForAccountRequest` message.
        ///   - serializer: A serializer for `Primandproper_Platform_Billing_V1_ListSubscriptionsForAccountRequest` messages.
        ///   - deserializer: A deserializer for `Primandproper_Platform_Billing_V1_ListSubscriptionsForAccountResponse` messages.
        ///   - options: Options to apply to this RPC.
        ///   - handleResponse: A closure which handles the response and returns its result to
        ///       the caller. Returning from the closure will cancel the RPC if it hasn't
        ///       already finished.
        /// - Returns: The result of `handleResponse`.
        internal func listSubscriptionsForAccount<Result>(
            request: GRPCCore.ClientRequest<Primandproper_Platform_Billing_V1_ListSubscriptionsForAccountRequest>,
            serializer: some GRPCCore.MessageSerializer<Primandproper_Platform_Billing_V1_ListSubscriptionsForAccountRequest>,
            deserializer: some GRPCCore.MessageDeserializer<Primandproper_Platform_Billing_V1_ListSubscriptionsForAccountResponse>,
            options: GRPCCore.CallOptions = .defaults,
            onResponse handleResponse: @Sendable @escaping (GRPCCore.ClientResponse<Primandproper_Platform_Billing_V1_ListSubscriptionsForAccountResponse>) async throws -> Result = { response in
                try response.message
            }
        ) async throws -> Result where Result: Sendable {
            try await self.client.unary(
                request: request,
                descriptor: Primandproper_Platform_Billing_V1_BillingService.Method.ListSubscriptionsForAccount.descriptor,
                serializer: serializer,
                deserializer: deserializer,
                options: options,
                onResponse: handleResponse
            )
        }

        /// Call the "ListCurrentSubscriptions" method.
        ///
        /// - Parameters:
        ///   - request: A request containing a single `Primandproper_Platform_Billing_V1_ListCurrentSubscriptionsRequest` message.
        ///   - serializer: A serializer for `Primandproper_Platform_Billing_V1_ListCurrentSubscriptionsRequest` messages.
        ///   - deserializer: A deserializer for `Primandproper_Platform_Billing_V1_ListCurrentSubscriptionsResponse` messages.
        ///   - options: Options to apply to this RPC.
        ///   - handleResponse: A closure which handles the response and returns its result to
        ///       the caller. Returning from the closure will cancel the RPC if it hasn't
        ///       already finished.
        /// - Returns: The result of `handleResponse`.
        internal func listCurrentSubscriptions<Result>(
            request: GRPCCore.ClientRequest<Primandproper_Platform_Billing_V1_ListCurrentSubscriptionsRequest>,
            serializer: some GRPCCore.MessageSerializer<Primandproper_Platform_Billing_V1_ListCurrentSubscriptionsRequest>,
            deserializer: some GRPCCore.MessageDeserializer<Primandproper_Platform_Billing_V1_ListCurrentSubscriptionsResponse>,
            options: GRPCCore.CallOptions = .defaults,
            onResponse handleResponse: @Sendable @escaping (GRPCCore.ClientResponse<Primandproper_Platform_Billing_V1_ListCurrentSubscriptionsResponse>) async throws -> Result = { response in
                try response.message
            }
        ) async throws -> Result where Result: Sendable {
            try await self.client.unary(
                request: request,
                descriptor: Primandproper_Platform_Billing_V1_BillingService.Method.ListCurrentSubscriptions.descriptor,
                serializer: serializer,
                deserializer: deserializer,
                options: options,
                onResponse: handleResponse
            )
        }

        /// Call the "ArchiveSubscription" method.
        ///
        /// - Parameters:
        ///   - request: A request containing a single `Primandproper_Platform_Billing_V1_ArchiveSubscriptionRequest` message.
        ///   - serializer: A serializer for `Primandproper_Platform_Billing_V1_ArchiveSubscriptionRequest` messages.
        ///   - deserializer: A deserializer for `Primandproper_Platform_Billing_V1_ArchiveSubscriptionResponse` messages.
        ///   - options: Options to apply to this RPC.
        ///   - handleResponse: A closure which handles the response and returns its result to
        ///       the caller. Returning from the closure will cancel the RPC if it hasn't
        ///       already finished.
        /// - Returns: The result of `handleResponse`.
        internal func archiveSubscription<Result>(
            request: GRPCCore.ClientRequest<Primandproper_Platform_Billing_V1_ArchiveSubscriptionRequest>,
            serializer: some GRPCCore.MessageSerializer<Primandproper_Platform_Billing_V1_ArchiveSubscriptionRequest>,
            deserializer: some GRPCCore.MessageDeserializer<Primandproper_Platform_Billing_V1_ArchiveSubscriptionResponse>,
            options: GRPCCore.CallOptions = .defaults,
            onResponse handleResponse: @Sendable @escaping (GRPCCore.ClientResponse<Primandproper_Platform_Billing_V1_ArchiveSubscriptionResponse>) async throws -> Result = { response in
                try response.message
            }
        ) async throws -> Result where Result: Sendable {
            try await self.client.unary(
                request: request,
                descriptor: Primandproper_Platform_Billing_V1_BillingService.Method.ArchiveSubscription.descriptor,
                serializer: serializer,
                deserializer: deserializer,
                options: options,
                onResponse: handleResponse
            )
        }

        /// Call the "GetPurchase" method.
        ///
        /// > Source IDL Documentation:
        /// >
        /// > The one-time half.
        ///
        /// - Parameters:
        ///   - request: A request containing a single `Primandproper_Platform_Billing_V1_GetPurchaseRequest` message.
        ///   - serializer: A serializer for `Primandproper_Platform_Billing_V1_GetPurchaseRequest` messages.
        ///   - deserializer: A deserializer for `Primandproper_Platform_Billing_V1_GetPurchaseResponse` messages.
        ///   - options: Options to apply to this RPC.
        ///   - handleResponse: A closure which handles the response and returns its result to
        ///       the caller. Returning from the closure will cancel the RPC if it hasn't
        ///       already finished.
        /// - Returns: The result of `handleResponse`.
        internal func getPurchase<Result>(
            request: GRPCCore.ClientRequest<Primandproper_Platform_Billing_V1_GetPurchaseRequest>,
            serializer: some GRPCCore.MessageSerializer<Primandproper_Platform_Billing_V1_GetPurchaseRequest>,
            deserializer: some GRPCCore.MessageDeserializer<Primandproper_Platform_Billing_V1_GetPurchaseResponse>,
            options: GRPCCore.CallOptions = .defaults,
            onResponse handleResponse: @Sendable @escaping (GRPCCore.ClientResponse<Primandproper_Platform_Billing_V1_GetPurchaseResponse>) async throws -> Result = { response in
                try response.message
            }
        ) async throws -> Result where Result: Sendable {
            try await self.client.unary(
                request: request,
                descriptor: Primandproper_Platform_Billing_V1_BillingService.Method.GetPurchase.descriptor,
                serializer: serializer,
                deserializer: deserializer,
                options: options,
                onResponse: handleResponse
            )
        }

        /// Call the "ListPurchases" method.
        ///
        /// - Parameters:
        ///   - request: A request containing a single `Primandproper_Platform_Billing_V1_ListPurchasesRequest` message.
        ///   - serializer: A serializer for `Primandproper_Platform_Billing_V1_ListPurchasesRequest` messages.
        ///   - deserializer: A deserializer for `Primandproper_Platform_Billing_V1_ListPurchasesResponse` messages.
        ///   - options: Options to apply to this RPC.
        ///   - handleResponse: A closure which handles the response and returns its result to
        ///       the caller. Returning from the closure will cancel the RPC if it hasn't
        ///       already finished.
        /// - Returns: The result of `handleResponse`.
        internal func listPurchases<Result>(
            request: GRPCCore.ClientRequest<Primandproper_Platform_Billing_V1_ListPurchasesRequest>,
            serializer: some GRPCCore.MessageSerializer<Primandproper_Platform_Billing_V1_ListPurchasesRequest>,
            deserializer: some GRPCCore.MessageDeserializer<Primandproper_Platform_Billing_V1_ListPurchasesResponse>,
            options: GRPCCore.CallOptions = .defaults,
            onResponse handleResponse: @Sendable @escaping (GRPCCore.ClientResponse<Primandproper_Platform_Billing_V1_ListPurchasesResponse>) async throws -> Result = { response in
                try response.message
            }
        ) async throws -> Result where Result: Sendable {
            try await self.client.unary(
                request: request,
                descriptor: Primandproper_Platform_Billing_V1_BillingService.Method.ListPurchases.descriptor,
                serializer: serializer,
                deserializer: deserializer,
                options: options,
                onResponse: handleResponse
            )
        }

        /// Call the "ListPurchasesForAccount" method.
        ///
        /// - Parameters:
        ///   - request: A request containing a single `Primandproper_Platform_Billing_V1_ListPurchasesForAccountRequest` message.
        ///   - serializer: A serializer for `Primandproper_Platform_Billing_V1_ListPurchasesForAccountRequest` messages.
        ///   - deserializer: A deserializer for `Primandproper_Platform_Billing_V1_ListPurchasesForAccountResponse` messages.
        ///   - options: Options to apply to this RPC.
        ///   - handleResponse: A closure which handles the response and returns its result to
        ///       the caller. Returning from the closure will cancel the RPC if it hasn't
        ///       already finished.
        /// - Returns: The result of `handleResponse`.
        internal func listPurchasesForAccount<Result>(
            request: GRPCCore.ClientRequest<Primandproper_Platform_Billing_V1_ListPurchasesForAccountRequest>,
            serializer: some GRPCCore.MessageSerializer<Primandproper_Platform_Billing_V1_ListPurchasesForAccountRequest>,
            deserializer: some GRPCCore.MessageDeserializer<Primandproper_Platform_Billing_V1_ListPurchasesForAccountResponse>,
            options: GRPCCore.CallOptions = .defaults,
            onResponse handleResponse: @Sendable @escaping (GRPCCore.ClientResponse<Primandproper_Platform_Billing_V1_ListPurchasesForAccountResponse>) async throws -> Result = { response in
                try response.message
            }
        ) async throws -> Result where Result: Sendable {
            try await self.client.unary(
                request: request,
                descriptor: Primandproper_Platform_Billing_V1_BillingService.Method.ListPurchasesForAccount.descriptor,
                serializer: serializer,
                deserializer: deserializer,
                options: options,
                onResponse: handleResponse
            )
        }

        /// Call the "ArchivePurchase" method.
        ///
        /// - Parameters:
        ///   - request: A request containing a single `Primandproper_Platform_Billing_V1_ArchivePurchaseRequest` message.
        ///   - serializer: A serializer for `Primandproper_Platform_Billing_V1_ArchivePurchaseRequest` messages.
        ///   - deserializer: A deserializer for `Primandproper_Platform_Billing_V1_ArchivePurchaseResponse` messages.
        ///   - options: Options to apply to this RPC.
        ///   - handleResponse: A closure which handles the response and returns its result to
        ///       the caller. Returning from the closure will cancel the RPC if it hasn't
        ///       already finished.
        /// - Returns: The result of `handleResponse`.
        internal func archivePurchase<Result>(
            request: GRPCCore.ClientRequest<Primandproper_Platform_Billing_V1_ArchivePurchaseRequest>,
            serializer: some GRPCCore.MessageSerializer<Primandproper_Platform_Billing_V1_ArchivePurchaseRequest>,
            deserializer: some GRPCCore.MessageDeserializer<Primandproper_Platform_Billing_V1_ArchivePurchaseResponse>,
            options: GRPCCore.CallOptions = .defaults,
            onResponse handleResponse: @Sendable @escaping (GRPCCore.ClientResponse<Primandproper_Platform_Billing_V1_ArchivePurchaseResponse>) async throws -> Result = { response in
                try response.message
            }
        ) async throws -> Result where Result: Sendable {
            try await self.client.unary(
                request: request,
                descriptor: Primandproper_Platform_Billing_V1_BillingService.Method.ArchivePurchase.descriptor,
                serializer: serializer,
                deserializer: deserializer,
                options: options,
                onResponse: handleResponse
            )
        }

        /// Call the "GetTransaction" method.
        ///
        /// > Source IDL Documentation:
        /// >
        /// > The ledger.
        ///
        /// - Parameters:
        ///   - request: A request containing a single `Primandproper_Platform_Billing_V1_GetTransactionRequest` message.
        ///   - serializer: A serializer for `Primandproper_Platform_Billing_V1_GetTransactionRequest` messages.
        ///   - deserializer: A deserializer for `Primandproper_Platform_Billing_V1_GetTransactionResponse` messages.
        ///   - options: Options to apply to this RPC.
        ///   - handleResponse: A closure which handles the response and returns its result to
        ///       the caller. Returning from the closure will cancel the RPC if it hasn't
        ///       already finished.
        /// - Returns: The result of `handleResponse`.
        internal func getTransaction<Result>(
            request: GRPCCore.ClientRequest<Primandproper_Platform_Billing_V1_GetTransactionRequest>,
            serializer: some GRPCCore.MessageSerializer<Primandproper_Platform_Billing_V1_GetTransactionRequest>,
            deserializer: some GRPCCore.MessageDeserializer<Primandproper_Platform_Billing_V1_GetTransactionResponse>,
            options: GRPCCore.CallOptions = .defaults,
            onResponse handleResponse: @Sendable @escaping (GRPCCore.ClientResponse<Primandproper_Platform_Billing_V1_GetTransactionResponse>) async throws -> Result = { response in
                try response.message
            }
        ) async throws -> Result where Result: Sendable {
            try await self.client.unary(
                request: request,
                descriptor: Primandproper_Platform_Billing_V1_BillingService.Method.GetTransaction.descriptor,
                serializer: serializer,
                deserializer: deserializer,
                options: options,
                onResponse: handleResponse
            )
        }

        /// Call the "ListTransactions" method.
        ///
        /// - Parameters:
        ///   - request: A request containing a single `Primandproper_Platform_Billing_V1_ListTransactionsRequest` message.
        ///   - serializer: A serializer for `Primandproper_Platform_Billing_V1_ListTransactionsRequest` messages.
        ///   - deserializer: A deserializer for `Primandproper_Platform_Billing_V1_ListTransactionsResponse` messages.
        ///   - options: Options to apply to this RPC.
        ///   - handleResponse: A closure which handles the response and returns its result to
        ///       the caller. Returning from the closure will cancel the RPC if it hasn't
        ///       already finished.
        /// - Returns: The result of `handleResponse`.
        internal func listTransactions<Result>(
            request: GRPCCore.ClientRequest<Primandproper_Platform_Billing_V1_ListTransactionsRequest>,
            serializer: some GRPCCore.MessageSerializer<Primandproper_Platform_Billing_V1_ListTransactionsRequest>,
            deserializer: some GRPCCore.MessageDeserializer<Primandproper_Platform_Billing_V1_ListTransactionsResponse>,
            options: GRPCCore.CallOptions = .defaults,
            onResponse handleResponse: @Sendable @escaping (GRPCCore.ClientResponse<Primandproper_Platform_Billing_V1_ListTransactionsResponse>) async throws -> Result = { response in
                try response.message
            }
        ) async throws -> Result where Result: Sendable {
            try await self.client.unary(
                request: request,
                descriptor: Primandproper_Platform_Billing_V1_BillingService.Method.ListTransactions.descriptor,
                serializer: serializer,
                deserializer: deserializer,
                options: options,
                onResponse: handleResponse
            )
        }

        /// Call the "ListTransactionsForAccount" method.
        ///
        /// - Parameters:
        ///   - request: A request containing a single `Primandproper_Platform_Billing_V1_ListTransactionsForAccountRequest` message.
        ///   - serializer: A serializer for `Primandproper_Platform_Billing_V1_ListTransactionsForAccountRequest` messages.
        ///   - deserializer: A deserializer for `Primandproper_Platform_Billing_V1_ListTransactionsForAccountResponse` messages.
        ///   - options: Options to apply to this RPC.
        ///   - handleResponse: A closure which handles the response and returns its result to
        ///       the caller. Returning from the closure will cancel the RPC if it hasn't
        ///       already finished.
        /// - Returns: The result of `handleResponse`.
        internal func listTransactionsForAccount<Result>(
            request: GRPCCore.ClientRequest<Primandproper_Platform_Billing_V1_ListTransactionsForAccountRequest>,
            serializer: some GRPCCore.MessageSerializer<Primandproper_Platform_Billing_V1_ListTransactionsForAccountRequest>,
            deserializer: some GRPCCore.MessageDeserializer<Primandproper_Platform_Billing_V1_ListTransactionsForAccountResponse>,
            options: GRPCCore.CallOptions = .defaults,
            onResponse handleResponse: @Sendable @escaping (GRPCCore.ClientResponse<Primandproper_Platform_Billing_V1_ListTransactionsForAccountResponse>) async throws -> Result = { response in
                try response.message
            }
        ) async throws -> Result where Result: Sendable {
            try await self.client.unary(
                request: request,
                descriptor: Primandproper_Platform_Billing_V1_BillingService.Method.ListTransactionsForAccount.descriptor,
                serializer: serializer,
                deserializer: deserializer,
                options: options,
                onResponse: handleResponse
            )
        }

        /// Call the "ArchiveTransaction" method.
        ///
        /// - Parameters:
        ///   - request: A request containing a single `Primandproper_Platform_Billing_V1_ArchiveTransactionRequest` message.
        ///   - serializer: A serializer for `Primandproper_Platform_Billing_V1_ArchiveTransactionRequest` messages.
        ///   - deserializer: A deserializer for `Primandproper_Platform_Billing_V1_ArchiveTransactionResponse` messages.
        ///   - options: Options to apply to this RPC.
        ///   - handleResponse: A closure which handles the response and returns its result to
        ///       the caller. Returning from the closure will cancel the RPC if it hasn't
        ///       already finished.
        /// - Returns: The result of `handleResponse`.
        internal func archiveTransaction<Result>(
            request: GRPCCore.ClientRequest<Primandproper_Platform_Billing_V1_ArchiveTransactionRequest>,
            serializer: some GRPCCore.MessageSerializer<Primandproper_Platform_Billing_V1_ArchiveTransactionRequest>,
            deserializer: some GRPCCore.MessageDeserializer<Primandproper_Platform_Billing_V1_ArchiveTransactionResponse>,
            options: GRPCCore.CallOptions = .defaults,
            onResponse handleResponse: @Sendable @escaping (GRPCCore.ClientResponse<Primandproper_Platform_Billing_V1_ArchiveTransactionResponse>) async throws -> Result = { response in
                try response.message
            }
        ) async throws -> Result where Result: Sendable {
            try await self.client.unary(
                request: request,
                descriptor: Primandproper_Platform_Billing_V1_BillingService.Method.ArchiveTransaction.descriptor,
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
extension Primandproper_Platform_Billing_V1_BillingService.ClientProtocol {
    /// Call the "CreateProduct" method.
    ///
    /// > Source IDL Documentation:
    /// >
    /// > The catalog: two reads any member of the scope may make, and three
    /// > administrative writes.
    ///
    /// - Parameters:
    ///   - request: A request containing a single `Primandproper_Platform_Billing_V1_CreateProductRequest` message.
    ///   - options: Options to apply to this RPC.
    ///   - handleResponse: A closure which handles the response and returns its result to
    ///       the caller. Returning from the closure will cancel the RPC if it hasn't
    ///       already finished.
    /// - Returns: The result of `handleResponse`.
    internal func createProduct<Result>(
        request: GRPCCore.ClientRequest<Primandproper_Platform_Billing_V1_CreateProductRequest>,
        options: GRPCCore.CallOptions = .defaults,
        onResponse handleResponse: @Sendable @escaping (GRPCCore.ClientResponse<Primandproper_Platform_Billing_V1_CreateProductResponse>) async throws -> Result = { response in
            try response.message
        }
    ) async throws -> Result where Result: Sendable {
        try await self.createProduct(
            request: request,
            serializer: GRPCProtobuf.ProtobufSerializer<Primandproper_Platform_Billing_V1_CreateProductRequest>(),
            deserializer: GRPCProtobuf.ProtobufDeserializer<Primandproper_Platform_Billing_V1_CreateProductResponse>(),
            options: options,
            onResponse: handleResponse
        )
    }

    /// Call the "GetProduct" method.
    ///
    /// - Parameters:
    ///   - request: A request containing a single `Primandproper_Platform_Billing_V1_GetProductRequest` message.
    ///   - options: Options to apply to this RPC.
    ///   - handleResponse: A closure which handles the response and returns its result to
    ///       the caller. Returning from the closure will cancel the RPC if it hasn't
    ///       already finished.
    /// - Returns: The result of `handleResponse`.
    internal func getProduct<Result>(
        request: GRPCCore.ClientRequest<Primandproper_Platform_Billing_V1_GetProductRequest>,
        options: GRPCCore.CallOptions = .defaults,
        onResponse handleResponse: @Sendable @escaping (GRPCCore.ClientResponse<Primandproper_Platform_Billing_V1_GetProductResponse>) async throws -> Result = { response in
            try response.message
        }
    ) async throws -> Result where Result: Sendable {
        try await self.getProduct(
            request: request,
            serializer: GRPCProtobuf.ProtobufSerializer<Primandproper_Platform_Billing_V1_GetProductRequest>(),
            deserializer: GRPCProtobuf.ProtobufDeserializer<Primandproper_Platform_Billing_V1_GetProductResponse>(),
            options: options,
            onResponse: handleResponse
        )
    }

    /// Call the "ListProducts" method.
    ///
    /// - Parameters:
    ///   - request: A request containing a single `Primandproper_Platform_Billing_V1_ListProductsRequest` message.
    ///   - options: Options to apply to this RPC.
    ///   - handleResponse: A closure which handles the response and returns its result to
    ///       the caller. Returning from the closure will cancel the RPC if it hasn't
    ///       already finished.
    /// - Returns: The result of `handleResponse`.
    internal func listProducts<Result>(
        request: GRPCCore.ClientRequest<Primandproper_Platform_Billing_V1_ListProductsRequest>,
        options: GRPCCore.CallOptions = .defaults,
        onResponse handleResponse: @Sendable @escaping (GRPCCore.ClientResponse<Primandproper_Platform_Billing_V1_ListProductsResponse>) async throws -> Result = { response in
            try response.message
        }
    ) async throws -> Result where Result: Sendable {
        try await self.listProducts(
            request: request,
            serializer: GRPCProtobuf.ProtobufSerializer<Primandproper_Platform_Billing_V1_ListProductsRequest>(),
            deserializer: GRPCProtobuf.ProtobufDeserializer<Primandproper_Platform_Billing_V1_ListProductsResponse>(),
            options: options,
            onResponse: handleResponse
        )
    }

    /// Call the "UpdateProduct" method.
    ///
    /// - Parameters:
    ///   - request: A request containing a single `Primandproper_Platform_Billing_V1_UpdateProductRequest` message.
    ///   - options: Options to apply to this RPC.
    ///   - handleResponse: A closure which handles the response and returns its result to
    ///       the caller. Returning from the closure will cancel the RPC if it hasn't
    ///       already finished.
    /// - Returns: The result of `handleResponse`.
    internal func updateProduct<Result>(
        request: GRPCCore.ClientRequest<Primandproper_Platform_Billing_V1_UpdateProductRequest>,
        options: GRPCCore.CallOptions = .defaults,
        onResponse handleResponse: @Sendable @escaping (GRPCCore.ClientResponse<Primandproper_Platform_Billing_V1_UpdateProductResponse>) async throws -> Result = { response in
            try response.message
        }
    ) async throws -> Result where Result: Sendable {
        try await self.updateProduct(
            request: request,
            serializer: GRPCProtobuf.ProtobufSerializer<Primandproper_Platform_Billing_V1_UpdateProductRequest>(),
            deserializer: GRPCProtobuf.ProtobufDeserializer<Primandproper_Platform_Billing_V1_UpdateProductResponse>(),
            options: options,
            onResponse: handleResponse
        )
    }

    /// Call the "ArchiveProduct" method.
    ///
    /// - Parameters:
    ///   - request: A request containing a single `Primandproper_Platform_Billing_V1_ArchiveProductRequest` message.
    ///   - options: Options to apply to this RPC.
    ///   - handleResponse: A closure which handles the response and returns its result to
    ///       the caller. Returning from the closure will cancel the RPC if it hasn't
    ///       already finished.
    /// - Returns: The result of `handleResponse`.
    internal func archiveProduct<Result>(
        request: GRPCCore.ClientRequest<Primandproper_Platform_Billing_V1_ArchiveProductRequest>,
        options: GRPCCore.CallOptions = .defaults,
        onResponse handleResponse: @Sendable @escaping (GRPCCore.ClientResponse<Primandproper_Platform_Billing_V1_ArchiveProductResponse>) async throws -> Result = { response in
            try response.message
        }
    ) async throws -> Result where Result: Sendable {
        try await self.archiveProduct(
            request: request,
            serializer: GRPCProtobuf.ProtobufSerializer<Primandproper_Platform_Billing_V1_ArchiveProductRequest>(),
            deserializer: GRPCProtobuf.ProtobufDeserializer<Primandproper_Platform_Billing_V1_ArchiveProductResponse>(),
            options: options,
            onResponse: handleResponse
        )
    }

    /// Call the "GetSubscription" method.
    ///
    /// > Source IDL Documentation:
    /// >
    /// > The recurring half. ListCurrentSubscriptions is the one an entitlement
    /// > screen reads: it pages the agreements whose paid period covers now, and
    /// > deliberately does not filter on status, because which status leaves an
    /// > account entitled is the consumer's ruling.
    ///
    /// - Parameters:
    ///   - request: A request containing a single `Primandproper_Platform_Billing_V1_GetSubscriptionRequest` message.
    ///   - options: Options to apply to this RPC.
    ///   - handleResponse: A closure which handles the response and returns its result to
    ///       the caller. Returning from the closure will cancel the RPC if it hasn't
    ///       already finished.
    /// - Returns: The result of `handleResponse`.
    internal func getSubscription<Result>(
        request: GRPCCore.ClientRequest<Primandproper_Platform_Billing_V1_GetSubscriptionRequest>,
        options: GRPCCore.CallOptions = .defaults,
        onResponse handleResponse: @Sendable @escaping (GRPCCore.ClientResponse<Primandproper_Platform_Billing_V1_GetSubscriptionResponse>) async throws -> Result = { response in
            try response.message
        }
    ) async throws -> Result where Result: Sendable {
        try await self.getSubscription(
            request: request,
            serializer: GRPCProtobuf.ProtobufSerializer<Primandproper_Platform_Billing_V1_GetSubscriptionRequest>(),
            deserializer: GRPCProtobuf.ProtobufDeserializer<Primandproper_Platform_Billing_V1_GetSubscriptionResponse>(),
            options: options,
            onResponse: handleResponse
        )
    }

    /// Call the "ListSubscriptions" method.
    ///
    /// - Parameters:
    ///   - request: A request containing a single `Primandproper_Platform_Billing_V1_ListSubscriptionsRequest` message.
    ///   - options: Options to apply to this RPC.
    ///   - handleResponse: A closure which handles the response and returns its result to
    ///       the caller. Returning from the closure will cancel the RPC if it hasn't
    ///       already finished.
    /// - Returns: The result of `handleResponse`.
    internal func listSubscriptions<Result>(
        request: GRPCCore.ClientRequest<Primandproper_Platform_Billing_V1_ListSubscriptionsRequest>,
        options: GRPCCore.CallOptions = .defaults,
        onResponse handleResponse: @Sendable @escaping (GRPCCore.ClientResponse<Primandproper_Platform_Billing_V1_ListSubscriptionsResponse>) async throws -> Result = { response in
            try response.message
        }
    ) async throws -> Result where Result: Sendable {
        try await self.listSubscriptions(
            request: request,
            serializer: GRPCProtobuf.ProtobufSerializer<Primandproper_Platform_Billing_V1_ListSubscriptionsRequest>(),
            deserializer: GRPCProtobuf.ProtobufDeserializer<Primandproper_Platform_Billing_V1_ListSubscriptionsResponse>(),
            options: options,
            onResponse: handleResponse
        )
    }

    /// Call the "ListSubscriptionsForAccount" method.
    ///
    /// - Parameters:
    ///   - request: A request containing a single `Primandproper_Platform_Billing_V1_ListSubscriptionsForAccountRequest` message.
    ///   - options: Options to apply to this RPC.
    ///   - handleResponse: A closure which handles the response and returns its result to
    ///       the caller. Returning from the closure will cancel the RPC if it hasn't
    ///       already finished.
    /// - Returns: The result of `handleResponse`.
    internal func listSubscriptionsForAccount<Result>(
        request: GRPCCore.ClientRequest<Primandproper_Platform_Billing_V1_ListSubscriptionsForAccountRequest>,
        options: GRPCCore.CallOptions = .defaults,
        onResponse handleResponse: @Sendable @escaping (GRPCCore.ClientResponse<Primandproper_Platform_Billing_V1_ListSubscriptionsForAccountResponse>) async throws -> Result = { response in
            try response.message
        }
    ) async throws -> Result where Result: Sendable {
        try await self.listSubscriptionsForAccount(
            request: request,
            serializer: GRPCProtobuf.ProtobufSerializer<Primandproper_Platform_Billing_V1_ListSubscriptionsForAccountRequest>(),
            deserializer: GRPCProtobuf.ProtobufDeserializer<Primandproper_Platform_Billing_V1_ListSubscriptionsForAccountResponse>(),
            options: options,
            onResponse: handleResponse
        )
    }

    /// Call the "ListCurrentSubscriptions" method.
    ///
    /// - Parameters:
    ///   - request: A request containing a single `Primandproper_Platform_Billing_V1_ListCurrentSubscriptionsRequest` message.
    ///   - options: Options to apply to this RPC.
    ///   - handleResponse: A closure which handles the response and returns its result to
    ///       the caller. Returning from the closure will cancel the RPC if it hasn't
    ///       already finished.
    /// - Returns: The result of `handleResponse`.
    internal func listCurrentSubscriptions<Result>(
        request: GRPCCore.ClientRequest<Primandproper_Platform_Billing_V1_ListCurrentSubscriptionsRequest>,
        options: GRPCCore.CallOptions = .defaults,
        onResponse handleResponse: @Sendable @escaping (GRPCCore.ClientResponse<Primandproper_Platform_Billing_V1_ListCurrentSubscriptionsResponse>) async throws -> Result = { response in
            try response.message
        }
    ) async throws -> Result where Result: Sendable {
        try await self.listCurrentSubscriptions(
            request: request,
            serializer: GRPCProtobuf.ProtobufSerializer<Primandproper_Platform_Billing_V1_ListCurrentSubscriptionsRequest>(),
            deserializer: GRPCProtobuf.ProtobufDeserializer<Primandproper_Platform_Billing_V1_ListCurrentSubscriptionsResponse>(),
            options: options,
            onResponse: handleResponse
        )
    }

    /// Call the "ArchiveSubscription" method.
    ///
    /// - Parameters:
    ///   - request: A request containing a single `Primandproper_Platform_Billing_V1_ArchiveSubscriptionRequest` message.
    ///   - options: Options to apply to this RPC.
    ///   - handleResponse: A closure which handles the response and returns its result to
    ///       the caller. Returning from the closure will cancel the RPC if it hasn't
    ///       already finished.
    /// - Returns: The result of `handleResponse`.
    internal func archiveSubscription<Result>(
        request: GRPCCore.ClientRequest<Primandproper_Platform_Billing_V1_ArchiveSubscriptionRequest>,
        options: GRPCCore.CallOptions = .defaults,
        onResponse handleResponse: @Sendable @escaping (GRPCCore.ClientResponse<Primandproper_Platform_Billing_V1_ArchiveSubscriptionResponse>) async throws -> Result = { response in
            try response.message
        }
    ) async throws -> Result where Result: Sendable {
        try await self.archiveSubscription(
            request: request,
            serializer: GRPCProtobuf.ProtobufSerializer<Primandproper_Platform_Billing_V1_ArchiveSubscriptionRequest>(),
            deserializer: GRPCProtobuf.ProtobufDeserializer<Primandproper_Platform_Billing_V1_ArchiveSubscriptionResponse>(),
            options: options,
            onResponse: handleResponse
        )
    }

    /// Call the "GetPurchase" method.
    ///
    /// > Source IDL Documentation:
    /// >
    /// > The one-time half.
    ///
    /// - Parameters:
    ///   - request: A request containing a single `Primandproper_Platform_Billing_V1_GetPurchaseRequest` message.
    ///   - options: Options to apply to this RPC.
    ///   - handleResponse: A closure which handles the response and returns its result to
    ///       the caller. Returning from the closure will cancel the RPC if it hasn't
    ///       already finished.
    /// - Returns: The result of `handleResponse`.
    internal func getPurchase<Result>(
        request: GRPCCore.ClientRequest<Primandproper_Platform_Billing_V1_GetPurchaseRequest>,
        options: GRPCCore.CallOptions = .defaults,
        onResponse handleResponse: @Sendable @escaping (GRPCCore.ClientResponse<Primandproper_Platform_Billing_V1_GetPurchaseResponse>) async throws -> Result = { response in
            try response.message
        }
    ) async throws -> Result where Result: Sendable {
        try await self.getPurchase(
            request: request,
            serializer: GRPCProtobuf.ProtobufSerializer<Primandproper_Platform_Billing_V1_GetPurchaseRequest>(),
            deserializer: GRPCProtobuf.ProtobufDeserializer<Primandproper_Platform_Billing_V1_GetPurchaseResponse>(),
            options: options,
            onResponse: handleResponse
        )
    }

    /// Call the "ListPurchases" method.
    ///
    /// - Parameters:
    ///   - request: A request containing a single `Primandproper_Platform_Billing_V1_ListPurchasesRequest` message.
    ///   - options: Options to apply to this RPC.
    ///   - handleResponse: A closure which handles the response and returns its result to
    ///       the caller. Returning from the closure will cancel the RPC if it hasn't
    ///       already finished.
    /// - Returns: The result of `handleResponse`.
    internal func listPurchases<Result>(
        request: GRPCCore.ClientRequest<Primandproper_Platform_Billing_V1_ListPurchasesRequest>,
        options: GRPCCore.CallOptions = .defaults,
        onResponse handleResponse: @Sendable @escaping (GRPCCore.ClientResponse<Primandproper_Platform_Billing_V1_ListPurchasesResponse>) async throws -> Result = { response in
            try response.message
        }
    ) async throws -> Result where Result: Sendable {
        try await self.listPurchases(
            request: request,
            serializer: GRPCProtobuf.ProtobufSerializer<Primandproper_Platform_Billing_V1_ListPurchasesRequest>(),
            deserializer: GRPCProtobuf.ProtobufDeserializer<Primandproper_Platform_Billing_V1_ListPurchasesResponse>(),
            options: options,
            onResponse: handleResponse
        )
    }

    /// Call the "ListPurchasesForAccount" method.
    ///
    /// - Parameters:
    ///   - request: A request containing a single `Primandproper_Platform_Billing_V1_ListPurchasesForAccountRequest` message.
    ///   - options: Options to apply to this RPC.
    ///   - handleResponse: A closure which handles the response and returns its result to
    ///       the caller. Returning from the closure will cancel the RPC if it hasn't
    ///       already finished.
    /// - Returns: The result of `handleResponse`.
    internal func listPurchasesForAccount<Result>(
        request: GRPCCore.ClientRequest<Primandproper_Platform_Billing_V1_ListPurchasesForAccountRequest>,
        options: GRPCCore.CallOptions = .defaults,
        onResponse handleResponse: @Sendable @escaping (GRPCCore.ClientResponse<Primandproper_Platform_Billing_V1_ListPurchasesForAccountResponse>) async throws -> Result = { response in
            try response.message
        }
    ) async throws -> Result where Result: Sendable {
        try await self.listPurchasesForAccount(
            request: request,
            serializer: GRPCProtobuf.ProtobufSerializer<Primandproper_Platform_Billing_V1_ListPurchasesForAccountRequest>(),
            deserializer: GRPCProtobuf.ProtobufDeserializer<Primandproper_Platform_Billing_V1_ListPurchasesForAccountResponse>(),
            options: options,
            onResponse: handleResponse
        )
    }

    /// Call the "ArchivePurchase" method.
    ///
    /// - Parameters:
    ///   - request: A request containing a single `Primandproper_Platform_Billing_V1_ArchivePurchaseRequest` message.
    ///   - options: Options to apply to this RPC.
    ///   - handleResponse: A closure which handles the response and returns its result to
    ///       the caller. Returning from the closure will cancel the RPC if it hasn't
    ///       already finished.
    /// - Returns: The result of `handleResponse`.
    internal func archivePurchase<Result>(
        request: GRPCCore.ClientRequest<Primandproper_Platform_Billing_V1_ArchivePurchaseRequest>,
        options: GRPCCore.CallOptions = .defaults,
        onResponse handleResponse: @Sendable @escaping (GRPCCore.ClientResponse<Primandproper_Platform_Billing_V1_ArchivePurchaseResponse>) async throws -> Result = { response in
            try response.message
        }
    ) async throws -> Result where Result: Sendable {
        try await self.archivePurchase(
            request: request,
            serializer: GRPCProtobuf.ProtobufSerializer<Primandproper_Platform_Billing_V1_ArchivePurchaseRequest>(),
            deserializer: GRPCProtobuf.ProtobufDeserializer<Primandproper_Platform_Billing_V1_ArchivePurchaseResponse>(),
            options: options,
            onResponse: handleResponse
        )
    }

    /// Call the "GetTransaction" method.
    ///
    /// > Source IDL Documentation:
    /// >
    /// > The ledger.
    ///
    /// - Parameters:
    ///   - request: A request containing a single `Primandproper_Platform_Billing_V1_GetTransactionRequest` message.
    ///   - options: Options to apply to this RPC.
    ///   - handleResponse: A closure which handles the response and returns its result to
    ///       the caller. Returning from the closure will cancel the RPC if it hasn't
    ///       already finished.
    /// - Returns: The result of `handleResponse`.
    internal func getTransaction<Result>(
        request: GRPCCore.ClientRequest<Primandproper_Platform_Billing_V1_GetTransactionRequest>,
        options: GRPCCore.CallOptions = .defaults,
        onResponse handleResponse: @Sendable @escaping (GRPCCore.ClientResponse<Primandproper_Platform_Billing_V1_GetTransactionResponse>) async throws -> Result = { response in
            try response.message
        }
    ) async throws -> Result where Result: Sendable {
        try await self.getTransaction(
            request: request,
            serializer: GRPCProtobuf.ProtobufSerializer<Primandproper_Platform_Billing_V1_GetTransactionRequest>(),
            deserializer: GRPCProtobuf.ProtobufDeserializer<Primandproper_Platform_Billing_V1_GetTransactionResponse>(),
            options: options,
            onResponse: handleResponse
        )
    }

    /// Call the "ListTransactions" method.
    ///
    /// - Parameters:
    ///   - request: A request containing a single `Primandproper_Platform_Billing_V1_ListTransactionsRequest` message.
    ///   - options: Options to apply to this RPC.
    ///   - handleResponse: A closure which handles the response and returns its result to
    ///       the caller. Returning from the closure will cancel the RPC if it hasn't
    ///       already finished.
    /// - Returns: The result of `handleResponse`.
    internal func listTransactions<Result>(
        request: GRPCCore.ClientRequest<Primandproper_Platform_Billing_V1_ListTransactionsRequest>,
        options: GRPCCore.CallOptions = .defaults,
        onResponse handleResponse: @Sendable @escaping (GRPCCore.ClientResponse<Primandproper_Platform_Billing_V1_ListTransactionsResponse>) async throws -> Result = { response in
            try response.message
        }
    ) async throws -> Result where Result: Sendable {
        try await self.listTransactions(
            request: request,
            serializer: GRPCProtobuf.ProtobufSerializer<Primandproper_Platform_Billing_V1_ListTransactionsRequest>(),
            deserializer: GRPCProtobuf.ProtobufDeserializer<Primandproper_Platform_Billing_V1_ListTransactionsResponse>(),
            options: options,
            onResponse: handleResponse
        )
    }

    /// Call the "ListTransactionsForAccount" method.
    ///
    /// - Parameters:
    ///   - request: A request containing a single `Primandproper_Platform_Billing_V1_ListTransactionsForAccountRequest` message.
    ///   - options: Options to apply to this RPC.
    ///   - handleResponse: A closure which handles the response and returns its result to
    ///       the caller. Returning from the closure will cancel the RPC if it hasn't
    ///       already finished.
    /// - Returns: The result of `handleResponse`.
    internal func listTransactionsForAccount<Result>(
        request: GRPCCore.ClientRequest<Primandproper_Platform_Billing_V1_ListTransactionsForAccountRequest>,
        options: GRPCCore.CallOptions = .defaults,
        onResponse handleResponse: @Sendable @escaping (GRPCCore.ClientResponse<Primandproper_Platform_Billing_V1_ListTransactionsForAccountResponse>) async throws -> Result = { response in
            try response.message
        }
    ) async throws -> Result where Result: Sendable {
        try await self.listTransactionsForAccount(
            request: request,
            serializer: GRPCProtobuf.ProtobufSerializer<Primandproper_Platform_Billing_V1_ListTransactionsForAccountRequest>(),
            deserializer: GRPCProtobuf.ProtobufDeserializer<Primandproper_Platform_Billing_V1_ListTransactionsForAccountResponse>(),
            options: options,
            onResponse: handleResponse
        )
    }

    /// Call the "ArchiveTransaction" method.
    ///
    /// - Parameters:
    ///   - request: A request containing a single `Primandproper_Platform_Billing_V1_ArchiveTransactionRequest` message.
    ///   - options: Options to apply to this RPC.
    ///   - handleResponse: A closure which handles the response and returns its result to
    ///       the caller. Returning from the closure will cancel the RPC if it hasn't
    ///       already finished.
    /// - Returns: The result of `handleResponse`.
    internal func archiveTransaction<Result>(
        request: GRPCCore.ClientRequest<Primandproper_Platform_Billing_V1_ArchiveTransactionRequest>,
        options: GRPCCore.CallOptions = .defaults,
        onResponse handleResponse: @Sendable @escaping (GRPCCore.ClientResponse<Primandproper_Platform_Billing_V1_ArchiveTransactionResponse>) async throws -> Result = { response in
            try response.message
        }
    ) async throws -> Result where Result: Sendable {
        try await self.archiveTransaction(
            request: request,
            serializer: GRPCProtobuf.ProtobufSerializer<Primandproper_Platform_Billing_V1_ArchiveTransactionRequest>(),
            deserializer: GRPCProtobuf.ProtobufDeserializer<Primandproper_Platform_Billing_V1_ArchiveTransactionResponse>(),
            options: options,
            onResponse: handleResponse
        )
    }
}

// Helpers providing sugared APIs for 'ClientProtocol' methods.
@available(macOS 15.0, iOS 18.0, watchOS 11.0, tvOS 18.0, visionOS 2.0, *)
extension Primandproper_Platform_Billing_V1_BillingService.ClientProtocol {
    /// Call the "CreateProduct" method.
    ///
    /// > Source IDL Documentation:
    /// >
    /// > The catalog: two reads any member of the scope may make, and three
    /// > administrative writes.
    ///
    /// - Parameters:
    ///   - message: request message to send.
    ///   - metadata: Additional metadata to send, defaults to empty.
    ///   - options: Options to apply to this RPC, defaults to `.defaults`.
    ///   - handleResponse: A closure which handles the response and returns its result to
    ///       the caller. Returning from the closure will cancel the RPC if it hasn't
    ///       already finished.
    /// - Returns: The result of `handleResponse`.
    internal func createProduct<Result>(
        _ message: Primandproper_Platform_Billing_V1_CreateProductRequest,
        metadata: GRPCCore.Metadata = [:],
        options: GRPCCore.CallOptions = .defaults,
        onResponse handleResponse: @Sendable @escaping (GRPCCore.ClientResponse<Primandproper_Platform_Billing_V1_CreateProductResponse>) async throws -> Result = { response in
            try response.message
        }
    ) async throws -> Result where Result: Sendable {
        let request = GRPCCore.ClientRequest<Primandproper_Platform_Billing_V1_CreateProductRequest>(
            message: message,
            metadata: metadata
        )
        return try await self.createProduct(
            request: request,
            options: options,
            onResponse: handleResponse
        )
    }

    /// Call the "GetProduct" method.
    ///
    /// - Parameters:
    ///   - message: request message to send.
    ///   - metadata: Additional metadata to send, defaults to empty.
    ///   - options: Options to apply to this RPC, defaults to `.defaults`.
    ///   - handleResponse: A closure which handles the response and returns its result to
    ///       the caller. Returning from the closure will cancel the RPC if it hasn't
    ///       already finished.
    /// - Returns: The result of `handleResponse`.
    internal func getProduct<Result>(
        _ message: Primandproper_Platform_Billing_V1_GetProductRequest,
        metadata: GRPCCore.Metadata = [:],
        options: GRPCCore.CallOptions = .defaults,
        onResponse handleResponse: @Sendable @escaping (GRPCCore.ClientResponse<Primandproper_Platform_Billing_V1_GetProductResponse>) async throws -> Result = { response in
            try response.message
        }
    ) async throws -> Result where Result: Sendable {
        let request = GRPCCore.ClientRequest<Primandproper_Platform_Billing_V1_GetProductRequest>(
            message: message,
            metadata: metadata
        )
        return try await self.getProduct(
            request: request,
            options: options,
            onResponse: handleResponse
        )
    }

    /// Call the "ListProducts" method.
    ///
    /// - Parameters:
    ///   - message: request message to send.
    ///   - metadata: Additional metadata to send, defaults to empty.
    ///   - options: Options to apply to this RPC, defaults to `.defaults`.
    ///   - handleResponse: A closure which handles the response and returns its result to
    ///       the caller. Returning from the closure will cancel the RPC if it hasn't
    ///       already finished.
    /// - Returns: The result of `handleResponse`.
    internal func listProducts<Result>(
        _ message: Primandproper_Platform_Billing_V1_ListProductsRequest,
        metadata: GRPCCore.Metadata = [:],
        options: GRPCCore.CallOptions = .defaults,
        onResponse handleResponse: @Sendable @escaping (GRPCCore.ClientResponse<Primandproper_Platform_Billing_V1_ListProductsResponse>) async throws -> Result = { response in
            try response.message
        }
    ) async throws -> Result where Result: Sendable {
        let request = GRPCCore.ClientRequest<Primandproper_Platform_Billing_V1_ListProductsRequest>(
            message: message,
            metadata: metadata
        )
        return try await self.listProducts(
            request: request,
            options: options,
            onResponse: handleResponse
        )
    }

    /// Call the "UpdateProduct" method.
    ///
    /// - Parameters:
    ///   - message: request message to send.
    ///   - metadata: Additional metadata to send, defaults to empty.
    ///   - options: Options to apply to this RPC, defaults to `.defaults`.
    ///   - handleResponse: A closure which handles the response and returns its result to
    ///       the caller. Returning from the closure will cancel the RPC if it hasn't
    ///       already finished.
    /// - Returns: The result of `handleResponse`.
    internal func updateProduct<Result>(
        _ message: Primandproper_Platform_Billing_V1_UpdateProductRequest,
        metadata: GRPCCore.Metadata = [:],
        options: GRPCCore.CallOptions = .defaults,
        onResponse handleResponse: @Sendable @escaping (GRPCCore.ClientResponse<Primandproper_Platform_Billing_V1_UpdateProductResponse>) async throws -> Result = { response in
            try response.message
        }
    ) async throws -> Result where Result: Sendable {
        let request = GRPCCore.ClientRequest<Primandproper_Platform_Billing_V1_UpdateProductRequest>(
            message: message,
            metadata: metadata
        )
        return try await self.updateProduct(
            request: request,
            options: options,
            onResponse: handleResponse
        )
    }

    /// Call the "ArchiveProduct" method.
    ///
    /// - Parameters:
    ///   - message: request message to send.
    ///   - metadata: Additional metadata to send, defaults to empty.
    ///   - options: Options to apply to this RPC, defaults to `.defaults`.
    ///   - handleResponse: A closure which handles the response and returns its result to
    ///       the caller. Returning from the closure will cancel the RPC if it hasn't
    ///       already finished.
    /// - Returns: The result of `handleResponse`.
    internal func archiveProduct<Result>(
        _ message: Primandproper_Platform_Billing_V1_ArchiveProductRequest,
        metadata: GRPCCore.Metadata = [:],
        options: GRPCCore.CallOptions = .defaults,
        onResponse handleResponse: @Sendable @escaping (GRPCCore.ClientResponse<Primandproper_Platform_Billing_V1_ArchiveProductResponse>) async throws -> Result = { response in
            try response.message
        }
    ) async throws -> Result where Result: Sendable {
        let request = GRPCCore.ClientRequest<Primandproper_Platform_Billing_V1_ArchiveProductRequest>(
            message: message,
            metadata: metadata
        )
        return try await self.archiveProduct(
            request: request,
            options: options,
            onResponse: handleResponse
        )
    }

    /// Call the "GetSubscription" method.
    ///
    /// > Source IDL Documentation:
    /// >
    /// > The recurring half. ListCurrentSubscriptions is the one an entitlement
    /// > screen reads: it pages the agreements whose paid period covers now, and
    /// > deliberately does not filter on status, because which status leaves an
    /// > account entitled is the consumer's ruling.
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
        _ message: Primandproper_Platform_Billing_V1_GetSubscriptionRequest,
        metadata: GRPCCore.Metadata = [:],
        options: GRPCCore.CallOptions = .defaults,
        onResponse handleResponse: @Sendable @escaping (GRPCCore.ClientResponse<Primandproper_Platform_Billing_V1_GetSubscriptionResponse>) async throws -> Result = { response in
            try response.message
        }
    ) async throws -> Result where Result: Sendable {
        let request = GRPCCore.ClientRequest<Primandproper_Platform_Billing_V1_GetSubscriptionRequest>(
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
        _ message: Primandproper_Platform_Billing_V1_ListSubscriptionsRequest,
        metadata: GRPCCore.Metadata = [:],
        options: GRPCCore.CallOptions = .defaults,
        onResponse handleResponse: @Sendable @escaping (GRPCCore.ClientResponse<Primandproper_Platform_Billing_V1_ListSubscriptionsResponse>) async throws -> Result = { response in
            try response.message
        }
    ) async throws -> Result where Result: Sendable {
        let request = GRPCCore.ClientRequest<Primandproper_Platform_Billing_V1_ListSubscriptionsRequest>(
            message: message,
            metadata: metadata
        )
        return try await self.listSubscriptions(
            request: request,
            options: options,
            onResponse: handleResponse
        )
    }

    /// Call the "ListSubscriptionsForAccount" method.
    ///
    /// - Parameters:
    ///   - message: request message to send.
    ///   - metadata: Additional metadata to send, defaults to empty.
    ///   - options: Options to apply to this RPC, defaults to `.defaults`.
    ///   - handleResponse: A closure which handles the response and returns its result to
    ///       the caller. Returning from the closure will cancel the RPC if it hasn't
    ///       already finished.
    /// - Returns: The result of `handleResponse`.
    internal func listSubscriptionsForAccount<Result>(
        _ message: Primandproper_Platform_Billing_V1_ListSubscriptionsForAccountRequest,
        metadata: GRPCCore.Metadata = [:],
        options: GRPCCore.CallOptions = .defaults,
        onResponse handleResponse: @Sendable @escaping (GRPCCore.ClientResponse<Primandproper_Platform_Billing_V1_ListSubscriptionsForAccountResponse>) async throws -> Result = { response in
            try response.message
        }
    ) async throws -> Result where Result: Sendable {
        let request = GRPCCore.ClientRequest<Primandproper_Platform_Billing_V1_ListSubscriptionsForAccountRequest>(
            message: message,
            metadata: metadata
        )
        return try await self.listSubscriptionsForAccount(
            request: request,
            options: options,
            onResponse: handleResponse
        )
    }

    /// Call the "ListCurrentSubscriptions" method.
    ///
    /// - Parameters:
    ///   - message: request message to send.
    ///   - metadata: Additional metadata to send, defaults to empty.
    ///   - options: Options to apply to this RPC, defaults to `.defaults`.
    ///   - handleResponse: A closure which handles the response and returns its result to
    ///       the caller. Returning from the closure will cancel the RPC if it hasn't
    ///       already finished.
    /// - Returns: The result of `handleResponse`.
    internal func listCurrentSubscriptions<Result>(
        _ message: Primandproper_Platform_Billing_V1_ListCurrentSubscriptionsRequest,
        metadata: GRPCCore.Metadata = [:],
        options: GRPCCore.CallOptions = .defaults,
        onResponse handleResponse: @Sendable @escaping (GRPCCore.ClientResponse<Primandproper_Platform_Billing_V1_ListCurrentSubscriptionsResponse>) async throws -> Result = { response in
            try response.message
        }
    ) async throws -> Result where Result: Sendable {
        let request = GRPCCore.ClientRequest<Primandproper_Platform_Billing_V1_ListCurrentSubscriptionsRequest>(
            message: message,
            metadata: metadata
        )
        return try await self.listCurrentSubscriptions(
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
        _ message: Primandproper_Platform_Billing_V1_ArchiveSubscriptionRequest,
        metadata: GRPCCore.Metadata = [:],
        options: GRPCCore.CallOptions = .defaults,
        onResponse handleResponse: @Sendable @escaping (GRPCCore.ClientResponse<Primandproper_Platform_Billing_V1_ArchiveSubscriptionResponse>) async throws -> Result = { response in
            try response.message
        }
    ) async throws -> Result where Result: Sendable {
        let request = GRPCCore.ClientRequest<Primandproper_Platform_Billing_V1_ArchiveSubscriptionRequest>(
            message: message,
            metadata: metadata
        )
        return try await self.archiveSubscription(
            request: request,
            options: options,
            onResponse: handleResponse
        )
    }

    /// Call the "GetPurchase" method.
    ///
    /// > Source IDL Documentation:
    /// >
    /// > The one-time half.
    ///
    /// - Parameters:
    ///   - message: request message to send.
    ///   - metadata: Additional metadata to send, defaults to empty.
    ///   - options: Options to apply to this RPC, defaults to `.defaults`.
    ///   - handleResponse: A closure which handles the response and returns its result to
    ///       the caller. Returning from the closure will cancel the RPC if it hasn't
    ///       already finished.
    /// - Returns: The result of `handleResponse`.
    internal func getPurchase<Result>(
        _ message: Primandproper_Platform_Billing_V1_GetPurchaseRequest,
        metadata: GRPCCore.Metadata = [:],
        options: GRPCCore.CallOptions = .defaults,
        onResponse handleResponse: @Sendable @escaping (GRPCCore.ClientResponse<Primandproper_Platform_Billing_V1_GetPurchaseResponse>) async throws -> Result = { response in
            try response.message
        }
    ) async throws -> Result where Result: Sendable {
        let request = GRPCCore.ClientRequest<Primandproper_Platform_Billing_V1_GetPurchaseRequest>(
            message: message,
            metadata: metadata
        )
        return try await self.getPurchase(
            request: request,
            options: options,
            onResponse: handleResponse
        )
    }

    /// Call the "ListPurchases" method.
    ///
    /// - Parameters:
    ///   - message: request message to send.
    ///   - metadata: Additional metadata to send, defaults to empty.
    ///   - options: Options to apply to this RPC, defaults to `.defaults`.
    ///   - handleResponse: A closure which handles the response and returns its result to
    ///       the caller. Returning from the closure will cancel the RPC if it hasn't
    ///       already finished.
    /// - Returns: The result of `handleResponse`.
    internal func listPurchases<Result>(
        _ message: Primandproper_Platform_Billing_V1_ListPurchasesRequest,
        metadata: GRPCCore.Metadata = [:],
        options: GRPCCore.CallOptions = .defaults,
        onResponse handleResponse: @Sendable @escaping (GRPCCore.ClientResponse<Primandproper_Platform_Billing_V1_ListPurchasesResponse>) async throws -> Result = { response in
            try response.message
        }
    ) async throws -> Result where Result: Sendable {
        let request = GRPCCore.ClientRequest<Primandproper_Platform_Billing_V1_ListPurchasesRequest>(
            message: message,
            metadata: metadata
        )
        return try await self.listPurchases(
            request: request,
            options: options,
            onResponse: handleResponse
        )
    }

    /// Call the "ListPurchasesForAccount" method.
    ///
    /// - Parameters:
    ///   - message: request message to send.
    ///   - metadata: Additional metadata to send, defaults to empty.
    ///   - options: Options to apply to this RPC, defaults to `.defaults`.
    ///   - handleResponse: A closure which handles the response and returns its result to
    ///       the caller. Returning from the closure will cancel the RPC if it hasn't
    ///       already finished.
    /// - Returns: The result of `handleResponse`.
    internal func listPurchasesForAccount<Result>(
        _ message: Primandproper_Platform_Billing_V1_ListPurchasesForAccountRequest,
        metadata: GRPCCore.Metadata = [:],
        options: GRPCCore.CallOptions = .defaults,
        onResponse handleResponse: @Sendable @escaping (GRPCCore.ClientResponse<Primandproper_Platform_Billing_V1_ListPurchasesForAccountResponse>) async throws -> Result = { response in
            try response.message
        }
    ) async throws -> Result where Result: Sendable {
        let request = GRPCCore.ClientRequest<Primandproper_Platform_Billing_V1_ListPurchasesForAccountRequest>(
            message: message,
            metadata: metadata
        )
        return try await self.listPurchasesForAccount(
            request: request,
            options: options,
            onResponse: handleResponse
        )
    }

    /// Call the "ArchivePurchase" method.
    ///
    /// - Parameters:
    ///   - message: request message to send.
    ///   - metadata: Additional metadata to send, defaults to empty.
    ///   - options: Options to apply to this RPC, defaults to `.defaults`.
    ///   - handleResponse: A closure which handles the response and returns its result to
    ///       the caller. Returning from the closure will cancel the RPC if it hasn't
    ///       already finished.
    /// - Returns: The result of `handleResponse`.
    internal func archivePurchase<Result>(
        _ message: Primandproper_Platform_Billing_V1_ArchivePurchaseRequest,
        metadata: GRPCCore.Metadata = [:],
        options: GRPCCore.CallOptions = .defaults,
        onResponse handleResponse: @Sendable @escaping (GRPCCore.ClientResponse<Primandproper_Platform_Billing_V1_ArchivePurchaseResponse>) async throws -> Result = { response in
            try response.message
        }
    ) async throws -> Result where Result: Sendable {
        let request = GRPCCore.ClientRequest<Primandproper_Platform_Billing_V1_ArchivePurchaseRequest>(
            message: message,
            metadata: metadata
        )
        return try await self.archivePurchase(
            request: request,
            options: options,
            onResponse: handleResponse
        )
    }

    /// Call the "GetTransaction" method.
    ///
    /// > Source IDL Documentation:
    /// >
    /// > The ledger.
    ///
    /// - Parameters:
    ///   - message: request message to send.
    ///   - metadata: Additional metadata to send, defaults to empty.
    ///   - options: Options to apply to this RPC, defaults to `.defaults`.
    ///   - handleResponse: A closure which handles the response and returns its result to
    ///       the caller. Returning from the closure will cancel the RPC if it hasn't
    ///       already finished.
    /// - Returns: The result of `handleResponse`.
    internal func getTransaction<Result>(
        _ message: Primandproper_Platform_Billing_V1_GetTransactionRequest,
        metadata: GRPCCore.Metadata = [:],
        options: GRPCCore.CallOptions = .defaults,
        onResponse handleResponse: @Sendable @escaping (GRPCCore.ClientResponse<Primandproper_Platform_Billing_V1_GetTransactionResponse>) async throws -> Result = { response in
            try response.message
        }
    ) async throws -> Result where Result: Sendable {
        let request = GRPCCore.ClientRequest<Primandproper_Platform_Billing_V1_GetTransactionRequest>(
            message: message,
            metadata: metadata
        )
        return try await self.getTransaction(
            request: request,
            options: options,
            onResponse: handleResponse
        )
    }

    /// Call the "ListTransactions" method.
    ///
    /// - Parameters:
    ///   - message: request message to send.
    ///   - metadata: Additional metadata to send, defaults to empty.
    ///   - options: Options to apply to this RPC, defaults to `.defaults`.
    ///   - handleResponse: A closure which handles the response and returns its result to
    ///       the caller. Returning from the closure will cancel the RPC if it hasn't
    ///       already finished.
    /// - Returns: The result of `handleResponse`.
    internal func listTransactions<Result>(
        _ message: Primandproper_Platform_Billing_V1_ListTransactionsRequest,
        metadata: GRPCCore.Metadata = [:],
        options: GRPCCore.CallOptions = .defaults,
        onResponse handleResponse: @Sendable @escaping (GRPCCore.ClientResponse<Primandproper_Platform_Billing_V1_ListTransactionsResponse>) async throws -> Result = { response in
            try response.message
        }
    ) async throws -> Result where Result: Sendable {
        let request = GRPCCore.ClientRequest<Primandproper_Platform_Billing_V1_ListTransactionsRequest>(
            message: message,
            metadata: metadata
        )
        return try await self.listTransactions(
            request: request,
            options: options,
            onResponse: handleResponse
        )
    }

    /// Call the "ListTransactionsForAccount" method.
    ///
    /// - Parameters:
    ///   - message: request message to send.
    ///   - metadata: Additional metadata to send, defaults to empty.
    ///   - options: Options to apply to this RPC, defaults to `.defaults`.
    ///   - handleResponse: A closure which handles the response and returns its result to
    ///       the caller. Returning from the closure will cancel the RPC if it hasn't
    ///       already finished.
    /// - Returns: The result of `handleResponse`.
    internal func listTransactionsForAccount<Result>(
        _ message: Primandproper_Platform_Billing_V1_ListTransactionsForAccountRequest,
        metadata: GRPCCore.Metadata = [:],
        options: GRPCCore.CallOptions = .defaults,
        onResponse handleResponse: @Sendable @escaping (GRPCCore.ClientResponse<Primandproper_Platform_Billing_V1_ListTransactionsForAccountResponse>) async throws -> Result = { response in
            try response.message
        }
    ) async throws -> Result where Result: Sendable {
        let request = GRPCCore.ClientRequest<Primandproper_Platform_Billing_V1_ListTransactionsForAccountRequest>(
            message: message,
            metadata: metadata
        )
        return try await self.listTransactionsForAccount(
            request: request,
            options: options,
            onResponse: handleResponse
        )
    }

    /// Call the "ArchiveTransaction" method.
    ///
    /// - Parameters:
    ///   - message: request message to send.
    ///   - metadata: Additional metadata to send, defaults to empty.
    ///   - options: Options to apply to this RPC, defaults to `.defaults`.
    ///   - handleResponse: A closure which handles the response and returns its result to
    ///       the caller. Returning from the closure will cancel the RPC if it hasn't
    ///       already finished.
    /// - Returns: The result of `handleResponse`.
    internal func archiveTransaction<Result>(
        _ message: Primandproper_Platform_Billing_V1_ArchiveTransactionRequest,
        metadata: GRPCCore.Metadata = [:],
        options: GRPCCore.CallOptions = .defaults,
        onResponse handleResponse: @Sendable @escaping (GRPCCore.ClientResponse<Primandproper_Platform_Billing_V1_ArchiveTransactionResponse>) async throws -> Result = { response in
            try response.message
        }
    ) async throws -> Result where Result: Sendable {
        let request = GRPCCore.ClientRequest<Primandproper_Platform_Billing_V1_ArchiveTransactionRequest>(
            message: message,
            metadata: metadata
        )
        return try await self.archiveTransaction(
            request: request,
            options: options,
            onResponse: handleResponse
        )
    }
}