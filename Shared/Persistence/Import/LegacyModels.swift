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

        var url: URL { Self.fileStorageDirectory.appendingPathComponent(csvFilename) }

        init(name: String, csvFilename: String) {
            self.csvFilename = csvFilename
            self.name = name
        }

        func load() -> Data? {
            Self.load(self.csvFilename)
        }

        static var load: (_ filename: String) -> Data? = { filename in
            let url = fileStorageDirectory.appendingPathComponent(filename)
            return FileManager.default.contents(atPath: url.path)
        }

        static var fileStorageDirectory: URL = FileManager.default
            .urls(for: .documentDirectory, in: .userDomainMask)
            .first!
    }
}

open class LegacyMetadata: Codable {
    static let defaultsKeyPrefix = "MetaDataKey"

    /// "MetaDataKey" + peripheral.identifier.uuidString
    private let key: String
    var name: String = ""
    var battery: UInt8 = 80
    var sessions: [LegacySessionModel] = []

    var cbPeripheralIdentifier: UUID? {
        let uuidString = String(key.dropFirst(Self.defaultsKeyPrefix.count))
        return UUID(uuidString: uuidString)
    }
}
