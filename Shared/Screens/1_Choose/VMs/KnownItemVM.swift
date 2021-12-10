// Copyright 2021 MbientLab Inc. All rights reserved. See LICENSE.MD.

import Foundation
import Combine
import MetaWear
import Metadata
import mbientSwiftUI
import CoreBluetooth

/// Provides up-to-date representations of a grouping of MetaWears or a single MetaWear (previously remembered or newly discovered) and related CRUD methods.
///
public class KnownItemVM: ObservableObject, ItemVM {

    public var isGroup: Bool { group != nil }
    public var deviceCount: Int { devices.endIndex }

    public var name: String {
        group?.name ?? devices.first?.meta.name ?? "Error"
    }

    public var macs: [String] {
        devices.map(\.meta.mac)
    }

    public var metadata: [MetaWear.Metadata] {
        devices.map(\.meta)
    }

    public var localIDs: [String?] { devices.map(\.mw?.peripheral.identifier.uuidString)
    }

    public var isMetaBoot: Bool {
        devices.contains { $0.mw?.isMetaBoot == true }
    }

    public var isConnected: Bool {
        devices.contains { $0.mw?.isConnectedAndSetup == true }
    }

    public var isLocallyKnown: Bool {
        if group == nil { return devices.allSatisfy { $0.mw != nil } }
        else { return devices.contains(where: { $0.mw != nil } ) }
    }

    public var models: [(mac: String, model: MetaWear.Model)] {
        devices.map { device in
            (device.meta.mac, device.meta.model)
        }
    }

    public var matchedGeometryID: String {
        if let group = group { return group.id.uuidString }
        return (
            localIDs.first { $0 != nil }
            ?? devices.compactMap { $0.meta.id }.first
        ) ?? UUID().uuidString
    }

    public private(set) var rssi: SignalLevel
    @Published public private(set) var rssiInt: Int
    @Published public private(set) var connection: CBPeripheralState

    @Published private var group: MetaWear.Group?
    @Published private var devices: [MWKnownDevice]
    private var rssiSub:         AnyCancellable? = nil
    private var connectionSub:   AnyCancellable? = nil
    private unowned let store:   MetaWearStore
    private unowned let routing: Routing

    public init(device: MWKnownDevice, store: MetaWearStore, routing: Routing) {
        self.connection = device.mw?.isConnectedAndSetup == true ? .connected : .disconnected
        self.store = store
        self.routing = routing
        self.devices = [device]
        let _rssi = device.mw?.rssi ?? Int(SignalLevel.noBarsRSSI)
        self.rssi = .init(rssi: _rssi)
        self.rssiInt = _rssi
    }

    public init(group: MetaWear.Group, store: MetaWearStore, routing: Routing) {
        self.store = store
        self.routing = routing
        let _devices = store.getDevicesInGroup(group)
        self.devices = _devices
        (self.rssi, self.rssiInt) = Self.getLowestSignal(in: _devices)
        self.connection = Self.getLowestConnectionState(in: _devices)
    }
}

// MARK: - Lifecycle

public extension KnownItemVM {

    func onAppear() {
        trackState()
    }

    func onDisappear() {
        rssiSub?.cancel()
        connectionSub?.cancel()
    }

    func connect() {
        if let group = group {
            routing.setNewFocus(item: .group(group.id))
        } else if let device = devices.first {
            routing.setNewFocus(item: .known(device.meta.mac))
        }
        routing.setDestination(.history)
    }

}

// MARK: - Intents

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


// MARK: - Internal - State updates

private extension KnownItemVM {

    static func getLowestSignal(in devices: [MWKnownDevice]) -> (SignalLevel, Int) {
        let min = Int(SignalLevel.noBarsRSSI)
        let lowest = devices.map { $0.mw?.rssi ?? min }.min() ?? min
        return (.init(rssi: lowest), lowest)
    }

    func trackState() {
        // If MetaWear reference not available at load
        // (scanner might be slower than persistence),
        // then keep retrying until found.
        guard let main = devices.first(where: { mw, _ in mw != nil })?.mw else {
            rssiSub = retryTimer()
                .sink { [weak self] _ in
                    self?.rssiSub?.cancel()
                    self?.trackState()
                }
            return
        }
        trackRSSI(main: main)
        trackConnection(main: main)
    }

    /// Retry using updated device references
    func retryTimer() -> AnyPublisher<[MWKnownDevice],Never> {
        Timer.TimerPublisher(interval: 1, tolerance: 1, runLoop: RunLoop.main, mode: .default, options: nil)
            .autoconnect()
            .compactMap { [weak self] _ -> [MWKnownDevice]? in
                guard let self = self else { return nil }
                let newDevices = self.devices.compactMap { self.store.getDeviceAndMetadata($0.meta.mac) }
                guard newDevices.contains(where: { $0.mw != nil }) else { return nil }
                return newDevices
            }
            .handleEvents(receiveOutput: { [weak self] update in
                DispatchQueue.main.async { [weak self] in
                    self?.devices = update
                }
            })
            .eraseToAnyPublisher()
    }

    func trackRSSI(main: MetaWear) {
        rssiSub?.cancel()
        rssiSub = main.rssiPublisher
            .map { [weak self] first -> (SignalLevel, Int) in
                guard let self = self else { return (.init(rssi: first), first) }
                return Self.getLowestSignal(in: self.devices)
            }
            .receive(on: DispatchQueue.main)
            .removeDuplicates(by: { $0.0 == $1.0 })
            .sink { [weak self] update in
                guard let self = self else { return }
                (self.rssi, self.rssiInt) = update
            }
    }

    func trackConnection(main: MetaWear) {
        connectionSub?.cancel()
        connectionSub = main.connectionState
            .map { [weak self] first -> CBPeripheralState in
                guard let self = self else { return first }
                return Self.getLowestConnectionState(in: self.devices)
            }
            .receive(on: DispatchQueue.main)
            .removeDuplicates()
            .sink(receiveValue: { [weak self] update in
                self?.connection = update
            })
    }

    static func getLowestConnectionState(in devices: [MWKnownDevice]) -> CBPeripheralState {
        devices.map { $0.mw?.connectionStateCurrent ?? .disconnected }.min() ?? .disconnected
    }
}

extension CBPeripheralState {
    var ranking: Int {
        switch self {
            case .disconnecting: return 0
            case .disconnected: return 1
            case .connecting: return 2
            case .connected: return 3
            default: return 0
        }
    }
}

extension CBPeripheralState: Comparable {
    public static func < (lhs: CBPeripheralState, rhs: CBPeripheralState) -> Bool {
        lhs.ranking < rhs.ranking
    }
}


//ForEach(vm.macs.indices, id: \.self) { index in
//    Text(vm.macs[index])
//        .font(.system(.headline, design: .monospaced))
//        .lineLimit(1)
//        .fixedSize()
//}
