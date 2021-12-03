// Copyright 2021 MbientLab Inc. All rights reserved. See LICENSE.MD.

import Foundation
import CoreBluetooth
import MetaWear
import Combine

/// Presents errors when Bluetooth services are unavailable
///
public class BLEStateWarningsVM: ObservableObject {

    @Published public var showError = false
    public private(set) var errorTitle: String = "Bluetooth Error"
    public private(set) var errorMessage: String = ""

    private var bleStateUpdates: AnyCancellable? = nil

    public init(scanner: MetaWearScanner) {
        handleBLEStateUpdates(from: scanner)
    }
}

private extension BLEStateWarningsVM {

    func handleBLEStateUpdates(from scanner: MetaWearScanner) {
        bleStateUpdates = scanner.centralManagerDidUpdateState
            .receive(on: DispatchQueue.main, options: nil)
            .sink { [weak self] state in
                switch state {
                    case .unsupported:
                        self?.errorMessage = "Device doesn't support the Bluetooth Low Energy."
                    case .unauthorized:
                        self?.errorMessage = "The application is not authorized to use the Bluetooth Low Energy."
                    case .poweredOff:
                        self?.errorMessage = "Bluetooth is currently powered off.  Please enable it in settings."

                    default: return
                }
                self?.showError = true
            }
    }
}
