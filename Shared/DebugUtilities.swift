// Copyright 2022 MbientLab Inc. All rights reserved. See LICENSE.MD.
#if DEBUG

import Foundation
import Combine

let useMetabaseConsoleLogger = false
var root: Root!
var defaults: UserDefaultsContainer!
var sessionsRepo: SessionRepository!

func printUserDefaults() {
    let defaultsPath = NSSearchPathForDirectoriesInDomains(.libraryDirectory, .userDomainMask, true).first ?? "Error"

    print("-- LOCAL --")
    print("Defaults stored at:", defaultsPath)
    print("")
    for key in defaults.local.dictionaryRepresentation().sorted(by: { $0.key < $1.key }) {
        if key.key.contains("NSWindow Frame"), let value = key.value as? String {
            let dimensions = value.components(separatedBy: .whitespaces)
            let width = dimensions[2]
            let height = dimensions[3]
            print("Window", "w", width, "h", height)
        } else if key.key.contains("mbient") {
            print(key.key, ":", key.value)
        }
    }
    print("-- CLOUD -- ")
    for key in defaults.cloud.dictionaryRepresentation.sorted(by: { $0.key < $1.key }) {
        print(key.key, ":", key.value)
    }
    print("")
}

fileprivate var subs = Set<AnyCancellable>()

func wipeCloudSessionData() {
    sessionsRepo.fetchAllSessions()
        .sink { _ in } receiveValue: { allSessions in
            allSessions.forEach { session in
                sessionsRepo.deleteSession(session)
                    .sink { _ in } receiveValue: { _ in }
                    .store(in: &subs)
            }
        }
        .store(in: &subs)
}

func wipeDefaults(preserveMetaWearData: Bool) {
    wipeOnboarding()

    if !preserveMetaWearData {
        root.devices.knownDevices
            .sink {
                $0.forEach { root.devices.forget(globally: $0) }
                finishWipe(preserveMetaWearData: preserveMetaWearData)
            }
            .store(in: &subs)
    } else {
        finishWipe(preserveMetaWearData: preserveMetaWearData)
    }
}

private func finishWipe(preserveMetaWearData: Bool) {
    let preserve: Set<String> = [
        UserDefaults.MetaWear.Keys.localPeripherals,
        UserDefaults.MetaWear.Keys.syncedMetadata,
        UserDefaults.MetaWear.Keys.loggingTokens
    ]

    defaults.local.dictionaryRepresentation().keys.forEach {
        if preserveMetaWearData, preserve.contains($0) { return }
        defaults.local.removeObject(forKey: $0)
    }
    defaults.cloud.dictionaryRepresentation.keys.forEach {
        if preserveMetaWearData, preserve.contains($0) { return }
        defaults.cloud.removeObject(forKey: $0)
    }
    DispatchQueue.main.after(1) {
        printUserDefaults()
    }
}

func wipeOnboarding() {
    defaults.local.didOnboardAppVersion = 0.0
    [
        UserDefaults.MetaWear.Keys.launchCount,
        UserDefaults.MetaWear.Keys.didOnboardAppVersion,
        UserDefaults.MetaWear.Keys.importedLegacySessions,
    ].forEach  { key in
        defaults.local.removeObject(forKey: key)
        defaults.cloud.removeObject(forKey: key)
    }
    DispatchQueue.main.after(1) {
        printUserDefaults()
    }
}
#endif
