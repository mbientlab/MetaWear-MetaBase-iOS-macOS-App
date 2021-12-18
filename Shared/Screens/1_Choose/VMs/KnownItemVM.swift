// Copyright 2021 MbientLab Inc. All rights reserved. See LICENSE.MD.

import Foundation
import Combine
import MetaWear
import MetaWearSync
import mbientSwiftUI
import CoreBluetooth
import SwiftUI

/// Provides up-to-date representations of a grouping of MetaWears or a single MetaWear (previously remembered or newly discovered) and related CRUD methods.
///
/// Uniquely identified by the group UUID or a local CoreBluetooth identifier (randomly chosen if known to multiple hosts).
///
public class KnownItemVM: ObservableObject, ItemVM {

    // Identity
    @Published private var group: MetaWear.Group?
    @Published private var devices: [MWKnownDevice]

    // Connection state
    @Published public private(set) var rssiInt: Int
    @Published public private(set) var connection: CBPeripheralState
    public private(set) var rssi: SignalLevel

    // Flash LED action
    @Published private var isIdentifyingMACs = Set<MACAddress>()
    public var isIdentifying: Bool { isIdentifyingMACs.isEmpty == false }
    public let ledVM = MWLED.Flash.Pattern.Emulator(preset: .zero)

    // Drag/drop
    @Published private(set) public var dropOutcome: DraggableMetaWear.DropOutcome = .noDrop
    public let dropQueue: DispatchQueue = .global(qos: .background)

    // Dependencies
    private unowned let store:   MetaWearSyncStore
    private unowned let routing: Routing

    // Subscriptions
    private var rssiSub:         AnyCancellable? = nil
    private var connectionSub:   AnyCancellable? = nil
    private var updateSub:   AnyCancellable? = nil
    private var identifyingSubs = Set<AnyCancellable>()

    /// Represent a MetaWear (either cloud-synced or locally known) as an item
    public init(device: MWKnownDevice, store: MetaWearSyncStore, routing: Routing) {
        self.connection = device.mw?.connectionState == .connected ? .connected : .disconnected
        self.store = store
        self.routing = routing
        self.devices = [device]
        let _rssi = device.mw?.rssi ?? Int(SignalLevel.noBarsRSSI)
        self.rssi = .init(rssi: _rssi)
        self.rssiInt = _rssi

        updateSub = store.publisher(for: device.meta.mac)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.devices = [$0] }
    }

    /// Represent a group as a single item
    public init(group: MetaWear.Group, store: MetaWearSyncStore, routing: Routing) {
        self.store = store
        self.routing = routing
        let _devices = store.getDevicesInGroup(group)
        self.devices = _devices
        (self.rssi, self.rssiInt) = Self.getLowestSignal(in: _devices)
        self.connection = Self.getLowestConnectionState(in: _devices)

        updateSub = store.publisher(for: group)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] groupUpdate, knownUpdate in
                self?.devices = knownUpdate
                self?.group = groupUpdate
            }
    }
}

// MARK: - Convenience Properties

public extension KnownItemVM {

    var isGroup: Bool { group != nil }
    var deviceCount: Int { devices.endIndex }

    var isMetaBoot:  Bool      { devices.contains { $0.mw?.isMetaBoot == true } }
    var isConnected: Bool      { devices.contains { $0.mw?.connectionState == .connected } }
    var name:        String    { group?.name ?? devices.first?.meta.name ?? "Error" }
    var macs:        [String]  { devices.map(\.meta.mac) }
    var localIDs:    [String?] { devices.map(\.mw?.peripheral.identifier.uuidString) }
    var metadata:    [MetaWear.Metadata] { devices.map(\.meta) }
    var identifyTip: String {
        "Flash LED\(macs.endIndex > 1 ? "s" : "") for \(macs.joined(separator: ", "))"
    }

    var isLocallyKnown: Bool {
        if group == nil { return devices.allSatisfy { $0.mw != nil } }
        else { return devices.contains(where: { $0.mw != nil } ) }
    }

    var models: [(mac: String, model: MetaWear.Model)] {
        devices.map { device in
            (device.meta.mac, device.meta.model)
        }
    }

