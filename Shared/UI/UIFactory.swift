// Copyright 2021 MbientLab Inc. All rights reserved. See LICENSE.MD.

import Foundation
import MetaWear
import MetaWearMetadata

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
    private lazy var actionQueue = DispatchQueue(label: Bundle.main.bundleIdentifier! + ".action",
                                                 qos: .userInitiated,
                                                 attributes: .concurrent)
}

public extension UIFactory {

    func makeDiscoveredDeviceListVM() -> DiscoveryListVM {
        .init(scanner: scanner, store: store)
    }

    func makeBluetoothStateWarningsVM() -> BLEStateVM {
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

    func makeHistoryScreenVM() -> HistoryScreenVM {
        guard let item = routing.focus?.item else { fatalError("Set item before navigation") }
        let (title, devices) = getKnownDevices(for: item)
        let vms = makeAboutVMs(for: devices)
        return .init(title: title, vms: vms, store: store, routing: routing, scanner: scanner)
    }

    func makeConfigureVM() -> ConfigureVM {
        guard let item = routing.focus?.item else { fatalError("Set item before navigation") }
        let (title, devices) = getKnownDevices(for: item)
        return .init(title: title, item: item, devices: devices, routing: routing)
    }

    func makeActionVM() -> ActionVM {
        guard let item = routing.focus?.item else { fatalError("Set item before navigation") }
        let action = ActionType(destination: routing.destination)
        let (_, devices) = getKnownDevices(for: item)
        let vms = makeAboutVMs(for: devices)
        return .init(action: action, devices: devices, vms: vms, store: store, routing: routing, backgroundQueue: actionQueue)
    }

}

private extension UIFactory {

    private func makeAboutVMs(for devices: [MWKnownDevice]) -> [AboutDeviceVM] {
        let vms = devices.map(makeAboutDeviceVM(device:))
        vms.indices.forEach { vms[$0].configure(for: $0) }
        return vms
    }

    private func getKnownDevices(for item: Routing.Item) -> (title: String, devices: [MWKnownDevice]) {
        switch item {
            case .group(let id):
                guard let group = store.getGroup(id: id) else { break }
                return (group.name, store.getDevicesInGroup(group))

            case .known(let mac):
                guard let device = store.getDeviceAndMetadata(mac) else { break }
                return (device.meta.name, [device])
        }
        return (title: "Error", devices: [])
    }
}
