// Copyright 2021 MbientLab Inc. All rights reserved. See LICENSE.MD.

import Foundation
import MetaWear
import CoreData

public struct Session: Identifiable, Hashable {
    public var id: UUID
    public var date: Date
    public var name: String
    public var group: UUID? = nil
    public var devices: Set<MACAddress>
    public var files: Set<UUID>


    public func duplicate(files: [File]) -> (session: Self, files: [File]) {
        let files = files.map { $0.duplicate() }
        let session = Self.init(id: .init(), date: date, name: name, group: group, devices: devices, files: Set(files.map(\.id)))
        return (session, files)
    }
}

public struct File: Identifiable {
    public var id: UUID
    public var csv: Data
    public var name: String

    public init(id: UUID, csv: Data, name: String) {
        self.id = id
        self.csv = csv
        self.name = name
    }

    public init(id: UUID = .init(),
                csv: Data,
                deviceName: String,
                signal: MWNamedSignal,
                date: Date
    ) {
        self.id = id
        self.csv = csv

        let date = shortDateTimeFormatter.string(from: date)
            .components(separatedBy: .alphanumerics.inverted)
            .joined(separator: "-")

        self.name = [deviceName, signal.name, date].joined(separator: " ")
    }

    func duplicate() -> Self {
        Self.init(id: .init(), csv: csv, name: name)
    }
}
