// Copyright 2021 MbientLab Inc. All rights reserved. See LICENSE.MD.

import mbientSwiftUI
import Combine
import MetaWear
import MetaWearSync

/// Performs an action (e.g., stream, log, download logs) for an arbitrary number of devices in a sequential queue.
///
/// Archives data obtained as CSVs grouped in one "session" event, linked to a device grouping ID and individual device MAC addresses. Optionally exports CSVs immediately.
///
public class ActionVM: ObservableObject, ActionHeaderVM {
    public typealias QueueItem = (device: MetaWear?,
                                  meta: MetaWearMetadata,
                                  config: ModulesConfiguration)

    // Overview of action
    public var representativeConfig:    ModulesConfiguration { configs.first ?? .init() }
    public let actionType:              ActionType
    public var actionDidComplete:       Bool { actionState.allSatisfy { $0.value == .completed } }
    public var hasErrors:               Bool { actionState.contains(where: { $0.value.hasError }) }
    @Published private(set) var retrievingPriorSession = false

    /// Device currently the focus of connect/stream/log/download command
    @Published public var actionFocus:  MACAddress = ""

    // Per-device action state
    public let deviceVMs:                    [AboutDeviceVM]
    @Published private(set) var actionState: [MACAddress:ActionState]
    public let streamCounters:               StreamingCountersContainer

    // Data export state
    @Published private(set) var export: Any? = nil
    @Published public var showExportFilesCTA = false
    @Published var isExporting               = false
    @Published var cloudSaveState:      CloudSaveState = .notStarted
    private let sessionID:              UUID
    public let title:                   String
    internal let startDate:             Date
    private var files:                  [File] = []
    private var currentDataStream:      [MACAddress:[MWDataTable]] = [:]
    private var devicesExportReady:     Int = 0
    private var exporter:               FilesExporter? = nil
    private var saveSession:            AnyCancellable? = nil
    private var navigationSub:          AnyCancellable? = nil

    // Queue for performing action device-by-device (on private DispatchQueue)
    private var nextQueueItem:          QueueItem? = nil
    private var actionQueue:            [QueueItem] = []
    private var actionFails:            [QueueItem] = []
    private var actions:                [MACAddress:AnyCancellable] = [:]
    private let configs:                [ModulesConfiguration]
    internal var tempLoadDate:           [MACAddress : Date] = [:]
    internal let streamCancel            = PassthroughSubject<Void,Never>()
    private var bleQueue:               DispatchQueue { store.bleQueue }
    internal unowned let workQueue:     DispatchQueue
    internal let timeoutDuration = DispatchQueue.SchedulerTimeType.Stride(30)

    // References
    private let devices:                [MWKnownDevice]
    private unowned let routing:        Routing
    private unowned let store:          MetaWearSyncStore
    private unowned let sessions:       SessionRepository
    private unowned let logging:        ActiveLoggingSessionsStore

    public init(action: ActionType,
                token: Session.LoggingToken,
                devices: [MWKnownDevice],
                vms: [AboutDeviceVM],
                store: MetaWearSyncStore,
                sessions: SessionRepository,
                routing: Routing,
                logging: ActiveLoggingSessionsStore,
                backgroundQueue: DispatchQueue
    ) {
        self.workQueue = backgroundQueue
        self.title = token.name
        self.startDate = token.date
        self.sessionID = token.sessionID
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
        retrievingPriorSession = true
        saveSession = sessions.fetchFiles(sessionID: sessionID)
            .sink { [weak self] completion in
                // Will error if the session ID isn't pre-existing.
                // That just means this is a new session, so proceed on.
                guard case .failure = completion else { return }
                DispatchQueue.main.async { [weak self] in
                    self?.retrievingPriorSession = false
                }
                self?.startAction()
            } receiveValue: { [weak self] files in
                self?.workQueue.sync { [weak self] in
                    self?.files = files
                }
                DispatchQueue.main.sync { [weak self] in
                    self?.retrievingPriorSession = false
                }
                self?.startAction()
            }
    }

    // Header VM conformance
    public var deviceCount: Int { deviceVMs.endIndex }
}

// MARK: - Intents

public extension ActionVM {

    /// User intent to enqueue a recovery for a device whose connection or operation failed/timed out
    func retry(_ meta: MetaWearMetadata) {
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
#if os(macOS)
        exporter?.runExportInteraction(onQueue: workQueue) { result in
            DispatchQueue.main.async { [weak self] in
                self?.isExporting = false
                if case let .success(url) = result, let url = url {
                    NSWorkspace.shared.activateFileViewerSelecting([url])
                }
            }
        }
#else
        // Present UI and copy files
        exporter?.runExportInteraction(onQueue: workQueue) { [weak self] result in
            DispatchQueue.main.async { [weak self] in
                switch result {
                    case .failure(let error):
                        self?.didDismissExportPopover(
                            selectedActivity: nil,
                            didPerformSelection: false,
                            modifiedItems: nil,
                            error: error)

                    case .success(let exportable):
                        self?.export = exportable
                }
            }
        }
#endif
    }

#if os(iOS)
    func didDismissExportPopover(
        selectedActivity: UIActivity.ActivityType?,
        didPerformSelection: Bool,
        modifiedItems: [Any]?,
        error: Error?
    ) {
        DispatchQueue.main.async { [weak self] in
            self?.export = nil
            self?.isExporting = false
        }
    }
#endif

    // MARK: - Navigation

