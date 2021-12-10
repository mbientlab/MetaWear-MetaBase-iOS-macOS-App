// Copyright 2021 MbientLab Inc. All rights reserved. See LICENSE.MD.

import Foundation
import Combine
import MetaWear
import Metadata

public class HistoryScreenVM: ObservableObject, HeaderVM {

    @Published public private(set) var items: [AboutDeviceVM] = []
    @Published public private(set) var ctaLabel = "New Session"
    public let title: String
    public var deviceCount: Int { items.endIndex }
    public let showBackButton = true

    private unowned let routing: Routing
    private unowned let scanner: MetaWearScanner

    public init(title: String, vms: [AboutDeviceVM], store: MetaWearStore, routing: Routing, scanner: MetaWearScanner) {
        self.routing = routing
        self.scanner = scanner
        self.title = title
        self.items = vms
    }
}

public extension HistoryScreenVM {

    func performCTA() {
        // No need to reset focus
        routing.setDestination(.configure)
    }

    func refresh() {
        items.forEach { $0.refresh() }
    }

    func onAppear() {
        items.forEach { $0.connect() }
    }

    func onDisappear() {
        scanner.stopScan()
    }
}

