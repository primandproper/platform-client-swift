# platform-client-swift

The Swift client for services built on
[`platform-go`](https://github.com/primandproper/platform-go): generated stubs for
platform's own protos, and (not yet) the runtime that makes calling them safe.

It is the third tier. `primitives-*` is how to do a thing, `platform-go` is what a product
has, and this is **how to talk to a service built on platform-go**. A product's own protos
generate in the product's repository; only platform's generate here.

## Why it exists

DDB's iOS app and web frontend each maintain their own copy of this. Worse, most of each
copy is frozen: its Makefile carries nine Swift domains and eight TypeScript ones through
every regeneration as preserved directories, because — in its own words — *"it was generated
from this repository's own protos before each domain moved, so it describes services the
server no longer runs."*

They are preserved rather than regenerated because regenerating one means porting every call
site in two apps. This repository is what lets those domains land one at a time, against the
real schema, once instead of twice.

## What is here now

**Generated stubs only.** `Sources/PlatformClient/Generated/` holds 24 files — 12 protos as
`.pb.swift` and `.grpc.swift` — built from a pinned `platform-go` tag. The output is
**committed**, so a consumer needs neither `protoc` nor the plugins.

This is a drop-in for DDB's iOS app in the sense that matters — same schema, same generator
family, compatible API surface — but **not byte-identical to what that app has today**, and
deliberately so. Its files came from `brew install protoc-gen-grpc-swift`, which pins
nothing; these come from a pinned toolchain. The two differ in generated doc comments and in
`Sendable` conformances the pinned version emits and brew's does not. Reproducibility was
worth more than matching a build nobody can reproduce.

## What is not here yet

The runtime, and it is the part that matters — auth refresh, deadlines, pagination,
idempotency keys, stream reconnect, error mapping, and the headless flows over them. It is
specified in [`platform-go`'s client contract](https://github.com/primandproper/platform-go/blob/main/docs/client-contract.md),
and one of that document's open questions
([platform-go#869](https://github.com/primandproper/platform-go/issues/869)) has to be
answered before the refresh path can be written correctly.

When it lands it will **not** be a lift of iOS's `Services/Auth`. That code mixes RFC-shaped
protocol logic with Keychain, Network.framework and RevenueCat in one type, and lifting it
would carry iOS's constraints into the TypeScript client by way of a shared design. The
contract is written language-neutrally for that reason, and platform differences — credential
storage, transport — arrive as injected seams.

## Codegen

```bash
make codegen   # fetch the protos, then generate
make build     # swift build
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
and swift-protobuf's output changed after 1.33.3 — it began emitting `nonisolated extension`
— so the first CI run here generated different files from identical `.proto` sources and the
regeneration check failed on the difference. Those two versions are what dinnerdonebetter's
committed output was generated with, which is what keeps this package a drop-in for that app.

`protoc` itself is pinned to 33.1 for the same reason, and `generate.sh` refuses to run
against a different version rather than producing a diff nobody can read.

**One pin, one derived version.** `PLATFORM_GO_VERSION` names a `platform-go` tag. The
`primitives-go` version is *read out of that tag's `go.mod`* rather than pinned separately —
`filtering.proto` lives there, and generating it from a different version than the server was
built against is a wire mismatch nothing in this repository would catch.

`scripts/fetch-protos.sh` downloads both tarballs from GitHub and lays every `.proto` under
one include root. **No Go toolchain**: this is a Swift repository and it stays one, which is
why it fetches a tag rather than resolving the module cache the way DDB's Makefile does.

Flags match DDB's (`grpc-swift-2`, `Client=true,Server=false`, `Visibility=Public`), because
output that does not match is output that cannot be dropped in.

### Upgrading

Edit `PLATFORM_GO_VERSION`, run `make codegen`, commit the diff. CI fails if the committed
output is not exactly what the pinned tag produces, so a bumped pin without a regeneration —
or a hand-edited generated file — is a red build rather than a runtime surprise.
