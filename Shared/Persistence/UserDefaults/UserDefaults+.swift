//  © 2021 Ryan Ferrell. github.com/importRyan


import Foundation
import MetaWear

let CurrentMetaBaseVersion = 5.0

public extension UserDefaults.MetaWear.Keys {

    /// Contains: Double
    static let hasUsedMetaBaseVersion = key("hasUsedMetabaseVersion")

    /// Contains: Versioned data
    static let sensorPresets = key("sensorPresets")

    /// Contains: Versioned data
    static let loggingTokens = key("loggingTokens")

    /// Contains: String array. Unique device identifiers (UUID string on iOS, ethernet MACs on Mac)
    static let importedLegacySessions = key("importedLegacySessions")

    private static func key(_ key: String) -> String {
        Bundle.main.bundleIdentifier! + ".\(key)"
    }
}
