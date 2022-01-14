// Copyright 2022 MbientLab Inc. All rights reserved. See LICENSE.MD.

import Foundation

struct LegacySessionModel: Codable {
    let mac: String
    let started: Date
    let name: String
    let note: String
    let model: String
    let firmwareRev: String
    let files: [SensorDataFile]

    struct SensorDataFile: Codable {
        let csvFilename: String
        let name: String

        var url: URL {
            FileManager.default
                .urls(for: .documentDirectory, in: .userDomainMask)
                .first!
                .appendingPathComponent(csvFilename)
        }

        init(name: String, csvFilename: String) {
            self.csvFilename = csvFilename
            self.name = name
        }
    }
}

class LegacyMetadata: Codable {
    static let defaultsKeyPrefix = "MetaDataKey"
    private let key: String
    var name: String = ""
    var battery: UInt8 = 80
    var sessions: [LegacySessionModel] = []
}
