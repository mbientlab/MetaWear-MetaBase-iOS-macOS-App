// Copyright 2021 MbientLab Inc. All rights reserved. See LICENSE.MD.

import SwiftUI
import Combine
import MetaWear
import MetaWearSync

public class ActionVM: ObservableObject, ActionHeaderVM {
    public typealias QueueItem = (device: MetaWear?, meta: MetaWear.Metadata, config: SensorConfigContainer)

    // Overview of action
    public var representativeConfig:    SensorConfigContainer { configs.first ?? .init() }
    public let actionType:              ActionType
    public var showSuccessCTAs:         Bool { state.allSatisfy { $0.value == .completed } }
    @Published public var actionFocus:  MACAddress = ""

    // Per-device action state
    public let deviceVMs:               [AboutDeviceVM]
    @Published private(set) var state:  [MACAddress:ActionState]
    public let streamCounters:          StreamingCountersContainer
    private var data:                   [MACAddress:[MWDataTable]]

    @Published var deviceCSVsReady:     Int = 0
    var csvTempURLs:                    [URL] = []
    @Published var presentExportDialog  = false

    // Queue for performing action device-by-device (on private DispatchQueue)
    private var nextQueueItem:          QueueItem? = nil
    private var actionQueue:            [QueueItem] = []
    private var actionFails:            [QueueItem] = []
    private var actions:                [MACAddress:AnyCancellable] = [:]
    private let configs:                [SensorConfigContainer]
    private let streamCancel            = PassthroughSubject<Void,Never>()
    private unowned let workQueue:      DispatchQueue
    private var bleQueue:               DispatchQueue { store.bleQueue }

    // References
    private let devices:                [MWKnownDevice]
    private unowned let routing:        Routing
    private unowned let store:          MetaWearSyncStore

    public init(action: ActionType,
                devices: [MWKnownDevice],
                vms: [AboutDeviceVM],
                store: MetaWearSyncStore,
                routing: Routing,
                backgroundQueue: DispatchQueue) {
        self.workQueue = backgroundQueue
        self.actionType = action
        self.devices = devices
        self.configs = routing.focus?.configs ?? []
        self.routing = routing
        self.store = store
        self.deviceVMs = vms
        self.state = Dictionary(repeating: .notStarted, keys: devices)
        self.data = Dictionary(repeating: [], keys: devices)
        self.streamCounters = .init(action, devices)
    }
}

// MARK: - Intents

public extension ActionVM {

    func start() {
        // One attempt at a time
        workQueue.sync(flags: .barrier) {
            guard self.nextQueueItem == nil else { return }
            setupQueue()
            moveToNextQueueItem()
        }
        workQueue.async { [weak self] in
            while let current = self?.nextQueueItem {
                self?.attemptAction(device: current) // Has optional semaphore
                self?.moveToNextQueueItem()
            }
        }
    }

    func retry(_ meta: MetaWear.Metadata) {
        workQueue.sync {
            guard nextQueueItem?.meta != meta else { return }
        }

        if self.actionQueue.isEmpty {
            start()
            return
        }

        workQueue.sync {
            if let failure = actionFails.first(where: { $0.meta == meta }) {
                actionFails.removeAll(where: { $0.meta == meta })
                actionQueue.insert(failure, at: 0)
            }
        }
        start()
    }

    func stopStreaming() {
        streamCancel.send()
    }

    func downloadLogs() {
        guard actionType == .log else { return }
        routing.setDestination(.downloadLogs)
    }

    func exportFiles() {
        if self.deviceCSVsReady == self.deviceVMs.endIndex {
            self.presentExportDialog = true
        }
    }

    func cancelAndUndo() {
        actions.forEach { $0.value.cancel() }
        streamCancel.send()
        deviceVMs.forEach { $0.reset() }
    }

    func backToHistory() {
        streamCancel.send()
        routing.goBack(until: .history)
    }

    func backToChooseDevices() {
        streamCancel.send()
        routing.goBack(until: .choose)
    }
}

// MARK: - Perform generic action and update UI state

private extension ActionVM {

    static let timeoutDuration = DispatchQueue.SchedulerTimeType.Stride(30)

