// Copyright 2021 MbientLab Inc. All rights reserved. See LICENSE.MD.

import Foundation

/// Sensor User Parameters Preset
public struct PresetSensorConfiguration: Identifiable, Hashable, Equatable {
    public let id: UUID
    public var name: String
    public let config: UserSensorConfiguration
    
    public init(id: UUID = .init(),
                name: String,
                config: UserSensorConfiguration) {
        self.id = id
        self.name = name
        self.config = config
    }
}

public extension PresetSensorConfiguration {
    
    func updated(for newConfig: UserSensorConfiguration) -> Self {
        .init(id: id, name: name, config: newConfig)
    }
    
    func updated(for newName: String) -> Self {
        .init(id: id, name: newName, config: config)
    }
    
    func matchesModules(for legal: LegalSensorParameters) -> Bool {
        if !legal.accelerometer && config.accelerometer { return false }
        if !legal.ambientLight && config.ambientLight { return false }
        if !legal.barometer && (config.pressure || config.altitude) { return false }
        if !legal.fusion && config.sensorFusion { return false }
        if !legal.gyroscope && config.gyroscope { return false }
        if !legal.humidity && config.humidity { return false }
        if !legal.magnetometer && config.magnetometer { return false }
        if !legal.temperature && config.temperature { return false }
        return true
    }
}

public extension Dictionary where Value == PresetSensorConfiguration {
    
    func filter(matching legal: LegalSensorParameters) -> [PresetSensorConfiguration] {
        reduce(into: [PresetSensorConfiguration]()) { result, element in
            guard element.value.matchesModules(for: legal) else { return }
            result.append(element.value)
        }
        .sorted(by: {
            guard $0.name == $1.name else { return $0.name < $1.name }
            return $0.id < $1.id
        })
    }
}
