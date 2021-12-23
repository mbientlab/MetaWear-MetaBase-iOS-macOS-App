// Copyright 2021 MbientLab Inc. All rights reserved. See LICENSE.MD.

import Foundation
import MetaWear
import CoreData

public struct Session: Identifiable {
    public var id: UUID
    public var date: Date
    public var name: String
    public var group: UUID? = nil
    public var devices: Set<MACAddress>
    public var files: Set<UUID>
}

public struct File: Identifiable {
    public var id: UUID
    public var csv: Data
    public var name: String
}
