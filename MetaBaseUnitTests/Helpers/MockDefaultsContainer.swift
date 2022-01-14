// Copyright 2021 MbientLab Inc. All rights reserved. See LICENSE.MD.

import Foundation
import Combine
@testable import MetaBase
import MetaWear
import MetaWearSync

class MockDefaultsContainer: DefaultsContainer {

    let cloud: NSUbiquitousKeyValueStore
    let local: UserDefaults

    func cloudFirstArray<T>(of type: T.Type, for key: String) -> [T]? {
        let result = local.array(forKey: key) as? [T]
        cloudReads.append((key, result))
        return result
    }

    func setArray(_ array: [Any]?, forKey key: String) {
        local.set(array, forKey: key)
        cloudWrites.append((key, array))
    }

    var cloudWrites: [(key: String, value: Any?)] = []
    var cloudReads: [(key: String, value: Any?)] = []
    let localKeyMask: [String]

    func localContents() -> [String:Any] {
        var contents = local.dictionaryRepresentation()
        localKeyMask.forEach {
            contents.removeValue(forKey: $0)
        }
        return contents
    }

    init(file: String = #file, line: UInt32) {
        self.cloud = NSUbiquitousKeyValueStore()
        self.local = UserDefaults(suiteName: file + "\(line)")!
        self.localKeyMask = Array(local.dictionaryRepresentation().keys)
    }
}
