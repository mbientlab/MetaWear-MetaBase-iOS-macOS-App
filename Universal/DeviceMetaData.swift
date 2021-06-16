//
//  DeviceMetaData.swift
//  MetaBase
//
//  Created by Stephen Schiffli on 4/26/17.
//  Copyright © 2017 MBIENTLAB, INC. All rights reserved.
//

import UIKit
import MetaWear


class DeviceMetaData: Codable {
    private let key: String
    var name: String {
        didSet {
            guard oldValue != name else {
                return
            }
            save()
        }
    }
    var battery: UInt8 {
        didSet {
            guard oldValue != battery else {
                return
            }
            save()
        }
    }
    var sessions: [SessionModel]
    
    init(key: String, name: String) {
        self.key = key
        self.name = name
        self.battery = 80
        self.sessions = []
    }
    
    func save() {
        saveToDefaults(key: key, value: self)
    }
}

fileprivate var cache: [String: DeviceMetaData] = [:]

extension MetaWear {
    fileprivate var metadataKey: String {
        get {
            return "MetaDataKey" + peripheral.identifier.uuidString
        }
    }
    var metadata: DeviceMetaData {
        if let metadata = cache[metadataKey] {
            return metadata
        }
        let metadata = loadfromDefaults(key: metadataKey) ?? DeviceMetaData(key: metadataKey, name: name)
        cache[metadataKey] = metadata
        return metadata
    }
}
