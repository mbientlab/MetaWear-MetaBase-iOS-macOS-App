// Copyright 2021 MbientLab Inc. All rights reserved. See LICENSE.MD.

import Foundation
import Combine
import MetaWear
import Metadata

public class DiscoveryListVM: ObservableObject {

    @Published public var groups = [MetaWear.Group]()
    @Published public var ungrouped = [MetaWear.Metadata]()
    @Published public var unknown = [UUID]()
    @Published public var isScanning = false

    private unowned let scanner: MetaWearScanner
    private var subs = Set<AnyCancellable>()

    public init(scanner: MetaWearScanner = .sharedRestore, store: MetaWearStore) {
        self.scanner = scanner

        scanner.isScanningPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in self?.isScanning = state }
            .store(in: &subs)

        store.groups
            .sink { [weak self] in self?.groups = $0.sorted(by: <) }
            .store(in: &subs)

        store.ungroupedDevices
            .sink { [weak self] in self?.ungrouped = $0.sorted(by: <) }
            .store(in: &subs)

        store.unknownDevices
            .sink { [weak self] in self?.unknown = $0.sorted(by: <) }
            .store(in: &subs)
    }
}

public extension DiscoveryListVM {

    var listIsEmpty: Bool { groups.isEmpty && ungrouped.isEmpty && unknown.isEmpty }

    var deviceCount: Int { groups.endIndex + ungrouped.endIndex + unknown.endIndex }

    func didAppear() {
        scanner.startScan(higherPerformanceMode: true)
    }

    func didDisappear() {
        scanner.stopScan()
    }
}
