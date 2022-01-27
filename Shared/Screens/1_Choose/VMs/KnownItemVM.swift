// Copyright 2021 MbientLab Inc. All rights reserved. See LICENSE.MD.

import Foundation
import Combine
import MetaWear
import MetaWearSync
import mbientSwiftUI
import CoreBluetooth

/// Provides up-to-date representations of a grouping of MetaWears or a single MetaWear (previously remembered or newly discovered) and related CRUD methods.
///
/// Uniquely identified by the group UUID or a local CoreBluetooth identifier (randomly chosen if known to multiple hosts).
///
public class KnownItemVM: ObservableObject, ItemVM {

    // Identity
    @Published private var group:                  MetaWearGroup?
    @Published private var devices:                [MWKnownDevice]

    // Connection state
    @Published public private(set) var rssiInt:    Int
    @Published public private(set) var connection: CBPeripheralState
    public private(set) var rssi:                  SignalLevel

    // Logging state
    @Published public private(set) var isLogging = false

    // Flash LED action
    @Published private var isIdentifyingMACs = Set<MACAddress>()
    public var isIdentifying: Bool { isIdentifyingMACs.isEmpty == false }
    public let ledVM = MWLED.Flash.Emulator(preset: .zero)

    // Drag/drop
    @Published private(set) public var dropOutcome: DraggableMetaWear.DropOutcome = .noDrop
    public let dropQueue: DispatchQueue

    // Dependencies
    private unowned let store:   MetaWearSyncStore
    private unowned let routing: Routing

    // Subscriptions
    private var rssiSub:          AnyCancellable? = nil
    private var connectionSub:    AnyCancellable? = nil
    private var updateSub:        AnyCancellable? = nil
    private var loggingSub:       AnyCancellable? = nil
    private var identifyingSubs = Set<AnyCancellable>()

    /// Represent a MetaWear (either cloud-synced or locally known) as an item
    public init(device: MWKnownDevice, store: MetaWearSyncStore, logging: ActiveLoggingSessionsStore, routing: Routing, queue: DispatchQueue) {
#if DEBUG
        if useMetabaseConsoleLogger { device.mw?.logDelegate = MWConsoleLogger.shared }
#endif
        self.dropQueue = queue
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

        loggingSub = logging.tokens
            .map { $0[.known(device.meta.mac)] }
            .sink { [weak self] token in
                self?.isLogging = token != nil
            }
    }

    /// Represent a group as a single item
    public init(group: MetaWearGroup, store: MetaWearSyncStore, logging: ActiveLoggingSessionsStore, routing: Routing, queue: DispatchQueue) {
        self.dropQueue = queue
        self.store = store
        self.routing = routing
        let _devices = store.getDevicesInGroup(group)
        self.devices = _devices
#if DEBUG
        if useMetabaseConsoleLogger {
            _devices.forEach {
                $0.mw?.logDelegate = MWConsoleLogger.shared
            }
        }
#endif
        (self.rssi, self.rssiInt) = Self.getLowestSignal(in: _devices)
        self.connection = Self.getLowestConnectionState(in: _devices)

        updateSub = store.publisher(for: group)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] groupUpdate, knownUpdate in
                self?.devices = knownUpdate
                self?.group = groupUpdate
            }

        loggingSub = logging.tokens
            .map { $0[.group(group.id)] }
            .sink { [weak self] token in
                self?.isLogging = token != nil
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
    var metadata:    [MetaWearMetadata] { devices.map(\.meta) }
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

    /// Group ID or Local CBUUID or MAC
    var matchedGeometryID: String {
        if let group = group { return group.id.uuidString }
        return (
            localIDs.first { $0 != nil }
            ?? devices.compactMap { $0.meta.id }.first
        ) ?? UUID().uuidString
    }

    var state: ItemState {
        .init(
            name: name,
            isGroup: isGroup,
            models: models,
            macs: macs,
            rssi: rssi,
            isLocallyKnown: isLocallyKnown,
            connection: connection,
            isLogging: isLogging,
            identifyTip: identifyTip,
            isIdentifying: isIdentifying,
            ledVM: ledVM
        )
    }

}

// MARK: - Lifecycle

public extension KnownItemVM {

    func onAppear() {
        trackState()
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
        devices.forEach(_identify(device:))
        devices.forEach { $0.mw?.connect() }
    }

    private func _identify(device: MWKnownDevice) {
        guard let metawear = device.mw else { return }
        isIdentifyingMACs.insert(device.meta.mac)

        metawear.publishWhenConnected()
            .command(.led(ledVM.color, ledVM.pattern))
            .first()
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { [weak self] completion in
                switch completion {
                    case .failure:
                        self?.isIdentifyingMACs.remove(device.meta.mac)
                    case .finished:
                        let delay = self?.ledVM.pattern.totalDuration ?? 1 + 0.25
                        DispatchQueue.main.after(delay) {
                            self?.isIdentifyingMACs.remove(device.meta.mac)
                        }
                }
            }, receiveValue: { [weak self] _ in
                self?.ledVM.emulate()
            })
            .store(in: &identifyingSubs)
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

