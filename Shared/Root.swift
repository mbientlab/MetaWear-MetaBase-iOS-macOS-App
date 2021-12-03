// Copyright 2021 MbientLab Inc. All rights reserved. See LICENSE.MD.

import Foundation
import MetaWear
import Metadata

public class Root: ObservableObject {

    // State
    public let devices: MetaWearStore
    public let routing: Routing

    // Services
    private let scanner: MetaWearScanner

    // VMs
    public let factory: UIFactory
    public let discoveryVM: MetaWearDiscoveryVM
    public let bluetoothVM: BLEStateWarningsVM

    public init() {
        let loader  = MWCloudLoader.shared
        let scanner = MetaWearScanner.sharedRestore
        let devices = MetaWearStore(scanner: scanner, loader: loader)
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
        devices.load()
    }
}
