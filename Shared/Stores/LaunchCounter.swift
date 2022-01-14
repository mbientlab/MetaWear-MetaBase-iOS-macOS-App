// Copyright 2022 MbientLab Inc. All rights reserved. See LICENSE.MD.

import Foundation

public class LocalLaunchCounter {

    public private(set) var launches: Int

    private unowned let defaults: UserDefaultsContainer
    private static let key = UserDefaults.MetaWear.Keys.launchCount

    public init(_ defaults: UserDefaultsContainer) {
        self.launches = defaults.local.integer(forKey: Self.key)
        self.defaults = defaults
    }

    public func markLaunched() {
        self.launches += 1
        defaults.local.set(self.launches, forKey: Self.key)
    }

    public func resetLaunches() {
        self.launches = 0
        defaults.local.set(0, forKey: Self.key)
    }
}
