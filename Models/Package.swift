// swift-tools-version: 5.7

import PackageDescription

let package = Package(
  name: "Models",
  defaultLocalization: .init("en"),
  platforms: [
    .iOS(.v16),
    .macOS(.v13),
    .watchOS(.v9),
  ],
  products: [
    .library(name: "Models", targets: ["Models"]),
    .library(name: "Mocks", targets: ["Mocks"]),
  ],
  dependencies: [
  ],
  targets: [
    .target(
      name: "Models",
      dependencies: []
    ),
    .target(
      name: "Mocks",
      dependencies: ["Models"]
    ),
    .testTarget(
      name: "MocksTests",
      dependencies: ["Mocks"]
    )
  ]
)
