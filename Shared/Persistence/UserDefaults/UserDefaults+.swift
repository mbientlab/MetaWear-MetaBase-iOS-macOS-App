//  © 2021 Ryan Ferrell. github.com/importRyan


import Foundation
import MetaWear

let CurrentMetaBaseVersion = (Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? Double) ?? 5.0

public extension UserDefaults.MetaWear.Keys {

    /// Contains: Double. Access only via a store or KVO dynamic var.
    static let didOnboardAppVersion = key("didOnboardAppVersion")

    /// Contains: Int. Access only via stores.
    static let launchCount = key("launchCount")

    /// Contains: Versioned data. Access only via a store.
    static let sensorPresets = key("sensorPresets")

    /// Contains: Versioned data. Access only via a store.
    static let loggingTokens = key("loggingTokens")

    /// Contains: String value for session recording method.
    static let lastActionChoice = key("lastActionChoice")

    /// Contains: Boolean for UI state of having onboarded the new remote recording mode
    static let didOnboardRemoteMode = key("didOnboardRemoteMode")

    /// Contains: String array. Unique device identifiers (UUID string on iOS, ethernet MACs on Mac). Access only via a store.
    static let importedLegacySessions = key("importedLegacySessions")

    private static func key(_ key: String) -> String {
        Bundle.main.bundleIdentifier! + ".\(key)"
    }
}

public extension UserDefaults {
    @objc dynamic var didOnboardAppVersion: Double {
        get { double(forKey: UserDefaults.MetaWear.Keys.didOnboardAppVersion) }
        set { set(newValue, forKey: UserDefaults.MetaWear.Keys.didOnboardAppVersion) }
    }
}
public extension NSUbiquitousKeyValueStore {
    @objc dynamic var didOnboardAppVersion: Double {
        get { double(forKey: UserDefaults.MetaWear.Keys.didOnboardAppVersion) }
        set { set(newValue, forKey: UserDefaults.MetaWear.Keys.didOnboardAppVersion) }
    }
}
