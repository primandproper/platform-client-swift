# platform-client-swift

The Swift client for services built on
[`platform-go`](https://github.com/primandproper/platform-go): generated stubs for
platform's own protos, and the runtime that makes calling them safe.

It is the third tier. `primitives-*` is how to do a thing, `platform-go` is what a product
has, and this is **how to talk to a service built on platform-go**. A product's own protos
generate in the product's repository; only platform's generate here.

## Why it exists

DDB's iOS app and web frontend each maintain their own copy of this. Worse, most of each
copy is frozen: its Makefile carries nine Swift domains and eight TypeScript ones through
every regeneration as preserved directories, because (in its own words) *"it was generated
from this repository's own protos before each domain moved, so it describes services the
server no longer runs."*

They are preserved rather than regenerated because regenerating one means porting every call
site in two apps. This repository is what lets those domains land one at a time, against the
real schema, once instead of twice.

## What it speaks

**platform-go v14.2.0** (`PLATFORM_GO_VERSION`). The generated stubs under
`Sources/PlatformClient/Generated/` are exactly that tag's protos (and the `primitives-go` ones
its `go.mod` names), and the runtime beside them
implements
[`platform-go`'s client contract](https://github.com/primandproper/platform-go/blob/v14.2.0/docs/client-contract.md)
as it describes that tag. Some rules need a server at least that new: R10 (the keyed refresh
retry, which is opt-in for that reason) and R11 (sign-in reasons, which an older server simply
does not send) from v14.1.0, and R18 to R20 (passkey sign-in and switching accounts, whose RPCs
an older server does not have) from v14.2.0.

The generated output is **committed**, so a consumer needs neither `protoc` nor the plugins.
It is a drop-in for DDB's iOS app in the sense that matters (same schema, same generator
family, compatible API surface) but **not byte-identical to what that app generated with
`brew install protoc-gen-grpc-swift`**, and deliberately so: brew pins nothing, and these come
from a pinned toolchain ([below](#codegen)). The two differ in generated doc comments and in
`Sendable` conformances the pinned version emits and brew's does not. Reproducibility was worth
more than matching a build nobody can reproduce.

### What a version promises

A version of this package states the platform-go tag it speaks, which is `PLATFORM_GO_VERSION`
at that version. Its version is its own rather than a mirror of that tag, because a client-only
fix needs a version number of its own to ship under. A bump of the pin is at least a minor
version. The package stays `0.x` until its consumer has adopted it on a released version.

## Using it

The package takes no transport dependency: a `Session` wraps whatever `GRPCClient` the app
builds. An iOS app builds one over `HTTP2ClientTransport.TransportServices` from
[`grpc-swift-nio-transport`](https://github.com/grpc/grpc-swift-nio-transport), which it adds
itself.

One `Session` per process, for every service the app calls: platform's and the product's own.
It holds the session, refreshes it, and hands each call the metadata that carries the access
token. The tenant (R12) does not go through it: it rides a `ConstantMetadataInterceptor` on the
`GRPCClient`, so it reaches anonymous and authenticated calls alike, the Session's own
exchanges included.

```swift
import GRPCCore
import GRPCNIOTransportHTTP2
import PlatformClient

let transport = try HTTP2ClientTransport.TransportServices(
  target: .dns(host: "api.example.com", port: 443),
  transportSecurity: .tls
)
let client = GRPCClient(
  transport: transport,
  // only if the deployment carries the tenant in metadata
  interceptors: [ConstantMetadataInterceptor(["x-tenant": "acme"])]
)
Task { try await client.runConnections() }

let session = Session(
  client: client,
  store: KeychainCredentialStore(service: "com.example.app", account: "session"),
  idempotentRefresh: true  // R10: only if the server is v14.1.0+ AND its refresh-token store supports it
)

let attempt = try await session.signIn(
  PasswordSignIn(handle: .emailAddress("a@example.com"), password: password))
if case .secondFactorRequired(let resend) = attempt {
  _ = try await resend(await promptForCode())
}

let status = try await session.getAuthStatus()  // .authenticated(s): s.requiredActions says where to send them

// Any generated client over the same GRPCClient, a product's own included, is called through
// session.call, so it shares the one refresher instead of racing it.
let identity = Primandproper_Platform_Identity_V1_IdentityService.Client(wrapping: client)
let request = Primandproper_Platform_Identity_V1_GetUserRequest.with { $0.userID = userID }
let user = try await session.call { metadata in
  try await identity.getUser(request, metadata: metadata)
}
```

`Session` is an actor, and `states()` streams its `SessionState` for a view model to observe.
Password reset, email verification, magic links and attaching a password are free functions
over the `GRPCClient` (`requestPasswordReset`, `verifyPasswordResetToken`,
`completePasswordReset`, `verifyEmailAddress`, `attachPassword`, `requestMagicLink`), because
none of them holds a session. Passkey sign-in is `beginPasskeySignIn` and `passkeySignIn` on
the Session, with `PasskeyAssertionOptions` and `PasskeyAssertion` bridging the WebAuthn JSON to
and from AuthenticationServices. `Pages` and `Items` walk a list RPC.

A settings form holds text, and a setting's value is a
`Primandproper_Platform_Settings_V1_TypedValue` (`TypedValue` here). `TypedValue(text:kind:)`
builds the value a write carries, accepting exactly the text the server reads as that kind
(Go's `strconv`, so `"True"` and `"NaN"` pass) and throwing `SettingValueError` otherwise; its
`description` is the form error. `TypedValue.text` reads one back in the form the server stores
and compares enumeration options in, and is `nil`, not `""`, for an unset resolution. The case
always follows the setting's kind, so a string setting answered `"42"` is written as a string.

Push registration is `Devices`, an actor over the `Session` and the same `GRPCClient`. The app
hands it the APNs token from `didRegisterForRemoteNotificationsWithDeviceToken`; a token that
arrives before sign-in is held and registered once the session is authenticated (the call
throws `NotSignedInError` meanwhile, and the app need not hand it over again). The
registration is kept in a `DeviceRegistrationStore`, `KeychainDeviceRegistrationStore` unless
told otherwise, with the login it was made under: the same token under the same login makes no
call, a rotated one registers and then revokes the old registration, and a new login registers
again. Signing out revokes it first, while the session can still make the call:

```swift
let devices = Devices(session: session, client: client)
_ = try? await devices.register(apnsToken: deviceToken, platform: .ios)

// signing out
try? await devices.revoke()
await session.signOut()
```

**`KeychainCredentialStore` is opt-in.** It holds the session as one generic-password item in
the data protection keychain, readable after first unlock (so a background refresh can reach
it) and never backed up or restored onto another device. It does not read what any earlier
store wrote: moving or discarding that item is the app's migration. Anything else that
conforms to `CredentialStore` will do, as long as it belongs in the platform's most protected
store: the refresh token in it is the one worth stealing.

**`idempotentRefresh` is off by default.** A client cannot tell from the wire whether the
server supports R10, and against one that does not, a keyed retry is a bare retry: reuse, and
the login revoked. Off, an exchange that fails ambiguously keeps the session until its access
token expires and never re-sends the refresh token (R5).

`PlatformClientTesting` is a product of its own, for an app's tests: `FakeServer` (a real gRPC
server over the in-process transport), `FakeClock`, `MemoryCredentialStore`,
`MemoryDeviceRegistrationStore`, `fakeIssuedToken` and `refusal`. It is separate so nothing in it can be linked into an app by
accident.

### A token held somewhere else

An app moving onto platform from its own sign-in already has an access token and refreshes it
elsewhere, so there is nothing for a `Session` to hold. `TokenCaller` lets it adopt the stubs
first: it sends whatever token it is handed, through the same `Authorizer` a `Session` would
use, and the tenant still rides the interceptor on the `GRPCClient`.

```swift
let caller = TokenCaller()
let user = try await caller.call(accessToken) { metadata in
  try await identity.getUser(request, metadata: metadata)
}
```

It holds no state, so R1 to R7 do not apply to it. It never refreshes and never retries: a call
answered `UNAUTHENTICATED` throws that `PlatformError`, and signing the person in again is the
caller's job. `callAnonymous` makes a call with no credential (`Register` has no helper and goes
through it). Once the login moves onto platform's `SignInService`, the caller should be a
`Session`.

### What was not ported

TypeScript's `ExchangeCoordinator` and `SharedExchangeCoordinator` have no counterpart here.
Both exist because a backend-for-frontend builds a `Session` per request, so many Sessions, and
in a deployment of several instances many processes, hold one refresh token and have to agree
on who exchanges it. An app has one process and one `Session`, and the `Session` is an actor:
actor isolation, with every concurrent caller awaiting the one exchange in flight, is the whole
of R1.

## Migrating

**The error type changed, and the compiler will not tell you.** `Session.call`, `TokenCaller`,
the sign-in helpers and the anonymous free functions convert a gRPC status to `PlatformError`
before throwing it. Nothing they throw is a `GRPCCore.RPCError`, so an existing
`catch let error as RPCError` still compiles and silently stops matching: the error falls
through to the next `catch`, and a server-down check written against `RPCError.code` never
fires.

Catch `PlatformError` instead. It carries the same `code`, plus the reason where there is one
(R11, R13), and `serverMessage` (also its `localizedDescription`) is what to show a person.
The `RPCError` it was read from stays on it as `rpcError`, for the trailing metadata and
`cause` a log line wants:

```swift
do {
  _ = try await session.call { metadata in
    try await identity.getUser(request, metadata: metadata)
  }
} catch let error as PlatformError where error.code == .unavailable {
  // the server is down
} catch let error as PlatformError where error.is(SignInReason.passwordChangeRequired) {
  // send them to the form
}
```

Where a `catch` can still see a raw `RPCError`, from a stub called outside the Session, say,
`toPlatformError(_:)` converts one and returns anything else unchanged:

```swift
if let refusal = toPlatformError(error) as? PlatformError, refusal.code == .unavailable {
  // the server is down
}
```

Errors that carry no status pass through as they were: `NotSignedInError` when there is no
session to call with, `MissingTokenError`, a `CredentialStore`'s own errors, and
`CancellationError`.

## The contract, rule by rule

Every file below is under `Sources/PlatformClient/`.

| rule | what | where |
| --- | --- | --- |
| R1 | one refresh at a time | `Session.swift`: `Session` (an actor; `fly`) |
| R2 | a failed refresh that is not a refusal does not sign out | `Session.swift`: `Session` (`settleFailedExchange`) |
| R3 | one refresh-and-retry on `UNAUTHENTICATED`, never a loop | `Session.swift`: `Session.call` |
| R4 | an idempotency key per logical operation, outside the retry | `Session.swift`: `Session` (`exchange(_:)`) for the refresh exchange; any other call adds its own `idempotency-key` to the metadata `Session.call` hands it |
| R5 | never re-send a refresh token bare | `Session.swift`: `Session` (`abandonRefreshToken`) |
| R6 | persist the successor before using it | `Session.swift`: `Session` (`adopt`) |
| R7 | `UNAUTHENTICATED` from an exchange is signed out, no questions | `Session.swift`: `Session` (`settleFailedExchange`) |
| R8 | cursors are opaque | `Pagination.swift`: `Pages`, `Items` |
| R9 | `counts_known` gates the counts | `Pagination.swift`: `Pagination.counts`, `ListResponse.counts` |
| R10 | retry an ambiguous exchange once, same key | `Session.swift`: `Session.init(idempotentRefresh:)` (opt-in); `Errors.swift`: `isAmbiguous` |
| R11 | branch on the reason, never the message | `Errors.swift`: `PlatformError.is`, `SignInReason`, `PasskeyReason`, `PasswordResetReason` |
| R12 | the tenant travels identically on every call | `ConstantMetadataInterceptor.swift`: `ConstantMetadataInterceptor`, on the `GRPCClient` every call goes through |
| R13 | the reason where there is one, the code where there is not | `Errors.swift`: `PlatformError`, `toPlatformError` |
| R14 | walk until a page has no rows | `Pagination.swift`: `Pages` |
| R15 | the same screen whether the address exists or not | `PasswordReset.swift`: `requestPasswordReset`; `Registration.swift`: `requestMagicLink` |
| R16 | verify a reset link before rendering the form | `PasswordReset.swift`: `verifyPasswordResetToken` |
| R17 | sign out on the server, then locally | `SignOut.swift`: `Session.signOut`, `Session.signOutEverywhere` |
| R18 | a passkey sign-in is a sign-in | `Passkeys.swift`: `Session.passkeySignIn` |
| R19 | a key tap is one factor | `Passkeys.swift`: `PasskeySignInResult.secondFactorRequired`; `PasskeyBridge.swift`: `PasskeyAssertionOptions.request` (asks for user verification by default) |
| R20 | a switch is a refresh | `Session.swift`: `Session.switchAccount` |

Streams are not covered, because the contract parks them: no platform-go proto declares one.

### Is the server down, or is it me?

`isTransient` (`Errors.swift`) answers it, beside `isAmbiguous`: true when the server could not
answer right now and trying later may succeed, which is what "try again later" and a breaker
consult. It reads a `PlatformError` and a bare `RPCError` alike; a wrapper of the app's own is
the app's to unwrap first.

| failure | transient | why |
| --- | --- | --- |
| `UNAVAILABLE` | yes | the server, or the way to it, is down |
| `DEADLINE_EXCEEDED` | yes | the server did not answer in time |
| `RESOURCE_EXHAUSTED` | yes | the server is shedding load or rate limiting; later may be under the limit |
| `CANCELLED`, `CancellationError` | no | the caller backed out; nothing is wrong with the server |
| `INTERNAL`, `UNKNOWN` | no | the server's fault, but a bug: a breaker that trips on it hides the bug behind "try later" |
| `DATA_LOSS` | no | a bug as well, and one trying again does not fix |
| `UNIMPLEMENTED` | no | this client and the server disagree on the API; that does not pass |
| `ABORTED` | no | the server answered: a conflict, retried as an operation, not waited out |
| `UNAUTHENTICATED`, `PERMISSION_DENIED` | no | the caller's credential, not the server's health |
| `INVALID_ARGUMENT`, `OUT_OF_RANGE`, `NOT_FOUND`, `ALREADY_EXISTS`, `FAILED_PRECONDITION` | no | the request, which fails the same way every time |
| no status at all, `ExchangeNotSentError` among them | no | it failed on this device and never reached the server: a transport that could not reach it is `UNAVAILABLE` |

## Codegen

```bash
make codegen        # fetch the protos, then generate
make build          # swift build
make format lint    # swift-format, then swift-format --strict and shellcheck
make test           # swift test
make test-keychain  # the Keychain tests, on an iOS Simulator under a host app
make test-floors    # swift test with every dependency at exactly its declared floor
```

**The generator is pinned too, not just the schema.** `scripts/plugins/` holds one manifest
per plugin, pinning `swift-protobuf` to 1.33.3 for `protoc-gen-swift` and `grpc-swift-protobuf`
to 2.1.1 for `protoc-gen-grpc-swift-2`, and `generate.sh` builds them rather than using
whatever is on the machine.

They are two packages because they cannot share a `swift-protobuf` on SwiftPM 6.2 or later:
`grpc-swift-2` 2.4.3, which the grpc plugin's output comes from, disables `swift-protobuf`'s
default traits, and SwiftPM refuses that against any release before 1.36.0, which declare
none. So the grpc plugin gets 1.36.1, which it only parses descriptors with, and
`protoc-gen-swift` keeps 1.33.3. DDB's `scripts/protoc-plugins` is the same split.

That is not defensive tidiness. `brew install swift-protobuf` gives you whatever is current,
and swift-protobuf's output changed after 1.33.3 (it began emitting `nonisolated extension`),
so the first CI run here generated different files from identical `.proto` sources and the
regeneration check failed on the difference. Those two versions are what dinnerdonebetter's
committed output was generated with, which is what keeps this package a drop-in for that app.

`protoc` itself is pinned to 33.1 for the same reason, and `generate.sh` refuses to run
against a different version rather than producing a diff nobody can read.

**One pin, one derived version.** `PLATFORM_GO_VERSION` names a `platform-go` tag. The
`primitives-go` version is *read out of that tag's `go.mod`* rather than pinned separately:
`filtering.proto` lives there, and generating it from a different version than the server was
built against is a wire mismatch nothing in this repository would catch.

`scripts/fetch-protos.sh` downloads both tarballs from GitHub and lays every `.proto` under
one include root. **No Go toolchain**: this is a Swift repository and it stays one, which is
why it fetches a tag rather than resolving the module cache the way DDB's Makefile does.

Flags match DDB's (`grpc-swift-2`, `Client=true,Server=false`, `Visibility=Public`), because
output that does not match is output that cannot be dropped in, with one difference: here
`Visibility=Public` goes to the grpc plugin as well. DDB compiles its stubs into the app's
own module, where `internal` clients are reachable; from a package they are not.

`generate.sh` runs `scripts/generate-list-conformances.sh` last, which writes
`ListConformances.swift`: the `ListRequest` and `ListResponse` conformances `Pages` needs, for
every generated message with the shape. A product's own list request and response conform
with one empty extension each.

### Upgrading

Edit `PLATFORM_GO_VERSION`, run `make codegen`, commit the diff. CI fails if the committed
output is not exactly what the pinned tag produces, so a bumped pin without a regeneration (or
a hand-edited generated file) is a red build rather than a runtime surprise. A bumped pin is at
least a minor version of this package ([above](#what-a-version-promises)).
