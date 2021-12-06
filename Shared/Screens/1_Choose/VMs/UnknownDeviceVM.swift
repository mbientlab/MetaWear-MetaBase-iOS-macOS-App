// Copyright 2021 MbientLab Inc. All rights reserved. See LICENSE.MD.

import SwiftUI
import mbientSwiftUI
import MetaWear
import Metadata
import CoreBluetooth
import Combine

public class UnknownDeviceVM: ObservableObject, ItemVM {
    var name: String
    var isGroup: Bool = false
    var models: [(mac: String, model: MetaWear.Model)] = []
    var isLocallyKnown: Bool = false
    var macs: [String] = []
    var rssi: SignalLevel
    var connection: CBPeripheralState

    private var rssiSub: AnyCancellable? = nil
    private var connectionSub: AnyCancellable? = nil
    private unowned let store: MetaWearStore
    private unowned let routing: Routing
    private unowned let device: MetaWear

    public init(cbuuid: CBPeripheralIdentifier,
                store: MetaWearStore,
                routing: Routing) {
        self.store = store
        self.routing = routing
        let _device = store.getDevice(byLocalCBUUID: cbuuid)
        guard let device = _device.device else { fatalError() }
        self.device = device
        self.name = device.name
        self.rssi = .init(rssi: device.rssi)
        self.connection = _device.device?.connectionStateCurrent ?? .disconnected
    }
}

public extension UnknownDeviceVM {

    func connect() {
        store.remember(unknown: device.peripheral.identifier) { device in
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

        connectionSub = device.connectionState
            .receive(on: DispatchQueue.main)
            .sink { [weak self] update in
                guard self?.connection != update else { return }
                self?.connection = update
            }
    }

    func onDisappear() {
        rssiSub?.cancel()
    }
}
