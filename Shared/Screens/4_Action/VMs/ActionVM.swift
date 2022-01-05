// Copyright 2021 MbientLab Inc. All rights reserved. See LICENSE.MD.

import mbientSwiftUI
import Combine
import MetaWear
import MetaWearSync

public class ActionVM: ObservableObject, ActionHeaderVM {
    public typealias QueueItem = (device: MetaWear?,
                                  meta: MetaWear.Metadata,
                                  config: ModulesConfiguration)

    // Overview of action
    public var representativeConfig:    ModulesConfiguration { configs.first ?? .init() }
    public let actionType:              ActionType
    public var actionDidComplete:       Bool { actionState.allSatisfy { $0.value == .completed } }

    /// Device currently the focus of connect/stream/log/download command
    @Published public var actionFocus:  MACAddress = ""

    // Per-device action state
    public let deviceVMs:                    [AboutDeviceVM]
    @Published private(set) var actionState: [MACAddress:ActionState]
    public let streamCounters:               StreamingCountersContainer

    // Data export state
    @Published var showExportFilesCTA  = false
    @Published var isExporting = false
    @Published var cloudSaveState: CloudSaveState = .notStarted
    private let sessionID = UUID()
    public let name: String
    private let date: Date
    private var files: [File] = []
    private var devicesExportReady:     Int = 0
    private var exporter: FilesExporter? = nil
    private var saveSession: AnyCancellable? = nil

    // Queue for performing action device-by-device (on private DispatchQueue)
    private var nextQueueItem:          QueueItem? = nil
    private var actionQueue:            [QueueItem] = []
    private var actionFails:            [QueueItem] = []
    private var actions:                [MACAddress:AnyCancellable] = [:]
    private let configs:                [ModulesConfiguration]
    private let streamCancel            = PassthroughSubject<Void,Never>()
    private unowned let workQueue:      DispatchQueue
    private var bleQueue:               DispatchQueue { store.bleQueue }

    // References
    private let devices:                [MWKnownDevice]
    private unowned let routing:        Routing
    private unowned let store:          MetaWearSyncStore
    private unowned let sessions:       SessionRepository
    private unowned let logging:        ActiveLoggingSessionsStore

    public init(action: ActionType,
                name: String,
                date: Date,
                devices: [MWKnownDevice],
                vms: [AboutDeviceVM],
                store: MetaWearSyncStore,
                sessions: SessionRepository,
                routing: Routing,
                logging: ActiveLoggingSessionsStore,
                backgroundQueue: DispatchQueue
    ) {
        self.workQueue = backgroundQueue
        self.name = name
        self.date = date
        self.sessions = sessions
        self.actionType = action
        self.devices = devices
        self.configs = action == .downloadLogs
        ? Array(repeating: .init(), count: devices.endIndex)
        : routing.focus?.configs ?? []
        self.routing = routing
        self.logging = logging
        self.store = store
        self.deviceVMs = vms
        self.actionState = Dictionary(repeating: .notStarted, keys: devices)
        self.streamCounters = .init(action, devices)
    }

    public func onAppear() {
        startAction()
    }
}

// MARK: - Intents

public extension ActionVM {

    /// User intent to enqueue a recovery for a device whose connection or operation failed/timed out
    func retry(_ meta: MetaWear.Metadata) {
        workQueue.sync {
            guard nextQueueItem?.meta != meta else { return }
        }

        if self.actionQueue.isEmpty {
            startAction()
            return
        }

        workQueue.sync {
            if let failure = actionFails.first(where: { $0.meta == meta }) {
                actionFails.removeAll(where: { $0.meta == meta })
                actionQueue.insert(failure, at: 0)
            }
        }
        startAction()
    }

    // MARK: - CTAs

    func stopStreaming() {
        streamCancel.send()
    }

    func downloadLogs() {
        guard actionType == .log else { return }
        routing.setDestination(.downloadLogs)
    }

