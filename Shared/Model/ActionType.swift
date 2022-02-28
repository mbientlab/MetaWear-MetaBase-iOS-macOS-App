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
    var tempLoadDate:    [MACAddress: Date] { get set }
    var timeoutDuration: DispatchQueue.SchedulerTimeType.Stride { get }
    var workQueue:       DispatchQueue { get }
    var streamCancel:    PassthroughSubject<Void,Never> { get }
    var streamCounters:  StreamingCountersContainer { get }

    func registerLoggingToken(isLogging: Bool)
    func removeLoggingToken()
    func updateActionState(mac: MACAddress, state: ActionState)
    /// Store accumulating data in preparation for a completion or early termination of the action
    func stashData(tables: [MWDataTable], for mac: MACAddress)
    /// Persist the accumulated data
    func saveData(for mac: MACAddress, didComplete: Bool)
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
            .handleEvents(receiveOutput: { [weak controller] _ in
                controller?.tempLoadDate[mac] = Date()
            })
            .loggersStart()
            .delay(for: 0.1, tolerance: 0, scheduler: controller.workQueue)
            .downloadLogs(startDate: controller.startDate)
            .receive(on: controller.workQueue)
            .handleEvents(receiveOutput: { [weak controller] download in
                // Update data and report current progress
                controller?.stashData(tables: download.data, for: mac)
                let percent = Int(download.percentComplete * 100)
                controller?.updateActionState(mac: mac, state: .working(percent))
            })
            .handleEvents(receiveCancel: { [weak controller] in
                // Export and save on pause
                controller?.saveData(for: mac, didComplete: false)
            })
            .drop(while: { $0.percentComplete < 1 })
            .handleEvents(receiveOutput: { [weak controller] _ in
                controller?.saveData(for: mac, didComplete: true)
                controller?.removeLoggingToken()
            })
            .compactMap { [weak device] _ in device }
            .command(.led(.green, .pulse(repetitions: 1)))
            .map { _ in () }
            .eraseToAnyPublisher()
    }
}

// MARK: - Log Action

extension ActionType {

    func recordMacro(for device: MetaWear,
                     _ config: ModulesConfiguration,
                     _ controller: ActionController
    ) -> MWPublisher<Void> {

        let reset =  device
            .publishWhenConnected()
            .first()
            .mapToMWError()
            .command(.macroEraseAll)
            .command(.resetActivities)
            .command(.restart)
            .map { _ in () }
            .eraseToAnyPublisher()

        let reconnect = device
            .publishWhenDisconnected()
            .first()
            .handleEvents(receiveOutput: { $0.connect() })
            .mapToMWError()
            .map { _ in () }
            .eraseToAnyPublisher()

        let program = device
            .publishWhenConnected()
            .dropFirst()
            .first()
            .mapToMWError()
            .writeRemoteStartPauseEvents(config)
            .writeLoggingMacro(config)
            .map { _ in () }
            .handleEvents(receiveOutput: { [weak controller] _ in
                controller?.registerLoggingToken(isLogging: true)
            })
            .eraseToAnyPublisher()

        return Publishers.Zip3(program, reconnect, reset)
            .map { _ in () }
            .timeout(controller.timeoutDuration, scheduler: controller.workQueue) { .operationFailed("Timeout") }
            .eraseToAnyPublisher()
    }
}

fileprivate extension AnyPublisher where Output == MetaWear, Failure == MWError {
    func writeLoggingMacro(_ config: ModulesConfiguration) -> MWPublisher<MWMacro.StopRecording.DataType> {
        let startsImmediately = config.mode == .log
        return self
            .command(.macroStartRecording(runOnStartup: true))
            .optionallyLog(config.button, startsImmediately: startsImmediately)
            .optionallyLog(config.accelerometer, startsImmediately: startsImmediately)
            .optionallyLog(config.altitude, startsImmediately: startsImmediately)
            .optionallyLog(config.gyroscope, startsImmediately: startsImmediately)
            .optionallyLog(byPolling: config.humidity, startsImmediately: startsImmediately)
            .optionallyLog(config.ambientLight, startsImmediately: startsImmediately)
            .optionallyLog(config.magnetometer, startsImmediately: startsImmediately)
            .optionallyLog(config.pressure, startsImmediately: startsImmediately)
            .optionallyLog(byPolling: config.thermometer, startsImmediately: startsImmediately)
            .optionallyLog(config.fusionEuler, startsImmediately: startsImmediately)
            .optionallyLog(config.fusionGravity, startsImmediately: startsImmediately)
            .optionallyLog(config.fusionLinear, startsImmediately: startsImmediately)
            .optionallyLog(config.fusionQuaternion, startsImmediately: startsImmediately)
            .command(.macroStopRecordingAndGenerateIdentifier)
            .map(\.result)
            .eraseToAnyPublisher()
    }

    func writeRemoteStartPauseEvents(_ config: ModulesConfiguration) -> MWPublisher<MetaWear> {
        guard config.mode == .remote else {
            return self
                .command(.led(.red, .slowRecordingFlash()))
        }
        return self
            .recordEvents(for: .buttonReleaseOdds) { record in
                record
                    .loggersStart()
                    .command(.logUserEvent(flag: 3))
                    .command(.led(.red, .slowRecordingFlash()))
            }
            .recordEvents(for: .buttonReleaseEvens) { record in
                record
                    .command(.logUserEvent(flag: 4))
                    .loggersPause()
                    .command(.led(.yellow, .slowRecordingFlash()))
            }
            .recordEvents(for: .buttonPressOdds) { record in
                record.command(.led(.red, .solid()))
            }
            .recordEvents(for: .buttonPressEvens) { record in
                record.command(.led(.yellow, .solid()))
            }
            .command(.led(.yellow, .slowRecordingFlash()))
    }
}

extension MWDataTable {
    
    func prefixUntil(date: Date?) -> MWDataTable {
        guard let date = date else { return self }

        let lastIndexBeforeDate = self.rows.lastIndex(where: {
            guard let epoch = Double($0.first ?? "")
            else { return false }
            return epoch < date.timeIntervalSince1970
        })

        guard let lastIndex = lastIndexBeforeDate else {
            var edited = self
            edited.rows = []
            return edited
        }

        guard lastIndex < self.rows.endIndex - 1 else {
            return self
        }

        var edited = self
        edited.rows = Array(edited.rows.prefix(through: lastIndex))
        return edited
    }

    func formatButtonLogs() -> MWDataTable {
        guard self.source == .mechanicalButton,
              var dataIndex = self.rows.first?.endIndex
        else { return self }
        dataIndex = max(0, dataIndex - 1)
        var edited = self
        edited.rows = edited.rows.map { row in
            switch row[dataIndex] {
            case "3":
                var row = row
                row[dataIndex] = "Start"
                return row
            case "4":
                var row = row
                row[dataIndex] = "Pause"
                return row
            default:
                return row
            }
        }
        return edited
    }
}

extension MWLED.Flash.Pattern {
    static func slowRecordingFlash() -> Self {
        MWLED.Flash.Pattern.custom(
            repetitions: .max,
            period: 5000,
            riseTime: 0,
            highTime: 70,
            fallTime: 0,
            offset: 0,
            intensityCeiling: 1,
            intensityFloor: 0
        )
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
        optionallyStream(config.button, &streams, setup)

        return Publishers.MergeMany(streams)
            .receive(on: controller.workQueue)
            .collect()
            .handleEvents(receiveOutput: { [weak controller] tables in
                controller?.stashData(tables: tables, for: mac)
                controller?.saveData(for: mac, didComplete: true)
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
