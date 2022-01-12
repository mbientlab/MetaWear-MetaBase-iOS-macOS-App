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
    private let importer:       MetaBase4SessionDataImporter
    private let metawearLoader: MWLoader<MWKnownDevicesLoadable>
    private let presetsLoader:  MWLoader<SensorPresetsLoadable>
    private let loggingLoader:  MWLoader<LoggingTokensLoadable>

    // UI
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
        let importer = MetaBase4SessionDataImporter(
            sessions: sessions,
            devices: devices,
            defaults: userDefaults
        )
        let routing = Routing()
        let factory = UIFactory(devices, sessions, presets, logging, importer, scanner, routing)

        self.devices = devices
        self.routing = routing
        self.scanner = scanner
        self.factory = factory
        self.importer = importer
        self.bluetoothVM = factory.makeBluetoothStateWarningsVM()
    }
}

public extension Root {

    func start() {
        do {
            coreData.setup()
            try devices.load()
            try presets.load()
            try logging.load()
            let _ = userDefaults.cloud.synchronize()
#if DEBUG
            printUserDefaults()
#endif
        } catch { NSLog("Load Failure: \(error.localizedDescription)") }
    }
}
