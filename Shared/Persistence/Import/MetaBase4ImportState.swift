// Copyright 2022 MbientLab Inc. All rights reserved. See LICENSE.MD.

import Foundation

struct MetaBase4ImportState {

    let dataExists: Bool
    let couldImport: Bool

    private static let key = UserDefaults.MetaWear.Keys.importedLegacySessions
    private static let prefix = LegacyMetadata.defaultsKeyPrefix

    init(_ defaults: DefaultsContainer, localDeviceID: String) {
        self.dataExists = Self.legacyDataExists(in: defaults.local)
        self.couldImport = dataExists ? !Self.didImportOnThisDevice(defaults, localDeviceID) : false
    }

    static func legacyDataExists(in defaults: UserDefaults) -> Bool {
        let decoder = JSONDecoder()
        return defaults.dictionaryRepresentation()
            .contains {
                guard $0.key.hasPrefix(Self.prefix),
                      let data = $0.value as? Data,
                      let metadata = try? decoder.decode(LegacyMetadata.self, from: data),
                      metadata.sessions.isEmpty == false
                else { return false }
                return true
            }
    }

    static func didImportOnThisDevice(_ defaults: DefaultsContainer, _ localDeviceID: String) -> Bool {
        guard let pastImports = defaults.cloudFirstArray(of: String.self, for: Self.key)
        else { return false }
        return pastImports.contains(localDeviceID)
    }
}
