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
    @Published public private(set) var meta:    MetaWearMetadata
    @Published public private(set) var battery: String = "–"
    public let loggedDataBytesSubject: CurrentValueSubject<Int?,Never> = .init(nil)

    public private(set) var rssi:                  SignalLevel
    @Published public private(set) var rssiInt:    Int
    @Published public private(set) var connection: CBPeripheralState
    let led = MWLED.Flash.Emulator(preset: .one)

    @Published private var device: MetaWear?
    private var rssiSub:           AnyCancellable? = nil
    private var connectionSub:     AnyCancellable? = nil
    private var batterySub:        AnyCancellable? = nil
    private var infoSub:           AnyCancellable? = nil
    private var ledSub:            AnyCancellable? = nil
    private var resetSub:          AnyCancellable? = nil
    private var refreshSub:        AnyCancellable? = nil
    private var stopLoggingSub:    AnyCancellable? = nil
    private var deleteDataSub:     AnyCancellable? = nil
    private var misc               = Set<AnyCancellable>()
    private unowned let store:     MetaWearSyncStore
    private unowned let logging:   ActiveLoggingSessionsStore
    private unowned let routing:   Routing
    private var didAppear = false

    // Debug
    var isStreaming                = false
    let cancel                     = PassthroughSubject<Void,Never>()

    public init(device: MWKnownDevice,
                store: MetaWearSyncStore,
                logging: ActiveLoggingSessionsStore,
                routing: Routing) {
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
        self.info = device.mw?.info ?? .init(
            manufacturer: "—",
            model: .unknown,
            serialNumber: device.meta.serial,
            firmwareRevision: "—",
            hardwareRevision: "—",
            mac: device.meta.mac
        )
    }
    
    /// Set a unique LED identification pattern when in a group of devices.
    public func configure(for index: Int) {
        led.pattern = MWLED.Preset.init(rawValue: index % 10)!.pattern
    }
}

public extension AboutDeviceVM {

    var loggedBytesRepresentable: String {
        String(describingBytes: loggedDataBytesSubject.value)
    }

    var rssiRepresentable: String {
        if isLocallyKnown == false { return "–" }
        if rssiInt == Int(SignalLevel.noBarsRSSI) { return "–" }
        return .init(rssiInt)
    }

    var connectionRepresentable: String {
        isLocallyKnown ? connection.label : "Cloud Synced"
    }

    var isNearby: Bool {
        connection == .connected || (isLocallyKnown && rssiInt != Int(SignalLevel.noBarsRSSI))
    }

}

public extension AboutDeviceVM {

    /// Starts tracking state and refreshes battery and device information
    func onAppear() {
        guard didAppear == false else { return }
        didAppear = true
        loggedDataBytesSubject
            .removeDuplicates()
            .sink { [weak self] _ in
                self?.objectWillChange.send()
            }
            .store(in: &misc)
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
                self?.updateLoggedDataSize()
            })
        connectIfNeeded()
    }

    func identifyByLED() {

        ledSub = device?
            .publishWhenConnected()
            .first()
            .command(.buzz(milliseconds: 500))
            .command(.buzzMMR(milliseconds: 500, percentStrength: 1))
            .command(.led(led.color, led.pattern))
            .sink(receiveCompletion: { _ in }, receiveValue: { [weak self] _ in
                self?.led.emulate()
            })

        connectIfNeeded()
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
            .sink { [weak self] in
                $0.connect()
                self?.refreshAll()
            }

        connectIfNeeded()
    }

    func rename() {
        let controller = RenamePopupPromptController.shared
        controller.delegate = self
        controller.rename(existingName: meta.name, mac: meta.mac)
    }

    /// To support downloading at a later date (@ThomasMcGuckian feature request)
    func stopLogging() {
        stopLoggingSub = device?
            .publishWhenConnected()
            .first()
            .loggersPause()
            .command(.powerDownSensors)
            .command(.led(.systemPink, .pulse(repetitions: 1)))
            .sink(receiveCompletion: { _ in }, receiveValue: { [weak self] _ in
                self?.updateLoggedDataSize()
            })

        connectIfNeeded()
    }

    func deleteLoggedData() {
        deleteDataSub = device?
            .publishWhenConnected()
            .first()
            .command(.deleteLoggedData)
            .command(.led(.red, .pulse(repetitions: 2)))
            .sink(receiveCompletion: { _ in }, receiveValue: { [weak self] _ in
                self?.updateLoggedDataSize()
            })

        connectIfNeeded()
    }

    func updateLoggedDataSize() {
        device?.publishWhenConnected().first()
            .read(.logLength)
            .map(\.value)
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { _ in }, receiveValue: { [weak self] bytes in
                self?.loggedDataBytesSubject.value = bytes
            })
            .store(in: &misc)

        connectIfNeeded()
    }
}

// MARK: - Rename Delegate

extension AboutDeviceVM: RenameDelegate {
    public func userDidRenameMetaWear(mac: MACAddress, newName: String) {
        try? store.rename(known: self.meta, to: newName)
    }

    public func userDidRenameGroup(id: UUID, newName: String) {
        fatalError("This controller should only represent a single device.")
    }
}

// MARK: - Internal - State updates

private extension AboutDeviceVM {

    private func connectIfNeeded() {
        if (device?.connectionState ?? .connecting) < .connecting {
            connect()
        }
    }

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

        connectIfNeeded()
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
        trackIdentity()
        guard let device = device else { return }
        trackRSSI(device)
        trackConnection(device)
    }

    func trackIdentity() {
        // If MetaWear reference not available at load
        // (scanner might be slower than persistence),
        // then keep retrying until found.

        store.publisher(for: meta.mac)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] deviceReference, metadata in
                let justFoundMetaWear = self?.device == nil && deviceReference != nil
                self?.device = deviceReference
                self?.meta = metadata

                if justFoundMetaWear {
                    self?.trackRSSI(deviceReference!)
                    self?.trackConnection(deviceReference!)
                    self?.refreshAll()
                }
            }
            .store(in: &misc)
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

fileprivate extension String {
    init(describingBytes bytes: Int?) {
        guard let bytes = bytes else { self = "—"; return }
        switch bytes {
            case ...999: self = "\(bytes) bytes"
            case ...999_999:
                let kilobytes = Double(bytes) / 1_000
                self = String(format: "%1.2f", kilobytes) + " KB"
            default:
                let megabytes = Double(bytes) / 1_000_000
                let nonZeroMB = Double.maximum(0.01, megabytes)
                self = String(format: "%1.2f", nonZeroMB) + " MB"
        }
    }
}
