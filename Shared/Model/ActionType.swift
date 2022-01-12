// Copyright 2021 MbientLab Inc. All rights reserved. See LICENSE.MD.

import Foundation
import Combine
import MetaWear

public enum ActionType {
    case stream
    case log
    case downloadLogs
}

// MARK: - Actions

/// Controller that manages a queue of MetaWear sensor data actions.
///
protocol ActionController: AnyObject {

    var startDate:       Date { get }
    var timeoutDuration: DispatchQueue.SchedulerTimeType.Stride { get }
    var workQueue:       DispatchQueue { get }
    var streamCancel:    PassthroughSubject<Void,Never> { get }
    var streamCounters:  StreamingCountersContainer { get }

    func registerLoggingToken()
    func removeLoggingToken()
    func updateActionState(mac: MACAddress, state: ActionState)
    func saveData(tables: [MWDataTable], for mac: MACAddress)
}

extension ActionType {

    /// Flattens log, download, and stream actions into a Publisher that emits a value (void) once when complete.
    ///
    /// This publisher will timeout after the injected inactivity time. Thus, lifetimes should be managed to avoid a false timeout after success in a large queue.
    ///
    func getActionPublisher(_ device: MetaWear,
                            _ mac: MACAddress,
                            _ config: ModulesConfiguration,
                            _ controller: ActionController
    ) -> MWPublisher<Void> {
        switch self {
            case .downloadLogs: return downloadLogs(for: device, mac, controller)
            case .log: return recordMacro(for: device, config, controller)
            case .stream: return stream(for: device, mac: mac, config: config, controller)
        }
    }

}

// MARK: - Download Action

extension ActionType {

    func downloadLogs(for device: MetaWear,
                      _ mac: MACAddress,
                      _ controller: ActionController) -> MWPublisher<Void> {
        device
            .publishWhenConnected()
            .mapToMWError()
            .timeout(controller.timeoutDuration, scheduler: controller.workQueue) { .operationFailed("Timeout") }
            .first()
            .downloadLogs(startDate: controller.startDate)
            .receive(on: controller.workQueue)
            .handleEvents(receiveOutput: { [weak controller] download in
                let percent = Int(download.percentComplete * 100)
                controller?.updateActionState(mac: mac, state: .working(percent))
            })
            .drop(while: { $0.percentComplete < 1 })
            .handleEvents(receiveOutput: { [weak controller] download in
                controller?.saveData(tables: download.data, for: mac)
            })
            .map { _ in () }
            .handleEvents(receiveOutput: { [weak controller] _ in
                controller?.removeLoggingToken()
            })
            .eraseToAnyPublisher()
    }
}

// MARK: - Log Action

extension ActionType {

    func recordMacro(for device: MetaWear,
                     _ config: ModulesConfiguration,
                     _ controller: ActionController) -> MWPublisher<Void> {
        device
            .publishWhenConnected()
            .first()
            .mapToMWError()
            .macro(config)
            .timeout(controller.timeoutDuration, scheduler: controller.workQueue) { .operationFailed("Timeout") }
            .map { _ in () }
            .handleEvents(receiveOutput: { [weak controller] _ in
                controller?.registerLoggingToken()
            })
            .eraseToAnyPublisher()
    }
}

fileprivate extension AnyPublisher where Output == MetaWear {
    func macro(_ config: ModulesConfiguration) -> MWPublisher<MWMacroIdentifier> {
        self.macro(executeOnBoot: true) { metawear in
            metawear
                .optionallyLog(config.accelerometer)
                .optionallyLog(config.altitude)
                .optionallyLog(config.gyroscope)
                .optionallyLog(byPolling: config.humidity)
                .optionallyLog(config.ambientLight)
                .optionallyLog(config.magnetometer)
                .optionallyLog(config.pressure)
                .optionallyLog(byPolling: config.thermometer)
                .optionallyLog(config.fusionEuler)
                .optionallyLog(config.fusionGravity)
                .optionallyLog(config.fusionLinear)
                .optionallyLog(config.fusionQuaternion)
        }
    }
}

// MARK: - Stream Action

extension ActionType {