    func exportFiles() {
        isExporting = true
        exporter?.runExportInteraction(onQueue: workQueue) {
            DispatchQueue.main.async { [weak self] in
                self?.isExporting = false
            }
        }
    }

    // MARK: - Navigation

    func cancelAndUndo() {
        actions.forEach { $0.value.cancel() }
        workQueue.sync {
            self.nextQueueItem = nil
            self.actionQueue = []
        }
        actionFocus = ""
        actionState = actionState.mapValues { state in
            guard state.hasOutcome == false else { return state }
            return .notStarted
        }
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

    /// Kickoff the action
    func startAction() {
        // One attempt at a time
        workQueue.sync(flags: .barrier) {
            guard self.nextQueueItem == nil else { return }
            setupQueue()
        }
        workQueue.async { [weak self] in
            self?.moveToNextQueueItem()
        }
    }

    static let timeoutDuration = DispatchQueue.SchedulerTimeType.Stride(30)

    func attemptAction(device current: QueueItem) {
        // 1 - Update UI state
        DispatchQueue.main.sync { [weak self] in
            self?.actionState[current.meta.mac] = .working(0)
        }

        // 2 - Acquire a device reference or skip
        guard let device = acquireDevice(current) else {
            self.fail(fromCurrent: current, .timeout)
            return
        }

        // 3 - Setup recording pipeline
        actions[current.meta.mac] = getActionPublisher(device, current.meta.mac, current.config)
            .receive(on: workQueue)
            .sink { [weak self] completion in
                guard case let .failure(error) = completion else { return }
                let timedOut = error.localizedDescription.contains("Timeout")
                self?.fail(fromCurrent: current, timedOut ? .timeout : .error(error.localizedDescription))
                self?.moveToNextQueueItem()

            } receiveValue: { [weak self] _ in
                self?.succeed(fromCurrent: current.meta)
                self?.moveToNextQueueItem()
            }

        // 4 - Kickoff through AboutDeviceVM in case design changes later
        if let vm = deviceVMs.first(where: { $0.meta == current.meta }) { vm.connect() }

        if actionType == .stream {
            moveToNextQueueItem()
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
            self.actionState[item.meta.mac, default: .notStarted] = .notStarted
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
            actionState[fromCurrent.meta.mac] = reason
        } else {
            DispatchQueue.main.sync { [weak self] in
                self?.actionFails.append(fromCurrent)
                self?.actionState[fromCurrent.meta.mac] = reason
            }
        }
    }

    /// Success cases: Advance to the next item, no need to update UI state
    func succeed(fromCurrent: MetaWear.Metadata) {
        if Thread.isMainThread {
            actionState[fromCurrent.mac] = .completed
        } else {
            DispatchQueue.main.sync { [weak self] in
                self?.actionState[fromCurrent.mac] = .completed
            }
        }
        actions[fromCurrent.mac]?.cancel()
    }

    /// Call on private queue
    func moveToNextQueueItem() {
        self.nextQueueItem = self.actionQueue.popLast()
        DispatchQueue.main.async { [weak self] in
            self?.actionFocus = self?.nextQueueItem?.meta.mac ?? ""
        }
        guard let next = self.nextQueueItem else { return }
        self.attemptAction(device: next)
    }
}

// MARK: - Save data from Stream or Download actions

private extension ActionVM {

    /// Call after downloading or completing streaming for one device
    func saveData(tables: [MWDataTable], for mac: MACAddress) {
        workQueue.async(flags: .barrier) { [weak self] in
            guard let self = self else { return }

            let files = tables.reduce(into: [File]()) { files, table in
                guard table.rows.isEmpty == false else { return }
                let data = table.makeCSV().data(using: .utf8) ?? Data()
                let deviceName = self.devices.first(where: { $0.meta.mac == mac })?.meta.name ?? mac
                let file = File(csv: data,
                                deviceName: deviceName,
                                signal: table.source,
                                date: self.date)
                files.append(file)
            }
            self.files.append(contentsOf: files)

            self.updateDevicesExportReadyState()
        }
    }

