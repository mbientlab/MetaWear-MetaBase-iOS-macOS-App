// Copyright 2021 MbientLab Inc. All rights reserved. See LICENSE.MD.

import Foundation
import MetaWear
import Metadata

public class UIFactory: ObservableObject {

    public init(devices: MetaWearStore,
                scanner: MetaWearScanner,
                routing: Routing) {
        self.store = devices
        self.scanner = scanner
        self.routing = routing
    }

    private unowned let store: MetaWearStore
    private unowned let scanner: MetaWearScanner
    private unowned let routing: Routing
}

public extension UIFactory {

    func makeDiscoveredDeviceListVM() -> DiscoveryListVM {
        .init(scanner: scanner, store: store)
    }

    func makeBluetoothStateWarningsVM() -> BLEStateWarningsVM {
        .init(scanner: scanner)
    }

    func makeMetaWearDiscoveryVM() -> MetaWearDiscoveryVM {
        .init(store: store)
    }

    func makeMetaWearItemVM(_ item: Routing.Item) -> KnownItemVM {
        switch item {
            case .known(let mac):
                guard let known = store.getDeviceAndMetadata(mac)
                else { fatalError() }
                return .init(device: known, store: store, routing: routing)

            case .group(let id):
                guard let group = store.getGroup(id: id)
                else { fatalError() }
                return .init(group: group, store: store, routing: routing)
        }
    }

    func makeUnknownItemVM(_ id: CBPeripheralIdentifier) -> UnknownDeviceVM {
        .init(cbuuid: id, store: store, routing: routing)
    }

    func makeAboutDeviceVM(device: MWKnownDevice) -> AboutDeviceVM {
        .init(device: device, store: store)
    }

    func makeHistoryScreenVM(item: Routing.Item) -> HistoryScreenVM {
        var vms: [AboutDeviceVM] = []
        switch item {
            case .group(let id):
                guard let group = store.getGroup(id: id) else { break }
                let devices = store.getDevicesInGroup(group)
                vms = devices.map(makeAboutDeviceVM(device:))

            case .known(let mac):
                guard let device = store.getDeviceAndMetadata(mac) else { break }
                vms = [makeAboutDeviceVM(device: device)]
        }
        return .init(item: item, vms: vms, store: store, routing: routing, scanner: scanner)
    }
}