    /// Stream all needed sensors on one device. Times out only when unable to connect.
    ///
    func stream(for device: MetaWear,
                mac: MACAddress,
                config: ModulesConfiguration,
                _ controller: ActionController) -> MWPublisher<Void> {

        var streams = [MWPublisher<MWDataTable>]()

        let didConnect = device
            .publishWhenConnected()
            .mapToMWError()
            .timeout(controller.timeoutDuration, scheduler: controller.workQueue) { .operationFailed("Timeout") }
            .handleEvents(receiveOutput: { [weak controller] _ in
                controller?.updateActionState(mac: mac, state: .working(0))
            })
            .first()
            .share()
            .eraseToAnyPublisher()

        let setup = (didConnect, device, mac, controller)

        optionallyStream(config.thermometer, &streams, setup)
        optionallyStream(config.accelerometer, &streams, setup)
        optionallyStream(config.magnetometer, &streams, setup)
        optionallyStream(config.altitude, &streams, setup)
        optionallyStream(config.ambientLight, &streams, setup)
        optionallyStream(config.gyroscope, &streams, setup)
        optionallyStream(config.humidity, &streams, setup)
        optionallyStream(config.pressure, &streams, setup)
        optionallyStream(config.fusionEuler, &streams, setup)
        optionallyStream(config.fusionGravity, &streams, setup)
        optionallyStream(config.fusionLinear, &streams, setup)
        optionallyStream(config.fusionQuaternion, &streams, setup)

        return Publishers.MergeMany(streams)
            .receive(on: controller.workQueue)
            .collect()
            .handleEvents(receiveOutput: { [weak controller] tables in
                controller?.saveData(tables: tables, for: mac)
            })
            .map { _ in () }
            .eraseToAnyPublisher()
    }
}

fileprivate typealias StreamSetup = (didConnect: MWPublisher<MetaWear>,
                                     metawear: MetaWear,
                                     mac: MACAddress,
                                     controller: ActionController)

fileprivate func optionallyStream<S: MWStreamable>(
    _ config: S?,
    _ streams: inout [MWPublisher<MWDataTable>],
    _ setup: StreamSetup
) {
    guard let config = config else { return }
    let controller = setup.controller
    let mac = setup.mac
    let startDate = controller.startDate

    let publisher = setup.didConnect
        .stream(config)
        .handleEvents(receiveOutput: { [weak controller] _ in
            controller?.streamCounters.counters[mac]?.send() }
        )
        .prefix(untilOutputFrom: setup.controller.streamCancel.receive(on: setup.metawear.bleQueue))
        .collect()
        .receive(on: setup.controller.workQueue)
        .map { MWDataTable(streamed: $0, config, startDate: startDate) }
        .eraseToAnyPublisher()

    streams.append(publisher)
}

fileprivate func optionallyStream<P: MWPollable>(
    _ config: P?,
    _ streams: inout [MWPublisher<MWDataTable>],
    _ setup: StreamSetup
) {
    guard let config = config else { return }
    let controller = setup.controller
    let mac = setup.mac
    let startDate = controller.startDate

    let publisher = setup.didConnect
        .stream(config)
        .handleEvents(receiveOutput: { [weak controller] _ in
            controller?.streamCounters.counters[mac]?.send() }
        )
        .prefix(untilOutputFrom: setup.controller.streamCancel.receive(on: setup.metawear.bleQueue))
        .collect()
        .receive(on: setup.controller.workQueue)
        .map { MWDataTable(streamed: $0, config, startDate: startDate) }
        .eraseToAnyPublisher()

    streams.append(publisher)
}

// MARK: - UI Labels

public extension ActionType {

    var title: String {
        switch self {
            case .stream:       return "Stream"
            case .log:          return "Log"
            case .downloadLogs: return "Download Logs"
        }
    }

    var workingLabel: String {
        switch self {
            case .stream:       return "Streaming"
            case .log:          return "Programming"
            case .downloadLogs: return "Downloading"
        }
    }

    var completedLabel: String {
        switch self {
            case .stream:       return "Streamed"
            case .log:          return "Logging"
            case .downloadLogs: return "Downloaded"
        }
    }

    init(destination: Routing.Destination) {
        switch destination {
            case .stream: self = .stream
            case .log: self = .log
            case .downloadLogs: self = .downloadLogs
            default: fatalError("Unrecognized action")
        }
    }
}