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

    @Published public private(set) var enableCTA = false
    @Published public private(set) var showSessionStartAlert = false
    public let alert: String
    private var enableCTAUpdates: AnyCancellable? = nil
    private var showStartAlertUpdates: AnyCancellable? = nil
    private var performDisconnectOnDisappear = true
    private var loggingUpdates: AnyCancellable? = nil
    private var didAppear = false

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

    func performCTA() {
        performDisconnectOnDisappear = false
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
        guard didAppear == false else { return }
        didAppear = true
        items.forEach { $0.connect() }

        startValidatingSessionStartCTA()

        let focus = routing.focus!.item
        loggingUpdates = logging.tokens
            .map { $0[focus] }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] token in
                self?.cta = .init(ongoingLoggingSession: token)
            }
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
                self?.enableCTA = canStart
            })

        showStartAlertUpdates = timer
            .compactMap { [weak self] _ in
                self?.items.allSatisfy { $0.isNearby }
            }
            .removeDuplicates()
            .sink(receiveValue: { [weak self] canStart in
                self?.showSessionStartAlert = !canStart
            })
    }
}

public enum AvailableActivity {
    case isLogging
    case newSession

    public var label: String {
        switch self {
            case .isLogging: return "Download Log"
            case .newSession: return "New Session"
        }
    }

    fileprivate init(ongoingLoggingSession: Session.LoggingToken?) {
        if let _ = ongoingLoggingSession { self = .isLogging }
        else { self = .newSession }
    }
}