    func pauseDownload() {
        deviceVMs.forEach { $0.disconnect() }
        actions.forEach { $0.value.cancel() }
        actionFocus = ""
        actionState = actionState.mapValues({ state in
            guard state.hasOutcome == false else { return state }
            return .completed
        })
    }

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
    }

    func backToHistory() {
        streamCancel.send()
        navigateUponDisconnect(to: .history)
        deviceVMs.forEach { $0.disconnect() }
    }

    func backToChooseDevices() {
        streamCancel.send()
        navigateUponDisconnect(to: .choose)
        deviceVMs.forEach { $0.disconnect() }
    }

    private func navigateUponDisconnect(to dest: Routing.Destination) {
        navigationSub = Publishers.MergeMany(deviceVMs.map(\.$connection))
            .filter { $0 == .disconnected }
            .collect(deviceVMs.count)
            .sink { [weak self] _ in
                self?.routing.goBack(until: dest)
            }
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
        actions[current.meta.mac] = actionType.getActionPublisher(device, current.meta.mac, current.config, self)
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
            DispatchQueue.main.async  { [weak self] in
                self?.actionState[item.meta.mac, default: .notStarted] = .notStarted
            }
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
    func succeed(fromCurrent: MetaWearMetadata) {
        if Thread.isMainThread {
            guard actionState[fromCurrent.mac] != .error("No data found") else { return }
            actionState[fromCurrent.mac] = .completed
        } else {
            DispatchQueue.main.sync { [weak self] in
                guard self?.actionState[fromCurrent.mac] != .error("No data found") else { return }
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

extension ActionVM: ActionController {

    func updateActionState(mac: MACAddress, state: ActionState) {
        DispatchQueue.main.async { [weak self] in
            self?.actionState[mac] = state
        }
    }

    func registerLoggingToken(isLogging: Bool) {
        let token = Session.LoggingToken(
            id: routing.focus!.item,
            date: startDate,
            name: title,
            sessionID: sessionID,
            isLogging: isLogging
        )
        logging.register(token: token)
    }

    func removeLoggingToken() {
        logging.remove(token: self.routing.focus!.item)
    }

    func stashData(tables: [MWDataTable], for mac: MACAddress) {
        self.currentDataStream[mac, default: []] = tables
    }

    /// Call after downloading or completing streaming for one device
    func saveData(for mac: MACAddress, didComplete: Bool) {
        workQueue.async(flags: .barrier) { [weak self] in
            guard let self = self, var tables = self.currentDataStream[mac] else { return }

            for tableIndex in tables.indices {

                guard tables[tableIndex].rows.isEmpty == false else { continue }
                let deviceName = self.devices.first(where: { $0.meta.mac == mac })?.meta.name ?? mac

                var newFile = File(
                    csv: .init(),
                    deviceName: deviceName,
                    signal: tables[tableIndex].source,
                    date: self.startDate
                )

                // If a prior session was loaded, use this as the starting data
                if let preexistingIndex = self.files.firstIndex(where: { $0.name == newFile.name }) {
                    newFile = self.files[preexistingIndex]
                    self.files.remove(at: preexistingIndex)
                }

                // Add new data to the end of any existing data
                let newCSVPrefix = newFile.csv.isEmpty ? "" : "\n"
                tables[tableIndex] = tables[tableIndex]
                    .formatButtonLogs()
                    .prefixUntil(date: self.tempLoadDate[mac])

                // Only create a CSV if there is data.
                guard tables[tableIndex].rows.isEmpty == false else {
                    if newFile.csv.isEmpty { continue }
                    self.files.append(newFile)
                    continue
                }

                let newCSV = tables[tableIndex].makeCSV(withHeaderRow: newFile.csv.isEmpty)
                newFile.csv.append((newCSVPrefix + newCSV).data(using: .utf8) ?? .init())
                self.files.append(newFile)
            }

            if tables.isEmpty || tables.allSatisfy({ $0.rows.isEmpty }) {
                DispatchQueue.main.async { [weak self] in
                    self?.actionState[mac] = .error("No data found")
                }
            }

            self.updateDevicesExportReadyState(didComplete: didComplete)
        }
    }
}

internal extension ActionVM {

    /// Call on background queue to trigger, when all devices' data are ready, a database write + option for user to immediately export
    private func updateDevicesExportReadyState(didComplete: Bool) {
        devicesExportReady += 1

        guard devicesExportReady == devices.endIndex,
              files.isEmpty == false
        else {
            DispatchQueue.main.async { [weak self] in
                self?.actionState = self?.actionState.mapValues { _ in .error("No data found") } ?? [:]
            }
            return
        }
        self.saveSessionToAppDatabase(didComplete: didComplete)

        do { self.exporter = try .init(id: sessionID, name: title, files: files) }
        catch { NSLog("\(Self.self)" + error.localizedDescription) }

        DispatchQueue.main.async { [weak self] in
            self?.showExportFilesCTA = true
        }
    }

    private func saveSessionToAppDatabase(didComplete: Bool) {
        guard files.isEmpty == false else { return }
        DispatchQueue.main.async { [weak self] in
            self?.cloudSaveState = .saving
        }

        let session = Session(
            id: sessionID,
            date: startDate,
            name: title,
            group: getGroup(),
            devices: Set(deviceVMs.map(\.meta.mac)),
            files: Set(files.map(\.id)),
            didComplete: didComplete
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

    private func getGroup() -> UUID? {
        guard case let .group(id) = routing.focus?.item else { return nil }
        return id
    }
}
