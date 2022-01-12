// Copyright 2022 MbientLab Inc. All rights reserved. See LICENSE.MD.
#if DEBUG

import Foundation

func printUserDefaults() {
    let bundle = Bundle.main.bundleIdentifier!
    let defaults = UserDefaults.standard.persistentDomain(forName: bundle) ?? [:]
    let defaultsPath = NSSearchPathForDirectoriesInDomains(.libraryDirectory, .userDomainMask, true).first ?? "Error"

    print("")
    for key in defaults.sorted(by: { $0.key < $1.key }) {
        if key.key.contains("NSWindow Frame"), let value = key.value as? String {
            let dimensions = value.components(separatedBy: .whitespaces)
            let width = dimensions[2]
            let height = dimensions[3]
            print("Window", "w", width, "h", height)
        } else {
            print(key.key, ":", key.value)
        }
    }
    print("")
    print("Defaults stored at:", defaultsPath)
    print("")
}

func wipeDefaults(preserveMetaWearData: Bool) {
    let preserve: Set<String> = [
        UserDefaults.MetaWear.Keys.localPeripherals,
        UserDefaults.MetaWear.Keys.syncedMetadata,
        UserDefaults.MetaWear.Keys.loggingTokens
    ]

    UserDefaults.standard.dictionaryRepresentation().keys.forEach {
        if preserveMetaWearData, preserve.contains($0) { return }
        UserDefaults.standard.removeObject(forKey: $0)
    }
    NSUbiquitousKeyValueStore.default.dictionaryRepresentation.keys.forEach {
        if preserveMetaWearData, preserve.contains($0) { return }
        NSUbiquitousKeyValueStore.default.removeObject(forKey: $0)
    }
}

func wipeOnboarding() {
    [UserDefaults.MetaWear.Keys.didOnboardAppVersion,
     UserDefaults.MetaWear.Keys.didGetNearbyDeviceInstructionForVersion,
     UserDefaults.MetaWear.Keys.importedLegacySessions
    ].forEach  { key in
        UserDefaults.standard.removeObject(forKey: key)
        NSUbiquitousKeyValueStore.default.removeObject(forKey: key)
    }
}
#endif
