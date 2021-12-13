// Copyright 2021 MbientLab Inc. All rights reserved. See LICENSE.MD.

import Foundation
import Combine
import MetaWear
import MetaWearMetadata
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

    @Published public private(set) var info:    MetaWear.DeviceInformation
    @Published public private(set) var meta:    MetaWear.Metadata
    @Published public private(set) var battery: String = "–"

    public private(set) var rssi:                  SignalLevel
    @Published public private(set) var rssiInt:    Int
    @Published public private(set) var connection: CBPeripheralState
    let led = MWLED.FlashPattern.Emulator(preset: .one)

    @Published private var device: MetaWear?
    private var rssiSub:           AnyCancellable? = nil
    private var connectionSub:     AnyCancellable? = nil
    private var batterySub:        AnyCancellable? = nil
    private var infoSub:           AnyCancellable? = nil
    private var ledSub:            AnyCancellable? = nil
    private var resetSub:          AnyCancellable? = nil
    private var refreshSub:        AnyCancellable? = nil
    private var misc = Set<AnyCancellable>()
    private unowned let store:     MetaWearStore
    var isStreaming = false
    let cancel = PassthroughSubject<Void,Never>()
    public init(device: MWKnownDevice, store: MetaWearStore) {
        self.connection = device.mw?.isConnectedAndSetup == true ? .connected : .disconnected
        self.store = store
        self.device = device.mw
        self.meta = device.meta
        let _rssi = device.mw?.rssi ?? Int(SignalLevel.noBarsRSSI)
        self.rssi = .init(rssi: _rssi)
        self.rssiInt = _rssi
        self.info = device.mw?.info ?? .init(manufacturer: "—",
                                             model: .unknown,
                                             serialNumber: device.meta.serial,
                                             firmwareRevision: "—",
                                             hardwareRevision: "—")
    }

    /// Set a unique LED identification pattern when in a group of devices.
    public func configure(for index: Int) {
        led.pattern = MWLED.FlashPattern.Presets.init(rawValue: index % 10)!.pattern
    }
}

public extension AboutDeviceVM {

    /// Starts tracking state and refreshes battery and device information
    func onAppear() {
        trackState()
        refreshAll()
    }

    func streamFUNCTIONAL_WHEN_SOLO() {
        isStreaming = true
        device?.publishWhenConnected()
            .handleEvents(receiveOutput: { _ in
                Swift.print("WHEN CONNECTED OUTPUT")
            })
            .first()
            .handleEvents(receiveOutput: { _ in
                Swift.print("WHEN CONNECTED OUTPUT -- AFTER FIRST")
            })
            .flatMap { [self] metawear in
                metawear.publish()
                    .stream(try! .thermometer(type: .onboard, board: device!.board))
                    .handleEvents(receiveSubscription: { _ in
                        Swift.print("-> subbed")
                    }, receiveOutput: { _ in
                        Swift.print("-> output")
                    }, receiveCompletion: { _ in
                        Swift.print("-> completion")
                    }, receiveCancel: {
                        Swift.print("-> cancel")
                    }, receiveRequest: { demand in
                        Swift.print("-> request", demand)
                    })
                    .prefix(untilOutputFrom: cancel)
                    .collect()
                    .map { MWDataTable(streamed: $0, try! .thermometer(type: .onboard, board: metawear.board))}
                    .eraseToAnyPublisher()
            }
            .sink(receiveCompletion: { completion in
                switch completion {
                    case .failure(let error): print(error.localizedDescription)
                    case .finished: Swift.print("FINISHED")
                }
            }, receiveValue: { value in
                Swift.print(value.rows.count)
            })
            .store(in: &misc)

        device?.connect()
    }

    func streamExperiment() {
        isStreaming = true

        let didConnect = device!
            .publishWhenConnected()
            .handleEvents(receiveOutput: { _ in
                Swift.print("WHEN CONNECTED OUTPUT")
            })
            .first()
            .handleEvents(receiveOutput: { _ in
                Swift.print("WHEN CONNECTED OUTPUT -- AFTER FIRST")
            })
            .mapToMWError()
            .timeout(20, scheduler: DispatchQueue.main) { .operationFailed("Timeout") }
            .handleEvents(receiveOutput: { _ in
                Swift.print("WHEN CONNECTED OUTPUT -- AFTER TIMEOUT")
            })
            .eraseToAnyPublisher()

        didConnect
            .handleEvents(receiveOutput: { _ in
                Swift.print("---------------- STARTING STREAM --------------------")
            })
            .stream(try! .thermometer(type: .onboard, board: device!.board))
            .prefix(untilOutputFrom: cancel)
            .collect()
            .map { MWDataTable(streamed: $0, try! .thermometer(type: .onboard, board: self.device!.board))}
            .handleEvents(receiveSubscription: { _ in
                Swift.print("-> subbed")
            }, receiveOutput: { _ in
                Swift.print("-> output")
            }, receiveCompletion: { _ in
                Swift.print("-> completion")
            }, receiveCancel: {
                Swift.print("-> cancel")
            }, receiveRequest: { demand in
                Swift.print("-> request", demand)
            })
            .sink(receiveCompletion: { completion in
                switch completion {
                    case .failure(let error): print(error.localizedDescription)
                    case .finished: Swift.print("FINISHED")
                }
            }, receiveValue: { value in
                Swift.print(value.rows.count)
            })
            .store(in: &misc)

        device?.connect()
    }


    func testA() {
        if isStreaming {
            cancel.send()
            isStreaming = false
        } else { streamFUNCTIONAL_WHEN_SOLO() }
    }

    func testB() {
        if isStreaming {
            cancel.send()
            isStreaming = false
        } else { streamExperiment() }
    }

    func onDisappear() {
        rssiSub?.cancel()
        connectionSub?.cancel()
        infoSub?.cancel()
        batterySub?.cancel()
    }

    func connect() {
        _reloadDevice()
        device?.connect()
    }

    func refreshAll() {
        refreshSub = device?.publishWhenConnected()
            .first()
            .sink(receiveValue: { [weak self] _ in
                self?.refreshBattery()
                self?.refreshDeviceInformation()
            })
        connect()
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
            .factoryReset()
            .sink(receiveCompletion: { _ in }, receiveValue: { _ in })

        if device?.isConnectedAndSetup == false { connect() }
    }

}

private extension AboutDeviceVM {

    func _reloadDevice() {
        guard device == nil else { return }
        self.device = store.getDevice(self.meta)
    }

    func refreshDeviceInformation() {
        infoSub = device?.read(.allDeviceInformation)
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { _ in }, receiveValue: { [weak self] info in
                self?.info = info
            })
    }

    func refreshBattery() {
        batterySub = device?.read(.batteryLife)
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
        connectionSub = device.connectionState
            .receive(on: DispatchQueue.main)
            .removeDuplicates()
            .sink(receiveValue: { [weak self] update in
                self?.connection = update
            })
    }
}
