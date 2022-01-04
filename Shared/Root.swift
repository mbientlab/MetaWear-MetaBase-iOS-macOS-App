// Copyright 2021 MbientLab Inc. All rights reserved. See LICENSE.MD.

import Foundation
import MetaWear
import MetaWearSync
import mbientSwiftUI

public class Root: ObservableObject {

    // State
    public let devices:  MetaWearSyncStore
    public let presets:  PresetSensorParametersStore
    public let logging:  ActiveLoggingSessionsStore
    public let routing:  Routing

    // Services
    private let scanner:        MetaWearScanner
    private let sessions:       SessionRepository
    private let coreData:       CoreDataBackgroundController
    private let userDefaults:   UserDefaultsContainer
    private let metawearLoader: MWLoader<MWKnownDevicesLoadable>
    private let presetsLoader:  MWLoader<SensorPresetsLoadable>
    private let loggingLoader:  MWLoader<LoggingTokensLoadable>

    // VMs
    public let factory:     UIFactory
    public let bluetoothVM: BluetoothStateVM

    public init() {
        self.coreData = CloudKitCoreDataController(inMemory: false)
        self.sessions = CoreDataSessionRepository(coreData: coreData)

        self.userDefaults = .init(cloud: .default, local: .standard)
        self.metawearLoader  = MetaWeariCloudSyncLoader(userDefaults.local, userDefaults.cloud)
        self.presetsLoader   = SensorPresetsCloudLoader(userDefaults)
        self.loggingLoader   = LoggingTokensCloudLoader(userDefaults)

        let scanner = MetaWearScanner.sharedRestore
        let devices = MetaWearSyncStore(scanner: scanner, loader: metawearLoader)
        self.presets = PresetSensorParametersStore(loader: presetsLoader)
        self.logging = ActiveLoggingSessionsStore(loader: loggingLoader)
        let routing = Routing()
        let factory = UIFactory(devices, sessions, presets, logging, scanner, routing)

        self.devices = devices
        self.routing = routing
        self.scanner = scanner
        self.factory = factory
        self.bluetoothVM = factory.makeBluetoothStateWarningsVM()
    }
}

public extension Root {

    func start() {
        do {
            try devices.load()
            try presets.load()
            try logging.load()
            let _ = userDefaults.cloud.synchronize()
#if DEBUG
            debugs()
#endif
        } catch { NSLog("Load Failure: \(error.localizedDescription)") }
    }
}

#if DEBUG
fileprivate func debugs() {
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

func wipeDefaults() {
    UserDefaults.standard.dictionaryRepresentation().forEach { element in
        UserDefaults.standard.removeObject(forKey: element.key)
    }
    NSUbiquitousKeyValueStore.default.dictionaryRepresentation.keys.forEach {
        NSUbiquitousKeyValueStore.default.removeObject(forKey: $0)
    }
}
#endif

class UserDefaultsContainer {
    internal init(cloud: NSUbiquitousKeyValueStore, local: UserDefaults) {
        self.cloud = cloud
        self.local = local
    }

    let cloud: NSUbiquitousKeyValueStore
    let local: UserDefaults
}
