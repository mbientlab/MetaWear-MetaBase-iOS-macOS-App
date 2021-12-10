// Copyright 2021 MbientLab Inc. All rights reserved. See LICENSE.MD.

import SwiftUI
import Combine
import MetaWear
import Metadata

public class ActionVM: ObservableObject, ActionHeaderVM {
    public typealias QueueItem = (device: MetaWear?, meta: MetaWear.Metadata, config: SensorConfigContainer)

    // Overview of action
    public var representativeConfig:    SensorConfigContainer { configs.first ?? .init() }
    public let actionType:              ActionType
    public let showBackButton           = true
    public var showSuccessCTAs:         Bool { state.allSatisfy { $0.value == .completed } }
    @Published public var actionFocus:  MACAddress = ""

    // Per-device action state
    public let deviceVMs:               [AboutDeviceVM]
    @Published private(set) var state:  [MACAddress:ActionState]

    // Queue for performing action device-by-device (on private DispatchQueue)
    private var nextQueueItem:          QueueItem? = nil
    private var actionQueue:            [QueueItem] = []
    private var actionFails:            [QueueItem] = []
    private var actions:                [MACAddress:AnyCancellable] = [:]
    private let configs:                [SensorConfigContainer]
    private unowned let queue:          DispatchQueue

    // References
    private let devices:                [MWKnownDevice]
    private let routingItem:            Routing.Item
    private unowned let routing:        Routing
    private unowned let store:          MetaWearStore

    public init(item: Routing.Item, action: ActionType, devices: [MWKnownDevice], vms: [AboutDeviceVM], store: MetaWearStore, routing: Routing, queue: DispatchQueue) {
        self.queue = queue
        self.actionType = action
        self.routingItem = item
        self.devices = devices
        self.configs = routing.destination.configs ?? []
        self.routing = routing
        self.store = store
        self.deviceVMs = vms
        self.state = Dictionary(uniqueKeysWithValues: devices.map(\.meta.mac).map { ($0, .notStarted)} )
    }
}

public extension ActionVM {

    func didTapBackButton() -> Bool {
        // Cancel

        return true
    }

    static private let timeoutDuration = DispatchQueue.SchedulerTimeType.Stride(30)

    func start() {
        // One attempt at a time
        queue.sync(flags: .barrier) {
            guard self.nextQueueItem == nil else { return }
            setupQueue()
            moveToNextQueueItem()
        }
        queue.async { [weak self] in
            while let current = self?.nextQueueItem {
                self?.tryAction(device: current)
                self?.moveToNextQueueItem()
            }
        }
    }

    func retry(_ meta: MetaWear.Metadata) {
        queue.sync {
            guard nextQueueItem?.meta != meta else { return }
        }

        if self.actionQueue.isEmpty {
            start()
            return
        }

        queue.sync {
            if let failure = actionFails.first(where: { $0.meta == meta }) {
                actionFails.removeAll(where: { $0.meta == meta })
                actionQueue.insert(failure, at: 0)
            }
        }
        start()
    }

    func cancelAndUndo() {
        // erase macros
        // stop start function
    }
}

// MARK: - Perform log and update UI state

private extension ActionVM {

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

    /// Call on private queue
    func moveToNextQueueItem() {
        self.nextQueueItem = self.actionQueue.popLast()

        DispatchQueue.main.async { [weak self] in
            self?.actionFocus = self?.nextQueueItem?.meta.mac ?? ""
        }
    }

    func tryAction(device current: QueueItem) {
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
        actions[current.meta.mac] = recordMacro(for: device, current.config)
            .receive(on: queue)
            .timeout(Self.timeoutDuration, scheduler: queue) { .operationFailed("Timeout") }
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
        if let vm = deviceVMs.first(where: { $0.meta == current.meta }) {
            vm.connect()
        } else { device.connect() }

        // 5 - Wait for programming to complete (until timeout)
        semaphore.wait()
        actions[current.meta.mac]?.cancel()
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

    /// Record the macro and update UI state upon completion
    func recordMacro(for device: MetaWear, _ config: SensorConfigContainer) -> MWPublisher<MWMacroIdentifier> {
        device
            .publishWhenConnected()
            .first()
            .mapToMWError()
            .macro(config)
            .eraseToAnyPublisher()
    }
}