    func attemptAction(device current: QueueItem) {
        // 1 - Update UI state
        DispatchQueue.main.sync { [weak self] in
            self?.state[current.meta.mac] = .working(0)
        }

        // 2 - Acquire a device reference or skip
        guard let device = acquireDevice(current) else {
            self.fail(fromCurrent: current, .timeout)
            return
        }

        // 3 - Setup recording pipeline
        let semaphore = DispatchSemaphore(value: 0)
        actions[current.meta.mac] = getActionPublisher(device, current.meta.mac, current.config)
            .receive(on: workQueue)
            .sink { [weak self] completion in
                guard case let .failure(error) = completion else { return }
                let timedOut = error.localizedDescription.contains("Timeout")
                self?.fail(fromCurrent: current, timedOut ? .timeout : .error(error.localizedDescription))
                semaphore.signal()
            } receiveValue: { [weak self] _ in
                self?.succeed(fromCurrent: current.meta)
                semaphore.signal()
            }

        // 4 - Kickoff through AboutDeviceVM in case design changes later
        if let vm = deviceVMs.first(where: { $0.meta == current.meta }) { vm.connect() }

        // 5 - Wait for programming to complete (until timeout) if needed (not when streaming)
        if actionType.waitForSemaphore {
            semaphore.wait()
            actions[current.meta.mac]?.cancel()
        }
    }

    /// Populate a queue and set initial state.
    /// On retries, handle the unfinished queue only.
    func setupQueue() {
        if self.actionQueue.isEmpty {
            self.actionQueue = self.actionFails.isEmpty
            ? zip(self.devices, self.configs).reversed().map { ($0.0, $0.1, $1) }
            : self.actionFails.reversed()
        }
        for item in actionQueue {
            self.state[item.meta.mac, default: .notStarted] = .notStarted
        }
    }

    /// Get a reference to a MetaWear from the store if not available at start
    func acquireDevice(_ item: QueueItem) -> MetaWear? {
        var device = item.device
        if device == nil { device = store.getDevice(item.meta) }
        return device
    }

    /// Failure cases: Update UI state to show failure reason and advance to the next queue item
    func fail(fromCurrent: QueueItem, _ reason: ActionState) {
        if Thread.isMainThread {
            actionFails.append(fromCurrent)
            state[fromCurrent.meta.mac] = reason
        } else {
            DispatchQueue.main.sync { [weak self] in
                self?.actionFails.append(fromCurrent)
                self?.state[fromCurrent.meta.mac] = reason
            }
        }
    }

    /// Success cases: Advance to the next item, no need to update UI state
    func succeed(fromCurrent: MetaWear.Metadata) {
        if Thread.isMainThread {
            state[fromCurrent.mac] = .completed
        } else {
            DispatchQueue.main.sync { [weak self] in
                self?.state[fromCurrent.mac] = .completed
            }
        }
    }

    /// Call on private queue
    func moveToNextQueueItem() {
        self.nextQueueItem = self.actionQueue.popLast()
        DispatchQueue.main.async { [weak self] in
            self?.actionFocus = self?.nextQueueItem?.meta.mac ?? ""
        }
    }
}

// MARK: - Specific actions

private extension ActionVM {

    /// A Publisher that emits a value (void) only once when complete, but includes a Timeout operator.
    func getActionPublisher(_ device: MetaWear, _ mac: MACAddress, _ config: SensorConfigContainer) -> MWPublisher<Void> {
        switch actionType {
            case .downloadLogs: return downloadLogs(for: device, mac)
            case .log: return recordMacro(for: device, config)
            case .stream: return stream(for: device, mac: mac, config: config)
        }
    }

    // MARK: - Log Action

    /// Record the macro and update UI state upon completion
    func recordMacro(for device: MetaWear, _ config: SensorConfigContainer) -> MWPublisher<Void> {
        device
            .publishWhenConnected()
            .first()
            .mapToMWError() //
            .macro(config)
            .timeout(Self.timeoutDuration, scheduler: workQueue) { .operationFailed("Timeout") }
            .map { _ in () }
            .eraseToAnyPublisher()
    }

    // MARK: - Download Action

    func downloadLogs(for device: MetaWear, _ mac: MACAddress) -> MWPublisher<Void> {
        device
            .publishWhenConnected()
            .mapToMWError()
            .timeout(Self.timeoutDuration, scheduler: workQueue) { .operationFailed("Timeout") }
            .first()
            .downloadLogs()
            .handleEvents(receiveOutput: { [weak self] download in
                DispatchQueue.main.async { [weak self] in
                    let percent = Int(download.percentComplete * 100)
                    self?.state[mac] = .working(percent)
                }
                guard download.data.isEmpty == false else { return }
                self?.workQueue.async { [weak self] in
                    self?.saveData(tables: download.data, for: mac)
                }
            })
            .drop(while: { $0.percentComplete < 1 })
            .map { _ in () }
            .eraseToAnyPublisher()
    }

