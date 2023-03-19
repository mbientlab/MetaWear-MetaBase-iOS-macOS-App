// swift-tools-version: 5.7

import PackageDescription

let package = Package(
  name: "MbientlabUI",
  defaultLocalization: .init("en"),
  platforms: [
    .iOS(.v16),
    .macOS(.v13),
    .watchOS(.v9),
  ],
  products: [
    .library(name: "MbientlabUI", targets: ["MbientlabUI"]),
  ],
  dependencies: [
  ],
  targets: [
    .target(
      name: "MbientlabUI",
      dependencies: [],
      resources: [
        .process("Resources")
      ]
    ),
    .testTarget(
      name: "MbientlabUITests",
      dependencies: ["MbientlabUI"]
    )
  ]
)
