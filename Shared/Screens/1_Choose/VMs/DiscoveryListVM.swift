// Copyright 2021 MbientLab Inc. All rights reserved. See LICENSE.MD.

import Foundation
import Combine
import MetaWear
import MetaWearSync

public class DiscoveryListVM: ObservableObject {

    @Published private(set) public var groups = [MetaWear.Group]()
    @Published private(set) public var ungrouped = [MetaWear.Metadata]()
    @Published private(set) public var unknown = [UUID]()
    @Published private(set) public var isScanning = false

    private unowned let scanner: MetaWearScanner
    private unowned let store: MetaWearSyncStore
    private var subs = Set<AnyCancellable>()
    private var didSetup = false

    public init(scanner: MetaWearScanner = .sharedRestore,
                store: MetaWearSyncStore) {
        self.scanner = scanner
        self.store = store
    }

    deinit { scanner.stopScan() }
}

public extension DiscoveryListVM {

    var listIsEmpty: Bool { groups.isEmpty && ungrouped.isEmpty && unknown.isEmpty }

    var deviceCount: Int { groups.endIndex + ungrouped.endIndex + unknown.endIndex }

    func didAppear() {
        scanner.startScan(higherPerformanceMode: true)
        guard didSetup == false else { return }
        didSetup = true

        scanner.isScanningPublisher
            .receive(on: DispatchQueue.main)
            .removeDuplicates()
            .sink { [weak self] state in self?.isScanning = state }
            .store(in: &subs)

        Publishers.CombineLatest(store.groups, store.ungroupedDevices)
            .receive(on: DispatchQueue.main)
        // A bit of a hack to consolidate Group/Ungroup updates
            .debounce(for: 0.02, scheduler: DispatchQueue.main)
            .sink { [weak self] groups, ungrouped in
                let groupedMACs = groups.reduce(into: Set<MACAddress>()) { $0.formUnion($1.deviceMACs) }
                let uniqueUngrouped = ungrouped.filter { !groupedMACs.contains($0.mac) }
                self?.groups = groups.sorted(by: <)
                self?.ungrouped = uniqueUngrouped.sorted(by: <)
            }
            .store(in: &subs)

        store.unknownDevices
            .sink { [weak self] update in
                self?.unknown = update.sorted(by: <)
            }
            .store(in: &subs)
    }

    func toggleScanning() {
        if isScanning { scanner.stopScan() }
        else { scanner.startScan(higherPerformanceMode: true) }
    }
}
