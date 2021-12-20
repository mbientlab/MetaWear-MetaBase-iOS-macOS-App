// Copyright 2021 MbientLab Inc. All rights reserved. See LICENSE.MD.

import Foundation
import MetaWear
import MetaWearSync

func Dictionary<V>(repeating: V, keys devices: [MWKnownDevice]) -> [MACAddress:V] {
    Dictionary(uniqueKeysWithValues: devices.map(\.meta.mac).map { ($0, repeating) })
}