    /// Forms a new group or merges items into self (as a group).
    /// If reforming a previous grouping of devices, MetaWearSyncStore
    /// will recover the UUID and name of that old group.
    ///
    func group(withItems: [MetaWearMetadata]) {
        guard withItems.isEmpty == false else { return }
        if var group = group {
            group.deviceMACs.formUnion(withItems.map(\.mac))
            store.update(group: group)

        } else {
            var itemMacs = macs + withItems.map(\.mac)
            itemMacs.removeAll { $0.contains("Unknown") }
            let newGroup = MetaWearGroup(id: .init(), deviceMACs: Set(itemMacs), name: "Group")
            store.add(group: newGroup)
        }
    }

    /// Merges the group into self (whether self is a group or solo device)
    func group(withGroup: MetaWearGroup) {
        if var group = group {
            group.deviceMACs.formUnion(withGroup.deviceMACs)
            store.update(group: group)
            store.remove(group: withGroup.id)
            DispatchQueue.main.async {
                self.group = group
                self.devices = self.store.getDevicesInGroup(group)
            }
        } else {
            var withGroup = withGroup
            withGroup.deviceMACs.formUnion(devices.map(\.meta.mac))
            store.update(group: withGroup)
            DispatchQueue.main.async {
                self.group = withGroup
                self.devices = self.store.getDevicesInGroup(withGroup)
            }
        }
    }

    func removeFromGroup(_ item: MACAddress) {
        guard var group = self.group else { return }
        group.deviceMACs.remove(item)
        store.update(group: group)
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

// MARK: - Drag and Drop

extension KnownItemVM: MWDropTargetVM {

    private func _makeDraggableContents() -> DraggableMetaWear.Item? {
        if let group = group { return .group(group) }
        if deviceCount == 1 {
            return .remembered(meta: metadata[0], localID: devices.compactMap(\.mw?.localBluetoothID).first)
        }
        return nil
    }

    func createDragRepresentation() -> NSItemProvider {
        guard let item = _makeDraggableContents() else { return NSItemProvider() }
        return .init(metawear: item, visibility: .ownProcess, plainTextVisibility: .all)
    }

    public func updateDropOutcome(for drop: [DraggableMetaWear.Item]) {
        guard let firstDroppedItem = drop.first else { dropOutcome = .noDrop; return }

        switch firstDroppedItem {
            case .unknown:
                self.dropOutcome = .noDrop // Don't accept unrecognized MetaWears

            case .group(let droppedGroup):
                if let group = self.group {
                    // A - Merge dropped device/group into self, except when that item is self!
                    self.dropOutcome = group.id == droppedGroup.id ? .noDrop : .addToGroup

                } else {
                    // B - Add self (a solo device) into the dropped group
                    self.dropOutcome = .addToGroup
                }

            case .remembered(meta: let metadata, localID: _):
                if let group = self.group {
                    // A - Merge only novel devices into recipient group
                    self.dropOutcome = group.deviceMACs.contains(metadata.mac) ? .noDrop : .addToGroup // Is the drop already in this group?

                } else if let ownMac = self.macs.first {
                    // B - Form new group only with non-self devices
                    self.dropOutcome = ownMac == metadata.mac ? .noDrop : .newGroup // Is dropping on self?

                    // C - Reject other situations
                } else { NSLog("\(Self.self)" + "Unexpected drop"); self.dropOutcome = .noDrop }
        }
    }

    public func receiveDrop(_ drop: [DraggableMetaWear.Item], intent: DraggableMetaWear.DropOutcome) {
        guard let first = drop.first else { return }

        switch intent {
            case .newGroup:
                // Form new group only with non-self devices
                let nonSelfDevices = drop.rememberedDevices(excluding: Set(self.macs)).map(\.metadata)
                group(withItems: nonSelfDevices)

            case .addToGroup:
                if case .group(let group) = first {
                    // Dropped a group
                    // Merge dropped group into self (which is a group, too)
                    // Add self (solo device) into the dropped group
                    self.group(withGroup: group)
                    return
                }

                // Dropped device(s)
                // Merge only novel devices into self (which is a group)
                let nonSelfDevices = drop.rememberedDevices(excluding: Set(self.macs)).map(\.metadata)
                group(withItems: nonSelfDevices)

            case .noDrop: return
            case .deleteFromGroup: return

        }
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
