// Copyright 2021 MbientLab Inc. All rights reserved. See LICENSE.MD.

import Foundation
import MetaWearSync

public class SensorPresetsCloudLoader: MWCloudKeyValueDataLoader<[PresetSensorConfiguration]> {

    public init(_ local: UserDefaults,
                _ cloud: NSUbiquitousKeyValueStore) {
        let key = UserDefaults.MetaWear.Keys.sensorPresets
        super.init(key: key, local, cloud)
    }
}

extension Array: VersionedContainerLoadable where Element == PresetSensorConfiguration {
    public typealias Container = MBPresetSensorConfigurationsContainer
}
