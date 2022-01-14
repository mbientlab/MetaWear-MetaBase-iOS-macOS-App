// Copyright 2022 MbientLab Inc. All rights reserved. See LICENSE.MD.

import mbientSwiftUI

public extension OnboardingSessionVM {

    struct Content {
        var items: [ItemsPanel.Item] = []
        var introTitle: String = ""
        var importTitle: String = ""
        var completeTitle: String = ""
    }
}

public extension OnboardingSessionVM.Content {

    static var newUserContent: Self = {
        .init(
            items: [
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
            ],
            introTitle: "Welcome to MetaBase",
            importTitle: "Migrate MetaBase 4 Data",
            completeTitle: "Welcome to MetaBase"
        )
    }()

    static var migrateMB4Content: Self = {
    #if os(macOS)
        let devicesTip = "iPads, iPhones, and Macs."
    #else
        let devicesTip = "iOS and MacOS. (Try our new native MacOS app!)"
    #endif

        return .init(
            items: [
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
            ],
            introTitle: "New in MetaBase 5",
            importTitle: "Migrate Data",
            completeTitle: "Welcome to MetaBase 5"
        )
    }()
}
