// Copyright 2021 MbientLab Inc. All rights reserved. See LICENSE.MD.

import Foundation
import Combine
import MetaWear
import Metadata
import mbientSwiftUI
import CoreBluetooth

/// Provides up-to-date information about a device,
/// excluding any updates to metadata from the
/// MetaWearStore (e.g., a name change).
///
public class AboutDeviceVM: ObservableObject, Identifiable {

    public var isLocallyKnown: Bool { device != nil }
    public var matchedGeometryID: String { meta.id }
    public var id: String { matchedGeometryID }

    @Published public private(set) var info: MetaWear.DeviceInformation
    @Published public private(set) var meta: MetaWear.Metadata
    @Published public private(set) var battery: String = "–"

    let led = MWLED.FlashPattern.Emulator(preset: .one)

    public private(set) var rssi: SignalLevel
    @Published public private(set) var rssiInt: Int
    @Published public private(set) var connection: CBPeripheralState

    @Published private var device:           MetaWear?
    private var rssiSub:                     AnyCancellable? = nil
    private var connectionSub:               AnyCancellable? = nil
    private var batterySub:                  AnyCancellable? = nil
    private var infoSub:                     AnyCancellable? = nil
    private var ledSub:                      AnyCancellable? = nil
    private unowned let store:               MetaWearStore

    public init(device: MWKnownDevice, store: MetaWearStore) {
        self.connection = device.mw?.isConnectedAndSetup == true ? .connected : .disconnected
        self.store = store
        self.device = device.mw
        self.meta = device.meta
        let _rssi = device.mw?.rssi ?? Int(SignalLevel.noBarsRSSI)
        self.rssi = .init(rssi: _rssi)
        self.rssiInt = _rssi
        self.info = device.mw?.info ?? .init(manufacturer: "–",
                                             modelNumber: "–",
                                             serialNumber: device.meta.serial,
                                             firmwareRevision: "—",
                                             hardwareRevision: "—")
    }
}

public extension AboutDeviceVM {

    func connect() {
        device?.connect()
    }

    func refresh() {
        refreshBattery()
        refreshDeviceInformation()
    }

    func onAppear() {
        trackState()
    }

    func onDisappear() {
        rssiSub?.cancel()
        connectionSub?.cancel()
        infoSub?.cancel()
        batterySub?.cancel()
    }

    func identifyByLED() {
        ledSub = device?
            .publishWhenConnected()
            .first()
            .command(.ledFlash(led.pattern))
            .sink(receiveCompletion: { _ in }, receiveValue: { [weak self] _ in
                self?.led.emulate()
            })

        device?.connect()
    }
}

private extension AboutDeviceVM {

    func refreshDeviceInformation() {
        infoSub = device?.readCharacteristic(.allDeviceInformation)
//            .print()
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { _ in }, receiveValue: { [weak self] info in
                self?.info = info
            })
    }

    func refreshBattery() {
        batterySub = device?.readCharacteristic(.batteryLife)
//            .print()
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { _ in }, receiveValue: { [weak self] percentage in
                self?.battery = "\(Int(percentage))%"
            })
    }

    func trackState() {
        // If MetaWear reference not available at load
        // (scanner might be slower than persistence),
        // then keep retrying until found.
        print(#function)
        guard let device = device else {
            rssiSub = retryTimer()
                .sink { [weak self] _ in
                    self?.rssiSub?.cancel()
                    self?.trackState()
                }
            return
        }

        trackRSSI(device)
        trackConnection(device)
        refresh()
    }

    /// Retry using updated device references
    func retryTimer() -> AnyPublisher<MWKnownDevice,Never> {
        Timer.TimerPublisher(interval: 1, tolerance: 1, runLoop: RunLoop.main, mode: .default, options: nil)
            .autoconnect()
            .compactMap { [weak self] _ -> MWKnownDevice? in
                guard let metadata = self?.meta,
                      let update = self?.store.getDeviceAndMetadata(metadata.mac)
                else { return nil }
                let metadataDidUpdate = update.meta != metadata
                if update.mw != nil || metadataDidUpdate { return update }
                else { return nil }
            }
            .handleEvents(receiveOutput: { [weak self] update in
                DispatchQueue.main.async { [weak self] in
                    self?.device = update.mw
                    self?.meta = update.meta
                }
            })
            .eraseToAnyPublisher()
    }

    func trackRSSI(_ device: MetaWear) {
        rssiSub?.cancel()
        rssiSub = device.rssiPublisher
            .removeDuplicates(within: 5)
            .map { rssi -> (SignalLevel, Int) in
                print("Received update", rssi, MetaWearScanner.sharedRestore.isScanning)
                return (.init(rssi: rssi), rssi)
            }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] update in
                guard let self = self else { return }
                (self.rssi, self.rssiInt) = update
            }
    }

    func trackConnection(_ device: MetaWear) {
        connectionSub?.cancel()
        connectionSub = device.connectionState
            .receive(on: DispatchQueue.main)
            .removeDuplicates()
            .sink(receiveValue: { [weak self] update in
                self?.connection = update
            })
    }
}
