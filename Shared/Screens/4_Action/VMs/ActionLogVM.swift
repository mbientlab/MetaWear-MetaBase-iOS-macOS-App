// Copyright 2021 MbientLab Inc. All rights reserved. See LICENSE.MD.

import SwiftUI
import Combine
import MetaWear
import Metadata

public class ActionLogVM: ObservableObject, ActionHeaderVM {
    public typealias QueueItem = (device: MetaWear?, meta: MetaWear.Metadata, config: SensorConfigContainer)

    public let title:                String
    public var representativeConfig: SensorConfigContainer { configs.first ?? .init() }
    public let showBackButton        = true

    public let deviceVMs:            [AboutDeviceVM]
    @Published var programmingState: [MACAddress:ActionState]
    public var showSuccessCTAs:      Bool { programmingState.allSatisfy { $0.value == .completed } }

    @Published var nextQueueItem:    QueueItem? = nil
    public var programmingFocus:     MACAddress { nextQueueItem?.meta.mac ?? "" }
    private var programmingQueue:    [QueueItem] = []
    private var programmingFailures: [QueueItem] = []
    private var subs:                [MACAddress:AnyCancellable] = [:]
    private let configs:             [SensorConfigContainer]

    private let devices:             [MWKnownDevice]
    private let routingItem:         Routing.Item
    private unowned let routing:     Routing
    private unowned let store:       MetaWearStore
    private unowned let queue:       DispatchQueue

    public init(item: Routing.Item, devices: [MWKnownDevice], vms: [AboutDeviceVM], store: MetaWearStore, routing: Routing, queue: DispatchQueue) {
        self.queue = queue
        self.title = "Logging"
        self.routingItem = item
        self.devices = devices
        self.configs = routing.destination.configs ?? []
        self.routing = routing
        self.store = store
        self.deviceVMs = vms
        self.programmingState = Dictionary(uniqueKeysWithValues: devices.map(\.meta.mac).map { ($0, .notStarted)} )
    }
}

public extension ActionLogVM {

    func didTapBackButton() -> Bool {
        // Cancel
        return true
    }

    static private let timeoutDuration = Double(30)

    func start() {
        // One attempt at a time
        guard self.nextQueueItem == nil else { return }

        // Setup a queue. On retries, handle the unfinished queue only.
        if self.programmingQueue.isEmpty {
            self.programmingQueue = self.programmingFailures.isEmpty
            ? zip(self.devices, self.configs).reversed().map { ($0.0, $0.1, $1) }
            : self.programmingFailures
        }
        for item in programmingQueue {
            self.programmingState[item.meta.mac, default: .notStarted] = .notStarted
        }

        guard self.nextQueueItem == nil else { return }
        self.nextQueueItem = self.programmingQueue.popLast()

        queue.async { [weak self] in
            while let current = self?.nextQueueItem {
                self?.tryToProgram(device: current)
            }

            // Exit this run
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                self.nextQueueItem = nil
                self.programmingQueue = self.programmingFailures.reversed()
            }
        }
    }

    func retry(_ meta: MetaWear.Metadata) {
        guard self.nextQueueItem?.meta != meta else { return }
        if self.programmingQueue.isEmpty { start(); return }
        print("Inserting")
        if let item = programmingFailures.first(where: { $0.meta == meta }) {
            self.programmingQueue.insert(item, at: 0)
        }
        start()
    }

    func cancelAndUndo() {
        // erase macros
        // stop start function
    }
}

// MARK: - Perform log and update UI state

private extension ActionLogVM {

