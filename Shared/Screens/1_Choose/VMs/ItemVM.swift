// Copyright 2021 MbientLab Inc. All rights reserved. See LICENSE.MD.

import Foundation
import mbientSwiftUI
import MetaWear
import MetaWearSync
import CoreBluetooth

public protocol ItemVM: Identifiable {
    var id: String { get }
    var name: String { get }
    var isGroup: Bool { get }
    var models: [(mac: String, model: MetaWear.Model)] { get }
    var macs: [String] { get }
    var rssi: SignalLevel { get }
    var isLocallyKnown: Bool { get }
    var connection: CBPeripheralState { get }
    var matchedGeometryID: String { get }
}

public extension ItemVM {
    var id: String { matchedGeometryID }
}
