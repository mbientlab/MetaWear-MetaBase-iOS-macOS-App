// Copyright 2021 MbientLab Inc. All rights reserved. See LICENSE.MD.

import Foundation
import Combine
import MetaWear
import MetaWearSync

/// Segregate high-frequency updates into one object
public class StreamingCountersContainer: ObservableObject {

    @Published private(set) var counts: [MACAddress:ActionState] = [:]
    private(set) var counters:          [MACAddress:PassthroughSubject<Void,Never>] = [:]
    private var subs                    = Set<AnyCancellable>()

    init(_ action: ActionType, _ devices: [MWKnownDevice]) {
        guard action == .stream else { return }

        self.counters = Dictionary(repeating: .init(), keys: devices)

        counters.forEach { mac, counter in
            counter
                .scan(0) { sum, _ in sum + 1 }
                .receive(on: DispatchQueue.main)
                .sink { [weak self] sum in
                    self?.counts[mac] = .working(sum)
                }
                .store(in: &subs)
        }
    }
}


func Dictionary<V>(repeating: V, keys devices: [MWKnownDevice]) -> [MACAddress:V] {
    Dictionary(uniqueKeysWithValues: devices.map(\.meta.mac).map { ($0, repeating) })
}

