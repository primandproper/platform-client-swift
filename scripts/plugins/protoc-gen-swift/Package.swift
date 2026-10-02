// swift-tools-version: 6.0
import PackageDescription

// protoc-gen-swift, pinned.
//
// It was installed with `brew install` before, which means "whatever is current on the
// machine that ran it", and the output differs between versions: swift-protobuf started
// emitting `nonisolated extension` after 1.33.3, so a developer and CI generated different
// files from identical .proto sources and the regeneration check failed on the difference
// rather than on anything real.
//
// Pinning the source schema is not enough. The generator is an input too.
//
// 1.33.3 is not arbitrary: it is what dinnerdonebetter's committed Swift output was
// generated with, and matching it is what keeps this package a drop-in for that app.
let package = Package(
  name: "swift-protobuf-plugin",
  dependencies: [
    .package(url: "https://github.com/apple/swift-protobuf.git", exact: "1.33.3")
  ]
)
