// Copyright 2021 MbientLab Inc. All rights reserved. See LICENSE.MD.

import Foundation
import mbientSwiftUI
import MetaWear
import Metadata

protocol ItemVM {
    var name: String { get }
    var isGroup: Bool { get }
    var models: [(mac: String, model: MetaWear.Model)] { get }
    var isLocallyKnown: Bool { get }
    var macs: [String] { get }
    var rssi: SignalLevel { get }
}