    func tryToProgram(device current: QueueItem) {
        // 1 - Update UI state
        DispatchQueue.main.sync {
            print(#line)
            programmingState[current.meta.mac] = .working
        }

        // 2 - Acquire a device reference or skip
        guard let device = acquireDevice(current) else {
            self.markAsFailureAndAdvance(fromCurrent: current, .timeout)
            return
        }

        // 3 - Setup recording pipeline
        let semaphore = DispatchSemaphore(value: 0)
        subs[current.meta.mac] = recordMacro(for: device, current.config)
            .receive(on: DispatchQueue.main)
            .handleEvents(receiveOutput: { [weak self] macroID in
                self?.programmingState[current.meta.mac] = .completed
            }, receiveCompletion: { [weak self] completion in
                guard let self = self else { return }
                switch completion {
                    case .failure(let error):
                        self.programmingState[current.meta.mac] = error.localizedDescription.contains("Timeout") ? .timeout : .error
                        print(error.localizedDescription, #line)

                    case .finished:
                        self.programmingState[current.meta.mac] = .completed
                }
            }, receiveCancel: { [weak self] in
                guard let self = self else { return }
                let alreadyCompleted = self.programmingState[current.meta.mac] == .completed

                self.programmingState[current.meta.mac] = alreadyCompleted ? .completed : .timeout
                if alreadyCompleted == false {
                    self.programmingFailures.append(current)
                }
            })
            .sink { [weak self] completion in
                guard case let .failure(error) = completion else { return }
                print(error.localizedDescription)
                self?.markAsFailureAndAdvance(fromCurrent: current, .error)
                self?.subs[current.meta.mac]?.cancel()
                semaphore.signal()
            } receiveValue: { [weak self] _ in
                self?.advanceToNextDevice(fromCurrent: current.meta)
                self?.subs[current.meta.mac]?.cancel()
                semaphore.signal()
            }

        // 4 - Kickoff
        if let vm = deviceVMs.first(where: { $0.meta == current.meta }) { vm.connect() } else { device.connect() }

        // 5 - Wait for programming to complete (until timeout)
        switch semaphore.wait(timeout: DispatchTime.now() + Self.timeoutDuration) {
            case .success:
                // 5.A If somehow the publisher didn't already advance, do that (unlikely)
                guard self.nextQueueItem?.meta == current.meta else { return }
                advanceToNextDevice(fromCurrent: current.meta)

            case .timedOut:
                // 5.B If somehow the publisher didn't already mark this as a failure (e.g., semaphore timeout), do that
                guard programmingFailures.last?.meta != current.meta else { return }
                subs[current.meta.mac]?.cancel()
                markAsFailureAndAdvance(fromCurrent: current, .timeout)
        }
    }

    /// Get a reference to a MetaWear from the store if not available at start
    func acquireDevice(_ item: QueueItem) -> MetaWear? {
        var device = item.device
        if device == nil { device = store.getDevice(item.meta) }
        return device
    }

    /// Failure cases: Update UI state to show failure reason and advance to the next queue item
    func markAsFailureAndAdvance(fromCurrent: QueueItem, _ reason: ActionState) {
        if Thread.isMainThread {
            print(#function, #line)
            self.programmingFailures.append(fromCurrent)
            self.programmingState[fromCurrent.meta.mac] = reason
            self.nextQueueItem = self.programmingQueue.popLast()

        } else {
            DispatchQueue.main.sync { [weak self] in
                print(#function, #line)
                guard let self = self else { return }
                print(#function, #line)
                self.programmingFailures.append(fromCurrent)
                self.programmingState[fromCurrent.meta.mac] = reason
                self.nextQueueItem = self.programmingQueue.popLast()
            }
        }
    }

    /// Success cases: Advance to the next item, no need to update UI state
    func advanceToNextDevice(fromCurrent: MetaWear.Metadata) {
        /// Publisher pipeline will already have updated device state.
        if Thread.isMainThread {
            print(#function, #line)
            if self.nextQueueItem?.meta == fromCurrent {
                self.nextQueueItem = self.programmingQueue.popLast()
            }
        } else {
            print(#function, #line)
            DispatchQueue.main.sync { [weak self] in
                if self?.nextQueueItem?.meta == fromCurrent {
                    self?.nextQueueItem = self?.programmingQueue.popLast()
                }
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
