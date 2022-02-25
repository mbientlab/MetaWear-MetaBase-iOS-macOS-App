// Copyright 2022 MbientLab Inc. All rights reserved. See LICENSE.MD.

import Foundation
import MetaWear

public class RecordingPreferenceStore {

    public private(set) var lastMode: RecordingModes

    private unowned let defaults: UserDefaultsContainer
    private static let key = UserDefaults.MetaWear.Keys.lastActionChoice

    public init(_ defaults: UserDefaultsContainer) {
        let value = defaults.local.string(forKey: Self.key) ?? ""
        self.lastMode = .init(rawValue: value) ?? .stream
        self.defaults = defaults
    }

    public func updateMode(to newMode: RecordingModes) {
        self.lastMode = newMode
        defaults.local.set(newMode.rawValue, forKey: Self.key)
    }
}
