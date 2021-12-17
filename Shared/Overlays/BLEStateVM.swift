// Copyright 2021 MbientLab Inc. All rights reserved. See LICENSE.MD.

import Foundation
import CoreBluetooth
import MetaWear
import Combine
#if os(macOS)
import SwiftUI
#elseif os(iOS)
import UIKit
#endif

/// Presents errors when Bluetooth services are unavailable
///
public class BLEStateVM: ObservableObject {

    @Published public var isHovered = false
    @Published public private(set) var isScanning = false

    public var showError:           Bool { state.isProblematic }
    public var ctaLabel:            String { state.ctaLabel }
    public var ctaLabelHovered:     String { state.ctaLabelHovered }
    @Published private var state:   CBManagerState

    private var bleStateUpdates:    AnyCancellable? = nil
    private var scannerUpdates:     AnyCancellable? = nil

    public init(scanner: MetaWearScanner) {
        self.state = scanner.central.state
        handleBLEStateUpdates(from: scanner)
    }

    func didTapCTA() {
        #if os(macOS)
        if let ctaURL = state.ctaURL { NSWorkspace.shared.open(ctaURL) }
        #elseif os(iOS)
        if let ctaURL = state.ctaURL { UIApplication.shared.open(ctaURL) }
        #endif
    }
}

private extension BLEStateVM {

    func handleBLEStateUpdates(from scanner: MetaWearScanner) {

        scannerUpdates = scanner.isScanningPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.isScanning = $0 }

        bleStateUpdates = scanner.bluetoothState
            .receive(on: DispatchQueue.main, options: nil)
            .sink { [weak self] in self?.state = $0  }
    }
}

// MARK: - Model

fileprivate extension CBManagerState {

    var ctaLabel: String {
        switch self {
            case .unsupported: return "Bluetooth Unsupported"
            case .unauthorized: return "Bluetooth Unauthorized"
            case .poweredOff: return "Bluetooth Off"
            default: return "Unknown Error"
        }
    }

    var ctaLabelHovered: String {
        switch self {
            case .unsupported: return "Open Preferences"
            case .unauthorized: return "Open Privacy Settings"
            case .poweredOff: return "Open Preferences"
            default: return "Unknown Error"
        }
    }

    var ctaURL: URL? {
#if os(macOS)
        let bluetoothURL = URL(fileURLWithPath: "/System/Library/PreferencePanes/Bluetooth.prefPane")
        let appSettingsURL = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Bluetooth")!
#endif
#if os(iOS)
        let bluetoothURL = URL(string: UIApplication.openSettingsURLString)
        let appSettingsURL = URL(string: UIApplication.openSettingsURLString)
#endif

        switch self {
            case .poweredOff: return bluetoothURL
            case .unauthorized: return appSettingsURL
            case .unsupported: return bluetoothURL
            default: return nil
        }
    }
}
