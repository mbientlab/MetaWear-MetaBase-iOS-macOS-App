// Copyright 2022 MbientLab Inc. All rights reserved. See LICENSE.MD.

import Foundation

public class UserDefaultsContainer {
    public init(cloud: NSUbiquitousKeyValueStore, local: UserDefaults) {
        self.cloud = cloud
        self.local = local
    }

    public let cloud: NSUbiquitousKeyValueStore
    public let local: UserDefaults
}

public extension UserDefaultsContainer {

    /// Gets Bool from Cloud, if preset, then local
    ///
    func cloudFirst(for key: String) -> Bool {
        cloud.dictionaryRepresentation[key] as? Bool
        ?? local.bool(forKey: key)
    }

    /// Gets cast array of objects for a key, if present, then local, if present
    ///
    func cloudFirstArray<T>(of type: T.Type, for key: String) -> [T]? {
        cloud.array(forKey: key) as? [T] ?? local.array(forKey: key) as? [T]
    }

    func setBool(_ bool: Bool, forKey key: String) {
        cloud.set(bool, forKey: key)
        local.set(bool, forKey: key)
    }

    func setArray(_ array: [Any]?, forKey key: String) {
        cloud.set(array, forKey: key)
        local.set(array, forKey: key)
    }
}
