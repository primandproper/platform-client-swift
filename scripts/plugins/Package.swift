// swift-tools-version: 6.0
import PackageDescription

// The codegen plugins, pinned.
//
// They were installed with `brew install` before, which means "whatever is current on the
// machine that ran it" — and the output differs between versions: swift-protobuf started
// emitting `nonisolated extension` after 1.33.3, so a developer and CI generated different
// files from identical .proto sources and the regeneration check failed on the difference
// rather than on anything real.
//
// Pinning the source schema is not enough. The generator is an input too.
//
// 1.33.3 is not arbitrary: it is what dinnerdonebetter's committed Swift output was
// generated with, and matching it is what keeps this package a drop-in for that app.
let package = Package(
  name: "plugins",
  dependencies: [
    .package(url: "https://github.com/apple/swift-protobuf.git", exact: "1.33.3"),
    .package(url: "https://github.com/grpc/grpc-swift-protobuf.git", exact: "2.1.1"),
    // Transitive, and pinned anyway: the grpc plugin's output tracks this, so letting it
    // float would reintroduce exactly the drift the two pins above exist to prevent.
    // 2.4.3 is what resolving the two above produced.
    .package(url: "https://github.com/grpc/grpc-swift-2.git", exact: "2.4.3"),
  ]
)