    func tempURL() -> URL {
        FileManager.default
            .temporaryDirectory
            .appendingPathComponent(Bundle.main.bundleIdentifier!, isDirectory: true)
    }

    func tempFolder(for mac: MACAddress) -> URL {
        tempURL().appendingPathComponent(mac.components(separatedBy: .alphanumerics.inverted).joined(separator: ""), isDirectory: true)
    }

    static let dateFormatter: DateFormatter = {
        let date = DateFormatter()
        date.dateStyle = .short
        date.timeStyle = .short
        return date
    }()

    func tempFileName(for signal: MWNamedSignal, date: Date) -> String {
        let dateString = Self.dateFormatter.string(from: date)
        let dateStringTrimmed = dateString.components(separatedBy: .alphanumerics.inverted).joined(separator: "-")
        return signal.name + " " + dateStringTrimmed
    }

    func saveData(tables: [MWDataTable], for mac: MACAddress) {
        self.data[mac] = tables
        print(mac, tables.map { ($0.source, $0.rows.endIndex) })
        writeTemporaryCSV(tables: tables, for: mac)
    }

    func writeTemporaryCSV(tables: [MWDataTable], for mac: MACAddress) {
        let date = Date()
        let folder = tempFolder(for: mac)
        tables.forEach { sensor in
            let fileName = tempFileName(for: sensor.source, date: date)
            let fileURL = folder.appendingPathComponent(fileName).appendingPathExtension("csv")
            do {
                try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true, attributes: nil)
                try sensor.makeCSV().write(to: fileURL, atomically: true, encoding: .utf8)
                self.csvTempURLs.append(fileURL)
            } catch { print(fileName, error) }
        }
        DispatchQueue.main.async { [weak self] in
            self?.deviceCSVsReady += 1
            if self?.deviceCSVsReady == self?.deviceVMs.endIndex {
                self?.presentExportDialog = true
            }
        }
    }

    // MARK: - Stream Action

    typealias StreamSetup = (didConnect: MWPublisher<MetaWear>, mac: MACAddress)

    /// Stream all needed sensors on one device. Times out only when unable to connect.
    func stream(for device: MetaWear,
                mac: MACAddress,
                config: SensorConfigContainer) -> MWPublisher<Void> {

        var streams = [MWPublisher<MWDataTable>]()

        let didConnect = device
            .publishWhenConnected()
            .mapToMWError()
            .timeout(Self.timeoutDuration, scheduler: workQueue) { .operationFailed("Timeout") }
            .handleEvents(receiveOutput: { [weak self] _ in
                DispatchQueue.main.async { [weak self] in
                    self?.state[mac] = .working(0)
                }
            })
            .first()
            .share()
            .eraseToAnyPublisher()

        let setup = (didConnect, mac)

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
            .receive(on: workQueue)
            .collect()
            .handleEvents(receiveOutput: { [weak self] tables in
                self?.saveData(tables: tables, for: mac)
            })
            .map { _ in () }
            .eraseToAnyPublisher()
    }

    func optionallyStream<S: MWStreamable>(
        _ config: S?,
        _ streams: inout [MWPublisher<MWDataTable>],
        _ setup: StreamSetup
    ) {
        guard let config = config else { return }

        let publisher = setup.didConnect
            .stream(config)
            .handleEvents(receiveOutput: { [weak self] _ in self?.streamCounters.counters[setup.mac]?.send() })
            .prefix(untilOutputFrom: streamCancel.receive(on: bleQueue))
            .collect()
            .receive(on: workQueue)
            .map { MWDataTable(streamed: $0, config) }
            .eraseToAnyPublisher()

        streams.append(publisher)
    }

    func optionallyStream<P: MWPollable>(_ config: P?,
                                         _ streams: inout [MWPublisher<MWDataTable>],
                                         _ setup: StreamSetup
    ) {
        guard let config = config else { return }

        let publisher = setup.didConnect
            .stream(config)
            .handleEvents(receiveOutput: { [weak self] _ in
                self?.streamCounters.counters[setup.mac]?.send() })
            .prefix(untilOutputFrom: streamCancel.receive(on: bleQueue))
            .collect()
            .receive(on: workQueue)
            .map { MWDataTable(streamed: $0, config) }
            .eraseToAnyPublisher()

        streams.append(publisher)
    }
}