    var matchedGeometryID: String {
        if let group = group { return group.id.uuidString }
        return (
            localIDs.first { $0 != nil }
            ?? devices.compactMap { $0.meta.id }.first
        ) ?? UUID().uuidString
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

    func identify() {
        devices.forEach { known in
            guard let device = known.mw else { return }
            isIdentifyingMACs.insert(known.meta.mac)
            device.publishWhenConnected()
                .command(.ledFlash(ledVM.pattern))
                .first()
                .receive(on: DispatchQueue.main)
                .sink(receiveCompletion: { [weak self] completion in
                    switch completion {
                        case .failure:
                            self?.isIdentifyingMACs.remove(known.meta.mac)
                        case .finished:
                            DispatchQueue.main.after(self?.ledVM.pattern.totalDuration ?? 1 + 0.25) {
                                self?.isIdentifyingMACs.remove(known.meta.mac)
                            }
                    }
                }, receiveValue: { [weak self] _ in
                    self?.ledVM.emulate()
                })
                .store(in: &identifyingSubs)
        }
        devices.forEach { $0.mw?.connect() }
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
        let controller = RenamePopupPromptController.shared
        controller.delegate = self

        if let groupID = group?.id {
            controller.rename(existingName: name, group: groupID)
        } else if let mac = macs.first {
            controller.rename(existingName: name, mac: mac)
        }
    }

}
import UniformTypeIdentifiers
// MARK: - Drag and Drop


extension KnownItemVM: MetaWearDropTargetVM {

    private func _makeDraggableContents() -> DraggableMetaWear.Item? {
        if let group = group { return .group(group) }
        if deviceCount == 1 {
            return .remembered(meta: metadata[0], localID: devices.compactMap(\.mw?.localBluetoothID).first)
        }
        return nil
    }

    func createDragRepresentation() -> NSItemProvider {
        guard let item = _makeDraggableContents() else { return NSItemProvider() }
        let provider = makeDraggableMetaWearProvider(item)
        return provider
    }

    public func updateDropOutcome(for drop: [DraggableMetaWear.Item]) {
        guard let first = drop.first else { dropOutcome = .noDrop; return }

        switch first {

                // Don't accept unrecognized MetaWears
            case .unknown: self.dropOutcome = .noDrop

            case .group(let droppedGroup):

                // Merge dropped group into recipient group
                if let group = self.group {
                    let isDroppingOnSelf = group.id == droppedGroup.id
                    self.dropOutcome = isDroppingOnSelf ? .noDrop : .addToGroup

                    // Add self (solo device) into dropped group
                } else { self.dropOutcome = .addToGroup }

            case .remembered(meta: let metadata, localID: _):

                // Merge only novel devices into recipient group
                if let group = self.group {
                    let alreadyContains = group.deviceMACs.contains(metadata.mac)
                    self.dropOutcome = alreadyContains ? .noDrop : .addToGroup

                    // Form new group only with non-self devices
                } else if let ownMac = self.macs.first {
                    let isDroppingOnSelf = ownMac == metadata.mac
                    self.dropOutcome = isDroppingOnSelf ? .noDrop : .newGroup

                    // Reject other situations
                } else { print("Unexpected drop"); self.dropOutcome = .noDrop }
        }
    }

    public func performDrop(info: DropInfo) -> Bool {
        guard let metawears = info.loadMetaWears() else { return false }
        print(metawears.count)
        return true
    }
}

// MARK: - Rename Delegate

extension KnownItemVM: RenameDelegate {
    public func userDidRenameMetaWear(mac: MACAddress, newName: String) {
        guard let metadata = devices.first(where: { $0.meta.mac == mac })?.meta else { return }
        try? store.rename(known: metadata, to: newName)
    }

    public func userDidRenameGroup(id: UUID, newName: String) {
        guard let group = self.group else { return }
        store.rename(group: group, to: newName)
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
        connectionSub = main.connectionStatePublisher
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
        devices.map { $0.mw?.connectionState ?? .disconnected }.min() ?? .disconnected
    }
}
