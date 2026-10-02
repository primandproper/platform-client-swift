// swift-tools-version: 6.0
import PackageDescription

let package = Package(
  name: "platform-client-swift",
  // grpc-swift-2 gates its API on these, so a lower floor only moves the error to the first
  // line that calls a GRPCClient.
  platforms: [.iOS(.v18), .macOS(.v15)],
  products: [
    .library(name: "PlatformClient", targets: ["PlatformClient"]),
    // Fakes for an app's own tests. A product of its own, so nothing in it can be linked into
    // an app by accident.
    .library(name: "PlatformClientTesting", targets: ["PlatformClientTesting"]),
  ],
  dependencies: [
    // The floors are what the committed generated code calls, so the generators pinned in
    // scripts/plugins/*/Package.swift dictate them: a plugin bump that emits a newer API moves
    // the matching floor in the same change. `make test-floors` builds and tests at exactly
    // these, which nothing else does, because SwiftPM always resolves the newest match.
    //
    // grpc-swift-2 needs 2.3.0 for MethodDescriptor(service:method:type:), which every
    // generated descriptor calls, and 2.4.1 for a client timeout to surface as
    // .deadlineExceeded rather than .unknown, which Session's exchange deadline relies on.
    .package(url: "https://github.com/grpc/grpc-swift-2.git", from: "2.4.1"),
    .package(url: "https://github.com/grpc/grpc-swift-protobuf.git", from: "2.1.1"),
    .package(url: "https://github.com/apple/swift-protobuf.git", from: "1.33.0"),
  ],
  targets: [
    .target(
      name: "PlatformClient",
      dependencies: [
        .product(name: "GRPCCore", package: "grpc-swift-2"),
        .product(name: "GRPCProtobuf", package: "grpc-swift-protobuf"),
        .product(name: "SwiftProtobuf", package: "swift-protobuf"),
      ],
      swiftSettings: [.swiftLanguageMode(.v6)]
    ),
    .target(
      name: "PlatformClientTesting",
      dependencies: [
        "PlatformClient",
        .product(name: "GRPCCore", package: "grpc-swift-2"),
        .product(name: "GRPCInProcessTransport", package: "grpc-swift-2"),
        .product(name: "GRPCProtobuf", package: "grpc-swift-protobuf"),
        .product(name: "SwiftProtobuf", package: "swift-protobuf"),
      ],
      swiftSettings: [.swiftLanguageMode(.v6)]
    ),
    .testTarget(
      name: "PlatformClientTests",
      dependencies: [
        "PlatformClient",
        "PlatformClientTesting",
        .product(name: "GRPCCore", package: "grpc-swift-2"),
      ],
      swiftSettings: [.swiftLanguageMode(.v6)]
    ),
  ]
)
