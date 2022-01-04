// Copyright 2021 MbientLab Inc. All rights reserved. See LICENSE.MD.

import Foundation
import MetaWearSync

public class SensorPresetsCloudLoader: MWCloudKeyValueDataLoader<SensorPresetsLoadable> {

    public init(_ local: UserDefaults,
                _ cloud: NSUbiquitousKeyValueStore) {
        let key = UserDefaults.MetaWear.Keys.sensorPresets
        super.init(key: key, local, cloud)
    }

    internal convenience init(_ defaults: UserDefaultsContainer) {
        self.init(defaults.local, defaults.cloud)
    }
}

public struct SensorPresetsLoadable {
    public var presets: [PresetSensorConfiguration]
    public init(presets: [PresetSensorConfiguration] = []) {
        self.presets = presets
    }
}

extension SensorPresetsLoadable: VersionedContainerLoadable {
    public typealias Container = MBPresetSensorConfigurationsContainer
}
