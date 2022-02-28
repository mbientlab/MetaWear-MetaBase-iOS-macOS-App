// Copyright 2021 MbientLab Inc. All rights reserved. See LICENSE.MD.

import Foundation
import Combine
import MetaWear
import MetaWearSync
import CoreBluetooth
import SwiftUI

public class HistoryScreenVM: ObservableObject, HeaderVM {

    @Published public private(set) var items: [AboutDeviceVM] = []
    @Published public private(set) var cta: AvailableActivity
    public var canCancelLogging: Bool { loggingToken?.isLogging == true }

    public let title: String
    public var deviceCount: Int { items.endIndex }

    @Published public private(set) var enableCTA = false
    @Published public private(set) var showSessionStartAlert = false
    @Published private var loggingToken: Session.LoggingToken?
    public let alert: String
    private var enableCTAUpdates: AnyCancellable? = nil
    private var showStartAlertUpdates: AnyCancellable? = nil
    private var performDisconnectOnDisappear = true
    private var loggingUpdates: AnyCancellable? = nil
    private var manualLogsCheck: AnyCancellable? = nil
    private var didAppear = false

#if os(iOS)
    @Published public private(set) var allDevicesConnectionState: CBPeripheralState  = .disconnected
    private var allDevicesConnectionSub: AnyCancellable? = nil
#endif

    private unowned let routing: Routing
    private unowned let scanner: MetaWearScanner
    private unowned let logging: ActiveLoggingSessionsStore

    public init(title: String,
                vms: [AboutDeviceVM],
                store: MetaWearSyncStore,
                routing: Routing,
                scanner: MetaWearScanner,
                logging: ActiveLoggingSessionsStore
    ) {
        self.routing = routing
        self.scanner = scanner
        self.logging = logging
        self.title = title
        self.items = vms.sorted(by: { $0.meta.name < $1.meta.name })
        let token = logging.session(for: routing.focus!.item)
        self.loggingToken = token
        self.cta = .init(ongoingLoggingSession: token)
        self.alert = Self.makeAlertMessage(soloTitle: vms.endIndex > 1 ? nil : title)
    }

    static func makeAlertMessage(soloTitle: String?) -> String {
        if let soloTitle = soloTitle {
            return "Bring \(soloTitle) nearby"
        } else {
            return "Bring all MetaWears nearby"
        }
    }

    deinit {
        if performDisconnectOnDisappear {
            items.forEach { $0.disconnect() }
        }
    }
}

public extension HistoryScreenVM {

    func onAppear() {
        guard didAppear == false else { return }
        didAppear = true
        items.forEach { $0.connect() }

        startValidatingSessionStartCTA()
        trackLoggingTokenToUpdateCTA()
    }

    func performCTA() {
        performDisconnectOnDisappear = false
        switch cta {
            case .newSession:
                // No need to reset focus
                routing.setDestination(.configure)
            case .downloadLog:
            let ongoingSessionName = logging.session(for: routing.focus!.item)?.name ?? Session.defaultName
                routing.setSessionName(ongoingSessionName)
                routing.setDestination(.downloadLogs)
        }
    }

    func stopLoggingAllDevices() {
        items.forEach { $0.stopLogging() }
        self.loggingToken?.isLogging = false
        guard let token = self.loggingToken else { return }
        logging.register(token: token)
    }

    func refresh() {
        items.forEach { $0.refreshAll() }
        startValidatingSessionStartCTA()
        setCTAByLogLength()
    }

    private func setCTAByLogLength() {
        let focus = routing.focus!.item
        manualLogsCheck = Publishers.MergeMany(items.map(\.loggedDataBytesSubject))
            .scan(false, { state, length in
                guard let length = length else { return state }
                return state == false ? length > 1 : state
            })
            .removeDuplicates()
            .sink(receiveValue: { [weak self] isLoggingByLogLength in
                guard let self = self else { return }
                // Remove logging token when no data to download anymore
                if !isLoggingByLogLength && self.cta == .downloadLog {
                    self.logging.remove(token: focus)
                }
                self.cta = isLoggingByLogLength ? .downloadLog : .newSession
            })

        items.forEach { $0.updateLoggedDataSize() }
    }
}

private extension HistoryScreenVM {

    func startValidatingSessionStartCTA() {
        let timer = Timer.TimerPublisher(interval: 0.5, tolerance: 0.5, runLoop: .main, mode: .common)
            .autoconnect()
            .share()

        enableCTAUpdates = timer
            .compactMap { [weak self] _ in
                self?.items.allSatisfy { $0.connection == .connected }
            }
            .removeDuplicates()
            .sink(receiveValue: { [weak self] canStart in
                guard let self = self else { return }
                self.enableCTA = canStart
            })

        showStartAlertUpdates = timer
            .delay(for: 2, tolerance: 0.5, scheduler: DispatchQueue.main)
            .compactMap { [weak self] _ in
                self?.items.allSatisfy { $0.isNearby }
            }
            .removeDuplicates()
            .sink(receiveValue: { [weak self] canStart in
                self?.showSessionStartAlert = !canStart
            })

        // Coalesce devices into one "connection state"
#if os(iOS)
        allDevicesConnectionSub = timer
            .compactMap { [weak self] _ -> CBPeripheralState? in
                let states = Set(self?.items.map(\.connection) ?? [])
                if states == [.connected] { return .connected }
                if states.contains(.connecting) { return .connecting }
                return states.min()
            }
            .removeDuplicates()
            .sink { [weak self] state in
                self?.allDevicesConnectionState = state
            }
#endif
    }

    func trackLoggingTokenToUpdateCTA() {
        let focus = routing.focus!.item
        loggingUpdates = logging.tokens
            .map { $0[focus] }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] token in
                guard let self = self else { return }
                self.loggingToken = token
                if token == nil {
                    self.setCTAByLogLength()
                } else {
                    self.cta = AvailableActivity(ongoingLoggingSession: token)
                }
            }
    }
}

public enum AvailableActivity {
    case downloadLog
    case newSession

    public var label: String {
        switch self {
            case .downloadLog: return "Download Log"
            case .newSession: return "New Session"
        }
    }

    fileprivate init(ongoingLoggingSession: Session.LoggingToken?) {
        if let _ = ongoingLoggingSession { self = .downloadLog }
        else { self = .newSession }
    }

    fileprivate init?(verifyByLogLength devices: [AboutDeviceVM]) {
        let hasAnyData = devices.contains { $0.loggedDataBytesSubject.value ?? 0 > 1 }
        let confirmedNoData = devices.allSatisfy { $0.loggedDataBytesSubject.value ?? 2 <= 1 }

        if hasAnyData {
            self = .downloadLog
        } else if confirmedNoData {
            self = .newSession
        } else { // Missing devices
            return nil
        }
    }
}
