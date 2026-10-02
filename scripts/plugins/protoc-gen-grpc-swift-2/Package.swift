// swift-tools-version: 6.0
import PackageDescription

// protoc-gen-grpc-swift-2, pinned, in a package of its own so it can take a different
// swift-protobuf from protoc-gen-swift's (see the third pin).
let package = Package(
  name: "grpc-swift-plugin",
  dependencies: [
    .package(url: "https://github.com/grpc/grpc-swift-protobuf.git", exact: "2.1.1"),
    // Transitive, and pinned anyway: the generator's output is produced by grpc-swift-2's
    // GRPCCodeGen, so letting it float would reintroduce the drift the pin above prevents.
    .package(url: "https://github.com/grpc/grpc-swift-2.git", exact: "2.4.3"),
    // Transitive too. grpc-swift-2 2.4.3 disables swift-protobuf's default traits, and
    // SwiftPM 6.2 refuses that against a swift-protobuf that declares none, which every
    // release before 1.36.0 does. This plugin only parses descriptors with it, so it does
    // not change what the plugin writes, and protoc-gen-swift keeps 1.33.3.
    .package(url: "https://github.com/apple/swift-protobuf.git", exact: "1.36.1"),
  ]
)
