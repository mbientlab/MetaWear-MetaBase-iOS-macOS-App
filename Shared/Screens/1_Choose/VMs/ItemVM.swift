// Copyright 2021 MbientLab Inc. All rights reserved. See LICENSE.MD.

import Foundation
import mbientSwiftUI
import MetaWear
import MetaWearSync
import CoreBluetooth

public protocol ItemVM {
    var matchedGeometryID: String { get }
    var state: ItemState { get }

    func identify()
    func connect()

    func onAppear()
}

public struct ItemState {
    public var name: String
    public var isGroup: Bool
    public var models: [(mac: String, model: MetaWear.Model)]
    public var macs: [String]
    public var rssi: SignalLevel
    public var isLocallyKnown: Bool
    public var connection: CBPeripheralState
    public var isLogging: Bool

    public var identifyTip: String
    public var isIdentifying: Bool
    public var ledVM: MWLED.Flash.Emulator

    public var isWorking: Bool { isIdentifying || connection == .connecting }
    public var showCloudSync: Bool { isLocallyKnown == false && models.isEmpty == false }
    public var isUnrecognized: Bool { models.isEmpty }
}
