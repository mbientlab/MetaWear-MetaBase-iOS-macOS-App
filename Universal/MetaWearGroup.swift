//
//  MetaWearGroup.swift
//  MetaBase
//
//  Created by Stephen Schiffli on 2/5/18.
//  Copyright © 2018 MBIENTLAB, INC. All rights reserved.
//

import MetaWear


class MetaWearGroup: Codable {
    let name: String
    let ids: [UUID]
    var isRecording = false {
        didSet {
            if isRecording != oldValue {
                saveToDefaults(key: MetaWearGroup.key, value: MetaWearGroup.cached)
            }
        }
    }
    var devices: [MetaWear] = []
    
    enum CodingKeys: String, CodingKey {
        case name
        case ids
        case isRecording
    }
    
    init(name: String, devices: [MetaWear]) {
        self.name = name
        self.ids = devices.map { $0.peripheral.identifier }
        self.devices = devices
    }
    
    private static let key = "MetaWearGroup"
    private static var cached: [MetaWearGroup] = loadfromDefaults(key: MetaWearGroup.key) ?? []
    
    static func load(_ devices: [MetaWear]) -> [MetaWearGroup] {
        for model in cached {
            model.devices = devices.filter { model.ids.contains($0.peripheral.identifier) }
        }
        return cached
    }
    static func add(_ group: MetaWearGroup) {
        cached.append(group)
        saveToDefaults(key: MetaWearGroup.key, value: cached)
    }
    static func remove(_ idx: Int) {
        cached.remove(at: idx)
        saveToDefaults(key: MetaWearGroup.key, value: cached)
    }
}
