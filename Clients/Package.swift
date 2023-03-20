// swift-tools-version: 5.7

import PackageDescription

let package = Package(
  name: "Clients",
  defaultLocalization: .init("en"),
  platforms: [
    .iOS(.v16),
    .macOS(.v13),
    .watchOS(.v9),
  ],
  products: [
    .library(name: "Scanner", targets: ["Scanner"]),
  ],
  dependencies: [
    .package(path: "../MbientlabFoundation"),
    .package(
      url: "https://github.com/pointfreeco/swift-composable-architecture",
      branch: "prerelease/1.0"
    ),
  ],
  targets: [
    .target(
      name: "Scanner",
      dependencies: [
        "MbientlabFoundation",
        .product(name: "ComposableArchitecture", package: "swift-composable-architecture")
      ]
    ),
  ]
)
