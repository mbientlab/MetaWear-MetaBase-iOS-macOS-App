// Copyright 2021 MbientLab Inc. All rights reserved. See LICENSE.MD.

import Foundation
import Combine
import MetaWear
import MetaWearSync

public class HistoryScreenVM: ObservableObject, HeaderVM {

    @Published public private(set) var items: [AboutDeviceVM] = []
    @Published public private(set) var ctaLabel = "New Session"

    @Published public private(set) var sessions: [Session] = []

    public let title: String
    public var deviceCount: Int { items.endIndex }
    public let showBackButton = true

    @Published public private(set) var showSessionStartAlert = false
    public let alert: String
    private var newSessionCanStartUpdates: AnyCancellable? = nil
    private var sessionsListUpdates: AnyCancellable? = nil

    private unowned let routing: Routing
    private unowned let scanner: MetaWearScanner
    private unowned let sessionRepo: SessionRepository

    public init(title: String,
                vms: [AboutDeviceVM],
                store: MetaWearSyncStore,
                sessionRepo: SessionRepository,
                routing: Routing,
                scanner: MetaWearScanner
    ) {
        self.sessionRepo = sessionRepo
        self.routing = routing
        self.scanner = scanner
        self.title = title
        self.items = vms

        alert = vms.endIndex > 1 ? "Bring all MetaWears nearby" : "Bring MetaWear nearby"
        startValidatingSessionStartCTA()
    }
}

public extension HistoryScreenVM {

    func performCTA() {
        // No need to reset focus
        routing.setDestination(.configure)
    }

    func refresh() {
        items.forEach { $0.refreshAll() }
    }

    func onAppear() {
        populateSessions()
        items.forEach { $0.connect() }
    }

    func onDisappear() {
        
    }

    func download(session: Session) {

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

    func populateSessions() {
        sessionsListUpdates = _makeSessionsListPublisher()
            .print()
            .sink { completion in
                switch completion {
                    case .failure(let error): print(error)
                    case .finished: print("FINISHED"); return
                }
            } receiveValue: { [weak self] sessions in
                self?.sessions = sessions
            }
    }

    func _makeSessionsListPublisher() -> AnyPublisher<[Session],Error> {
        // One device
        if deviceCount == 1, let mac = items.first?.meta.mac {
            return sessionRepo.fetchSessions(matchingMAC: mac)

        // For group
        } else if deviceCount > 1,
                    case let .group(groupID) = routing.focus?.item {
            return sessionRepo.fetchSessions(matchingGroupID: groupID)

        // Error case
        } else {
            return Just([]).setFailureType(to: Error.self).eraseToAnyPublisher()
        }
    }
}
