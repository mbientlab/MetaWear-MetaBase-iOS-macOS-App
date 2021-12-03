// Copyright 2021 MbientLab Inc. All rights reserved. See LICENSE.MD.

import Foundation
import Combine
import MetaWear
import Metadata
import mbientSwiftUI

/// Provides up-to-date representations of a grouping of MetaWears or a single MetaWear (previously remembered or newly discovered) and related CRUD methods.
///
public class KnownItemVM: ObservableObject, ItemVM {

    public var matchedGeometryID: String {
        if let group = group { return group.id.uuidString }
        return (
            localIDs.first { $0 != nil }
            ?? devices.compactMap { $0.meta.id }.first
        ) ?? UUID().uuidString
    }

    public var name: String { group?.name ?? devices.first?.meta.name ?? "Error" }
    public var macs: [String] { devices.map(\.meta.mac) }
    public var localIDs: [String?] { devices.map(\.mw?.peripheral.identifier.uuidString) }
    public var isMetaBoot: Bool { devices.contains { $0.mw?.isMetaBoot == true } }
    public var isConnected: Bool { devices.contains { $0.mw?.isConnectedAndSetup == true } }
    public var isLocallyKnown: Bool {
        if group == nil { return devices.allSatisfy { $0.mw != nil } }
        else { return devices.contains(where: { $0.mw != nil } ) }
    }
    public var models: [(mac: String, model: MetaWear.Model)] {
        devices.map { device in
            (device.meta.mac, device.meta.model)
        }
    }

    public var isGroup: Bool { group != nil }
    public var deviceCount: Int { devices.endIndex }

    @Published public private(set) var rssi: SignalLevel
    @Published public private(set) var isAttemptingConnection = false

    @Published private var group: MetaWear.Group?
    @Published private var devices: [MWKnownDevice]
    private var rssiSub: AnyCancellable? = nil
    private unowned let store: MetaWearStore
    private unowned let routing: Routing

    public init(device: MWKnownDevice, store: MetaWearStore, routing: Routing) {
        self.store = store
        self.routing = routing
        self.devices = [device]
        self.rssi = .init(rssi: device.mw?.rssi ?? Int(SignalLevel.noBarsRSSI))
    }

    public init(group: MetaWear.Group, store: MetaWearStore, routing: Routing) {
        self.store = store
        self.routing = routing
        let _devices = store.getDevicesInGroup(group)
        self.devices = _devices
        self.rssi = Self.getLowestSignal(in: _devices)
    }

    func onAppear() {
        trackRSSI()
    }

    func onDisappear() {
        rssiSub?.cancel()
    }

    func connect() {
        if let group = group {
            routing.setDestination(.history(.group(group.id)))
        } else if let device = devices.first {
            routing.setDestination(.history(.known(device.meta.mac)))
        }
    }
}

public extension KnownItemVM {

    func forgetLocally() {
        devices.map(\.meta).forEach { store.forget(locally: $0) }
    }

    func forgetGlobally() {
        devices.map(\.meta).forEach { store.forget(globally: $0) }
    }

    func group(withItems: [MetaWear.Metadata]) {
        if var group = group {
            group.deviceMACs.formUnion(withItems.map(\.mac))
            store.update(group: group)

        } else {
            var itemMacs = macs + withItems.map(\.mac)
            itemMacs.removeAll { $0.contains("Unknown") }
            let newGroup = MetaWear.Group(id: .init(), deviceMACs: Set(itemMacs), name: "Group")
            store.add(group: newGroup)
        }
    }

    func group(withGroup: MetaWear.Group) {
        if var group = group {
            group.deviceMACs.formUnion(withGroup.deviceMACs)
            store.update(group: group)
            store.remove(group: withGroup.id)
            self.group = group
            self.devices = store.getDevicesInGroup(group)
        } else {
            var withGroup = withGroup
            withGroup.deviceMACs.formUnion(devices.map(\.meta.mac))
            store.update(group: withGroup)
            self.group = withGroup
            self.devices = store.getDevicesInGroup(withGroup)
        }

    }

    func disbandGroup() {
        guard let group = group else { return }
        store.remove(group: group.id)
        self.group = nil
    }

    func rename() {
        fatalError()
    }

}

private extension KnownItemVM {

    static func getLowestSignal(in devices: [MWKnownDevice]) -> SignalLevel {
        let min = Int(SignalLevel.noBarsRSSI)
        let lowest = devices.map { $0.mw?.rssi ?? min }.min() ?? min
        return .init(rssi: lowest)
    }

    func trackRSSI() {
        guard let main = devices.first(where: { mw, _ in mw != nil })?.mw else { return }

        rssiSub = main.rssiPublisher
            .map { [weak self] first -> SignalLevel in
                guard let self = self else { return .init(rssi: first) }
                return Self.getLowestSignal(in: self.devices)
            }
            .sink { [weak self] update in
                guard self?.rssi != update else { return }
                self?.rssi = update
            }
    }
}