    /// Call on background queue to trigger, when all devices' data are ready, a database write + option for user to immediately export
    func updateDevicesExportReadyState() {
        devicesExportReady += 1
        guard devicesExportReady == devices.endIndex, files.isEmpty == false else { return }
        self.saveSessionToAppDatabase()

        do { self.exporter = try .init(id: sessionID, name: name, files: files) }
        catch { NSLog("\(Self.self)" + error.localizedDescription) }

        DispatchQueue.main.async { [weak self] in
            self?.showExportFilesCTA = true
        }
    }

    func saveSessionToAppDatabase() {
        guard files.isEmpty == false else { return }
        DispatchQueue.main.async { [weak self] in
            self?.cloudSaveState = .saving
        }

        let session = Session(id: sessionID,
                              date: date,
                              name: name,
                              group: getGroup(),
                              devices: Set(deviceVMs.map(\.meta.mac)),
                              files: Set(files.map(\.id))
        )

        saveSession = sessions.addSession(session, files: files)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                switch completion {
                    case .failure(let error): self?.cloudSaveState = .error(error)
                    case .finished: self?.cloudSaveState = .saved
                }
            } receiveValue: { _ in }
    }

    func getGroup() -> UUID? {
        guard case let .group(id) = routing.focus?.item else { return nil }
        return id
    }
}

// MARK: - Specific actions

private extension ActionVM {

    /// A Publisher that emits a value (void) only once when complete, but includes a Timeout operator.
    func getActionPublisher(_ device: MetaWear, _ mac: MACAddress, _ config: ModulesConfiguration) -> MWPublisher<Void> {
        switch actionType {
            case .downloadLogs: return downloadLogs(for: device, mac)
            case .log: return recordMacro(for: device, config)
            case .stream: return stream(for: device, mac: mac, config: config)
        }
    }

    // MARK: - Log Action

    /// Record the macro and update UI state upon completion
    func recordMacro(for device: MetaWear, _ config: ModulesConfiguration) -> MWPublisher<Void> {
        device
            .publishWhenConnected()
            .first()
            .mapToMWError() //
            .macro(config)
            .timeout(Self.timeoutDuration, scheduler: workQueue) { .operationFailed("Timeout") }
            .map { _ in () }
            .handleEvents(receiveOutput: { [weak self] _ in
                guard let self = self else { return }
                let token = Session.LoggingToken(
                    id: self.routing.focus!.item,
                    date: self.date,
                    name: self.name
                )
                self.logging.register(token: token)
            })
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
            .receive(on: workQueue)
            .handleEvents(receiveOutput: { [weak self] download in
                DispatchQueue.main.async { [weak self] in
                    let percent = Int(download.percentComplete * 100)
                    self?.actionState[mac] = .working(percent)
                }
            })
            .drop(while: { $0.percentComplete < 1 })
            .handleEvents(receiveOutput: { [weak self] download in
                self?.saveData(tables: download.data, for: mac)
            })
            .map { _ in () }
            .handleEvents(receiveOutput: { [weak self] _ in
                guard let self = self else { return }
                self.logging.remove(token: self.routing.focus!.item)
            })
            .eraseToAnyPublisher()
    }

    // MARK: - Stream Action

    typealias StreamSetup = (didConnect: MWPublisher<MetaWear>, mac: MACAddress)

    /// Stream all needed sensors on one device. Times out only when unable to connect.
    func stream(for device: MetaWear,
                mac: MACAddress,
                config: ModulesConfiguration) -> MWPublisher<Void> {

        var streams = [MWPublisher<MWDataTable>]()

        let didConnect = device
            .publishWhenConnected()
            .mapToMWError()
            .timeout(Self.timeoutDuration, scheduler: workQueue) { .operationFailed("Timeout") }
            .handleEvents(receiveOutput: { [weak self] _ in
                DispatchQueue.main.async { [weak self] in
                    self?.actionState[mac] = .working(0)
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
