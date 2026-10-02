// swift-tools-version: 6.0
import PackageDescription

let package = Package(
  name: "platform-client-swift",
  // grpc-swift-2 gates its API on these, so a lower floor only moves the error to the first
  // line that calls a GRPCClient.
  platforms: [.iOS(.v18), .macOS(.v15)],
  products: [
    .library(name: "PlatformClient", targets: ["PlatformClient"])
  ],
  dependencies: [
    // Versions match what dinnerdonebetter's iOS app already links, because this package
    // has to drop into that app beside them rather than drag it onto a second grpc-swift.
    .package(url: "https://github.com/grpc/grpc-swift-2.git", from: "2.1.0"),
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
    .testTarget(
      name: "PlatformClientTests",
      dependencies: ["PlatformClient"],
      swiftSettings: [.swiftLanguageMode(.v6)]
    ),
  ]
)
