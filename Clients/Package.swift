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
    .library(name: "MetawearScanner", targets: ["MetawearScanner"]),
  ],
  dependencies: [
    .package(path: "../MbientlabFoundation"),
  ],
  targets: [
    .target(
      name: "MetawearScanner",
      dependencies: [
        "MbientlabFoundation",
      ]
    ),
  ]
)
