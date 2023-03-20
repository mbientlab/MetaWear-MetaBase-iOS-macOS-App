// swift-tools-version: 5.7

import PackageDescription

let package = Package(
  name: "Features",
  defaultLocalization: .init("en"),
  platforms: [
    .iOS(.v16),
    .macOS(.v13),
    .watchOS(.v9),
  ],
  products: [
    .library(name: "Root", targets: ["Root"]),
  ],
  dependencies: [
    .package(path: "../Clients"),
    .package(path: "../MbientlabFoundation"),
    .package(path: "../MbientlabUI"),
  ],
  targets: [
    .target(
      name: "Root",
      dependencies: [
        .product(name: "MetawearScanner", package: "Clients"),
        "MbientlabFoundation",
        "MbientlabUI"
      ]
    ),
  ]
)
