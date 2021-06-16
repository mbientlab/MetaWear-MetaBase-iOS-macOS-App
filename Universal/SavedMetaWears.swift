//
//  SavedMetaWears.swift
//  MetaBase
//
//  Created by Stephen Schiffli on 1/23/18.
//  Copyright © 2018 MBIENTLAB, INC. All rights reserved.
//

import MetaWear
import MetaWearCpp
import BoltsSwift


protocol SavedMetaWearsDelegate: class {
    func savedMetaWears(_ savedMetaWears: SavedMetaWears, didAddDevicesAt indexes: [Int])
    func savedMetaWears(_ savedMetaWears: SavedMetaWears, didRemoveDevicesAt indexes: [Int])
    func savedMetaWears(_ savedMetaWears: SavedMetaWears, didAddGroupAt idx: Int, removeDevicesAt indexes: [Int])
    func savedMetaWears(_ savedMetaWears: SavedMetaWears, didRemoveGroupAt idx: Int, addDevicesAt indexes: [Int])
}

class SavedMetaWears {
    var devices: [MetaWear] = []
    var groups: [MetaWearGroup] = []
    weak var delegate: SavedMetaWearsDelegate?
    let scanner: MetaWearScanner
    
    init(scanner: MetaWearScanner = MetaWearScanner.shared) {
        self.scanner = scanner
    }
    
    func load(_ delegate: SavedMetaWearsDelegate) -> Task<Void> {
        self.delegate = delegate
        return scanner.retrieveSavedMetaWearsAsync().continueOnSuccessWith {
            self.groups = MetaWearGroup.load($0)
            self.devices = $0.filter { !(self.groups.flatMap{$0.devices}.contains($0)) }
            // Load saved data
            $0.forEach {
                if let data = try? Data(contentsOf: $0.uniqueUrl) {
                    $0.deserialize([UInt8](data))
                }
            }
        }
    }
    
    func startRssiTracking() {
        scanner.startScan(allowDuplicates: true) { _ in }
    }
    
    func stopRssiTracking() {
        scanner.stopScan()
    }
    
    func addDevice(_ device: MetaWear) {
        guard !devices.contains(where: { $0.peripheral.identifier == device.peripheral.identifier }) else {
            return
        }
        device.apiAccessQueue.async {
            device.remember()
            // Save this to speed up connection next time
            let state = Data(bytes: device.serialize())
            try? state.write(to: device.uniqueUrl,
                             options: [.atomic, .completeFileProtectionUntilFirstUserAuthentication])
            self.devices.append(device)
            mbl_mw_debug_disconnect(device.board)
            self.delegate?.savedMetaWears(self, didAddDevicesAt: [self.devices.count - 1])
        }
    }
    
    func removeDevice(_ idx: Int) {
        let device = devices.remove(at: idx)
        device.forget()
        try? FileManager.default.removeItem(at: device.uniqueUrl)
        delegate?.savedMetaWears(self, didRemoveDevicesAt: [idx])
    }
    
    func groupDevices(name: String, indexes: [Int]) {
        let groupDevices = indexes.sorted().reversed().map { devices.remove(at: $0) }
        let group = MetaWearGroup(name: name, devices: groupDevices)
        groups.append(group)
        MetaWearGroup.add(group)
        delegate?.savedMetaWears(self, didAddGroupAt: groups.count - 1, removeDevicesAt: indexes)
    }
    
    func ungroup(_ idx: Int) {
        MetaWearGroup.remove(idx)
        let group = groups.remove(at: idx)
        let start = devices.count
        devices.append(contentsOf: group.devices)
        delegate?.savedMetaWears(self, didRemoveGroupAt: idx, addDevicesAt: [Int](start..<devices.count))
    }
}
