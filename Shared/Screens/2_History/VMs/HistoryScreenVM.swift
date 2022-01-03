// Copyright 2021 MbientLab Inc. All rights reserved. See LICENSE.MD.

import Foundation
import Combine
import MetaWear
import MetaWearSync

public class HistoryScreenVM: ObservableObject, HeaderVM {

    @Published public private(set) var items: [AboutDeviceVM] = []
    @Published public private(set) var cta: AvailableActivity

    public let title: String
    public var deviceCount: Int { items.endIndex }
    public let showBackButton = true

    @Published public private(set) var showSessionStartAlert = false
    public let alert: String
    private var newSessionCanStartUpdates: AnyCancellable? = nil

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
        self.items = vms
        self.cta = .init(ongoingLoggingSession: logging.session(for: routing.focus!.item))

        alert = vms.endIndex > 1 ? "Bring all MetaWears nearby" : "Bring MetaWear nearby"
        startValidatingSessionStartCTA()
    }
}

public extension HistoryScreenVM {

    func performCTA() {

        switch cta {
            case .newSession:
                // No need to reset focus
                routing.setDestination(.configure)
            case .isLogging:
                let ongoingSessionName = logging.session(for: routing.focus!.item)?.name ?? "New Session"
                routing.setSessionName(ongoingSessionName)
                routing.setDestination(.downloadLogs)
        }
    }

    func refresh() {
        items.forEach { $0.refreshAll() }
    }

    func onAppear() {
        items.forEach { $0.connect() }
    }

    func onDisappear() {
        items.forEach { $0.disconnect() }
    }

}

private extension HistoryScreenVM {

    func startValidatingSessionStartCTA() {
        newSessionCanStartUpdates = Timer.TimerPublisher(interval: 1, tolerance: 1, runLoop: .main, mode: .common)
            .compactMap { [weak self] _ in self?.items.contains(where: { $0.isNearby == false }) }
            .removeDuplicates()
            .sink(receiveValue: { [weak self] shouldAlert in
                self?.showSessionStartAlert = shouldAlert
            })
    }
}

public enum AvailableActivity {
    case isLogging
    case newSession

    public var label: String {
        switch self {
            case .isLogging: return "Download Logs"
            case .newSession: return "New Session"
        }
    }

    fileprivate init(ongoingLoggingSession: Session.LoggingToken?) {
        if let _ = ongoingLoggingSession { self = .isLogging }
        else { self = .newSession }
    }
}
