// swift-tools-version: 5.7

import PackageDescription

let package = Package(
  name: "MbientlabFoundation",
  defaultLocalization: .init("en"),
  platforms: [
    .iOS(.v16),
    .macOS(.v13),
    .watchOS(.v9),
  ],
  products: [
    .library(name: "MbientlabFoundation", targets: ["MbientlabFoundation"]),
  ],
  dependencies: [
  ],
  targets: [
    .target(
      name: "MbientlabFoundation",
      dependencies: []
    ),
  ]
)
