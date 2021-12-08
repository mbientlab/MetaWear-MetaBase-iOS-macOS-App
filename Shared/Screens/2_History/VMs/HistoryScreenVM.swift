// Copyright 2021 MbientLab Inc. All rights reserved. See LICENSE.MD.

import Foundation
import Combine
import MetaWear
import Metadata

public class HistoryScreenVM: ObservableObject {

    @Published public private(set) var items: [AboutDeviceVM] = []
    @Published public private(set) var ctaLabel = "New Session"
    let title: String

    private let routingItem: Routing.Item
    private unowned let routing: Routing
    private unowned let scanner: MetaWearScanner

    public init(item: Routing.Item, vms: [AboutDeviceVM], store: MetaWearStore, routing: Routing, scanner: MetaWearScanner) {
        self.routing = routing
        self.routingItem = item
        vms.indices.forEach {
            vms[$0].led.pattern = MWLED.FlashPattern.Presets.init(rawValue: $0 % 10)!.pattern
        }
        self.items = vms
        self.scanner = scanner
        self.title = {
            if case let Routing.Item.group(id) = item, let group = store.getGroup(id: id) {
                return group.name
            } else {
                return vms.first?.meta.name ?? "Error"
            }
        }()
    }
}

public extension HistoryScreenVM {

    func performCTA() {
        routing.setDestination(.moduleConfig(routingItem))
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
