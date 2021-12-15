// Copyright 2021 MbientLab Inc. All rights reserved. See LICENSE.MD.

import Foundation
import Combine
import MetaWear
import MetaWearMetadata

public class HistoryScreenVM: ObservableObject, HeaderVM {

    @Published public private(set) var items: [AboutDeviceVM] = []
    @Published public private(set) var ctaLabel = "New Session"

    public let title: String
    public var deviceCount: Int { items.endIndex }
    public let showBackButton = true

    @Published public private(set) var showSessionStartAlert = false
    public let alert: String
    private var sub: AnyCancellable? = nil

    private unowned let routing: Routing
    private unowned let scanner: MetaWearScanner

    public init(title: String, vms: [AboutDeviceVM], store: MetaWearStore, routing: Routing, scanner: MetaWearScanner) {
        self.routing = routing
        self.scanner = scanner
        self.title = title
        self.items = vms

        alert = vms.endIndex > 1 ? "Bring all MetaWears nearby" : "Bring MetaWear nearby"
        sub = Timer.TimerPublisher(interval: 1, tolerance: 1, runLoop: .main, mode: .common)
            .map { _ in vms.contains(where: { $0.isNearby == false }) }
            .removeDuplicates()
            .sink(receiveValue: { [weak self] shouldAlert in
                self?.showSessionStartAlert = shouldAlert
            })
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
        items.forEach { $0.connect() }
    }

    func onDisappear() {
        
    }
}
