// Copyright 2021 MbientLab Inc. All rights reserved. See LICENSE.MD.

import Foundation
import Combine
import MetaWear
import MetaWearSync
import mbientSwiftUI
import CoreBluetooth

/// Provides up-to-date information about a device,
/// excluding any updates to metadata from the
/// MetaWearSyncStore (e.g., a name change).
///
public class AboutDeviceVM: ObservableObject, Identifiable {

    public var isLocallyKnown: Bool { device != nil }
    public var matchedGeometryID: String { meta.id }
    public var id: String { matchedGeometryID }

    @Published public private(set) var info:    MetaWear.DeviceInformation
    @Published public private(set) var meta:    MetaWear.Metadata
    @Published public private(set) var battery: String = "–"

    public var rssiRepresentable: String {
        if isLocallyKnown == false { return "–" }
        if rssiInt == Int(SignalLevel.noBarsRSSI) { return "–" }
        return .init(rssiInt)
    }
    public var connectionRepresentable: String {
        isLocallyKnown ? connection.label : "Cloud Synced"
    }
    public var isNearby: Bool {
        connection == .connected || (isLocallyKnown && rssiInt != Int(SignalLevel.noBarsRSSI))
    }
    public private(set) var rssi:                  SignalLevel
    @Published public private(set) var rssiInt:    Int
    @Published public private(set) var connection: CBPeripheralState
    let led = MWLED.Flash.Pattern.Emulator(preset: .one)

    @Published private var device: MetaWear?
    private var rssiSub:           AnyCancellable? = nil
    private var connectionSub:     AnyCancellable? = nil
    private var batterySub:        AnyCancellable? = nil
    private var infoSub:           AnyCancellable? = nil
    private var ledSub:            AnyCancellable? = nil
    private var resetSub:          AnyCancellable? = nil
    private var refreshSub:        AnyCancellable? = nil
    private var misc               = Set<AnyCancellable>()
    private unowned let store:     MetaWearSyncStore
    private unowned let logging:   ActiveLoggingSessionsStore
    private unowned let routing:   Routing
    private var didAppear = false

    // Debug
    var isStreaming                = false
    let cancel                     = PassthroughSubject<Void,Never>()

    public init(device: MWKnownDevice, store: MetaWearSyncStore, logging: ActiveLoggingSessionsStore, routing: Routing) {
#if DEBUG
        if useMetabaseConsoleLogger {
            device.mw?.logDelegate = MWConsoleLogger.shared
        }
#endif

        self.connection = device.mw?.connectionState == .connected ? .connected : .disconnected
        self.store = store
        self.routing = routing
        self.logging = logging
        self.device = device.mw
        self.meta = device.meta
        let _rssi = device.mw?.rssi ?? Int(SignalLevel.noBarsRSSI)
        self.rssi = .init(rssi: _rssi)
        self.rssiInt = _rssi
        self.info = device.mw?.info ?? .init(manufacturer: "—",
                                             model: .unknown,
                                             serialNumber: device.meta.serial,
                                             firmwareRevision: "—",
                                             hardwareRevision: "—",
                                             mac: device.meta.mac)
    }
    
    /// Set a unique LED identification pattern when in a group of devices.
    public func configure(for index: Int) {
        led.pattern = MWLED.Flash.Pattern.Presets.init(rawValue: index % 10)!.pattern
    }
}

public extension AboutDeviceVM {

    /// Starts tracking state and refreshes battery and device information
    func onAppear() {
        guard didAppear == false else { return }
        didAppear = true
        trackState()
        refreshAll()
    }

    func connect() {
        _reloadDevice()
        device?.connect()
    }

    func disconnect() {
        device?.disconnect()
    }

    func refreshAll() {
        refreshSub = device?.publishWhenConnected()
            .delay(for: 0.25, tolerance: 0, scheduler: device?.bleQueue ?? DispatchQueue.main)
            .first()
            .sink(receiveValue: { [weak self] _ in
                self?.refreshBattery()
                self?.refreshDeviceInformation()
            })
        if (device?.connectionState ?? .connecting) < .connecting {
            connect()
        }
    }

    func identifyByLED() {
        ledSub = device?
            .publishWhenConnected()
            .first()
            .command(.ledFlash(led.pattern))
            .sink(receiveCompletion: { _ in }, receiveValue: { [weak self] _ in
                self?.led.emulate()
            })

        connect()
    }

    func reset() {
        guard resetSub == nil else { return }
        resetSub = device?
            .publishWhenConnected()
            .first()
            .command(.resetFactoryDefaults)
            .sink(receiveCompletion: { _ in }, receiveValue: { [self] _ in
                logging.remove(token: routing.focus!.item)
            })


        refreshSub = device?.publishWhenDisconnected()
            .first()
            .delay(for: 1.5, tolerance: 0.5, scheduler: DispatchQueue.main)
            .sink { $0.connect() }

        if device?.connectionState != .connected { connect() }
    }

}

private extension AboutDeviceVM {

    func _reloadDevice() {
        guard device == nil else { return }
        self.device = store.getDevice(self.meta)
    }

    func refreshDeviceInformation() {
        infoSub = device?.publishWhenConnected()
            .read(.deviceInformation)
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { _ in }, receiveValue: { [weak self] info in
                self?.info = info
            })

        if device?.connectionState != .connected { device?.connect() }
    }

    func refreshBattery() {
        batterySub = device?.publishWhenConnected()
            .read(.batteryLevel)
            .map(\.value)
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { _ in }, receiveValue: { [weak self] percentage in
                self?.battery = "\(Int(percentage))%"
            })
    }

    func trackState() {
        // If MetaWear reference not available at load
        // (scanner might be slower than persistence),
        // then keep retrying until found.
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
            .receive(on: DispatchQueue.main)
            .sink { [weak self] update in
                guard let self = self else { return }
                (self.rssi, self.rssiInt) = (.init(rssi: update), update)
            }
    }

    func trackConnection(_ device: MetaWear) {
        connectionSub?.cancel()
        connectionSub = device.connectionStatePublisher
            .receive(on: DispatchQueue.main)
            .removeDuplicates()
            .sink(receiveValue: { [weak self] update in
                self?.connection = update
            })
    }
}
