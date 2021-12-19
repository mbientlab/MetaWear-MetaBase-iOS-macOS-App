// Copyright 2021 MbientLab Inc. All rights reserved. See LICENSE.MD.

import Foundation
import MetaWear
import MetaWearSync
import mbientSwiftUI

public class Root: ObservableObject {

    // State
    public let devices: MetaWearSyncStore
    public let routing: Routing

    // Services
    private let scanner: MetaWearScanner
    private let cloud: NSUbiquitousKeyValueStore
    private let local: UserDefaults
    private let metawearLoader: MWKnownDevicesPersistence

    // VMs
    public let factory: UIFactory
    public let bluetoothVM: BluetoothStateVM

    public init() {
        self.cloud = .default
        self.local = .standard
        self.metawearLoader  = MWCloudLoader(local: local, cloud: cloud) 

        let scanner = MetaWearScanner.sharedRestore
        let devices = MetaWearSyncStore(scanner: scanner, loader: metawearLoader)
        let routing = Routing()
        let factory = UIFactory(devices: devices, scanner: scanner, routing: routing)

        self.devices = devices
        self.routing = routing
        self.scanner = scanner
        self.factory = factory
        self.bluetoothVM = factory.makeBluetoothStateWarningsVM()
    }
}

public extension Root {

    func start() {
        do {
            try devices.load()
            let _ = cloud.synchronize()
#if DEBUG
            debugs()
#endif
        } catch { NSLog("Load Failure: \(error.localizedDescription)") }
    }
}

fileprivate func debugs() {
    let bundle = Bundle.main.bundleIdentifier!
    let defaults = UserDefaults.standard.persistentDomain(forName: bundle) ?? [:]
    let defaultsPath = NSSearchPathForDirectoriesInDomains(.libraryDirectory, .userDomainMask, true).first ?? "Error"

    print("")
    for key in defaults.sorted(by: { $0.key < $1.key }) {
        if key.key.contains("NSWindow Frame"), let value = key.value as? String {
            let dimensions = value.components(separatedBy: .whitespaces)
            let width = dimensions[2]
            let height = dimensions[3]
            print("Window", "w", width, "h", height)
        } else {
            print(key.key, ":", key.value)
        }
    }
    print("")
    print("Defaults stored at:", defaultsPath)
    print("")
}

fileprivate func wipeDefaults() {
    UserDefaults.standard.dictionaryRepresentation().forEach { element in
        UserDefaults.standard.removeObject(forKey: element.key)
    }
}
