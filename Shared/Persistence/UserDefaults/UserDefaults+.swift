//  © 2021 Ryan Ferrell. github.com/importRyan


import Foundation
import MetaWear

let CurrentMetaBaseVersion = 5.0

public extension UserDefaults.MetaWear.Keys {
    static let hasUsedMetaBaseVersion = Bundle.main.bundleIdentifier! + ".hasUsedMetabaseVersion"
    static let sensorPresets = "com.mbientlab.MetaBase.sensorPresets"
}
