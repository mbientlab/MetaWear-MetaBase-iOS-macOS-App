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
    .library(name: "MainSplitScreen", targets: ["MainSplitScreen"]),
    .library(name: "MainTabsScreen", targets: ["MainTabsScreen"]),
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
        "MbientlabUI",
        "MainSplitScreen",
        "MainTabsScreen",
      ]
    ),
    .target(
      name: "MainSplitScreen",
      dependencies: [
        "MbientlabFoundation",
        "MbientlabUI"
      ]
    ),
    .target(
      name: "MainTabsScreen",
      dependencies: [
        "MbientlabFoundation",
        "MbientlabUI"
      ]
    ),
  ]
)
