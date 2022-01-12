// Copyright 2022 MbientLab Inc. All rights reserved. See LICENSE.MD.

import mbientSwiftUI

extension OnboardingVM {

    static func makeNewToMetaBaseContent() -> (String, [Item]) {
        ("Welcome to MetaBase", Self.makeNewToMetaBaseItems())
    }

    static func makeMetaBase4MigrationContent() -> (String, [Item]) {
        ("New in MetaBase 5", Self.makeMetaBase4MigrationItems())
    }

    // MARK: - Content


    static func makeNewToMetaBaseItems() -> [Item] {
        [
            .init(
                symbol: .barometer,
                headline: "Record Bluetooth Sensors",
                description: "Group and configure your MetaWear sensors to log or stream data in CSV format.",
                color: Color(.systemOrange)
            ),
            .init(
                symbol: .icloud,
                headline: "iCloud Sync",
                description: "Access sensor recordings across your iPads, iPhones, and Macs.",
                color: .myMint
            ),
            .init(
                symbol: .swift,
                headline: "Developing a MetaWear App?",
                description: "Our new Swift SDK is SwiftUI-friendly. Find demos on mbientLab's GitHub.",
                color: Color(.systemRed)
            ),
        ]
    }

    static func makeMetaBase4MigrationItems() -> [Item] {
#if os(macOS)
        let devicesTip = "iPads, iPhones, and Macs."
#else
        let devicesTip = "iOS and MacOS. (Try our new native MacOS app!)"
#endif

        return [
            .init(
                symbol: .icloud,
                headline: "iCloud Sync",
                description: "Sync recordings and settings across \(devicesTip)",
                color: .myMint
            ),
            .init(
                symbol: .shortcutMenu,
                headline: "Sensor Presets",
                description: "Save frequently used configurations for easier streaming and logging runs.",
                color: Color(.systemOrange)
            ),
            .init(
                symbol: .swift,
                headline: "Combine SDK",
                description: "For developers, our new Swift SDK is Bolts-free and SwiftUI-friendly. Find demos on mbientLab's GitHub.",
                color: Color(.systemRed)
            ),
        ]
    }
}
