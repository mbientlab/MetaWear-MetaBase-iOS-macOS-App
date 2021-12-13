// Copyright 2021 MbientLab Inc. All rights reserved. See LICENSE.MD.

import Foundation
import MetaWear
import MetaWearMetadata

public class Root: ObservableObject {

    // State
    public let devices: MetaWearStore
    public let routing: Routing

    // Services
    private let scanner: MetaWearScanner
    private let cloud: NSUbiquitousKeyValueStore
    private let local: UserDefaults
    private let metawearLoader: MWKnownDevicesPersistence

    // VMs
    public let factory: UIFactory
    public let discoveryVM: MetaWearDiscoveryVM
    public let bluetoothVM: BLEStateWarningsVM

    public init() {
        self.cloud = .default
        self.local = .standard
        self.metawearLoader  = MWCloudLoader(local: local, cloud: cloud)

        let scanner = MetaWearScanner.sharedRestore
        let devices = MetaWearStore(scanner: scanner, loader: metawearLoader)
        let routing = Routing()
        let factory = UIFactory(devices: devices, scanner: scanner, routing: routing)

        self.devices = devices
        self.routing = routing
        self.scanner = scanner
        self.factory = factory
        self.bluetoothVM = factory.makeBluetoothStateWarningsVM()
        self.discoveryVM = factory.makeMetaWearDiscoveryVM()
    }
}

public extension Root {

    func start() {
        do {
            try devices.load()
            let _ = cloud.synchronize()
        } catch { NSLog("Load Failure: \(error.localizedDescription)") }
    }
}
