// Copyright 2021 MbientLab Inc. All rights reserved. See LICENSE.MD.

import mbientSwiftUI
import MetaWear
import MetaWearSync
import CoreBluetooth
import Combine


/// Unknown items are uniquely identified by the CoreBluetooth local UUID string.
///
public class UnknownItemVM: ObservableObject, ItemVM {

    public let ledVM: MWLED.Flash.Pattern.Emulator = .init(preset: .eight)

    public var matchedGeometryID: String { device.peripheral.identifier.uuidString }
    public private(set) var name: String
    public private(set) var models: [(mac: String, model: MetaWear.Model)] = []
    public private(set) var isCloudSynced = false
    public private(set) var macs: [String] = []
    @Published public private(set) var rssi: SignalLevel
    @Published public private(set) var connection: CBPeripheralState

    private var rssiSub: AnyCancellable? = nil
    private var connectionSub: AnyCancellable? = nil
    private unowned let store: MetaWearSyncStore
    private unowned let routing: Routing
    private unowned let device: MetaWear

    public init(cbuuid: CBPeripheralIdentifier,
                store: MetaWearSyncStore,
                routing: Routing) {
        self.store = store
        self.routing = routing
        let _device = store.getDevice(byLocalCBUUID: cbuuid)
        guard let device = _device.device else { fatalError() }
        self.isCloudSynced = store.deviceIsCloudSynced(mac: device.info.mac)
        self.device = device
        self.name = device.name
        self.rssi = .init(rssi: device.rssi)
        self.connection = _device.device?.connectionState ?? .disconnected
    }
}

public extension UnknownItemVM {

    func connect() {
        connection = .connecting
        store.connectAndRemember(unknown: device.peripheral.identifier) { device in
                // Custom flashing etc.
        }
    }

    func onAppear() {
        rssiSub = device.rssiPublisher
            .map(SignalLevel.init(rssi:))
            .receive(on: DispatchQueue.main)
            .sink { [weak self] update in
                guard self?.rssi != update else { return }
                self?.rssi = update
            }

        connectionSub = device.connectionStatePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] update in
                guard self?.connection != update else { return }
                self?.connection = update
            }
    }

    func onDisappear() {
        rssiSub?.cancel()
    }

    func identify() {
        // Not offered
    }

    var state: ItemState {
        .init(
            name: name,
            isGroup: false,
            models: models,
            macs: macs,
            rssi: rssi,
            isLocallyKnown: false,
            connection: connection,
            identifyTip: "",
            isIdentifying: false,
            ledVM: ledVM
        )
    }
}

extension UnknownItemVM {

    func createDragRepresentation() -> NSItemProvider {
        NSItemProvider() // Drag not used for unknown items. Tap to connect.
    }
}
