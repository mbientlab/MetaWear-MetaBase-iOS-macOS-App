//
//  SessionModel.swift
//  MetaBase
//
//  Created by Stephen Schiffli on 2/5/18.
//  Copyright © 2018 MBIENTLAB, INC. All rights reserved.
//

import Foundation
import MetaWear


struct SensorDataFile: Codable {
    let csvFilename: String
    let name: String

    init(name: String, csvFilename: String) {
        self.csvFilename = csvFilename
        self.name = name
    }
}

struct SessionModel: Codable {
    let mac: String
    let started: Date
    let name: String
    let note: String
    let model: String
    let firmwareRev: String
    let files: [SensorDataFile]
    
    init(device: MetaWear, started: Date, states: [State], note: String) {
        mac = device.mac ?? "FF:FF:FF:FF:FF:FF"
        self.started = started
        name = device.metadata.name
        self.note = note
        model = device.modelDescription
        firmwareRev = device.info?.firmwareRevision ?? "N/A"
        files = states.map { SensorDataFile(name: $0.sensor.name, csvFilename: $0.csvFilename) }
    }
}
