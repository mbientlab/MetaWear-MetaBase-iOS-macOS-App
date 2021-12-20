// Copyright 2021 MbientLab Inc. All rights reserved. See LICENSE.MD.

import Foundation

public class SensorPresetsCloudLoader: MWCloudKeyValueDataLoader<[PresetSensorConfiguration]> {

    public init(_ local: UserDefaults,
                _ cloud: NSUbiquitousKeyValueStore) {
        let key = UserDefaults.MetaWear.Keys.sensorPresets
        super.init(key: key, local, cloud)
    }
}

extension Array: ContainerLoadable where Element == PresetSensorConfiguration {
    public typealias Container = MBPresetSensorConfigurationsContainer
}
