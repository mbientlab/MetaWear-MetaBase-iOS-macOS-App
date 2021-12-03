// Copyright 2021 MbientLab Inc. All rights reserved. See LICENSE.MD.

import Foundation
import MetaWear
import Metadata

public class UIFactory: ObservableObject {

    public init(devices: MetaWearStore,
                scanner: MetaWearScanner,
                routing: Routing) {
        self.devices = devices
        self.scanner = scanner
        self.routing = routing
    }

    private unowned let devices: MetaWearStore
    private unowned let scanner: MetaWearScanner
    private unowned let routing: Routing
}

public extension UIFactory {

    func makeDiscoveredDeviceListVM() -> DiscoveryListVM {
        .init(scanner: scanner, store: devices)
    }

    func makeBluetoothStateWarningsVM() -> BLEStateWarningsVM {
        .init(scanner: scanner)
    }

    func makeMetaWearDiscoveryVM() -> MetaWearDiscoveryVM {
        .init(store: devices)
    }

    func makeMetaWearItemVM(_ item: Routing.Item) -> KnownItemVM {
        switch item {
            case .known(let mac):
                guard let known = devices.getDeviceAndMetadata(mac)
                else { fatalError() }
                return .init(device: known, store: devices, routing: routing)

            case .group(let id):
                guard let group = devices.getGroup(id: id)
                else { fatalError() }
                return .init(group: group, store: devices, routing: routing)
        }
    }

    func makeUnknownItemVM(_ id: CBPeripheralIdentifier) -> UnknownDeviceVM {
        .init(cbuuid: id, store: devices, routing: routing)
    }
}
